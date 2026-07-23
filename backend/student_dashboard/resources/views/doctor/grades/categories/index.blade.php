@extends('layouts.doctor')

@section('title', 'تقسيم أعمال السنة - ' . $subject->name)

@section('content')
@push('styles')
<style>
    :root {
        --glass-bg: rgba(255, 255, 255, 0.7);
        --glass-border: rgba(255, 255, 255, 0.3);
    }

    .premium-header {
        background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        position: relative;
        overflow: hidden;
        margin-bottom: 2rem;
        box-shadow: 0 20px 40px -15px rgba(99, 102, 241, 0.35);
    }

    .premium-header::after {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 400px;
        height: 400px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 50%;
        filter: blur(60px);
    }

    .glass-card {
        background: var(--glass-bg);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid var(--glass-border);
        border-radius: 24px;
        box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.07);
    }

    .score-badge {
        background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
        color: white;
        padding: 0.5rem 1.25rem;
        border-radius: 12px;
        font-weight: 800;
        font-size: 1.1rem;
    }

    .category-card {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        border: 2px solid transparent;
        background: white;
    }

    .category-card:hover {
        transform: translateY(-5px);
        border-color: #6366f1;
    }

    .progress-track {
        background: #f1f5f9;
        height: 12px;
        border-radius: 10px;
        overflow: hidden;
    }

    .progress-value {
        height: 100%;
        background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
        transition: width 0.6s ease;
    }

    .btn-premium {
        background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
        color: white;
        border: none;
        padding: 0.8rem 2rem;
        border-radius: 16px;
        font-weight: 800;
        transition: all 0.3s ease;
    }

    .btn-premium:hover {
        transform: scale(1.02);
        box-shadow: 0 10px 20px -5px rgba(99, 102, 241, 0.4);
        color: white;
    }
</style>
@endpush

<div class="premium-header">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-4 position-relative" style="z-index: 2;">
        <div>
            <span class="badge px-3 py-2 rounded-pill mb-3 fw-700" style="background: rgba(255,255,255,0.2); color: white;">مركز إدارة الدرجات</span>
            <h1 class="fw-900 mb-2" style="font-size: 2.5rem;">هيكلة أعمال السنة</h1>
            <p class="text-white text-opacity-80 fw-700 m-0"><i class="fa-solid fa-book-open me-2"></i>{{ $subject->name }} | {{ $subject->major->name }}</p>
        </div>
        <div class="d-flex gap-3">
            <a href="{{ route('doctor.grades.show', $subject->id) }}" class="btn px-4 rounded-4 fw-800 border-0" style="background: rgba(255,255,255,0.2); color: white;">العودة للدرجات</a>
            <a href="{{ route('doctor.grades.delegations.index', $subject->id) }}" class="btn bg-white px-4 rounded-4 fw-800 border-0 shadow-lg" style="color: #6366f1;">تفويض الطلاب <i class="fa-solid fa-user-shield ms-2"></i></a>
        </div>
    </div>
</div>

