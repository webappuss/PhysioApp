<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            SubscriptionPlanSeeder::class,
            OutcomeScoreDefinitionSeeder::class,
            ExerciseSeeder::class,
            MilestoneSeeder::class,
            AdminUserSeeder::class,
        ]);
    }
}
