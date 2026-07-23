# دليل تكامل API الطالب (Attendify Student API)

هذا الدليل مخصص لمطوري الفرونت-إند (Mobile/Web) لتمكينهم من تشغيل وربط الـ API الخاص بالطالب بشكل صحيح وتجنب الأخطاء الشائعة.

## 🚀 الأساسيات (The Basics)

### 1. الروابط الأساسية (Base URLs)
- **Local Dev:** `http://127.0.0.1:8000/api/student`
- **Production:** `[سيتم تزويدك به]/api/student`

### 2. الهيدرز المطلوبة (Required Headers)
يجب إرسال هذه الهيدرز في **كل** طلب لضمان استلام رد بصيغة JSON وللتعامل الصحيح مع الـ Session:
- `Accept: application/json` (ضروري جداً لتجنب التحويل لصفحات HTML عند حدوث خطأ)
- `Content-Type: application/json` (عند إرسال بيانات في الـ Body)
- `Authorization: Bearer {token}` (بعد تسجيل الدخول)

---

## 🔐 المصادقة (Authentication)

### تسجيل الدخول (Login)
يمكنك تسجيل الدخول باستخدام **البريد الإلكتروني** أو **الرقم الأكاديمي** (Student Number).
- الـ Endpoint: `POST /api/student/login`
- الحقول: `login` (email or student_number), `password`.

### التحقق من الحالة (User Status)
النظام يحتوي على Middleware (CheckUserStatus) يقوم بالتالي:
- إذا كان حساب الطالب **غير مفعل (Inactive)**: سيعود الرد بـ `403 Forbidden` مع رسالة تشرح السبب.
- إذا قام الأدمن بعمل **Kick** للجلسة: سيعود الرد بـ `401 Unauthorized` ويجب مسح الـ Token وإعادة توجيه المستخدم لصفحة الدخول.

---

## 📊 الدرجات (Grades) - هام جداً
هناك نوعان من الدرجات في النظام:
1. **الدرجات الأكاديمية (My Grades):** وهي درجات المواد الخاصة بالطالب نفسه. تظهر في `GET /api/student/grades`.
2. **الدرجات المفوضة (Authorized Grades):** في بعض الحالات، يُفوض الطالب (المندوب عادةً) لإدخال درجات العملي لزملائه. هذه تظهر في `GET /api/student/authorized-grades`.

---

## 📑 التقارير المصدرة (PDF Reports)
الـ endpoints الخاصة بالتقارير (Attendance, Grades, Exams) تعيد حالياً **رابط تحميل (Direct URL)**. 
- يجب على التطبيق فتح هذا الرابط في المتصفح أو استخدامه مع مكتبة تحميل (Downloader) مع إرسال الـ `Bearer Token`.
- الروابط تعيد ملف بصيغة `application/pdf`.

---

## 💡 ملاحظات تقنية هامة

### 1. مركز الدراسة الذكي (Smart Study Hub)
هذا الجزء يسمح للطالب بإضافة مهام (Study Task, Reminder, Resource) من صفحات مختلفة (المحاضرات أو المكتبة) إلى جدوله الخاص.
- عند إضافة "محاضرة" للمذاكرة، يتم استخدام `referenceable_type: 'lecture'`.
- عند إضافة "مورد تعليمي" للمكتبة، يتم استخدام `referenceable_type: 'resource'`.

### 2. معالجة الأخطاء (Error Handling)
جميع الطلبات الناجحة تعود بـ `success: true`. في حال حدوث خطأ:
- الحقل `message` يحتوي على شرح باللغة العربية للخطأ ليظهر للمستخدم.
- الحقل `errors` (في حال الـ Validation Error) يحتوي على مصفوفة بالأخطاء لكل حقل.

### 3. الصلاحيات (Permissions)
بعض الأزرار (مثل "رفع ملف للمكتبة" أو "توليد كروت") يجب ألا تظهر للمستخدم إلا إذا كان يملك الصلاحية.
- تحقق من مصفوفة `permissions` التي تعود في endpoint الـ `/me`.
- الصلاحيات الأساسية: `upload_shared_library`, `generate_cards`.

---

تأكد من مراجعة مجموعة Postman المحدثة فهي تحتوي على أمثلة حية لكل طلب.
