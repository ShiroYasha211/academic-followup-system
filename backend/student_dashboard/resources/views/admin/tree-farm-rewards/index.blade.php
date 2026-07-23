@extends('layouts.admin')

@section('title', 'إدارة مزرعة الأشجار والجوائز')

@section('content')
<style>
    /* Premium Tree Farm Admin Dashboard Styles */
    .tree-farm-admin-container {
        animation: fadeIn 0.6s ease-out;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .bg-success-gradient {
        background: linear-gradient(135deg, #1b4332 0%, #2d6a4f 100%);
    }

    .header-icon-box {
        width: 56px;
        height: 56px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 8px 16px -4px rgba(45, 106, 79, 0.3);
    }

    .stat-card-premium {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        border: 1px solid rgba(0, 0, 0, 0.03);
    }

    .stat-card-premium:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px -4px rgba(0, 0, 0, 0.06) !important;
    }

    .bg-success-light { background-color: rgba(45, 106, 79, 0.08); }
    .bg-warning-light { background-color: rgba(245, 158, 11, 0.08); }
    .bg-danger-light { background-color: rgba(239, 68, 68, 0.08); }
    .bg-primary-light { background-color: rgba(59, 130, 246, 0.08); }

    .badge-soft-success {
        background-color: rgba(22, 163, 74, 0.08);
        color: #16a34a;
        border: 1px solid rgba(22, 163, 74, 0.15);
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
    }

    .badge-soft-danger {
        background-color: rgba(220, 38, 38, 0.08);
        color: #dc2626;
        border: 1px solid rgba(220, 38, 38, 0.15);
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
    }

    .badge-soft-warning {
        background-color: rgba(217, 119, 6, 0.08);
        color: #d97706;
        border: 1px solid rgba(217, 119, 6, 0.15);
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
    }

    .badge-soft-info {
        background-color: rgba(2, 132, 199, 0.08);
        color: #0284c7;
        border: 1px solid rgba(2, 132, 199, 0.15);
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
    }

    .badge-soft-secondary {
        background-color: rgba(107, 114, 128, 0.08);
        color: #4b5563;
        border: 1px solid rgba(107, 114, 128, 0.15);
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
    }

    .table-hover tbody tr {
        transition: background-color 0.2s ease;
    }

    .table-hover tbody tr:hover {
        background-color: rgba(243, 244, 246, 0.35) !important;
    }

    .btn-premium {
        border-radius: 10px;
        font-weight: 600;
        transition: all 0.2s ease;
    }

    .btn-premium:hover {
        transform: translateY(-1px);
    }

    .border-inline-start-md {
        border-inline-start: 1px solid rgba(0, 0, 0, 0.08) !important;
    }

    .scroll-container {
        scrollbar-width: thin;
        scrollbar-color: #cbd5e1 #f1f1f1;
    }

    .scroll-container::-webkit-scrollbar {
        width: 6px;
    }
    .scroll-container::-webkit-scrollbar-track {
        background: #f1f1f1;
        border-radius: 4px;
    }
    .scroll-container::-webkit-scrollbar-thumb {
        background: #cbd5e1;
        border-radius: 4px;
    }
    .scroll-container::-webkit-scrollbar-thumb:hover {
        background: #94a3b8;
    }

    .animate-pulse {
        animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
    }

    @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: .5; }
    }

    /* Custom Premium Nav Pills styling */
    .tree-farm-nav-pills .nav-link {
        color: #4b5563;
        font-weight: 700;
        border-radius: 12px;
        padding: 0.8rem 1.5rem;
        transition: all 0.2s ease;
        border: 1px solid transparent;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        background: transparent;
    }

    .tree-farm-nav-pills .nav-link:hover {
        background-color: rgba(45, 106, 79, 0.05);
        color: #2d6a4f;
    }

    .tree-farm-nav-pills .nav-link.active {
        background-color: #2d6a4f !important;
        color: white !important;
        box-shadow: 0 6px 16px -4px rgba(45, 106, 79, 0.3);
    }
</style>

