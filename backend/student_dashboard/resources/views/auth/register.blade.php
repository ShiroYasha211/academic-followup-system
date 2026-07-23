<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>إنشاء حساب جديد - المنصة الأكاديمية الشاملة</title>
    @if($favicon = \App\Models\Setting::get('app_favicon'))
        <link rel="icon" type="image/x-icon" href="{{ asset('storage/' . $favicon) }}">
    @endif
    <link rel="stylesheet" href="{{ asset('css/bootstrap.rtl.min.css') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
    <script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.x.x/dist/cdn.min.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <style>
        :root { --primary-gradient: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); --secondary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%); --glass-bg: rgba(255,255,255,.12); --border-glass: rgba(255,255,255,.25); --card-shadow: 0 25px 50px -12px rgba(0,0,0,.15); }
        body { font-family:'Tajawal',sans-serif; background:var(--secondary-gradient); min-height:100vh; display:flex; align-items:center; justify-content:center; margin:0; padding:40px 0; overflow-x:hidden; }
        @keyframes fadeInUp { from { opacity:0; transform:translateY(30px); } to { opacity:1; transform:translateY(0); } }
        @keyframes fadeInRight { from { opacity:0; transform:translateX(30px); } to { opacity:1; transform:translateX(0); } }
        .animate-up { animation: fadeInUp .8s ease-out both; } .animate-up-delay-1 { animation: fadeInUp .8s ease-out .2s both; } .animate-up-delay-2 { animation: fadeInUp .8s ease-out .4s both; }
        .register-wrapper { width:100%; max-width:1150px; padding:20px; } .login-card { background:#fff; border-radius:30px; overflow:hidden; box-shadow:var(--card-shadow); border:none; }
        .login-visual { background:var(--primary-gradient); padding:3rem; display:flex; flex-direction:column; justify-content:center; align-items:center; position:relative; overflow:hidden; color:#fff; text-align:center; }
        .login-visual::before { content:''; position:absolute; width:400px; height:400px; background:rgba(255,255,255,.1); border-radius:50%; top:-150px; right:-150px; }
        .glass-panel { background:var(--glass-bg); backdrop-filter:blur(15px); -webkit-backdrop-filter:blur(15px); border:1px solid var(--border-glass); border-radius:30px; padding:2.5rem; z-index:1; width:100%; max-width:500px; box-shadow:0 15px 35px rgba(0,0,0,.1); animation: fadeInRight .8s ease-out both; }
        .brand-icon { width:70px; height:70px; background:var(--primary-gradient); border-radius:20px; display:flex; align-items:center; justify-content:center; margin:0 auto 1.5rem; box-shadow:0 10px 25px -5px rgba(79,70,229,.4); color:#fff; }
        .brand-title { font-size:1.6rem; font-weight:800; color:#1e293b; margin-bottom:.5rem; letter-spacing:-.5px; }
        .role-card { border:2px solid #e2e8f0; border-radius:20px; padding:1.25rem; text-align:center; cursor:pointer; transition:all .3s ease; background:#fff; height:100%; display:flex; flex-direction:column; justify-content:center; align-items:center; }
        .role-card:hover { border-color:#4f46e5; transform:translateY(-5px); box-shadow:0 10px 20px -5px rgba(79,70,229,.15); }
        .role-card.selected { border-color:#4f46e5; background:#f5f3ff; position:relative; }
        .role-card.selected::after { content:'\f058'; font-family:'Font Awesome 6 Free'; font-weight:900; position:absolute; top:-10px; right:-10px; background:#fff; color:#4f46e5; font-size:1.4rem; border-radius:50%; line-height:1; box-shadow:0 4px 10px rgba(79,70,229,.2); }
        .form-label { font-weight:700; color:#475569; margin-bottom:.6rem; font-size:.85rem; text-transform:uppercase; letter-spacing:.5px; }
        .form-control,.form-select { border:2px solid #e2e8f0; border-radius:14px !important; padding:.85rem 1.2rem; transition:all .3s ease; background:#f8fafc; color:#1e293b; font-weight:500; }
        .form-control:focus,.form-select:focus { border-color:#4f46e5; box-shadow:0 0 0 4px rgba(79,70,229,.1); background:#fff; outline:none; }
        .input-group { border:2px solid #e2e8f0; border-radius:14px !important; overflow:hidden; background:#f8fafc; }
        .input-group .form-control { border:none !important; background:transparent !important; }
        .input-group-text { background-color:transparent; border:none; color:#94a3b8; padding-right:1.2rem; }
        .btn-submit { background:var(--primary-gradient); border:none; border-radius:16px; padding:1rem; font-size:1.1rem; font-weight:800; color:#fff; transition:all .3s ease; box-shadow:0 8px 20px -5px rgba(79,70,229,.4); }
        .btn-submit:hover { transform:translateY(-3px); color:#fff; }
        @media (max-width:991.98px) { .login-visual { display:none; } .login-card { max-width:800px; margin:0 auto; border-radius:30px; } }
    </style>
    <script>
        document.addEventListener('alpine:init', () => {
            Alpine.data('registerData', () => ({
                role: '{{ old('role', 'student') }}',
                gender: '{{ old('gender') }}',
                university_id: '{{ old('university_id') }}',
                college_id: '{{ old('college_id') }}',
                major_id: '{{ old('major_id') }}',
                level_id: '{{ old('level_id') }}',
                allColleges: @json($colleges),
                allMajors: @json($majors),
                allLevels: @json($levels),
                showPassword: false,
                showPasswordConfirm: false,
                get filteredColleges() { if (!this.university_id) return []; return this.allColleges.filter(c => c.university_id == this.university_id); },
                get filteredMajors() { if (!this.college_id) return []; return this.allMajors.filter(m => m.college_id == this.college_id); },
                get filteredLevels() { if (!this.major_id) return []; return this.allLevels.filter(l => l.major_id == this.major_id); },
                universityChanged() { this.college_id = ''; this.major_id = ''; this.level_id = ''; },
                collegeChanged() { this.major_id = ''; this.level_id = ''; },
                majorChanged() { this.level_id = ''; }
            }))
        })
    </script>
</head>
<body>
    <div class="register-wrapper" x-data="registerData">
        <div class="card login-card animate-up">
            <div class="row g-0">
                <div class="col-lg-7 p-4 p-md-5">
                    <div class="text-center mb-5 animate-up-delay-1">
                        <div class="brand-icon"><i class="fas fa-user-plus fa-lg"></i></div>
                        <h1 class="brand-title">إنشاء حساب جديد</h1>
                        <p class="text-muted fw-500">انضم إلى مجتمعنا الأكاديمي اليوم</p>
                    </div>
                    @if($errors->any())
                        <div class="alert alert-danger alert-dismissible fade show rounded-4 border-0 shadow-sm mb-4 animate-up-delay-2" role="alert">
                            <div class="fw-bold mb-1 small"><i class="fas fa-exclamation-triangle me-2"></i> يرجى تصحيح الأخطاء التالية:</div>
                            <ul class="mb-0 small ps-3">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    @endif
                    <form action="{{ route('admin.register') }}" method="POST" class="animate-up-delay-2">
                        @csrf
                        <input type="hidden" name="role" x-model="role">
                        <div class="mb-5">
                            <label class="form-label d-block text-center mb-4 fw-800 text-primary small opacity-75">اختر نوع الحساب</label>
                            <div class="row g-3 justify-content-center">
                                <div class="col-6 col-md-4"><div class="role-card" :class="role === 'student' ? 'selected' : ''" @click="role = 'student'"><div class="fs-2 mb-2"><i class="fas fa-user-graduate"></i></div><div class="fw-800 small text-nowrap">طالب</div></div></div>
                                <div class="col-6 col-md-4"><div class="role-card" :class="role === 'delegate' ? 'selected' : ''" @click="role = 'delegate'"><div class="fs-2 mb-2"><i class="fas fa-star"></i></div><div class="fw-800 small text-nowrap">مندوب</div></div></div>
                                <div class="col-6 col-md-4"><div class="role-card" :class="role === 'doctor' ? 'selected' : ''" @click="role = 'doctor'"><div class="fs-2 mb-2"><i class="fas fa-chalkboard-teacher"></i></div><div class="fw-800 small text-nowrap">عضو هيئة تدريس</div></div></div>
                            </div>
                        </div>
                        <div class="row g-3 mb-4">
                            <div class="col-12"><label for="name" class="form-label">الاسم الكامل (الرباعي)</label><input type="text" id="name" name="name" class="form-control" value="{{ old('name') }}" required></div>
                            <div class="col-12"><label for="email" class="form-label">البريد الإلكتروني</label><input type="email" id="email" name="email" class="form-control" placeholder="name@example.com" value="{{ old('email') }}" required></div>
                            <div class="col-md-6"><label for="password" class="form-label">كلمة المرور</label><div class="input-group"><input :type="showPassword ? 'text' : 'password'" id="password" name="password" class="form-control" required minlength="8"><span class="input-group-text"><i class="fas" :class="showPassword ? 'fa-eye-slash' : 'fa-eye'" @click="showPassword = !showPassword" style="cursor:pointer;"></i></span></div></div>
                            <div class="col-md-6"><label for="password_confirmation" class="form-label">تأكيد كلمة المرور</label><div class="input-group"><input :type="showPasswordConfirm ? 'text' : 'password'" id="password_confirmation" name="password_confirmation" class="form-control" required minlength="8"><span class="input-group-text"><i class="fas" :class="showPasswordConfirm ? 'fa-eye-slash' : 'fa-eye'" @click="showPasswordConfirm = !showPasswordConfirm" style="cursor:pointer;"></i></span></div></div>
                        </div>
                        <div x-show="role !== ''" x-collapse class="p-4 rounded-5 bg-light mb-4 border border-dashed border-2">
                            <h6 class="fw-800 mb-4 text-primary text-center"><i class="fas fa-university me-2"></i><span x-text="role === 'doctor' ? 'التبعية الأكاديمية' : 'البيانات الأكاديمية'"></span></h6>
                            <div class="row g-3">
                                <div class="col-12" x-show="role === 'student' || role === 'delegate'" x-collapse><label for="student_number" class="form-label">الرقم الجامعي / رقم القيد</label><input type="text" id="student_number" name="student_number" class="form-control" value="{{ old('student_number') }}" :required="role === 'student' || role === 'delegate'"></div>
                                <div class="col-md-6" x-show="role === 'student' || role === 'delegate'" x-collapse><label for="gender" class="form-label">الجنس</label><select id="gender" name="gender" class="form-select" x-model="gender" :required="role === 'student' || role === 'delegate'"><option value="">اختر الجنس</option><option value="male">ذكر</option><option value="female">أنثى</option></select></div>
                                <div class="col-md-6"><label for="university_id" class="form-label">الجامعة</label><select id="university_id" name="university_id" class="form-select" x-model="university_id" @change="universityChanged()" :required="role === 'student' || role === 'delegate' || role === 'doctor'"><option value="">اختر الجامعة</option>@foreach($universities as $university)<option value="{{ $university->id }}">{{ $university->name }}</option>@endforeach</select></div>
                                <div class="col-md-6"><label for="college_id" class="form-label">الكلية</label><select id="college_id" name="college_id" class="form-select" x-model="college_id" :disabled="!university_id" @change="collegeChanged()" :required="role === 'student' || role === 'delegate' || role === 'doctor'"><option value="">اختر الجامعة أولاً...</option><template x-for="college in filteredColleges" :key="college.id"><option :value="college.id" x-text="college.name"></option></template></select></div>
                                <div class="col-md-6" x-show="role === 'student' || role === 'delegate'" x-collapse><label for="major_id" class="form-label">التخصص</label><select id="major_id" name="major_id" class="form-select" x-model="major_id" :disabled="!college_id" @change="majorChanged()" :required="role === 'student' || role === 'delegate'"><option value="">اختر الكلية أولاً...</option><template x-for="major in filteredMajors" :key="major.id"><option :value="major.id" x-text="major.name"></option></template></select></div>
                                <div class="col-md-6" x-show="role === 'student' || role === 'delegate'" x-collapse><label for="level_id" class="form-label">المستوى الدراسي</label><select id="level_id" name="level_id" class="form-select" x-model="level_id" :disabled="!major_id" :required="role === 'student' || role === 'delegate'"><option value="">اختر التخصص أولاً...</option><template x-for="level in filteredLevels" :key="level.id"><option :value="level.id" x-text="level.name"></option></template></select></div>
                                <div class="col-12" x-show="role === 'doctor'" x-collapse>
                                    <div class="alert alert-info mb-0">
                                        يتم منح صلاحية المسؤول الإداري لاحقًا من لوحة الإدارة عبر صفحة الدكاترة، وليست نوع حساب مستقل عند التسجيل.
                                    </div>
                                </div>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-submit w-100 mb-4">إرسال طلب التسجيل</button>
                        <div class="text-center"><span class="text-muted small">لديك حساب بالفعل؟</span><a href="{{ route('admin.login') }}" class="text-primary text-decoration-none fw-800 ms-1">تسجيل الدخول</a></div>
                    </form>
                </div>
                <div class="col-lg-5 login-visual">
                    <div class="glass-panel text-center">
                        <h2 class="fw-800 mb-4">حساب واحد لكل مستخدم</h2>
                        <p class="opacity-75 mb-5 lead">إنشاء الحساب يخضع للمراجعة للتأكد من هوية المستخدمين وصلاحياتهم حفاظًا على أمن البيانات الأكاديمية.</p>
                        <div class="text-end small">
                            <div class="d-flex align-items-center mb-4"><div class="bg-white bg-opacity-20 rounded-circle p-2 me-3"><i class="fas fa-check"></i></div><span class="fw-500 lead fs-6">اختر نوع حسابك بدقة</span></div>
                            <div class="d-flex align-items-center mb-4"><div class="bg-white bg-opacity-20 rounded-circle p-2 me-3"><i class="fas fa-check"></i></div><span class="fw-500 lead fs-6">بيانات الطالب مطلوبة كاملة للطالب والمندوب</span></div>
                            <div class="d-flex align-items-center"><div class="bg-white bg-opacity-20 rounded-circle p-2 me-3"><i class="fas fa-check"></i></div><span class="fw-500 lead fs-6">صلاحية المسؤول الإداري تمنح لاحقًا للدكتور من لوحة الإدارة</span></div>
                        </div>
                    </div>
                    <div class="mt-auto text-white opacity-50 small pb-4">المنصة الأكاديمية &copy; {{ date('Y') }}</div>
                </div>
            </div>
        </div>
    </div>
    <script src="{{ asset('js/bootstrap.bundle.min.js') }}"></script>
</body>
</html>
