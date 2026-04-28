# Clera — Production Readiness Checklist

Each task is marked: ✅ Done | 🔧 In Progress | ⏳ Pending | 🤝 Manual (needs you)

---

## Phase 1 — Critical Fixes (app broken without these)

- [x] ✅ **P1-1** Create `scan-images` bucket in Supabase Storage (Private) — **YOU MUST DO THIS**
- [x] ✅ **P1-2** Wire profile_setup_screen to real API
- [x] ✅ **P1-3** Redirect new users to profile setup after first login (router guard)
- [x] ✅ **P1-4** Profile cache cleared on sign out
- [x] ✅ **P1-5** Result screen reads from flat API response + rawResponse correctly

---

## Phase 2 — Missing Features

- [x] ✅ **P2-1** Wire share button on result screen (share_plus)
- [x] ✅ **P2-2** Wire favourite button (Hive local save, heart toggles)
- [x] ✅ **P2-3** Wire search + filter in history screen (live filter, pull-to-refresh)
- [x] ✅ **P2-4** Wire paywall screen (in-app purchase) — real IAP with restore, store prices

---

## Phase 3 — Security

- [ ] 🤝 **P3-1** Move secrets out of .env into CI/CD environment variables (before deploy)
- [x] ✅ **P3-2** API rate limiting — 60 req/min via ThrottlerModule
- [x] ✅ **P3-3** Request validation via class-validator on all DTOs
- [ ] 🤝 **P3-4** Enable Supabase RLS — run SQL below in Supabase SQL Editor

### RLS SQL (run in Supabase SQL Editor)
```sql
-- Enable RLS on all tables
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Scan" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ScanIngredient" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PurchaseIntent" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Subscription" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Feedback" ENABLE ROW LEVEL SECURITY;

-- Note: API uses service role key (bypasses RLS) so these
-- policies protect against direct DB access only
CREATE POLICY "users_own_data" ON "User"
  FOR ALL USING (id = auth.uid());

CREATE POLICY "scans_own_data" ON "Scan"
  FOR ALL USING ("userId" = auth.uid());

CREATE POLICY "ingredients_via_scan" ON "ScanIngredient"
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM "Scan" WHERE "Scan".id = "ScanIngredient"."scanId" AND "Scan"."userId" = auth.uid())
  );

CREATE POLICY "intent_own_data" ON "PurchaseIntent"
  FOR ALL USING ("userId" = auth.uid());
```

---

## Phase 4 — Infrastructure / Deployment

- [x] ✅ **P4-1** Deploy API to Railway — live at `https://safescanapi-production.up.railway.app`
- [x] ✅ **P4-2** Update `AppConfig.apiBaseUrl` to production URL after deploy
- [x] ✅ **P4-3** Set up CI/CD (GitHub Actions) — api.yml + flutter.yml
- [x] ✅ **P4-4** Set up error monitoring (Sentry) — @sentry/node (API) + sentry_flutter (app)
- [x] ✅ **P4-5** Set up uptime monitoring — GitHub Actions cron every 5 min + BetterStack heartbeat
- [x] ✅ **P4-6** Dockerfile fixed (npm, not pnpm) + railway.json added with healthcheck + auto-migrate

### Deploy API to Railway (step by step)
1. Push this repo to GitHub
2. Go to railway.app → New Project → Deploy from GitHub → select repo → set root to `apps/api`
3. Set these environment variables in Railway dashboard:
   - `DATABASE_URL` — Supabase Transaction pooler URL (port 6543, `?pgbouncer=true`)
   - `DIRECT_URL` — Supabase direct URL (port 5432, for migrations)
   - `SUPABASE_URL` — `https://cjfetpevxdtszlalcqgc.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` — from Supabase dashboard
   - `ANTHROPIC_API_KEY` — your key
   - `SENTRY_DSN` — from Sentry project (optional but recommended)
   - `NODE_ENV` — `production`
4. Railway auto-detects the Dockerfile and deploys
5. `railway.json` ensures migrations run on every deploy before the server starts
6. Railway gives you a URL like `https://clera-api.up.railway.app`
7. Update `AppConfig.apiBaseUrl` in `apps/mobile/lib/core/config/app_config.dart`

---

## Phase 5 — App Store Requirements

