<?php

namespace App\Modules\Discovery\Services;

use Illuminate\Support\Facades\DB;

class DiscoveryService
{
    public function searchPhysios(array $filters): array
    {
        $lat        = $filters['latitude'] ?? null;
        $lng        = $filters['longitude'] ?? null;
        $radius     = $filters['radius_km'] ?? config('physioconnect.maps.default_radius_km', 10);
        $specialty  = $filters['specialty'] ?? null;
        $bookingType= $filters['booking_type'] ?? null;
        $minRating  = $filters['min_rating'] ?? 0;
        $perPage    = min((int) ($filters['per_page'] ?? 20), 50);

        $query = DB::table('physiotherapist_profiles')
            ->join('users', 'physiotherapist_profiles.user_id', '=', 'users.id')
            ->where('physiotherapist_profiles.is_verified', true)
            ->where('physiotherapist_profiles.is_available', true)
            ->where('users.status', 'active')
            ->where('physiotherapist_profiles.rating', '>=', $minRating)
            ->select(
                'physiotherapist_profiles.id',
                'users.name',
                'users.avatar_url',
                'physiotherapist_profiles.qualification',
                'physiotherapist_profiles.specializations',
                'physiotherapist_profiles.years_experience',
                'physiotherapist_profiles.home_visit_charge',
                'physiotherapist_profiles.video_consult_charge',
                'physiotherapist_profiles.rating',
                'physiotherapist_profiles.total_reviews',
                'physiotherapist_profiles.total_sessions',
                'physiotherapist_profiles.service_radius_km',
                'physiotherapist_profiles.current_latitude',
                'physiotherapist_profiles.current_longitude',
            );

        // Geolocation filter with Haversine formula
        if ($lat && $lng) {
            $query->selectRaw(
                '(6371 * acos(cos(radians(?)) * cos(radians(current_latitude))
                 * cos(radians(current_longitude) - radians(?))
                 + sin(radians(?)) * sin(radians(current_latitude)))) AS distance_km',
                [$lat, $lng, $lat]
            )
            ->whereNotNull('physiotherapist_profiles.current_latitude')
            ->havingRaw('distance_km <= ?', [$radius])
            ->orderBy('distance_km');
        } else {
            $query->orderByDesc('physiotherapist_profiles.rating');
        }

        if ($specialty) {
            $query->whereJsonContains('physiotherapist_profiles.specializations', $specialty);
        }

        if ($bookingType === 'home_visit') {
            $query->whereNotNull('physiotherapist_profiles.home_visit_charge');
        } elseif ($bookingType === 'video_consult') {
            $query->whereNotNull('physiotherapist_profiles.video_consult_charge');
        }

        $results = $query->paginate($perPage);

        return [
            'data'       => $results->items(),
            'pagination' => [
                'current_page' => $results->currentPage(),
                'per_page'     => $results->perPage(),
                'total'        => $results->total(),
                'last_page'    => $results->lastPage(),
            ],
        ];
    }

    public function getPhysioDetail(int $physioId): array
    {
        $profile = DB::table('physiotherapist_profiles')
            ->join('users', 'physiotherapist_profiles.user_id', '=', 'users.id')
            ->where('physiotherapist_profiles.id', $physioId)
            ->where('physiotherapist_profiles.is_verified', true)
            ->select(
                'physiotherapist_profiles.*',
                'users.name',
                'users.avatar_url',
            )
            ->firstOrFail();

        $reviews = DB::table('reviews')
            ->join('patient_profiles', 'reviews.patient_id', '=', 'patient_profiles.id')
            ->join('users', 'patient_profiles.user_id', '=', 'users.id')
            ->where('reviews.physio_id', $physioId)
            ->where('reviews.is_visible', true)
            ->select('reviews.*', 'users.name as patient_name')
            ->orderByDesc('reviews.created_at')
            ->limit(10)
            ->get();

        return [
            'profile' => $profile,
            'reviews' => $reviews,
        ];
    }

    public function getAvailableSlots(int $physioId, string $date): array
    {
        $dayOfWeek = date('w', strtotime($date)); // 0=Sunday

        $slots = DB::table('physiotherapist_availability')
            ->where('physio_id', $physioId)
            ->where('day_of_week', $dayOfWeek)
            ->where('is_active', true)
            ->get();

        $blockedSlots = DB::table('physio_blocked_slots')
            ->where('physio_id', $physioId)
            ->where('blocked_date', $date)
            ->get();

        $bookedTimes = DB::table('bookings')
            ->where('physio_id', $physioId)
            ->where('scheduled_date', $date)
            ->whereNotIn('status', ['cancelled', 'no_show'])
            ->pluck('scheduled_time')
            ->toArray();

        $available = [];
        foreach ($slots as $slot) {
            $times = $this->generateTimeSlots($slot->start_time, $slot->end_time, 60);
            foreach ($times as $time) {
                $blocked = $blockedSlots->first(
                    fn($b) => (! $b->start_time) ||
                        ($time >= $b->start_time && $time < $b->end_time)
                );
                if (! $blocked && ! in_array($time, $bookedTimes)) {
                    $available[] = $time;
                }
            }
        }

        return $available;
    }

    private function generateTimeSlots(string $start, string $end, int $intervalMins): array
    {
        $slots   = [];
        $current = strtotime($start);
        $endTs   = strtotime($end);

        while ($current < $endTs) {
            $slots[]  = date('H:i:s', $current);
            $current += $intervalMins * 60;
        }

        return $slots;
    }
}
