<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patient_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date_of_birth')->nullable();
            $table->enum('gender', ['male', 'female', 'other'])->nullable();
            $table->string('blood_group', 5)->nullable();
            $table->decimal('height_cm', 5, 1)->nullable();
            $table->decimal('weight_kg', 5, 1)->nullable();
            $table->string('occupation')->nullable();
            $table->text('medical_history')->nullable();       // AES-256 encrypted
            $table->text('current_medications')->nullable();   // AES-256 encrypted
            $table->text('allergies')->nullable();             // AES-256 encrypted
            $table->string('emergency_contact_name')->nullable();
            $table->string('emergency_contact_phone', 15)->nullable();
            $table->enum('preferred_language', ['en', 'hi', 'gu'])->default('en');
            $table->foreignId('plan_id')->nullable()->constrained('subscription_plans')->nullOnDelete();
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamps();
        });

        Schema::create('patient_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->string('label', 50)->nullable();
            $table->string('address_line1');
            $table->string('address_line2')->nullable();
            $table->string('city', 100);
            $table->string('state', 100);
            $table->string('pincode', 10);
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('patient_addresses');
        Schema::dropIfExists('patient_profiles');
    }
};
