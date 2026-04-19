# AGENTS.md — PhysioConnect Development State

## ⚠️ MANDATORY: Read this before writing a single line of code

---

## CURRENT PHASE
Phase: 1
Phase Status: In Progress
Phase Started: 2026-04-17
Phase Target Completion: 2026-08-17

---

## LAST UPDATED
Date: 2026-04-17 13:00
Updated By: Claude AI Agent (claude/physioconnect-architecture-LnJ1d)
Last Commit: (initial scaffold)

---

## WHAT IS DONE ✅

### Backend (Laravel — `backend/`)
- [x] Laravel modular monolith project scaffold
- [x] composer.json with all required dependencies
- [x] .env.example with all required variables
- [x] Application bootstrap (app.php, Kernel.php, console Kernel)
- [x] ModuleServiceProvider — auto-discovers all module routes & migrations
- [x] All database migrations (users, profiles, bookings, sessions, payments, exercises, rehab, scores, messaging, notifications, audit, gamification)
- [x] Auth module: OTP send/verify, Sanctum token issue/refresh/logout, /auth/me
- [x] Auth middleware: role-based guards (patient, physio, surgeon, psychologist, admin)
- [x] RBAC Policies: PatientRecordPolicy
- [x] Patient module: profile CRUD, address management, dashboard, care team, check-ins, outcome scores
- [x] Physiotherapist module: profile CRUD, availability management, dashboard, patient list, earnings, location update
- [x] Discovery module: geolocation-based physio search with filters, single physio detail, availability slots
- [x] Booking module: create booking, confirm/start/complete/cancel, tracking, package support
- [x] Session module: SOAP notes create/update, session detail
- [x] Payment module: Razorpay order creation, webhook verification, history, package purchase
- [x] Exercise module: library (CRUD), phase exercise assignment, exercise completion with AI modifier hook
- [x] Rehab Plan module: create, detail, phase advance, exercises per phase
- [x] Admin module: dashboard metrics, physio verification queue, approve/reject, booking management, user management, revenue analytics
- [x] Shared services: AuditLogger, NotificationService (FCM/SMS/email), ClaudeAdapter (AI), RazorpayService
- [x] Shared middleware: ForceJson, SanitizeInput, RateLimitAI
- [x] PHPUnit tests for Auth, Booking, and Payment endpoints

### Patient App (Flutter — `patient_app/`)
- [ ] Not started

### Physio App (Flutter — `physio_app/`)
- [ ] Not started

### Admin Panel (React — `admin_panel/`)
- [ ] Not started

---

## WHAT IS IN PROGRESS 🔄

| Task | Developer | Started | Branch | ETA |
|------|-----------|---------|--------|-----|
| Phase 1 backend complete | Claude Agent | 2026-04-17 | claude/physioconnect-architecture-LnJ1d | 2026-04-17 |

---

## WHAT IS NEXT 📋 (Priority Order)

1. [ ] Migrate & seed database (run `php artisan migrate --seed`)
2. [ ] Stand up EC2 + RDS environment (AWS Phase 1 spec)
3. [ ] Flutter patient app — OTP login + physio discovery
4. [ ] Flutter physio app — onboarding + booking management
5. [ ] React admin panel — verification queue + dashboard
6. [ ] Beta launch: onboard 30 physios in Ahmedabad
7. [ ] Phase 2 starts only after 200 active users (CRITICAL RULE)

---

## ARCHITECTURE DECISIONS LOG

| Decision | Reason | Date |
|----------|--------|------|
| Laravel modular monolith over microservices | Phase 1 team size, simpler deployment | 2026-04-17 |
| Separate Flutter apps for patient/physio | Different UX flows, different app store listings | 2026-04-17 |
| Riverpod for Flutter state management | Better testability vs BLoC at our scale | 2026-04-17 |
| Razorpay over Stripe | Better UPI/RuPay support in India | 2026-04-17 |
| Redis for sessions + job queue | Avoid extra DB load for ephemeral data | 2026-04-17 |
| Sanctum (token auth) over Passport | Lighter weight, SPA/mobile friendly | 2026-04-17 |
| AES-256 (Laravel Crypt) for medical data | HIPAA-inspired, DPDP Act 2023 compliance | 2026-04-17 |
| S3 signed URLs (15-min expiry) for files | Prevent unauthorised direct file access | 2026-04-17 |
| claude-sonnet-4-20250514 model | Best capability/cost ratio for clinical triage | 2026-04-17 |

---

## ENVIRONMENT SETUP

### Backend
```bash
git clone https://github.com/webappuss/physioapp
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### Required .env Variables
```
DB_HOST=
DB_DATABASE=physioconnect
DB_USERNAME=
DB_PASSWORD=

RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_WEBHOOK_SECRET=

ANTHROPIC_API_KEY=
CLAUDE_MODEL=claude-sonnet-4-20250514

GOOGLE_MAPS_API_KEY=
FIREBASE_SERVER_KEY=

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=ap-south-1
AWS_BUCKET=physioconnect-medical

