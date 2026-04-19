<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Platform Commission Rates
    |--------------------------------------------------------------------------
    */
    'commission' => [
        'home_visit_percent' => env('RAZORPAY_PLATFORM_COMMISSION_PERCENT', 15),
        'video_percent'      => env('RAZORPAY_VIDEO_COMMISSION_PERCENT', 12),
        'fixed_fee'          => env('RAZORPAY_FIXED_PLATFORM_FEE', 50),
        'gst_percent'        => 18,
    ],

    /*
    |--------------------------------------------------------------------------
    | Payout Configuration
    |--------------------------------------------------------------------------
    */
    'payout' => [
        'hold_hours'  => 48,        // hours after session completion before payout eligible
        'schedule'    => 'friday',  // weekly payout day
    ],

    /*
    |--------------------------------------------------------------------------
    | OTP Configuration
    |--------------------------------------------------------------------------
    */
    'otp' => [
        'expiry_minutes' => env('OTP_EXPIRY_MINUTES', 10),
        'max_attempts'   => env('OTP_MAX_ATTEMPTS', 5),
        'length'         => 6,
        // In production, use real SMS. In local, log OTP.
        'log_in_development' => env('APP_ENV') !== 'production',
    ],

    /*
    |--------------------------------------------------------------------------
    | Sanctum Token Config
    |--------------------------------------------------------------------------
    */
    'token' => [
        'expiry_days' => env('SANCTUM_TOKEN_EXPIRY_DAYS', 30),
    ],

    /*
    |--------------------------------------------------------------------------
    | AI / Claude Configuration
    |--------------------------------------------------------------------------
    */
    'ai' => [
        'anthropic_api_key' => env('ANTHROPIC_API_KEY'),
        'model'             => env('CLAUDE_MODEL', 'claude-sonnet-4-20250514'),
        'max_tokens'        => (int) env('CLAUDE_MAX_TOKENS', 1200),
        'rate_per_minute'   => (int) env('AI_RATE_LIMIT_PER_MINUTE', 10),
        'cache_ttl'         => (int) env('AI_CACHE_TTL_SECONDS', 3600),
        'rehab_plan_per_physio_per_day' => 10,
    ],

    /*
    |--------------------------------------------------------------------------
    | Google Maps
    |--------------------------------------------------------------------------
    */
    'maps' => [
        'api_key'            => env('GOOGLE_MAPS_API_KEY'),
        'default_radius_km'  => 10,
    ],

    /*
    |--------------------------------------------------------------------------
    | S3 Signed URL Expiry
    |--------------------------------------------------------------------------
    */
    'storage' => [
        'signed_url_minutes' => 15,
        'max_file_size_mb'   => 20,
        'allowed_types'      => ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'dcm'],
    ],

    /*
    |--------------------------------------------------------------------------
    | Audit / Compliance
    |--------------------------------------------------------------------------
    */
    'audit' => [
        'retention_years' => 7,
    ],

    /*
    |--------------------------------------------------------------------------
    | Phase gating — do not enable Phase 2 until threshold met
    |--------------------------------------------------------------------------
    */
    'phases' => [
        'phase2_user_threshold' => 200,
        'phase3_user_threshold' => 1000,
    ],

    /*
    |--------------------------------------------------------------------------
    | Rate Limits (requests per minute)
    |--------------------------------------------------------------------------
    */
    'rate_limits' => [
        'patient' => 60,
        'physio'  => 200,
        'admin'   => 500,
    ],

];
