<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exercises', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('category', [
                'strengthening', 'mobility', 'stability', 'cardio',
                'neurological', 'proprioception', 'hydrotherapy', 'breathing', 'other',
            ])->nullable();
            $table->json('pathology_tags')->nullable();
            $table->enum('difficulty', ['beginner', 'moderate', 'advanced'])->nullable();
            $table->text('description')->nullable();
            $table->text('technique_cue')->nullable();
            $table->string('verbal_cue', 500)->nullable();
            $table->text('contraindications')->nullable();
            $table->string('video_url', 500)->nullable();
            $table->string('thumbnail_url', 500)->nullable();
            $table->unsignedTinyInteger('default_sets')->default(3);
            $table->string('default_reps', 20)->default('10-12');
            $table->unsignedTinyInteger('default_duration_min')->nullable();
            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('rehab_plans', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles');
            $table->string('title')->nullable();
            $table->string('condition')->nullable();
            $table->unsignedTinyInteger('total_phases')->default(4);
            $table->unsignedTinyInteger('current_phase')->default(1);
            $table->date('start_date')->nullable();
            $table->date('estimated_end_date')->nullable();
            $table->enum('status', ['active', 'completed', 'paused', 'abandoned'])->default('active');
            $table->boolean('ai_generated')->default(false);
            $table->text('ai_generation_prompt')->nullable();
            $table->text('plan_notes')->nullable();
            $table->timestamps();
        });

        Schema::create('rehab_phases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('plan_id')->constrained('rehab_plans')->cascadeOnDelete();
            $table->unsignedTinyInteger('phase_number');
            $table->string('name')->nullable();
            $table->text('focus')->nullable();
            $table->unsignedTinyInteger('start_week')->nullable();
            $table->unsignedTinyInteger('end_week')->nullable();
            $table->enum('status', ['upcoming', 'active', 'completed'])->default('upcoming');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->text('phase_notes')->nullable();
            $table->foreignId('advancement_approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('advancement_approved_at')->nullable();
        });

        Schema::create('phase_exercises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('phase_id')->constrained('rehab_phases')->cascadeOnDelete();
            $table->foreignId('exercise_id')->constrained('exercises');
            $table->unsignedTinyInteger('sets')->nullable();
            $table->string('reps', 20)->nullable();
            $table->unsignedTinyInteger('duration_min')->nullable();
            $table->unsignedTinyInteger('frequency_per_week')->default(1);
            $table->unsignedTinyInteger('order_index')->default(0);
            $table->text('progression_note')->nullable();
            $table->text('caution_note')->nullable();
            $table->boolean('is_active')->default(true);
        });

        Schema::create('exercise_completions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('phase_exercise_id')->constrained('phase_exercises');
            $table->date('completed_date');
            $table->unsignedTinyInteger('sets_done')->nullable();
            $table->string('reps_done', 20)->nullable();
            $table->decimal('pain_during', 3, 1)->nullable();
            $table->decimal('pain_after', 3, 1)->nullable();
            $table->text('patient_feedback')->nullable();
            $table->json('ai_modification')->nullable();
            $table->enum('completion_status', ['done', 'partial', 'skipped'])->default('done');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['patient_id', 'completed_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercise_completions');
        Schema::dropIfExists('phase_exercises');
        Schema::dropIfExists('rehab_phases');
        Schema::dropIfExists('rehab_plans');
        Schema::dropIfExists('exercises');
    }
};
