@extends('layouts.student')

@section('title', 'Oneline Shot')

@section('content')
<div class="container-fluid px-0">
    <!-- Page Header -->
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div>
            <h1 class="h2 fw-bolder text-dark mb-1 d-flex align-items-center gap-2">
                <i class="fas fa-layer-group text-primary" style="font-size: 1.75rem;"></i>
                Oneline Shot
            </h1>
            <p class="text-secondary mb-0">أنشئ حزم Oneline Shot واستقبل إشعارات مراجعة ذكية على مدار اليوم</p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('student.flashcards.public-store') }}" class="btn btn-outline-success border-2 fw-bold d-inline-flex align-items-center gap-2" style="border-radius: 12px; padding: 0.6rem 1.25rem;">
                <i class="fas fa-shopping-basket"></i>
                المتجر العام
            </a>
            <a href="{{ route('student.flashcards.create') }}" class="btn btn-primary fw-bold d-inline-flex align-items-center gap-2 shadow-sm" style="border-radius: 12px; padding: 0.6rem 1.25rem;">
                <i class="fas fa-plus"></i>
                حزمة جديدة
            </a>
        </div>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
        <div class="col-6 col-md-4">
            <div class="card border-0 shadow-sm rounded-4 p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="rounded-3 d-flex align-items-center justify-content-center text-primary" style="width: 48px; height: 48px; background: rgba(79, 70, 229, 0.1);">
                        <i class="fas fa-folder-open fs-4"></i>
                    </div>
                    <div>
                        <div class="small text-secondary fw-bold">حزمي</div>
                        <div class="h4 fw-black mb-0">{{ $totalPacks }}</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-6 col-md-4">
            <div class="card border-0 shadow-sm rounded-4 p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="rounded-3 d-flex align-items-center justify-content-center text-success" style="width: 48px; height: 48px; background: rgba(16, 185, 129, 0.1);">
                        <i class="fas fa-check-double fs-4"></i>
                    </div>
                    <div>
                        <div class="small text-secondary fw-bold">نشطة</div>
                        <div class="h4 fw-black mb-0">{{ $activePacks }}</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-12 col-md-4">
            <div class="card border-0 shadow-sm rounded-4 p-3">
                <div class="d-flex align-items-center gap-3">
                    <div class="rounded-3 d-flex align-items-center justify-content-center text-warning" style="width: 48px; height: 48px; background: rgba(245, 158, 11, 0.1);">
                        <i class="fas fa-layer-group fs-4"></i>
                    </div>
                    <div>
                        <div class="small text-secondary fw-bold">إجمالي البطاقات</div>
                        <div class="h4 fw-black mb-0">{{ $totalCards }}</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm rounded-3 mb-4">{{ session('success') }}</div>
    @endif
    @if(session('info'))
        <div class="alert alert-info border-0 shadow-sm rounded-3 mb-4">{{ session('info') }}</div>
    @endif

    <!-- Packs Grid -->
    <div class="row g-4">
        @forelse($packs as $pack)
        <div class="col-md-6 col-lg-4">
            <div class="card border-0 shadow-sm h-100 position-relative overflow-hidden transition-all hover-translate-y" style="border-radius: 20px;">
                <!-- Color Bar -->
                <div style="height: 6px; background: {{ $pack->color ?? '#4f46e5' }};"></div>

                <div class="card-body p-4">
                    <div class="d-flex justify-content-between align-items-start mb-3">
                        <div class="d-flex align-items-center gap-3">
                            <div class="rounded-4 d-flex align-items-center justify-content-center fs-3" style="width: 52px; height: 52px; background: {{ $pack->color ?? 'rgba(79,70,229,0.1)' }}20;">
                                {{ $pack->icon ?? '📚' }}
                            </div>
                            <div>
                                <h3 class="h6 fw-bolder text-dark mb-1">
                                    {{ Str::limit($pack->title, 30) }}
                                    @if($pack->is_assigned)
                                        <span class="text-danger ms-1" title="تم التعيين من قِبل الإدارة">
                                            <i class="fa-solid fa-thumbtack"></i>
                                        </span>
                                    @endif
                                </h3>
                                @php
                                    $modeLabels = ['flash_card' => 'تذكرة', 'one_line' => 'نص واحد', 'qa' => 'سؤال وجواب', 'mcq' => 'اختيارات'];
                                @endphp
                                <div class="d-flex align-items-center gap-1 flex-wrap">
                                    <span class="badge bg-light text-secondary rounded-pill px-2" style="font-size: 0.7rem;">{{ $modeLabels[$pack->display_mode] ?? $pack->display_mode }}</span>
                                    @if($pack->is_assigned)
                                        <span class="badge bg-danger-subtle text-danger border border-danger-subtle rounded-pill px-2" style="font-size: 0.7rem;">
                                            <i class="fa-solid fa-chalkboard-user me-1"></i> تعيين الإدارة
                                        </span>
                                    @endif
                                </div>
                            </div>
                        </div>
                        <!-- Toggle Active -->
                        <form action="{{ route('student.flashcards.toggle', $pack) }}" method="POST">
                            @csrf
                            @method('PATCH')
                            <button type="submit" class="p-0 bg-transparent border-0" title="{{ $pack->is_active ? 'إيقاف' : 'تفعيل' }}">
                                <div class="rounded-pill position-relative" style="width: 44px; height: 24px; background: {{ $pack->is_active ? '#10b981' : '#cbd5e1' }}; transition: all 0.2s;">
                                    <div class="rounded-circle bg-white position-absolute shadow-sm" style="width: 20px; height: 20px; top: 2px; {{ $pack->is_active ? 'right: 2px' : 'left: 2px' }}; transition: all 0.2s;"></div>
                                </div>
                            </button>
                        </form>
                    </div>

                    @if($pack->description)
                    <p class="text-secondary small mb-4 lh-base">{{ Str::limit($pack->description, 80) }}</p>
                    @endif

                    <div class="d-flex align-items-center justify-content-between pt-3 border-top border-light">
                        <div class="d-flex align-items-center gap-2">
                            <span class="fw-bold text-dark small">{{ $pack->items_count }} بطاقة</span>
                            <span class="small py-1 px-2 rounded-2 fw-bold" style="background: {{ $pack->notifications_enabled ? 'rgba(16,185,129,0.1)' : 'rgba(100,116,139,0.1)' }}; color: {{ $pack->notifications_enabled ? '#10b981' : '#94a3b8' }};">
                                <i class="fas fa-bell" style="font-size: 0.75rem;"></i>
                            </span>
                        </div>
                        <div class="d-flex gap-1">
                            <a href="{{ route('student.flashcards.show', $pack) }}" class="btn btn-sm btn-light border-0 d-flex align-items-center justify-content-center text-primary" style="width: 32px; height: 32px; border-radius: 8px;" title="عرض">
                                <i class="fas fa-eye" style="font-size: 0.9rem;"></i>
                            </a>
                            <a href="{{ route('student.flashcards.review', $pack) }}" class="btn btn-sm btn-light border-0 d-flex align-items-center justify-content-center text-purple" style="width: 32px; height: 32px; border-radius: 8px; color: #a855f7;" title="مراجعة">
                                <i class="fas fa-play-circle" style="font-size: 0.9rem;"></i>
                            </a>
                            <a href="{{ route('student.flashcards.edit', $pack) }}" class="btn btn-sm btn-light border-0 d-flex align-items-center justify-content-center text-info" style="width: 32px; height: 32px; border-radius: 8px;" title="تعديل">
                                <i class="fas fa-edit" style="font-size: 0.85rem;"></i>
                            </a>
                            <form action="{{ route('student.flashcards.destroy', $pack) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذه الحزمة؟')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-light border-0 d-flex align-items-center justify-content-center text-danger" style="width: 32px; height: 32px; border-radius: 8px;" title="حذف">
                                    <i class="fas fa-trash-alt" style="font-size: 0.85rem;"></i>
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        @empty
        <div class="col-12 text-center py-5">
            <i class="fas fa-layer-group text-secondary opacity-25 mb-4" style="font-size: 4rem;"></i>
            <h4 class="fw-bold text-dark mb-2">لا توجد حزم بطاقات بعد</h4>
            <p class="text-secondary mb-4">أنشئ أول حزمة Oneline Shot أو تصفح المتجر العام لسحب حزم جاهزة</p>
            <div class="d-flex gap-2 justify-content-center">
                <a href="{{ route('student.flashcards.create') }}" class="btn btn-primary fw-bold px-4 px-md-5 rounded-3 shadow-sm">إنشاء حزمة</a>
                <a href="{{ route('student.flashcards.public-store') }}" class="btn btn-outline-success fw-bold px-4 px-md-5 rounded-3">تصفح المتجر</a>
            </div>
        </div>
        @endforelse
    </div>
</div>

<style>
    .hover-translate-y:hover {
        transform: translateY(-5px);
    }
    .transition-all {
        transition: all 0.3s ease;
    }
</style>
@endsection
