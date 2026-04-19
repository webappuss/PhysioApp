<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('surgeon_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('hospital_name')->nullable();
            $table->string('designation')->nullable();
            $table->string('specialization')->nullable();
            $table->string('registration_number', 100)->nullable();
            $table->string('mci_number', 100)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('psychologist_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('qualification')->nullable();
            $table->string('rci_registration', 100)->nullable();
            $table->string('specialization')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('care_teams', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->nullable()->constrained('physiotherapist_profiles')->nullOnDelete();
            $table->foreignId('surgeon_id')->nullable()->constrained('surgeon_profiles')->nullOnDelete();
            $table->foreignId('psychologist_id')->nullable()->constrained('psychologist_profiles')->nullOnDelete();
            $table->string('primary_condition')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('care_teams');
        Schema::dropIfExists('psychologist_profiles');
        Schema::dropIfExists('surgeon_profiles');
    }
};
