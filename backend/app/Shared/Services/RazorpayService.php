<?php

namespace App\Shared\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class RazorpayService
{
    private string $keyId;
    private string $keySecret;
    private string $baseUrl = 'https://api.razorpay.com/v1';

    public function __construct()
    {
        $this->keyId     = config('razorpay.key_id');
        $this->keySecret = config('razorpay.key_secret');
    }

    public function createOrder(int $amountPaise, string $receiptId, array $notes = []): array
    {
        $response = Http::withBasicAuth($this->keyId, $this->keySecret)
            ->post("{$this->baseUrl}/orders", [
                'amount'          => $amountPaise,
                'currency'        => 'INR',
                'receipt'         => $receiptId,
                'notes'           => $notes,
                'payment_capture' => 1,
            ]);

        if ($response->failed()) {
            throw new \RuntimeException('Razorpay order creation failed: ' . $response->body());
        }

        return $response->json();
    }

    public function verifyPaymentSignature(string $orderId, string $paymentId, string $signature): bool
    {
        $expectedSignature = hash_hmac(
            'sha256',
            "{$orderId}|{$paymentId}",
            $this->keySecret
        );

        return hash_equals($expectedSignature, $signature);
    }

    public function verifyWebhookSignature(string $payload, string $signature): bool
    {
        $expectedSignature = hash_hmac('sha256', $payload, config('razorpay.webhook_secret'));
        return hash_equals($expectedSignature, $signature);
    }

    public function capturePayment(string $paymentId, int $amountPaise): array
    {
        $response = Http::withBasicAuth($this->keyId, $this->keySecret)
            ->post("{$this->baseUrl}/payments/{$paymentId}/capture", [
                'amount'   => $amountPaise,
                'currency' => 'INR',
            ]);

        if ($response->failed()) {
            throw new \RuntimeException('Razorpay capture failed: ' . $response->body());
        }

        return $response->json();
    }

    public function refundPayment(string $paymentId, int $amountPaise, string $reason = ''): array
    {
        $response = Http::withBasicAuth($this->keyId, $this->keySecret)
            ->post("{$this->baseUrl}/payments/{$paymentId}/refund", [
                'amount' => $amountPaise,
                'notes'  => ['reason' => $reason],
            ]);

        if ($response->failed()) {
            throw new \RuntimeException('Razorpay refund failed: ' . $response->body());
        }

        return $response->json();
    }

    public function createPayout(string $fundAccountId, int $amountPaise, string $purpose, string $narration = ''): array
    {
        $response = Http::withBasicAuth($this->keyId, $this->keySecret)
            ->post("{$this->baseUrl}/payouts", [
                'account_number' => config('razorpay.payout_account'),
                'fund_account_id' => $fundAccountId,
                'amount'          => $amountPaise,
                'currency'        => 'INR',
                'mode'            => 'IMPS',
                'purpose'         => $purpose,
                'narration'       => $narration ?: 'PhysioConnect earnings payout',
            ]);

        if ($response->failed()) {
            throw new \RuntimeException('Razorpay payout failed: ' . $response->body());
        }

        return $response->json();
    }

    public function calculateFees(float $sessionFee, string $bookingType = 'home_visit'): array
    {
        $commissionPct = $bookingType === 'home_visit'
            ? config('physioconnect.commission.home_visit_percent', 15)
            : config('physioconnect.commission.video_percent', 12);

        $platformFee  = round($sessionFee * ($commissionPct / 100), 2)
            + config('physioconnect.commission.fixed_fee', 50);
        $gst          = round($platformFee * (config('physioconnect.commission.gst_percent', 18) / 100), 2);
        $totalCharged = $sessionFee + $platformFee + $gst;
        $physioEarns  = $sessionFee - round($sessionFee * ($commissionPct / 100), 2);

        return [
            'session_fee'     => $sessionFee,
            'platform_fee'    => $platformFee,
            'gst'             => $gst,
            'total_amount'    => $totalCharged,
            'physio_earning'  => $physioEarns,
            'amount_paise'    => (int) round($totalCharged * 100),
        ];
    }
}
