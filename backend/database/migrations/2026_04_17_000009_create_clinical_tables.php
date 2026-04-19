<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patient_intakes', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->enum('intake_type', ['initial', 'follow_up', 'discharge'])->default('initial');
            $table->enum('pathology_group', ['spine', 'knee', 'shoulder', 'hip', 'ankle', 'general', 'other'])->nullable();
            $table->string('primary_condition')->nullable();
            $table->text('chief_complaint')->nullable();
            $table->enum('onset_type', ['sudden', 'gradual', 'post_surgery', 'insidious', 'sports', 'work'])->nullable();
            $table->enum('duration_category', ['acute', 'sub_acute', 'chronic'])->nullable();
            $table->unsignedInteger('duration_days')->nullable();
            $table->text('mechanism_of_injury')->nullable();
            $table->json('pain_sites')->nullable();
            $table->decimal('vas_score', 3, 1)->nullable();
            $table->json('red_flags')->nullable();
            $table->boolean('red_flags_present')->default(false);
            $table->text('previous_treatment')->nullable();
            $table->text('patient_goals')->nullable();
            $table->json('mri_urls')->nullable();
            $table->json('xray_urls')->nullable();
            $table->enum('ai_triage_level', ['physiotherapy', 'orthopaedic', 'neurological', 'emergency'])->nullable();
            $table->unsignedTinyInteger('ai_triage_confidence')->nullable();
            $table->string('ai_primary_diagnosis', 500)->nullable();
            $table->text('ai_reasoning')->nullable();
            $table->json('ai_preliminary_plan')->nullable();
            $table->string('ai_predicted_recovery', 100)->nullable();
            $table->boolean('ai_red_flag_alert')->default(false);
            $table->foreignId('completed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('outcome_score_definitions', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->string('abbreviation', 50);
            $table->enum('pathology', ['spine', 'knee', 'shoulder', 'hip', 'ankle', 'general', 'all'])->nullable();
            $table->decimal('score_min', 8, 2);
            $table->decimal('score_max', 8, 2);
            $table->string('unit', 20)->nullable();
            $table->boolean('lower_better');
            $table->text('description')->nullable();
            $table->string('reference', 500)->nullable();
            $table->json('bands')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('patient_outcome_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('intake_id')->nullable()->constrained('patient_intakes')->nullOnDelete();
            $table->string('score_code', 50);
            $table->decimal('raw_score', 8, 2);
            $table->decimal('normalised_pct', 5, 2)->nullable();
            $table->string('band_label', 100)->nullable();
            $table->foreignId('recorded_by')->constrained('users');
            $table->date('session_date');
            $table->unsignedTinyInteger('week_number')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['patient_id', 'score_code', 'session_date']);
        });

        Schema::create('outcome_score_responses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('score_record_id')->constrained('patient_outcome_scores')->cascadeOnDelete();
            $table->string('question_code', 100)->nullable();
            $table->decimal('response_value', 5, 2)->nullable();
            $table->string('response_label')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('daily_checkins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->date('checkin_date');
            $table->decimal('pain_score', 3, 1)->nullable();
            $table->unsignedTinyInteger('mood_score')->nullable();
            $table->decimal('sleep_hours', 3, 1)->nullable();
            $table->unsignedTinyInteger('energy_level')->nullable();
            $table->unsignedInteger('steps_count')->nullable();
            $table->text('patient_notes')->nullable();
            $table->text('ai_insight')->nullable();
            $table->enum('ai_alert_level', ['green', 'amber', 'red'])->default('green');
            $table->text('ai_action_today')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['patient_id', 'checkin_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_checkins');
        Schema::dropIfExists('outcome_score_responses');
        Schema::dropIfExists('patient_outcome_scores');
        Schema::dropIfExists('outcome_score_definitions');
        Schema::dropIfExists('patient_intakes');
    }
};
