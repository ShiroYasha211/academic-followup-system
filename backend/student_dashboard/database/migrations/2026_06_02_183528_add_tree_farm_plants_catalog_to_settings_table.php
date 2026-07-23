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
                'key' => 'tree_farm_plants_catalog',
                'value' => json_encode([
                    ['code' => 'grass', 'name' => 'عشب البداية', 'required_seconds' => 600, 'coins' => 8, 'rarity' => 'common'],
                    ['code' => 'red_flower', 'name' => 'زهرة حمراء', 'required_seconds' => 900, 'coins' => 15, 'rarity' => 'common'],
                    ['code' => 'blue_flower', 'name' => 'زهرة زرقاء', 'required_seconds' => 1200, 'coins' => 20, 'rarity' => 'common'],
                    ['code' => 'blue_bud', 'name' => 'برعم أزرق', 'required_seconds' => 1500, 'coins' => 25, 'rarity' => 'uncommon'],
                    ['code' => 'purple_flower', 'name' => 'زهرة بنفسجية', 'required_seconds' => 1800, 'coins' => 35, 'rarity' => 'uncommon'],
                    ['code' => 'pine_small', 'name' => 'صنوبرة صغيرة', 'required_seconds' => 2700, 'coins' => 55, 'rarity' => 'rare'],
                    ['code' => 'pine_tall', 'name' => 'صنوبرة شامخة', 'required_seconds' => 3600, 'coins' => 80, 'rarity' => 'rare'],
                    ['code' => 'orange_tree', 'name' => 'شجرة برتقالية', 'required_seconds' => 5400, 'coins' => 120, 'rarity' => 'epic'],
                    ['code' => 'orange_cypress', 'name' => 'سرو برتقالي', 'required_seconds' => 7200, 'coins' => 170, 'rarity' => 'legendary'],
                ]),
                'type' => 'json',
                'group' => 'academic',
                'label' => 'كتالوج بذور نباتات المزرعة',
                'description' => 'إعدادات وقت التركيز وجوائز العملات لكل نبتة في مزرعة الأشجار',
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
        \DB::table('settings')->where('key', 'tree_farm_plants_catalog')->delete();
    }
};
