<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class RateLimitAI
{
    public function handle(Request $request, Closure $next): Response
    {
        $user     = $request->user();
        $limit    = config('physioconnect.ai.rate_per_minute', 10);
        $key      = "ai_rate:{$user->id}";
        $current  = (int) Cache::get($key, 0);

        if ($current >= $limit) {
            return response()->json([
                'success' => false,
                'message' => 'AI request limit reached. Please wait before making another AI request.',
                'code'    => 'AI_RATE_LIMIT',
            ], 429);
        }

        Cache::put($key, $current + 1, now()->addMinute());

        return $next($request);
    }
}
