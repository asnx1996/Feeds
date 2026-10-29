# رضعات سما — Baby feeding tracker

Family app for logging baby feedings (formula by bottle number or breastfeeding by minutes, who fed, time, note), with birth info, weekly weight/length tracking and a PDF report. Supports more than one child.
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
Migration `migrations/2026-10-19_children_growth_feed_type.sql` adds:
- `public.children` (name, sex girl/boy, birth_at, birth_weight_g, birth_length_cm, birth_head_cm, delivery_type natural/csection, gestation_weeks, hospital, blood_type, notes).
- `public.growth` (child_id, measured_on date, weight_g, length_cm, head_cm, note).
- `feeds.child_id`, `feeds.feed_type` ('formula' | 'breast'), `feeds.duration_min`, `feeds.breast_side` ('right'|'left'|'both'); `amount_ml` is now nullable (breast feeds have no ml).
The migration must be run in Supabase before deploying the matching `index.html`.
Feeds saved before children existed (`child_id` null) are linked to the first child created in setup (`store.feeds.adopt`).
Realtime enabled (`supabase_realtime` publication) on feeds, children and growth so both phones sync live.
The app loads the current child's last 30 days of feeds (max 500 rows) and all their growth rows.
Both parents sign in with ONE shared family account (email + password, created in Supabase Auth).
Any schema change goes in a new SQL file / migration — never edit `schema.sql` or data by hand in code.

## App behaviour
- First run (no children): `#setupView` step 1 = names + girl/boy (can add several children), step 2 = birth info per child. Birth date/time is required, the rest optional. The same view is reused for "+ طفل" (add) and "عدّل معلومات الولادة" (edit, step 2 only).
- Child switcher chips under the header (`sama_child` in localStorage). Title becomes "رضعات {name}"; "منو أعطاها/أعطاه" follows the child's sex.
- Tabs: الرضعات / التقارير (`sama_page`). Reports page: child card (age, birth info, last weight), weekly weighing hint, weight-by-age SVG chart, growth list (tap to edit, tap-twice delete), 7-day feeding averages, and "طلّع تقرير PDF" which fills `#printReport` and calls `window.print()` (print CSS hides everything else).
- Settings (gear next to the theme switch): amounts shown/entered either by bottle number or in ml, never both (`sama_unit` = 'number' | 'ml', per device, default number). Data is always stored in ml; the PDF report always uses ml.
- Feed sheet: type صناعي/طبيعي. Formula amount is picked by the number on the bottle (1 = 30 ml, `ML_PER_UNIT`) or "غير" in ml. Breastfeeding = minutes + side, no amount, given_by = ماما. The old formula-number field was removed from the UI (column kept).- Add, edit and delete feeds. Tap a history entry to open the sheet in edit mode (`editingId`); title becomes "تعديل الرضعة".
- New-feed sheet remembers the last type / bottle number / minutes / side / who in localStorage `sama_prefs`.
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
- Wallet card (byllzz), reshaped as a baby bag (`.bag`) → today's summary; bag front = total ml + count + breast minutes + time since last feed; 3 cards = last 3 feeds; tap toggles `.open` and the cards rise fully out of the bag.
- Sun/moon switch (Galahhad) → theme; forced `direction: ltr`; saved in localStorage `sama_theme`.
- Back-to-top + delete button (vinodjangid07) → delete is tap-twice ("احذف؟" then delete).
- Toast (akshat-patel28) → "انسجلت الرضعة" with an Undo (تراجع) button.
- Time wheel (CodeFronts full-circle-wheel) → feed time. Tap the time button → wheel goes hour → minute (5-min stops, −/+ for 1 min) → day (last 7 days) and closes. The hidden `#feedTime` datetime-local input still holds the value; call `timeSync()` after setting it in code.
- Custom amount/minutes ("غير") use a −/+ stepper (`.stepper`, hold to repeat); the number can still be typed.

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
`ML_PER_UNIT = 30`, `UNITS = [1,2,3,4,5]`, `DURATIONS = [5,10,15,20,30]`, `GIVERS = ['ماما','بابا','غيرهم']`.
Demo mode localStorage keys: `sama_feeds_v1`, `sama_children_v1`, `sama_growth_v1`.

## Ideas for next versions
- Reminder after X hours since last feed (notification).
- Undo for delete (like the toast after adding).
- Weekly chart of daily totals.
- Extra logs: diapers, sleep, medicine.
- Delete a child.
- Formula tin tracking (opened date, running low).
- Export history (PDF/CSV) for the doctor.
