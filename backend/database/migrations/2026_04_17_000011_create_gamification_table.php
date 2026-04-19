<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patient_xp', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->unsignedInteger('total_xp')->default(0);
            $table->unsignedTinyInteger('level')->default(1);
            $table->unsignedSmallInteger('streak_days')->default(0);
            $table->unsignedSmallInteger('longest_streak')->default(0);
            $table->date('last_activity_date')->nullable();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
        });

        Schema::create('xp_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->smallInteger('xp_amount'); // can be negative
            $table->string('reason')->nullable();
            $table->string('source', 100)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('milestones', function (Blueprint $table) {
            $table->id();
            $table->string('code', 100)->unique();
            $table->string('title')->nullable();
            $table->text('description')->nullable();
            $table->string('icon', 50)->nullable();
            $table->unsignedSmallInteger('xp_reward')->nullable();
            $table->string('condition_type', 100)->nullable();
            $table->string('condition_value')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('patient_milestones', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('milestone_id')->constrained()->cascadeOnDelete();
            $table->timestamp('achieved_at')->useCurrent();

            $table->unique(['patient_id', 'milestone_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('patient_milestones');
        Schema::dropIfExists('milestones');
        Schema::dropIfExists('xp_transactions');
        Schema::dropIfExists('patient_xp');
    }
};
