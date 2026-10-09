import 'package:flutter/material.dart';

class LegalDocuments {
  static const version = '2026-10-09-v1';

  static String text(String language) => switch (language) {
    'ja' => _ja,
    'zh' => _zh,
    'ko' => _ko,
    _ => _en,
  };

  static const _en = '''
食誌 / ShyokuShi — Privacy Notice and Terms of Use
Effective date: 9 October 2026 · Version 1

PLEASE READ BEFORE USING THE APP
This notice describes the current starter app as it is implemented. It is a product notice, not a lawyer’s opinion, a promise that every law applies or does not apply, or a substitute for jurisdiction-specific legal advice. Privacy and health-app obligations can depend on the developer, the user, the data flows, and where the app is offered. The developer should obtain qualified legal review before public distribution and update this notice whenever the app or its providers change.

1. Who operates this app and how to contact the developer
食誌 is an independent nutrition and meal-tracking application built by Neko. The app has no user account or hosted diary service in this version. The source and a public contact route are available at https://github.com/neko7123. A GitHub issue may be visible publicly; do not post your name, health details, backups, screenshots containing personal information, or other confidential material there. The developer’s identity, address, and any formal privacy contact details should be added before commercial or public release if required by applicable law.

2. What the app stores
Food names, meal names, meal dates and times, portion grams, nutrition values, notes, attached food photographs, weight entries, body-profile details, goals, selected country, language, appearance, and app preferences are stored in the app’s local database or app-private files. A profile can include age, height, weight, activity level, and a weight goal. These details may be sensitive or may be treated as health-related personal information under laws applicable to you. The app does not require an account. This version does not operate a cloud account, cloud sync, advertising system, analytics service, or food-recognition service.

On Android, the diary database and photos are kept in the app’s private storage. The operating system’s application sandbox limits access by other ordinary applications, but this is not a separate encryption layer and is not a guarantee against malware, a compromised or unlocked device, forensic access, operating-system defects, or a person who can access the device. Device encryption and screen-lock security are controlled by the device and its owner. On web, data is stored in browser site storage and can be removed by clearing browser data. Uninstalling the app or clearing its storage can remove the local diary.

3. Online food searches and third parties
When you choose to search for a food, the search term and the network request’s ordinary technical information (such as IP address, time, app or browser networking metadata) are sent to external food-data services. The app may query Open Food Facts, including regional and global endpoints, and USDA FoodData Central. A country selection helps choose a regional product catalogue; it does not guarantee that results are issued or approved by that country’s government, that a result is locally applicable, or that a national food-composition table is being used. Search availability, accuracy, provider terms, and provider privacy practices are controlled by those providers. Their services may log requests under their own policies. Do not enter a name, address, diagnosis, or other sensitive information as a search term. An optional USDA API key may be configured at build time; a public demonstration key may be subject to strict limits. Searches can fail, be incomplete, or return no results.

The app does not send diary entries, profile details, notes, or attached photos to those providers as part of food search. This statement describes the current code and must be reviewed after any future integration, advertising, analytics, crash reporting, cloud storage, or AI feature is added. Third-party websites and services are governed by their own terms and privacy notices; this app does not control them.

4. Nutrition, weight, BMI, and medical disclaimer
食誌 is a record-keeping and general wellness tool. It is not a medical device or healthcare service, and it does not diagnose, treat, cure, prevent, or monitor a disease. It does not give medical, dietetic, clinical, emergency, or individualized professional advice. Calorie and nutrient values can be missing, rounded, stale, incorrectly labelled, based on a different recipe or preparation state, or associated with the wrong food. Portion estimates are entered by the user; a photograph does not identify food or determine grams. Calculations, calorie targets, weight projections, and BMI are estimates for tracking only. BMI is a limited screening measure and is not a diagnosis or a complete measure of health. Nothing in the app replaces a clinician, registered dietitian, medicine label, laboratory result, or official food-safety advice.

Do not start, stop, or change a diet, medication, treatment, or exercise plan based only on this app. Ask a qualified healthcare professional about personal nutrition needs, pregnancy, allergies, eating-disorder concerns, a medical condition, or a major weight change. In an emergency, contact local emergency services. Use extra care for children and adolescents; adult BMI categories and adult calorie equations are not suitable for every person. You are responsible for deciding whether a value is appropriate before relying on it.

5. Photos, permissions, and local access
Photos are chosen through the operating system’s camera or photo picker and copied into the app’s local photo folder. The app needs access only to the image you choose (and camera use when you choose to take a photo). Photos are not currently uploaded or analyzed. A photo can reveal faces, locations, device metadata, or other personal information; choose images carefully. If you export a backup, photo bytes present at export time are included in that backup.

6. Export, import, and encryption
Export creates an encrypted backup containing diary entries, profile, preferences, weight logs, and available photos. On supported Android versions, the file is saved under Downloads/ShyokuShi. The app generates a random ten-character key and displays it after export. The key is required to decrypt the backup. Copy it carefully and store it separately from the backup. Anyone holding both the backup and its key may read the included information. The app cannot recover a lost key. A short key is easier to mistype and has less strength than a longer passphrase; use the app’s key only for this backup, do not reuse it elsewhere, and keep the phone and backup secure. Encryption reduces exposure but cannot protect a key visible on an unlocked screen, a compromised device, or an unencrypted copy made by another app.

Import requires you to choose a file and enter its key. Import replaces the current diary, profile, preferences, weight history, and related records with the chosen backup. Make a separate backup first if you might need current data. Keep backups in a secure place and delete unwanted copies from Downloads, messaging apps, cloud drives, or recipients’ devices yourself. Legacy unencrypted JSON backup files may be accepted for compatibility; those files do not receive the same confidentiality as encrypted backups. Review a file’s origin before importing it. A damaged or maliciously modified file may fail validation; never import a file from an untrusted source.

7. Retention, deletion, and your choices
You can edit or delete entries within the app, export a copy, and stop using the app. This version has no account portal or remote diary from which the developer can retrieve or delete records. Local records generally remain until you delete them, clear app storage, or uninstall the app; backups and copies created outside the app may remain elsewhere. Android system backups, device migration, file managers, sharing targets, and browser backups are controlled by the operating system and your settings. Before selling, lending, or discarding a device, use its own reset and backup controls. Applicable law may give you rights such as access, correction, deletion, restriction, objection, portability, or a complaint to a regulator; which rights apply and how to exercise them depends on your location and the developer’s legal role. Contact through the GitHub project for product questions, but do not include private diary data in public issues.

8. Security and incidents
The app uses platform-private storage and encrypted export files, but the local SQLite database itself is not separately encrypted by an app-managed key. No software or transmission is perfectly secure. Protect your device with a screen lock, keep the operating system updated, do not share the export key, and do not place the key in the same folder as the backup. If you believe data was exposed, secure the device and any copies first, then use the project contact route without publicly posting sensitive information. This notice does not waive any incident-notification duties that may apply under law.

9. Terms of use
You may use the app for personal food and wellness record keeping, subject to these terms and applicable law. You are responsible for the accuracy of information you enter, confirming search matches, checking nutrition labels, making and protecting backups, and deciding whether to act on displayed estimates. You must not use the app to break laws, interfere with its operation, access another person’s data without permission, or treat its outputs as professional diagnosis or treatment. Do not rely on the app where an error could cause injury or delay necessary care.

The app, its calculations, food matches, and availability are provided “as is” and “as available” to the extent permitted by law. The developer does not promise uninterrupted operation, error-free calculations, complete food coverage, a particular result, compatibility with every device, or recovery of lost records. External food data belongs to its respective contributors and is subject to its applicable licence and attribution terms. You must review those terms before redistributing database content or images. The developer may change, suspend, or discontinue features. These terms do not exclude consumer rights, warranties, remedies, or liability that cannot lawfully be excluded. To the maximum extent the law permits, the developer is not responsible for indirect loss, loss of data caused by device failure or user action, or decisions made from estimates; this does not limit liability where such a limitation is unlawful, including liability that cannot be excluded for intentional misconduct or personal injury caused by negligence where applicable.

10. Changes, governing law, and acceptance
This notice may change when the product or law changes. The current version and effective date appear above; material changes should be presented in the app before they take effect where required. The app asks you to scroll through this notice, check the agreement box, and select “Start your journey” before first use. Your acceptance is stored locally with this notice version and date. You can stop using the app if you do not agree. Nothing here selects a governing law or court; mandatory consumer and privacy protections in your jurisdiction continue to apply. A release intended for the public should add a developer legal identity, contact address, jurisdiction-specific rights and procedures, and a lawyer-reviewed version before launch.
''';

