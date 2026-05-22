# تقرير وظائف تطبيق معين للطالب

تاريخ الفحص: 2026-05-14

هذا التقرير مبني على فحص مشروع Flutter `frontend/moeen_student_app`، ويغطي التطبيق كاملًا كما هو موجود في المشروع: حساب الطالب، حساب المندوب، والمندوب العملي. تم الاعتماد على الراوتر، القوائم الجانبية، الشاشات، الـ repositories، والخدمات المشتركة لاستخراج الوظائف الفعلية.

## 1. ملخص عام للتطبيق

### الحسابات المدعومة
- **حساب الطالب**: الواجهة الأساسية للطالب لمتابعة الدراسة، الحضور، المقررات، الكويزات، المكتبة، الرسائل، القسم السريري، والوظائف التحفيزية.
- **حساب المندوب**: مساحة مستقلة داخل نفس التطبيق لإدارة الدفعة والطلاب والمواد والحضور والدرجات والتواصل.
- **حساب المندوب العملي**: يظهر للطالب إذا كان لديه صلاحية مندوب عملي، ويستخدم لإدارة ومراجعة الحالات العملية والتفويضات.

### الدخول والتسجيل
- شاشة البداية `/`.
- تسجيل الدخول `/login`.
- إنشاء حساب طالب `/register`.
- شاشة توجيه عامة `/home`.
- تسجيل الدخول يحاول أولًا عبر `/student/login`.
- إذا كان الإدخال بريدًا وفشل دخول الطالب، يحاول الدخول كمندوب عبر `/delegate/login`.
- التطبيق يحدد وجهة المستخدم بعد الدخول:
  - المندوب ينتقل إلى `/delegate/dashboard`.
  - الطالب أو المندوب العملي ينتقل إلى `/student/home`.
- التسجيل يجلب الجامعات والكليات والتخصصات والمستويات من API عام، ثم يرسل بيانات الطالب إلى `/register`.

### الخدمات المشتركة
- التطبيق عربي بالكامل RTL.
- يستخدم Theme موحد وهوية Moeen.
- يدعم Firebase Cloud Messaging للإشعارات.
- يدعم إشعارات محلية لعمليات التحميل.
- يدعم Offline Banner عند انقطاع الإنترنت.
- يدعم Download Banner داخل التطبيق.
- يخزن الجلسة في التخزين الآمن.
- يستخدم كاش محلي للعديد من شاشات الطالب، ويعيد البيانات المحفوظة عند فشل الشبكة.
- يدعم فتح الملفات بعد التحميل عبر `OpenFilex`.
- يستخدم حوارات موحدة للتأكيد، المعلومات، والـ Bottom Sheets.

## 2. حساب الطالب

### 2.1 الرئيسية
- **المسار**: `/student/home`
- **القائمة**: الرئيسية.
- **الوظائف**:
  - عرض ترحيب باسم الطالب.
  - زر سريع لمسح QR الحضور.
  - عرض إحصائيات عامة من لوحة الطالب.
  - عرض الاختبار القادم إن وجد.
  - عرض التنبيهات المهمة.
  - عرض إجراءات سريعة للتنقل.
  - عرض آخر الأخبار والإعلانات.
- **البيانات**: تأتي من `/student/dashboard`.
- **الأوفلاين**: بيانات الداشبورد مخزنة في الكاش وتعرض عند عدم الاتصال إذا كانت موجودة.

### 2.2 تحضير QR سريع
- **المسار**: `/student/qr-scan`
- **القائمة**: تحضير QR سريع.
- **الوظائف**:
  - فتح الكاميرا لمسح QR الحضور.
  - إرسال الرمز إلى API لتسجيل حضور الطالب.
  - عرض Dialog عند نجاح التسجيل أو ظهور خطأ.
  - العودة للرئيسية بعد اكتمال التسجيل.
- **العملية**: `POST /student/qr-attendance/scan`.
- **الأوفلاين**: يحتاج إنترنت لأنه عملية تسجيل حضور لحظية.

### 2.3 الملف الشخصي
- **المسار**: `/student/profile`
- **القائمة**: الملف الشخصي.
- **الوظائف**:
  - عرض بيانات الطالب الشخصية والأكاديمية.
  - عرض الاسم، البريد، رقم القيد، الجامعة، الكلية، التخصص، المستوى، الدور، وحالة القسم السريري.
  - تغيير البريد الإلكتروني بعد التحقق من كلمة المرور.
  - تغيير كلمة المرور.
- **العمليات**:
  - `GET /student/me`
  - `PATCH /student/profile/email`
  - `POST /student/change-password`
- **الأوفلاين**: عرض البيانات المخزنة ممكن، أما تغيير البريد وكلمة المرور فيحتاجان إنترنت.

### 2.4 الاشتراك والرصيد
- **المسار**: `/student/subscription`
- **القائمة**: الاشتراك والرصيد.
- **الوظائف**:
  - عرض حالة الاشتراك.
  - عرض الباقات المتاحة.
  - الاشتراك في باقة.
  - استخدام كود شحن/استرداد.
  - تفعيل أو إيقاف التجديد التلقائي.
- **العمليات**:
  - `GET /student/subscription`
  - `POST /student/subscription/redeem`
  - `POST /student/subscription/subscribe`
  - `POST /student/subscription/auto-renew`
- **الأوفلاين**: العرض من الكاش ممكن، العمليات المالية تحتاج إنترنت.

### 2.5 السجل المالي
- **المسار**: `/student/ledger`
- **القائمة**: السجل المالي.
- **الوظائف**:
  - عرض كشف الحساب والمعاملات.
  - التنقل بين الصفحات.
  - تصدير كشف الحساب PDF.
  - تحميل ملف كشف الحساب وفتحه.
- **العمليات**:
  - `GET /student/ledger`
  - `GET /student/ledger/export`
- **الأوفلاين**: العرض من الكاش ممكن، التصدير يحتاج إنترنت.

### 2.6 المقررات الدراسية
- **المسار**: `/student/subjects`
- **القائمة**: المقررات الدراسية.
- **الوظائف**:
  - عرض مواد الطالب.
  - فلترة المواد حسب الترم.
  - إذا كان التخصص يستخدم السيمسترات، يظهر فلتر السيمستر بعد اختيار الترم.
  - مسح الفلاتر.
  - فتح تفاصيل أي مقرر.
- **البيانات**: `GET /student/subjects?term_id=&semester_id=`.
- **الأوفلاين**: مدعومة عبر الكاش حسب الفلاتر.

### 2.7 تفاصيل المقرر
- **المسار**: `/student/subjects/:id`
- **الوصول**: من قائمة المقررات أو من روابط داخلية.
- **التبويبات**:
  - نظرة عامة.
  - الدرجات.
  - المحاضرات.
  - التكاليف.
  - المصادر.
  - سجل الحضور.
