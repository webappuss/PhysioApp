<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Requests\SendOtpRequest;
use App\Modules\Auth\Requests\VerifyOtpRequest;
use App\Modules\Auth\Services\AuthService;
use App\Modules\Auth\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private OtpService  $otpService,
        private AuthService $authService,
    ) {}

    public function sendOtp(SendOtpRequest $request): JsonResponse
    {
        $this->otpService->send($request->phone, $request->purpose ?? 'login');

        return response()->json([
            'success' => true,
            'message' => 'OTP sent successfully.',
        ]);
    }

    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $this->otpService->verify($request->phone, $request->otp, $request->purpose ?? 'login');

        $user   = $this->authService->findOrCreateUser($request->phone, $request->role ?? 'patient');
        $result = $this->authService->issueToken($user);

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data'    => $result,
        ]);
    }

    public function refreshToken(Request $request): JsonResponse
    {
        $user   = $request->user();
        $result = $this->authService->issueToken($user);

        return response()->json([
            'success' => true,
            'data'    => $result,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->authService->userResource($request->user()),
        ]);
    }
}
