@extends('layouts.admin')

@section('title', 'تفاصيل مشاركة المزرعة العامة')

@section('content')
@php
    $student = $profile->user;
    $formatDuration = static function (int $seconds): string {
        $hours = intdiv($seconds, 3600);
        $minutes = intdiv($seconds % 3600, 60);
        return $hours > 0
            ? number_format($hours) . ' س ' . $minutes . ' د'
            : $minutes . ' دقيقة';
    };
    $displayName = $profile->use_alias && $profile->public_name
        ? $profile->public_name
        : ($student?->name ?? 'مستخدم محذوف');
@endphp

<style>
    .farm-profile-page {
        color: #173b2e;
    }

    .farm-profile-hero {
        padding: 1.5rem;
        color: #fff;
        background: linear-gradient(135deg, #155f43, #2d8a62);
        border-radius: 1.25rem;
        box-shadow: 0 18px 42px rgba(21, 95, 67, .15);
    }

    .farm-profile-card {
        background: #fff;
        border: 1px solid #dfeae3;
        border-radius: 1rem;
        box-shadow: 0 8px 24px rgba(22, 53, 43, .045);
    }

    .farm-profile-metric {
        min-height: 100%;
        padding: 1rem;
        background: #f6faf7;
        border: 1px solid #e3eee7;
        border-radius: .85rem;
    }

    .farm-plant-card {
        padding: .9rem;
        background: #f8fbf9;
        border: 1px solid #e5eee8;
        border-radius: .85rem;
    }
</style>

<main class="container-fluid py-4 farm-profile-page" dir="rtl">
    <div class="d-flex align-items-center justify-content-between gap-3 mb-4 flex-wrap">
        <a href="{{ route('admin.tree-farm-rewards.index', ['tab' => 'public_farm']) }}" class="btn btn-light border rounded-3">
            <i class="fa-solid fa-arrow-right me-1"></i>
            العودة إلى المزرعة العامة
        </a>
        <form method="POST" action="{{ route('admin.tree-farm-rewards.public-farm.visibility', $profile) }}">
            @csrf
            <button type="submit" class="btn {{ $profile->is_public ? 'btn-outline-warning' : 'btn-success' }} rounded-3">
                <i class="fa-solid {{ $profile->is_public ? 'fa-eye-slash' : 'fa-eye' }} me-1"></i>
                {{ $profile->is_public ? 'إخفاء من المزرعة العامة' : 'إعادة الظهور' }}
            </button>
        </form>
    </div>

    <section class="farm-profile-hero mb-4">
        <div class="row align-items-center g-4">
            <div class="col-lg-7">
                <div class="d-flex align-items-center gap-3">
                    <div class="d-grid place-items-center bg-white bg-opacity-10 rounded-4 fw-black" style="width: 64px; height: 64px; font-size: 1.45rem;">
                        {{ mb_substr($student?->name ?? 'م', 0, 1) }}
                    </div>
                    <div>
                        <div class="small text-white-50 mb-1">سجل المشاركة العامة</div>
                        <h1 class="h3 fw-bold mb-1">{{ $student?->name ?? 'مستخدم محذوف' }}</h1>
                        <div class="text-white-50">{{ $student?->student_number ?: $student?->email }}</div>
                    </div>
                </div>
            </div>
            <div class="col-lg-5">
                <div class="bg-white bg-opacity-10 rounded-4 p-3">
                    <div class="small text-white-50">الاسم الظاهر للطلاب</div>
                    <div class="h5 fw-bold mb-1">{{ $displayName }}</div>
                    <div class="small">{{ $profile->is_public ? 'ظاهر حاليًا في ترتيب الجامعة' : 'مخفي حاليًا من المزرعة العامة' }}</div>
                </div>
            </div>
        </div>
    </section>

    <div class="row g-3 mb-4">
        <div class="col-md-3 col-6">
            <div class="farm-profile-metric">
                <div class="h4 fw-bold mb-1">{{ $formatDuration((int) $profile->total_public_focus_seconds) }}</div>
                <div class="small text-muted">التركيز العام الكلي</div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="farm-profile-metric">
                <div class="h4 fw-bold mb-1">{{ number_format($sessions->total()) }}</div>
                <div class="small text-muted">الجلسات العامة</div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="farm-profile-metric">
                <div class="h4 fw-bold mb-1">{{ number_format($publicPlantsCount) }}</div>
                <div class="small text-muted">النباتات العامة</div>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="farm-profile-metric">
                <div class="h4 fw-bold mb-1">{{ number_format((int) $profile->coins_balance) }}</div>
                <div class="small text-muted">رصيد العملات</div>
            </div>
        </div>
    </div>

    <section class="farm-profile-card p-3 p-lg-4 mb-4">
        <div class="d-flex align-items-center justify-content-between gap-3 mb-3 flex-wrap">
            <div>
                <h2 class="h6 fw-bold mb-1">البيانات الأكاديمية</h2>
                <p class="small text-muted mb-0">المسار المرتبط بحساب الطالب.</p>
            </div>
        </div>
        <div class="row g-3">
            @foreach([
                'الجامعة' => $student?->university?->name,
                'الكلية' => $student?->college?->name,
                'التخصص' => $student?->major?->name,
                'المستوى' => $student?->level?->name,
            ] as $label => $value)
                <div class="col-lg-3 col-md-6">
                    <div class="p-3 rounded-3 bg-light h-100">
                        <div class="small text-muted mb-1">{{ $label }}</div>
                        <div class="fw-bold">{{ $value ?: 'غير محدد' }}</div>
                    </div>
                </div>
            @endforeach
        </div>
    </section>

    <section class="farm-profile-card p-3 p-lg-4 mb-4">
        <div class="mb-3">
            <h2 class="h6 fw-bold mb-1">النباتات العامة</h2>
            <p class="small text-muted mb-0">آخر النباتات التي أضافها الطالب إلى المزرعة العامة.</p>
        </div>
        @if($plants->isEmpty())
            <div class="text-center py-5 text-muted">لا توجد نباتات عامة مسجلة لهذا الطالب.</div>
        @else
            <div class="row g-3">
                @foreach($plants as $plant)
                    <div class="col-xl-3 col-lg-4 col-md-6">
                        <article class="farm-plant-card h-100">
                            <div class="d-flex align-items-start justify-content-between gap-2 mb-2">
                                <div class="d-grid place-items-center rounded-3 bg-success-subtle text-success" style="width: 42px; height: 42px;">
                                    <i class="fa-solid fa-seedling"></i>
                                </div>
                                <span class="badge bg-light text-dark border">{{ $plant->rarity }}</span>
                            </div>
                            <div class="fw-bold mb-1">{{ $plant->name }}</div>
                            <div class="small text-muted mb-2">{{ $plant->subject_name ?: 'بدون مادة مرتبطة' }}</div>
                            <div class="d-flex justify-content-between small">
                                <span>{{ $formatDuration((int) $plant->required_seconds) }}</span>
                                <span class="text-warning fw-bold">{{ number_format((int) $plant->coins_awarded) }} عملة</span>
                            </div>
                            <div class="small text-muted mt-2">{{ optional($plant->planted_at)->format('Y/m/d h:i A') }}</div>
                        </article>
                    </div>
                @endforeach
            </div>
        @endif
    </section>

    <section class="farm-profile-card overflow-hidden">
        <div class="p-3 p-lg-4 border-bottom">
            <h2 class="h6 fw-bold mb-1">سجل الجلسات العامة</h2>
            <p class="small text-muted mb-0">كل جلسة ونتيجتها والنبتة الناتجة عنها.</p>
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0" style="min-width: 900px;">
                <thead class="table-light">
                    <tr>
                        <th>التاريخ</th>
                        <th>المادة</th>
                        <th>المدة المخططة</th>
                        <th>المدة الفعلية</th>
                        <th>الحالة</th>
                        <th>النبتة</th>
                        <th>المكافأة</th>
                        <th>المصدر</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($sessions as $session)
                        <tr>
                            <td>
                                <div class="fw-bold">{{ optional($session->started_at)->format('Y/m/d') }}</div>
                                <div class="small text-muted">{{ optional($session->started_at)->format('h:i A') }}</div>
                            </td>
                            <td>{{ $session->subject_name ?: 'غير مرتبطة بمادة' }}</td>
                            <td>{{ $formatDuration((int) $session->planned_seconds) }}</td>
                            <td>{{ $formatDuration((int) $session->focused_seconds) }}</td>
                            <td><span class="badge bg-light text-dark border">{{ $session->status }}</span></td>
                            <td>{{ $session->plant?->name ?: 'لم تنتج نبتة' }}</td>
                            <td>{{ number_format((int) $session->awarded_coins) }} عملة</td>
                            <td>{{ $session->source === 'offline' ? 'مزامنة أوفلاين' : 'مباشر' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="text-center py-5 text-muted">لا توجد جلسات عامة.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($sessions->hasPages())
            <div class="p-3 border-top">{{ $sessions->links() }}</div>
        @endif
    </section>
</main>
@endsection
