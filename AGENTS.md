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
Date: 2026-04-20 00:00
Updated By: Claude AI Agent (claude/physioconnect-architecture-LnJ1d)
Last Commit: feat: deployment infrastructure (Docker, CI/CD, seeders, admin login)

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
- [x] Auth: OTP phone login with 60s countdown, +91 prefix, phone regex validation
- [x] Dashboard: XP/streak gamification card, upcoming bookings, today's exercises
- [x] Discovery: GPS-based physio search, type filters, slot picker
- [x] Booking: 14-day date picker, session type selector, detail view, cancel dialog
- [x] Check-in: Pain/mood/sleep/energy sliders with notes (+10 XP snackbar)
- [x] Payment: Razorpay SDK, server-side signature verification
- [x] Profile: View/edit personal & medical info, gamification stats, logout

### Physio App (Flutter — `physio_app/`)
- [x] Auth: OTP phone login with physio role
- [x] Dashboard: earnings gradient card, today's sessions, upcoming appointments
- [x] Bookings: list + detail with confirm/start/complete/cancel actions
- [x] SOAP Notes: S/O/A/P + home exercise program with session creation
- [x] Patients: list with last visit and session count
- [x] Availability: weekly schedule editor with time pickers, slot duration
- [x] Profile: verification status banner, fees, specializations, edit sheet, logout

### Admin Panel (React — `admin_panel/`)
- [x] Auth: email/password login, Zustand persistent session, 401 auto-logout
- [x] Layout: sidebar with NavLinks, user badge, logout
- [x] Dashboard: total/monthly revenue cards, 6 KPI stat tiles
- [x] Verification Queue: pending physios, approve/reject with reason dialog
- [x] Bookings: searchable/filterable table with status and payment badges
- [x] Users: role-filtered table with status indicators
- [x] Revenue Analytics: Recharts area + bar charts (monthly revenue, by type, transactions)

### Deployment Infrastructure
- [x] Backend Dockerfile (PHP 8.3-fpm-alpine, nginx, supervisor, opcache)
- [x] docker-compose.yml (local dev: API + MySQL 8 + Redis + admin panel)
- [x] docker-compose.prod.yml (production: ECR images, AWS CloudWatch logging)
- [x] GitHub Actions CI: Laravel tests + MySQL, TypeScript build, Docker build check
- [x] GitHub Actions Deploy: ECR push + S3/CloudFront admin + EC2 SSM deploy
- [x] Database seeders: ExerciseSeeder (20 evidence-based exercises), MilestoneSeeder (14 achievements), DemoPhysioSeeder (10 Ahmedabad physios)
- [x] Admin email/password login endpoint (POST /api/v1/admin/login)

---

## WHAT IS IN PROGRESS 🔄

| Task | Developer | Started | Branch | ETA |
|------|-----------|---------|--------|-----|
| AWS environment provisioning | DevOps | — | — | TBD |

---

## WHAT IS NEXT 📋 (Priority Order)

1. [ ] Provision EC2 (t3.medium) + RDS MySQL 8 (db.t3.medium) + ElastiCache Redis in ap-south-1
2. [ ] Push ECR image, set .env.production, run `php artisan migrate --seed` on server
3. [ ] Register `api.physioconnect.in` → EC2 load balancer with ACM SSL cert
4. [ ] Deploy admin panel to S3 + CloudFront at `admin.physioconnect.in`
5. [ ] Configure GitHub Actions secrets (AWS_ACCESS_KEY_ID, ECR, Razorpay, etc.)
6. [ ] Run `php artisan db:seed --class=DemoPhysioSeeder` for 10 Ahmedabad demo physios
7. [ ] Submit patient_app and physio_app to Play Store (internal testing track)
8. [ ] Beta launch: onboard 30 physios in Ahmedabad
9. [ ] Phase 2 starts only after 200 active users (CRITICAL RULE)

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
