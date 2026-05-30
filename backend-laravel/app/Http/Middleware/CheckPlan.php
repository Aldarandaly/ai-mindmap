<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPlan
{
    /**
     * Handle an incoming request.
     */
    public function handle(
        Request $request,
        Closure $next,
        ...$plans
    ): Response {

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 401);
        }

        if (!in_array($user->plan, $plans)) {
            return response()->json([
                'message' => 'Upgrade your subscription'
            ], 403);
        }

        return $next($request);
    }
}
