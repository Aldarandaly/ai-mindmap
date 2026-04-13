<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\DiagramController;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::apiResource('projects', ProjectController::class)->only(['index', 'store', 'show']);
    
    Route::post('/diagrams/generate', [DiagramController::class, 'generate']);
    Route::get('/projects/{project}/diagrams', [DiagramController::class, 'index']);
    Route::get('/diagrams/{diagram}', [DiagramController::class, 'show']);
});
