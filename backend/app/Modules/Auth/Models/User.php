<?php

namespace App\Modules\Auth\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'uuid', 'phone', 'email', 'name', 'role', 'status',
        'lang_preference', 'avatar_url', 'last_login_at',
        'phone_verified_at', 'email_verified_at',
    ];

    protected $hidden = ['remember_token'];

    protected $casts = [
        'phone_verified_at'  => 'datetime',
        'email_verified_at'  => 'datetime',
        'last_login_at'      => 'datetime',
        'deleted_at'         => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $user) {
            $user->uuid = $user->uuid ?? (string) Str::uuid();
        });
    }

    public function isAdmin(): bool
    {
        return in_array($this->role, ['admin', 'super_admin']);
    }

    public function hasRole(string|array $roles): bool
    {
        return in_array($this->role, (array) $roles);
    }

    public function patientProfile()
    {
        return $this->hasOne(\App\Modules\Auth\Models\PatientProfile::class, 'user_id');
    }

    public function physioProfile()
    {
        return $this->hasOne(\App\Modules\Auth\Models\PhysioProfile::class, 'user_id');
    }
}
