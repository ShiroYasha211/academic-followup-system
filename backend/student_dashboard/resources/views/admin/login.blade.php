<!DOCTYPE html>
<html lang="ar" dir="rtl">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تسجيل الدخول - المنصة الأكاديمية الشاملة</title>

    @if($favicon = \App\Models\Setting::get('app_favicon'))
        <link rel="icon" type="image/x-icon" href="{{ asset('storage/' . $favicon) }}">
    @endif

    <!-- Bootstrap 5 RTL (Local) -->
    <link rel="stylesheet" href="{{ asset('css/bootstrap.rtl.min.css') }}">
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
            --secondary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --glass-bg: rgba(255, 255, 255, 0.12);
            --border-glass: rgba(255, 255, 255, 0.25);
            --card-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.15);
        }

        body {
            font-family: 'Tajawal', sans-serif;
            background: var(--secondary-gradient);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            overflow-x: hidden;
        }

        /* Entrance Animations */
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @keyframes fadeInRight {
            from { opacity: 0; transform: translateX(30px); }
            to { opacity: 1; transform: translateX(0); }
        }

        .animate-up { animation: fadeInUp 0.8s ease-out both; }
        .animate-up-delay-1 { animation: fadeInUp 0.8s ease-out 0.2s both; }
        .animate-up-delay-2 { animation: fadeInUp 0.8s ease-out 0.4s both; }

        .login-wrapper {
            width: 100%;
            max-width: 1100px;
            padding: 20px;
        }

        .login-card {
            background: #fff;
            border-radius: 30px;
            overflow: hidden;
            box-shadow: var(--card-shadow);
            border: none;
            transition: transform 0.3s ease;
        }

        /* Side Visual */
        .login-visual {
            background: var(--primary-gradient);
            padding: 3rem;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            position: relative;
            overflow: hidden;
            color: white;
            text-align: center;
        }

        .login-visual::before {
            content: '';
            position: absolute;
            width: 400px; height: 400px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            top: -150px; right: -150px;
            animation: pulse 10s infinite alternate;
        }

        @keyframes pulse {
            0% { transform: scale(1); opacity: 0.1; }
            100% { transform: scale(1.2); opacity: 0.2; }
        }

        .glass-panel {
            background: var(--glass-bg);
            backdrop-filter: blur(15px);
            -webkit-backdrop-filter: blur(15px);
            border: 1px solid var(--border-glass);
            border-radius: 30px;
            padding: 3rem;
            z-index: 1;
            width: 100%;
            max-width: 450px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
            animation: fadeInRight 0.8s ease-out both;
        }

        /* Branding */
        .brand-icon {
            width: 75px;
            height: 75px;
            background: var(--primary-gradient);
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            box-shadow: 0 10px 25px -5px rgba(79, 70, 229, 0.4);
            color: white;
            transition: transform 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }

        .brand-icon:hover { transform: rotate(10deg) scale(1.1); }

        .brand-title {
            font-size: 1.6rem;
            font-weight: 800;
            color: #1e293b;
            margin-bottom: 0.5rem;
            letter-spacing: -0.5px;
        }

        /* Form Controls Refresh */
        .form-label {
            font-weight: 700;
            color: #475569;
            margin-bottom: 0.6rem;
            font-size: 0.85rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .input-group {
            background: #f8fafc;
            border-radius: 14px;
            overflow: hidden;
            transition: all 0.3s ease;
            border: 2px solid #e2e8f0;
        }

        .input-group:focus-within {
            border-color: #4f46e5;
            box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1);
            background: #fff;
        }

        .input-group-text {
            background-color: transparent;
            border: none;
            color: #94a3b8;
            padding-right: 1.2rem;
            font-size: 1.1rem;
        }

        .form-control {
            border: none !important;
            background: transparent !important;
            padding: 0.85rem 0.5rem;
            font-weight: 500;
            color: #1e293b;
            border-radius: 0 !important;
        }

        .form-control:focus { box-shadow: none; }

        .password-toggle {
            cursor: pointer;
            color: #94a3b8;
            transition: color 0.3s;
            padding: 0 1rem;
            display: flex;
            align-items: center;
        }

        .password-toggle:hover { color: #4f46e5; }

        /* Buttons Refresh */
        .btn-submit {
            background: var(--primary-gradient);
            border: none;
            border-radius: 14px;
            padding: 1rem;
            font-size: 1.1rem;
            font-weight: 800;
            color: white;
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            box-shadow: 0 8px 20px -5px rgba(79, 70, 229, 0.4);
            position: relative;
            overflow: hidden;
        }

        .btn-submit::after {
            content: '';
            position: absolute;
            top: 0; left: -100%;
            width: 100%; height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
            transition: 0.5s;
        }

        .btn-submit:hover::after { left: 100%; }

        .btn-submit:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 25px -5px rgba(79, 70, 229, 0.5);
            color: white;
        }

        .btn-submit:active { transform: translateY(-1px); }

        /* Slides Refresh */
        .slide {
            display: none;
            animation: slideIn 0.8s ease;
        }
        .slide.active { display: block; }

        @keyframes slideIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }

        .dot {
            width: 10px; height: 10px;
            background: rgba(255, 255, 255, 0.3);
            border-radius: 5px;
            cursor: pointer;
            transition: all 0.3s;
        }
        .dot.active {
            background: white;
            width: 25px;
        }

        @media (max-width: 991.98px) {
            .login-visual { display: none; }
            .login-card { max-width: 500px; margin: 0 auto; border-radius: 30px; }
        }
    </style>
