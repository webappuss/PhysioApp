<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('physiotherapist_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('registration_number', 100);
            $table->string('registration_body', 100)->nullable();
            $table->string('qualification')->nullable();
            $table->json('specializations')->nullable();
            $table->unsignedTinyInteger('years_experience')->nullable();
            $table->text('bio')->nullable();
            $table->json('languages_spoken')->nullable();
            $table->decimal('service_radius_km', 5, 1)->default(10);
            $table->decimal('home_visit_charge', 10, 2)->nullable();
            $table->decimal('video_consult_charge', 10, 2)->nullable();
            $table->boolean('is_available')->default(true);
            $table->boolean('is_verified')->default(false);
            $table->timestamp('verified_at')->nullable();
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('rating', 3, 2)->default(0.00);
            $table->unsignedInteger('total_reviews')->default(0);
            $table->unsignedInteger('total_sessions')->default(0);
            $table->string('bank_account_id')->nullable();
            $table->decimal('current_latitude', 10, 8)->nullable();
            $table->decimal('current_longitude', 11, 8)->nullable();
            $table->timestamp('location_updated_at')->nullable();
            $table->timestamps();
        });

        Schema::create('physiotherapist_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles')->cascadeOnDelete();
            $table->enum('document_type', ['degree', 'registration', 'id_proof', 'profile_photo', 'other']);
            $table->string('file_url', 500);
            $table->string('s3_key', 500);
            $table->boolean('verified')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('physiotherapist_availability', function (Blueprint $table) {
            $table->id();
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles')->cascadeOnDelete();
            $table->unsignedTinyInteger('day_of_week'); // 0=Sunday, 6=Saturday
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_active')->default(true);
        });

        Schema::create('physio_blocked_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles')->cascadeOnDelete();
            $table->date('blocked_date');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->string('reason')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('physio_blocked_slots');
        Schema::dropIfExists('physiotherapist_availability');
        Schema::dropIfExists('physiotherapist_documents');
        Schema::dropIfExists('physiotherapist_profiles');
    }
};