- **الوظائف**:
  - عرض بيانات المادة والدكتور والترم والسيمستر.
  - عرض نسبة الحضور، الغياب، الأعذار، وأعمال السنة والنهائي.
  - عرض معلومات الحرمان إن وجدت.
  - عرض تفاصيل الدرجات والتصنيفات.
  - عرض المحاضرات مع إمكانية تغيير حالة الاستماع/الإنجاز.
  - عرض تكاليف المادة والانتقال لتفاصيل التكليف.
  - عرض مصادر المادة وتحميلها أو فتحها.
  - عرض سجل الحضور.
  - رفع عذر من سجل الحضور عند توفر الحالة المناسبة.
- **العمليات**:
  - `GET /student/subjects/:id`
  - `POST /student/lectures/:id/toggle-listen`
  - `POST /student/excuse`
- **الأوفلاين**: عرض التفاصيل من الكاش ممكن، تغيير حالة المحاضرة ورفع العذر يحتاجان إنترنت.

### 2.8 مركز الدراسة
- **المسار**: `/student/study-center`
- **القائمة**: مركز الدراسة.
- **الوظائف**:
  - عرض عناصر مركز الدراسة حسب التبويب/التصنيف.
  - إضافة مهمة دراسة مخصصة.
  - فتح جلسة دراسة لعنصر محدد.
  - التحقق من التذكيرات المرتبطة بمركز الدراسة.
- **العمليات**:
  - `GET /student/study-center`
  - `GET /student/study-center/check-reminders`
  - `POST /student/study-center/custom`
- **الأوفلاين**: عرض البيانات المخزنة ممكن، الإضافة تحتاج إنترنت.

### 2.9 جلسة الدراسة
- **المسار**: `/student/study-center/:id/session`
- **الوظائف**:
  - عرض جلسة دراسة تفصيلية.
  - إضافة أعمدة داخل الجلسة.
  - تعديل الأعمدة.
  - حذف الأعمدة.
  - زيادة عداد/إنجاز عمود.
  - التراجع عن إجراء على عنصر أو عمود.
  - تعديل عنصر دراسة.
  - حذف عنصر دراسة.
- **العمليات**:
  - `GET /student/study-center/:id/session`
  - `POST /student/study-center/columns`
  - `PUT /student/study-center/columns/:id`
  - `DELETE /student/study-center/columns/:id`
  - `POST /student/study-center/columns/:id/increment`
  - `POST /student/study-center/:id/undo`
  - `POST /student/study-center/columns/:id/undo`
  - `PUT /student/study-center/:id`
  - `DELETE /student/study-center/:id`
- **الأوفلاين**: عرض الجلسة من الكاش ممكن، كل التعديلات تحتاج إنترنت.

### 2.10 الجدول الدراسي
- **المسار**: `/student/schedules`
- **القائمة**: الجدول الدراسي.
- **الوظائف**:
  - عرض الجدول الدراسي.
  - تبويبات حسب الأيام.
  - عرض المادة، الوقت، القاعة/المكان، والدكتور حسب البيانات المتاحة.
- **البيانات**: `GET /student/schedules`.
- **الأوفلاين**: مدعوم عبر الكاش.

### 2.11 الأخبار والإعلانات
- **المسار**: `/student/news`
- **القائمة**: الأخبار والإعلانات.
- **الوظائف**:
  - عرض الأخبار والإعلانات في مركز موحد.
  - فلترة المصدر إذا كان مدعومًا.
  - فتح تفاصيل الإعلان في Bottom Sheet.
  - تعليم إشعارات المركز كمقروءة عند فتح التفاصيل عندما تكون مرتبطة بإشعار قابل للتتبع.
- **البيانات**:
  - `GET /student/news-hub`
  - `POST /student/notifications/:id/read`
- **الأوفلاين**: العرض من الكاش ممكن، تعليم المقروء يحتاج إنترنت.

### 2.12 الكويزات
- **المسار**: `/student/quizzes`
- **القائمة**: الكويزات.
- **التبويبات**:
  - المتاحة.
  - المسابقات.
  - محاولاتي.
- **الوظائف**:
  - عرض الكويزات المتاحة للطالب.
  - عرض المسابقات.
  - عرض محاولات الطالب.
  - فتح كويز للحل.
  - دعم كود الدخول إذا كان مطلوبًا.
  - إظهار حالة النتيجة، مع إخفائها إذا كانت النتيجة مخفية من الدكتور.
- **العمليات**:
  - `GET /student/quizzes`
  - `GET /student/quizzes/:id/take`
- **الأوفلاين**: عرض القائمة من الكاش ممكن، بدء/تسليم الاختبار يحتاج إنترنت.

### 2.13 حل الكويز
- **المسار**: `/student/quizzes/:id/take`
- **الوظائف**:
  - عرض أسئلة الكويز.
  - حفظ الإجابات محليًا داخل الشاشة حتى التسليم.
  - دعم مؤقت عام للكويز.
  - دعم مؤقت لكل سؤال إذا كان الكويز بنمط `per_question`.
  - منع الرجوع للسؤال السابق في نمط وقت لكل سؤال.
  - تحذير قبل الخروج.
  - تسليم الإجابات الحالية عند تأكيد الخروج أو انتهاء الوقت.
  - منع لقطة الشاشة داخل شاشة الحل على Android.
- **العملية**: `POST /student/quizzes/:attempt/submit`.
- **الأوفلاين**: يحتاج إنترنت للتسليم.

### 2.14 نتيجة الكويز
- **المسار**: `/student/quizzes/results/:attemptId`
- **الوظائف**:
  - عرض النتيجة عند السماح بها.
  - عرض رسالة إخفاء الدرجة إذا كانت النتائج مخفية.
  - عرض ملخص الإجابات والأسئلة حسب بيانات API.
- **البيانات**: `GET /student/quizzes/results/:attemptId`.
- **الأوفلاين**: العرض من الكاش ممكن إذا سبق تحميل النتيجة.

### 2.15 نجومي
- **المسار**: `/student/stars`
- **القائمة**: نجومي.
- **التبويبات**:
  - الإهداء.
  - لوحة الشرف.
  - السجل.
- **الوظائف**:
  - عرض رصيد النجوم.
  - البحث عن طالب لإهداء النجوم.
  - إهداء نجوم لطالب آخر.
  - عرض لوحة الشرف.
  - عرض سجل معاملات النجوم.
  - عرض شارة النجوم في AppBar بجانب التنبيهات.
- **العمليات**:
  - `GET /student/stars`
  - `GET /student/stars/search`
  - `POST /student/stars/gift`
- **الأوفلاين**: عرض الرصيد والسجل من الكاش ممكن، الإهداء يحتاج إنترنت.

