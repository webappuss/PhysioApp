<?php

namespace App\Modules\Payment\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Payment\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(private PaymentService $paymentService) {}

    public function createOrder(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'booking_id' => 'required|integer|exists:bookings,id',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->paymentService->createOrder($request->user(), $validated),
        ], 201);
    }

    public function verify(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'razorpay_order_id'   => 'required|string',
            'razorpay_payment_id' => 'required|string',
            'razorpay_signature'  => 'required|string',
            'payment_method'      => 'sometimes|in:rupay,upi,card,netbanking,emi,wallet',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payment verified successfully.',
            'data'    => $this->paymentService->verify($request->user(), $validated),
        ]);
    }

    // Webhook — no auth middleware, uses signature verification instead
    public function webhook(Request $request): JsonResponse
    {
        $this->paymentService->handleWebhook(
            $request->getContent(),
            $request->header('X-Razorpay-Signature', '')
        );

        return response()->json(['status' => 'ok']);
    }

    public function history(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->paymentService->history($request->user()),
        ]);
    }

    public function createPackage(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'physio_id'      => 'required|integer|exists:physiotherapist_profiles,id',
            'total_sessions' => 'required|integer|min:2|max:30',
            'package_amount' => 'required|numeric|min:100',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Session package created.',
            'data'    => $this->paymentService->createPackage($request->user(), $validated),
        ], 201);
    }
}
