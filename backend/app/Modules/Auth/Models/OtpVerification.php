<?php

namespace App\Modules\Auth\Models;

use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    public $timestamps = false;

    protected $fillable = ['phone', 'otp_hash', 'purpose', 'expires_at', 'verified', 'attempts'];

    protected $casts = [
        'verified'   => 'boolean',
        'expires_at' => 'datetime',
    ];

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isExhausted(): bool
    {
        return $this->attempts >= config('physioconnect.otp.max_attempts', 5);
    }
}
