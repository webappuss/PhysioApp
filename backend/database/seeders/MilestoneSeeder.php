<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MilestoneSeeder extends Seeder
{
    public function run(): void
    {
        $milestones = [
            // ── CHECK-IN STREAKS ──────────────────────────────────────────
            [
                'code'        => 'CHECKIN_1',
                'title'       => 'First Check-in',
                'description' => 'Completed your very first daily check-in.',
                'icon'        => '🌱',
                'xp_reward'   => 10,
                'category'    => 'checkin',
                'threshold'   => 1,
                'is_active'   => true,
            ],
            [
                'code'        => 'CHECKIN_7',
                'title'       => '7-Day Streak',
                'description' => 'Checked in every day for a week.',
                'icon'        => '🔥',
                'xp_reward'   => 50,
                'category'    => 'checkin',
                'threshold'   => 7,
                'is_active'   => true,
            ],
            [
                'code'        => 'CHECKIN_30',
                'title'       => '30-Day Streak',
                'description' => 'A month of consistent daily check-ins.',
                'icon'        => '💎',
                'xp_reward'   => 200,
                'category'    => 'checkin',
                'threshold'   => 30,
                'is_active'   => true,
            ],
            [
                'code'        => 'CHECKIN_100',
                'title'       => '100-Day Champion',
                'description' => '100 consecutive days of check-ins. Extraordinary dedication.',
                'icon'        => '🏆',
                'xp_reward'   => 500,
                'category'    => 'checkin',
                'threshold'   => 100,
                'is_active'   => true,
            ],

            // ── EXERCISE COMPLETIONS ──────────────────────────────────────
            [
                'code'        => 'EXERCISE_1',
                'title'       => 'First Rep',
                'description' => 'Completed your first exercise session.',
                'icon'        => '💪',
                'xp_reward'   => 15,
                'category'    => 'exercise',
                'threshold'   => 1,
                'is_active'   => true,
            ],
            [
                'code'        => 'EXERCISE_10',
                'title'       => 'Getting Stronger',
                'description' => 'Completed 10 exercise sessions.',
                'icon'        => '🏋️',
                'xp_reward'   => 75,
                'category'    => 'exercise',
                'threshold'   => 10,
                'is_active'   => true,
            ],
            [
                'code'        => 'EXERCISE_50',
                'title'       => 'Fitness Warrior',
                'description' => 'Completed 50 exercise sessions.',
                'icon'        => '⚡',
                'xp_reward'   => 300,
                'category'    => 'exercise',
                'threshold'   => 50,
                'is_active'   => true,
            ],
            [
                'code'        => 'EXERCISE_100',
                'title'       => 'Century Club',
                'description' => '100 exercise sessions completed.',
                'icon'        => '🎯',
                'xp_reward'   => 750,
                'category'    => 'exercise',
                'threshold'   => 100,
                'is_active'   => true,
            ],

            // ── SESSIONS (physio visits) ──────────────────────────────────
            [
                'code'        => 'SESSION_1',
                'title'       => 'First Session',
                'description' => 'Completed your first physiotherapy session.',
                'icon'        => '🩺',
                'xp_reward'   => 25,
                'category'    => 'session',
                'threshold'   => 1,
                'is_active'   => true,
            ],
            [
                'code'        => 'SESSION_5',
                'title'       => 'Committed Patient',
                'description' => 'Completed 5 physiotherapy sessions.',
                'icon'        => '⭐',
                'xp_reward'   => 100,
                'category'    => 'session',
                'threshold'   => 5,
                'is_active'   => true,
            ],
            [
                'code'        => 'SESSION_20',
                'title'       => 'Recovery Pro',
                'description' => 'Completed 20 physiotherapy sessions.',
                'icon'        => '🌟',
                'xp_reward'   => 400,
                'category'    => 'session',
                'threshold'   => 20,
                'is_active'   => true,
            ],

            // ── PAIN REDUCTION ───────────────────────────────────────────
            [
                'code'        => 'PAIN_HALVED',
                'title'       => 'Pain Halved',
                'description' => 'Your pain score dropped by 50% since starting rehab.',
                'icon'        => '💊',
                'xp_reward'   => 150,
                'category'    => 'outcome',
                'threshold'   => 50,
                'is_active'   => true,
            ],
            [
                'code'        => 'PAIN_FREE',
                'title'       => 'Pain Free',
                'description' => 'Reported zero pain on a check-in. Keep it up!',
                'icon'        => '🌈',
                'xp_reward'   => 200,
                'category'    => 'outcome',
                'threshold'   => 0,
                'is_active'   => true,
            ],

            // ── LEVELS ────────────────────────────────────────────────────
            [
                'code'        => 'LEVEL_5',
                'title'       => 'Level 5 Reached',
                'description' => 'You\'ve reached level 5 on PhysioConnect.',
                'icon'        => '🚀',
                'xp_reward'   => 100,
                'category'    => 'level',
                'threshold'   => 5,
                'is_active'   => true,
            ],
            [
                'code'        => 'LEVEL_10',
                'title'       => 'Level 10 Reached',
                'description' => 'You\'ve reached level 10 — a true PhysioConnect champion.',
                'icon'        => '👑',
                'xp_reward'   => 500,
                'category'    => 'level',
                'threshold'   => 10,
                'is_active'   => true,
            ],
        ];

        $now = now()->toDateTimeString();
        foreach ($milestones as &$m) {
            $m['created_at'] = $now;
            $m['updated_at'] = $now;
        }

        DB::table('milestones')->insertOrIgnore($milestones);
    }
}
