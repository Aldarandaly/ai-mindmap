<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Services\PaymobService;
use App\Services\PlanService;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    protected $planService;

    public function __construct(PlanService $planService)
    {
        $this->planService = $planService;
    }

    // Get all plans
    public function plans()
    {
        return response()->json([
            'plans'  => PlanService::PLANS,
            'prices' => PlanService::PRICES,
        ]);
    }

    // Current user plan
    public function currentPlan(Request $request)
    {
        return response()->json(
            $this->planService->getUserPlanInfo($request->user())
        );
    }

    // Initiate payment
    public function initiate(Request $request, PaymobService $paymob)
    {
        try {
            $request->validate([
                'plan' => 'required|in:pro,enterprise',
                'billing_cycle' => 'required|in:monthly,annual',
            ]);

            $amount = PlanService::PRICES[$request->plan][$request->billing_cycle];

            $subscription = Subscription::create([
                'user_id'        => $request->user()->id,
                'plan'           => $request->plan,
                'billing_cycle'  => $request->billing_cycle,
                'amount'         => $amount,
                'payment_method' => 'paymob',
                'status'         => 'pending',
            ]);

            $token = $paymob->auth();

            $order = $paymob->createOrder($token, $amount, $subscription->id . '_' . time());

            $paymentKey = $paymob->paymentKey($token, $order['id'], $amount, [
                "first_name"   => $request->user()->name,
                "last_name"    => "user",
                "email"        => $request->user()->email,
                "phone_number" => "01000000000",
                "city"         => "Cairo",
                "country"      => "EG",
                "street"       => "NA",
                "building"     => "NA",
                "floor"        => "NA",
                "apartment"    => "NA",
            ]);


            $iframeId = env('PAYMOB_IFRAME_ID');
            $paymentUrl = "https://accept.paymob.com/api/acceptance/iframes/{$iframeId}?payment_token="
                . $paymentKey['token'];

            return response()->json(['payment_url' => $paymentUrl]);
        } catch (\Exception $e) {

            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function webhook(Request $request)
    {
        $data = $request->all();

        $subscriptionId = $data['merchant_order_id'] ?? null;
        $success = $data['success'] ?? false;

        if ($success && $subscriptionId) {

            $subscription = Subscription::find($subscriptionId);

            if ($subscription) {
                $subscription->update([
                    'status' => 'active',
                    'starts_at' => now(),
                    'expires_at' => $subscription->billing_cycle === 'annual'
                        ? now()->addYear()
                        : now()->addMonth(),
                ]);

                $subscription->user->update([
                    'plan' => $subscription->plan
                ]);
            }
        }

        return response()->json(['ok' => true]);
    }
    // User sends transaction ID
    public function confirm(Request $request)
    {
        $request->validate([
            'subscription_id' => 'required|exists:subscriptions,id',
            'transaction_id'  => 'required|string',
        ]);

        $subscription = Subscription::where('id', $request->subscription_id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        if ($subscription->status !== 'pending') {
            return response()->json([
                'message' => 'Subscription already processed.',
            ], 400);
        }

        $subscription->update([
            'transaction_id' => $request->transaction_id,
            'status'         => 'waiting_review',
        ]);

        return response()->json([
            'message' => 'Payment submitted successfully. Waiting admin review.',
        ]);
    }

    // Admin confirms payment
    public function approve(Request $request)
    {
        $request->validate([
            'subscription_id' => 'required|exists:subscriptions,id',
        ]);

        $subscription = Subscription::findOrFail($request->subscription_id);

        if ($subscription->status !== 'waiting_review') {
            return response()->json([
                'message' => 'Subscription not waiting review.',
            ], 400);
        }

        $expiresAt = $subscription->billing_cycle === 'annual'
            ? now()->addYear()
            : now()->addMonth();

        $subscription->update([
            'status'     => 'active',
            'starts_at'  => now(),
            'expires_at' => $expiresAt,
        ]);

        $subscription->user->update([
            'plan'             => $subscription->plan,
            'billing_cycle'    => $subscription->billing_cycle,
            'plan_started_at'  => now(),
            'plan_expires_at'  => $expiresAt,
        ]);

        return response()->json([
            'message' => 'Subscription approved successfully.',
        ]);
    }
    public function confirmSuccess(Request $request)
    {
        \Illuminate\Support\Facades\Log::info('confirmSuccess called for user: ' . $request->user()->id);

        $request->validate([
            'plan'          => 'required|in:pro,enterprise',
            'billing_cycle' => 'required|in:monthly,annual',
        ]);

        $expiresAt = $request->billing_cycle === 'annual'
            ? now()->addYear()
            : now()->addMonth();

        \Illuminate\Support\Facades\Log::info('User ID: ' . $request->user()->id . ' Plan before: ' . $request->user()->plan);

        \Illuminate\Support\Facades\DB::table('users')
            ->where('id', $request->user()->id)
            ->update([
                'plan'            => $request->plan,
                'billing_cycle'   => $request->billing_cycle,
                'plan_started_at' => now(),
                'plan_expires_at' => $expiresAt,
            ]);

        $freshPlan = \Illuminate\Support\Facades\DB::table('users')
            ->where('id', $request->user()->id)
            ->value('plan');

        \Illuminate\Support\Facades\Log::info('Plan after update: ' . $freshPlan);

        return response()->json([
            'message' => 'Plan activated successfully',
            'plan'    => $freshPlan,
        ]);
    }
    // Cancel subscription
    public function cancel(Request $request)
    {
        $subscription = Subscription::where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->latest()
            ->first();

        if (!$subscription) {
            return response()->json([
                'message' => 'No active subscription found.',
            ], 404);
        }

        $subscription->update([
            'status' => 'cancelled',
        ]);

        $request->user()->update([
            'plan' => 'free',
        ]);

        return response()->json([
            'message' => 'Subscription cancelled successfully.',
        ]);
    }

    private function getPaymentInstructions(
        string $method,
        float $amount,
        int $subscriptionId
    ): array {
        return match ($method) {

            'instapay' => [
                'method'  => 'InstaPay',
                'account' => 'zeyad777@instapay',
                'amount'  => $amount,
                'note'    => "SUB-$subscriptionId",
                'steps'   => [
                    'Open InstaPay app',
                    "Send $amount EGP to zeyad777@instapay",
                    "Add note SUB-$subscriptionId",
                    'Send transaction ID',
                ],
            ],

            'vodafone' => [
                'method' => 'Vodafone Cash',
                'number' => '01XXXXXXXXX',
                'amount' => $amount,
                'note'   => "SUB-$subscriptionId",
                'steps'  => [
                    'Open Vodafone Cash',
                    "Send $amount EGP",
                    "Add note SUB-$subscriptionId",
                    'Send transaction ID',
                ],
            ],

            default => [
                'method' => 'Card',
            ]
        };
    }
}
