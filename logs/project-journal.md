# Журнал розвитку інформаційної системи «Ветеринарна клініка»

**Тип документа:** живий журнал рішень, перевірок і переходів між етапами розвитку продукту

**Дата останнього зафіксованого етапу:** 18.10.2026

**Поточний стан:** пакет планування реалізації D02 підготовлено й схвалено Human у робочому діалозі; формальне рішення G02 `GO / REVISE` ще не прийнято

## 1. Призначення журналу

Журнал зберігає фактичну історію розвитку інформаційної системи: джерела рішень, участь Agent і Human, зміни артефактів, результати перевірок, невідповідності та відкриті дії. Записи відновлено з Git history, актуальних GitHub Issues, планових документів, diff і доступної історії робочого діалогу.

Поточна детальна частина охоплює завершену підготовку пакета планування реалізації. Перехід до розробки залежить від окремого рішення G02. Розробка F01–F10, функціональні тести, validation і підготовка до випуску ще не виконувалися, тому журнал не містить вигаданих Red/Green результатів або Gate-рішень.

Журнал є процесним доказом D01 (#18), але сам по собі не закриває D01, D02, V02 або G02.

## 2. Етапи розвитку продукту

| Етап | Фактичний стан | Основний результат | Наступна контрольна точка |
|---|---|---|---|
| Аналіз і специфікація вимог | Завершено для baseline SRS v0.1 та ADD-001 | Затверджена SRS, історичний SPEC-GATE G01, ADD-001 без зміни стабільних REQ/AC/BDD | Використовувати baseline як межу подальших рішень |
| Планування реалізації | Пакет D02 підготовлено, технічно перевірено та схвалено Human у робочому діалозі | 25 Issues, traceability matrix, implementation plan, Gantt, risk register, planning audit V02 | Формальний запис Human у D02 #19; окреме рішення G02 `GO / REVISE` |
| Розробка та тестування | Не розпочато | Немає реалізаційних commit, Red/Green або integration evidence | Може початися лише після дозволеного переходу через G02 та готовності відповідних DEP |
| Валідація та підготовка до випуску | Не розпочато | VAL01, фінальний V02, G03/G04 evidence відсутні як виконані результати | Майбутні Human Review, G03, VAL01 і G04 за планом та фактичними доказами |

## 3. Нормативна й процесна основа

- [SRS v0.1](../spec/SRS_Vet_Clinic_v0.1.tex);
- [ADD-001](../spec/SRS_Vet_Clinic_v0.1_addendum_001.md);
- [SKED summary](sked-summary.md);
- [SPEC-GATE log](spec-gate.md);
- [правила Git workflow](../docs/git-workflow.md);
- [матриця простежуваності](../docs/planning/traceability.md);
- [план реалізації](../docs/planning/implementation-plan.md);
- [реєстр ризиків](../docs/planning/risk-register.md);
- [повторний аудит планової частини V02](../docs/planning/v02-planning-audit.md);
- [Issue #18 — D01](https://github.com/yanchiix/vet-clinic/issues/18).

Дати комітів наведено за Git history у часовому поясі `+03:00`. Для GitHub Issues збережено фактичні UTC timestamps там, де вони потрібні як доказ. Якщо точного часу Human-рішення немає, журнал подає лише достовірну дату й прямо позначає обмеження доказу.

## 4. Хронологія розвитку

### 4.1. Аналіз і специфікація вимог

| Дата | Відповідальний | Дії та причина | Результат | Докази |
|---|---|---|---|---|
| 02.10.2026 | Agent — аналіз і виправлення; Human — Review вимог | Опрацьовано блокуючі зауваження SPEC-GATE, уточнено припущення й перевірено специфікацію перед baseline. Метою було усунути неоднозначності до затвердження вимог. | Підготовлено переглянутий SRS draft і журнали перевірок. | Commits [`d2bb92b`](https://github.com/yanchiix/vet-clinic/commit/d2bb92bead8667599e458d783f47ea59c389e47e), [`bbdc09e`](https://github.com/yanchiix/vet-clinic/commit/bbdc09e70ca8c4d50968df5deae3dedbb2e47e4c), [`5166dd6`](https://github.com/yanchiix/vet-clinic/commit/5166dd6cbf95ed18180ec8555155bc019a44705d); [SKED summary](sked-summary.md); [SPEC-GATE log](spec-gate.md). |
| 03.10.2026, 15:21:10 +03:00 | Human — затвердження baseline; Agent — підготовка доказів | Після SPEC-GATE Human затвердив SRS baseline. G01 зберігається як історичний Gate аналізу й специфікації, а не як дозвіл на початок реалізації. | `SRS_Vet_Clinic_v0.1.tex` зафіксовано як baseline. | Commit [`f6a9589`](https://github.com/yanchiix/vet-clinic/commit/f6a95894fe1e08da6b6787a0d26e6bacaf653e6d), `gate: approve SRS baseline`. |
| 03.10.2026, 17:01:27 +03:00 | Agent — синхронізація артефактів; Human — погодження уточнення | Додано ADD-001 для уточнення застосування REQ-F-067 разом із REQ-F-062 без створення нових REQ/AC/BDD. | Baseline доповнено нормативним ADD-001; метадані SRS і SPEC-GATE синхронізовано. | Commit [`76cec12`](https://github.com/yanchiix/vet-clinic/commit/76cec123adb1afbf4353ff9756ee933bdb6c00b6), `spec: add SRS addendum and sync baseline metadata`; [ADD-001](../spec/SRS_Vet_Clinic_v0.1_addendum_001.md). |

### 4.2. Планування реалізації

| Дата | Відповідальний | Дії та причина | Результат | Докази |
|---|---|---|---|---|
| 17.10.2026 | Agent — первинна декомпозиція; Human — перевірка й рішення щодо структури | Вимоги згруповано у керовані tickets без створення окремого Issue для кожного REQ. Human уточнив різницю між start prerequisites і closure/integration verification, відокремив історичний G01 від G02, підтвердив Ticket ID у V02, додав D02 і погодив компактний набір. | Фінальна декомпозиція містить 25 Local ID: S01, A01, G01, T01–T04, F01–F10, D01–D02, V01–V02, VAL01, G02–G04. Зафіксовано workflow `Todo → In Progress → Review → Done`; Review, validation і Gate-рішення залишено Human. | [Issues #1–#25](https://github.com/yanchiix/vet-clinic/issues?q=is%3Aissue+sort%3Acreated-asc) створені між `2026-10-17T18:02:43Z` і `2026-10-17T18:05:10Z`. Human-рішення підтверджені робочим діалогом; окремого репозиторного файла з дослівним текстом первинного Review немає. |
| 17.10.2026, 21:34:38 +03:00 | Agent — технічна підготовка; Human — попереднє погодження змісту | Створено `docs/planning/traceability.md`, щоб пов’язати baseline із запланованими роботами й перевірками. | Збережено 95 REQ та нормативні REQ → AC → BDD; кожен рядок отримав планові Ticket ID. | Commit [`f04fd2e`](https://github.com/yanchiix/vet-clinic/commit/f04fd2efe1c1543575516f8fede3a186ee5b65cd), `docs: add Lab 3 ticket traceability matrix`. Назву commit відтворено без змін як історичний факт. |
| 17–18.10.2026 | Agent — технічне створення Issues; Human — погодження scope і дозволи | Створено 25 погоджених GitHub Issues без дублікатів. S01, A01 і G01 закрито як історичні артефакти; решту залишено відкритими. G03 уточнено для access/integrity evidence та ADD-001. | Кожен Issue має Local ID, label, Source requirements, AC/BDD, розділені dependencies, роль і Done when. G03 (#24) відкритий; `updated_at` — `2026-10-17T22:59:49Z`. | Актуальні [Issues #1–#25](https://github.com/yanchiix/vet-clinic/issues?q=is%3Aissue+sort%3Acreated-asc); [G03 #24](https://github.com/yanchiix/vet-clinic/issues/24). Окремого машинного журналу авторства GitHub API-операцій у репозиторії немає; розподіл Agent/Human підтверджений робочим діалогом. |
| 18.10.2026, 01:45:03 +03:00 | Agent — підготовка документів; Human — поетапне погодження моделі | Створено `implementation-plan.md` і `risk-register.md`; у матрицю додано десять погоджених зв’язків G03 (#24) для REQ-F-030–033 та REQ-F-067–072. Визначено одного Agent, окремий Human resource, відносні дні, INT-роботи, Gate і `BK-168H`. | Підготовлено пакет D02: етапи, start/closure dependencies, числовий Gantt, resource-constrained sequence, 12 traditional і 6 AI-specific risks, high-cost-of-failure controls. Сценарій: Agent 246 год, Human 37,5 год, горизонт 46 відносних робочих днів. | Commit [`10e051b`](https://github.com/yanchiix/vet-clinic/commit/10e051b0bc945a56e69a16b5539860d1014c13a6), `docs: add Lab 3 implementation plan and risk register`. Назву commit відтворено без змін. |
| 18.10.2026 | Agent — незалежний аудит; Human — розгляд зауважень | Виконано планову частину V02: звірено SRS/ADD-001, 95 рядків матриці, усі 25 Issues, D02, dependencies, Gate, Gantt, Human actions і ризики. | Початковий результат — `REVIEW REQUIRED`; виявлено V02-PA-01–05. До рішення Human автоматичних виправлень не виконувалося. | [V02 planning audit](../docs/planning/v02-planning-audit.md), розділи 2–4; актуальні Issue bodies; Git diff пакета D02. |
| 18.10.2026 | Human — рішення щодо scope виправлень; Agent — точкові зміни й повторна перевірка | Human погодив V02-PA-01–05. Agent змінив лише погоджені зв’язки й формулювання, додав Mermaid Gantt і повторив перевірки. | PA-01–05 опрацьовано. Підтверджено 95/95 REQ, незмінність AC/BDD, двосторонню простежуваність, ADD-001/G03, відсутність dependency cycles і нової функціональності. | [V02 planning audit](../docs/planning/v02-planning-audit.md); [G03 #24](https://github.com/yanchiix/vet-clinic/issues/24); commit [`d69899d`](https://github.com/yanchiix/vet-clinic/commit/d69899d51caa076dbf2bf835274897cb3992fe5c). |
| 18.10.2026 | Agent — технічна перевірка; Human — фінальний Review D02 | Числову таблицю Gantt зіставлено з Mermaid-діаграмою: 38 робіт, D0–D46, один Agent, окремий Human resource, паралельні G03/INT-OPS і validation-гілки. Human переглянув пакет і повідомив `APPROVE` у робочому діалозі. | D02 схвалено Human у діалозі. Рішення не є G02: GO і не змінює Issue/Project автоматично. Точний час Review у доступних доказах відсутній; достовірна дата — 18.10.2026. | [Implementation plan, розділ 11](../docs/planning/implementation-plan.md); [V02 planning audit, розділ 6](../docs/planning/v02-planning-audit.md); робочий діалог. Формальний коментар Human у [D02 #19](https://github.com/yanchiix/vet-clinic/issues/19) на момент запису не опубліковано. |
| 18.10.2026, 12:57:52 +03:00 | Agent — commit/push після прямого дозволу Human | Перевірено HEAD, status, staging, погоджений diff і `git diff --check`; до commit включено лише чотири planning-файли. Виконано fast-forward push без force, щоб не переписати сторонні зміни. | `origin/main` і локальний HEAD оновлено до `d69899d51caa076dbf2bf835274897cb3992fe5c`. Issues, Project statuses і Gate-рішення не змінювалися. | Commit [`d69899d`](https://github.com/yanchiix/vet-clinic/commit/d69899d51caa076dbf2bf835274897cb3992fe5c), `docs: resolve V02 planning audit findings`; Git history. |

### 4.3. Розробка та тестування

Етап не розпочато. F01–F10 і T01–T04 відкриті; підтверджених реалізаційних commit, Red, Green, refactoring або integration evidence немає.

### 4.4. Валідація та підготовка до випуску

Етап не розпочато. G03, VAL01, завершальний V02 і G04 залишаються майбутніми контрольними роботами. Умовні Gate outcomes у planning model не є фактичними рішеннями.

## 5. Ключові рішення планування

| Рішення | Причина | Відповідальний за остаточне рішення | Доказ |
|---|---|---|---|
| Згрупувати 95 REQ у 25 Issues | Зберегти керовану структуру робіт і не створювати окремий ticket для кожної вимоги | Human після пропозиції Agent | [Issues #1–#25](https://github.com/yanchiix/vet-clinic/issues?q=is%3Aissue+sort%3Acreated-asc), [traceability matrix](../docs/planning/traceability.md) |
| Залишити G01 історичним і створити окремий G02 | SPEC-GATE підтверджує baseline вимог, а PLAN-GATE має окремо оцінити готовність плану | Human | [G01 #3](https://github.com/yanchiix/vet-clinic/issues/3), [G02 #23](https://github.com/yanchiix/vet-clinic/issues/23) |
| Розділити start prerequisites і closure/integration verification | Не перетворювати майбутні інтеграційні докази на умови старту та не створювати взаємного очікування Done | Human після аналізу Agent | [Implementation plan, розділи 5–6](../docs/planning/implementation-plan.md) |
| Використовувати локальний Green як milestone | Дозволити наступній Agent-роботі використовувати перевірений механізм до повного інтеграційного закриття попереднього Issue | Human | [Implementation plan, розділ 7](../docs/planning/implementation-plan.md) |
| Планувати одного Agent і окремий Human resource | Відобразити реальне ресурсне обмеження сценарію та не планувати дві активні Agent-роботи одночасно | Human | [Implementation plan, розділи 3 і 13](../docs/planning/implementation-plan.md) |
| Виконувати чотири сценарії ADD-001 в INT-APPT | Основний доказ стосується зв’язку рекомендації з бронюванням; INT-MED має використати його без повторного effort | Human після source sanity-check | [Implementation plan, розділ 8](../docs/planning/implementation-plan.md), [risk register](../docs/planning/risk-register.md) |
| Відокремити `BK-168H` від робочих днів | REQ-NF-008 задає 168 календарних годин зберігання; очікування не є безперервною Agent-роботою | Human | [Implementation plan, розділ 10](../docs/planning/implementation-plan.md) |
| Обмежити G03 погодженим high-cost scope | Посилити перевірку доступу, медичних даних, критичних статусів і рекомендацій без розширення Gate на невказані REQ | Human | [G03 #24](https://github.com/yanchiix/vet-clinic/issues/24), [risk register](../docs/planning/risk-register.md) |
| Залишити Review, validation і Gate-рішення за Human | Не делегувати Agent прийняття критичних переходів або продуктового результату | Human | [D01 #18](https://github.com/yanchiix/vet-clinic/issues/18), G02–G04 |

## 6. Зауваження V02-PA-01–05

| ID | Виявлена невідповідність | Погоджене виправлення | Фактичний результат і доказ |
|---|---|---|---|
| V02-PA-01 | У Related AC / BDD Issue #24 бракувало BDD-030 для REQ-F-048 / AC-F-048. | Додати лише BDD-030 без зміни Title, label, state, Project status або інших розділів. | У [G03 #24](https://github.com/yanchiix/vet-clinic/issues/24) міститься `BDD-030–034`; Issue лишається відкритим. |
| V02-PA-02 | D01 (#18) не було у рядку REQ-DP-005, хоча Source requirements D01 охоплюють REQ-DP-003–006. | Додати D01 (#18) до REQ-DP-005 зі збереженням інших Ticket ID. | Виправлено в [traceability matrix](../docs/planning/traceability.md); commit [`d69899d`](https://github.com/yanchiix/vet-clinic/commit/d69899d51caa076dbf2bf835274897cb3992fe5c). |
| V02-PA-03 | A01 не був відображений у REQ-F-062 і REQ-F-067. | Додати A01 (#2) як історичний Addendum-ticket у два рядки. | Виправлено без зміни REQ/AC/BDD у [traceability matrix](../docs/planning/traceability.md). |
| V02-PA-04 | Планові документи містили застарілі твердження про версію матриці й майбутнє оновлення G03. | Посилатися на матрицю з того самого planning-пакета та описати фактичний стан Issue #24 і матриці. | Узгоджено `implementation-plan.md`, `risk-register.md` і Planning verification; commit [`d69899d`](https://github.com/yanchiix/vet-clinic/commit/d69899d51caa076dbf2bf835274897cb3992fe5c). |
| V02-PA-05 | Зведені risk-рядки можна було прочитати як повне Gate-покриття REQ-F-051–053. | Уточнити, що G03 у цій групі контролює REQ-F-046–050; не розширювати Gate. | Межу G03 уточнено в [risk register](../docs/planning/risk-register.md); REQ-F-051–053 залишено для T03/V01/VAL01. |

## 7. Розмежування відповідальності

| Роль | Підтверджені дії | Межі повноважень |
|---|---|---|
| Agent | Готував декомпозицію, GitHub-ready тексти, planning-документи, risk register і аудит; після дозволу технічно створював або оновлював артефакти; перевіряв traceability, dependencies, Gantt, diff і Git-стан. | Не приймає validation або Gate-рішення; не фіксує Human approval без прямого повідомлення; не додає функціональність поза baseline. |
| Human | Уточнював dependencies, додав D02, погодив workflow, ресурсну модель, Gantt, risks, G03 і PA-01–05; виконав фінальний Review D02 та повідомив `APPROVE`; самостійно контролює публікацію формального коментаря. | Лише Human приймає Review, validation і `GO / REVISE`. APPROVE D02 не дорівнює G02: GO. |
| Agent + Human | Працювали через послідовність proposal → Review → correction → recheck; Agent готував доказ, Human приймав або повертав результат. | D01 ведеться протягом наступних етапів і закривається лише за повного набору процесних доказів. |

## 8. Результати повторних перевірок

Ці результати стосуються документації та планової частини V02. Вони не є результатами розробки або функціонального тестування F01–F10.

| Перевірка | Результат |
|---|---|
| SRS ↔ traceability | 95 REQ у SRS і 95 рядків матриці; 0 розбіжностей AC/BDD |
| Issues ↔ matrix | 24 точні двосторонні відповідності; G04 (#25) — задокументований release-wide виняток |
| Актуальні Issues | Прочитано всі 25; Local ID, label, state, обов’язкові розділи й нормативні ID перевірено |
| ADD-001 | Чотири сценарії заплановано виконати в INT-APPT; INT-MED має використати evidence без повторного effort |
| G03 | Узгоджено control access, medical-record integrity, REQ-F-030–033, REQ-F-046–050 і рекомендацій у чинному scope |
| Gantt | 38 робіт; D0–D46; Agent 246 год; Human 37,5 год; ресурсних накладень і dependency cycles не виявлено |
| Git diff | Whitespace-перевірка пройдена; commit `d69899d` містить лише чотири погоджені planning-файли |
| Нова функціональність | Не додана; OPEN-003 і OPEN-006 збережено як обмеження baseline |

## 9. Поточний стан, відкриті питання та наступні дії

- **D02 (#19):** Human повідомив `APPROVE` у робочому діалозі 18.10.2026. Формальний коментар Human у GitHub ще не опубліковано; стан Issue на момент перевірки — `open`, кількість коментарів — `0`. Журнал не публікує рішення від імені Human і не змінює статус D02.
- **G02 (#23):** рішення `GO / REVISE` **ще не прийнято**. До рішення потрібно використати погоджений пакет D02, планову частину V02 і цей процесний доказ; APPROVE D02 не підміняє PLAN-GATE.
- **V02 (#21):** планова частина має технічний PASS; Issue залишається відкритим до фінального аудиту після розробки та перевірок.
- **D01 (#18):** Issue відкритий. Журнал охоплює analysis/specification і planning; майбутні TDD, Agent actions, Human Review, validation та Gate-рішення додаються після фактичного виконання.
- **F01–F10 і T01–T04:** відкриті, реалізація й тестування не починалися; Red/Green evidence відсутні.
- **DEP-001–005:** у базовому розкладі вважаються готовими до відповідних залежних робіт. Фактичну готовність потрібно перевірити перед стартом; невідомі затримки не оцінюються вигаданими числами.
- **OPEN-003 і OPEN-006:** залишаються обмеженнями baseline. Нова поведінка потребуватиме Human Review і, за потреби, Addendum.
- **Обмеження доказів:** точний час фінального Human Review D02 та постійний URL на робочий діалог недоступні. Дослівні prompts, непідтверджені commands і вигадані результати не включено.

## 10. Правило продовження журналу

Новий запис додається лише після появи фактичного доказу й містить:

1. дату та етап розвитку продукту;
2. Ticket ID і пов’язані REQ/AC/BDD;
3. відповідального Agent, Human або Agent + Human;
4. виконану дію та причину рішення;
5. посилання на commit, Issue, diff, test protocol або Gate evidence;
6. фактичний результат і наступну контрольну точку.

Для розробки й тестів додатково фіксуються очікуваний та фактичний Red, Green після реалізації й повторний Green після refactoring, якщо він був. Для Review, validation і Gate фіксуються пакет доказів, автор рішення Human і фактичний результат без автоматичного припущення.

Наступні записи очікуються після фактичної події: публікації Human-коментаря D02, рішення G02, старту дозволеної Agent-роботи або появи нового підтвердженого блокера. Порожні чи прогнозні записи не створюються.
