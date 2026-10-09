import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../data/app_database.dart';

class BackupExport {
  const BackupExport({
    required this.key,
    required this.entryCount,
    required this.photoCount,
  });

  final String key;
  final int entryCount;
  final int photoCount;
}

class BackupImport {
  const BackupImport({
    required this.entryCount,
    required this.plannedCount,
    required this.weightCount,
    required this.skippedCount,
    required this.photoCount,
    required this.preferences,
    required this.profileImported,
    required this.preferencesImported,
  });

  final int entryCount;
  final int plannedCount;
  final int weightCount;
  final int skippedCount;
  final int photoCount;
  final Map<String, dynamic>? preferences;
  final bool profileImported;
  final bool preferencesImported;
}

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  Future<BackupExport> exportToDownloads() async {
    final passphrase = _generatePassphrase();
    final entries = await _db.allEntryMaps();
    final appDir = await _db.localDirectory;
    final packedEntries = <Map<String, dynamic>>[];
    var photoCount = 0;
    for (final raw in entries) {
      final entry = Map<String, dynamic>.from(raw);
      final photoPath = entry['photoPath'] as String?;
      if (photoPath != null && photoPath.isNotEmpty) {
        if (photoPath.startsWith('data:image/')) {
          final comma = photoPath.indexOf(',');
          if (comma > 0) {
            entry['photoBase64'] = photoPath.substring(comma + 1);
            entry['photoExtension'] = photoPath.substring(
              11,
              photoPath.indexOf(';') > 11 ? photoPath.indexOf(';') : comma,
            );
          }
        } else {
          final file = File(photoPath);
          if (await file.exists()) {
            entry['photoBase64'] = base64Encode(await file.readAsBytes());
            entry['photoExtension'] = p
                .extension(photoPath)
                .replaceFirst('.', '');
          }
        }
        if (entry['photoBase64'] is String) {
          photoCount++;
        } else {
          entry['photoPath'] = null;
        }
      }
      packedEntries.add(entry);
    }
    final payload = <String, dynamic>{
      'format': 'nutri_diary_backup',
      'formatVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'app': 'Nutri Diary',
      'entries': packedEntries,
      'entryCount': packedEntries.length,
      'photoCount': photoCount,
      'weights': await _db.allWeightMaps(),
      'meta': await _db.allMeta(),
      'photoNote': 'Photos present at export time are embedded as base64.',
    };
    final plaintext = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final kdf = Pbkdf2.hmacSha256(iterations: 310000, bits: 256);
    final key = await kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final cipher = AesGcm.with256bits();
    final secretBox = await cipher.encrypt(plaintext, secretKey: key);
    final envelope = <String, dynamic>{
      'format': 'nutri_diary_encrypted_backup',
      'formatVersion': 2,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': 310000,
      'salt': base64Encode(salt),
      'sealed': base64Encode(secretBox.concatenation()),
    };
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(envelope)),
    );
    final fileName =
        'ShyokuShi_${DateTime.now().millisecondsSinceEpoch}.ntbackup';
    final backup = File(p.join(appDir.path, fileName));
    await backup.writeAsBytes(bytes, flush: true);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await const MethodChannel('shiyokushi/downloads').invokeMethod<String>(
        'saveBackup',
        {'fileName': fileName, 'sourcePath': backup.path},
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          title: '食誌 encrypted backup',
          text: 'Encrypted diary backup. Keep its key separately.',
          files: [XFile(backup.path, mimeType: 'application/octet-stream')],
        ),
      );
    }
    return BackupExport(
      key: passphrase,
      entryCount: packedEntries.length,
      photoCount: photoCount,
    );
  }

  Future<Uint8List?> pickBackup() async {
    final selection = await FilePicker.pickFiles(
      // Android document providers often hide app-created Downloads files
      // when a custom MIME/extension filter is used. Validate the bytes below.
      type: FileType.any,
    );
    if (selection.isEmpty) return null;
    try {
      return await selection.single.readAsBytes();
    } catch (_) {
      throw const FormatException('The selected backup could not be read.');
    }
  }

  bool requiresPassphrase(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> &&
          decoded['format'] == 'nutri_diary_encrypted_backup';
    } catch (_) {
      throw const FormatException('The selected file is not a valid backup.');
    }
  }

  Future<BackupImport> importBackup(String passphrase, Uint8List bytes) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const FormatException('The selected file is not a valid backup.');
    }
    if (decoded is Map<String, dynamic> &&
        decoded['format'] == 'nutri_diary_encrypted_backup') {
      if (decoded['formatVersion'] != 2 ||
          decoded['kdf'] != 'PBKDF2-HMAC-SHA256' ||
          decoded['iterations'] != 310000) {
        throw const FormatException('Unsupported encrypted backup format.');
      }
      try {
        final salt = base64Decode('${decoded['salt']}');
        final sealed = base64Decode('${decoded['sealed']}');
        final key = await Pbkdf2.hmacSha256(
          iterations: 310000,
          bits: 256,
        ).deriveKeyFromPassword(password: passphrase, nonce: salt);
        final cipher = AesGcm.with256bits();
        final box = SecretBox.fromConcatenation(
          sealed,
          nonceLength: cipher.nonceLength,
          macLength: cipher.macAlgorithm.macLength,
        );
        decoded = jsonDecode(
          utf8.decode(await cipher.decrypt(box, secretKey: key)),
        );
      } catch (_) {
        throw const FormatException(
          'Could not decrypt this backup. Check the passphrase and file.',
        );
      }
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'The selected file does not contain readable backup data.',
      );
    }
    if (decoded['format'] != null &&
        decoded['format'] != 'nutri_diary_backup') {
      throw const FormatException(
        'The selected file is not a ShyokuShi backup.',
      );
    }
    if (decoded['formatVersion'] != null && decoded['formatVersion'] != 1) {
      throw const FormatException('This backup version is not supported.');
    }
    final rawEntries = decoded['entries'];
    final rawWeights = decoded['weights'];
    final rawMeta = decoded['meta'];
    var skippedCount = 0;
    final entryMaps = <Map<String, dynamic>>[];
    if (rawEntries is List) {
      for (final raw in rawEntries) {
        final normalized = _foodEntry(raw);
        if (normalized == null) {
          skippedCount++;
        } else {
          entryMaps.add(normalized);
        }
      }
    } else if (rawEntries != null) {
      skippedCount++;
    }
    final weightMaps = <Map<String, dynamic>>[];
    if (rawWeights is List) {
      for (final raw in rawWeights) {
        final normalized = _weightEntry(raw);
        if (normalized == null) {
          skippedCount++;
        } else {
          weightMaps.add(normalized);
        }
      }
    } else if (rawWeights != null) {
      skippedCount++;
    }
    final importedMeta = _metadata(rawMeta);
    if (rawMeta != null && importedMeta.isEmpty) skippedCount++;
    if (entryMaps.isEmpty && weightMaps.isEmpty && importedMeta.isEmpty) {
      throw const FormatException(
        'No readable food entries, weight logs, or profile settings were found.',
      );
    }
    final appDir = await _db.localDirectory;
    final photoDir = Directory(p.join(appDir.path, 'food_photos'));
    var photoCount = 0;
    for (final entry in entryMaps) {
      var base64Photo = entry.remove('photoBase64');
      final legacyPhotoPath = entry['photoPath'] as String?;
      if (base64Photo == null &&
          legacyPhotoPath?.startsWith('data:image/') == true) {
        final comma = legacyPhotoPath!.indexOf(',');
        if (comma >= 0) base64Photo = legacyPhotoPath.substring(comma + 1);
      }
      final ext = '${entry.remove('photoExtension') ?? 'jpg'}'.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '',
      );
      if (base64Photo is String && base64Photo.isNotEmpty) {
        try {
          await photoDir.create(recursive: true);
          final photo = File(
            p.join(
              photoDir.path,
              'restored_${entry['id']}.${ext.isEmpty ? 'jpg' : ext}',
            ),
          );
          await photo.writeAsBytes(base64Decode(base64Photo), flush: true);
          entry['photoPath'] = photo.path;
          photoCount++;
        } catch (_) {
          entry['photoPath'] = null;
          skippedCount++;
        }
      } else if (legacyPhotoPath == null ||
          legacyPhotoPath.startsWith('data:image/') ||
          !await File(legacyPhotoPath).exists()) {
        entry['photoPath'] = null;
        if (legacyPhotoPath != null) skippedCount++;
      }
    }
    final plannedCount =
        entryMaps.where((entry) => entry['isPlanned'] == 1).length;
    await _db.mergeImported(
      entries: entryMaps,
      weights: weightMaps,
      meta: importedMeta,
    );
    final restoredPreferences = await _db.readMeta('preferences');
    return BackupImport(
      entryCount: entryMaps.length,
      plannedCount: plannedCount,
      weightCount: weightMaps.length,
      skippedCount: skippedCount,
      photoCount: photoCount,
      preferences: restoredPreferences,
      profileImported: importedMeta.containsKey('profile'),
      preferencesImported: importedMeta.containsKey('preferences'),
    );
  }

  Map<String, dynamic>? _foodEntry(dynamic raw) {
    if (raw is! Map) return null;
    final row = Map<String, dynamic>.from(raw);
    if (!row.keys.any(
      const {
        'id',
        'loggedAt',
        'name',
        'meal',
        'grams',
        'calories100g',
      }.contains,
    )) {
      return null;
    }
    final rawDate = _text(row['loggedAt']);
    final loggedAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    final name = _text(row['name']);
    final meal = _text(row['meal']);
    final grams = _number(row['grams']) ?? 0.0;
    final suppliedId = _text(row['id']);
    final id =
        suppliedId.isNotEmpty
            ? suppliedId
            : _stableImportId('$rawDate|$name|$meal|$grams');
    final planned =
        row['isPlanned'] == true ||
        row['isPlanned'] == 1 ||
        row['isPlanned'] == '1';
    return {
      'id': id,
      'loggedAt': loggedAt.toIso8601String(),
      'name': name.isEmpty ? 'Imported food' : name,
      'meal': meal.isEmpty ? 'Snack' : meal,
      'grams': grams,
      'calories100g': _number(row['calories100g']) ?? 0.0,
      'protein100g': _number(row['protein100g']) ?? 0.0,
      'carbs100g': _number(row['carbs100g']) ?? 0.0,
      'fat100g': _number(row['fat100g']) ?? 0.0,
      'fiber100g': _number(row['fiber100g']) ?? 0.0,
      'sugar100g': _number(row['sugar100g']) ?? 0.0,
      'source':
          _text(row['source']).isEmpty ? 'Imported' : _text(row['source']),
      'photoPath': row['photoPath'] is String ? row['photoPath'] : null,
      'notes': _text(row['notes']),
      'isPlanned': planned ? 1 : 0,
      'mealId': row['mealId'] is String ? row['mealId'] : null,
      'referenceId': row['referenceId'] is String ? row['referenceId'] : null,
      if (row['photoBase64'] is String) 'photoBase64': row['photoBase64'],
      if (row['photoExtension'] is String)
        'photoExtension': row['photoExtension'],
    };
  }

  Map<String, dynamic>? _weightEntry(dynamic raw) {
    if (raw is! Map) return null;
    final row = Map<String, dynamic>.from(raw);
    final kg = _number(row['kg']);
    if (kg == null || !kg.isFinite || kg <= 0) return null;
    final rawDate = _text(row['loggedAt']);
    return {
      'id':
          _text(row['id']).isEmpty
              ? _stableImportId('$rawDate|weight|$kg')
              : _text(row['id']),
      'loggedAt':
          (DateTime.tryParse(rawDate) ?? DateTime.now()).toIso8601String(),
      'kg': kg,
      'notes': _text(row['notes']),
    };
  }

  Map<String, dynamic> _metadata(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, dynamic>{};
    for (final item in raw.entries) {
      if (item.key is! String) continue;
      final key = item.key as String;
      if (key == 'setupComplete' || key == 'legalConsent') continue;
      if (key == 'preferences' && item.value is Map) {
        final source = item.value as Map;
        final valid = <String, dynamic>{};
        for (final preference in source.entries) {
          if (preference.key is String &&
              (preference.value is String ||
                  preference.value is bool ||
                  preference.value is num)) {
            final key = preference.key as String;
            final value = preference.value;
            if ((key == 'displayName' &&
                    value is String &&
                    value.length <= 64) ||
                (key == 'language' &&
                    const {'en', 'ja', 'zh', 'ko'}.contains(value)) ||
                (key == 'country' &&
                    const {
                      'JP',
                      'US',
                      'CA',
                      'GB',
                      'KR',
                      'CN',
                      'OTHER',
                    }.contains(value))) {
              valid[key] = value;
            }
          }
        }
        if (valid.isNotEmpty) result[key] = valid;
      } else if (key == 'profile' && item.value is Map) {
        final source = item.value as Map;
        final profile = <String, dynamic>{};
        for (final field in const [
          'age',
          'heightCm',
          'weightKg',
          'targetWeightKg',
        ]) {
          final value = _number(source[field]);
          final rangeIsValid = switch (field) {
            'age' => value != null && value >= 1 && value <= 110,
            'heightCm' => value != null && value >= 80 && value <= 250,
            _ => value != null && value >= 20 && value <= 500,
          };
          if (value != null && value.isFinite && rangeIsValid) {
            profile[field] = field == 'age' ? value.round() : value;
          }
        }
        if (const {'male', 'female', 'other'}.contains(source['sex'])) {
          profile['sex'] = source['sex'];
        }
        if (const {
          'sedentary',
          'light',
          'moderate',
          'high',
          'veryHigh',
        }.contains(source['activity'])) {
          profile['activity'] = source['activity'];
        }
        if (const {'gain', 'lose', 'maintain'}.contains(source['goalType'])) {
          profile['goalType'] = source['goalType'];
        }
        if (source['targetDate'] is String &&
            DateTime.tryParse(source['targetDate'] as String) != null) {
          profile['targetDate'] = source['targetDate'];
        }
        if (profile.isNotEmpty) result[key] = profile;
      } else if (key == 'appearance' && item.value is Map) {
        final themeMode = (item.value as Map)['themeMode'];
        if (themeMode is String) result[key] = {'themeMode': themeMode};
      }
    }
    return result;
  }

  String _text(dynamic value) => value is String ? value.trim() : '';

  String _stableImportId(String value) {
    final encoded = base64Url.encode(utf8.encode(value)).replaceAll('=', '');
    return 'import_${encoded.substring(0, encoded.length.clamp(1, 28).toInt())}';
  }

  double? _number(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite ? number : null;
  }

  String _generatePassphrase() {
    const letters = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ';
    const digits = '23456789';
    const symbols = '!@#%+-_=';
    const all = '$letters$digits$symbols';
    final random = Random.secure();
    final chars = <String>[
      letters[random.nextInt(letters.length)],
      digits[random.nextInt(digits.length)],
      symbols[random.nextInt(symbols.length)],
      for (var i = 3; i < 10; i++) all[random.nextInt(all.length)],
    ]..shuffle(random);
    return chars.join();
  }
}