### 2.16 مزرعة الأشجار
- **المسار**: `/student/tree-farm`
- **القائمة**: مزرعة الأشجار.
- **الوظائف**:
  - عرض المزرعة الخاصة والعامة.
  - بدء جلسة تركيز.
  - عرض عداد الجلسة.
  - إرسال heartbeat أثناء الجلسة.
  - طلب مهلة أثناء الجلسة.
  - إنهاء الجلسة وتسجيل النبات/المكافأة.
  - حفظ الجلسات أوفلاين كمعلقة.
  - مزامنة الجلسات والأفكار عند رجوع الإنترنت.
  - تفريغ الأفكار وربطها بتذكير.
  - طلب مكافأة coins.
  - تعديل ملف المزرعة العام: الاسم، الظهور العام، الاسم الوهمي.
  - عرض مرتبة الشرف للمزرعة العامة.
- **العمليات**:
  - `GET /student/tree-farm`
  - `POST /student/tree-farm/sessions/start`
  - `POST /student/tree-farm/sessions/:id/heartbeat`
  - `POST /student/tree-farm/sessions/:id/grace`
  - `POST /student/tree-farm/sessions/:id/finish`
  - `POST /student/tree-farm/offline-sync`
  - `POST /student/tree-farm/thoughts`
  - `POST /student/tree-farm/reward-requests`
  - `PATCH /student/tree-farm/profile`
- **الأوفلاين**: مدعومة محليًا؛ الاعتماد العام والمكافآت لا تتم إلا بعد المزامنة.

### 2.17 التنبيهات
- **المسار**: `/student/notifications`
- **القائمة**: التنبيهات.
- **الوظائف**:
  - عرض قائمة التنبيهات.
  - تعليم تنبيه كمقروء.
  - تعليم جميع التنبيهات كمقروءة.
  - التصويت/التفاعل مع إشعار إذا كان يدعم ذلك.
  - عدادات شارات حسب الشاشة.
  - التنقل من الإشعارات إلى الوجهات المناسبة مثل مركز الدراسة، الكويزات، التكاليف، الجداول، المكتبة، النجوم، الرسائل، الأخبار.
- **العمليات**:
  - `GET /student/notifications`
  - `GET /student/notifications/unread-count`
  - `POST /student/notifications/:id/read`
  - `POST /student/notifications/mark-all-read`
  - `POST /student/notifications/:id/vote`
- **الأوفلاين**: عرض القائمة من الكاش ممكن، تحديث المقروء والتصويت يحتاجان إنترنت.

### 2.18 جداول الاختبارات
- **المسار**: `/student/exams`
- **القائمة**: جداول الاختبارات.
- **التبويبات**:
  - الجداول الرسمية.
  - بواسطة المندوب.
- **الوظائف**:
  - عرض جداول الاختبارات الرسمية.
  - عرض جداول الاختبارات التي أضافها المندوب.
  - عرض وقت الاختبار، المادة، المكان، والملاحظات حسب البيانات.
- **البيانات**: `GET /student/exams`.
- **الأوفلاين**: مدعوم عبر الكاش.

### 2.19 مصادر المقرر
- **المسار**: `/student/resources`
- **القائمة**: مصادر المقرر.
- **الوظائف**:
  - عرض مصادر المقرر.
  - البحث والفلترة حسب المادة والتصنيف.
  - تبويبات تصنيفات الملفات.
  - عرض تفاصيل المصدر.
  - تحميل الملف إلى مجلد Moeen حسب القسم.
  - فتح الملف إذا كان محملًا سابقًا.
  - عرض نوع الملف وامتداده وأيقونة مناسبة.
  - معالجة تكرار أسماء الملفات بدون تخريب الامتداد.
- **البيانات**: `GET /student/resources`.
- **الأوفلاين**: عرض القائمة من الكاش ممكن، التحميل يحتاج إنترنت، فتح الملف المحلي لا يحتاج إنترنت.

### 2.20 المكتبة المشتركة
- **المسار**: `/student/library`
- **القائمة**: المكتبة المشتركة.
- **الوظائف**:
  - عرض ملفات المكتبة المشتركة.
  - البحث والفلترة حسب المادة والتصنيف ونوع الملف.
  - تبويبات تصنيفات المكتبة.
  - رفع ملف إلى المكتبة.
  - تحميل ملف.
  - فتح ملف محمل سابقًا.
  - عرض تفاصيل الملف ونوعه وامتداده وأيقونته.
  - دعم حد رفع الملفات المحدث.
- **العمليات**:
  - `GET /student/library`
  - `GET /student/library/:id/download`
  - `POST /student/library/upload`
- **الأوفلاين**: عرض القائمة من الكاش وفتح الملفات المحلية ممكن، الرفع والتحميل يحتاجان إنترنت.

### 2.21 One Line Shot
- **المسار**: `/student/flashcards`
- **القائمة**: One Line Shot.
- **الشاشات المرتبطة**:
  - تفاصيل الحزمة `/student/flashcards/:id`.
  - مراجعة الحزمة `/student/flashcards/:id/review`.
  - المتجر `/student/flashcards-store`.
- **الوظائف**:
  - عرض كروت اليوم من قائمة يومية.
  - عرض الحزم وإحصائياتها.
  - إنشاء حزمة جديدة.
  - فتح تفاصيل حزمة.
  - إضافة بطاقة داخل الحزمة.
  - إنشاء حزمة فرعية.
  - حذف بطاقة أو حزمة.
  - تفعيل/تعطيل الحزمة.
  - مراجعة كروت بأنواع: قراءة سريعة، اقلب الكرت، سؤال وجواب، اختيارات.
  - تسجيل مستوى المراجعة: سهل، متوسط، صعب.
  - حفظ التقدم محليًا عند عدم الاتصال ومزامنته لاحقًا.
  - استعراض متجر الحزم واستنساخ حزمة إلى حساب الطالب.
- **العمليات**:
  - `GET /student/flashcards`
  - `GET /student/flashcards/daily-queue`
  - `GET /student/flashcards/:id`
  - `GET /student/flashcards/:id/review`
  - `GET /student/flashcards/store`
  - `POST /student/flashcards`
  - `DELETE /student/flashcards/:id`
  - `POST /student/flashcards/:id/toggle`
  - `POST /student/flashcards/clone/:id`
  - `POST /student/flashcards/:id/items`
  - `DELETE /student/flashcards/items/:id`
  - `POST /student/flashcards/progress`
- **الأوفلاين**: عرض البيانات المحفوظة وتسجيل التقدم محليًا ممكن، إنشاء/حذف/استنساخ الحزم يحتاج إنترنت.

### 2.22 التكاليف والواجبات
- **المسار**: `/student/assignments`
- **القائمة**: التكاليف والواجبات.
- **التبويبات**:
  - قيد الانتظار.
  - تم التسليم.
  - متأخرة.
