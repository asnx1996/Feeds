# رضعات سما — Baby feeding tracker

Family app for logging baby Sama's bottle feedings (amount in ml, formula number, who fed her, time, note).
Used mostly at night, one-handed, on phones — keep everything big, fast, and readable in dark mode.

## Stack
- Main app: `index.html` (vanilla HTML/CSS/JS, no build step, no framework).
- PWA files next to it: `manifest.webmanifest`, `sw.js`, `offline.html`, icons in `assets/`.
- Hosted on GitHub Pages.
- Data: Supabase (`@supabase/supabase-js@2.117.2` from jsDelivr CDN, pinned version).
  - Project URL: `https://vakelwjiktrbpsophlps.supabase.co`
  - Publishable key is in `index.html` (public by design; security comes from RLS).
- If `SUPABASE_URL` / `SUPABASE_ANON_KEY` are empty, the app runs in local demo mode (localStorage key `sama_feeds_v1`).
- If Supabase is configured but the library failed to load, the app shows `#errorView` instead of falling back to demo mode (so feeds never get saved on one phone only).

## Database (`schema.sql`)
Table `public.feeds`: `id uuid`, `user_id uuid default auth.uid()`, `fed_at timestamptz`,
`amount_ml int (1–1000)`, `formula_no text`, `given_by text`, `note text`, `created_at`.
RLS on: each authenticated user sees/edits only their own rows.
Realtime enabled (`supabase_realtime` publication) so both phones sync live; any change triggers `reload()`.
The app loads the last 30 days (max 500 rows).
Both parents sign in with ONE shared family account (email + password, created in Supabase Auth).
Any schema change goes in a new SQL file / migration — never edit `schema.sql` or data by hand in code.

## App behaviour
- Add, edit and delete feeds. Tap a history entry to open the sheet in edit mode (`editingId`); title becomes "تعديل الرضعة".
- New-feed sheet remembers the last amount / formula / who in localStorage `sama_prefs`.
- Toast after save: "انسجلت الرضعة" with Undo (new feeds only) or "انعدلت الرضعة" (no undo).
- Connection: `#netBanner` shows when offline or when loading fails, with a "جرّب" retry button. Reloads on `online` and when the tab becomes visible.
- Session expiry (`SIGNED_OUT`) returns to the login screen.
- Desktop: ≥768px the sheet becomes a centered dialog; ≥960px two columns (summary + button on the right, history on the left).

## PWA (`sw.js`)
- Cache name `sama-pwa-v1` — bump the version when cached files change.
- Caches only the offline page, manifest and icons. Navigation falls back to `offline.html` when there is no network.
- Never cache Supabase requests, auth, or feeding records.

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
- Escape user text with `esc()` before putting it in HTML.
- Make targeted changes only — don't rewrite or remove working logic outside the requested fix.
- Deliver complete, ready-to-use files.

## Settings in code
`AMOUNTS = [30, 60, 90, 120, 150]`, `FORMULAS = ['1','2','3']`, `GIVERS = ['ماما','بابا','غيرهم']`.

## Ideas for next versions
- Reminder after X hours since last feed (notification).
- Undo for delete (like the toast after adding).
- Weekly chart of daily totals.
- Extra logs: diapers, sleep, medicine, weight/height.
- Formula tin tracking (opened date, running low).
- Export history (PDF/CSV) for the doctor.
