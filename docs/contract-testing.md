# Перевірки API-контракту

## Результати

Результати нижче надані користувачем; у межах цього документаційного проходу Redocly та Prism повторно не запускалися.

| Перевірка | Команда / запуск | Результат |
|---|---|---|
| OpenAPI lint | `npx @redocly/cli@latest lint api/openapi.yaml --extends=minimal` | OpenAPI 3.0.3 — VALID; 0 errors; 56 warnings. |
| Prism mock | `npx @stoplight/prism-cli@latest mock api/openapi.yaml` | Successfully started at `http://127.0.0.1:4010`. |
| Smoke test | `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\contract\prism-smoke.ps1` | 14 PASS; 0 FAIL; 14 total. |

Smoke-сценарії з `tests/contract/prism-smoke.ps1`:

- `GET /appointment-slots`: відсутній bearer, валідний запит, некоректна й відсутня дата;
- `GET /pets`: відсутній bearer;
- `POST /pets`: порожнє некоректне тіло й валідне синтетичне тіло (HTTP 201);
- `POST /appointments`: порожнє некоректне тіло й валідне синтетичне тіло (HTTP 201; Prism-заголовок `Prefer: code=201`);
- `GET /pets/pet-1/medical-records`: відсутній bearer;
- `GET /pets/pet-smoke-1/medical-records`: bearer-запит (HTTP 200);
- `GET /recommendations`: запит із bearer;
- `POST /recommendations`: порожнє некоректне тіло;
- `POST /auth/client-sessions`: порожнє некоректне тіло.

## Попередження Redocly

Усі 56 warnings належать до `no-required-schema-properties-undefined` у композиційних схемах з умовними `required`. Ці попередження стосуються структури `oneOf`/`allOf`; вони не були усунені видаленням умов або переліків обов’язкових полів. Сам факт валідності OpenAPI не підтверджує, що backend реалізує ці умовні обмеження.

## Межі доказу

Prism smoke підтверджує лише окремі HTTP-відповіді mock-сервера для перевірених запитів. Він не перевіряє реальне виконання бізнес-правил, збереження даних, авторизацію за ролями, конкурентні операції чи інтеграції.

Для `POST /auth/client-sessions` сценарій `Client login: invalid body` очікує HTTP 422, який Prism повертає під час валідації тіла. Операція не описує окрему відповідь 422 у OpenAPI; цей результат не є підтвердженою відповіддю контракту чи backend-вимоги.

## API-GATE

У перевірених документах `docs/` окремих критеріїв під назвою API-GATE не знайдено. У `docs/planning/implementation-plan.md` визначено критерії G03 Integrity Gate: серед іншого, потрібні релевантні результати T01–T04, INT-AUTH, INT-PET, INT-APPT, INT-MED та докази наслідків станів, статусів і рекомендацій.

Виконано за наданими результатами:

- lint контракту: VALID, 0 errors;
- Prism smoke: 14 із 14 сценаріїв пройшли.

Для G03/API-GATE залишаються невиконаними або непідтвердженими:

- перевірка умовних обмежень і бізнес-правил на реальному backend;
- релевантні результати T01–T04 та інтеграційних наборів INT-AUTH, INT-PET, INT-APPT і INT-MED;
- інші докази G03 щодо наслідків станів, статусів і рекомендацій;
- окреме рішення Human GO/REVISE для G03.

Наявні lint і smoke-перевірки не закривають цей перелік і не є рішенням G03.
Статус G03: OPEN — Gate залишається відкритим до реалізації та відповідних перевірок backend; результати mock його не закривають.