- **الوظائف**:
  - عرض تكاليف الطالب.
  - ترتيب/فرز حسب تاريخ التسليم.
  - فتح تفاصيل التكليف.
  - تحديث أولوية التكليف للطالب.
  - تسليم التكليف مع ملف/ملاحظات حسب المتاح.
- **العمليات**:
  - `GET /student/assignments`
  - `GET /student/assignments/:id/details`
  - `POST /student/assignments/:id/priority`
  - `POST /student/assignments/:id/submit`
- **الأوفلاين**: عرض القائمة والتفاصيل من الكاش ممكن، التسليم وتغيير الأولوية يحتاجان إنترنت.

### 2.23 التذكيرات
- **المسار**: `/student/reminders`
- **القائمة**: التذكيرات.
- **الوظائف**:
  - عرض تذكيرات الطالب القادمة/المسجلة من النظام.
  - ربط بعض التذكيرات بمركز الدراسة أو مزرعة الأشجار حسب البيانات.
- **البيانات**: `GET /student/reminders`.
- **الأوفلاين**: مدعوم عبر الكاش.

### 2.24 الرسائل
- **المسار**: `/student/messages`
- **القائمة**: الرسائل.
- **الشاشة التفصيلية**: `/student/messages/:id`.
- **الوظائف**:
  - عرض محادثات الطالب.
  - بدء محادثة.
  - فتح محادثة.
  - إرسال رسالة نصية.
  - عرض عداد الرسائل غير المقروءة في الواجهة.
- **العمليات**:
  - `GET /student/messages`
  - `GET /student/messages/start`
  - `GET /student/messages/:id`
  - `POST /student/messages/:id`
- **الأوفلاين**: عرض المحادثات المحفوظة ممكن، الإرسال يحتاج إنترنت.

### 2.25 استفسارات الدكتور
- **المسار**: `/student/inquiries`
- **القائمة**: استفسارات الدكتور.
- **الشاشة التفصيلية**: `/student/inquiries/:id`.
- **الوظائف**:
  - عرض الاستفسارات.
  - فلترة حسب الحالة.
  - جلب خيارات إنشاء الاستفسار.
  - إنشاء استفسار جديد للدكتور/المادة.
  - فتح تفاصيل الاستفسار والردود والحالة.
- **العمليات**:
  - `GET /student/inquiries`
  - `GET /student/inquiries/options`
  - `GET /student/inquiries/:id`
  - `POST /student/inquiries`
- **الأوفلاين**: عرض القوائم والتفاصيل من الكاش ممكن، الإنشاء يحتاج إنترنت.

### 2.26 القسم العملي والسريري
- **المسار الرئيسي**: `/student/clinical`
- **القائمة**: يظهر إذا كان تخصص الطالب يدعم القسم السريري.
- **الوظائف العامة**:
  - عرض مركز السريري.
  - عرض ملخص السجل والتقييمات والتدريب والحالات النادرة.
  - التنقل إلى شاشات القسم السريري الفرعية.
- **الأوفلاين**: أغلب العرض من الكاش، العمليات تحتاج إنترنت.

#### السجل السريري
- **المسار**: `/student/clinical/logbook`
- **الوظائف**:
  - عرض السجلات السريرية.
  - إنشاء سجل جديد.
  - تعديل سجل.
  - حذف سجل.
  - عرض QR/باركود للسجل عند الحاجة.
  - تجديد QR للسجل غير المكتمل.
  - عرض حالة الاعتماد.
  - عرض المهام السريرية وإرسال إنجاز مهمة.
- **العمليات**:
  - `GET /student/clinical/logbook`
  - `POST /student/clinical/logbook`
  - `PUT /student/clinical/logbook/:id`
  - `DELETE /student/clinical/logbook/:id`
  - `POST /student/clinical/logbook/:id/regenerate-qr`
  - `POST /student/clinical/assignments/:id/submit`

#### التقييمات السريرية
- **المسار**: `/student/clinical/evaluations`
- **الوظائف**:
  - عرض تقييمات الطالب السريرية.
  - عرض الدرجات والتقييمات والملاحظات حسب البيانات.
- **البيانات**: `GET /student/clinical/evaluations`.

#### الاختبار والتدريب السريري
- **المسار**: `/student/clinical/mock-exams`
- **شاشة الحل**: `/student/clinical/mock-exams/:id/take`
- **شاشة النتيجة**: `/student/clinical/mock-exams/results/:id`
- **الوظائف**:
  - عرض نماذج التدريب المتاحة.
  - إنشاء قائمة تدريب مخصصة.
  - حذف قائمة تدريب مخصصة.
  - اختيار نمط المؤقت: رسمي، مخصص، أو حر.
  - إدخال الوقت المخصص رقميًا.
  - حل عناصر التقييم: تم، جزئي، لم يتم.
  - تسليم التدريب.
  - عرض النتيجة والتحليل والمهارات والبنود.
- **العمليات**:
  - `GET /student/clinical/mock-exams`
  - `POST /student/clinical/mock-exams/custom`
  - `DELETE /student/clinical/mock-exams/custom/:id`
  - `GET /student/clinical/mock-exams/:id/take`
  - `POST /student/clinical/mock-exams/:id/submit`
  - `GET /student/clinical/mock-exams/results/:id`

#### مركز الحالات النادرة
- **المسار**: `/student/clinical/rare-cases`
- **الوظائف**:
  - عرض الحالات النادرة.
  - فتح تفاصيل حالة.
  - عرض التشخيص، المركز/المستشفى، القسم، الغرفة، الدكتور، تاريخ النشر، العلامات السريرية، والمرفق إن وجد.
- **العمليات**:
  - `GET /student/clinical/rare-cases`
  - `GET /student/clinical/rare-cases/:id`

### 2.27 الدعم الفني
- **المسار**: `/student/support`
- **الوظائف**:
  - عرض قنوات التواصل المباشر.
  - عرض روابط منصات التواصل الاجتماعي.
  - صفحة معلومات ودعم، وليست مرتبطة بـ API رئيسي.

### 2.28 Placeholder
- **المسار**: `/student/placeholder/:feature`
- **الوظيفة**:
  - شاشة احتياطية عند وجود عنصر قائمة أو مسار ميزة غير مكتملة.

## 3. حساب المندوب

### 3.1 الرئيسية
- **المسار**: `/delegate/dashboard`
- **القائمة**: الرئيسية.
- **الوظائف**:
  - عرض ملخص الدفعة.
  - عرض إحصائيات الطلاب والمواد والحضور والدرجات والرسائل.
  - أزرار وصول سريع للطلاب، المواد، الحضور، الدرجات، الرسائل، وQR.
