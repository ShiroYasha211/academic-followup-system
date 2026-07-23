@extends('layouts.student')

@section('title', 'متجر Oneline Shot')

@section('content')
<div class="container-fluid py-4 text-end" dir="rtl">
    <!-- Page Header -->
    <div class="d-flex justify-content-between align-items-center mb-5 flex-wrap gap-3">
        <div>
            <h1 class="h3 fw-black text-dark mb-1 d-flex align-items-center gap-3">
                <div class="bg-success-subtle p-2 rounded-3">
                    <i class="fa-solid fa-store text-success"></i>
                </div>
                المتجر العام لـ Oneline Shot
            </h1>
            <p class="text-secondary mb-0 fw-bold small">اكتشف حزم تعليمية مميزة وقم بإضافتها لمجموعتك بضغطة زر</p>
        </div>
        <a href="{{ route('student.flashcards.index') }}" class="btn btn-light fw-black rounded-3 px-4 py-2 shadow-sm border d-inline-flex align-items-center gap-2">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
            حزمي الخاصة
        </a>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4 p-3 px-4 fw-bold">
            <i class="fa-solid fa-check-circle me-2"></i> {{ session('success') }}
        </div>
    @endif
    
    @if(session('info'))
        <div class="alert alert-info border-0 shadow-sm rounded-4 mb-4 p-3 px-4 fw-bold">
            <i class="fa-solid fa-circle-info me-2"></i> {{ session('info') }}
        </div>
    @endif

    <!-- Search & Filters -->
    <div class="card border-0 shadow-sm rounded-5 p-4 mb-5 bg-white border border-light">
        <form action="{{ route('student.flashcards.public-store') }}" method="GET" class="row g-3 align-items-end">
            <div class="col-md-7">
                <label class="form-label fw-bold text-secondary small mb-2">ابحث عن موضوع معين</label>
                <div class="input-group border-2 border rounded-4 overflow-hidden bg-light shadow-none">
                    <span class="input-group-text border-0 bg-transparent text-secondary pe-0"><i class="fa-solid fa-magnifying-glass"></i></span>
                    <input type="text" name="search" value="{{ request('search') }}" 
                           class="form-control border-0 bg-transparent fw-bold shadow-none p-3" 
                           placeholder="مثال: المصطلحات الطبية، علم التشريح...">
                </div>
            </div>
            
            <div class="col-md-3">
                <label class="form-label fw-bold text-secondary small mb-2">نوع الحزمة</label>
                <select name="display_mode" onchange="this.form.submit()" class="form-select border-2 bg-light rounded-4 fw-bold shadow-none p-3 border">
                    <option value="">كل الأنواع</option>
                    <option value="flash_card" {{ request('display_mode') == 'flash_card' ? 'selected' : '' }}>بطاقة تعليمية</option>
                    <option value="one_line" {{ request('display_mode') == 'one_line' ? 'selected' : '' }}>رسالة نصية</option>
                    <option value="qa" {{ request('display_mode') == 'qa' ? 'selected' : '' }}>سؤال وجواب</option>
                    <option value="mcq" {{ request('display_mode') == 'mcq' ? 'selected' : '' }}>اختيارات</option>
                </select>
            </div>
            
            <div class="col-md-2">
                <button type="submit" class="btn btn-primary w-100 rounded-4 py-3 fw-black shadow-none border-0 transition-all">
                    تصفية النتائج
                </button>
            </div>
        </form>
    </div>

    <!-- Store Grid -->
    <div class="row g-4">
        @forelse($storeItems as $storeItem)
        @php $pack = $storeItem->pack; @endphp
        @if($pack)
        <div class="col-md-6 col-xl-4">
            <div class="card border-0 shadow-sm rounded-5 h-100 bg-white overflow-hidden card-hover transition-all border border-light">
                <div style="height: 6px; background: {{ $pack->color ?? '#4f46e5' }};"></div>
                <div class="card-body p-4">
                    <div class="d-flex align-items-start justify-content-between mb-4">
                        <div class="d-flex align-items-center gap-3">
                            <div class="rounded-4 d-flex align-items-center justify-content-center shadow-sm text-white fs-4 fw-black" 
                                 style="width: 54px; height: 54px; background: {{ $pack->color ?? '#4f46e5' }};">
                                {{ $pack->icon ?? '📚' }}
                            </div>
                            <div>
                                <h3 class="h6 fw-black text-dark mb-1">{{ Str::limit($pack->title, 35) }}</h3>
                                <div class="text-secondary small fw-bold">
                                    <i class="fa-solid fa-user-pen me-1"></i> {{ $pack->user->name ?? 'مجهول' }}
                                </div>
                            </div>
                        </div>
                        @if($storeItem->is_featured)
                            <span class="badge bg-warning text-dark border-0 rounded-pill px-3 py-2 fw-black small shadow-sm">
                                <i class="fa-solid fa-star me-1"></i> مميزة
                            </span>
                        @endif
                    </div>

                    @if($pack->description)
                        <p class="text-secondary small fw-bold mb-4 line-clamp-2 lh-base">{{ Str::limit($pack->description, 110) }}</p>
                    @else
                        <div class="mb-4" style="height: 42px;"></div>
                    @endif

                    <div class="d-flex align-items-center gap-2 mb-4 flex-wrap">
                        <span class="badge bg-light text-secondary border rounded-pill px-3 py-2 fw-bold small">
                            {{ $pack->items_count ?? 0 }} بطاقة
                        </span>
                        @if($pack->display_mode)
                            <span class="badge bg-primary-subtle text-primary border border-primary-subtle rounded-pill px-3 py-2 fw-bold small">
                                <i class="fa-solid fa-layer-group me-1"></i> {{ $pack->getDisplayModeTextAttribute() }}
                            </span>
                        @endif
                        <span class="text-secondary small fw-bold ms-auto">
                            <i class="fa-solid fa-download me-1"></i> {{ $storeItem->downloads_count }} سحب
                        </span>
                    </div>

                    <div class="pt-3 border-top border-light mt-auto">
                        <form action="{{ route('student.flashcards.clone', $pack) }}" method="POST">
                            @csrf
                            <button type="submit" class="btn btn-emerald w-100 rounded-4 py-2 fw-black shadow-sm transition-all text-white d-flex align-items-center justify-content-center gap-2">
                                <i class="fas fa-cloud-download-alt"></i>
                                سحب وحفظ الحزمة
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        @endif
        @empty
        <div class="col-12 py-5 text-center">
            <div class="bg-light rounded-circle d-inline-flex align-items-center justify-content-center p-4 mb-4" style="width: 130px; height: 130px;">
                <i class="fa-solid fa-store-slash fs-1 text-secondary opacity-30"></i>
            </div>
            <h3 class="fw-black text-dark mb-2">لا توجد حزم متاحة حالياً</h3>
            <p class="text-secondary mb-0 fw-bold px-4">ترقب قريباً إطلاق أقوى الحزم التعليمية في متجر Oneline Shot</p>
        </div>
        @endforelse
    </div>

    <!-- Pagination -->
    @if($storeItems->hasPages())
    <div class="d-flex justify-content-center mt-5">
        {{ $storeItems->links() }}
    </div>
    @endif
</div>

<style>
    .fw-black { font-weight: 900; }
    .btn-primary { background: linear-gradient(135deg, #4f46e5, #7c3aed); }
    .btn-emerald { background: linear-gradient(135deg, #10b981, #059669); border: none; }
    .btn-emerald:hover { opacity: 0.9; transform: translateY(-2px); }
    .card-hover:hover { transform: translateY(-5px); box-shadow: 0 15px 35px rgba(0,0,0,0.1) !important; }
    .line-clamp-2 {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }
</style>
@endsection
