<?php

use Illuminate\Support\Facades\Schedule;

/*
|--------------------------------------------------------------------------
| PhysioConnect Scheduled Tasks
|--------------------------------------------------------------------------
*/

// Weekly physio payout calculation — every Friday at 09:00 IST
Schedule::command('physio:calculate-payouts')->weeklyOn(5, '09:00');

// Clean expired OTPs daily
Schedule::command('otp:cleanup')->daily();

// Send exercise reminder pushes — every morning at 07:30
Schedule::command('notify:exercise-reminders')->dailyAt('07:30');
