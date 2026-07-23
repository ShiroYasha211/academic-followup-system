<!DOCTYPE html>
<html lang="ar" dir="rtl">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title') - لوحة المندوب</title>
    @if($favicon = \App\Models\Setting::get('app_favicon'))
        <link rel="icon" type="image/x-icon" href="{{ asset('storage/' . $favicon) }}">
    @endif

    <!-- Bootstrap 5 RTL -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.rtl.min.css">

    <!-- Dashboard CSS -->
    <link rel="stylesheet" href="{{ asset('css/dashboard.css') }}">

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- Alpine.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    @stack('styles')

    <style>
        .admin-wrapper {
            display: flex;
            min-height: 100vh;
        }

        .sidebar {
            width: var(--sidebar-width);
            background-color: var(--sidebar-bg);
            color: var(--sidebar-text);
            display: flex;
            flex-direction: column;
            transition: width 0.3s ease, transform 0.3s ease;
            position: fixed;
            height: 100vh;
            z-index: 100;
            overflow-x: hidden;
        }

        .sidebar-brand {
            padding: 1.5rem;
            color: white;
            font-size: 1.2rem;
            font-weight: 700;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            display: flex;
            align-items: center;
            gap: 0.75rem;
            white-space: nowrap;
        }

        .sidebar-nav {
            flex: 1;
            padding: 1rem 0;
            overflow-y: auto;
            overflow-x: hidden;
        }

        .nav-link {
            display: flex;
            align-items: center;
            padding: 0.75rem 1.5rem;
            color: var(--sidebar-text);
            text-decoration: none;
            transition: all 0.2s;
            font-weight: 500;
            gap: 0.75rem;
            white-space: nowrap;
        }

        .nav-link:hover,
        .nav-link.active {
            background-color: var(--sidebar-active-bg);
            color: var(--sidebar-active-text);
            border-right: 3px solid var(--primary-color);
        }

        .nav-group-label {
            padding: 1rem 1.5rem 0.5rem;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: rgba(255, 255, 255, 0.4);
            font-weight: 700;
            white-space: nowrap;
        }

        .main-content {
            flex: 1;
            margin-right: var(--sidebar-width);
            display: flex;
            flex-direction: column;
            background-color: var(--bg-body);
            min-height: 100vh;
            transition: margin-right 0.3s ease;
        }

        .top-header {
            background-color: white;
            padding: 1rem 2rem;
            box-shadow: var(--shadow-sm);
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 90;
        }

        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(100%);
            }

            .sidebar.open {
                transform: translateX(0);
            }

            .main-content {
                margin-right: 0 !important;
            }
        }

        /* Toggle Button Visibility */
        .mobile-toggle {
            display: none;
        }

        .desktop-toggle {
            display: none;
        }

        @media (max-width: 768px) {
            .mobile-toggle {
                display: block;
            }
        }

        @media (min-width: 769px) {
            .desktop-toggle {
                display: block;
            }
        }

        /* Subscription Lock Styles */
        .nav-link.locked {
            opacity: 0.5;
            cursor: not-allowed;
            filter: grayscale(1);
            position: relative;
        }

        .nav-link.locked::after {
            content: '🔒';
            position: absolute;
            left: 1.5rem;
            font-size: 0.8rem;
        }

        .balance-badge {
            background: #f1f5f9;
            padding: 0.5rem 1rem;
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 0.5rem;
            font-weight: 700;
            color: var(--text-primary);
            border: 1px solid #e2e8f0;
            text-decoration: none;
            transition: all 0.2s;
        }

        .balance-badge:hover {
            background: #e2e8f0;
        }

        /* Permission Lock Styles */
        .btn-locked {
            opacity: 0.6 !important;
            cursor: not-allowed !important;
            filter: grayscale(1);
            position: relative;
        }
        
        .btn-locked::after {
            content: '🔒';
            position: absolute;
            top: -8px;
            left: -8px;
            font-size: 0.85rem;
            background: white;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            z-index: 20;
            border: 1px solid #e2e8f0;
        }
    </style>
</head>

