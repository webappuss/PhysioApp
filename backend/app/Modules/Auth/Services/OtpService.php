<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Models\OtpVerification;
use App\Shared\Services\NotificationService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class OtpService
{
    public function __construct(private NotificationService $notificationService) {}

    public function send(string $phone, string $purpose): void
    {
        $this->enforceRateLimit($phone);

        $otp = $this->generateOtp();

        // Invalidate prior OTPs for this phone+purpose
        OtpVerification::where('phone', $phone)
            ->where('purpose', $purpose)
            ->where('verified', false)
            ->delete();

        OtpVerification::create([
            'phone'      => $phone,
            'otp_hash'   => Hash::make($otp),
            'purpose'    => $purpose,
            'expires_at' => now()->addMinutes(config('physioconnect.otp.expiry_minutes', 10)),
            'verified'   => false,
            'attempts'   => 0,
        ]);

        if (config('physioconnect.otp.log_in_development')) {
            Log::info("PhysioConnect OTP [{$purpose}] for {$phone}: {$otp}");
        } else {
            $this->notificationService->sendSms($phone, "Your PhysioConnect OTP is {$otp}. Valid for 10 minutes. Do not share.");
        }
    }

    public function verify(string $phone, string $otp, string $purpose): bool
    {
        $record = OtpVerification::where('phone', $phone)
            ->where('purpose', $purpose)
            ->where('verified', false)
            ->latest('id')
            ->first();

        if (! $record) {
            throw ValidationException::withMessages(['otp' => ['No OTP found. Please request a new one.']]);
        }

        if ($record->isExpired()) {
            throw ValidationException::withMessages(['otp' => ['OTP has expired. Please request a new one.']]);
        }

        if ($record->isExhausted()) {
            throw ValidationException::withMessages(['otp' => ['Too many incorrect attempts. Please request a new OTP.']]);
        }

        $record->increment('attempts');

        if (! Hash::check($otp, $record->otp_hash)) {
            throw ValidationException::withMessages(['otp' => ['Invalid OTP.']]);
        }

        $record->update(['verified' => true]);

        return true;
    }

    private function generateOtp(): string
    {
        $length = config('physioconnect.otp.length', 6);
        return str_pad((string) random_int(0, (int) str_repeat('9', $length)), $length, '0', STR_PAD_LEFT);
    }

    private function enforceRateLimit(string $phone): void
    {
        $key   = "otp_send:{$phone}";
        $count = (int) Cache::get($key, 0);

        if ($count >= 5) {
            throw ValidationException::withMessages(['phone' => ['Too many OTP requests. Please wait before trying again.']]);
        }

        Cache::put($key, $count + 1, now()->addHour());
    }
}
