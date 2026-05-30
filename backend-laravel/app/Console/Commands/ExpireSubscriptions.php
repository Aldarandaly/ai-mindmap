<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Subscription;

class ExpireSubscriptions extends Command
{
    protected $signature = 'subscriptions:expire';
    protected $description = 'Expire old subscriptions';
    public function handle()
    {
        $subscriptions = Subscription::where('status', 'active')->where('expires_at', '<', now())->get();
        foreach ($subscriptions as $subscription) {
            $subscription->update(['status' => 'expired',]);
            $subscription->user->update(['plan' => 'free',]);
        }
        $this->info('Expired subscriptions processed.');
    }
}