<div class="row g-4">
    <!-- Right Content: Current Distribution (Primary focus) -->
    <div class="col-lg-8">
        <div class="glass-card p-4 h-100">
            <h4 class="fw-900 mb-4 d-flex align-items-center gap-2">
                <div class="bg-success bg-opacity-10 p-2 rounded-3">
                    <i class="fa-solid fa-layer-group text-success"></i>
                </div>
                التوزيع الحالي للدرجات
            </h4>

            <div class="row g-3">
                @forelse($categories as $category)
                <div class="col-md-6">
                    <div class="category-card glass-card p-4 h-100">
                        <div class="d-flex justify-content-between align-items-start mb-4">
                            <div class="score-badge">{{ (float)$category->max_score }}</div>
                            <form action="{{ route('doctor.grades.categories.destroy', $category->id) }}" method="POST" onsubmit="return confirm('تنبيه: سيؤدي الحذف لإلغاء تفويضات الطلاب لهذه الفئة. هل تريد الاستمرار؟')">
                                @csrf @method('DELETE')
                                <button class="btn btn-link text-danger-emphasis p-2 rounded-circle bg-danger bg-opacity-10 border-0" title="حذف">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </form>
                        </div>
                        <h5 class="fw-900 text-dark mb-1">{{ $category->name }}</h5>
                        <div class="text-secondary small fw-700 mb-3">تفويض رصد المهام متاح في صفحة التفويض</div>
                        
                        <div class="d-flex align-items-center gap-2">
                            <div class="flex-grow-1 progress-track" style="height: 6px;">
                                <div class="progress-value" style="width: {{ ($category->max_score / 40) * 100 }}%"></div>
                            </div>
                            <span class="fw-800 small text-primary">{{ round(($category->max_score / 40) * 100) }}%</span>
                        </div>
                    </div>
                </div>
                @empty
                <div class="col-12 text-center py-5">
                    <div class="bg-light bg-opacity-50 p-5 rounded-5 border-dashed border-2">
                        <i class="fa-solid fa-diagram-project fa-4x text-light-emphasis opacity-25 mb-4"></i>
                        <h5 class="fw-900 text-secondary">ابدأ ببناء خطة أعمال السنة</h5>
                        <p class="text-secondary opacity-75">قم بإضافة التقسيمات (مثل الحضور، الكويز، المهام) لتنظيم عملية رصد الدرجات.</p>
                    </div>
                </div>
                @endforelse
            </div>

            @if(count($categories) > 0)
            <div class="mt-5 p-4 rounded-4 bg-primary bg-opacity-10 d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="fw-900 text-primary mb-1">جاهز للمرحلة التالية؟</h5>
                    <p class="text-primary-emphasis fw-700 small m-0">قم بتفويض الطلاب الموثوقين للبدء برصد هذه الدرجات بدلاً عنك.</p>
                </div>
                <a href="{{ route('doctor.grades.delegations.index', $subject->id) }}" class="btn btn-premium px-4">انتقل للتفويض <i class="fa-solid fa-arrow-left ms-2"></i></a>
            </div>
            @endif
        </div>
    </div>

    <!-- Left Content: Setup (Secondary focus) -->
    <div class="col-lg-4">
        <div class="glass-card p-4 h-100">
            <h4 class="fw-900 mb-4 d-flex align-items-center gap-2">
                <div class="bg-primary bg-opacity-10 p-2 rounded-3">
                    <i class="fa-solid fa-plus text-primary"></i>
                </div>
                إضافة تقسيم جديد
            </h4>
            
            <form action="{{ route('doctor.grades.categories.store', $subject->id) }}" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="form-label fw-800 text-secondary">عنوان التقييم</label>
                    <input type="text" name="name" class="form-control form-control-lg rounded-4 border-0 shadow-sm" placeholder="مثلاً: اختبار نصفي، مشاركة.." required style="background: white;">
                </div>
                <div class="mb-4">
                    <label class="form-label fw-800 text-secondary">الوزن النسبي (من 40)</label>
                    <div class="input-group input-group-lg">
                        <input type="number" name="max_score" class="form-control rounded-start-4 border-0 shadow-sm" step="0.5" min="0.5" max="{{ 40 - $totalMaxScore }}" placeholder="10" required style="background: white;">
                        <span class="input-group-text rounded-end-4 border-0 bg-white fw-900">درجة</span>
                    </div>
                </div>

                <button type="submit" class="btn btn-premium w-100 py-3" {{ $totalMaxScore >= 40 ? 'disabled' : '' }}>
                    حفظ التصنيف <i class="fa-solid fa-check-double ms-2"></i>
                </button>

                @if($totalMaxScore >= 40)
                    <div class="alert alert-warning border-0 rounded-4 mt-3 fw-700 small">
                        تنبيه: لقد استنفدت الـ 40 درجة بالكامل.
                    </div>
                @endif
            </form>

            <div class="mt-5 pt-4 border-top">
                <h6 class="fw-900 text-secondary text-uppercase small mb-4">ملخص التوزيع</h6>
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <span class="fw-800">إجمالي الموزع</span>
                    <span class="fw-900 h3 m-0 {{ $totalMaxScore > 40 ? 'text-danger' : 'text-primary' }}">{{ $totalMaxScore }}<small class="h6 text-secondary">/40</small></span>
                </div>
                <div class="progress-track">
                    <div class="progress-value" style="width: {{ ($totalMaxScore / 40) * 100 }}%"></div>
                </div>
                <p class="text-secondary small mt-3 fw-700">المجموع النهائي لأعمال السنة يجب أن يكون 40 درجة ليتم رصده بشكل صحيح.</p>
            </div>
        </div>
    </div>
</div>
@endsection
