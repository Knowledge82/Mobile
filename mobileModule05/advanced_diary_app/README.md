# advanced_diary_app

Дневник с профилем-статистикой и календарём (Piscine Mobile, модуль 05: «Manage Data and Display»).
Один проект на два упражнения: ex00 (профиль: имя, выход, последние 2 записи, всего записей,
проценты по самочувствиям, новая запись) и ex01 (ежедневник: календарь и записи выбранного дня).

Проект продолжает [diary_app](../../mobileModule04/diary_app) из модуля 04 (по сабжу его копируют в новую
папку). Вход через Google и GitHub, база Firestore и правила безопасности остались прежними
(та же база, те же `firestore.rules`); изменились экраны.

- Разбор по слоям: [ex00](../../docs/05-ex00.md) (профиль, статистика, оболочка с вкладками),
  [ex01](../../docs/05-ex01.md) (календарь без сторонних пакетов, записи дня, сверка с сабжем).
- Настройка Firebase, вход, Firestore: в разборах модуля 04 ([ex00](../../docs/04-ex00.md), [ex01](../../docs/04-ex01.md)).

## Что нового по сравнению с модулем 04

    lib/
      logic/                     чистая логика без Flutter и базы
        diary_stats.dart           последние записи, проценты (метод наибольших остатков), записи за день
        calendar_math.dart         сетка месяца, сдвиг месяцев, дни в месяце
      ui/
        home_page.dart             оболочка: ОДНА подписка на записи, охранник, нижняя панель из двух вкладок
        profile_page.dart          вкладка «Профиль» (раньше: список всех записей)
        agenda_page.dart           вкладка «Ежедневник»
        month_calendar.dart        свой месячный календарь (table_calendar не используем: см. разбор 05-ex01)
        diary_actions.dart         создать / прочитать / удалить, общие для обеих вкладок
        entry_tile.dart            строка записи, общая для обеих вкладок
    test/                        + diary_stats_test, calendar_math_test, month_calendar_test, agenda_page_test;
                                   profile_page_test переписан

Записи по-прежнему лежат по пути `users/{uid}/entries/{id}` (`email`, `date`, `title`, `feeling`, `content`).

## Первый запуск (коротко; подробно в разборах)

    cd ~/Projects/Mobile/mobileModule05/advanced_diary_app
    flutter create --platforms=android,web --project-name advanced_diary_app .
    cd ~/Projects/Mobile
    PERMISSIONS=INTERNET tools/patch_android_manifest.sh mobileModule05/advanced_diary_app/android/app/src/main/AndroidManifest.xml
    tools/set_android_min_sdk.sh mobileModule05/advanced_diary_app/android/app/build.gradle.kts
    cd mobileModule05/advanced_diary_app
    flutterfire configure           # ТОТ ЖЕ проект Firebase; добавится НОВОЕ Android-приложение (другой applicationId)
    # в консоли Firebase: SHA-1 для нового Android-приложения (04-ex00, раздел 6.5)
    flutter pub get && flutter analyze && flutter test
    flutter run -d <устройство>

**Не копируйте `lib/firebase_options.dart` из модуля 04:** в нём идентификатор Android-приложения
`diary_app`, а у этого проекта другое имя пакета, и вход Google не заработает.

Всё написано **без запуска** (в среде подготовки нет Flutter, а pub.dev недоступен).
