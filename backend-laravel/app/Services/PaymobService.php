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
        $this->client = new Client([
            'verify'   => false,
            'base_uri' => 'https://accept.paymob.com',
        ]);

        $this->apiKey        = env('PAYMOB_API_KEY');
        $this->integrationId = env('PAYMOB_INTEGRATION_ID');
        $this->hmac          = env('PAYMOB_HMAC');
    }

    public function auth()
    {
        $res = $this->client->post('/api/auth/tokens', [
            'json' => ['api_key' => $this->apiKey]
        ]);
        return json_decode($res->getBody(), true)['token'];
    }

    public function createOrder($token, $amount, $orderId)
    {
        $res = $this->client->post('/api/ecommerce/orders', [
            'json' => [
                'auth_token'        => $token,
                'delivery_needed'   => false,
                'amount_cents'      => (int) ($amount * 100),
                'currency'          => 'EGP',
                'merchant_order_id' => (string) $orderId,
                'items'             => [],
            ]
        ]);
        return json_decode($res->getBody(), true);
    }

    public function paymentKey($token, $orderId, $amount, $billingData)
    {
        $res = $this->client->post('/api/acceptance/payment_keys', [
            'json' => [
                'auth_token'     => $token,
                'amount_cents'   => $amount * 100,
                'expiration'     => 3600,
                'order_id'       => $orderId,
                'integration_id' => (int) $this->integrationId,
                'billing_data'   => $billingData,
                'currency'       => 'EGP',
            ]
        ]);
        return json_decode($res->getBody(), true);
    }
}