  static const _ja = '''
食誌 / ShyokuShi — プライバシー通知および利用規約
施行日：2026年10月9日 · バージョン1

ご利用前にお読みください
本通知は、現在のスターターアプリの実装に基づく製品説明です。弁護士の意見、特定の法律の適用・不適用を保証するもの、または地域に応じた法律相談の代わりではありません。プライバシーや健康アプリに関する義務は、開発者、利用者、データの流れ、提供地域などによって異なる場合があります。一般公開や商用配布の前に、専門家による確認を受け、アプリや外部サービスが変更されたときは通知も更新してください。

1. 運営者と連絡方法
食誌はNekoが制作する個人向けの食事・栄養記録アプリです。この版には利用者アカウントや、開発者が運営する日記サーバーはありません。ソースコードと公開連絡窓口は https://github.com/neko7123 にあります。GitHubの課題投稿は公開されることがあります。氏名、健康情報、バックアップ、個人情報が写った画面などを投稿しないでください。一般公開や商用提供に必要な場合は、開発者の法的な氏名・所在地・正式なプライバシー連絡先を追加してください。

2. 保存される情報
食品名、食事名、日時、量、栄養値、メモ、添付写真、体重、身体プロフィール、目標、国、言語、表示設定およびアプリ設定は、端末内のデータベースまたはアプリ専用ファイルに保存されます。プロフィールには年齢、身長、体重、活動量、体重目標が含まれることがあります。これらは機微情報、または適用法上の健康関連個人情報に該当する場合があります。アカウントは不要です。この版はクラウドアカウント、同期、広告、分析、食品認識を提供しません。

Androidでは日記データベースと写真をアプリ専用領域に保存します。通常の他アプリからのアクセスをOSのサンドボックスが制限しますが、アプリ独自の暗号化を意味せず、マルウェア、ロック解除済み・侵害された端末、フォレンジック、OSの欠陥、端末にアクセスできる人から保護する保証ではありません。端末暗号化と画面ロックはOSと利用者の管理対象です。Web版ではブラウザーのサイト領域に保存され、ブラウザーデータ削除で消える場合があります。アプリの削除や保存領域の消去により日記が失われることがあります。

3. オンライン検索と外部提供者
利用者が食品を検索すると、検索語と通常の通信情報（IPアドレス、時刻、アプリまたはブラウザーの通信メタデータ等）が外部食品データサービスに送信されます。Open Food Factsの地域別・世界向け検索、およびUSDA FoodData Centralを利用する場合があります。国の設定は地域の商品カタログ選択に利用されますが、政府発行・承認のデータ、国内での適用性、または政府の食品成分表利用を保証しません。結果の有無、正確さ、利用条件、プライバシー対応は各提供者が管理し、独自の方針で検索記録を保持することがあります。検索語に氏名、住所、診断名などの機微情報を入力しないでください。USDAキーはビルド時に設定できますが、公開デモキーには厳しい制限があり得ます。検索は失敗したり、不完全だったり、結果がなかったりすることがあります。

現在、食品検索で日記、プロフィール、メモ、添付写真を外部提供者に送信しません。この説明は現在のコードに関するものであり、今後クラウド、広告、分析、クラッシュ報告、AI機能などを追加する際は見直しが必要です。外部サービスにはそれぞれの利用規約とプライバシー通知が適用され、このアプリはそれらを管理しません。

4. 栄養・体重・BMIおよび医療上の免責
食誌は記録と一般的な健康習慣のためのツールです。医療機器・医療サービスではなく、疾患の診断、治療、治癒、予防、監視を行いません。医学、栄養療法、臨床、緊急対応、個別専門家の助言を提供しません。カロリーや栄養値は欠落、丸め、古さ、表示誤り、レシピや調理状態の違い、誤った食品との紐付けがあり得ます。量は利用者が入力します。写真から食品やグラム数は判定しません。計算、目標、体重予測、BMIは記録用の推定値です。BMIは限定的なスクリーニング指標であり、診断でも健康全体の指標でもありません。臨床家、管理栄養士、医薬品表示、検査結果、公的な食品安全情報の代わりにはなりません。

本アプリだけを根拠に食事、薬、治療、運動を開始・中止・変更しないでください。個別の栄養、妊娠、アレルギー、摂食障害の懸念、病気、大幅な体重変化については有資格の医療専門家に相談してください。緊急時は地域の緊急窓口へ連絡してください。子ども・青少年には特別な配慮が必要で、成人用BMI区分やカロリー式が適さない場合があります。表示値を利用する前に妥当性を判断する責任は利用者にあります。

5. 写真と権限
写真はOSのカメラまたは写真ピッカーから選択され、アプリのローカル写真領域にコピーされます。選択した画像へのアクセスと、撮影を選んだ場合のカメラ利用が必要です。現在、写真をアップロード・解析しません。写真に顔、位置、端末メタデータなどが含まれることがあります。選択には注意してください。バックアップには書き出し時点で存在する写真データが含まれます。

6. 書き出し、読み込み、暗号化
書き出しバックアップは日記、プロフィール、設定、体重履歴、利用可能な写真を含む暗号化ファイルです。対応AndroidではDownloads/ShyokuShiに保存されます。書き出し後、ランダムな10文字の鍵を表示します。復元にはこの鍵が必要です。正確に控え、バックアップとは別の場所に保管してください。ファイルと鍵の両方を持つ人は内容を読めます。紛失した鍵は復元できません。10文字の鍵は長いパスフレーズより入力ミスしやすく、強度も低くなります。このバックアップ専用にし、他サービスで再利用せず、端末とファイルを安全に保管してください。暗号化はリスクを下げますが、画面に表示された鍵、侵害端末、他アプリが作った非暗号化コピーを保護しません。

読み込みではファイルを先に選択し、鍵を入力します。読み込みは現在の日記、プロフィール、設定、体重履歴、関連記録を選択バックアップで置き換えます。必要なら事前に別バックアップを作成してください。不要なコピーはDownloads、メッセージ、クラウド、受信者端末から利用者自身が削除してください。旧形式の非暗号化JSONを互換性のため読み込める場合がありますが、暗号化バックアップと同じ機密性はありません。送信元を確認し、信頼できないファイルを読み込まないでください。

7. 保存期間、削除、利用者の選択
アプリ内で記録を編集・削除し、コピーを書き出し、利用を中止できます。この版には開発者が遠隔で日記を取得・削除するアカウント画面やサーバーがありません。ローカル記録は利用者が削除するか、アプリ保存領域を消すか、アプリをアンインストールするまで残ることがあります。アプリ外のバックアップやコピーは別の場所に残る場合があります。OSのバックアップ、端末移行、ファイル管理アプリ、共有先、ブラウザーのバックアップはOS設定と利用者が管理します。端末の譲渡・廃棄前に端末固有の初期化とバックアップ機能を利用してください。アクセス、訂正、消去、処理制限、異議申立て、移転、監督機関への苦情などの権利は、所在地と開発者の法的立場により適用範囲や手続が異なります。問い合わせはGitHub経由で行えますが、公開課題に個人データを含めないでください。

8. セキュリティと事故
アプリ専用保存領域と暗号化書き出しを使いますが、SQLiteの日記データベース自体はアプリ固有鍵で別途暗号化されていません。ソフトウェアや通信に完全な安全はありません。画面ロックを有効にし、OSを更新し、鍵を共有せず、鍵とバックアップを同じフォルダーに置かないでください。情報が漏れたと思われる場合、まず端末とコピーを保護し、機微情報を公開せずプロジェクト窓口へ連絡してください。本通知は法律上必要な事故報告義務を免除しません。

9. 利用規約
利用者は本規約と適用法に従い、個人的な食事・健康習慣の記録に本アプリを利用できます。入力情報の正確さ、検索候補の確認、食品表示の照合、バックアップの作成と保護、表示された推定値を使うかの判断は利用者の責任です。違法行為、アプリ妨害、権限のない他人のデータ閲覧、診断・治療としての利用は禁止します。誤りがけがを招く、または必要な受診を遅らせる状況で本アプリに依存しないでください。

本アプリ、計算、食品候補、利用可能性は、法律で認められる範囲で「現状有姿」「提供可能な範囲」で提供されます。継続稼働、計算の無誤謬、食品網羅性、特定の結果、全端末との互換性、失われた記録の復元を保証しません。外部食品データは各投稿者のものであり、適用ライセンスと表示条件に従います。データベースや画像を再配布する前に条件を確認してください。開発者は機能を変更・停止・終了する場合があります。法律上排除できない消費者権利、保証、救済、責任は制限しません。法律が許す最大範囲で、間接損失、端末故障・利用者行為によるデータ損失、推定値に基づく判断について責任を負いません。ただし、法律で許されない制限、故意の不正行為や、適用法上免責できない過失による人身損害等は除きます。

10. 変更、準拠法、同意
製品や法律の変化に応じて通知を更新する場合があります。現行版と施行日は冒頭に表示されます。重要な変更は、法令が求める場合、発効前にアプリ内で通知します。初回利用では本通知を最後までスクロールし、同意欄を選び、「利用を開始」を押します。同意した版と日付は端末内に保存されます。同意しない場合は利用を中止できます。本通知は特定の準拠法や裁判所を選択せず、居住地の強制適用される消費者・プライバシー保護を変更しません。一般公開前に、開発者の法的主体、連絡先、地域別権利と手続、弁護士が確認した文書を追加してください。
''';