</head>

<body>

    <div class="login-wrapper">
        <div class="card login-card animate-up">
            <div class="row g-0">
                <!-- Form Side -->
                <div class="col-lg-6 p-4 p-md-5">
                    <div class="text-center mb-5 animate-up-delay-1">
                        <div class="brand-icon">
                            <i class="fas fa-graduation-cap fa-2x"></i>
                        </div>
                        <h1 class="brand-title">المنصة الأكاديمية الشاملة</h1>
                        <p class="text-muted fw-500">بوابتك المتكاملة للإدارة والتواصل الأكاديمي</p>
                    </div>

                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible fade show rounded-4 border-0 shadow-sm mb-4 animate-up-delay-2" role="alert">
                            <i class="fas fa-check-circle me-2"></i>
                            {{ session('success') }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    @endif

                    @if($errors->any())
                        <div class="alert alert-danger alert-dismissible fade show rounded-4 border-0 shadow-sm mb-4 animate-up-delay-2" role="alert">
                            <i class="fas fa-exclamation-circle me-2"></i>
                            {{ $errors->first() }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    @endif

                    <form action="{{ route('admin.login') }}" method="POST" id="loginForm" class="animate-up-delay-2">
                        @csrf

                        <div class="mb-4">
                            <label for="email" class="form-label text-primary-gradient">البريد الإلكتروني</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="fas fa-envelope"></i></span>
                                <input type="email" id="email" name="email" class="form-control" placeholder="name@example.com" value="{{ old('email') }}" required autofocus>
                            </div>
                        </div>

                        <div class="mb-4">
                            <label for="password" class="form-label">كلمة المرور</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="fas fa-lock"></i></span>
                                <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" required>
                                <div class="password-toggle" onclick="togglePassword()">
                                    <i class="fas fa-eye" id="eyeIcon"></i>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex align-items-center justify-content-between mb-4 px-1">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" name="remember" id="remember">
                                <label class="form-check-label text-muted small fw-bold" for="remember">تذكرني</label>
                            </div>
                            <div class="small">
                                <a href="{{ route('admin.register') }}" class="text-primary text-decoration-none fw-800">حساب جديد</a>
                                <span class="text-muted mx-2 opacity-50">|</span>
                                <a href="#" onclick="showForgotModal(); return false;" class="text-muted text-decoration-none hover-primary transition-all">نسيت كلمة المرور؟</a>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-submit w-100 mb-3" id="submitBtn">
                            <span class="btn-text">تسجيل الدخول</span>
                            <div class="spinner-border spinner-border-sm text-light d-none ms-2" role="status" id="submitSpinner"></div>
                        </button>
                    </form>

                    <div class="text-center mt-5 text-muted small animate-up-delay-2 opacity-75">
                        جميع الحقوق محفوظة &copy; {{ date('Y') }} المنصة الأكاديمية
                    </div>
                </div>

                <!-- Visual Side -->
                <div class="col-lg-6 login-visual">
                    <div class="glass-panel text-center">
                        <div class="slides-container mb-4">
                            <div class="slide active">
                                <div class="fs-1 mb-3">🎓</div>
                                <h2 class="fw-800 mb-3">المنصة الأكاديمية</h2>
                                <p class="opacity-75 lead px-2">نظام متكامل لإدارة العملية التعليمية من الحضور والتكاليف إلى الدرجات والتواصل</p>
                            </div>
                            <div class="slide">
                                <div class="fs-1 mb-3">📊</div>
                                <h2 class="fw-800 mb-3">التقارير اللحظية</h2>
                                <p class="opacity-75 lead px-2">تتبع دقيق للحضور والغياب، إدارة الدرجات، وتقارير تفصيلية وإحصائيات فورية</p>
                            </div>
                            <div class="slide">
                                <div class="fs-1 mb-3">📝</div>
                                <h2 class="fw-800 mb-3">إدارة التكاليف</h2>
                                <p class="opacity-75 lead px-2">إنشاء التكاليف ومتابعة تسليمات الطلاب مع نظام تقييم ومراجعة متكامل</p>
                            </div>
                        </div>
                        
                        <div class="d-flex justify-content-center gap-2 mt-4">
                            <div class="dot active" onclick="setSlide(0)"></div>
                            <div class="dot" onclick="setSlide(1)"></div>
                            <div class="dot" onclick="setSlide(2)"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Forgot Password Modal -->
    <div class="modal fade" id="forgotModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 rounded-5 shadow-lg">
                <div class="modal-body text-center p-5">
                    <div class="mb-4 text-primary animate-up">
                        <div class="bg-primary bg-opacity-10 d-inline-block p-4 rounded-circle">
                            <i class="fas fa-key fa-3x"></i>
                        </div>
                    </div>
                    <h4 class="fw-800 mb-3">نسيت كلمة المرور؟</h4>
                    <p class="text-muted mb-4 lead">لإعادة ضبط كلمة المرور الخاصة بك، يرجى التواصل مع إدارة النظام أو الدعم الفني وتزويدهم بالبيانات اللازمة للتحقق من هويتك.</p>
                    <button type="button" class="btn btn-primary w-100 rounded-4 py-3 fw-bold shadow-sm" data-bs-dismiss="modal">حسناً، فهمت</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap 5 JS (Local) -->
    <script src="{{ asset('js/bootstrap.bundle.min.js') }}"></script>

    <script>
        // Password Toggle
        function togglePassword() {
            const input = document.getElementById('password');
            const icon = document.getElementById('eyeIcon');
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.replace('fa-eye', 'fa-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.replace('fa-eye-slash', 'fa-eye');
            }
        }

        // Slider Logic
        let currentSlide = 0;
        const slides = document.querySelectorAll('.slide');
        const dots = document.querySelectorAll('.dot');

        function showSlide(index) {
            slides.forEach(s => s.classList.remove('active'));
            dots.forEach(d => d.classList.remove('active'));
            if (slides[index]) slides[index].classList.add('active');
            if (dots[index]) dots[index].classList.add('active');
        }

        let slideInterval = setInterval(() => {
            currentSlide = (currentSlide + 1) % slides.length;
            showSlide(currentSlide);
        }, 5000);

        function setSlide(index) {
            clearInterval(slideInterval);
            currentSlide = index;
            showSlide(currentSlide);
            slideInterval = setInterval(() => {
                currentSlide = (currentSlide + 1) % slides.length;
                showSlide(currentSlide);
            }, 5000);
        }

        // Form Submit
        document.getElementById('loginForm').addEventListener('submit', function() {
            const btn = document.getElementById('submitBtn');
            const text = btn.querySelector('.btn-text');
            const spinner = document.getElementById('submitSpinner');
            btn.classList.add('disabled');
            btn.style.opacity = '0.8';
            text.textContent = 'جاري تسجيل الدخول...';
            spinner.classList.remove('d-none');
        });

        // Forgot Modal
        function showForgotModal() {
            const modal = new bootstrap.Modal(document.getElementById('forgotModal'));
            modal.show();
        }
    </script>
</body>

</html>