- **البيانات**: `GET /delegate/dashboard`.
- **الأوفلاين**: لا يظهر في repository كاش مخصص للمندوب؛ يعتمد على الاتصال.

### 3.2 أخبار الدفعة
- **المسار**: `/delegate/news`
- **الوظائف**:
  - عرض أخبار الدفعة.
  - فتح تفاصيل الخبر.
  - التصويت على الخبر إذا كان يدعم التصويت.
  - تعليم كل الأخبار كمقروءة.
- **العمليات**:
  - `GET /delegate/news`
  - `GET /delegate/news/:batchId`
  - `POST /delegate/news/:id/vote`
  - `POST /delegate/news/mark-all-as-read`

### 3.3 تنبيهات المندوب
- **المسار**: `/delegate/notifications`
- **الوظائف**:
  - عرض التنبيهات.
  - تعليم تنبيه كمقروء.
  - تعليم الكل كمقروء.
- **العمليات**:
  - `GET /delegate/notifications`
  - `POST /delegate/notifications/:id/read`
  - `POST /delegate/notifications/mark-all-read`

### 3.4 الطلاب
- **المسار**: `/delegate/students`
- **الوظائف**:
  - عرض طلاب الدفعة.
  - البحث والفلترة.
  - إنشاء طالب.
  - تعديل طالب.
  - حذف طالب.
  - تحميل قالب Excel للطلاب.
  - استيراد طلاب من Excel.
  - عرض وتعديل صلاحيات الطالب الخاصة بالمكتبة المشتركة.
- **العمليات**:
  - `GET /delegate/students`
  - `GET /delegate/students/template`
  - `POST /delegate/students/import`
  - `POST /delegate/students`
  - `PUT /delegate/students/:id`
  - `DELETE /delegate/students/:id`
  - `GET /delegate/students/:id/permissions`
  - `POST /delegate/students/:id/permissions`

### 3.5 المواد
- **المسار**: `/delegate/subjects`
- **الوظائف**:
  - عرض مواد الدفعة.
  - عرض تفاصيل المادة.
  - إنشاء مادة.
  - تعديل مادة.
  - حذف مادة.
  - اختيار الدكتور، الترم، والبيانات الأكاديمية.
- **العمليات**:
  - `GET /delegate/subjects`
  - `GET /delegate/subjects/:id`
  - `GET /delegate/subjects/doctors`
  - `GET /delegate/subjects/terms`
  - `POST /delegate/subjects`
  - `PUT /delegate/subjects/:id`
  - `DELETE /delegate/subjects/:id`

### 3.6 الجدول الدراسي
- **المسار**: `/delegate/schedules`
- **الوظائف**:
  - عرض جدول الدفعة حسب الأيام.
  - إنشاء حصة.
  - تعديل حصة.
  - حذف حصة.
  - اختيار المادة واليوم والوقت والمكان.
- **العمليات**:
  - `GET /delegate/schedules`
  - `POST /delegate/schedules`
  - `PUT /delegate/schedules/:id`
  - `DELETE /delegate/schedules/:id`

### 3.7 جداول الاختبارات
- **المسار**: `/delegate/exams`
- **الوظائف**:
  - عرض جداول الاختبارات التي يديرها المندوب.
  - إنشاء جدول اختبار.
  - تعديل جدول اختبار.
  - حذف جدول اختبار.
- **العمليات**:
  - `GET /delegate/exam-schedules`
  - `POST /delegate/exam-schedules`
  - `PUT /delegate/exam-schedules/:id`
  - `DELETE /delegate/exam-schedules/:id`

### 3.8 التكاليف والواجبات
- **المسار**: `/delegate/assignments`
- **الوظائف**:
  - عرض تكاليف الدفعة.
  - تبويب نشطة ومنتهية.
  - إنشاء تكليف.
  - تعديل تكليف.
  - حذف تكليف.
  - ربط التكليف بمادة وتاريخ تسليم ووصف.
- **العمليات**:
  - `GET /delegate/assignments`
  - `POST /delegate/assignments`
  - `PUT /delegate/assignments/:id`
  - `DELETE /delegate/assignments/:id`

### 3.9 مصادر المقرر
- **المسار**: `/delegate/resources`
- **الوظائف**:
  - عرض مصادر المقرر.
  - البحث والفلترة والتبويبات حسب التصنيف.
  - رفع مصدر جديد.
  - تعديل مصدر.
  - حذف مصدر.
  - استيراد مصدر من المكتبة المشتركة.
- **العمليات**:
  - `GET /delegate/resources`
  - `POST /delegate/resources`
  - `PUT /delegate/resources/:id`
  - `DELETE /delegate/resources/:id`
  - `GET /delegate/library/search`
  - `POST /delegate/resources/import`

### 3.10 المكتبة المشتركة للمندوب
- **المسار**: `/delegate/resources/library`
- **الوظائف**:
  - البحث في المكتبة المشتركة.
  - استيراد ملف من المكتبة إلى مصادر المقرر.
  - اختيار المادة والتصنيف والبيانات المرتبطة.
- **العمليات**:
  - `GET /delegate/library/search`
  - `POST /delegate/resources/import`

### 3.11 التذكيرات
- **المسار**: `/delegate/reminders`
- **الوظائف**:
  - عرض التذكيرات حسب الفلتر.
  - إنشاء تذكير.
  - تعديل تذكير.
  - حذف تذكير.
- **العمليات**:
  - `GET /delegate/reminders`
  - `POST /delegate/reminders`
  - `PUT /delegate/reminders/:id`
  - `DELETE /delegate/reminders/:id`

### 3.12 إعلانات الدفعة
- **المسار**: `/delegate/announcements`
- **الوظائف**:
  - عرض إعلانات الدفعة.
  - إنشاء إعلان نصي أو بمرفق.
  - تعديل إعلان.
  - حذف إعلان.
  - تثبيت/إلغاء تثبيت إعلان.
  - فلترة حسب الحالة/النوع حسب الشاشة.
- **العمليات**:
  - `GET /delegate/announcements`
  - `POST /delegate/announcements`
  - `PUT /delegate/announcements/:id`
  - `POST /delegate/announcements/:id`
  - `PATCH /delegate/announcements/:id/toggle-pin`
  - `DELETE /delegate/announcements/:id`

### 3.13 رصد الحضور
- **المسار**: `/delegate/attendance`
- **المسارات المرتبطة**:
  - `/delegate/attendance/tracking`
  - `/delegate/attendance/form`
  - `/delegate/qr-attendance`
  - `/delegate/attendance/qr-session`
- **التبويبات**:
  - مواد/بدء رصد.
  - سجل الحضور والتقارير.
