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

    private function getFcmTokens(int $userId): array
    {
        // Fetch FCM tokens from a device_tokens table (simplified for Phase 1)
        return \DB::table('device_tokens')
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->pluck('token')
            ->toArray();
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