- [ ] 🤝 **P5-1** App icon — SVG at `assets/icons/clera_icon.svg` ready; export to PNG + run launcher icons
- [x] ✅ **P5-2** Splash screen — Android: forest green (#0D4A2E) light / near-black (#0B0B0E) dark
- [x] ✅ **P5-3** Privacy Policy screen (Settings → Privacy Policy)
- [x] ✅ **P5-4** Terms of Service screen (Settings → Terms of Service)
- [ ] 🤝 **P5-5** Create App Store listing (screenshots, description)
- [ ] 🤝 **P5-6** Create Play Store listing
- [ ] 🤝 **P5-7** Set up iOS provisioning profiles / signing

### App icon — fastest path
1. Open `apps/mobile/assets/icons/clera_icon.svg` in Figma / Inkscape / any SVG editor
2. Export as 1024×1024 PNG → save as `apps/mobile/assets/icons/app_icon.png`
3. Also export foreground only (leaf + brackets, no bg circle) → `apps/mobile/assets/icons/app_icon_foreground.png`
4. Run in `apps/mobile/`: `flutter pub get && dart run flutter_launcher_icons`

---

## Phase 6 — Polish

- [x] ✅ **P6-1** Pull-to-refresh on history screen
- [x] ✅ **P6-2** Search in history screen
- [x] ✅ **P6-3** Empty state messages on history + ingredients
- [x] ✅ **P6-4** Offline banner — shows "No internet connection" at top of app
- [x] ✅ **P6-5** Loading skeletons — history cards + result hero
- [x] ✅ **P6-6** Home screen wired to real recent scans + quota banner
- [x] ✅ **P6-7** Quota exceeded → paywall redirect (403 handling)
- [x] ✅ **P6-8** Favourites screen (Hive → API fetch)
- [x] ✅ **P6-9** About screen with Clera branding
- [x] ✅ **P6-10** Delete account flow (confirmation dialog + API soft delete)
- [x] ✅ **P6-11** PDF/HTML export endpoint + share button on result screen
- [x] ✅ **P6-12** Subscription verify endpoint — upgrades user tier on purchase
- [x] ✅ **P6-13** Feedback endpoint + Flutter feedback screen (bug/feature/general + star rating)
- [x] ✅ **P6-14** Onboarding skipped for already-logged-in users
- [x] ✅ **P6-15** Theme toggle (light/system/dark) persisted via secure storage

---

## Phase 7 — Bug Fixes & Code Quality (this session)

- [x] ✅ **P7-1** Prisma schema: Subscription `startedAt` default + compound unique `(userId, productId)`
- [x] ✅ **P7-2** Prisma schema: Feedback `scanId` nullable, `comment` non-null, added `type` field
- [x] ✅ **P7-3** Subscriptions service: upsert uses compound unique key `userId_productId`
- [x] ✅ **P7-4** Feedback controller: saves `type` field
- [x] ✅ **P7-5** DB migration `20260428000000_fix_schema` — adds ProductImage, PurchaseIntent, fixes Subscription/Feedback
- [x] ✅ **P7-6** Dockerfile fixed: was using pnpm (not installed), now uses npm
- [x] ✅ **P7-7** `railway.json` added: Dockerfile build + healthcheck + `prisma migrate deploy` on start
- [x] ✅ **P7-8** Removed unused `bullmq` + `ioredis` dependencies (no Redis in use)
- [x] ✅ **P7-9** `.env.example` updated to reflect Supabase-only setup (removed stale AWS/Redis vars)
- [x] ✅ **P7-10** Scan category sent lowercase to API (`'Food'` → `'food'`) — was failing DTO enum validation
- [x] ✅ **P7-11** Home screen gallery pick: now sets `pendingScanProvider` correctly (was setting dead local provider)
- [x] ✅ **P7-12** System prompt: "SafeScan's Label Analyst" → "Clera's Label Analyst"
- [x] ✅ **P7-13** CI workflow: removed stale `JWT_SECRET` + `REDIS_URL` env vars from test step

---

## What YOU must do before going live

| # | Status | Action | Where |
|---|--------|--------|--------|
| 1 | ✅ Done | Run RLS SQL | Supabase Dashboard → SQL Editor |
| 2 | ✅ Done | Deploy API to Railway | Live at `https://safescanapi-production.up.railway.app` |
| 3 | ✅ Done | Set env vars in Railway | `DATABASE_URL`, `NODE_ENV`, `PORT`, `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| 4 | ✅ Done | Update `apiBaseUrl` in `app_config.dart` | Points to Railway URL |
| 5 | 🔴 **URGENT** | Rotate exposed secrets | Anthropic key + Supabase service role key + DB password were visible in chat — rotate all three now |
| 6 | 🤝 Pending | Set GitHub Secrets for CI/CD | Repo → Settings → Secrets: `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`, `RAILWAY_TOKEN`, `API_BASE_URL`, `SENTRY_DSN`, `BETTERSTACK_HEARTBEAT_URL` |
| 7 | 🤝 Pending | Run `flutter pub get` in `apps/mobile/` | Your terminal (after adding Flutter to PATH) |
| 8 | 🤝 Pending | Export app icon SVG → 1024×1024 PNG | Open `assets/icons/clera_icon.svg` in Figma / Inkscape → export PNG |
| 9 | 🤝 Pending | Run `dart run flutter_launcher_icons` | `apps/mobile/` terminal after step 8 |
| 10 | 🤝 Pending | Register IAP product IDs | App Store Connect + Play Console: `clera_pro_annual`, `clera_pro_monthly`, `clera_family_annual` |
| 11 | 🤝 Pending | Build release APK/IPA | `flutter build apk --release` / `flutter build ipa` |
| 12 | 🤝 Pending | Create App Store + Play Store listings | App Store Connect + Play Console |

### How to rotate secrets (do this now)

**Anthropic API key:**
1. Go to console.anthropic.com → API Keys
2. Delete the old key (`sk-ant-api03-otYAmFe...`)
3. Create a new key → copy it
4. Update `ANTHROPIC_API_KEY` in Railway Variables

**Supabase service role key:**
1. Supabase Dashboard → Project Settings → API
2. Click "Reset" next to Service Role key
3. Copy the new key
4. Update `SUPABASE_SERVICE_ROLE_KEY` in Railway Variables

**Database password:**
1. Supabase Dashboard → Project Settings → Database → Reset database password
2. Copy the new password (URL-encode `@` as `%40` if present)
3. Update `DATABASE_URL` in Railway: `postgresql://postgres.cjfetpevxdtszlalcqgc:NEWPASSWORD@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres`

---

## Progress Log

| Date | Task | Status |
|------|------|--------|
| 2026-04-22 | P1-2 Profile setup wired to API | ✅ |
| 2026-04-22 | History screen wired to real API | ✅ |
| 2026-04-22 | Ingredients screen wired to real API | ✅ |
| 2026-04-22 | Settings screen with sign out wired | ✅ |
| 2026-04-22 | ProductImage + PurchaseIntent tables created | ✅ |
| 2026-04-22 | AWS SDK removed, Supabase Storage wired | ✅ |
| 2026-04-22 | Purchase intent bottom sheet wired | ✅ |
| 2026-04-22 | P1-3 New user → profile setup redirect | ✅ |
| 2026-04-22 | P1-5 Result screen data mapping fixed | ✅ |
| 2026-04-22 | P2-1 Share button wired | ✅ |
| 2026-04-22 | P2-2 Favourite button wired (Hive) | ✅ |
| 2026-04-22 | P2-3 Search + filter + pull-to-refresh in history | ✅ |
| 2026-04-22 | P3-2 Rate limiting confirmed active | ✅ |
| 2026-04-22 | P5-3 Privacy Policy screen | ✅ |
| 2026-04-22 | P5-4 Terms of Service screen | ✅ |
| 2026-04-22 | P6-4 Offline banner added | ✅ |
| 2026-04-23 | P4-3 GitHub Actions CI/CD (api.yml + flutter.yml) | ✅ |
| 2026-04-23 | P4-4 Sentry error monitoring (API + Flutter) | ✅ |
| 2026-04-23 | P6-5 Loading skeletons (history + result) | ✅ |
| 2026-04-23 | P2-4 Paywall wired to in_app_purchase (real IAP + restore) | ✅ |
| 2026-04-23 | P4-5 Uptime monitoring (GH Actions cron + BetterStack heartbeat) | ✅ |
| 2026-04-23 | P5-2 Android splash screen (brand colors, dark mode aware) | ✅ |
| 2026-04-23 | P5-1 App icon SVG + flutter_launcher_icons config | 🤝 needs PNG export |
| 2026-04-23 | P6-6 Home screen wired to real API (recent scans + quota banner) | ✅ |
| 2026-04-23 | P6-7 Quota exceeded 403 → paywall redirect | ✅ |
| 2026-04-23 | P6-8 Favourites screen | ✅ |
| 2026-04-23 | P6-9 About screen | ✅ |
| 2026-04-23 | P6-10 Delete account flow | ✅ |
| 2026-04-23 | P6-11 PDF/HTML export API + result screen export button | ✅ |
| 2026-04-28 | P6-12 Subscription verify API + IAP receipt forwarding | ✅ |
| 2026-04-28 | P6-13 Feedback API endpoint + Flutter feedback screen | ✅ |
| 2026-04-28 | P6-14 Onboarding skip for logged-in users | ✅ |
| 2026-04-28 | P6-15 Theme toggle (light/system/dark) with persistence | ✅ |
| 2026-04-28 | P7-1 Prisma schema fix: Subscription compound unique + startedAt default | ✅ |
| 2026-04-28 | P7-2 Prisma schema fix: Feedback nullable scanId + type field | ✅ |
| 2026-04-28 | P7-3..4 Service/controller fixes for subscription upsert + feedback type | ✅ |
| 2026-04-28 | P7-5 Migration 20260428000000_fix_schema | ✅ |
| 2026-04-28 | P7-6 Dockerfile: pnpm → npm | ✅ |
| 2026-04-28 | P7-7 railway.json with healthcheck + migrate deploy | ✅ |
| 2026-04-28 | P7-8 Removed bullmq + ioredis (unused) | ✅ |
| 2026-04-28 | P7-9 .env.example cleanup | ✅ |
| 2026-04-28 | P7-10 Scan category lowercase fix (enum validation was failing) | ✅ |
| 2026-04-28 | P7-11 Home gallery pick: wired to pendingScanProvider | ✅ |
| 2026-04-28 | P7-12 Anthropic system prompt: SafeScan → Clera | ✅ |
| 2026-04-28 | P7-13 CI: removed stale JWT_SECRET + REDIS_URL | ✅ |
| 2026-04-28 | P4-1 API deployed to Railway (fixed OpenSSL, region, env vars) | ✅ |
| 2026-04-28 | P4-2 Flutter apiBaseUrl updated to Railway production URL | ✅ |
