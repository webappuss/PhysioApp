<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Seeds 10 demo physiotherapists in Ahmedabad for development/staging testing.
 * NOT called from DatabaseSeeder — run manually: php artisan db:seed --class=DemoPhysioSeeder
 */
class DemoPhysioSeeder extends Seeder
{
    public function run(): void
    {
        $physios = [
            [
                'name'            => 'Dr. Priya Sharma',
                'phone'           => '9876543201',
                'specializations' => ['Orthopedic', 'Sports Rehabilitation'],
                'experience'      => 8,
                'consultation_fee'=> 800,
                'home_visit_fee'  => 1200,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0225,
                'lng'             => 72.5714,
                'bio'             => 'Specialist in post-surgical rehab and sports injury recovery.',
            ],
            [
                'name'            => 'Dr. Rahul Patel',
                'phone'           => '9876543202',
                'specializations' => ['Neurological', 'Stroke Rehabilitation'],
                'experience'      => 12,
                'consultation_fee'=> 1000,
                'home_visit_fee'  => 1500,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0395,
                'lng'             => 72.5560,
                'bio'             => '12 years experience in neuro rehab including stroke and Parkinson\'s.',
            ],
            [
                'name'            => 'Dr. Meena Joshi',
                'phone'           => '9876543203',
                'specializations' => ['Pediatric', 'Developmental'],
                'experience'      => 6,
                'consultation_fee'=> 700,
                'home_visit_fee'  => 1100,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0105,
                'lng'             => 72.5050,
                'bio'             => 'Dedicated paediatric physiotherapist helping children achieve motor milestones.',
            ],
            [
                'name'            => 'Dr. Arjun Mehta',
                'phone'           => '9876543204',
                'specializations' => ['Spine', 'Manual Therapy'],
                'experience'      => 10,
                'consultation_fee'=> 900,
                'home_visit_fee'  => 1400,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0469,
                'lng'             => 72.6300,
                'bio'             => 'Manual therapy certified with a focus on lumbar and cervical conditions.',
            ],
            [
                'name'            => 'Dr. Sunita Desai',
                'phone'           => '9876543205',
                'specializations' => ['Women\'s Health', 'Pelvic Floor'],
                'experience'      => 7,
                'consultation_fee'=> 850,
                'home_visit_fee'  => 1250,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0302,
                'lng'             => 72.5870,
                'bio'             => 'Specialising in women\'s health physio, antenatal and postnatal care.',
            ],
            [
                'name'            => 'Dr. Vikram Shah',
                'phone'           => '9876543206',
                'specializations' => ['Geriatric', 'Balance & Falls Prevention'],
                'experience'      => 15,
                'consultation_fee'=> 950,
                'home_visit_fee'  => 1350,
                'city'            => 'Ahmedabad',
                'lat'             => 22.9956,
                'lng'             => 72.5992,
                'bio'             => '15 years of geriatric physio and community falls prevention programs.',
            ],
            [
                'name'            => 'Dr. Kavya Nair',
                'phone'           => '9876543207',
                'specializations' => ['Cardiopulmonary', 'ICU Rehab'],
                'experience'      => 9,
                'consultation_fee'=> 1000,
                'home_visit_fee'  => 1500,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0550,
                'lng'             => 72.5400,
                'bio'             => 'Cardiorespiratory specialist trained in ICU early mobility and COPD rehab.',
            ],
            [
                'name'            => 'Dr. Deepak Verma',
                'phone'           => '9876543208',
                'specializations' => ['Orthopedic', 'Post-Surgical'],
                'experience'      => 5,
                'consultation_fee'=> 750,
                'home_visit_fee'  => 1100,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0130,
                'lng'             => 72.5710,
                'bio'             => 'Fresh energy and evidence-based orthopaedic rehabilitation.',
            ],
            [
                'name'            => 'Dr. Anjali Gupta',
                'phone'           => '9876543209',
                'specializations' => ['Sports', 'Dry Needling'],
                'experience'      => 11,
                'consultation_fee'=> 900,
                'home_visit_fee'  => 1300,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0280,
                'lng'             => 72.6150,
                'bio'             => 'Sports physio for cricketers and athletes. Certified in dry needling.',
            ],
            [
                'name'            => 'Dr. Kiran Modi',
                'phone'           => '9876543210',
                'specializations' => ['Hand Therapy', 'Ergonomics'],
                'experience'      => 8,
                'consultation_fee'=> 800,
                'home_visit_fee'  => 1200,
                'city'            => 'Ahmedabad',
                'lat'             => 23.0450,
                'lng'             => 72.5800,
                'bio'             => 'Hand and upper limb specialist with ergonomics expertise for desk workers.',
            ],
        ];

        foreach ($physios as $physio) {
            // Create user
            $userId = DB::table('users')->insertGetId([
                'uuid'               => Str::uuid(),
                'phone'              => $physio['phone'],
                'name'               => $physio['name'],
                'role'               => 'physiotherapist',
                'status'             => 'active',
                'phone_verified_at'  => now(),
                'created_at'         => now(),
                'updated_at'         => now(),
            ]);

            // Create physio profile
            DB::table('physiotherapist_profiles')->insertOrIgnore([
                'user_id'                  => $userId,
                'specializations'          => json_encode($physio['specializations']),
                'experience_years'         => $physio['experience'],
                'consultation_fee'         => $physio['consultation_fee'],
                'home_visit_fee'           => $physio['home_visit_fee'],
                'bio'                      => $physio['bio'],
                'city'                     => $physio['city'],
                'current_latitude'         => $physio['lat'],
                'current_longitude'        => $physio['lng'],
                'verification_status'      => 'approved',
                'is_available_for_booking' => true,
                'accepts_home_visits'      => true,
                'accepts_video_consult'    => true,
                'rating'                   => round(4.0 + lcg_value() * 1.0, 1),
                'total_reviews'            => rand(5, 120),
                'total_sessions'           => rand(20, 500),
                'created_at'               => now(),
                'updated_at'               => now(),
            ]);
        }

        $this->command->info('Seeded 10 demo physiotherapists in Ahmedabad.');
    }
}