  static const _zh = '''
食誌 / ShyokuShi — 隐私说明与使用条款
生效日期：2026年10月9日 · 版本1

使用前请阅读
本文描述当前入门版应用的实际功能，是产品说明，不是律师意见，不保证任何法律一定适用或不适用，也不能替代针对所在地的法律咨询。隐私和健康应用义务可能取决于开发者、用户、数据流向和应用提供地区。公开发布或商业分发前，应由合格法律专业人士审阅；应用或服务商发生变化时，也应更新说明。

1. 运营者与联系
食誌是由Neko制作的个人饮食和营养记录应用。此版本没有用户账户，也没有由开发者运营的云端日记服务。源代码和公开联系渠道位于 https://github.com/neko7123。GitHub问题帖可能公开展示。请勿在那里发布姓名、健康信息、备份文件、含个人信息的截图或其他机密资料。若公开或商业发布依法需要，应补充开发者的法律身份、地址和正式隐私联系信息。

2. 应用保存的信息
食品名称、餐次、日期和时间、克数、营养数值、备注、附加照片、体重记录、身体资料、目标、国家、语言、外观和应用偏好保存在本地数据库或应用私有文件中。资料可能包含年龄、身高、体重、活动水平和体重目标。这些信息可能属于敏感信息或相关法律定义的健康个人信息。使用应用无需账户。此版本没有云端账户、同步、广告、分析或食品识别服务。

Android会把日记数据库和照片保存在应用私有空间。操作系统沙箱限制普通其他应用访问，但这并不等于应用另行加密，也不能保证免受恶意软件、设备被破解或解锁、取证访问、操作系统缺陷或能接触设备的人侵害。设备加密和屏幕锁由设备及用户设置管理。Web版本保存在浏览器站点存储中，清理浏览器数据可能删除内容。卸载应用或清除其存储也可能删除日记。

3. 在线搜索和第三方
当您主动搜索食品时，搜索词和网络请求的普通技术信息（例如IP地址、时间以及应用或浏览器网络元数据）会发送给外部食品数据服务。应用可能查询Open Food Facts的地区或全球目录，以及USDA FoodData Central。国家设置用于选择地区商品目录；它不保证结果由该国政府发布或认可，不保证适合当地使用，也不表示使用了政府食品成分表。结果、准确度、服务条款和隐私做法由服务商控制，服务商可能依其政策记录请求。请勿在搜索词中输入姓名、地址、诊断或其他敏感信息。USDA密钥可在构建时配置；公共演示密钥可能有严格限制。搜索可能失败、不完整或没有结果。

当前食品搜索不会把日记条目、资料、备注或照片发送给这些服务商。此说明仅对应当前代码；将来若加入云服务、广告、分析、崩溃报告或人工智能功能，应重新审查。第三方服务适用各自的条款和隐私说明，本应用无法控制这些服务。

4. 营养、体重、BMI和医疗免责声明
食誌是记录和一般健康习惯工具，不是医疗器械或医疗服务，不诊断、治疗、治愈、预防或监测疾病，也不提供医疗、营养治疗、临床、急救或个人专业建议。热量和营养数值可能缺失、经过舍入、过时、标记错误、基于不同食谱或烹调状态，或与错误食品匹配。份量由用户输入；照片不会识别食物或推断克数。计算、目标、体重预测和BMI仅为记录估算。BMI是有限的筛查指标，不是诊断，也不全面反映健康。应用不能替代医生、注册营养师、药品标签、实验室结果或官方食品安全建议。

请勿仅凭本应用开始、停止或改变饮食、药物、治疗或运动计划。对于个人营养需求、怀孕、过敏、饮食障碍担忧、疾病或明显体重变化，请咨询合格医疗专业人士。紧急情况请联系当地急救服务。儿童和青少年需要特别谨慎；成人BMI类别和成人热量公式并非适用于所有人。在依赖某项数值前，用户应自行判断其是否适用。

5. 照片和权限
照片通过操作系统相机或照片选择器选取，并复制到应用本地照片文件夹。应用只需访问您选中的图片；选择拍照时需要相机。当前不会上传或分析照片。照片可能暴露人脸、位置、设备元数据或其他个人信息，请谨慎选择。导出备份会包含导出时存在的照片内容。

6. 导出、导入和加密
导出会创建加密备份，包含日记条目、资料、偏好、体重记录和可用照片。在支持的Android版本中，文件保存在Downloads/ShyokuShi。导出完成后，应用显示随机生成的十字符密钥。恢复备份需要该密钥；请准确抄写并与备份分开保存。持有文件和密钥的人可以读取其中内容。密钥丢失后无法恢复。十字符密钥比长口令更容易输错且强度较低；仅用于此备份，不要在其他服务重复使用，并保护设备和文件。加密可降低暴露风险，但不能保护解锁屏幕上显示的密钥、被入侵设备或其他应用制作的未加密副本。

导入时先选择文件，再输入密钥。导入会以备份内容替换当前日记、资料、偏好、体重记录及相关记录。如可能需要当前数据，请先另行备份。Downloads、消息应用、云盘或接收者设备中的副本需由用户自行删除。为兼容旧版本，可能接受旧式未加密JSON文件；此类文件不具备加密备份相同的保密性。导入前请核实来源，不要导入不可信文件。

7. 保存期限、删除和您的选择
您可以在应用内修改或删除记录、导出副本并停止使用。此版本没有账户门户或远程日记服务器，开发者无法从远端检索或删除您的本地记录。记录通常会保留至您删除、清除应用存储或卸载应用；应用外的备份和副本可能仍在其他位置。系统备份、设备迁移、文件管理器、分享目标和浏览器备份由操作系统和您的设置管理。出售、借出或丢弃设备前，请使用设备自带的重置和备份功能。访问、更正、删除、限制处理、反对、数据携带或向监管机构投诉等权利，取决于所在地和开发者的法律身份。产品问题可通过GitHub联系，但不要在公开问题中附上私人日记信息。

8. 安全与事件
应用使用私有存储和加密导出文件，但SQLite日记数据库本身没有使用应用管理的密钥另行加密。没有软件或传输方式能保证绝对安全。请使用屏幕锁、更新系统、不要分享导出密钥，也不要把密钥和备份放在同一文件夹。如果怀疑数据泄露，请先保护设备和副本，再通过项目渠道联系，不要公开敏感信息。本说明不免除法律可能规定的事件通知义务。

9. 使用条款
您可以依本条款和适用法律将应用用于个人饮食及健康习惯记录。您负责所输入信息的准确性、核对搜索结果和食品标签、制作并保护备份，以及决定是否参考应用估值。不得利用应用违法、干扰运行、未经授权查看他人数据，或把结果当作专业诊断或治疗。在错误可能造成伤害或延误必要护理的情况下，不应依赖本应用。

在法律允许范围内，应用、计算、食品匹配和服务按“现状”和“可提供状态”提供。开发者不保证持续运行、计算无误、食品覆盖完整、取得特定结果、兼容所有设备或恢复丢失记录。外部食品数据属于各自贡献者，受相应许可和署名条件约束；再分发数据库内容或图片前，请核对许可。开发者可能更改、暂停或终止功能。本条款不排除法律禁止排除的消费者权利、保证、救济或责任。在法律允许的最大范围内，开发者不承担间接损失、设备故障或用户行为导致的数据损失，以及依据估算作出的决定所造成的责任；法律不允许限制的责任、故意不当行为或适用法律不能免责的过失人身损害责任除外。

10. 更新、法律和同意
产品或法律变化时，本说明可能更新；当前版本和生效日期列于开头。法律要求时，重要变更会在生效前通过应用通知。首次使用时，您需要滚动阅读本说明、勾选同意框并点击“开始使用”。应用在本地保存接受的版本和日期。不同意时可以停止使用。本说明不选择任何准据法或法院，也不改变您所在地强制适用的消费者和隐私保护。公开发布前应补充开发者法律身份、联系方式、地区权利及程序，并由律师审阅。
''';

