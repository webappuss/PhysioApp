<?php

namespace App\Modules\Payment\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use App\Shared\Services\NotificationService;
use App\Shared\Services\RazorpayService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PaymentService
{
    public function __construct(
        private RazorpayService     $razorpayService,
        private AuditLogger         $auditLogger,
        private NotificationService $notificationService,
    ) {}

    public function createOrder(User $user, array $data): array
    {
        $patientProfile = DB::table('patient_profiles')->where('user_id', $user->id)->firstOrFail();
        $booking        = DB::table('bookings')->find($data['booking_id']);
        abort_if(! $booking, 404, 'Booking not found.');
        abort_unless($booking->patient_id === $patientProfile->id, 403, 'Not your booking.');

        $receiptId = 'RCP-' . strtoupper(Str::random(10));
        $order     = $this->razorpayService->createOrder(
            (int) round($booking->total_amount * 100),
            $receiptId,
            ['booking_uuid' => $booking->uuid]
        );

        // Persist payment record
        $paymentId = DB::table('payments')->insertGetId([
            'uuid'              => (string) Str::uuid(),
            'patient_id'        => $patientProfile->id,
            'booking_id'        => $booking->id,
            'amount'            => $booking->total_amount,
            'razorpay_order_id' => $order['id'],
            'status'            => 'created',
            'metadata'          => json_encode(['receipt' => $receiptId]),
            'created_at'        => now(),
            'updated_at'        => now(),
        ]);

        $this->auditLogger->log($user, 'create_payment_order', 'payments', $paymentId);

        return [
            'razorpay_order_id' => $order['id'],
            'amount'            => $booking->total_amount,
            'amount_paise'      => (int) round($booking->total_amount * 100),
            'currency'          => 'INR',
            'key_id'            => config('razorpay.key_id'),
            'payment_id'        => $paymentId,
        ];
    }

    public function verify(User $user, array $data): array
    {
        $valid = $this->razorpayService->verifyPaymentSignature(
            $data['razorpay_order_id'],
            $data['razorpay_payment_id'],
            $data['razorpay_signature'],
        );

        if (! $valid) {
            $this->auditLogger->log($user, 'payment_signature_invalid', 'payments', null, [], $data);
            throw ValidationException::withMessages(['signature' => ['Payment verification failed. Please contact support.']]);
        }

        $payment = DB::table('payments')
            ->where('razorpay_order_id', $data['razorpay_order_id'])
            ->firstOrFail();

        DB::table('payments')->where('id', $payment->id)->update([
            'razorpay_payment_id' => $data['razorpay_payment_id'],
            'razorpay_signature'  => $data['razorpay_signature'],
            'payment_method'      => $data['payment_method'] ?? null,
            'status'              => 'captured',
            'captured_at'         => now(),
            'updated_at'          => now(),
        ]);

        // Update booking payment status
        if ($payment->booking_id) {
            DB::table('bookings')->where('id', $payment->booking_id)->update([
                'payment_status' => 'captured',
                'payment_id'     => $payment->id,
                'status'         => 'confirmed',
                'confirmed_at'   => now(),
                'updated_at'     => now(),
            ]);
        }

        $this->auditLogger->log($user, 'payment_verified', 'payments', $payment->id);

        $this->notificationService->notifyPaymentSuccess($user->id, [
            'amount'     => number_format($payment->amount / 100, 2),
            'booking_id' => $payment->booking_id,
            'uuid'       => $payment->uuid ?? '',
        ]);

        return (array) DB::table('payments')->find($payment->id);
    }

    public function handleWebhook(string $payload, string $signature): void
    {
        if (! $this->razorpayService->verifyWebhookSignature($payload, $signature)) {
            Log::warning('Razorpay webhook: invalid signature');
            abort(400, 'Invalid webhook signature.');
        }

        $event = json_decode($payload, true);
        $eventType = $event['event'] ?? '';

        match ($eventType) {
            'payment.captured'  => $this->onPaymentCaptured($event),
            'payment.failed'    => $this->onPaymentFailed($event),
            'refund.processed'  => $this->onRefundProcessed($event),
            default             => null,
        };
    }

    public function history(User $user): array
    {
        $patientProfile = DB::table('patient_profiles')->where('user_id', $user->id)->firstOrFail();

        return DB::table('payments')
            ->where('patient_id', $patientProfile->id)
            ->orderByDesc('created_at')
            ->get()
            ->toArray();
    }

    public function createPackage(User $user, array $data): array
    {
        $patientProfile = DB::table('patient_profiles')->where('user_id', $user->id)->firstOrFail();

        $packageId = DB::table('session_packages')->insertGetId([
            'patient_id'      => $patientProfile->id,
            'physio_id'       => $data['physio_id'],
            'total_sessions'  => $data['total_sessions'],
            'package_amount'  => $data['package_amount'],
            'status'          => 'active',
            'expires_at'      => now()->addMonths(3)->toDateString(),
            'created_at'      => now(),
        ]);

        $this->auditLogger->log($user, 'create_session_package', 'session_packages', $packageId);

        return (array) DB::table('session_packages')->find($packageId);
    }

    private function onPaymentCaptured(array $event): void
    {
        $paymentId = $event['payload']['payment']['entity']['id'] ?? null;
        if (! $paymentId) return;

        DB::table('payments')
            ->where('razorpay_payment_id', $paymentId)
            ->update(['status' => 'captured', 'captured_at' => now(), 'updated_at' => now()]);
    }

    private function onPaymentFailed(array $event): void
    {
        $paymentId = $event['payload']['payment']['entity']['id'] ?? null;
        if (! $paymentId) return;

        DB::table('payments')
            ->where('razorpay_payment_id', $paymentId)
            ->update(['status' => 'failed', 'updated_at' => now()]);
    }

    private function onRefundProcessed(array $event): void
    {
        $paymentId = $event['payload']['refund']['entity']['payment_id'] ?? null;
        $amount    = $event['payload']['refund']['entity']['amount'] ?? 0;
        if (! $paymentId) return;

        DB::table('payments')
            ->where('razorpay_payment_id', $paymentId)
            ->update([
                'status'        => 'refunded',
                'refunded_at'   => now(),
                'refund_amount' => $amount / 100,
                'updated_at'    => now(),
            ]);
    }
}
