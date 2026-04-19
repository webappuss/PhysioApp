<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('package_id')->nullable(); // constrained after session_packages created
            $table->foreignId('subscription_id')->nullable()->constrained('subscriptions')->nullOnDelete();
            $table->decimal('amount', 10, 2);
            $table->char('currency', 3)->default('INR');
            $table->enum('payment_method', ['rupay', 'upi', 'card', 'netbanking', 'emi', 'wallet'])->nullable();
            $table->string('razorpay_order_id')->nullable();
            $table->string('razorpay_payment_id')->nullable();
            $table->string('razorpay_signature', 500)->nullable();
            $table->enum('status', ['created', 'authorized', 'captured', 'refunded', 'failed'])->default('created');
            $table->timestamp('captured_at')->nullable();
            $table->timestamp('refunded_at')->nullable();
            $table->decimal('refund_amount', 10, 2)->nullable();
            $table->text('refund_reason')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index('razorpay_payment_id');
        });

        Schema::create('session_packages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles');
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles');
            $table->unsignedTinyInteger('total_sessions');
            $table->unsignedTinyInteger('used_sessions')->default(0);
            $table->decimal('package_amount', 10, 2);
            $table->foreignId('payment_id')->nullable()->constrained('payments')->nullOnDelete();
            $table->enum('status', ['active', 'exhausted', 'expired', 'refunded'])->default('active');
            $table->date('expires_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('physio_payouts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('physio_id')->constrained('physiotherapist_profiles');
            $table->date('period_from');
            $table->date('period_to');
            $table->decimal('gross_amount', 10, 2)->nullable();
            $table->decimal('platform_commission', 10, 2)->nullable();
            $table->decimal('net_amount', 10, 2)->nullable();
            $table->unsignedInteger('sessions_count')->nullable();
            $table->enum('status', ['pending', 'processing', 'paid', 'failed'])->default('pending');
            $table->string('razorpay_payout_id')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('physio_payouts');
        Schema::dropIfExists('session_packages');
        Schema::dropIfExists('payments');
    }
};
