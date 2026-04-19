<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user || ! $user->hasRole($roles)) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to perform this action.',
                'code'    => 'FORBIDDEN',
            ], 403);
        }

        if ($user->status === 'suspended') {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been suspended. Please contact support.',
                'code'    => 'ACCOUNT_SUSPENDED',
            ], 403);
        }

        return $next($request);
    }
}
