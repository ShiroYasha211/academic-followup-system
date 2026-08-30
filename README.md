# معين

معين منصة تعليمية وأكاديمية متكاملة تربط الطالب والدكتور والمندوب والإدارة في نظام واحد. يضم المستودع خادم Laravel ولوحات الويب، تطبيق الطالب، تطبيق الدكتور والكادر الأكاديمي، وبرنامج سطح المكتب المستخدم في عمليات الحضور.

## المكونات

```text
backend/student_dashboard   Laravel API ولوحات الويب
frontend/moeen_student_app  تطبيق الطالب والمندوب
frontend/moeen_doctor_app   تطبيق الدكتور والكادر الأكاديمي
desktop                     برنامج سطح المكتب للحضور
```

## الوظائف الرئيسية

- إدارة الجامعات والكليات والتخصصات والمستويات والمواد.
- إدارة حسابات الطلاب والدكاترة والمندوبين والمسؤولين.
- تسجيل الحضور بالباركود ومتابعة الغياب والتأخير.
- إدارة صلاحيات وطلبات تعديل الحضور مع تسجيل التغييرات.
- إنشاء الكويزات وتشغيل الاختبارات وعرض النتائج وفق إعدادات الدكتور.
- البطاقات التعليمية وOne Line Shot ومركز الدراسة.
- الاشتراكات والأرصدة والسجلات المالية وكروت الشحن.
- النجوم ومزرعة الأشجار والمكافآت التعليمية.
- القسم العملي والسريري وقوائم OSCE والتقييمات.
- الإعلانات والرسائل والموارد والمكتبة والجداول والتقارير.
- إشعارات Firebase وتقييد الحساب بالأجهزة المعتمدة.

## المتطلبات

### الخادم ولوحات الويب

- PHP 8.2 أو أحدث.
- Composer.
- MySQL أو MariaDB.
- Node.js وnpm.

### تطبيقات الجوال

- Flutter SDK.
- Android Studio أو Android SDK.
- ملف `google-services.json` المناسب لكل تطبيق.

## تشغيل Laravel محليًا

```bash
cd backend/student_dashboard
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan storage:link
npm run build
php artisan serve
```

اضبط بيانات قاعدة البيانات والبريد وFirebase داخل `.env` قبل التشغيل.

## تشغيل تطبيق الطالب

```bash
cd frontend/moeen_student_app
flutter pub get
flutter run
```

لبناء نسخة Release:

```bash
flutter build apk --release
```

## تشغيل تطبيق الدكتور

```bash
cd frontend/moeen_doctor_app
flutter pub get
flutter run
```

لبناء نسخة Release:

```bash
flutter build apk --release
```

## ملفات البيئة الحساسة

لا ترفع الملفات التالية إلى Git:

- `.env`
- `google-services.json`
- ملفات التوقيع `.jks` و`.keystore`
- ملفات APK وملفات التثبيت النهائية
- مفاتيح الخدمات الخارجية

استخدم `.env.example` لتوثيق متغيرات الخادم المطلوبة دون إضافة بيانات حقيقية.
