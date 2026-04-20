<?php

namespace App\Shared\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    public function sendPush(int $userId, string $title, string $body, array $data = []): void
    {
        try {
            $tokens = $this->getFcmTokens($userId);
            if (empty($tokens)) return;

            Http::withHeaders([
                'Authorization' => 'key=' . config('physioconnect.firebase_server_key'),
                'Content-Type'  => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'registration_ids' => $tokens,
                'notification'     => ['title' => $title, 'body' => $body],
                'data'             => $data,
                'priority'         => 'high',
            ]);

            $this->persistNotification($userId, 'push', $title, $body, $data);
        } catch (\Throwable $e) {
            Log::error('FCM push failed', ['user_id' => $userId, 'error' => $e->getMessage()]);
        }
    }

    public function sendSms(string $phone, string $message): void
    {
        try {
            Http::withBasicAuth(
                config('services.twilio.sid'),
                config('services.twilio.token'),
            )->post('https://api.twilio.com/2010-04-01/Accounts/' . config('services.twilio.sid') . '/Messages.json', [
                'From' => config('services.twilio.from'),
                'To'   => '+91' . ltrim($phone, '+91'),
                'Body' => $message,
            ]);
        } catch (\Throwable $e) {
            Log::error('SMS send failed', ['phone' => $phone, 'error' => $e->getMessage()]);
        }
    }

    public function notifyBookingConfirmed(int $patientUserId, int $physioUserId, array $bookingData): void
    {
        $this->sendPush(
            $patientUserId,
            'Booking Confirmed',
            "Your session on {$bookingData['date']} at {$bookingData['time']} is confirmed.",
            ['type' => 'booking_confirmed', 'booking_uuid' => $bookingData['uuid']],
        );

        $this->sendPush(
            $physioUserId,
            'New Booking',
            "New patient booking on {$bookingData['date']} at {$bookingData['time']}.",
            ['type' => 'new_booking', 'booking_uuid' => $bookingData['uuid']],
        );
    }

    public function notifyPhysioEnRoute(int $patientUserId, array $bookingData): void
    {
        $this->sendPush(
            $patientUserId,
            'Physiotherapist En Route',
            'Your physiotherapist is on the way!',
            ['type' => 'physio_en_route', 'booking_uuid' => $bookingData['uuid']],
        );
    }

    public function notifyNewBookingRequest(int $physioUserId, array $bookingData): void
    {
        $this->sendPush(
            $physioUserId,
            'New Booking Request',
            "New booking request for {$bookingData['date']} at {$bookingData['time']}. Confirm to accept.",
            ['type' => 'new_booking', 'id' => (string) ($bookingData['id'] ?? ''), 'booking_uuid' => $bookingData['uuid']],
        );
    }

    public function notifyBookingCancelled(int $notifyUserId, string $cancelledByName, array $bookingData): void
    {
        $this->sendPush(
            $notifyUserId,
            'Booking Cancelled',
            "Your booking on {$bookingData['date']} was cancelled by {$cancelledByName}.",
            ['type' => 'booking_cancelled', 'id' => (string) ($bookingData['id'] ?? ''), 'booking_uuid' => $bookingData['uuid']],
        );
    }

    public function notifySessionCompleted(int $patientUserId, array $bookingData): void
    {
        $this->sendPush(
            $patientUserId,
            'Session Completed',
            'Your session is complete. Check your rehab plan for today\'s exercises.',
            ['type' => 'session_completed', 'id' => (string) ($bookingData['id'] ?? ''), 'booking_uuid' => $bookingData['uuid']],
        );
    }

    public function notifyPaymentSuccess(int $patientUserId, array $paymentData): void
    {
        $this->sendPush(
            $patientUserId,
            'Payment Successful',
            "Payment of ₹{$paymentData['amount']} received. Your booking is confirmed.",
            ['type' => 'payment_success', 'id' => (string) ($paymentData['booking_id'] ?? ''), 'payment_uuid' => $paymentData['uuid'] ?? ''],
        );
    }

    private function getFcmTokens(int $userId): array
    {
        $token = \DB::table('users')->where('id', $userId)->value('fcm_token');
        return $token ? [$token] : [];
    }

    private function persistNotification(int $userId, string $channel, string $title, string $body, array $data): void
    {
        \DB::table('notifications')->insert([
            'user_id'    => $userId,
            'type'       => $data['type'] ?? 'general',
            'title'      => $title,
            'body'       => $body,
            'data'       => json_encode($data),
            'channel'    => $channel,
            'sent_at'    => now(),
            'created_at' => now(),
        ]);
    }
}
