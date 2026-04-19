<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SubscriptionPlanSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'code'          => 'trial',
                'name'          => 'Free Trial',
                'price_monthly' => 0,
                'price_yearly'  => 0,
                'trial_days'    => 14,
                'max_patients'  => null,
                'features'      => json_encode(['home_visit', 'basic_exercises', 'chat']),
                'is_active'     => true,
            ],
            [
                'code'          => 'pro',
                'name'          => 'PhysioConnect Pro',
                'price_monthly' => 2999,
                'price_yearly'  => 29990,
                'trial_days'    => 0,
                'max_patients'  => null,
                'features'      => json_encode([
                    'home_visit', 'video_consult', 'ai_rehab_plan',
                    'outcome_scores', 'analytics', 'chat', 'exercise_library',
                ]),
                'is_active'     => true,
            ],
            [
                'code'          => 'hospital',
                'name'          => 'Enterprise / Hospital',
                'price_monthly' => 12999,
                'price_yearly'  => 129990,
                'trial_days'    => 0,
                'max_patients'  => null,
                'features'      => json_encode([
                    'home_visit', 'video_consult', 'ai_rehab_plan',
                    'outcome_scores', 'analytics', 'chat', 'exercise_library',
                    'research_dashboard', 'academy', 'multi_physio',
                ]),
                'is_active'     => true,
            ],
        ];

        DB::table('subscription_plans')->insertOrIgnore($plans);
    }
}
