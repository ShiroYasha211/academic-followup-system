<?php

namespace Database\Seeders;

use App\Models\Permission;
use Illuminate\Database\Seeder;

class PermissionSeeder extends Seeder
{
    public function run(): void
    {
        Permission::firstOrCreate([
            'slug' => 'upload_shared_library'
        ], [
            'name' => 'الرفع في المكتبة المشتركة',
            'description' => 'يسمح للمستخدم برفع الملفات والموارد التعليمية إلى المكتبة العامة للمادة.'
        ]);

        Permission::firstOrCreate([
            'slug' => 'generate_cards'
        ], [
            'name' => 'توليد الكروت من الرصيد',
            'description' => 'يسمح للمستخدم بتوليد كروت شحن رصيد مقابل خصم قيمتها من رصيده الشخصي.'
        ]);
    }
}
