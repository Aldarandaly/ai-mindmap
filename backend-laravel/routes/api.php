<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\DiagramController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\PaymentController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/plans', [PaymentController::class, 'plans']);
Route::post('/payment/webhook', [PaymentController::class, 'webhook']);

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', [AuthController::class, 'profile']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::delete('/user', [AuthController::class, 'destroy']);

    Route::apiResource('projects', ProjectController::class)->only(['index', 'store', 'show']);

    Route::post('/diagrams/generate', [DiagramController::class, 'generate']);
    Route::get('/diagrams/recent', [DiagramController::class, 'recent']);
    Route::get('/projects/{project}/diagrams', [DiagramController::class, 'index']);
    Route::get('/diagrams/{diagram}', [DiagramController::class, 'show']);
    Route::put('/diagrams/{diagram}', [DiagramController::class, 'update']);

    Route::post('/diagrams/edit', [DiagramController::class, 'edit']);

    Route::get('/plan/current', [PaymentController::class, 'currentPlan']);
    Route::post('/payment/initiate', [PaymentController::class, 'initiate']);
    Route::post('/payment/cancel', [PaymentController::class, 'cancel']);
    Route::post('/payment/approve', [PaymentController::class, 'approve']);
    Route::post('/payment/confirm-success', [PaymentController::class, 'confirmSuccess']);

    Route::get('/projects/{project}/chats', [ChatController::class, 'index']);
    Route::post('/projects/{project}/chat', [ChatController::class, 'send']);
});