REDIS_HOST=
```

### Patient App
```bash
cd patient_app
flutter pub get
flutter run --flavor development
```

---

## API ENDPOINTS STATUS

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| /api/v1/auth/send-otp | POST | ✅ Done | Rate-limited 5/hr per phone |
| /api/v1/auth/verify-otp | POST | ✅ Done | Returns Sanctum token |
| /api/v1/auth/refresh-token | POST | ✅ Done | |
| /api/v1/auth/logout | POST | ✅ Done | |
| /api/v1/auth/me | GET | ✅ Done | |
| /api/v1/patient/profile | GET/PUT | ✅ Done | |
| /api/v1/patient/dashboard | GET | ✅ Done | |
| /api/v1/patient/care-team | GET | ✅ Done | |
| /api/v1/patient/checkins | GET/POST | ✅ Done | |
| /api/v1/patient/scores | GET/POST | ✅ Done | |
| /api/v1/patient/scores/{code}/history | GET | ✅ Done | |
| /api/v1/physio/profile | GET/PUT | ✅ Done | |
| /api/v1/physio/availability | GET/PUT | ✅ Done | |
| /api/v1/physio/dashboard | GET | ✅ Done | |
| /api/v1/physio/patients | GET | ✅ Done | |
| /api/v1/physio/patients/{id} | GET | ✅ Done | |
| /api/v1/physio/earnings | GET | ✅ Done | |
| /api/v1/physio/location | POST | ✅ Done | |
| /api/v1/discover/physios | GET | ✅ Done | Haversine geolocation |
| /api/v1/discover/physios/{id} | GET | ✅ Done | |
| /api/v1/discover/physios/{id}/availability | GET | ✅ Done | |
| /api/v1/bookings | POST | ✅ Done | |
| /api/v1/bookings/{id} | GET | ✅ Done | |
| /api/v1/bookings/{id}/confirm | PUT | ✅ Done | Physio confirms |
| /api/v1/bookings/{id}/start | PUT | ✅ Done | Physio en route/arrived |
| /api/v1/bookings/{id}/complete | PUT | ✅ Done | |
| /api/v1/bookings/{id}/cancel | PUT | ✅ Done | |
| /api/v1/bookings/{id}/tracking | GET | ✅ Done | Latest physio coords |
| /api/v1/sessions | POST | ✅ Done | |
| /api/v1/sessions/{id} | GET/PUT | ✅ Done | |
| /api/v1/sessions/{id}/soap | POST | ✅ Done | Encrypted SOAP notes |
| /api/v1/rehab-plans | POST | ✅ Done | |
| /api/v1/rehab-plans/{id} | GET | ✅ Done | |
| /api/v1/rehab-plans/{id}/advance-phase | PUT | ✅ Done | |
| /api/v1/rehab-plans/{id}/phases | GET | ✅ Done | |
| /api/v1/rehab-plans/{id}/exercises | GET/POST | ✅ Done | |
| /api/v1/exercises/{id}/complete | POST | ✅ Done | |
| /api/v1/exercises/{id}/ai-modify | POST | ✅ Done | Phase 2 AI hook |
| /api/v1/payments/create-order | POST | ✅ Done | Razorpay |
| /api/v1/payments/verify | POST | ✅ Done | Signature validation |
| /api/v1/payments/history | GET | ✅ Done | |
| /api/v1/payments/packages | POST | ✅ Done | |
| /api/v1/admin/dashboard | GET | ✅ Done | |
| /api/v1/admin/physios/pending | GET | ✅ Done | Verification queue |
| /api/v1/admin/physios/{id}/verify | PUT | ✅ Done | Approve/reject |
| /api/v1/admin/bookings | GET | ✅ Done | |
| /api/v1/admin/payments | GET | ✅ Done | |
| /api/v1/admin/analytics/revenue | GET | ✅ Done | |
| /api/v1/ai/triage | POST | ⬜ Phase 2 | |
| /api/v1/ai/rehab-plan | POST | ⬜ Phase 2 | |
| /api/v1/ai/exercise-modify | POST | ⬜ Phase 2 | |
| /api/v1/ai/checkin-insight | POST | ⬜ Phase 2 | |

---

## KNOWN ISSUES / BLOCKERS

| Issue | Severity | Description | Owner |
|-------|---------|-------------|-------|
| — | — | — | — |

---

## DO NOT TOUCH ⛔

- `database/migrations/` — Only add new migrations, never modify existing ones
- `app/Shared/Services/AuditLogger.php` — Audit logging must not be disabled
- `.env.production` — Only DevOps lead has access
- `app/Modules/Payment/Services/RazorpayService.php` — Never bypass signature verification
- `app/Shared/Middleware/SanitizeInput.php` — XSS protection, never remove

---

## CODING STANDARDS

- **Laravel:** PSR-12, Eloquent only (no raw queries), all business logic in Services
- **Flutter:** Feature-first structure, all API calls via Repository pattern
- **React:** TypeScript strict mode, React Query for all server state
- **Git:** Conventional commits (`feat:`, `fix:`, `chore:`, `test:`)
- **Branch naming:** `feature/module-description`, `fix/issue-description`
- **Tests:** Every new API endpoint must have a PHPUnit feature test
- **Encryption:** All medical fields use `Crypt::encryptString()` before DB insert

---

## HOW TO RESUME AS AN AI AGENT

1. Read this entire file
2. Check `## WHAT IS IN PROGRESS` for active tasks
3. Read the relevant module code in `backend/app/Modules/[ModuleName]/`
4. Do not create new patterns — match existing conventions
5. Update this file when your task is complete
6. Always write tests for new API endpoints
7. Never start Phase 2 features unless explicitly instructed AND Phase 1 has 200+ active users
