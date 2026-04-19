<?php

use App\Http\Middleware\ForceJson;
use App\Shared\Middleware\SanitizeInput;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->api(prepend: [
            ForceJson::class,
        ]);

        $middleware->append(SanitizeInput::class);

        $middleware->alias([
            'role'       => \App\Shared\Middleware\CheckRole::class,
            'ai.limit'   => \App\Shared\Middleware\RateLimitAI::class,
            'audit'      => \App\Shared\Middleware\AuditAccess::class,
        ]);

        $middleware->throttleWithRedis();
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->render(function (NotFoundHttpException $e, Request $request) {
            return response()->json([
                'success' => false,
                'message' => 'Resource not found.',
                'code'    => 'NOT_FOUND',
            ], 404);
        });

        $exceptions->render(function (\Illuminate\Validation\ValidationException $e, Request $request) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
                'code'    => 'VALIDATION_ERROR',
            ], 422);
        });

        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, Request $request) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
                'code'    => 'UNAUTHENTICATED',
            ], 401);
        });

        $exceptions->render(function (\Illuminate\Auth\Access\AuthorizationException $e, Request $request) {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden.',
                'code'    => 'FORBIDDEN',
            ], 403);
        });
    })->create();
