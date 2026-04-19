<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('phone', 15)->unique();
            $table->string('email')->unique()->nullable();
            $table->string('name');
            $table->enum('role', ['patient', 'physiotherapist', 'surgeon', 'psychologist', 'admin', 'super_admin']);
            $table->enum('status', ['pending', 'active', 'suspended', 'deleted'])->default('pending');
            $table->enum('lang_preference', ['en', 'hi', 'gu'])->default('en');
            $table->string('avatar_url', 500)->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamp('phone_verified_at')->nullable();
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('otp_verifications', function (Blueprint $table) {
            $table->id();
            $table->string('phone', 15);
            $table->string('otp_hash');
            $table->enum('purpose', ['login', 'register', 'reset']);
            $table->timestamp('expires_at');
            $table->boolean('verified')->default(false);
            $table->tinyInteger('attempts')->default(0)->unsigned();
            $table->timestamp('created_at')->useCurrent();

            $table->index('phone');
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('otp_verifications');
        Schema::dropIfExists('users');
    }
};
