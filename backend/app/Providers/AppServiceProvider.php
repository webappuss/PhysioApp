<?php

namespace App\Providers;

use App\Modules\Auth\Models\User;
use App\Modules\Auth\Policies\PatientRecordPolicy;
use App\Shared\Services\AuditLogger;
use App\Shared\Services\ClaudeAdapter;
use App\Shared\Services\NotificationService;
use App\Shared\Services\RazorpayService;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use Laravel\Sanctum\Sanctum;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind shared services as singletons
        $this->app->singleton(AuditLogger::class);
        $this->app->singleton(NotificationService::class);
        $this->app->singleton(RazorpayService::class);
        $this->app->singleton(ClaudeAdapter::class, fn($app) => new ClaudeAdapter(
            $app->make(AuditLogger::class)
        ));
    }

    public function boot(): void
    {
        // Use our User model for Sanctum
        Sanctum::usePersonalAccessTokenModel(\Laravel\Sanctum\PersonalAccessToken::class);

        // Override the default auth user model
        $this->app->bind(
            \Illuminate\Foundation\Auth\User::class,
            User::class
        );

        // Register RBAC policies
        Gate::policy(\App\Modules\Auth\Models\User::class, PatientRecordPolicy::class);

        // Register the policy for patient profile records
        Gate::define('view-patient-record', [PatientRecordPolicy::class, 'view']);
        Gate::define('update-patient-record', [PatientRecordPolicy::class, 'update']);
    }
}
