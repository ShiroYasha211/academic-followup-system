<!DOCTYPE html>
<html lang="ar" dir="rtl">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title') - بوابة أعضاء هيئة التدريس</title>
    @if($favicon = \App\Models\Setting::get('app_favicon'))
        <link rel="icon" type="image/x-icon" href="{{ asset('storage/' . $favicon) }}">
    @endif
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="{{ asset('css/dashboard.css') }}">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    @stack('styles')
    <style>
        .admin-wrapper { display: flex; min-height: 100vh; }
        .sidebar { width: var(--sidebar-width); background-color: var(--sidebar-bg); color: var(--sidebar-text); display: flex; flex-direction: column; transition: width 0.3s ease, transform 0.3s ease; position: fixed; height: 100vh; z-index: 100; overflow-x: hidden; }
        .sidebar-brand { padding: 1.5rem; color: white; font-size: 1.2rem; font-weight: 700; border-bottom: 1px solid rgba(255,255,255,0.1); display: flex; align-items: center; gap: 0.75rem; white-space: nowrap; }
        .sidebar-nav { flex: 1; padding: 1rem 0; overflow-y: auto; overflow-x: hidden; }
        .nav-link { display: flex; align-items: center; padding: 0.75rem 1.5rem; color: var(--sidebar-text); text-decoration: none; transition: all 0.2s; font-weight: 500; gap: 0.75rem; white-space: nowrap; }
        .nav-link:hover, .nav-link.active { background-color: var(--sidebar-active-bg); color: var(--sidebar-active-text); border-right: 3px solid var(--primary-color); }
        .nav-group-label { padding: 1rem 1.5rem 0.5rem; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; color: rgba(255,255,255,0.4); font-weight: 700; white-space: nowrap; }
        .main-content { flex: 1; margin-right: var(--sidebar-width); display: flex; flex-direction: column; background-color: var(--bg-body); min-height: 100vh; transition: margin-right 0.3s ease; }
        .top-header { background-color: white; padding: 1rem 2rem; box-shadow: var(--shadow-sm); display: flex; justify-content: space-between; align-items: center; position: sticky; top: 0; z-index: 90; }
        .mobile-toggle { display: none; }
        .desktop-toggle { display: none; }
        .nav-link.locked { opacity: 0.5; cursor: not-allowed; filter: grayscale(1); position: relative; }
        .nav-link.locked::after { content: '🔒'; position: absolute; left: 1.5rem; font-size: 0.8rem; }
        .balance-badge { background: #f1f5f9; padding: 0.5rem 1rem; border-radius: 12px; display: flex; align-items: center; gap: 0.5rem; font-weight: 700; color: var(--text-primary); border: 1px solid #e2e8f0; text-decoration: none; transition: all 0.2s; }
        .balance-badge:hover { background: #e2e8f0; }
        @media (max-width: 768px) {
            .sidebar { transform: translateX(100%); }
            .sidebar.open { transform: translateX(0); }
            .main-content { margin-right: 0 !important; }
            .mobile-toggle { display: block; }
        }
        @media (min-width: 769px) {
            .desktop-toggle { display: block; }
        }
    </style>
</head>

<body x-data="{ sidebarOpen: false, sidebarCollapsed: false, showLogoutModal: false }">
    <div class="admin-wrapper">
        <div class="sidebar-overlay" :class="{ 'active': sidebarOpen }" @click="sidebarOpen = false"></div>

        <aside class="sidebar" :class="{ 'open': sidebarOpen, 'collapsed': sidebarCollapsed }">
            <div class="sidebar-brand">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 10v6M2 10v6M12 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"></path><path d="M6 15v-2a6 6 0 1 1 12 0v2"></path></svg>
                <span>بوابة هيئة التدريس</span>
            </div>

            <nav class="sidebar-nav">
                <a href="{{ route('doctor.dashboard') }}" class="nav-link {{ request()->routeIs('doctor.dashboard') ? 'active' : '' }}"><span>الرئيسية</span></a>
                <a href="{{ route('doctor.subscription.index') }}" class="nav-link {{ request()->routeIs('doctor.subscription.*') ? 'active' : '' }}"><span>الاشتراك والرصيد</span>@if(!Auth::user()->isSubscribed())<span style="background:#ef4444; width:8px; height:8px; border-radius:50%; margin-right:auto;"></span>@endif</a>
                <a href="{{ route('doctor.ledger') }}" class="nav-link {{ request()->routeIs('doctor.ledger') ? 'active' : '' }}"><span>كشف الحساب (مالي)</span></a>
                @if(Auth::user()->hasPermission('generate_cards'))
                    <a href="{{ route('doctor.cards.generate.index') }}" class="nav-link {{ request()->routeIs('doctor.cards.generate.*') ? 'active' : '' }}"><span>توليد الكروت</span></a>
                @endif

                @if(Auth::user()->canAccessClinicalWorkspace())
                    <div class="nav-group-label">السريري</div>
                    <a href="{{ route('doctor.clinical.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.clinical.*') && !request()->routeIs('doctor.clinical.rare-cases.*') ? 'active' : '' }}"><span>القسم العملي (Clinical)</span></a>
                    <a href="{{ route('doctor.clinical.rare-cases.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.clinical.rare-cases.*') ? 'active' : '' }}"><span>إعلان حالات نادرة</span></a>
                    <a href="{{ route('doctor.clinical.volunteers.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.clinical.volunteers.*') ? 'active' : '' }}"><span>سجل المتطوعين</span></a>
                @endif

                <div class="nav-group-label">الأكاديمية</div>
                <a href="{{ route('doctor.excuses.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.excuses.*') ? 'active' : '' }}"><span>أعذار الغياب</span></a>
                <a href="{{ route('doctor.attendance.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.attendance.*') ? 'active' : '' }}"><span>رصد الحضور</span></a>
                <a href="{{ route('doctor.reports.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.reports.*') ? 'active' : '' }}"><span>التقارير</span></a>
                <a href="{{ route('doctor.assignments.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.assignments.*') ? 'active' : '' }}"><span>التكاليف</span></a>
                <a href="{{ route('doctor.grades.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.grades.*') ? 'active' : '' }}"><span>إدارة الدرجات</span></a>
                <a href="{{ route('doctor.library.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.library.*') ? 'active' : '' }}"><span>المكتبة المشتركة</span></a>

                <div class="nav-group-label">التواصل</div>
                <a href="{{ route('doctor.announcements.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.announcements.*') ? 'active' : '' }}"><span>إعلاناتي</span></a>
                <a href="{{ route('doctor.quizzes.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.quizzes.*') ? 'active' : '' }}"><span>كويزاتي</span></a>
                <a href="{{ route('doctor.stars.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.stars.*') ? 'active' : '' }}"><span>منح النجوم</span></a>
                <a href="{{ route('doctor.inquiries.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.inquiries.*') ? 'active' : '' }}"><span>استفسارات الطلاب</span></a>
                <a href="{{ route('doctor.messages.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.messages.*') ? 'active' : '' }}"><span>محادثات المندوبين</span></a>
                <a href="{{ route('doctor.news.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.news.*') ? 'active' : '' }}"><span>المركز الإخباري</span></a>
                <a href="{{ route('doctor.notifications.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('doctor.notifications.*') ? 'active' : '' }}"><span>الإشعارات</span></a>

                <div class="nav-group-label">الحساب</div>
                <a href="{{ route('doctor.profile.password') }}" class="nav-link {{ request()->routeIs('doctor.profile.password') ? 'active' : '' }}"><span>تغيير كلمة المرور</span></a>
            </nav>
        </aside>

        <main class="main-content" :class="{ 'expanded': sidebarCollapsed }">
            <header class="top-header">
                <div style="display:flex; align-items:center; gap:1rem;">
                    <button @click="sidebarOpen = !sidebarOpen" class="btn mobile-toggle" style="background:none; border:none; font-size:1.5rem; padding:0;">☰</button>
                    <button @click="sidebarCollapsed = !sidebarCollapsed" class="btn desktop-toggle" style="background:none; border:none; cursor:pointer; color:var(--text-secondary); padding:0;">≡</button>
                    <h2 class="header-title">@yield('title')</h2>
                </div>

                <div class="user-menu">
                    @if(Auth::user()->canAccessAdministrativeWorkspace())
                        <a href="{{ route('administrative.dashboard') }}" class="balance-badge" title="لوحة المسؤول الإداري" style="text-decoration:none; margin-left:1rem; background:linear-gradient(135deg, #ede9fe 0%, #ddd6fe 100%); border-color:#c4b5fd;">
                            <span style="color:#6d28d9; font-weight:800;">لوحة المسؤول الإداري</span>
                        </a>
                    @endif
                    <button @click="showLogoutModal = true" class="logout-btn-icon" title="تسجيل الخروج">⎋</button>
                    <a href="{{ route('doctor.subscription.index') }}" class="balance-badge" title="رصيدك الحالي" style="text-decoration:none; margin-left:1rem;"><span>{{ number_format(Auth::user()->balance) }} ريال</span></a>
                    <div style="width:1px; height:24px; background-color:var(--border-color);"></div>
                    <div class="user-info">
                        <span class="user-name">
                            {{ Auth::user()->name }}
                            @if(Auth::user()->isSubscribed())
                                <span style="background:linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color:white; padding:2px 8px; border-radius:6px; font-size:0.70rem; font-weight:800; margin-right:4px; display:inline-flex; align-items:center;">مشترك</span>
                            @else
                                <span style="background-color:#94a3b8; color:white; padding:2px 8px; border-radius:6px; font-size:0.70rem; font-weight:800; margin-right:4px; display:inline-flex; align-items:center;">غير مشترك</span>
                            @endif
                        </span>
                        <span class="user-role">
                            @if(Auth::user()->isDoctorWithAdministrativeAccess())
                                دكتور + مسؤول إداري
                            @elseif(Auth::user()->role->value === 'administrative')
                                مسؤول إداري
                            @else
                                دكتور
                            @endif
                        </span>
                    </div>
                    <div class="user-avatar">{{ mb_substr(Auth::user()->name, 0, 1) }}</div>
                </div>
            </header>

            <div style="flex:1; padding:2rem; overflow-x:auto;">
                @include('partials.alerts')
                @yield('content')
            </div>

            <footer style="text-align:center; padding:1.5rem; color:var(--text-secondary); font-size:0.85rem; border-top:1px solid var(--border-color);">
                جميع الحقوق محفوظة &copy; {{ date('Y') }} النظام الأكاديمي
            </footer>
        </main>
    </div>

    <div x-show="showLogoutModal" class="modal-overlay" style="display:none;" x-transition.opacity.duration.300ms>
        <div class="modal-container" @click.away="showLogoutModal = false">
            <div class="modal-icon">⎋</div>
            <h3 class="modal-title">تأكيد تسجيل الخروج</h3>
            <p class="modal-message">هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟</p>
            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" @click="showLogoutModal = false">إلغاء</button>
                <form action="{{ route('admin.logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="btn btn-danger">نعم، تسجيل الخروج</button>
                </form>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    @stack('scripts')
</body>

</html>
