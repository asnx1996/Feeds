# رضعات سما — Baby feeding tracker

Family app for logging baby Sama's bottle feedings (amount in ml, formula number, who fed her, time, note).
Used mostly at night, one-handed, on phones — keep everything big, fast, and readable in dark mode.

## Stack
- Single file: `index.html` (vanilla HTML/CSS/JS, no build step, no framework).
- Hosted on GitHub Pages.
- Data: Supabase (`@supabase/supabase-js@2` from jsDelivr CDN).
  - Project URL: `https://vakelwjiktrbpsophlps.supabase.co`
  - Publishable key is in `index.html` (public by design; security comes from RLS).
- If `SUPABASE_URL` / `SUPABASE_ANON_KEY` are empty, the app runs in local demo mode (localStorage).

## Database (`schema.sql`)
Table `public.feeds`: `id uuid`, `user_id uuid default auth.uid()`, `fed_at timestamptz`,
`amount_ml int (1–1000)`, `formula_no text`, `given_by text`, `note text`, `created_at`.
RLS on: each authenticated user sees/edits only their own rows.
Realtime enabled (`supabase_realtime` publication) so both phones sync live.
Both parents sign in with ONE shared family account (email + password, created in Supabase Auth).
Any schema change goes in a new SQL file / migration — never edit data by hand in code.

## UI pieces (adapted from Uiverse.io, MIT — keep the credit comment in `<head>`)
- Star button (MuhammadHasann) → "رضعة جديدة"; stars burst on tap (class `.burst`), not hover.
- Segmented radios (00Kubi) → amount / formula / who. Each group has its own `name`.
- Wallet card (byllzz) → today's summary; pocket = total ml + count + time since last feed; 3 cards = last 3 feeds; tap toggles `.open`.
- Sun/moon switch (Galahhad) → theme; forced `direction: ltr`; saved in localStorage `sama_theme`.
- Back-to-top + delete button (vinodjangid07) → delete is tap-twice ("احذف؟" then delete).
- Toast (akshat-patel28) → "انسجلت الرضعة" with an Undo (تراجع) button.

## Conventions
- RTL, Arabic UI copy in Iraqi dialect (e.g. هسه، منو، ما كو). Western digits (`ar-IQ-u-nu-latn`).
- Colors only via CSS variables in `:root` and `:root[data-theme="dark"]`.
- No hover-only interactions; hover effects go inside `@media (hover:hover)`.
- Tap targets ≥ 44px. Respect `prefers-reduced-motion`.
- Wrap all localStorage access in try/catch (`safeGet` / `safeSet`).
- Make targeted changes only — don't rewrite or remove working logic outside the requested fix.
- Deliver complete, ready-to-use files.

## Settings in code
`AMOUNTS = [30, 60, 90, 120, 150]`, `FORMULAS = ['1','2','3']`, `GIVERS = ['ماما','بابا','غيرهم']`.

## Ideas for next versions
- Edit an existing feed (currently only add / delete).
- PWA: manifest + service worker so it installs like an app; reminder after X hours since last feed.
- Weekly chart of daily totals.
- Extra logs: diapers, sleep, medicine, weight/height.
- Formula tin tracking (opened date, running low).
- Export history (PDF/CSV) for the doctor.