<body x-data="{ sidebarOpen: false, sidebarCollapsed: false, showLogoutModal: false }">

    <div class="admin-wrapper">

        <!-- Mobile Sidebar Overlay -->
        <div class="sidebar-overlay" :class="{ 'active': sidebarOpen }" @click="sidebarOpen = false"></div>

        <!-- Sidebar -->
        <aside class="sidebar" :class="{ 'open': sidebarOpen, 'collapsed': sidebarCollapsed }">
            <div class="sidebar-brand">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="8.5" cy="7" r="4"></circle>
                    <polyline points="17 11 19 13 23 9"></polyline>
                </svg>
                <span>لوحة المندوب</span>
            </div>

            <nav class="sidebar-nav">
                <a href="{{ route('delegate.dashboard') }}" class="nav-link {{ request()->routeIs('delegate.dashboard') ? 'active' : '' }}" title="الرئيسية">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="3" width="7" height="7"></rect>
                        <rect x="14" y="3" width="7" height="7"></rect>
                        <rect x="14" y="14" width="7" height="7"></rect>
                        <rect x="3" y="14" width="7" height="7"></rect>
                    </svg>
                    <span>الرئيسية</span>
                </a>

                <a href="{{ route('delegate.subscription.index') }}" class="nav-link {{ request()->routeIs('delegate.subscription.*') ? 'active' : '' }}" title="الاشتراك والرصيد">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
                        <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
                    </svg>
                    <span>الاشتراك والرصيد</span>
                    @if(!Auth::user()->isSubscribed())
                        <span style="background: #ef4444; width: 8px; height: 8px; border-radius: 50%; margin-right: auto;"></span>
                    @endif
                <a href="{{ route('delegate.ledger') }}" class="nav-link {{ request()->routeIs('delegate.ledger') ? 'active' : '' }}" title="كشف الحساب">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
                    </svg>
                    <span>كشف الحساب (مالي)</span>
                </a>

                @if(Auth::user()->hasPermission('generate_cards'))
                <a href="{{ route('delegate.cards.generate.index') }}" class="nav-link {{ request()->routeIs('delegate.cards.generate.*') ? 'active' : '' }}" title="توليد الكروت">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="5" width="20" height="14" rx="2"></rect>
                        <line x1="2" x2="22" y1="10" y2="10"></line>
                        <path d="M7 15h.01"></path>
                        <path d="M11 15h2"></path>
                    </svg>
                    <span>توليد الكروت</span>
                </a>
                @endif

                <div class="nav-group-label" title="إدارة الدفعة">إدارة الدفعة</div>

                <a href="{{ route('delegate.students.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.students.*') ? 'active' : '' }}" title="الطلاب">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="9" cy="7" r="4"></circle>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                    </svg>
                    <span>الطلاب</span>
                </a>

                <a href="{{ route('delegate.subjects.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.subjects.*') ? 'active' : '' }}" title="المواد الدراسية">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    <span>المواد الدراسية</span>
                </a>

                <a href="{{ route('delegate.schedules.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.schedules.*') ? 'active' : '' }}" title="الجدول الدراسي">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                        <line x1="16" y1="2" x2="16" y2="6"></line>
                        <line x1="8" y1="2" x2="8" y2="6"></line>
                        <line x1="3" y1="10" x2="21" y2="10"></line>
                    </svg>
                    <span>الجدول الدراسي</span>
                </a>

                <a href="{{ route('delegate.exams.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.exams.*') ? 'active' : '' }}" title="جداول الاختبارات">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                        <polyline points="10 9 9 9 8 9"></polyline>
                    </svg>
                    <span>جداول الاختبارات</span>
                </a>

                <a href="{{ route('delegate.resources.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.resources.*') ? 'active' : '' }}" title="مصادر المقرر">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-book-open">
                        <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
                        <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
                    </svg>
                    <span>مصادر المقرر</span>
                </a>

                <a href="{{ route('delegate.library.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.library.*') ? 'active' : '' }}" title="المكتبة المشتركة">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
                    </svg>
                    <span>المكتبة المشتركة</span>
                </a>

                <a href="{{ route('delegate.assignments.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.assignments.*') ? 'active' : '' }}" title="التكاليف الدراسية">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                        <polyline points="10 9 9 9 8 9"></polyline>
                    </svg>
                    <span>التكاليف الدراسية</span>
                </a>

                @php
                    $myDelegationsCount = Auth::user()->delegatedGradeCategories()->count();
                @endphp
                @if($myDelegationsCount > 0)
                <a href="{{ route('delegate.authorized-grades.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.authorized-grades.*') ? 'active' : '' }}" title="مهام الرصد المفوضة">
                    <i class="fa-solid fa-file-signature" style="width: 20px; font-size: 1.1rem;"></i>
                    <span>مهام الرصد المفوضة</span>
                    <span style="background: #4f46e5; color: white; font-size: 0.7rem; font-weight: 700; padding: 0.1rem 0.5rem; border-radius: 50px; margin-right: auto;">{{ $myDelegationsCount }}</span>
                </a>
                @endif


                <a href="{{ route('delegate.news.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.news.*') ? 'active' : '' }}" title="المركز الإخباري الرسمي">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M19 20H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h10l4 4v12a2 2 0 0 1-2 2z"></path>
                        <polyline points="14 4 14 8 19 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                        <polyline points="10 9 9 9 8 9"></polyline>
                    </svg>
                    <span>المركز الإخباري</span>
                    @php
                        $delegateUnreadNewsCount = \App\Models\StudentNotification::where('user_id', Auth::id())
                            ->whereIn('type', ['announcement', 'exam', 'assignment', 'poll'])
                            ->whereNull('read_at')
                            ->count();
                    @endphp
                    @if($delegateUnreadNewsCount > 0)
                        <span style="background: #ef4444; color: white; font-size: 0.65rem; font-weight: 800; width: 18px; height: 18px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: auto;">
                            {{ $delegateUnreadNewsCount }}
                        </span>
                    @endif
                </a>

                <a href="{{ route('delegate.announcements.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.announcements.*') ? 'active' : '' }}" title="أخبار الدفعة">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2"></path>
                        <path d="M18 14h-8"></path>
                        <path d="M15 18h-5"></path>
                        <path d="M10 6h8v4h-8V6Z"></path>
                    </svg>
                    <span>أخبار الدفعة</span>
                </a>

                <a href="{{ route('delegate.reminders.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.reminders.*') ? 'active' : '' }}" title="جدولة التذكيرات">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    <span>جدولة التذكيرات</span>
                </a>

                <div class="nav-group-label" title="الحضور والمتابعة">الحضور والمتابعة</div>

                <a href="{{ route('delegate.attendance.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.attendance.*') ? 'active' : '' }}" title="رصد الحضور">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 11 12 14 22 4"></polyline>
                        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
                    </svg>
                    <span>رصد الحضور</span>
                </a>

                <a href="{{ route('delegate.notifications.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.notifications.*') ? 'active' : '' }}" title="تنبيهات الغياب">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                    </svg>
                    <span>تنبيهات الغياب</span>
                </a>

                @if(Auth::user()->isClinicalDelegate())
                <div class="nav-group-label" title="القسم العملي">القسم العملي</div>

                <a href="{{ route('delegate.clinical.delegations.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.clinical.delegations.*') ? 'active' : '' }}" title="تفويض الطلاب">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="8.5" cy="7" r="4"></circle>
                        <line x1="20" y1="8" x2="20" y2="14"></line>
                        <line x1="23" y1="11" x2="17" y2="11"></line>
                    </svg>
                    <span>تفويض الطلاب</span>
                </a>

                <a href="{{ route('delegate.clinical.cases.index') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->is('*/clinical/cases') ? 'active' : '' }}" title="الحالات السريرية">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 12h-4l-3 9L9 3l-3 9H2"></path>
                    </svg>
                    <span>الحالات السريرية</span>
                </a>

                <a href="{{ route('delegate.clinical.cases.pending') }}" class="nav-link {{ !Auth::user()->isSubscribed() ? 'locked' : '' }} {{ request()->routeIs('delegate.clinical.cases.pending') ? 'active' : '' }}" title="مراجعة الحالات">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 20h9"></path>
                        <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path>
                    </svg>
                    <span>مراجعة الحالات</span>
                    @php
                        $pendingCount = \App\Models\Clinical\ClinicalCase::where('approval_status', 'pending')->count();
                    @endphp
                    @if($pendingCount > 0)
                        <span style="background: #ef4444; color: white; border-radius: 50%; width: 18px; height: 18px; display: flex; align-items: center; justify-content: center; font-size: 0.65rem; font-weight: 800; margin-right: auto;">{{ $pendingCount }}</span>
                    @endif
                </a>
                @endif

                <div class="nav-group-label" title="التواصل">التواصل</div>

                <a href="{{ route('delegate.messages.index') }}" class="nav-link {{ request()->routeIs('delegate.messages.*') ? 'active' : '' }}" title="رسائل الطلاب">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                    </svg>
                    <span>رسائل الطلاب</span>
                </a>

                <a href="{{ route('delegate.inquiries.index') }}" class="nav-link {{ request()->routeIs('delegate.inquiries.*') ? 'active' : '' }}" title="استفسارات الدكتور">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                    <span>استفسارات الدكتور</span>
                </a>

                <!-- Doctor Chat -->
                <a href="{{ route('delegate.doctor-chat.index') }}" class="nav-link {{ request()->routeIs('delegate.doctor-chat.*') ? 'active' : '' }}" title="محادثات الدكاترة">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                        <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                    </svg>
                    <span>محادثات الدكاترة</span>
                </a>

                <div class="nav-group-label" title="الحساب">الحساب</div>
                <a href="{{ route('delegate.profile.password') }}" class="nav-link {{ request()->routeIs('delegate.profile.password') ? 'active' : '' }}" title="تغيير كلمة المرور">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                    <span>تغيير كلمة المرور</span>
                </a>

            </nav>
        </aside>

        <!-- Content Area -->
        <main class="main-content" :class="{ 'expanded': sidebarCollapsed }">

            <!-- Header -->
            <header class="top-header">
                <div style="display: flex; align-items: center; gap: 1rem;">
                    <!-- Mobile Sidebar Toggle -->
                    <button @click="sidebarOpen = !sidebarOpen" class="btn mobile-toggle" style="background: none; border: none; font-size: 1.5rem; padding: 0;">
                        ☰
                    </button>
                    <!-- Desktop Collapse Toggle -->
                    <button @click="sidebarCollapsed = !sidebarCollapsed" class="btn desktop-toggle" style="background: none; border: none; cursor: pointer; color: var(--text-secondary); padding: 0;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="3" y1="12" x2="21" y2="12"></line>
                            <line x1="3" y1="6" x2="21" y2="6"></line>
                            <line x1="3" y1="18" x2="21" y2="18"></line>
                        </svg>
                    </button>

                    <h2 class="header-title">@yield('title')</h2>
                </div>

                <!-- User Profile Section -->
                <div class="user-menu" style="display: flex; align-items: center; gap: 1rem;">

                    <a href="{{ route('student.dashboard') }}" class="btn-submit" style="padding: 0.5rem 1rem; font-size: 0.85rem; border-radius: 8px; text-decoration: none; width: auto; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);" title="التبديل لحساب الطالب">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M16 3h5v5"></path>
                            <path d="M4 20L21 3"></path>
                            <path d="M21 16v5h-5"></path>
                            <path d="M15 15l6 6"></path>
                            <path d="M4 4l5 5"></path>
                        </svg>
                        التبديل للطالب
                    </a>

                    <a href="{{ route('delegate.subscription.index') }}" class="balance-badge" title="رصيدك الحالي" style="text-decoration: none; margin-left: 1rem;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary-color)" stroke-width="2">
                            <path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                        </svg>
                        <span>{{ number_format(Auth::user()->balance) }} ريال</span>
                    </a>

                    <div style="width: 1px; height: 24px; background-color: var(--border-color); margin: 0 0.5rem;"></div>


                    <button @click="showLogoutModal = true" class="logout-btn-icon" title="تسجيل الخروج">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                            <polyline points="16 17 21 12 16 7"></polyline>
                            <line x1="21" y1="12" x2="9" y2="12"></line>
                        </svg>
                    </button>

                    <div style="width: 1px; height: 24px; background-color: var(--border-color);"></div>

                    <div class="user-info">
                        <span class="user-name">
                            {{ Auth::user()->name }}
                            @if(Auth::user()->isSubscribed())
                                <span style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: white; padding: 2px 8px; border-radius: 6px; font-size: 0.70rem; font-weight: 800; margin-right: 4px; display: inline-flex; align-items: center;">
                                    مشترك
                                </span>
                            @else
                                <span style="background-color: #94a3b8; color: white; padding: 2px 8px; border-radius: 6px; font-size: 0.70rem; font-weight: 800; margin-right: 4px; display: inline-flex; align-items: center;">
                                    غير مشترك
                                </span>
                            @endif
                        </span>
                        <span class="user-role">مندوب {{ Auth::user()->level->name ?? '' }}</span>
                    </div>

                    <div class="user-avatar">
                        {{ mb_substr(Auth::user()->name, 0, 1) }}
                    </div>
                </div>
            </header>

            <!-- Page Content -->
            <div style="flex: 1; padding: 2rem; overflow-x: auto;">
                @include('partials.alerts')
                @yield('content')
            </div>

            <!-- Footer -->
            <footer style="text-align: center; padding: 1.5rem; color: var(--text-secondary); font-size: 0.85rem; border-top: 1px solid var(--border-color);">
                جميع الحقوق محفوظة &copy; {{ date('Y') }} النظام الأكاديمي
            </footer>

        </main>
    </div>

    <!-- Logout Confirmation Modal -->
    <div
        x-show="showLogoutModal"
        class="modal-overlay"
        style="display: none;"
        x-transition.opacity.duration.300ms>
        <div
            class="modal-container"
            @click.away="showLogoutModal = false">
            <div class="modal-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                    <polyline points="16 17 21 12 16 7"></polyline>
                    <line x1="21" y1="12" x2="9" y2="12"></line>
                </svg>
            </div>

            <h3 class="modal-title">تأكيد تسجيل الخروج</h3>
            <p class="modal-message">هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟</p>

            <div class="modal-actions">
                <button
                    type="button"
                    class="btn btn-secondary"
                    @click="showLogoutModal = false">
                    إلغاء
                </button>

                <form action="{{ route('admin.logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="btn btn-danger">
                        نعم، تسجيل الخروج
                    </button>
                </form>
            </div>
        </div>
    </div>

    @stack('scripts')
    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>
