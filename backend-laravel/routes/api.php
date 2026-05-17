<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\DiagramController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::apiResource('projects', ProjectController::class)->only(['index', 'store', 'show']);

    Route::post('/diagrams/generate', [DiagramController::class, 'generate']);
    Route::get('/diagrams/recent', [DiagramController::class, 'recent']);
    Route::get('/projects/{project}/diagrams', [DiagramController::class, 'index']);
    Route::get('/diagrams/{diagram}', [DiagramController::class, 'show']);

    Route::get('/projects/{project}/chats', [ChatController::class, 'index']);
    Route::post('/projects/{project}/chat', [ChatController::class, 'send']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
});
