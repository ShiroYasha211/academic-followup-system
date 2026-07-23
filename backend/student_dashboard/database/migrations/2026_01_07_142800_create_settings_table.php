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
        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->string('type')->default('text'); // text, number, boolean, json
            $table->string('group')->default('general'); // general, academic, attendance, etc.
            $table->string('label')->nullable(); // Arabic label
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // Insert default settings
        $this->insertDefaultSettings();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('settings');
    }

    /**
     * Insert default system settings
     */
    private function insertDefaultSettings(): void
    {
        $settings = [
            // General Settings
            [
                'key' => 'app_name',
                'value' => 'نظام إدارة الحضور',
                'type' => 'text',
                'group' => 'general',
                'label' => 'اسم النظام',
                'description' => 'اسم التطبيق الذي يظهر في الواجهة'
            ],
            [
                'key' => 'app_description',
                'value' => 'نظام متكامل لإدارة الحضور والغياب للطلاب',
                'type' => 'text',
                'group' => 'general',
                'label' => 'وصف النظام',
                'description' => 'وصف مختصر للنظام'
            ],

            // Academic Settings
            [
                'key' => 'default_max_absences',
                'value' => '3',
                'type' => 'number',
                'group' => 'academic',
                'label' => 'الحد الأقصى للغياب (افتراضي)',
                'description' => 'عدد مرات الغياب المسموح بها قبل إنذار الطالب - يمكن تخصيصه لكل مادة'
            ],
            [
                'key' => 'excuse_deadline_days',
                'value' => '7',
                'type' => 'number',
                'group' => 'academic',
                'label' => 'مهلة تقديم العذر (بالأيام)',
                'description' => 'عدد الأيام المسموح بها للطالب لتقديم عذر بعد الغياب'
            ],
            [
                'key' => 'deprivation_threshold',
                'value' => '25',
                'type' => 'number',
                'group' => 'academic',
                'label' => 'نسبة الحرمان (%)',
                'description' => 'نسبة الغياب التي تؤدي لحرمان الطالب من دخول الاختبار'
            ],

            // Attendance Settings
            [
                'key' => 'late_arrival_minutes',
                'value' => '15',
                'type' => 'number',
                'group' => 'attendance',
                'label' => 'مدة التأخير (بالدقائق)',
                'description' => 'عدد الدقائق التي تعتبر تأخيراً بعد بداية المحاضرة'
            ],
            [
                'key' => 'allow_excuse_upload',
                'value' => '1',
                'type' => 'boolean',
                'group' => 'attendance',
                'label' => 'السماح برفع الأعذار',
                'description' => 'السماح للطلاب برفع ملفات الأعذار'
            ],
        ];

        foreach ($settings as $setting) {
            \DB::table('settings')->insert(array_merge($setting, [
                'created_at' => now(),
                'updated_at' => now()
            ]));
        }
    }
};
