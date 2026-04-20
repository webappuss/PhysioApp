<?php

use App\Modules\Admin\Controllers\AdminController;
use App\Modules\Auth\Controllers\AuthController;
use App\Modules\Booking\Controllers\BookingController;
use App\Modules\Booking\Controllers\SessionController;
use App\Modules\Discovery\Controllers\DiscoveryController;
use App\Modules\Exercise\Controllers\ExerciseController;
use App\Modules\Exercise\Controllers\RehabPlanController;
use App\Modules\Patient\Controllers\PatientController;
use App\Modules\Payment\Controllers\PaymentController;
use App\Modules\Physiotherapist\Controllers\PhysioController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| PhysioConnect API Routes — v1
| Base: /api/v1/
|--------------------------------------------------------------------------
*/

// ─── HEALTH CHECK (outside v1 prefix, no auth, used by ALB + deploy script) ──
Route::get('health', function () {
    $checks = [];

    // DB connectivity
    try {
        \DB::connection()->getPdo();
        $checks['database'] = 'ok';
    } catch (\Throwable) {
        $checks['database'] = 'error';
    }

    // Cache/Redis connectivity
    try {
        \Cache::put('_health', 1, 5);
        $checks['cache'] = 'ok';
    } catch (\Throwable) {
        $checks['cache'] = 'error';
    }

    $healthy = ! in_array('error', $checks);

    return response()->json([
        'status'  => $healthy ? 'ok' : 'degraded',
        'checks'  => $checks,
        'version' => config('app.version', '1.0.0'),
        'env'     => config('app.env'),
    ], $healthy ? 200 : 503);
});

