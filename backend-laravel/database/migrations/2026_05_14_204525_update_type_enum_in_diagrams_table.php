<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE diagrams MODIFY COLUMN type ENUM(
                'class', 'erd', 'mindmap', 'auto',
                'usecase', 'activity', 'sequence',
                'context', 'state', 'dfd', 'gantt'
            ) DEFAULT 'auto'");
        }
        
    }

    public function down(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE diagrams MODIFY COLUMN type ENUM(
                'class', 'erd', 'mindmap', 'auto'
            ) DEFAULT 'auto'");
        }
    }
};