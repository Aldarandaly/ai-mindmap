<?php

namespace App\Services;

use GuzzleHttp\Client;

class PaymobService
{
    private $client;
    private $apiKey;
    private $integrationId;
    private $hmac;

    public function __construct()
    {
        $this->client = new Client();

        $this->apiKey = env('PAYMOB_API_KEY');
        $this->integrationId = env('PAYMOB_INTEGRATION_ID');
        $this->hmac = env('PAYMOB_HMAC');
    }

    // 1. Get auth token
    public function auth()
    {
        $res = $this->client->post('https://accept.paymob.com/api/auth/tokens', [
            'json' => [
                'api_key' => $this->apiKey
            ]
        ]);

        return json_decode($res->getBody(), true)['token'];
    }

    // 2. Create order
    public function createOrder($token, $amount, $orderId)
    {
        $res = $this->client->post('https://accept.paymob.com/api/ecommerce/orders', [
            'json' => [
                'auth_token' => $token,
                'delivery_needed' => false,
                'amount_cents' => $amount * 100,
                'currency' => 'EGP',
                'merchant_order_id' => $orderId
            ]
        ]);

        return json_decode($res->getBody(), true);
    }

    // 3. Payment key
    public function paymentKey($token, $orderId, $amount, $billingData)
    {
        $res = $this->client->post('https://accept.paymob.com/api/acceptance/payment_keys', [
            'json' => [
                'auth_token' => $token,
                'amount_cents' => $amount * 100,
                'expiration' => 3600,
                'order_id' => $orderId,
                'integration_id' => $this->integrationId,
                'billing_data' => $billingData,
                'currency' => 'EGP',
            ]
        ]);

        return json_decode($res->getBody(), true);
    }
}
