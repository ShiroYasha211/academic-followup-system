@extends('layouts.delegate')

@section('title', 'جداول الاختبارات')

@push('styles')
<style>
    /* Stats Row */
    .stats-row {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .stat-card .icon {
        width: 50px;
        height: 50px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-card .value {
        font-size: 1.75rem;
        font-weight: 700;
    }

    .stat-card .label {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    /* Schedules Grid */
    .schedules-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
        gap: 1.5rem;
    }

    .schedule-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
        transition: all 0.3s;
    }

    .schedule-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.12);
    }

    .schedule-header {
        padding: 1.25rem 1.5rem;
        background: linear-gradient(135deg, #fef2f2 0%, #fff 100%);
        border-bottom: 1px solid var(--border-color);
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
    }

    .schedule-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.35rem;
    }

    .schedule-term {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .schedule-status {
        padding: 0.35rem 0.875rem;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .schedule-status.published {
        background: #d1fae5;
        color: #065f46;
    }

    .schedule-status.draft {
        background: #fef3c7;
        color: #92400e;
    }

    .official-badge {
        background: linear-gradient(135deg, #0369a1 0%, #075985 100%);
        color: white;
        padding: 0.35rem 0.875rem;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.35rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }

    .schedule-body {
        padding: 1.25rem 1.5rem;
    }

    .schedule-meta {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
        margin-bottom: 1rem;
    }

    .meta-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .meta-icon {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .meta-info .value {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
    }

    .meta-info .label {
        font-size: 0.75rem;
        color: var(--text-secondary);
    }

    .schedule-description {
        font-size: 0.9rem;
        color: var(--text-secondary);
        padding: 0.75rem;
        background: #f8fafc;
        border-radius: 8px;
        margin-top: 0.5rem;
    }

    .schedule-actions {
        padding: 1rem 1.5rem;
        background: #fafafa;
        border-top: 1px solid var(--border-color);
        display: flex;
        gap: 0.5rem;
    }

    .action-btn {
        flex: 1;
        padding: 0.75rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.9rem;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.35rem;
        text-decoration: none;
        transition: all 0.2s;
        border: none;
        cursor: pointer;
    }

    .action-btn.view {
        background: #f1f5f9;
        color: var(--text-primary);
    }

    .action-btn.edit {
        background: #e0f2fe;
        color: #0284c7;
    }

    .action-btn.delete {
        background: #fee2e2;
        color: #dc2626;
    }

    .action-btn:hover {
        transform: translateY(-1px);
    }

    /* Modal */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.6);
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .modal-container {
        background: white;
        border-radius: 20px;
        width: 90%;
        max-width: 800px;
        max-height: 90vh;
        overflow-y: auto;
        padding: 1.5rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    .item-card {
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 1rem;
        margin-bottom: 0.75rem;
        position: relative;
    }

    .item-grid {
        display: grid;
        grid-template-columns: 2fr 1fr 1fr;
        gap: 0.75rem;
    }

    .item-grid.row2 {
        grid-template-columns: 1fr 1fr 1fr;
        margin-top: 0.75rem;
    }
</style>
@endpush

@section('content')

<div x-data="{ 
    showCreateModal: false,
    viewMode: 'cards',
    items: [{id: 1, subject_id: '', exam_date: '', start_time: '', end_time: '', location: ''}],
    addItem() {
        this.items.push({
            id: Date.now(),
            subject_id: '',
            exam_date: '',
            start_time: '',
            end_time: '',
            location: ''
        });
    },
    removeItem(index) {
        if (this.items.length > 1) {
            this.items.splice(index, 1);
        } else {
            alert('يجب إضافة مادة واحدة على الأقل');
        }
    }
}">

    <!-- Page Header -->
    <div class="page-header d-flex justify-content-between align-items-center mb-4">
        <div>
            <h1 class="h3 mb-1 fw-bold">جداول الاختبارات</h1>
            <p class="text-muted">إدارة جداول اختبارات الدفعة</p>
        </div>
        @php $canCreate = Auth::user()->hasDelegatePermission('exams', 'create'); @endphp
        <button 
            @if($canCreate) @click="showCreateModal = true" @endif
            class="btn btn-danger px-4 py-2 rounded-3 fw-bold {{ !$canCreate ? 'btn-locked' : '' }}"
            @if(!$canCreate) title="ليس لديك صلاحية إنشاء جداول اختبارات" @endif
        >
            <i class="fa-solid fa-plus me-1"></i> إنشاء جدول جديد
        </button>
    </div>

    <!-- Stats Row -->
    <div class="row g-3 mb-4">
        <div class="col-md-4">
            <div class="stat-card">
                <div class="icon text-danger" style="background: rgba(239, 68, 68, 0.1);">
                    <i class="fa-solid fa-calendar-days"></i>
                </div>
                <div>
                    <div class="value">{{ $schedules->count() }}</div>
                    <div class="label">جدول اختبارات</div>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="stat-card">
                <div class="icon text-success" style="background: rgba(16, 185, 129, 0.1);">
                    <i class="fa-solid fa-check"></i>
                </div>
                <div>
                    <div class="value">{{ $schedules->where('is_published', true)->count() }}</div>
                    <div class="label">جدول منشور</div>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="stat-card">
                <div class="icon text-warning" style="background: rgba(245, 158, 11, 0.1);">
                    <i class="fa-solid fa-file-pen"></i>
                </div>
                <div>
                    <div class="value">{{ $schedules->where('is_published', false)->count() }}</div>
                    <div class="label">مسودة</div>
                </div>
            </div>
        </div>
    </div>

    @if($schedules->isEmpty())
    <div class="card border-0 shadow-sm rounded-4 p-5 text-center">
        <div class="mb-3">
            <i class="fa-solid fa-calendar-xmark text-muted" style="font-size: 4rem; opacity: 0.3;"></i>
        </div>
        <h3 class="h5 fw-bold mb-2">لا توجد جداول اختبارات</h3>
        <p class="text-muted mb-4">ابدأ بإنشاء جدول اختبارات جديد للدفعة</p>
        <button @click="showCreateModal = true" class="btn btn-danger px-4 py-2 rounded-3">إنشاء أول جدول</button>
    </div>
    @else

    <div class="d-flex justify-content-end mb-4">
        <div class="btn-group bg-white p-1 rounded-3 border shadow-sm">
            <button @click="viewMode = 'cards'" class="btn btn-sm px-3" :class="viewMode === 'cards' ? 'btn-danger' : 'btn-light text-muted'">
                <i class="fa-solid fa-grip me-1"></i> بطاقات
            </button>
            <button @click="viewMode = 'calendar'" class="btn btn-sm px-3" :class="viewMode === 'calendar' ? 'btn-danger' : 'btn-light text-muted'">
                <i class="fa-solid fa-list me-1"></i> قائمة التواريخ
            </button>
        </div>
    </div>

    <!-- Cards View -->
    <div class="row g-4" x-show="viewMode === 'cards'">
        @foreach($schedules as $schedule)
        <div class="col-md-6 col-lg-4">
            <div class="schedule-card">
                <div class="schedule-header">
                    <div>
                        <div class="schedule-title">{{ $schedule->title }}</div>
                        <div class="schedule-term">{{ $schedule->term->name ?? '-' }}</div>
                    </div>
                    <div class="d-flex flex-column align-items-end gap-2">
                        <span class="schedule-status {{ $schedule->is_published ? 'published' : 'draft' }}">
                            {{ $schedule->is_published ? 'منشور' : 'مسودة' }}
                        </span>
                        @if($schedule->creator && in_array($schedule->creator->role->value, ['admin', 'administrative']))
                        <span class="official-badge">
                            <i class="fa-solid fa-shield-check"></i> رسمي
                        </span>
                        @endif
                    </div>
                </div>

                <div class="schedule-body">
                    <div class="row g-3 mb-3">
                        <div class="col-6">
                            <div class="d-flex align-items-center gap-2">
                                <div class="meta-icon" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
                                    <i class="fa-solid fa-book-open"></i>
                                </div>
                                <div>
                                    <div class="fw-bold">{{ $schedule->items_count ?? $schedule->items()->count() }}</div>
                                    <div class="small text-muted">مادة</div>
                                </div>
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="d-flex align-items-center gap-2">
                                <div class="meta-icon" style="background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">
                                    <i class="fa-solid fa-clock-rotate-left"></i>
                                </div>
                                <div>
                                    <div class="fw-bold">{{ $schedule->created_at->format('d/m') }}</div>
                                    <div class="small text-muted">تاريخ الإنشاء</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    @if($schedule->description)
                    <p class="text-muted small mb-0 p-2 rounded-2 bg-light">{{ Str::limit($schedule->description, 80) }}</p>
                    @endif
                </div>

                <div class="schedule-actions">
                    <a href="{{ route('delegate.exams.show', $schedule->id) }}" class="action-btn view bg-light">
                        <i class="fa-solid fa-eye me-1"></i> عرض
                    </a>
                    @if(!$schedule->creator || !in_array($schedule->creator->role->value, ['admin', 'administrative']))
                    @php $canUpdate = Auth::user()->hasDelegatePermission('exams', 'update'); @endphp
                    <a 
                        @if($canUpdate) href="{{ route('delegate.exams.edit', $schedule->id) }}" @endif
                        class="action-btn edit {{ !$canUpdate ? 'btn-locked' : '' }}" 
                        style="background: #e0f2fe; color: #0284c7;"
                        title="{{ $canUpdate ? 'تعديل' : 'ليس لديك صلاحية التعديل' }}"
                    >
                        <i class="fa-solid fa-pen-to-square me-1"></i> تعديل
                    </a>

                    @php $canDelete = Auth::user()->hasDelegatePermission('exams', 'delete'); @endphp
                    <form action="{{ route('delegate.exams.destroy', $schedule->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من الحذف؟');" class="flex-fill">
                        @csrf
                        @method('DELETE')
                        <button type="{{ $canDelete ? 'submit' : 'button' }}" class="action-btn delete w-100 {{ !$canDelete ? 'btn-locked' : '' }}" title="{{ $canDelete ? 'حذف' : 'ليس لديك صلاحية الحذف' }}">
                            <i class="fa-solid fa-trash me-1"></i> حذف
                        </button>
                    </form>
                    @endif
                </div>
            </div>
        </div>
        @endforeach
    </div>

    <!-- List View -->
    <div x-show="viewMode === 'calendar'" style="display: none;">
        <div class="card border-0 shadow-sm rounded-4 overflow-hidden">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="bg-light">
                        <tr>
                            <th class="px-4">التاريخ</th>
                            <th>المادة</th>
                            <th>الوقت</th>
                            <th>القاعة</th>
                            <th class="text-end px-4">الجدول</th>
                        </tr>
                    </thead>
                    <tbody>
                        @php
                        $allItems = collect();
                        foreach($schedules as $sched) {
                            foreach($sched->items as $item) {
                                $item->parent_schedule = $sched;
                                $allItems->push($item);
                            }
                        }
                        $allItems = $allItems->sortBy('exam_date');
                        @endphp

                        @forelse($allItems as $item)
                        <tr>
                            <td class="px-4">
                                <div class="fw-bold text-primary">
                                    <i class="fa-solid fa-calendar-day me-1"></i> {{ \Carbon\Carbon::parse($item->exam_date)->translatedFormat('l, d F Y') }}
                                </div>
                            </td>
                            <td class="fw-bold">{{ $item->subject->name ?? '-' }}</td>
                            <td>
                                <span class="badge bg-light text-dark border px-3 py-2">
                                    {{ \Carbon\Carbon::parse($item->start_time)->format('h:i A') }} - {{ \Carbon\Carbon::parse($item->end_time)->format('h:i A') }}
                                </span>
                            </td>
                            <td class="text-muted">{{ $item->location ?? 'غير محدد' }}</td>
                            <td class="text-end px-4">
                                <a href="{{ route('delegate.exams.show', $item->parent_schedule->id) }}" class="text-decoration-none fw-bold small">
                                    {{ Str::limit($item->parent_schedule->title, 20) }}
                                    @if($item->parent_schedule->creator && in_array($item->parent_schedule->creator->role->value, ['admin', 'administrative']))
                                    <i class="fa-solid fa-shield-check text-info ms-1" title="جدول رسمي"></i>
                                    @endif
                                </a>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="5" class="text-center py-5 text-muted">لا توجد مواد مجدولة حالياً.</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    @endif

    <!-- Create Modal -->
    <div x-show="showCreateModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container shadow-lg" @click.away="showCreateModal = false">
            <div class="d-flex justify-content-between align-items-center mb-4 pb-3 border-bottom">
                <h3 class="h5 fw-bold mb-0 text-danger">
                    <i class="fa-solid fa-calendar-plus me-1"></i> إنشاء جدول اختبارات جديد
                </h3>
                <button @click="showCreateModal = false" class="btn-close shadow-none"></button>
            </div>

            <form action="{{ route('delegate.exams.store') }}" method="POST">
                @csrf

                <div class="mb-3">
                    <label class="form-label fw-bold small">عنوان الجدول <span class="text-danger">*</span></label>
                    <input type="text" name="title" class="form-control shadow-sm" placeholder="مثال: جدول الاختبارات النهائية" required list="title_suggestions">
                    <datalist id="title_suggestions">
                        <option value="جدول الاختبارات النهائية">
                        <option value="جدول الاختبارات النصفية">
                        <option value="جدول اختبارات الدور الثاني">
                    </datalist>
                </div>

                <div class="row g-3 mb-3">
                    <div class="col-md-6">
                        <label class="form-label fw-bold small">الفصل الدراسي <span class="text-danger">*</span></label>
                        <select name="term_id" class="form-select shadow-sm" required>
                            <option value="">اختر الفصل...</option>
                            @foreach($terms as $term)
                            <option value="{{ $term->id }}">{{ $term->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-6 d-flex align-items-end pb-2">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="is_published" value="1" id="publishCheck">
                            <label class="form-check-label fw-bold small cursor-pointer" for="publishCheck">
                                نشر الجدول للطلاب فوراً
                            </label>
                        </div>
                    </div>
                </div>

                <div class="mb-4">
                    <label class="form-label fw-bold small">ملاحظات</label>
                    <textarea name="description" class="form-control shadow-sm" rows="2" placeholder="أي تعليمات إضافية..."></textarea>
                </div>

                <div class="rounded-4 p-3 bg-light border mb-4">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h4 class="h6 fw-bold mb-0">📚 المواد الدراسية</h4>
                        <button type="button" @click="addItem()" class="btn btn-sm btn-outline-primary px-3 fw-bold">+ إضافة مادة</button>
                    </div>

                    <div style="max-height: 400px; overflow-y: auto;">
                        <template x-for="(item, index) in items" :key="item.id">
                            <div class="card border-0 shadow-sm rounded-3 mb-3">
                                <div class="card-body">
                                    <div class="d-flex justify-content-end mb-2">
                                        <button type="button" @click="removeItem(index)" class="btn-close btn-sm" style="font-size: 0.7rem;"></button>
                                    </div>
                                    <div class="row g-2">
                                        <div class="col-md-4">
                                            <label class="small fw-bold mb-1">المادة</label>
                                            <select :name="'items[' + index + '][subject_id]'" class="form-select form-select-sm" required>
                                                <option value="">اختر المادة...</option>
                                                @foreach($subjects as $subject)
                                                <option value="{{ $subject->id }}">{{ $subject->name }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <label class="small fw-bold mb-1">التاريخ</label>
                                            <input type="date" :name="'items[' + index + '][exam_date]'" class="form-control form-control-sm" required>
                                        </div>
                                        <div class="col-md-4 text-center d-flex flex-column">
                                            <label class="small fw-bold mb-1">القاعة</label>
                                            <input type="text" :name="'items[' + index + '][location]'" class="form-control form-control-sm" placeholder="اختياري">
                                        </div>
                                    </div>
                                    <div class="row g-2 mt-2">
                                        <div class="col-6">
                                            <label class="small fw-bold mb-1">تبدأ الساعة</label>
                                            <input type="time" :name="'items[' + index + '][start_time]'" class="form-control form-control-sm" required>
                                        </div>
                                        <div class="col-6">
                                            <label class="small fw-bold mb-1">تنتهي الساعة</label>
                                            <input type="time" :name="'items[' + index + '][end_time]'" class="form-control form-control-sm" required>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </template>
                    </div>
                </div>

                <div class="d-flex gap-2 justify-content-end">
                    <button type="button" class="btn btn-light px-4" @click="showCreateModal = false">إلغاء</button>
                    <button type="submit" class="btn btn-danger px-4">حفظ الجدول</button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection