<?php

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Route;

// Route::get('/', function () {
//     return view('welcome');
// });

// test
Route::get('/test', function () {
    return Http::post('http://127.0.0.1:8001/generate', [
        'text' => 'test',
        'type' => 'class'
    ])->json();
});