<?php

namespace App\Services;

use App\Models\User;

class PlanService
{
    const PLANS = [

        'free' => [
            'diagrams_per_month'      => 10,
            'chat_messages_per_month' => 20,
            'diagram_types'           => ['erd', 'class', 'mindmap'],
            'generation_modes'        => ['generate'],
            'export_formats'          => [],
            'history_days'            => 0,
        ],

        'pro' => [
            'diagrams_per_month'      => 100,
            'chat_messages_per_month' => 200,
            'diagram_types'           => 'all',
            'generation_modes'        => ['generate', 'analyse', 'explain'],
            'export_formats'          => ['png', 'svg'],
            'history_days'            => 30,
        ],

        'enterprise' => [
            'diagrams_per_month'      => -1,
            'chat_messages_per_month' => -1,
            'diagram_types'           => 'all',
            'generation_modes'        => ['generate', 'analyse', 'explain'],
            'export_formats'          => ['png', 'svg', 'pdf'],
            'history_days'            => -1,
        ],
    ];

    const PRICES = [

        'pro' => [
            'monthly' => 99,
            'annual'  => 799,
        ],

        'enterprise' => [
            'monthly' => 299,
            'annual'  => 2499,
        ],
    ];

    public function canGenerateDiagram(User $user): array
    {
        $this->resetUsageIfNeeded($user);

        $limits = self::PLANS[$user->plan];

        if ($limits['diagrams_per_month'] === -1) {
            return ['allowed' => true];
        }

        if (
            $user->diagrams_used_this_month >=
            $limits['diagrams_per_month']
        ) {
            return [
                'allowed' => false,
                'reason'  => 'Monthly diagram limit reached.',
                'limit'   => $limits['diagrams_per_month'],
                'used'    => $user->diagrams_used_this_month,
            ];
        }

        return ['allowed' => true];
    }

    public function canSendChatMessage(User $user): array
    {
        $this->resetUsageIfNeeded($user);

        $limits = self::PLANS[$user->plan];

        if ($limits['chat_messages_per_month'] === -1) {
            return ['allowed' => true];
        }

        if (
            $user->chat_messages_used_this_month >=
            $limits['chat_messages_per_month']
        ) {
            return [
                'allowed' => false,
                'reason'  => 'Monthly chat limit reached.',
            ];
        }

        return ['allowed' => true];
    }

    public function canUseDiagramType(User $user, string $type): bool
    {
        $limits = self::PLANS[$user->plan];

        if ($limits['diagram_types'] === 'all') {
            return true;
        }

        return in_array($type, $limits['diagram_types']);
    }

    public function canExportPdf(User $user): bool
    {
        return in_array(
            'pdf',
            self::PLANS[$user->plan]['export_formats']
        );
    }

    public function incrementDiagramUsage(User $user): void
    {
        $user->increment('diagrams_used_this_month');
    }

    public function incrementChatUsage(User $user): void
    {
        $user->increment('chat_messages_used_this_month');
    }

    public function resetUsageIfNeeded(User $user): void
    {
        $now = now();

        if (
            $user->usage_reset_at === null ||
            $user->usage_reset_at->lt($now->copy()->startOfMonth())
        ) {
            $user->update([
                'diagrams_used_this_month'      => 0,
                'chat_messages_used_this_month' => 0,
                'usage_reset_at'                => now(),
            ]);
        }
    }

    public function getUserPlanInfo(User $user): array
    {
        $this->resetUsageIfNeeded($user);

        $limits = self::PLANS[$user->plan];

        return [
            'plan'            => $user->plan,
            'billing_cycle'   => $user->billing_cycle,
            'expires_at'      => $user->plan_expires_at,

            'diagrams_used'   => $user->diagrams_used_this_month,
            'diagrams_limit'  => $limits['diagrams_per_month'],

            'chat_used'       => $user->chat_messages_used_this_month,
            'chat_limit'      => $limits['chat_messages_per_month'],

            'diagram_types'   => $limits['diagram_types'],
            'export_formats'  => $limits['export_formats'],
        ];
    }
}