- **الوظائف**:
  - عرض المواد والمحاضرات المتاحة للرصد.
  - بدء جلسة رصد حضور.
  - رصد يدوي للطلاب.
  - حفظ سجل حضور.
  - عرض سجلات الحضور السابقة.
  - عرض تقرير حضور.
  - تنزيل تقرير حضور PDF.
  - بدء QR حضور.
  - تدوير رمز QR.
  - متابعة حالة جلسة QR.
  - إنهاء جلسة QR.
  - إلغاء جلسة QR.
  - ربط جلسة QR مع الديسكتوب بكود Pairing.
- **العمليات**:
  - `GET /delegate/attendances`
  - `GET /delegate/attendances/create`
  - `POST /delegate/attendances`
  - `GET /delegate/attendances/report`
  - `GET /delegate/attendances/report/pdf`
  - `POST /delegate/attendance-pairing`
  - `POST /delegate/qr-attendance/start`
  - `GET /delegate/qr-attendance/:id/token`
  - `GET /delegate/qr-attendance/:id/status`
  - `POST /delegate/qr-attendance/:id/finalize`
  - `POST /delegate/qr-attendance/:id/cancel`
  - `GET /delegate/qr-attendance/active`

### 3.14 إنذارات الغياب
- **المسار**: `/delegate/absence-alerts`
- **التبويبات**:
  - غائبون اليوم.
  - المعرضون للحرمان.
- **الوظائف**:
  - عرض الطلاب الغائبين اليوم.
  - عرض الطلاب المعرضين للحرمان.
  - فتح رسالة لطالب من القائمة عند الحاجة.
- **العملية**: `GET /delegate/attendances/alerts`.

### 3.15 الدرجات المفوضة
- **المسار**: `/delegate/authorized-grades`
- **المسار البديل**: `/delegate/grade-helper-delegations`
- **التبويبات**:
  - مهامي.
  - المساعدون.
- **الوظائف**:
  - عرض فئات الدرجات المفوضة للمندوب.
  - فتح تفاصيل فئة.
  - إدخال درجات الطلاب المفوضة.
  - حفظ الدرجات.
  - عرض تفويضات المساعدين.
  - إنشاء تفويض مساعد.
  - إلغاء تفويض مساعد.
- **العمليات**:
  - `GET /delegate/authorized-grades`
  - `GET /delegate/authorized-grades/:categoryId`
  - `POST /delegate/authorized-grades/:categoryId`
  - `GET /delegate/grade-helper-delegations`
  - `GET /delegate/grade-helper-delegations/:categoryId/students`
  - `POST /delegate/grade-helper-delegations`
  - `DELETE /delegate/grade-helper-delegations/:id`

### 3.16 رسائل الطلاب
- **المسار**: `/delegate/messages`
- **الشاشة التفصيلية**: `/delegate/messages/:id`
- **الوظائف**:
  - عرض محادثات الطلاب.
  - عرض الطلاب المؤهلين للمراسلة.
  - فتح محادثة.
  - إرسال رسالة لطالب.
- **العمليات**:
  - `GET /delegate/messages`
  - `GET /delegate/messages/eligible-students`
  - `GET /delegate/messages/:id`
  - `POST /delegate/messages/:id`

### 3.17 محادثات الدكاترة
- **المسار**: `/delegate/doctor-chats`
- **الشاشة التفصيلية**: `/delegate/doctor-chats/:id`
- **الوظائف**:
  - عرض محادثات الدكاترة.
  - عرض الدكاترة المؤهلين للمراسلة.
  - فتح محادثة.
  - إرسال رسالة لدكتور.
- **العمليات**:
  - `GET /delegate/doctor-chats`
  - `GET /delegate/doctor-chats/eligible-doctors`
  - `GET /delegate/doctor-chats/:id`
  - `POST /delegate/doctor-chats/:id`

### 3.18 استفسارات الدكتور للمندوب
- **المسار**: `/delegate/inquiries`
- **الوظائف**:
  - عرض الاستفسارات.
  - فلترة حسب الحالة.
  - فتح تفاصيل استفسار.
  - الرد على استفسار.
  - تحويل استفسار.
  - تحديث حالة الاستفسار.
- **العمليات**:
  - `GET /delegate/inquiries`
  - `GET /delegate/inquiries/:id`
  - `POST /delegate/inquiries/:id/reply`
  - `POST /delegate/inquiries/:id/forward`
  - `PATCH /delegate/inquiries/:id/status`

### 3.19 اشتراك المندوب والرصيد
- **المسار**: `/delegate/subscription`
- **الوظائف**:
  - عرض حالة اشتراك المندوب.
  - عرض الباقات.
  - الاشتراك.
  - استرداد كود.
  - تفعيل/إيقاف التجديد التلقائي.
- **العمليات**:
  - `GET /delegate/subscription`
  - `POST /delegate/subscription/redeem`
  - `POST /delegate/subscription/subscribe`
  - `POST /delegate/subscription/auto-renew`

### 3.20 كشف حساب المندوب
- **المسار**: `/delegate/ledger`
- **الوظائف**:
  - عرض كشف حساب المندوب.
  - التنقل بين الصفحات.
  - تصدير PDF.
- **العمليات**:
  - `GET /delegate/ledger`
  - `GET /delegate/ledger/export`

### 3.21 ملف المندوب الشخصي
- **المسار**: `/delegate/profile`
- **الوظائف**:
  - عرض بيانات المندوب.
  - عرض بيانات الطالب المرتبطة عند الحاجة.
  - تغيير كلمة المرور.
- **العمليات**:
  - `GET /delegate/me`
  - `GET /student/me`
  - `POST /delegate/change-password`

### 3.22 الصلاحيات والاشتراك في حساب المندوب
- عناصر كثيرة في قائمة المندوب عليها `requiresSubscription = true`.
- إذا كان العنصر يحتاج اشتراكًا ولم يكن المندوب مشتركًا، يظهر تنبيه ويدفعه إلى صفحة الاشتراك.
- بعض الوظائف تعتمد على صلاحيات الجلسة القادمة من `AuthSession.permissions`.
- عند عدم وجود صلاحية، تعرض الشاشات Dialog يوضح عدم امتلاك صلاحية العملية.

## 4. المندوب العملي

### 4.1 مركز المندوب العملي
- **المسار**: `/student/practical`
- **الظهور**: يظهر فقط إذا كانت جلسة الطالب تحتوي `isPracticalDelegate`.
- **الوظائف**:
  - عرض إحصائيات السجلات المعتمدة والمعلقة.
  - عرض المهام السريرية.
  - عرض تقييمات الطالب.
  - عرض نماذج التدريب.
  - عرض الحالات التي تحتاج مراجعة.
  - عرض آخر السجلات.
  - روابط سريعة إلى السجل والحالات والتفويضات.
