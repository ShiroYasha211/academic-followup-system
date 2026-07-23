@extends('layouts.admin')

@section('title', 'إدارة Oneline Shot')

@section('content')
<style>
    :root {
        --glass-bg: rgba(255, 255, 255, 0.9);
        --glass-border: rgba(255, 255, 255, 0.4);
        --premium-shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.05);
        --accent-hsl: 245, 75%, 60%;
    }

    .premium-card {
        background: white;
        border: 1px solid #f1f5f9;
        border-radius: 24px;
        box-shadow: var(--premium-shadow);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        overflow: hidden;
    }

    .premium-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.08);
    }

    .stat-card {
        padding: 1.75rem;
        display: flex;
        align-items: center;
        gap: 1.5rem;
    }

    .icon-box {
        width: 60px;
        height: 60px;
        border-radius: 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        flex-shrink: 0;
    }

    .search-input {
        background: #f8fafc;
        border: 2px solid #f1f5f9;
        border-radius: 16px;
        padding: 0.85rem 1rem 0.85rem 3rem;
        transition: all 0.2s;
        width: 100%;
    }

    .search-input:focus {
        background: white;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1);
        outline: none;
    }

    .filter-select {
        background: #f8fafc;
        border: 2px solid #f1f5f9;
        border-radius: 14px;
        padding: 0.75rem 1rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .filter-select:hover {
        border-color: #e2e8f0;
    }

    .btn-create {
        background: linear-gradient(135deg, var(--primary-color), #6366f1);
        color: white;
        padding: 0.85rem 1.75rem;
        border-radius: 16px;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.75rem;
        box-shadow: 0 10px 20px -5px rgba(79, 70, 229, 0.4);
        transition: all 0.3s;
    }

    .btn-create:hover {
        transform: scale(1.02);
        box-shadow: 0 15px 25px -5px rgba(79, 70, 229, 0.5);
        color: white;
    }

    .data-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .data-table th {
        background: #f8fafc;
        padding: 1.25rem 1.5rem;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        border-bottom: 2px solid #f1f5f9;
    }

    .data-table td {
        padding: 1.25rem 1.5rem;
        vertical-align: middle;
        border-bottom: 1px solid #f8fafc;
    }

    .table-row {
        transition: all 0.2s;
    }

    .table-row:hover {
        background: #fcfdff;
    }

    .action-btn {
        width: 40px;
        height: 40px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
        border: none;
        cursor: pointer;
    }

    .action-btn:hover {
        transform: translateY(-2px);
    }

    .pack-avatar {
        width: 52px;
        height: 52px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        box-shadow: inset 0 0 0 1px rgba(0,0,0,0.05);
    }

    .badge-pill {
        padding: 0.4rem 0.85rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.75rem;
    }
</style>

<div x-data="{ 
    showAssignModal: false, 
    assignPackId: null, 
    assignPackTitle: '',
    searchQuery: '',
    studentFound: null,
    searchError: '',
    isSearching: false,
    
    searchStudent() {
        if(!this.searchQuery) return;
        this.isSearching = true;
        this.studentFound = null;
        this.searchError = '';
        
        fetch('{{ route('admin.flashcards.users.search') }}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ student_number: this.searchQuery })
        })
        .then(res => res.json())
        .then(data => {
            if(data.success) {
                this.studentFound = data.user;
            } else {
                this.searchError = data.message || 'الطالب غير موجود';
            }
        })
        .catch(err => {
            this.searchError = 'حدث خطأ في الاتصال بالسيرفر';
        })
        .finally(() => {
            this.isSearching = false;
        });
    }
}">
    <!-- Page Header -->
    <div class="mb-5 d-flex justify-content-between align-items-center flex-wrap gap-4">
        <div>
            <h1 class="mb-2 d-flex align-items-center gap-3" style="font-weight: 900; letter-spacing: -0.02em;">
                <span class="icon-box" style="background: rgba(var(--accent-hsl), 0.1); color: var(--primary-color); width: 48px; height: 48px; border-radius: 14px;">
                    <i class="fa-solid fa-bolt-lightning"></i>
                </span>
                إدارة Oneline Shot
            </h1>
            <p class="text-secondary m-0" style="font-size: 1.1rem;">تحكم في تجربة التعلم الذكية ووزع المحتوى التعليمي للطلاب</p>
        </div>
        <div>
            <a href="{{ route('admin.flashcards.assignments') }}" class="btn btn-outline-info fw-bold rounded-pill px-4 me-2 border-2 text-dark">
                <i class="fa-solid fa-users-viewfinder me-2 text-info"></i>
                إدارة التعيينات
            </a>
            <a href="{{ route('admin.flashcards.store-mgmt') }}" class="btn btn-outline-primary fw-bold rounded-pill px-4 me-2 border-2">
                <i class="fa-solid fa-store me-2"></i>
                إدارة المتجر
            </a>
            <a href="{{ route('admin.flashcards.create') }}" class="btn-create">
                <i class="fa-solid fa-plus"></i>
                حزمة جديدة
            </a>
        </div>
    </div>

    <!-- Stats Grid -->
    <div class="row g-4 mb-5">
        <div class="col-md-3">
            <div class="premium-card stat-card">
                <div class="icon-box" style="background: rgba(79, 70, 229, 0.1); color: #4f46e5;">
                    <i class="fa-solid fa-layer-group"></i>
                </div>
                <div>
                    <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 700; margin-bottom: 2px;">إجمالي الحزم</div>
                    <div style="font-size: 1.8rem; font-weight: 900; color: var(--text-primary);">{{ $packs->total() }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="premium-card stat-card">
                <div class="icon-box" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                    <i class="fa-solid fa-store"></i>
                </div>
                <div>
                    <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 700; margin-bottom: 2px;">في المتجر</div>
                    <div style="font-size: 1.8rem; font-weight: 900; color: var(--text-primary);">{{ $publicPacks }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="premium-card stat-card">
                <div class="icon-box" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                    <i class="fa-solid fa-users"></i>
                </div>
                <div>
                    <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 700; margin-bottom: 2px;">طلاب نشطين</div>
                    <div style="font-size: 1.8rem; font-weight: 900; color: var(--text-primary);">{{ $totalUsers }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="premium-card stat-card">
                <div class="icon-box" style="background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                    <i class="fa-solid fa-id-card"></i>
                </div>
                <div>
                    <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 700; margin-bottom: 2px;">إجمالي البطاقات</div>
                    <div style="font-size: 1.8rem; font-weight: 900; color: var(--text-primary);">{{ $totalCards }}</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Filters Section -->
    <div class="premium-card p-4 mb-4">
        <form action="{{ route('admin.flashcards.index') }}" method="GET" class="row g-3 align-items-center">
            <div class="col-lg-5 col-md-12">
                <div class="position-relative">
                    <input type="text" name="search" value="{{ request('search') }}"
                           class="search-input" placeholder="بحث بعنوان الحزمة...">
                    <i class="fa-solid fa-magnifying-glass position-absolute" style="right: 1.25rem; top: 50%; transform: translateY(-50%); color: var(--text-secondary);"></i>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <select name="type" onchange="this.form.submit()" class="form-select filter-select">
                    <option value="">جميع الأنواع</option>
                    <option value="public" {{ request('type') == 'public' ? 'selected' : '' }}>عامة (في المتجر)</option>
                    <option value="private" {{ request('type') == 'private' ? 'selected' : '' }}>خاصة (للمستخدمين)</option>
                </select>
            </div>
            <div class="col-lg-3 col-md-6">
                <select name="display_mode" onchange="this.form.submit()" class="form-select filter-select">
                    <option value="">جميع الأوضاع</option>
                    <option value="flash_card" {{ request('display_mode') == 'flash_card' ? 'selected' : '' }}>بطاقة تعليمية</option>
                    <option value="one_line" {{ request('display_mode') == 'one_line' ? 'selected' : '' }}>رسالة نصية</option>
                    <option value="qa" {{ request('display_mode') == 'qa' ? 'selected' : '' }}>سؤال وجواب</option>
                    <option value="mcq" {{ request('display_mode') == 'mcq' ? 'selected' : '' }}>اختيارات</option>
                </select>
            </div>
            @if(request()->anyFilled(['search', 'type', 'display_mode']))
                <div class="col-lg-1">
                    <a href="{{ route('admin.flashcards.index') }}" class="text-danger fw-bold text-decoration-none small">مسح</a>
                </div>
            @endif
        </form>
    </div>

    <!-- Content Table -->
    <div class="premium-card">
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th style="width: 40%">الحزمة</th>
                        <th class="text-center">البطاقات</th>
                        <th class="text-center">الوضع</th>
                        <th class="text-center">الظهور (للطالب)</th>
                        <th class="text-center">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($packs as $pack)
                    <tr class="table-row">
                        <td>
                            <div class="d-flex align-items-center gap-3">
                                <div class="pack-avatar" style="background: {{ hexToRgba($pack->color ?? '#4f46e5', 0.15) }}; color: {{ $pack->color ?? '#4f46e5' }};">
                                    📚
                                </div>
                                <div>
                                    <h6 class="mb-0 fw-bold">
                                        {{ Str::limit($pack->title, 50) }}
                                        <span class="badge bg-indigo-soft text-indigo ms-1" style="font-size: 0.65rem; background: #eef2ff; color: #4f46e5;">رسمي</span>
                                    </h6>
                                    <small class="text-secondary">{{ $pack->created_at->diffForHumans() }}</small>
                                </div>
                            </div>
                        </td>
                        <td class="text-center">
                            <span class="fs-5 fw-black">{{ $pack->items_count }}</span>
                        </td>
                        <td class="text-center">
                            @php
                                $modes = [
                                    'flash_card' => ['label' => 'بِطاقة', 'color' => '#6366f1', 'bg' => '#eef2ff'],
                                    'one_line' => ['label' => 'رسالة', 'color' => '#10b981', 'bg' => '#ecfdf5'],
                                    'qa' => ['label' => 'سؤال', 'color' => '#f59e0b', 'bg' => '#fffbeb'],
                                    'mcq' => ['label' => 'اختيارات', 'color' => '#ef4444', 'bg' => '#fef2f2'],
                                ];
                                $typeSummary = $pack->item_type_summary ?: [$pack->display_mode];
                            @endphp
                            <div class="d-flex justify-content-center gap-1 flex-wrap">
                                @foreach(array_slice($typeSummary, 0, 3) as $type)
                                    @php $m = $modes[$type] ?? $modes['flash_card']; @endphp
                                    <span class="badge-pill" style="background: {{ $m['bg'] }}; color: {{ $m['color'] }};">
                                        {{ $m['label'] }}
                                    </span>
                                @endforeach
                                @if(count($typeSummary) > 3)
                                    <span class="badge-pill" style="background:#f8fafc;color:#64748b;">+{{ count($typeSummary) - 3 }}</span>
                                @endif
                            </div>
                        </td>
                        <td class="text-center">
                            @if($pack->user && $pack->user->hasRole(\App\Enums\UserRole::ADMIN))
                                <div class="form-check form-switch d-flex justify-content-center" x-data="{ 
                                    is_public: {{ $pack->is_public ? 'true' : 'false' }},
                                    loading: false,
                                    toggle() {
                                        if (this.loading) return;
                                        this.loading = true;
                                        fetch('{{ route('admin.flashcards.toggle-visibility', $pack) }}', {
                                            method: 'POST',
                                            headers: {
                                                'Content-Type': 'application/json',
                                                'Accept': 'application/json',
                                                'X-CSRF-TOKEN': '{{ csrf_token() }}'
                                            }
                                        })
                                        .then(async res => {
                                            const data = await res.json();
                                            if (!res.ok) {
                                                alert(data.message || 'حدث خطأ غير متوقع');
                                                this.is_public = !this.is_public; // Revert
                                                return;
                                            }
                                            this.is_public = data.is_public;
                                        })
                                        .catch(err => {
                                            alert('حدث خطأ في الاتصال بالسيرفر');
                                            this.is_public = !this.is_public; // Revert
                                        })
                                        .finally(() => this.loading = false);
                                    }
                                }">
                                    <input class="form-check-input border-2" type="checkbox" role="switch" 
                                           style="width: 3rem; height: 1.5rem; cursor: pointer;"
                                           :checked="is_public" @change="toggle()" :disabled="loading">
                                    <span class="ms-2 small fw-bold" :class="is_public ? 'text-success' : 'text-secondary'" 
                                          x-text="is_public ? 'عام' : 'خاص'"></span>
                                </div>
                            @else
                                <span class="badge" style="background: #f1f5f9; color: #64748b;">محتوى الطالب</span>
                            @endif
                        </td>
                        <td>
                            <div class="d-flex justify-content-center gap-2">
                                <a href="{{ route('admin.flashcards.show', $pack) }}" class="action-btn" style="background: #eef2ff; color: #4f46e5;" title="عرض التفاصيل">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                                <a href="{{ route('admin.flashcards.edit', $pack) }}" class="action-btn" style="background: #f0f9ff; color: #0ea5e9;" title="تعديل">
                                    <i class="fa-solid fa-pen-to-square"></i>
                                </a>
                                @if(!$pack->is_public)
                                <form action="{{ route('admin.flashcards.publish', $pack) }}" method="POST">
                                    @csrf
                                    <button type="submit" class="action-btn" style="background: #ecfdf5; color: #10b981;" title="نشر في المتجر">
                                        <i class="fa-solid fa-cloud-arrow-up"></i>
                                    </button>
                                </form>
                                @endif
                                <button type="button" 
                                        data-title="{{ $pack->title }}"
                                        @click="assignPackId = {{ $pack->id }}; assignPackTitle = $event.currentTarget.dataset.title; showAssignModal = true"
                                        class="action-btn" style="background: #fffbeb; color: #f59e0b;" title="تعيين لطالب">
                                    <i class="fa-solid fa-user-plus"></i>
                                </button>
                                <form action="{{ route('admin.flashcards.destroy', $pack) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من الحذف نهائياً؟')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="action-btn" style="background: #fef2f2; color: #ef4444;" title="حذف">
                                        <i class="fa-solid fa-trash-can"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="text-center py-5">
                            <div class="opacity-25 mb-3">
                                <i class="fa-solid fa-folder-open fa-4x"></i>
                            </div>
                            <h5 class="text-secondary fw-bold">لا يوجد حزم متاحة حالياً</h5>
                            <p class="small text-muted">ابدأ بإضافة أول حزمة من زر "حزمة جديدة" في الأعلى</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        
        @if($packs->hasPages())
        <div class="p-4 border-top">
            {{ $packs->links() }}
        </div>
        @endif
    </div>

    <!-- Assign Modal -->
    <div x-show="showAssignModal" x-transition.opacity
         class="position-fixed w-100 h-100" 
         style="background: rgba(0,0,0,0.6); z-index: 9999; backdrop-filter: blur(4px); top: 0; left: 0;" x-cloak>
        <div class="d-flex align-items-center justify-content-center w-100 h-100">
            <div @click.away="showAssignModal = false" class="premium-card p-5" style="max-width: 500px; width: 90%;">
                <div class="text-center mb-4">
                    <div class="icon-box mx-auto mb-3" style="background: #fef3c7; color: #d97706; width: 72px; height: 72px; border-radius: 20px;">
                        <i class="fa-solid fa-user-astronaut fa-2x"></i>
                    </div>
                    <h4 class="fw-black mb-2">تعيين حزمة لمستخدم</h4>
                    <p class="text-secondary small" x-text="'سيتم منح نسخة من الحزمة: ' + assignPackTitle"></p>
                </div>
                
                <!-- Search Form (when no student found) -->
                <div x-show="!studentFound">
                    <div class="mb-4">
                        <label class="form-label small fw-bold text-secondary">البحث عن الطالب (الرقم الجامعي)</label>
                        <div class="d-flex gap-2">
                            <input type="text" x-model="searchQuery" @keydown.enter.prevent="searchStudent" class="form-control" placeholder="أدخل الرقم الجامعي هنا..." 
                                   style="padding: 0.85rem; border-radius: 12px; border: 2px solid #f1f5f9; background: #f8fafc;">
                            <button type="button" @click="searchStudent" class="btn btn-primary px-4 fw-bold" style="border-radius: 12px; background: var(--primary-color);" :disabled="isSearching || !searchQuery">
                                <i class="fa-solid fa-search" x-show="!isSearching"></i>
                                <i class="fa-solid fa-spinner fa-spin" x-show="isSearching" style="display: none;"></i>
                            </button>
                        </div>
                        <div x-show="searchError" x-text="searchError" class="text-danger small mt-2 fw-bold" style="display: none;"></div>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="button" @click="showAssignModal = false; searchQuery = ''; searchError = ''" class="btn border-0 w-100" style="background: #f1f5f9; border-radius: 12px; font-weight: 700;">إلغاء</button>
                    </div>
                </div>

                <!-- Assignment Form (when student is found) -->
                <form :action="'{{ url('admin/flashcards') }}/' + assignPackId + '/assign'" method="POST" x-show="studentFound" style="display: none;">
                    @csrf
                    <input type="hidden" name="user_id" :value="studentFound?.id">
                    
                    <div class="p-3 mb-4 rounded-4" style="background: #f8fafc; border: 2px solid #e2e8f0;">
                        <div class="d-flex align-items-center gap-3">
                            <div class="icon-box" style="width: 48px; height: 48px; background: #e0f2fe; color: #0284c7; border-radius: 12px;">
                                <i class="fa-solid fa-user-check fa-lg"></i>
                            </div>
                            <div>
                                <h6 class="mb-1 fw-bold text-dark" x-text="studentFound?.name"></h6>
                                <div class="text-secondary small d-flex gap-2">
                                    <span x-text="studentFound?.student_number"></span>
                                    <span>&bull;</span>
                                    <span x-text="studentFound?.college"></span>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="d-flex gap-2">
                        <button type="button" @click="studentFound = null; searchQuery = ''" class="btn border-0 flex-grow-1" style="background: #f1f5f9; border-radius: 12px; font-weight: 700;">بحث آخر</button>
                        <button type="submit" class="btn btn-primary flex-grow-1" style="border-radius: 12px; font-weight: 700; background: var(--primary-color);">تأكيد التعيين</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

@php
function hexToRgba($hex, $alpha = 1) {
    $hex = str_replace('#', '', $hex);
    if (strlen($hex) == 3) {
        $r = hexdec(substr($hex, 0, 1) . substr($hex, 0, 1));
        $g = hexdec(substr($hex, 1, 1) . substr($hex, 1, 1));
        $b = hexdec(substr($hex, 2, 1) . substr($hex, 2, 1));
    } else {
        $r = hexdec(substr($hex, 0, 2));
        $g = hexdec(substr($hex, 2, 2));
        $b = hexdec(substr($hex, 4, 2));
    }
    return "rgba($r, $g, $b, $alpha)";
}
@endphp

@endsection
