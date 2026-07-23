import json

collection_path = r"e:\Projects\student_dashboard\Attendify_Student_API.postman_collection.json"

with open(collection_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Descriptions map: keys are string matches on request url raw or path
descriptions = {
    "api/student/login": """**تسجيل دخول الطالب**
- **المدخلات (Body):** `academic_number` (الرقم الأكاديمي), `password` (كلمة المرور).
- **المخرجات:** يقوم بإرجاع بيانات الطالب مع `token` (يجب حفظه واستخدامه في جميع الطلبات القادمة).
- **ملاحظة للفرونت إند:** لا تنسَ تخزين الـ Token محلياً (مثلاً في SharedPreferences) وإرساله في `Authorization: Bearer {token}` في جميع الـ Endpoints الأخرى.""",
    
    "api/student/me": """**جلب بيانات الطالب الحالي**
- **ملاحظة:** يستخدم للتحقق من أن الـ Token ما زال صالحاً ولتحديث بيانات الطالب في التطبيق.""",
    
    "api/student/change-password": """**تغيير كلمة المرور**
- **المدخلات:** `current_password`, `new_password`, `new_password_confirmation`.
- **ملاحظة:** يرجى إظهار رسالة نجاح للمستخدم عند التغيير.""",

    "api/student/dashboard": """**الواجهة الرئيسية (Dashboard)**
- **ماذا تفعل؟** ترجع الإحصائيات العامة للطالب (نسبة الحضور، المهام غير المنجزة، الجدول اليومي، وأهم التنبيهات).
- **ملاحظة للفرونت إند:** هذه هي الـ Endpoint التي يجب استدعاؤها بمجرد فتح التطبيق لبناء الشاشة الرئيسية.""",
    
    "api/student/notifications": """**التنبيهات**
- **ملاحظة:** يمكن استدعاء `api/student/notifications/unread-count` لمعرفة عدد التنبيهات غير المقروءة لعرضها كـ Badge أحمر فوق أيقونة الجرس.""",
    
    "api/student/subjects": """**المواد الدراسية (Subjects)**
- **البارامترات (Query):** يمكن إرسال `?semester_id=X` لفلترة المواد حسب الترم.
- **ملاحظة للفرونت إند:** هذه الشاشة تعرض المواد للترم الحالي افتراضياً. يحتوي الرد على نسبة الحضور لكل مادة.""",

    "api/student/subjects/{{subject_id}}": """**تفاصيل المادة الدراسية**
- **ماذا تفعل؟** تقوم بجلب كل ما يخص المادة (محاضرات، درجات، تكاليف، وإحصائيات الحضور بتفصيل).
- **العمليات المخفية (Hidden Logic):**
  1. ترجع نسبة الغياب وتوضح `warning_level` (إن كان `danger` فإنه معرّض للحرمان ويجب إظهار تحذير أحمر).
  2. ترجع قائمة المحاضرات `lectures` وكل محاضرة بها حقل `is_studied` (لتفعيل زر تمت المذاكرة).
  3. ترجع سجل الغيابات `attendance_history` مع توضيح `can_submit_excuse` إذا كان غائباً ولم يتجاوز المهلة المسموحة لتقديم العذر.""",

    "api/student/lectures/{{lecture_id}}/toggle-listen": """**تحديد المحاضرة كمقروءة/مسموعة**
- **ماذا تفعل؟** Endpoint من نوع Toggle (إذا كانت غير مقروءة تجعلها مقروءة والعكس).
- **ملاحظة:** استخدمها لزر الـ Checkbox في قائمة المحاضرات.""",

    "api/student/assignments": """**قائمة التكاليف الواجبات (Assignments)**
- **ماذا تفعل؟** جلب كل التكاليف الخاصة بمواد الطالب.
- **الحالات:** `available` (متاح)، `submitted` (تم التسليم)، `missing` (متأخر). الرجاء تلوين الـ UI بناءً على الحالة.""",
    
    "api/student/assignments/preference": """**تحديث تفضيلات التكاليف**
- **المدخلات:** يمكن تمرير الفلتر المطلوب لحفظ تفضيل العرض.""",

    "api/student/assignments/{{assignment_id}}": """**عرض بيانات التكليف الأساسية**""",
    
    "api/student/assignments/{{assignment_id}}/details": """**عرض تفاصيل التكليف مع المرفقات**""",

    "api/student/assignments/{{assignment_id}}/submit": """**تسليم التكليف**
- **المدخلات:** إرسال `file` (مرفق) و `notes` كـ `multipart/form-data`.
- **ملاحظة:** تأكد من إظهار Loading Indicator للمستخدم لأن رفع الملفات قد يستغرق بعض الوقت.""",

    "api/student/assignments/{{assignment_id}}/priority": """**تحديد أولوية التكليف**
- **المدخلات:** `priority` (high, medium, low).
- **الفائدة:** يتيح للطالب ترتيب واجباته المحفوظة محلياً أو على السيرفر.""",

    "api/student/schedule": """**الحبر الذكي (جدول الطالب الذكي - Smart Schedule)**
- **ماذا تفعل؟** تجلب جدول مهام الطالب الخاص (Study Hub).
- **البارامترات (Query):** يمكن تمرير `?tab=study` أو `reminders` أو `resources` أو `assignments` لجلب البيانات المخصصة للتبويب.
- **ملاحظة:** يتم حساب الإحصائيات (مثل المتأخرة والمنجزة) وإرجاعها في الرد `stats` لتحديث الكروت في واجهة المستخدم.""",

    "api/student/schedule/custom-task": """**إضافة مهمة مخصصة للحبر الذكي**
- **المدخلات:** `title`, `scheduled_date`, `item_type`, `priority`.""",

    "api/student/schedule/check-reminders": """**التحقق من التنبيهات المستحقة (Local Notifications Tracker)**
- **ملاحظة للفرونت إند:** يمكن استدعاء هذا الرابط بشكل صامت في الخلفية (Background) عند فتح التطبيق لجلب أي تنبيهات مستحقة وإظهارها كـ In-App Notification أو Push Notification محلي.""",

    "api/student/schedule/reorder": """**إعادة ترتيب المهام (Drag & Drop)**
- **المدخلات (Body):** مصفوفة `items` تحتوي على `id` و `order`.
- **الاستخدام:** يتم الاستدعاء صامتاً في الخلفية عند قيام الطالب بإعادة ترتيب عناصر الجدول.""",

    "api/student/library": """**المكتبة المشتركة (Shared Library)**
- **البارامترات (Query Filters):** `subject_id`, `category`, `search`, `year`.
- **العمليات المخفية:** لا تعرض للمستخدم إلا الملفات المسموح بها برمجياً (حسب دفعة الطالب أو الكلية أو الكشوفات العامة).""",

    "api/student/library/{{resource}}/download": """**تحميل ملف من المكتبة المشتركة**
- **ماذا تفعل؟** تقوم بزيادة عداد التحميلات (Downloads Count) ثم تُرجع لك الرابط المباشر `download_url`.
- **كيفية الاستخدام في التطبيق:**
  1. اطلب هذا المسار أولاً.
  2. خذ `download_url` من الرد.
  3. قم بتنزيل الملف باستخدام مكتبة تنزيل (مثل Flutter Downloader) لتوفير تجربة مستخدم جيدة مع شريط تقدم (Progress Bar).""",

    "api/student/library/upload": """**رفع ملف إلى المكتبة المشتركة**
- **المدخلات:** `file`, `title`, `subject_id`, `category`, `visibility` (batch|college|everyone).
- **ملاحظة هامة:** يجب إرسال الطلب كـ `multipart/form-data` مع التأكد من أن الطالب لديه صلاحية الرفع (إلا سيرجع الخطأ 403).""",

    "api/student/cards-generate": """**توليد واستعراض الكروت الجاهزة للطباعة**
- **ماذا تفعل؟** خاصية استخراج بطاقات مالية أو تعريفية (حسب الكود المدعوم في السيرفر). إذا كان `GET` فهذا لعرض الطلبات السابقة.""",

    "api/student/subscription": """**عرض حالة الاشتراك (Subscription)**
- **البيانات المرجعة:** `user_balance` (الرصيد الحالي), `is_subscribed` (هل هو مشترك), `subscribed_until` (تاريخ الانتهاء), و `packages` (الباقات المتاحة).
- **الـ UI:** قم بتلوين حالة الاشتراك بالأخضر إذا كان فعّالاً.""",

    "api/student/subscription/subscribe": """**تفعيل باقة جديدة**
- **ملاحظة للفرونت إند:** السيرفر يتحقق من رصيد الطالب تلقائياً. إذا كان الرصيد غير كافٍ، سيرجع خطأ (مثلاً 400)، ويجب في هذه الحالة إظهار نافذة (BottomSheet) للطالب تطلب منه شحن الرصيد باستخدام كود شحن.""",

    "api/student/subscription/redeem": """**شحن الرصيد (Voucher Redeem)**
- **المدخلات:** `code`.
- **تنبيه:** عند النجاح، يرجى تحديث रصيد الطالب في واجهة المستخدم (User Context المتواجد على مستوى التطبيق Global State).""",

    "api/student/messages": """**الرسائل المباشرة (Chat Conversations)**
- **الاستخدام:** لجلب قائمة المحادثات النشطة. يجب دعم pagination والـ pull-to-refresh.""",
    
    "api/student/messages/{{conversation}}/send": """**إرسال رسالة**
- **المدخلات:** `message` (نص الرسالة), أو `attachment` (ملف، صورة).
- **ملاحظة للفرونت إند:** استخدم Optimistic UI هنا (قم بإضافة الرسالة للشاشة فوراً قبل رد السيرفر ثم حدث حالتها لـ Sent عند استلام الـ 200).""",

    "api/student/inquiries": """**استفسارات الدكاترة (Inquiries)**
- **الاستخدام:** يمكن للطالب طرح سؤال على الدكتور في مادة معينة.
- **ملاحظة:** تأكد من إظهار حالة الرد (معلق "pending"، مُرد عليه "answered").""",

    "api/student/reports/attendance": """**تقرير الحضور والغياب (PDF)**
- **ماذا يرجع؟** يرجع الرابط المباشر للملف (Export URL).
- **ملاحظة شديدة الأهمية للفرونت إند (Authentication in WebViews / Downloads):**
  الروابط المرجعة للـ PDF تتطلب "Authentication". إما أن تمرر الـ Token كـ Header في أداة التحميل، أو لو قمت بفتحه في `WebView` يجب أن تمرر له الـ Authorization Headers أو الكوكيز.""",
}

def update_node(items):
    for item in items:
        if "item" in item:
            update_node(item["item"])
        else:
            req = item.get("request", {})
            url_dict = req.get("url", {})
            raw_url = url_dict.get("raw", "")
            
            # Find a matching description based on route pattern
            for path_key, desc in descriptions.items():
                if path_key in raw_url:
                    # Append description, allowing existing ones if any, but replacing empty or default
                    current_desc = req.get("description", "")
                    if current_desc.strip():
                        # Override or append? Let's override since currently they are mostly empty
                        req["description"] = desc
                    else:
                        req["description"] = desc
                    break

update_node(data["item"])

with open(collection_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print("Added frontend documentation and hidden logic descriptions to Postman collection successfully.")