<div class="container-fluid py-4 tree-farm-admin-container" dir="rtl">
    <!-- Page Header -->
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div class="d-flex align-items-center gap-3">
            <div class="header-icon-box bg-success-gradient">
                <i class="fa-solid fa-tree fa-xl text-white"></i>
            </div>
            <div>
                <h1 class="h3 fw-bold mb-1">إدارة مزرعة الأشجار والجوائز</h1>
                <p class="text-muted mb-0">لوحة تحكم المسئول لمتابعة إنجازات تركيز الطلاب واعتماد طلبات استبدال النجوم.</p>
            </div>
        </div>
        <a href="{{ route('admin.dashboard') }}" class="btn btn-light border btn-premium px-4 py-2"><i class="fa-solid fa-arrow-left me-2"></i> العودة للرئيسية</a>
    </div>

    <!-- Alert Feedback -->
    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4 p-3 d-flex align-items-center gap-2" role="alert">
            <i class="fa-solid fa-circle-check text-success fa-lg"></i>
            <div class="fw-bold">{{ session('success') }}</div>
        </div>
    @endif

    @if(session('error'))
        <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4 p-3 d-flex align-items-center gap-2" role="alert">
            <i class="fa-solid fa-circle-exclamation text-danger fa-lg"></i>
            <div class="fw-bold">{{ session('error') }}</div>
        </div>
    @endif

    @if($errors->any())
        <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4 p-3" role="alert">
            <ul class="mb-0 fw-bold">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    @php
        $activeTreeFarmTab = request('tab') === 'public_farm' ? 'public_farm' : 'analytics';
    @endphp

    <!-- Premium Tab Navigation -->
    <ul class="nav nav-pills tree-farm-nav-pills gap-2 mb-4 bg-white p-2 rounded-4 shadow-sm" id="treeFarmTabs" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link {{ $activeTreeFarmTab === 'analytics' ? 'active' : '' }}" id="analytics-tab" data-bs-toggle="tab" data-bs-target="#analytics-pane" type="button" role="tab" aria-controls="analytics-pane" aria-selected="{{ $activeTreeFarmTab === 'analytics' ? 'true' : 'false' }}">
                <i class="fa-solid fa-chart-pie"></i> الرئيسية والتحليلات
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" id="requests-tab" data-bs-toggle="tab" data-bs-target="#requests-pane" type="button" role="tab" aria-controls="requests-pane" aria-selected="false">
                <i class="fa-solid fa-star"></i> طلبات النجوم
                @if($pendingRequests->count() > 0)
                    <span class="badge bg-danger ms-1 animate-pulse">{{ $pendingRequests->count() }}</span>
                @endif
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" id="leaderboard-tab" data-bs-toggle="tab" data-bs-target="#leaderboard-pane" type="button" role="tab" aria-controls="leaderboard-pane" aria-selected="false">
                <i class="fa-solid fa-trophy"></i> المتصدرون وأرصدة الطلاب
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link {{ $activeTreeFarmTab === 'public_farm' ? 'active' : '' }}" id="public-farm-tab" data-bs-toggle="tab" data-bs-target="#public-farm-pane" type="button" role="tab" aria-controls="public-farm-pane" aria-selected="{{ $activeTreeFarmTab === 'public_farm' ? 'true' : 'false' }}">
                <i class="fa-solid fa-earth-americas"></i> المزرعة العامة
                @if(($publicStats['participants'] ?? 0) > 0)
                    <span class="badge bg-success ms-1">{{ number_format($publicStats['participants']) }}</span>
                @endif
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" id="settings-tab" data-bs-toggle="tab" data-bs-target="#settings-pane" type="button" role="tab" aria-controls="settings-pane" aria-selected="false">
                <i class="fa-solid fa-sliders"></i> إعدادات الرقابة وسعر الصرف
            </button>
        </li>
    </ul>

    <!-- Tab Contents -->
    <div class="tab-content" id="treeFarmTabsContent">
        
        <!-- Tab 1: Analytics -->
        <div class="tab-pane fade {{ $activeTreeFarmTab === 'analytics' ? 'show active' : '' }}" id="analytics-pane" role="tabpanel" aria-labelledby="analytics-tab" tabindex="0">
            <!-- Overview Stats Cards -->
            <div class="row g-4 mb-4">
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-4 stat-card-premium">
                        <div class="card-body p-4 d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-value-premium h3 fw-bold text-success mb-1">
                                    @php
                                        $totalSeconds = \App\Models\Student\TreeFarmProfile::sum('total_focus_seconds');
                                        $totalHours = floor($totalSeconds / 3600);
                                    @endphp
                                    {{ number_format($totalHours) }} ساعة
                                </div>
                                <div class="text-muted small fw-bold">إجمالي ساعات التركيز</div>
                            </div>
                            <div class="header-icon-box bg-success-light">
                                <i class="fa-solid fa-clock-rotate-left fa-lg text-success"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-4 stat-card-premium">
                        <div class="card-body p-4 d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-value-premium h3 fw-bold text-warning mb-1">
                                    {{ number_format(\App\Models\Student\TreeFarmProfile::sum('coins_balance')) }}
                                </div>
                                <div class="text-muted small fw-bold">عملات الطلاب المتبقية</div>
                            </div>
                            <div class="header-icon-box bg-warning-light">
                                <i class="fa-solid fa-coins fa-lg text-warning"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-4 stat-card-premium">
                        <div class="card-body p-4 d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-value-premium h3 fw-bold text-danger mb-1">
                                    {{ $pendingRequests->count() }}
                                </div>
                                <div class="text-muted small fw-bold">طلبات نجوم معلقة</div>
                            </div>
                            <div class="header-icon-box bg-danger-light">
                                <i class="fa-solid fa-star fa-lg text-danger"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-4 stat-card-premium">
                        <div class="card-body p-4 d-flex align-items-center justify-content-between">
                            <div>
                                <div class="stat-value-premium h3 fw-bold text-primary mb-1">
                                    {{ \App\Models\Student\TreeFarmProfile::count() }}
                                </div>
                                <div class="text-muted small fw-bold">الطلاب النشطين بالمزرعة</div>
                            </div>
                            <div class="header-icon-box bg-primary-light">
                                <i class="fa-solid fa-user-graduate fa-lg text-primary"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Subject breakdown and success rate circular progress -->
            <div class="row g-4 mb-4">
                <!-- Subject Focus Insights & Withered tree analytics -->
                <div class="col-lg-8">
                    <div class="card shadow-sm border-0 h-100 rounded-4">
                        <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                            <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-chart-pie me-2"></i> تحليلات التركيز والمواد الدراسية</h2>
                            <span class="badge badge-soft-success">تحديث مباشر</span>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <!-- Withered Tree Analytics (Success Rate) -->
                                <div class="col-md-5 mb-4 mb-md-0">
                                    <h5 class="fw-bold mb-3 small text-muted text-uppercase">معدل نجاح الجلسات (الأشجار الجافة)</h5>
                                    
                                    <div class="d-flex flex-column align-items-center justify-content-center h-100 py-3">
                                        <!-- Circular progress / visual representation -->
                                        <div class="position-relative mb-3 d-flex align-items-center justify-content-center" style="width: 140px; height: 140px;">
                                            <svg width="140" height="140" viewBox="0 0 140 140" style="transform: rotate(-90deg);">
                                                <circle cx="70" cy="70" r="60" fill="transparent" stroke="#f3f4f6" stroke-width="12"></circle>
                                                <circle cx="70" cy="70" r="60" fill="transparent" stroke="#2d6a4f" stroke-width="12" 
                                                        stroke-dasharray="377" stroke-dashoffset="{{ 377 - (377 * $successRate) / 100 }}"
                                                        stroke-linecap="round" style="transition: stroke-dashoffset 1s ease-out;"></circle>
                                            </svg>
                                            <div class="position-absolute text-center">
                                                <div class="h3 fw-bold mb-0 text-success">{{ $successRate }}%</div>
                                                <span class="text-muted small" style="font-size: 0.75rem;">نسبة النجاح</span>
                                            </div>
                                        </div>
                                        
                                        <div class="w-100 px-3 mt-2">
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <span class="small text-muted"><i class="fa-solid fa-tree text-success me-1"></i> جلسات ناجحة:</span>
                                                <span class="fw-bold text-success">{{ $successSessions }}</span>
                                            </div>
                                            <div class="d-flex justify-content-between align-items-center">
                                                <span class="small text-muted"><i class="fa-solid fa-fire text-danger me-1"></i> جلسات جافة (فشل):</span>
                                                <span class="fw-bold text-danger">{{ $failedSessions }} ({{ $failRate }}%)</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Subject Focus Breakdown -->
                                <div class="col-md-7 border-inline-start-md">
                                    <h5 class="fw-bold mb-3 small text-muted text-uppercase">توزيع وقت التركيز حسب المواد الدراسية</h5>
                                    @if(count($subjectInsights) > 0)
                                        <div class="scroll-container" style="max-height: 250px; overflow-y: auto; padding-inline-start: 4px;">
                                            <table class="table table-sm align-middle table-hover mb-0">
                                                <thead class="table-light sticky-top">
                                                    <tr>
                                                        <th>المادة الدراسية</th>
                                                        <th class="text-center">الجلسات</th>
                                                        <th class="text-start">مدة التركيز</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    @foreach($subjectInsights as $insight)
                                                        @php
                                                            $subHours = floor($insight->total_focused_seconds / 3600);
                                                            $subMinutes = floor(($insight->total_focused_seconds % 3600) / 60);
                                                        @endphp
                                                        <tr>
                                                            <td>
                                                                <span class="fw-bold text-dark">{{ $insight->subject_name }}</span>
                                                            </td>
                                                            <td class="text-center">
                                                                <span class="badge badge-soft-secondary">{{ $insight->total_sessions }}</span>
                                                            </td>
                                                            <td class="text-start fw-bold text-success">
                                                                @if($subHours > 0)
                                                                    {{ $subHours }} س و {{ $subMinutes }} د
                                                                @else
                                                                    {{ $subMinutes }} د
                                                                @endif
                                                            </td>
                                                        </tr>
                                                    @endforeach
                                                </tbody>
                                            </table>
                                        </div>
                                    @else
                                        <div class="text-center text-muted py-5">
                                            <i class="fa-solid fa-chart-bar fa-2xl text-light mb-3 d-block"></i>
                                            لا توجد بيانات جلسات تركيز مصنفة حسب المواد بعد.
                                        </div>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Early Warning Card (At-Risk Students) -->
                <div class="col-lg-4">
                    <div class="card shadow-sm border-0 h-100 rounded-4 border-start border-danger border-4">
                        <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                            <h2 class="h5 fw-bold mb-0 text-danger"><i class="fa-solid fa-triangle-exclamation me-2"></i> نظام الإنذار المبكر (التعثر الدراسي)</h2>
                            <span class="badge badge-soft-danger animate-pulse">تنبيه حرج</span>
                        </div>
                        <div class="card-body d-flex flex-column">
                            <p class="text-muted small mb-3">الطلاب الذين واجهوا نسبة جفاف/تشتت بلغت 50% أو أكثر من إجمالي 3 جلسات على الأقل. يوصى بتواصل المرشد الأكاديمي معهم لمساعدتهم.</p>
                            
                            <div class="flex-grow-1 scroll-container" style="max-height: 250px; overflow-y: auto; padding-inline-start: 4px;">
                                @forelse($atRiskStudents as $atRisk)
                                    <div class="p-3 mb-3 bg-light rounded-3 d-flex justify-content-between align-items-center border-start border-danger border-3">
                                        <div style="min-width: 0; flex: 1;" class="pe-2">
                                            <div class="fw-bold text-dark text-truncate">{{ $atRisk->user?->name ?? 'طالب محذوف' }}</div>
                                            <div class="small text-muted text-truncate">رقم القيد: {{ $atRisk->user?->student_number ?? '-' }}</div>
                                            <div class="small text-muted" style="font-size: 0.8rem;">إجمالي الجلسات: {{ $atRisk->total_sessions }} | الجافة: {{ $atRisk->burned_sessions }}</div>
                                        </div>
                                        <div class="text-end" style="flex-shrink: 0;">
                                            <span class="badge badge-soft-danger mb-2 d-block text-center">{{ $atRisk->failure_rate }}% جفاف 🥀</span>
                                            <a href="mailto:{{ $atRisk->user?->email }}?subject=متابعة أكاديمية - منصة معين&body=مرحباً {{ $atRisk->user?->name }}،%0d%0aنود التواصل معك بخصوص تقدمك الدراسي..." class="btn btn-sm btn-outline-danger btn-premium py-1 px-3.5 w-100" style="font-size: 0.8rem;">
                                                <i class="fa-solid fa-envelope me-1"></i> تواصل
                                            </a>
                                        </div>
                                    </div>
                                @empty
                                    <div class="text-center text-muted py-5 my-auto">
                                        <i class="fa-solid fa-circle-check fa-2xl text-success mb-3 d-block"></i>
                                        لا يوجد طلاب يواجهون تعثراً دراسياً حالياً. كل الطلاب ملتزمون!
                                    </div>
                                @endforelse
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab 2: Star Exchange Requests -->
        <div class="tab-pane fade" id="requests-pane" role="tabpanel" aria-labelledby="requests-tab" tabindex="0">
            <!-- Star Requests Pending Review -->
            <div class="card shadow-sm border-0 mb-4 rounded-4">
                <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                    <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-square-poll-horizontal me-2"></i> طلبات بانتظار المراجعة</h2>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table align-middle mb-0 table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th class="ps-4">الطالب</th>
                                    <th>رقم القيد</th>
                                    <th>العملات المستبدلة</th>
                                    <th>النجوم المستحقة</th>
                                    <th>تاريخ الطلب</th>
                                    <th style="min-width: 320px;" class="pe-4">الإجراء والاعتماد</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($pendingRequests as $request)
                                    <tr>
                                        <td class="ps-4">
                                            <div class="fw-bold text-dark">{{ $request->user?->name ?? 'طالب محذوف' }}</div>
                                            <div class="small text-muted">{{ $request->user?->email }}</div>
                                        </td>
                                        <td>{{ $request->user?->student_number ?? '-' }}</td>
                                        <td><span class="badge badge-soft-warning"><i class="fa-solid fa-coins me-1"></i> {{ number_format($request->coins_amount) }} عملة</span></td>
                                        <td><span class="badge badge-soft-success"><i class="fa-solid fa-star me-1"></i> {{ number_format($request->stars_amount) }} نجوم</span></td>
                                        <td class="text-muted small">{{ optional($request->created_at)->format('Y-m-d H:i') }}</td>
                                        <td class="pe-4">
                                            <div class="d-flex gap-2 align-items-center">
                                                <form action="{{ route('admin.tree-farm-rewards.approve', $request) }}" method="POST" onsubmit="return confirm('اعتماد هذا الطلب وتحويل العملات إلى نجوم؟')" class="mb-0">
                                                    @csrf
                                                    <button class="btn btn-sm btn-success btn-premium px-3 py-1.5" type="submit"><i class="fa-solid fa-check me-1"></i> اعتماد</button>
                                                </form>
                                                <form action="{{ route('admin.tree-farm-rewards.reject', $request) }}" method="POST" class="d-flex mb-0">
                                                    @csrf
                                                    <div class="input-group input-group-sm">
                                                        <input type="text" name="rejection_reason" class="form-control form-control-sm" placeholder="سبب الرفض (اختياري)">
                                                        <button class="btn btn-outline-danger btn-premium" type="submit"><i class="fa-solid fa-xmark me-1"></i> رفض</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" class="text-center text-muted py-5"><i class="fa-solid fa-circle-check fa-2xl text-success mb-3 d-block"></i> لا توجد طلبات مكافآت بانتظار المراجعة حالياً.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                @if($pendingRequests->hasPages())
                    <div class="card-footer bg-white border-0 py-3">
                        {{ $pendingRequests->appends(['sort_by' => $sortBy])->links() }}
                    </div>
                @endif
            </div>

            <!-- Recent Actions Log -->
            <div class="card shadow-sm border-0 rounded-4">
                <div class="card-header bg-white border-0 py-3">
                    <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-history me-2"></i> آخر الطلبات التي تمت مراجعتها</h2>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table align-middle mb-0 table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th class="ps-4">الطالب</th>
                                    <th>الحالة</th>
                                    <th>العملات المستبدلة</th>
                                    <th>النجوم الممنوحة</th>
                                    <th>المراجع المسؤول</th>
                                    <th class="pe-4">ملاحظة الرفض</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($recentRequests as $request)
                                    <tr>
                                        <td class="ps-4">{{ $request->user?->name ?? 'طالب محذوف' }}</td>
                                        <td>
                                            @if($request->status === 'approved')
                                                <span class="badge badge-soft-success"><i class="fa-solid fa-circle-check me-1"></i> معتمد</span>
                                            @else
                                                <span class="badge badge-soft-danger"><i class="fa-solid fa-circle-xmark me-1"></i> مرفوض</span>
                                            @endif
                                        </td>
                                        <td><i class="fa-solid fa-coins text-warning me-1"></i> {{ number_format($request->coins_amount) }}</td>
                                        <td><i class="fa-solid fa-star text-success me-1"></i> {{ number_format($request->stars_amount) }}</td>
                                        <td><i class="fa-solid fa-user-shield text-muted me-1"></i> {{ $request->reviewer?->name ?? '-' }}</td>
                                        <td class="text-muted pe-4">{{ $request->rejection_reason ?? '-' }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" class="text-center text-muted py-5">لا توجد مراجعات سابقة للطلبات.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab 3: Leaderboard & Balance Adjustments -->
        <div class="tab-pane fade" id="leaderboard-pane" role="tabpanel" aria-labelledby="leaderboard-tab" tabindex="0">
            <div class="row g-4">
                <!-- Leaderboard Table -->
                <div class="col-lg-8">
                    <div class="card shadow-sm border-0 rounded-4">
                        <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center flex-wrap gap-2">
                            <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-trophy me-2 text-warning"></i> قائمة ترتيب طلاب مزرعة الأشجار</h2>
                            <div class="d-flex gap-2 align-items-center">
                                <span class="small text-muted fw-bold">ترتيب حسب:</span>
                                <a href="{{ route('admin.tree-farm-rewards.index', ['sort_by' => 'focus']) }}" class="btn btn-sm btn-premium {{ $sortBy === 'focus' ? 'btn-success text-white' : 'btn-light border' }}"><i class="fa-solid fa-clock me-1"></i> مدة التركيز</a>
                                <a href="{{ route('admin.tree-farm-rewards.index', ['sort_by' => 'coins']) }}" class="btn btn-sm btn-premium {{ $sortBy === 'coins' ? 'btn-success text-white' : 'btn-light border' }}"><i class="fa-solid fa-coins me-1"></i> رصيد العملات</a>
                            </div>
                        </div>
                        <div class="card-body p-0">
                            <div class="table-responsive">
                                <table class="table align-middle mb-0 table-hover">
                                    <thead class="table-light">
                                        <tr>
                                            <th style="width: 100px;" class="text-center">الترتيب</th>
                                            <th>الطالب (الاسم الحقيقي)</th>
                                            <th>الاسم المستعار</th>
                                            <th>رقم القيد</th>
                                            <th class="text-center">إجمالي التركيز</th>
                                            <th class="text-center">العملات المتبقية</th>
                                            <th class="text-center">ظهور لوحة المتصدرين</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($students as $index => $profile)
                                            @php
                                                $rank = $students->firstItem() + $index;
                                            @endphp
                                            <tr>
                                                <td class="text-center">
                                                    @if($rank === 1)
                                                        <span class="badge bg-warning text-dark px-3 py-2 fw-bold" style="font-size: 0.9rem;">🥇 1</span>
                                                    @elseif($rank === 2)
                                                        <span class="badge bg-secondary text-white px-3 py-2 fw-bold" style="font-size: 0.85rem;">🥈 2</span>
                                                    @elseif($rank === 3)
                                                        <span class="badge px-3 py-2 fw-bold text-white" style="font-size: 0.8rem; background-color: #cd7f32 !important;">🥉 3</span>
                                                    @else
                                                        <span class="fw-bold text-muted">{{ $rank }}</span>
                                                    @endif
                                                </td>
                                                <td>
                                                    <div class="fw-bold text-dark">{{ $profile->user?->name ?? 'طالب محذوف' }}</div>
                                                    <div class="small text-muted">{{ $profile->user?->email }}</div>
                                                </td>
                                                <td>
                                                    @if($profile->use_alias && $profile->public_name)
                                                        <span class="badge badge-soft-info">{{ $profile->public_name }}</span>
                                                    @else
                                                        <span class="text-muted small"><i class="fa-solid fa-user-lock me-1"></i> الاسم الحقيقي</span>
                                                    @endif
                                                </td>
                                                <td>{{ $profile->user?->student_number ?? '-' }}</td>
                                                <td class="text-center fw-bold text-success">
                                                    @php
                                                        $hours = floor($profile->total_focus_seconds / 3600);
                                                        $minutes = floor(($profile->total_focus_seconds % 3600) / 60);
                                                    @endphp
                                                    <i class="fa-regular fa-clock me-1 text-success"></i>
                                                    @if($hours > 0)
                                                        {{ $hours }} س و {{ $minutes }} د
                                                    @else
                                                        {{ $minutes }} د
                                                    @endif
                                                </td>
                                                <td class="text-center">
                                                    <span class="badge badge-soft-warning px-2.5 py-2"><i class="fa-solid fa-coins me-1"></i> {{ number_format($profile->coins_balance) }}</span>
                                                </td>
                                                <td class="text-center">
                                                    @if($profile->is_public)
                                                        <span class="badge badge-soft-success">مرئي للجميع</span>
                                                    @else
                                                        <span class="badge badge-soft-secondary">حساب خاص</span>
                                                    @endif
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="7" class="text-center text-muted py-5">لا توجد بيانات طلاب مشاركين في المزرعة بعد.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                        @if($students->hasPages())
                            <div class="card-footer bg-white border-0 py-3">
                                {{ $students->appends(['sort_by' => $sortBy])->links() }}
                            </div>
                        @endif
                    </div>
                </div>

                <!-- Manual Wallet Adjustment Tool -->
                <div class="col-lg-4">
                    <div class="card shadow-sm border-0 rounded-4">
                        <div class="card-header bg-white border-0 py-3">
                            <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-user-pen me-2"></i> التعديل اليدوي للأرصدة (عملات / نجوم)</h2>
                        </div>
                        <div class="card-body">
                            <form action="{{ route('admin.tree-farm-rewards.adjust-balance') }}" method="POST" onsubmit="return confirm('هل أنت متأكد من رغبتك في تعديل رصيد الطالب المحدد؟')">
                                @csrf
                                <div class="mb-3">
                                    <label for="user_id" class="form-label fw-bold small text-muted">اختر الطالب</label>
                                    <select name="user_id" id="user_id" class="form-select" required>
                                        <option value="">-- اختر الطالب المعني --</option>
                                        @foreach($allTreeFarmStudents as $std)
                                            <option value="{{ $std->id }}">{{ $std->name }} (رقم القيد: {{ $std->student_number ?? 'لا يوجد' }})</option>
                                        @endforeach
                                    </select>
                                </div>

                                <div class="row g-2 mb-3">
                                    <div class="col-6">
                                        <label for="adjustment_type" class="form-label fw-bold small text-muted">نوع العملة</label>
                                        <select name="adjustment_type" id="adjustment_type" class="form-select" required>
                                            <option value="coins">عملات المزرعة 🪙</option>
                                            <option value="stars">النجوم الأكاديمية ⭐</option>
                                        </select>
                                    </div>
                                    <div class="col-6">
                                        <label for="action" class="form-label fw-bold small text-muted">الإجراء</label>
                                        <select name="action" id="action" class="form-select" required>
                                            <option value="add">إضافة (منح) ➕</option>
                                            <option value="deduct">خصم (تراجع) ➖</option>
                                        </select>
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label for="amount" class="form-label fw-bold small text-muted">الكمية</label>
                                    <input type="number" name="amount" id="amount" class="form-control" placeholder="أدخل عدد العملات أو النجوم..." min="1" required>
                                </div>

                                <div class="mb-4">
                                    <label for="description" class="form-label fw-bold small text-muted">السبب / الملاحظة (لأغراض التدقيق)</label>
                                    <input type="text" name="description" id="description" class="form-control" placeholder="مثال: الفوز بمسابقة التركيز الأسبوعية، أو تلاعب بالوقت..." required>
                                </div>

                                <button type="submit" class="btn btn-warning btn-premium text-dark w-100 py-2"><i class="fa-solid fa-circle-check me-1"></i> تنفيذ التعديل المالي</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab 4: Control & Moderation Settings -->
        @include('admin.tree-farm-rewards.partials.public-farm')

        <div class="tab-pane fade" id="settings-pane" role="tabpanel" aria-labelledby="settings-tab" tabindex="0">
            <div class="row g-4">
                <!-- Limits & Exchange Rate Card (col-lg-5) -->
                <div class="col-lg-5">
                    <div class="card shadow-sm border-0 rounded-4 h-100">
                        <div class="card-header bg-white border-0 py-3">
                            <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-sliders me-2"></i> إعدادات شروط التبديل والحدود</h2>
                        </div>
                        <div class="card-body">
                            <form action="{{ route('admin.tree-farm-rewards.update-settings') }}" method="POST">
                                @csrf
                                <div class="mb-3">
                                    <label for="tree_farm_exchange_rate" class="form-label fw-bold small text-muted">سعر الصرف (كم عملة تساوي النجمة الواجهة)</label>
                                    <div class="input-group">
                                        <span class="input-group-text bg-light text-muted"><i class="fa-solid fa-coins"></i></span>
                                        <input type="number" name="tree_farm_exchange_rate" id="tree_farm_exchange_rate" class="form-control" value="{{ $exchangeRate }}" min="1" required>
                                        <span class="input-group-text bg-light fw-bold text-success">عملة = 1 نجمة ⭐</span>
                                    </div>
                                    <div class="form-text text-muted small">تحديد عدد العملات التي يحتاج الطالب لجمعها لطلب استبدالها بنجمة واحدة. القيمة الافتراضية هي 25 عملة.</div>
                                </div>

                                <div class="mb-4">
                                    <label for="tree_farm_weekly_star_limit" class="form-label fw-bold small text-muted">الحد الأقصى الأسبوعي لاستبدال النجوم</label>
                                    <div class="input-group">
                                        <span class="input-group-text bg-light text-muted"><i class="fa-solid fa-shield-halved"></i></span>
                                        <input type="number" name="tree_farm_weekly_star_limit" id="tree_farm_weekly_star_limit" class="form-control" value="{{ $weeklyStarLimit }}" min="0" required>
                                        <span class="input-group-text bg-light fw-bold text-danger">نجوم / أسبوع</span>
                                    </div>
                                    <div class="form-text text-muted small">الحد الأقصى للنجوم التي يمكن للطالب طلبها أسبوعياً من المزرعة لمنع الاحتيال والغش (ضع 0 لتعطيل الحد الأسبوعي).</div>
                                </div>

                                <button type="submit" class="btn btn-success btn-premium w-100 py-2"><i class="fa-solid fa-floppy-disk me-1"></i> حفظ إعدادات الرقابة والصرف</button>
                            </form>
                        </div>
                    </div>
                </div>

                <!-- Seeds & Rewards Catalog Card (col-lg-7) -->
                <div class="col-lg-7">
                    <div class="card shadow-sm border-0 rounded-4 h-100">
                        <div class="card-header bg-white border-0 py-3">
                            <h2 class="h5 fw-bold mb-0 text-success"><i class="fa-solid fa-seedling me-2"></i> تعديل كتالوج بذور النباتات وجوائز التركيز</h2>
                        </div>
                        <div class="card-body">
                            <p class="text-muted small mb-3">يمكنك تعديل مدة التركيز المطلوبة لكل نبتة وجائزة العملات المحددة لها. (الأسماء وصور النباتات ثابتة ولا يمكن إضافتها أو حذفها حالياً).</p>
                            
                            <form action="{{ route('admin.tree-farm-rewards.update-catalog') }}" method="POST">
                                @csrf
                                <div class="table-responsive scroll-container" style="max-height: 380px; overflow-y: auto;">
                                    <table class="table table-sm align-middle mb-0 table-hover">
                                        <thead class="table-light sticky-top">
                                            <tr>
                                                <th>نوع النبتة</th>
                                                <th>المدة المطلوبة (دقائق)</th>
                                                <th>العملات الممنوحة</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            @foreach($plantsCatalog as $index => $plant)
                                                <tr>
                                                    <td>
                                                        <div class="d-flex align-items-center gap-2">
                                                            <div class="rounded-circle bg-light d-flex align-items-center justify-content-center" style="width: 32px; height: 32px;">
                                                                @if($plant['code'] === 'grass') 🌿
                                                                @elseif($plant['code'] === 'red_flower') 🌹
                                                                @elseif($plant['code'] === 'blue_flower') 🪻
                                                                @elseif($plant['code'] === 'blue_bud') 🪹
                                                                @elseif($plant['code'] === 'purple_flower') 🌸
                                                                @elseif($plant['code'] === 'pine_small') 🌲
                                                                @elseif($plant['code'] === 'pine_tall') 🌳
                                                                @elseif($plant['code'] === 'orange_tree') 🍊
                                                                @elseif($plant['code'] === 'orange_cypress') 🌴
                                                                @else 🌱 @endif
                                                            </div>
                                                            <div>
                                                                <div class="fw-bold small text-dark">{{ $plant['name'] }}</div>
                                                                <span class="badge bg-light text-muted" style="font-size: 0.65rem;">{{ $plant['rarity'] }}</span>
                                                            </div>
                                                        </div>
                                                        <input type="hidden" name="plants[{{ $index }}][code]" value="{{ $plant['code'] }}">
                                                    </td>
                                                    <td>
                                                        <div class="input-group input-group-sm" style="max-width: 140px;">
                                                            <input type="number" name="plants[{{ $index }}][required_minutes]" class="form-control text-center" value="{{ round($plant['required_seconds'] / 60) }}" min="1" required>
                                                            <span class="input-group-text bg-light small">د</span>
                                                        </div>
                                                    </td>
                                                    <td>
                                                        <div class="input-group input-group-sm" style="max-width: 140px;">
                                                            <input type="number" name="plants[{{ $index }}][coins]" class="form-control text-center text-warning fw-bold" value="{{ $plant['coins'] }}" min="0" required>
                                                            <span class="input-group-text bg-light small"><i class="fa-solid fa-coins text-warning"></i></span>
                                                        </div>
                                                    </td>
                                                </tr>
                                            @endforeach
                                        </tbody>
                                    </table>
                                </div>

                                <button type="submit" class="btn btn-success btn-premium w-100 py-2 mt-4"><i class="fa-solid fa-circle-check me-1"></i> حفظ تعديلات كتالوج البذور</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        // Find if there is an active tab in localStorage
        var activeTab = localStorage.getItem('activeTreeFarmTab');
        
        // Also check if URL contains specific page params to override default tab
        var urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('students_page')) {
            activeTab = '#leaderboard-tab';
        } else if (urlParams.has('pending_page')) {
            activeTab = '#requests-tab';
        }

        if (activeTab) {
            var tabEl = document.querySelector(activeTab);
            if (tabEl) {
                var tab = new bootstrap.Tab(tabEl);
                tab.show();
            }
        }

        // Store active tab on change
        var tabTriggerList = [].slice.call(document.querySelectorAll('#treeFarmTabs button'));
        tabTriggerList.forEach(function(tabTriggerEl) {
            tabTriggerEl.addEventListener('shown.bs.tab', function(event) {
                localStorage.setItem('activeTreeFarmTab', '#' + event.target.id);
            });
        });
    });
</script>
@endsection