- **البيانات**:
  - `GET /student/clinical/logbook`
  - `GET /student/clinical/evaluations`
  - `GET /student/clinical/mock-exams`
  - `GET /delegate/clinical/cases/pending`
  - `GET /student/clinical/cases/pending`

### 4.2 السجل العملي
- **المسار**: `/student/practical/logbook`
- **الوظائف**:
  - عرض السجلات العملية.
  - عرض حالة الاعتماد.
  - عرض المهام السريرية المرتبطة.
  - عرض تفاصيل السجل والباركود/QR حسب البيانات المتاحة.
- **البيانات**: `GET /student/clinical/logbook`.

### 4.3 مراجعة الحالات
- **المسار**: `/student/practical/cases`
- **الوظائف**:
  - عرض الحالات التي تنتظر اعتماد المندوب العملي.
  - عرض الحالات التي أرسلها المستخدم كمساعد عملي.
  - اعتماد حالة.
  - رفض حالة مع سبب.
- **العمليات**:
  - `GET /delegate/clinical/cases/pending`
  - `GET /student/clinical/cases/pending`
  - `POST /delegate/clinical/cases/:id/approve`
  - `POST /delegate/clinical/cases/:id/reject`

### 4.4 تفويض مساعدين
- **المسار**: `/student/practical/delegations`
- **الوظائف**:
  - عرض التفويضات السريرية/العملية.
  - عرض الطلاب المؤهلين.
  - إنشاء تفويض لطالب مساعد.
  - إلغاء تفويض.
- **العمليات**:
  - `GET /delegate/clinical/delegations`
  - `GET /delegate/clinical/delegations/students`
  - `POST /delegate/clinical/delegations`
  - `DELETE /delegate/clinical/delegations/:id`

## 5. الوظائف المشتركة

### 5.1 الجلسة والتوجيه
- تخزين التوكن وبيانات الجلسة في `SessionStorage`.
- دعم Workspace للطالب والمندوب.
- إمكانية حساب واحد يملك صلاحية الوصول لمساحة الطالب والمندوب حسب الدور.
- عند فتح إشعار قبل جاهزية الجلسة، يخزن التطبيق الوجهة مؤقتًا ثم يفتحها بعد تسجيل الدخول.

### 5.2 الاشتراك وحماية القوائم
- عناصر القائمة قد تكون مفتوحة أو مشروطة بالاشتراك.
- إذا كان الاشتراك غير فعال، يظهر تنبيه وينتقل المستخدم إلى صفحة الاشتراك.
- QR الطالب غير مشروط بالاشتراك.
- القسم السريري يظهر فقط إذا كان التخصص يدعم السريري.
- قسم المندوب العملي يظهر فقط للمستخدم ذي صلاحية `isPracticalDelegate`.

### 5.3 الإشعارات
- يستخدم Firebase Messaging.
- يسجل توكن الجهاز في:
  - `/student/devices/token`
  - أو `/delegate/devices/token`
  حسب مساحة المستخدم.
- يحذف توكن الجهاز عند تسجيل الخروج.
- يعرض إشعارًا محليًا عند استقبال إشعار في المقدمة.
- يدعم التنقل من الإشعار إلى:
  - مركز الدراسة أو جلسة دراسة.
  - الكويزات.
  - التكاليف.
  - الجداول.
  - التذكيرات.
  - مصادر المقرر.
  - المكتبة.
  - النجوم.
  - الاستفسارات.
  - الرسائل.
  - الأخبار.
  - شاشة التنبيهات كـ fallback.

### 5.4 العمل بدون إنترنت
- يوجد `ConnectivityService` لمراقبة حالة الاتصال.
- يظهر شريط Offline Banner عند انقطاع الاتصال.
- عند عودة الاتصال يتم تحديث الجلسة والداشبورد والاشتراك وعدادات التنبيهات.
- يوجد `OfflineCacheService` لتخزين بيانات الطالب في ملفات JSON.
- عند فشل الشبكة، يحاول repository الطالب قراءة نسخة مخزنة.
- البيانات المخزنة تحتوي معلومات مثل `cached_at`, `cache_age_hours`, و`offline_stale`.
- ليست كل وظائف المندوب مخزنة أوفلاين؛ الكاش الأساسي مركز في حساب الطالب.

### 5.5 التحميل وفتح الملفات
- يستخدم `DownloadService`.
- يدعم:
  - تحميل رابط عام.
  - تحميل داخل مجلد `Moeen` مقسم حسب القسم.
  - إيجاد ملف محمل سابقًا.
  - فتح ملف محلي.
  - كاش داخلي للملفات.
  - إشعارات تقدم التحميل.
  - إشعار اكتمال أو فشل التحميل.
  - إنشاء اسم فريد عند تكرار اسم الملف مع الحفاظ على الامتداد.
- يستخدم `OpenFilex` لفتح الملفات.

### 5.6 الحوارات والتصميم
- `showMoeenConfirmDialog` للتأكيدات.
- `showMoeenInfoDialog` لرسائل النجاح والخطأ.
- `showMoeenBottomSheet` للنماذج السريعة.
- `StudentShell` و`DelegateShell` يوفران:
  - AppBar.
  - Drawer.
  - شارات التنبيهات.
  - شارة النجوم في حساب الطالب.
  - معالجة زر الرجوع.
  - تنبيه الخروج عند الحاجة.
  - تسجيل الخروج الآمن.

## 6. جدول مطابقة سريع

