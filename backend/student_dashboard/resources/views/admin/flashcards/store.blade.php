@extends('layouts.admin')

@section('title', 'إدارة متجر Oneline Shot')

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

    .stat-card {
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
    }

    .icon-box {
        width: 54px;
        height: 54px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        flex-shrink: 0;
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

    .featured-star:hover {
        transform: scale(1.2);
    }
</style>

<div class="mb-5 d-flex justify-content-between align-items-center flex-wrap gap-4">
    <div>
        <h1 class="mb-2 d-flex align-items-center gap-3" style="font-weight: 900; letter-spacing: -0.02em;">
            <span class="icon-box" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                <i class="fa-solid fa-store"></i>
            </span>
            إدارة المتجر العام
        </h1>
        <p class="text-secondary m-0" style="font-size: 1.1rem;">تحكم في الحزم المعروضة للطلاب، ميز المحتوى، وراقب التحميلات</p>
    </div>
    <a href="{{ route('admin.flashcards.index') }}" class="btn btn-light fw-bold rounded-pill px-4 border-2">
        <i class="fa-solid fa-arrow-right me-2"></i>
        العودة لجميع الحزم
    </a>
</div>

<!-- Category Filters -->
<div class="premium-card p-4 mb-4">
    <form action="{{ route('admin.flashcards.store-mgmt') }}" method="GET" class="row g-3 align-items-center">
        <div class="col-lg-6">
            <div class="position-relative">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="form-control border-2 rounded-4 p-3 ps-5" placeholder="بحث بعنوان الحزمة في المتجر...">
                <i class="fa-solid fa-magnifying-glass position-absolute" style="left: 1.25rem; top: 50%; transform: translateY(-50%); color: #94a3b8;"></i>
            </div>
        </div>
        <div class="col-lg-4">
            <select name="display_mode" onchange="this.form.submit()" class="form-select border-2 rounded-4 p-3">
                <option value="">جميع الأنواع</option>
                <option value="flash_card" {{ request('display_mode') == 'flash_card' ? 'selected' : '' }}>بطاقة تعليمية</option>
                <option value="one_line" {{ request('display_mode') == 'one_line' ? 'selected' : '' }}>رسالة نصية</option>
                <option value="qa" {{ request('display_mode') == 'qa' ? 'selected' : '' }}>سؤال وجواب</option>
                <option value="mcq" {{ request('display_mode') == 'mcq' ? 'selected' : '' }}>اختيارات</option>
            </select>
        </div>
        <div class="col-lg-2">
            <button type="submit" class="btn btn-primary w-100 rounded-4 p-3 fw-bold">تصفية</button>
        </div>
    </form>
</div>

<div class="premium-card">
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>الحزمة العامة</th>
                    <th>التصنيف</th>
                    <th class="text-center">التحميلات</th>
                    <th class="text-center">الناشر</th>
                    <th class="text-center">الإجراءات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($storeItems as $item)
                @php $pack = $item->pack; @endphp
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-3">
                            <div class="rounded-4 d-flex align-items-center justify-content-center text-white shadow-sm fw-black" 
                                 style="width: 44px; height: 44px; background: {{ $pack->color ?? '#4f46e5' }}; font-size: 1.2rem;">
                                📚
                            </div>
                            <div>
                                <h6 class="mb-0 fw-bold">{{ Str::limit($pack->title, 40) }}</h6>
                                <div class="d-flex gap-2">
                                    <small class="text-secondary">{{ $pack->items_count }} بطاقة</small>
                                    <small class="text-muted">•</small>
                                    <small class="text-secondary">
                                        {{ count($pack->item_type_summary ?? []) > 1 ? 'محتوى متنوع' : $pack->getDisplayModeTextAttribute() }}
                                    </small>
                                </div>
                            </div>
                        </div>
                    </td>
                    <td>
                        <span class="badge bg-primary-subtle text-primary border border-primary-subtle rounded-3 px-3 py-2 fw-bold small">
                            {{ $item->category ?? 'عام' }}
                        </span>
                    </td>
                    <td class="text-center">
                        <div class="fw-black fs-5 text-dark">{{ number_format($item->downloads_count) }}</div>
                        <small class="text-muted uppercase" style="font-size: 0.65rem;">مرة سحب</small>
                    </td>
                    <td class="text-center">
                        <div class="small fw-bold text-dark">{{ $item->publisher->name ?? 'النظام' }}</div>
                        <small class="text-secondary">{{ $item->created_at->format('Y/m/d') }}</small>
                    </td>
                    <td>
                        <div class="d-flex justify-content-center gap-2">
                            <a href="{{ route('admin.flashcards.show', $pack) }}" class="btn btn-sm btn-light border rounded-3 p-2" title="تعديل المحتوى">
                                <i class="fa-solid fa-edit text-primary"></i>
                            </a>
                            <form action="{{ route('admin.flashcards.toggle-featured', $pack) }}" method="POST">
                                @csrf
                                <button type="submit" class="btn btn-sm btn-light border rounded-3 p-2" title="{{ $item->is_featured ? 'إلغاء التمييز' : 'تمييز في المتجر' }}">
                                    <i class="fa-solid fa-star {{ $item->is_featured ? 'text-warning' : 'text-secondary' }}"></i>
                                </button>
                            </form>
                            <form action="{{ route('admin.flashcards.toggle-visibility', $pack) }}" method="POST">
                                @csrf
                                <button type="submit" class="btn btn-sm btn-light border rounded-3 p-2" title="إزالة من المتجر" onclick="return confirm('هل تريد إزالة هذه الحزمة من المتجر العام؟ ستبقى متاحة في قائمة حزمك.')">
                                    <i class="fa-solid fa-eye-slash text-danger"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center py-5">
                        <div class="opacity-25 mb-3">
                            <i class="fa-solid fa-store-slash fa-4x"></i>
                        </div>
                        <h5 class="text-secondary fw-bold">المتجر فارغ حالياً</h5>
                        <p class="small text-muted">قم بنشر الحزم من لوحة التحكم لتظهر هنا</p>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($storeItems->hasPages())
    <div class="p-4 border-top">
        {{ $storeItems->links() }}
    </div>
    @endif
</div>
@endsection
