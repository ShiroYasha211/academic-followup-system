<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        \DB::table('settings')->insert([
            [
                'key' => 'tree_farm_exchange_rate',
                'value' => '25',
                'type' => 'number',
                'group' => 'academic',
                'label' => 'سعر صرف عملات مزرعة الأشجار',
                'description' => 'عدد العملات المطلوبة لاستبدال نجمة واحدة',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'tree_farm_weekly_star_limit',
                'value' => '5',
                'type' => 'number',
                'group' => 'academic',
                'label' => 'الحد الأقصى الأسبوعي لاستبدال النجوم',
                'description' => 'الحد الأقصى للنجوم التي يمكن للطالب طلبها أسبوعياً من المزرعة (0 تعني بلا حد)',
                'created_at' => now(),
                'updated_at' => now(),
            ]
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        \DB::table('settings')->whereIn('key', ['tree_farm_exchange_rate', 'tree_farm_weekly_star_limit'])->delete();
    }
};
