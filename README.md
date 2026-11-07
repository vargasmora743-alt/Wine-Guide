# Wine Guide 3.2

Production entry: `index.html`. The existing Supabase project, email/password sign-in, recovery, wine aliases, shared wine editor, and learning/service sections are preserved.

- Staff: Sommelier home, location specials, wine collection, grape and pairing browsing, read-only access.
- Owner/Manager: Executive Pro dashboard, catalog editing, reports, four locations, and location specials. Owner additionally manages existing employee profiles and roles.
- Olive, cream and gold palette. Special Cocktail is separate and available only in Union Square.
- Special wines are independent location records; removing one never deletes a shared wine.

## Run

`npm start` serves the existing root `index.html` on port 10000 (or `PORT`). `npm install` installs test dependencies. `npm test` runs DOM and HTTP-handler regression checks. `npm run test:browser` runs the optional browser suite after `npx playwright install chromium` (or set `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`).

## Supabase migration

Run `supabase/migrations/202611060001_location_specials.sql` in the existing project's SQL Editor before using specials and employee management. It extends the previously supplied `location_specials` schema with `kind`, enforces Union Square cocktails in PostgreSQL, and adds role policies and employee access protection. It does not replace wines or insert sample data. This repository change does not execute SQL remotely.

Review the current wines RLS policies before launch: active Staff SELECT only; active Owner/Manager SELECT/INSERT/UPDATE/DELETE. Existing wine policies are preserved by this migration. Existing staff profile SELECT for the signed-in user must remain enabled. Owner profile UPDATE also requires the existing authenticated table UPDATE grant. Sales metrics are not fabricated.

## Verification

Automated DOM checks use mocked Supabase responses, covering Staff/Manager/Owner, all four locations, Union Square-only cocktail visibility and writes, location removal, denied updates, account recovery, and the HTTP handler. The additional browser suite covers mobile overflow and captures temporary screenshots. Browser execution was blocked in the implementation environment, so visual/mobile verification remains pending. Live authentication and database RLS require the real Supabase project and migration; mocked tests do not verify server-side permissions.

Future changes should update this app and apply additive Supabase migrations, retaining the same repository and database.
