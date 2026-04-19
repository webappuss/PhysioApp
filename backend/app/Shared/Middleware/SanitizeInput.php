<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SanitizeInput
{
    private array $except = ['password', 'otp', 'razorpay_signature'];

    public function handle(Request $request, Closure $next): Response
    {
        $input = $request->all();
        $request->replace($this->sanitize($input));

        return $next($request);
    }

    private function sanitize(array $data): array
    {
        foreach ($data as $key => $value) {
            if (in_array($key, $this->except)) continue;

            if (is_array($value)) {
                $data[$key] = $this->sanitize($value);
            } elseif (is_string($value)) {
                $data[$key] = strip_tags(trim($value));
            }
        }

        return $data;
    }
}
