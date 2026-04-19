<?php

return [
    'key_id'          => env('RAZORPAY_KEY_ID'),
    'key_secret'      => env('RAZORPAY_KEY_SECRET'),
    'webhook_secret'  => env('RAZORPAY_WEBHOOK_SECRET'),
    'currency'        => 'INR',
    'api_url'         => 'https://api.razorpay.com/v1',
];