  static const _ko = '''
食誌 / ShyokuShi — 개인정보 안내 및 이용 약관
시행일: 2026년 10월 9일 · 버전 1

사용 전에 읽어 주세요
이 안내는 현재 스타터 앱의 구현 상태를 설명하는 제품 안내입니다. 변호사의 의견이 아니며, 특정 법률이 적용되거나 적용되지 않는다고 보장하지 않고, 관할 지역별 법률 자문을 대신하지 않습니다. 개인정보 및 건강 앱 의무는 개발자, 이용자, 데이터 흐름, 제공 지역에 따라 달라질 수 있습니다. 공개 배포나 상업적 제공 전에 자격을 갖춘 전문가에게 검토받고, 앱이나 서비스 제공자가 바뀌면 안내도 갱신해야 합니다.

1. 운영자 및 연락 방법
食誌는 Neko가 만든 개인 식사 및 영양 기록 앱입니다. 현재 버전에는 사용자 계정이나 개발자가 운영하는 클라우드 일기 서비스가 없습니다. 소스와 공개 연락 경로는 https://github.com/neko7123 입니다. GitHub 이슈는 공개될 수 있으므로 이름, 건강 정보, 백업 파일, 개인정보가 포함된 화면 캡처 또는 기밀 정보를 게시하지 마세요. 공개 또는 상업 출시 전에 법에서 요구하는 경우 개발자의 법적 신원, 주소, 공식 개인정보 연락처를 추가해야 합니다.

2. 앱에 저장되는 정보
식품명, 식사명, 날짜와 시간, 섭취량, 영양값, 메모, 첨부 사진, 체중 기록, 신체 프로필, 목표, 국가, 언어, 화면 모드 및 앱 설정은 로컬 데이터베이스 또는 앱 전용 파일에 저장됩니다. 프로필에는 나이, 키, 체중, 활동 수준 및 체중 목표가 포함될 수 있습니다. 이러한 정보는 민감 정보 또는 관련 법률상 건강 관련 개인정보로 취급될 수 있습니다. 계정은 필요하지 않습니다. 이 버전은 클라우드 계정, 동기화, 광고, 분석 또는 음식 인식 기능을 운영하지 않습니다.

Android에서는 일기 데이터베이스와 사진을 앱 전용 저장 공간에 둡니다. 운영체제 샌드박스가 일반적인 다른 앱의 접근을 제한하지만, 앱 자체의 별도 암호화는 아니며 악성코드, 잠금 해제 또는 침해된 기기, 포렌식 접근, 운영체제 결함, 기기에 접근할 수 있는 사람으로부터 보호한다고 보장하지 않습니다. 기기 암호화와 화면 잠금은 운영체제 및 사용자가 관리합니다. 웹 버전은 브라우저 사이트 저장소에 보관되며 브라우저 데이터를 지우면 사라질 수 있습니다. 앱 삭제 또는 저장 공간 삭제도 로컬 일기를 지울 수 있습니다.

3. 온라인 음식 검색 및 제3자
사용자가 음식 검색을 선택하면 검색어와 일반적인 네트워크 요청 정보(IP 주소, 시간, 앱 또는 브라우저 네트워크 메타데이터 등)가 외부 음식 데이터 서비스로 전송됩니다. Open Food Facts의 지역 및 글로벌 카탈로그와 USDA FoodData Central을 조회할 수 있습니다. 국가 설정은 지역 상품 카탈로그 선택에 사용될 뿐, 결과가 해당 정부에서 발행·승인되거나 현지에 적합하거나 국가 식품성분표를 사용한다는 보장은 아닙니다. 결과, 정확도, 이용 조건 및 개인정보 처리 방식은 각 제공자가 관리하며 자체 정책에 따라 요청을 기록할 수 있습니다. 이름, 주소, 진단명 또는 기타 민감 정보를 검색어에 입력하지 마세요. USDA 키는 빌드 시 설정할 수 있으며 공개 데모 키에는 엄격한 한도가 있을 수 있습니다. 검색은 실패하거나 불완전하거나 결과가 없을 수 있습니다.

현재 음식 검색은 일기 항목, 프로필, 메모 또는 사진을 해당 제공자에게 보내지 않습니다. 이 설명은 현재 코드에 관한 것이며 향후 클라우드, 광고, 분석, 오류 보고 또는 AI 기능을 추가하면 다시 검토해야 합니다. 제3자 서비스에는 각자의 약관과 개인정보 안내가 적용되며 앱은 이를 통제하지 않습니다.

4. 영양, 체중, BMI 및 의료 면책
食誌는 기록과 일반적인 건강 습관을 위한 도구입니다. 의료기기 또는 의료 서비스가 아니며 질병을 진단, 치료, 완치, 예방 또는 감시하지 않습니다. 의료, 영양치료, 임상, 응급 또는 개인별 전문가 조언을 제공하지 않습니다. 열량과 영양값은 누락, 반올림, 오래된 정보, 잘못된 표시, 다른 레시피나 조리 상태 또는 잘못 연결된 음식에 근거할 수 있습니다. 섭취량은 사용자가 입력하며 사진이 음식이나 그램을 판별하지 않습니다. 계산, 목표, 체중 예상 및 BMI는 기록용 추정치입니다. BMI는 제한적인 선별 지표일 뿐 진단이나 건강 전체를 나타내는 값이 아닙니다. 의료인, 등록 영양사, 의약품 라벨, 검사 결과 또는 공식 식품안전 안내를 대체하지 않습니다.

이 앱만을 근거로 식단, 약, 치료 또는 운동을 시작·중단·변경하지 마세요. 개인 영양, 임신, 알레르기, 섭식장애 우려, 질환 또는 큰 체중 변화는 자격 있는 의료 전문가와 상담하세요. 응급 상황에는 지역 응급 서비스에 연락하세요. 어린이와 청소년은 별도 주의가 필요하며 성인 BMI 기준과 성인 열량 공식이 모두에게 적절하지 않습니다. 수치에 의존하기 전에 적절성을 판단할 책임은 사용자에게 있습니다.

5. 사진과 권한
사진은 운영체제 카메라 또는 사진 선택기에서 선택되어 앱의 로컬 사진 폴더로 복사됩니다. 선택한 사진에 대한 접근과 사진 촬영을 선택했을 때의 카메라 사용이 필요합니다. 현재 사진을 업로드하거나 분석하지 않습니다. 사진에는 얼굴, 위치, 기기 메타데이터 또는 기타 개인정보가 포함될 수 있으므로 신중하게 선택하세요. 백업에는 내보내기 시점에 존재하는 사진 데이터가 포함됩니다.

6. 내보내기, 가져오기 및 암호화
내보내기는 일기 항목, 프로필, 설정, 체중 기록 및 이용 가능한 사진을 포함하는 암호화 백업을 만듭니다. 지원되는 Android에서는 Downloads/ShyokuShi에 저장됩니다. 완료 후 앱이 무작위 10자 키를 표시합니다. 복원에는 이 키가 필요하므로 정확히 적어 백업과 별도로 보관하세요. 파일과 키를 모두 가진 사람은 내용을 읽을 수 있습니다. 키를 잃으면 복구할 수 없습니다. 10자 키는 긴 암호문보다 오타가 쉽고 강도가 낮으므로 이 백업 전용으로 사용하고 다른 서비스에서 재사용하지 말며 기기와 파일을 안전하게 보관하세요. 암호화는 노출 위험을 줄이지만 잠금 해제 화면에 보이는 키, 침해된 기기 또는 다른 앱이 만든 평문 사본을 보호하지 않습니다.

가져오기는 먼저 파일을 고른 뒤 키를 입력합니다. 가져오면 현재 일기, 프로필, 설정, 체중 기록 및 관련 기록이 선택한 백업으로 교체됩니다. 현재 데이터가 필요할 수 있으면 먼저 별도 백업을 만드세요. Downloads, 메시지 앱, 클라우드 드라이브 또는 수신자 기기에 만들어진 사본은 사용자가 직접 삭제해야 합니다. 이전 버전 호환을 위해 암호화되지 않은 구형 JSON을 읽을 수 있지만 암호화 백업과 같은 기밀성이 없습니다. 출처를 확인하고 신뢰할 수 없는 파일을 가져오지 마세요.

7. 보관, 삭제 및 사용자의 선택
앱 안에서 기록을 수정하거나 삭제하고 복사본을 내보내거나 사용을 중단할 수 있습니다. 현재 버전에는 개발자가 원격으로 로컬 일기를 검색하거나 지울 계정 포털이나 서버가 없습니다. 로컬 기록은 삭제, 앱 저장 공간 삭제 또는 앱 제거 전까지 남을 수 있으며 앱 밖의 백업은 다른 위치에 계속 남을 수 있습니다. 운영체제 백업, 기기 이전, 파일 관리자, 공유 대상, 브라우저 백업은 운영체제와 사용자 설정이 관리합니다. 기기를 판매·대여·폐기하기 전 기기 자체의 초기화와 백업 설정을 사용하세요. 열람, 정정, 삭제, 처리 제한, 이의 제기, 이동, 감독기관 신고 등의 권리는 거주 지역과 개발자의 법적 역할에 따라 달라집니다. 제품 문의는 GitHub로 할 수 있지만 공개 이슈에 사적인 일기 데이터를 넣지 마세요.

8. 보안 및 사고
앱 전용 저장소와 암호화 내보내기를 사용하지만 SQLite 일기 데이터베이스 자체는 앱 관리 키로 별도 암호화되지 않습니다. 어떤 소프트웨어나 전송도 완전히 안전하다고 할 수 없습니다. 화면 잠금을 사용하고 운영체제를 업데이트하며 키를 공유하지 말고 키와 백업을 같은 폴더에 두지 마세요. 정보가 노출되었다고 생각되면 먼저 기기와 사본을 보호한 다음 민감한 내용을 공개하지 않고 프로젝트 연락 경로를 이용하세요. 이 안내는 법에 따른 사고 통지 의무를 면제하지 않습니다.

9. 이용 약관
사용자는 본 약관과 적용 법률에 따라 개인 식사 및 건강 습관 기록용으로 앱을 사용할 수 있습니다. 입력 정보의 정확성, 검색 결과 확인, 식품 라벨 확인, 백업 생성과 보호, 표시된 추정치를 이용할지 여부는 사용자 책임입니다. 법 위반, 앱 운영 방해, 허가 없이 다른 사람의 데이터에 접근, 결과를 전문 진단이나 치료로 취급하는 행위는 금지됩니다. 오류가 부상을 일으키거나 필요한 진료를 늦출 수 있는 상황에서 앱에 의존하지 마세요.

법률이 허용하는 범위에서 앱, 계산, 음식 검색 결과, 이용 가능성은 “있는 그대로” 및 “제공 가능한 상태”로 제공됩니다. 개발자는 중단 없는 운영, 오류 없는 계산, 완전한 음식 목록, 특정 결과, 모든 기기 호환성 또는 잃어버린 기록 복원을 보장하지 않습니다. 외부 식품 데이터는 각 기여자에게 귀속되며 해당 라이선스와 출처 표시 조건을 따릅니다. 데이터베이스나 사진을 재배포하기 전에 조건을 확인하세요. 개발자는 기능을 변경·중단·종료할 수 있습니다. 법률상 배제할 수 없는 소비자 권리, 보증, 구제 또는 책임을 배제하지 않습니다. 법이 허용하는 최대 범위에서 간접 손실, 기기 고장이나 사용자 행동으로 인한 데이터 손실, 추정치에 따른 판단에 대한 책임을 지지 않지만, 법률상 허용되지 않는 제한, 고의적 위법행위 또는 면책할 수 없는 과실로 인한 신체 손해 등은 제외됩니다.

10. 변경, 준거법 및 동의
제품 또는 법률이 바뀌면 이 안내를 수정할 수 있습니다. 현재 버전과 시행일은 위에 표시됩니다. 법이 요구하는 경우 중요한 변경은 시행 전에 앱에서 안내합니다. 첫 사용 전에 본 안내를 끝까지 스크롤하고 동의란을 선택한 뒤 “시작하기”를 눌러야 합니다. 동의한 버전과 날짜는 기기에 저장됩니다. 동의하지 않으면 사용을 중단할 수 있습니다. 이 안내는 특정 준거법이나 법원을 선택하지 않으며 거주 지역의 강행 소비자·개인정보 보호를 변경하지 않습니다. 공개 출시 전에는 개발자의 법적 신원, 연락처, 지역별 권리와 절차, 변호사 검토 문서를 추가하세요.
''';
}

