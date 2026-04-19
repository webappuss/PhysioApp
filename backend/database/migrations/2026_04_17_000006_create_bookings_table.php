<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles');
            $table->enum('booking_type', ['home_visit', 'video_consult', 'clinic']);
            $table->enum('status', [
                'pending', 'confirmed', 'physio_en_route', 'arrived',
                'in_session', 'completed', 'cancelled', 'no_show',
            ])->default('pending');
            $table->date('scheduled_date');
            $table->time('scheduled_time');
            $table->foreignId('address_id')->nullable()->constrained('patient_addresses')->nullOnDelete();
            $table->string('session_notes_preview', 500)->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->foreignId('cancelled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->decimal('session_fee', 10, 2);
            $table->decimal('platform_fee', 10, 2);
            $table->decimal('total_amount', 10, 2);
            $table->enum('payment_status', ['pending', 'authorized', 'captured', 'refunded', 'failed'])->default('pending');
            $table->foreignId('payment_id')->nullable()->constrained('payments')->nullOnDelete();
            $table->foreignId('package_id')->nullable()->constrained('session_packages')->nullOnDelete();
            $table->timestamps();

            $table->index(['physio_id', 'scheduled_date']);
            $table->index(['patient_id', 'scheduled_date']);
        });

        Schema::create('booking_tracking', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->timestamp('recorded_at')->useCurrent();

            $table->index(['booking_id', 'recorded_at']);
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles');
            $table->unsignedTinyInteger('session_number')->nullable();
            $table->json('visit_checklist')->nullable();
            $table->text('subjective')->nullable();   // SOAP-S, encrypted
            $table->text('objective')->nullable();    // SOAP-O, encrypted
            $table->text('assessment')->nullable();   // SOAP-A, encrypted
            $table->text('plan')->nullable();         // SOAP-P, encrypted
            $table->text('ai_soap_summary')->nullable();
            $table->text('ai_next_session_suggestions')->nullable();
            $table->decimal('pain_at_start', 3, 1)->nullable();
            $table->decimal('pain_at_end', 3, 1)->nullable();
            $table->json('techniques_used')->nullable();
            $table->json('equipment_used')->nullable();
            $table->unsignedTinyInteger('duration_mins')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('booking_tracking');
        Schema::dropIfExists('bookings');
    }
};