Route::prefix('v1')->group(function () {

    // ─── AUTH (public) ────────────────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('send-otp',     [AuthController::class, 'sendOtp']);
        Route::post('verify-otp',   [AuthController::class, 'verifyOtp']);
    });

    // ─── ADMIN LOGIN (email + password) ───────────────────────────────────
    Route::post('admin/login', [AdminController::class, 'login']);

    // ─── PAYMENT WEBHOOK (public — verified by Razorpay signature) ────────
    Route::post('payments/webhook', [PaymentController::class, 'webhook']);

    // ─── DISCOVERY (public — no auth needed for search) ───────────────────
    Route::prefix('discover')->group(function () {
        Route::get('physios',                    [DiscoveryController::class, 'index']);
        Route::get('physios/{id}',               [DiscoveryController::class, 'show']);
        Route::get('physios/{id}/availability',  [DiscoveryController::class, 'availability']);
    });

    // ─── AUTHENTICATED ROUTES ─────────────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::prefix('auth')->group(function () {
            Route::post('refresh-token', [AuthController::class, 'refreshToken']);
            Route::post('logout',        [AuthController::class, 'logout']);
            Route::get('me',             [AuthController::class, 'me']);
        });

        // ── PATIENT ───────────────────────────────────────────────────────
        Route::middleware('role:patient')->prefix('patient')->group(function () {
            Route::get('profile',         [PatientController::class, 'profile']);
            Route::put('profile',         [PatientController::class, 'updateProfile']);
            Route::get('dashboard',       [PatientController::class, 'dashboard']);
            Route::get('care-team',       [PatientController::class, 'careTeam']);
            Route::get('checkins',        [PatientController::class, 'checkins']);
            Route::post('checkins',       [PatientController::class, 'storeCheckin']);
            Route::get('scores',          [PatientController::class, 'scores']);
            Route::post('scores',         [PatientController::class, 'storeScore']);
            Route::get('scores/{code}/history', [PatientController::class, 'scoreHistory']);
        });

        // ── PHYSIOTHERAPIST ───────────────────────────────────────────────
        Route::middleware('role:physiotherapist')->prefix('physio')->group(function () {
            Route::get('profile',                   [PhysioController::class, 'profile']);
            Route::put('profile',                   [PhysioController::class, 'updateProfile']);
            Route::get('availability',              [PhysioController::class, 'availability']);
            Route::put('availability',              [PhysioController::class, 'updateAvailability']);
            Route::get('dashboard',                 [PhysioController::class, 'dashboard']);
            Route::get('patients',                  [PhysioController::class, 'patients']);
            Route::get('patients/{id}',             [PhysioController::class, 'patientDetail']);
            Route::get('earnings',                  [PhysioController::class, 'earnings']);
            Route::post('location',                 [PhysioController::class, 'updateLocation']);
        });

        // ── BOOKINGS (patients book, physios action) ──────────────────────
        Route::prefix('bookings')->group(function () {
            Route::post('/',                        [BookingController::class, 'store'])
                ->middleware('role:patient');
            Route::get('{id}',                      [BookingController::class, 'show']);
            Route::put('{id}/confirm',              [BookingController::class, 'confirm'])
                ->middleware('role:physiotherapist');
            Route::put('{id}/start',                [BookingController::class, 'start'])
                ->middleware('role:physiotherapist');
            Route::put('{id}/complete',             [BookingController::class, 'complete'])
                ->middleware('role:physiotherapist');
            Route::put('{id}/cancel',               [BookingController::class, 'cancel']);
            Route::get('{id}/tracking',             [BookingController::class, 'tracking']);
        });

        // ── SESSIONS ──────────────────────────────────────────────────────
        Route::prefix('sessions')->group(function () {
            Route::post('/',                        [SessionController::class, 'store'])
                ->middleware('role:physiotherapist');
            Route::get('{id}',                      [SessionController::class, 'show']);
            Route::post('{id}/soap',                [SessionController::class, 'updateSoap'])
                ->middleware('role:physiotherapist');
        });

        // ── REHAB PLANS ───────────────────────────────────────────────────
        Route::prefix('rehab-plans')->group(function () {
            Route::post('/',                        [RehabPlanController::class, 'store'])
                ->middleware('role:physiotherapist');
            Route::get('{id}',                      [RehabPlanController::class, 'show']);
            Route::put('{id}/advance-phase',        [RehabPlanController::class, 'advancePhase'])
                ->middleware('role:physiotherapist');
            Route::post('{id}/exercises',           [RehabPlanController::class, 'addExercise'])
                ->middleware('role:physiotherapist');
        });

        // ── EXERCISES ─────────────────────────────────────────────────────
        Route::prefix('exercises')->group(function () {
            Route::get('/',                         [ExerciseController::class, 'index']);
            Route::post('/',                        [ExerciseController::class, 'store'])
                ->middleware('role:physiotherapist,admin,super_admin');
            Route::post('{id}/complete',            [ExerciseController::class, 'complete'])
                ->middleware('role:patient');
            Route::post('{id}/ai-modify',           [ExerciseController::class, 'aiModify'])
                ->middleware(['role:patient', 'ai.limit']);
        });

        // ── PAYMENTS ──────────────────────────────────────────────────────
        Route::prefix('payments')->group(function () {
            Route::post('create-order',             [PaymentController::class, 'createOrder'])
                ->middleware('role:patient');
            Route::post('verify',                   [PaymentController::class, 'verify'])
                ->middleware('role:patient');
            Route::get('history',                   [PaymentController::class, 'history'])
                ->middleware('role:patient');
            Route::post('packages',                 [PaymentController::class, 'createPackage'])
                ->middleware('role:patient');
        });

        // ── ADMIN ─────────────────────────────────────────────────────────
        Route::middleware('role:admin,super_admin')->prefix('admin')->group(function () {
            Route::get('dashboard',                 [AdminController::class, 'dashboard']);
            Route::get('physios/pending',           [AdminController::class, 'pendingPhysios']);
            Route::put('physios/{id}/verify',       [AdminController::class, 'verifyPhysio']);
            Route::get('bookings',                  [AdminController::class, 'bookings']);
            Route::get('payments',                  [AdminController::class, 'payments']);
            Route::get('analytics/revenue',         [AdminController::class, 'revenue']);
            Route::get('users',                     [AdminController::class, 'users']);
            Route::put('users/{id}/status',         [AdminController::class, 'updateUserStatus']);
        });
    });
});