class LegalConsentDialog extends StatefulWidget {
  const LegalConsentDialog({super.key, required this.language});
  final String language;

  @override
  State<LegalConsentDialog> createState() => _LegalConsentDialogState();
}

class _LegalConsentDialogState extends State<LegalConsentDialog> {
  final _scrollController = ScrollController();
  bool _readToEnd = false;
  bool _agreed = false;

  String _label(String en) => switch ((widget.language, en)) {
    ('ja', 'Privacy & terms') => 'プライバシーと利用規約',
    ('ja', 'I have read and agree to the privacy notice and terms.') =>
      'プライバシー通知と利用規約を読み、同意します。',
    ('ja', 'Scroll to the end to enable agreement.') =>
      '最後までスクロールすると同意欄が有効になります。',
    ('ja', 'Start your journey') => 'はじめる',
    ('zh', 'Privacy & terms') => '隐私与使用条款',
    ('zh', 'I have read and agree to the privacy notice and terms.') =>
      '我已阅读并同意隐私说明和使用条款。',
    ('zh', 'Scroll to the end to enable agreement.') => '滚动到末尾后即可勾选同意。',
    ('zh', 'Start your journey') => '开始使用',
    ('ko', 'Privacy & terms') => '개인정보 및 이용 약관',
    ('ko', 'I have read and agree to the privacy notice and terms.') =>
      '개인정보 안내와 이용 약관을 읽고 동의합니다.',
    ('ko', 'Scroll to the end to enable agreement.') =>
      '끝까지 스크롤하면 동의 항목이 활성화됩니다.',
    ('ko', 'Start your journey') => '시작하기',
    (_, _) => en,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 24 &&
          !_readToEnd) {
        setState(() => _readToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      title: Text(_label('Privacy & terms')),
      content: SizedBox(
        width: 560,
        height: MediaQuery.sizeOf(context).height * .62,
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(right: 12),
                  child: SelectableText(LegalDocuments.text(widget.language)),
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreed,
              onChanged:
                  _readToEnd
                      ? (value) => setState(() => _agreed = value ?? false)
                      : null,
              title: Text(
                _label(
                  'I have read and agree to the privacy notice and terms.',
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!_readToEnd)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _label('Scroll to the end to enable agreement.'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _agreed ? () => Navigator.pop(context, true) : null,
          child: Text(_label('Start your journey')),
        ),
      ],
    ),
  );
}
