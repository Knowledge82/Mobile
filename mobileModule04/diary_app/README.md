# diary_app

Дневник с входом через Google или GitHub и хранением записей в Cloud Firestore
(Piscine Mobile, модуль 04: «Auth and Database»). Один проект на два упражнения:
ex00 (страница входа) и ex01 (профиль: список, создание, чтение, удаление).
Проект продолжится в модуле 05.

- Разбор по слоям: [ex00](../../docs/04-ex00.md) (вход, Firebase Auth, настройка облака),
  [ex01](../../docs/04-ex01.md) (Firestore, правила безопасности, работа без сети, аккаунт проверяющего).

## Как устроен код

    lib/
      main.dart                  единственное место, где создаются настоящие сервисы; нет Firebase -> экран-инструкция
      app.dart, app_services.dart   MaterialApp и пакет зависимостей (auth, diary, now)
      config.dart                пределы длины и срок ожидания сервера
      firebase_options.dart      ЗАГЛУШКА: заменяется командой flutterfire configure (не секретный, коммитится)
      models/                    AppUser, DiaryEntry/EntryDraft, Feeling (хранится именем)
      services/                  интерфейсы AuthService и DiaryRepository, их реализации на Firebase, entry_mapper
      ui/                        login_page, sign_in_page, profile_page, new_entry_dialog, entry_dialog, setup_error_page ...
    firestore.rules             правила безопасности (публикуются в консоли Firebase)
    assets/images/leaves.jpg    листва для первого экрана (рисует tools/make_leaves.py)
    test/                       подделки сервисов + тесты экранов, ошибок входа, переводчика записей

Записи лежат по пути `users/{uid}/entries/{id}` с полями `email`, `date` (timestamp), `title`,
`feeling` (имя значения: `satisfied`...), `content`.

## Первый запуск (коротко; подробно в разборах)

    cd ~/Projects/Mobile/mobileModule04/diary_app
    flutter create --platforms=android,web --project-name diary_app .
    cd ~/Projects/Mobile
    PERMISSIONS=INTERNET tools/patch_android_manifest.sh mobileModule04/diary_app/android/app/src/main/AndroidManifest.xml
    tools/set_android_min_sdk.sh mobileModule04/diary_app/android/app/build.gradle.kts
    cd mobileModule04/diary_app
    # облако: проект Firebase, вход Google и GitHub, база Firestore, правила, SHA-1 (04-ex00 раздел 6, 04-ex01 раздел 6)
    flutterfire configure
    flutter pub get && flutter analyze && flutter test
    flutter run -d <устройство>

Без `flutterfire configure` приложение запустится и покажет экран «Firebase is not configured».
Тесты от облака не зависят: они идут на подделках сервисов.

Всё написано **без запуска** (в среде подготовки нет Flutter, а pub.dev недоступен): настройку облака,
вход и работу без сети нужно проверить на телефоне.
