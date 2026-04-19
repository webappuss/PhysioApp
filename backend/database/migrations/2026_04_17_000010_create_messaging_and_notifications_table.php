<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->nullable()->constrained('physiotherapist_profiles')->nullOnDelete();
            $table->foreignId('surgeon_id')->nullable()->constrained('surgeon_profiles')->nullOnDelete();
            $table->foreignId('psychologist_id')->nullable()->constrained('psychologist_profiles')->nullOnDelete();
            $table->enum('type', ['patient_physio', 'care_team', 'patient_surgeon', 'patient_psych']);
            $table->timestamp('last_message_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users');
            $table->enum('sender_role', ['patient', 'physiotherapist', 'surgeon', 'psychologist', 'ai']);
            $table->enum('message_type', ['text', 'image', 'file', 'ai_insight', 'exercise_update']);
            $table->text('content')->nullable(); // encrypted
            $table->string('file_url', 500)->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['conversation_id', 'created_at']);
        });

        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles');
            $table->decimal('overall_rating', 2, 1);
            $table->unsignedTinyInteger('punctuality')->nullable();
            $table->unsignedTinyInteger('expertise')->nullable();
            $table->unsignedTinyInteger('communication')->nullable();
            $table->text('review_text')->nullable();
            $table->boolean('is_visible')->default(true);
            $table->timestamp('created_at')->useCurrent();

            $table->unique('booking_id');
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 100)->nullable();
            $table->string('title')->nullable();
            $table->text('body')->nullable();
            $table->json('data')->nullable();
            $table->enum('channel', ['push', 'sms', 'email', 'in_app'])->default('push');
            $table->timestamp('read_at')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'read_at']);
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('user_role', 50)->nullable();
            $table->string('action');
            $table->string('resource', 100)->nullable();
            $table->foreignId('resource_id')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'action', 'created_at']);
            $table->index(['resource', 'resource_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('reviews');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
    }
};