| المسار | الشاشة | الحساب | الوظيفة |
|---|---|---|---|
| `/` | SplashScreen | عام | فحص الجلسة والتوجيه |
| `/login` | LoginScreen | عام | تسجيل الدخول |
| `/register` | RegisterScreen | عام | إنشاء حساب طالب |
| `/home` | HomePlaceholderScreen | عام | توجيه/صفحة انتقال عامة |
| `/student/home` | StudentDashboardScreen | طالب | الرئيسية |
| `/student/profile` | StudentProfileScreen | طالب | الملف الشخصي |
| `/student/subscription` | StudentSubscriptionScreen | طالب | الاشتراك والرصيد |
| `/student/ledger` | StudentLedgerScreen | طالب | السجل المالي |
| `/student/subjects` | StudentSubjectsScreen | طالب | المقررات |
| `/student/subjects/:id` | StudentSubjectDetailsScreen | طالب | تفاصيل مقرر |
| `/student/study-center` | StudentStudyCenterScreen | طالب | مركز الدراسة |
| `/student/study-center/:id/session` | StudentStudySessionScreen | طالب | جلسة دراسة |
| `/student/schedules` | StudentScheduleScreen | طالب | الجدول الدراسي |
| `/student/news` | StudentNewsScreen | طالب | الأخبار والإعلانات |
| `/student/quizzes` | StudentQuizzesScreen | طالب | الكويزات |
| `/student/quizzes/:id/take` | StudentQuizTakeScreen | طالب | حل كويز |
| `/student/quizzes/results/:attemptId` | StudentQuizResultScreen | طالب | نتيجة كويز |
| `/student/stars` | StudentStarsScreen | طالب | النجوم |
| `/student/tree-farm` | StudentTreeFarmScreen | طالب | مزرعة الأشجار |
| `/student/notifications` | StudentNotificationsScreen | طالب | التنبيهات |
| `/student/qr-scan` | StudentQrScanScreen | طالب | QR الحضور |
| `/student/reminders` | StudentRemindersScreen | طالب | التذكيرات |
| `/student/messages` | StudentMessagesScreen | طالب | الرسائل |
| `/student/messages/:id` | StudentConversationScreen | طالب | محادثة |
| `/student/inquiries` | StudentInquiriesScreen | طالب | الاستفسارات |
| `/student/inquiries/:id` | StudentInquiryDetailsScreen | طالب | تفاصيل استفسار |
| `/student/clinical` | StudentClinicalScreen | طالب | القسم السريري |
| `/student/clinical/logbook` | StudentClinicalLogbookScreen | طالب | السجل السريري |
| `/student/clinical/evaluations` | StudentClinicalEvaluationsScreen | طالب | التقييمات |
| `/student/clinical/mock-exams` | StudentClinicalMockExamsScreen | طالب | التدريب السريري |
| `/student/clinical/mock-exams/:id/take` | StudentClinicalMockTakeScreen | طالب | حل تدريب |
| `/student/clinical/mock-exams/results/:id` | StudentClinicalMockResultScreen | طالب | نتيجة تدريب |
| `/student/clinical/rare-cases` | StudentClinicalRareCasesScreen | طالب | الحالات النادرة |
| `/student/assignments` | StudentAssignmentsScreen | طالب | التكاليف |
| `/student/assignments/:id` | StudentAssignmentDetailsScreen | طالب | تفاصيل تكليف |
| `/student/flashcards` | StudentFlashcardsScreen | طالب | One Line Shot |
| `/student/flashcards-store` | StudentFlashcardStoreScreen | طالب | متجر الكروت |
| `/student/flashcards/:id/review` | StudentFlashcardReviewScreen | طالب | مراجعة كروت |
| `/student/flashcards/:id` | StudentFlashcardDetailsScreen | طالب | تفاصيل حزمة |
| `/student/exams` | StudentExamsScreen | طالب | جداول الاختبارات |
| `/student/resources` | StudentResourcesScreen | طالب | مصادر المقرر |
| `/student/library` | StudentLibraryScreen | طالب | المكتبة المشتركة |
| `/student/support` | StudentSupportScreen | طالب | الدعم |
| `/student/placeholder/:feature` | StudentPlaceholderScreen | طالب | شاشة احتياطية |
| `/student/practical` | PracticalDelegateHomeScreen | مندوب عملي | مركز المندوب العملي |
| `/student/practical/logbook` | PracticalLogbookScreen | مندوب عملي | السجل العملي |
| `/student/practical/cases` | PracticalCasesScreen | مندوب عملي | مراجعة الحالات |
| `/student/practical/delegations` | PracticalDelegationsScreen | مندوب عملي | تفويض مساعدين |
| `/delegate/dashboard` | DelegateDashboardScreen | مندوب | الرئيسية |
| `/delegate/news` | DelegateNewsScreen | مندوب | أخبار الدفعة |
| `/delegate/notifications` | DelegateNotificationsScreen | مندوب | التنبيهات |
| `/delegate/students` | DelegateStudentsScreen | مندوب | الطلاب |
| `/delegate/subjects` | DelegateSubjectsScreen | مندوب | المواد |
| `/delegate/schedules` | DelegateSchedulesScreen | مندوب | الجدول |
| `/delegate/exams` | DelegateExamSchedulesScreen | مندوب | جداول الاختبارات |
| `/delegate/assignments` | DelegateAssignmentsScreen | مندوب | التكاليف |
| `/delegate/resources` | DelegateResourcesScreen | مندوب | مصادر المقرر |
| `/delegate/resources/library` | DelegateSharedLibraryScreen | مندوب | المكتبة المشتركة |
| `/delegate/reminders` | DelegateRemindersScreen | مندوب | التذكيرات |
| `/delegate/announcements` | DelegateAnnouncementsScreen | مندوب | الإعلانات |
| `/delegate/attendance` | DelegateAttendanceScreen | مندوب | الحضور والتقارير |
| `/delegate/attendance/tracking` | DelegateAttendanceTrackingScreen | مندوب | بدء/متابعة رصد |
| `/delegate/attendance/form` | DelegateAttendanceFormScreen | مندوب | نموذج حضور يدوي |
| `/delegate/qr-attendance` | DelegateAttendanceScreen | مندوب | مدخل QR الحضور |
| `/delegate/attendance/qr-session` | DelegateQrSessionScreen | مندوب | جلسة QR |
| `/delegate/absence-alerts` | DelegateAbsenceAlertsScreen | مندوب | إنذارات الغياب |
| `/delegate/authorized-grades` | DelegateAuthorizedGradesScreen | مندوب | الدرجات المفوضة |
| `/delegate/grade-helper-delegations` | DelegateAuthorizedGradesScreen | مندوب | تفويض مساعدي الدرجات |
| `/delegate/messages` | DelegateMessagesScreen | مندوب | رسائل الطلاب |
| `/delegate/messages/:id` | DelegateConversationScreen | مندوب | محادثة طالب |
| `/delegate/doctor-chats` | DelegateDoctorChatsScreen | مندوب | محادثات الدكاترة |
| `/delegate/doctor-chats/:id` | DelegateDoctorConversationScreen | مندوب | محادثة دكتور |
| `/delegate/inquiries` | DelegateInquiriesScreen | مندوب | الاستفسارات |
| `/delegate/subscription` | DelegateSubscriptionScreen | مندوب | الاشتراك |
| `/delegate/ledger` | DelegateLedgerScreen | مندوب | كشف الحساب |
| `/delegate/profile` | DelegateProfileScreen | مندوب | الملف الشخصي |

## 7. ملاحظات تحقق

- تم استخراج الشاشات من `app_router.dart`.
- تم استخراج عناصر حساب الطالب من `StudentShell`.
- تم استخراج عناصر حساب المندوب من `DelegateShell`.
- تم استخراج وظائف الطالب من `StudentContentRepository` وواجهات الطالب.
- تم استخراج وظائف المندوب من `DelegateRepository` وواجهات المندوب.
- تم استخراج وظائف المندوب العملي من `PracticalDelegateRepository`.
- تم تضمين الوظائف الداخلية المهمة: الإشعارات، التحميل، الكاش، الجلسة، وواجهات الحوارات.
