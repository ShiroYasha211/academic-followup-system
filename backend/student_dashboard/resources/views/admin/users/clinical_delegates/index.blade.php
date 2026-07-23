@extends('layouts.admin')

@section('title', 'إدارة مندوبي العملي')

@section('content')
@php
    $levelsCount = $clinicalMajors->sum(fn($major) => $major->levels->count());
    $assignedLevelsCount = $clinicalMajors->sum(fn($major) => $major->levels->filter(fn($level) => $level->clinicalDelegates->isNotEmpty())->count());
    $delegatesCount = $clinicalMajors->sum(fn($major) => $major->levels->sum(fn($level) => $level->clinicalDelegates->count()));
@endphp

<style>
    .clinical-page-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .clinical-page-icon {
        width: 56px;
        height: 56px;
        border-radius: 16px;
        background: linear-gradient(135deg, #0f766e, #14b8a6);
        color: #fff;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 14px 30px rgba(20, 184, 166, 0.22);
    }

    .clinical-page-title h1 {
        margin: 0 0 0.25rem;
        font-size: 1.45rem;
        font-weight: 900;
        color: #0f172a;
    }

    .clinical-page-title p {
        margin: 0;
        color: #64748b;
        font-size: 0.9rem;
    }

    .stats-row {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .stat-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 1.1rem;
        display: flex;
        align-items: center;
        gap: 0.85rem;
    }

    .stat-card .icon {
        width: 44px;
        height: 44px;
        border-radius: 13px;
        display: grid;
        place-items: center;
        background: #ecfeff;
        color: #0891b2;
    }

    .stat-card strong {
        display: block;
        font-size: 1.55rem;
        line-height: 1;
        font-weight: 900;
        color: #0f172a;
    }

    .stat-card span {
        color: #64748b;
        font-size: 0.82rem;
        font-weight: 700;
    }

    .major-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 18px;
        margin-bottom: 1rem;
        overflow: hidden;
        box-shadow: 0 12px 34px rgba(15, 23, 42, 0.04);
    }

    .major-card-header {
        padding: 1.1rem 1.25rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
        background: linear-gradient(135deg, #f8fafc, #ffffff);
    }

    .major-card-header h3 {
        margin: 0 0 0.2rem;
        font-size: 1.05rem;
        font-weight: 900;
        color: #0f172a;
    }

    .major-card-header p {
        margin: 0;
        color: #64748b;
        font-size: 0.82rem;
    }

    .major-badge {
        flex: 0 0 auto;
        padding: 0.38rem 0.7rem;
        border-radius: 999px;
        background: #ecfdf5;
        color: #047857;
        font-size: 0.78rem;
        font-weight: 900;
    }

    .levels-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
        gap: 1rem;
        padding: 1rem;
    }

    .level-card {
        border: 1px solid #e2e8f0;
        border-radius: 15px;
        padding: 1rem;
        background: #fbfdff;
    }

    .level-head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 0.85rem;
    }

    .level-head h4 {
        margin: 0;
        font-size: 0.95rem;
        font-weight: 900;
        color: #1e293b;
    }

    .delegate-count {
        padding: 0.25rem 0.55rem;
        border-radius: 999px;
        background: #eef2ff;
        color: #4338ca;
        font-size: 0.72rem;
        font-weight: 900;
    }

    .delegate-list {
        display: grid;
        gap: 0.65rem;
        margin-bottom: 0.85rem;
    }

    .delegate-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.75rem;
        padding: 0.72rem;
        border-radius: 12px;
        background: #fff;
        border: 1px solid #e2e8f0;
    }

    .delegate-person {
        display: flex;
        align-items: center;
        gap: 0.65rem;
        min-width: 0;
    }

    .delegate-avatar {
        width: 36px;
        height: 36px;
        flex: 0 0 36px;
        border-radius: 50%;
        background: linear-gradient(135deg, #ccfbf1, #99f6e4);
        color: #0f766e;
        font-weight: 900;
        display: grid;
        place-items: center;
    }

    .delegate-person strong {
        display: block;
        color: #0f172a;
        font-size: 0.86rem;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .delegate-person small {
        display: block;
        color: #64748b;
        font-size: 0.75rem;
    }

    .btn-assign,
    .btn-remove {
        border: none;
        border-radius: 11px;
        font-size: 0.82rem;
        font-weight: 900;
        cursor: pointer;
    }

    .btn-assign {
        width: 100%;
        padding: 0.72rem;
        color: #fff;
        background: linear-gradient(135deg, #0f766e, #14b8a6);
    }

    .btn-remove {
        padding: 0.45rem 0.6rem;
        color: #dc2626;
        background: #fef2f2;
    }

    .empty-level {
        padding: 0.85rem;
        border-radius: 12px;
        background: #fffbeb;
        color: #92400e;
        font-size: 0.82rem;
        font-weight: 800;
        margin-bottom: 0.85rem;
    }

    @media (max-width: 760px) {
        .stats-row {
            grid-template-columns: 1fr;
        }

        .major-card-header {
            align-items: flex-start;
            flex-direction: column;
        }
    }
</style>

<div x-data="{
    showAssignModal: false,
    selectedMajorId: '',
    selectedLevelId: '',
    selectedMajorName: '',
    selectedLevelName: '',
    searchQuery: '',
    studentsByLevel: @js($studentsByMajor),
    get selectedKey() {
        return this.selectedMajorId + '-' + this.selectedLevelId;
    },
    get filteredStudents() {
        const students = this.studentsByLevel[this.selectedKey] || [];
        if (!this.searchQuery) return students;
        const q = this.searchQuery.toLowerCase();
        return students.filter((student) =>
            student.name.toLowerCase().includes(q) ||
            String(student.student_number || '').toLowerCase().includes(q)
        );
    },
    openModal(majorId, levelId, majorName, levelName) {
        this.selectedMajorId = String(majorId);
        this.selectedLevelId = String(levelId);
        this.selectedMajorName = majorName;
        this.selectedLevelName = levelName;
        this.searchQuery = '';
        this.showAssignModal = true;
    }
}">
    <div class="clinical-page-header">
        <div class="clinical-page-icon">
            <i class="fa-solid fa-user-nurse"></i>
        </div>
        <div class="clinical-page-title">
            <h1>إدارة مندوبي العملي</h1>
            <p>يمكن تعيين أكثر من مندوب عملي لكل تخصص ومستوى، دون استبدال المندوبين الحاليين.</p>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success" style="margin-bottom: 1rem;">{{ session('success') }}</div>
    @endif

    @if(session('error'))
        <div class="alert alert-danger" style="margin-bottom: 1rem;">{{ session('error') }}</div>
    @endif

    <div class="stats-row">
        <div class="stat-card">
            <div class="icon"><i class="fa-solid fa-layer-group"></i></div>
            <div>
                <strong>{{ number_format($levelsCount) }}</strong>
                <span>مستويات سريرية</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="icon"><i class="fa-solid fa-user-check"></i></div>
            <div>
                <strong>{{ number_format($delegatesCount) }}</strong>
                <span>إجمالي مندوبي العملي</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="icon"><i class="fa-solid fa-circle-check"></i></div>
            <div>
                <strong>{{ number_format($assignedLevelsCount) }}</strong>
                <span>مستويات لديها مناديب</span>
            </div>
        </div>
    </div>

    @forelse($clinicalMajors as $major)
        <section class="major-card">
            <div class="major-card-header">
                <div>
                    <h3>{{ $major->name }}</h3>
                    <p>{{ $major->college->name ?? '-' }} - {{ $major->college->university->name ?? '-' }}</p>
                </div>
                <span class="major-badge">{{ $major->levels->count() }} مستوى</span>
            </div>

            <div class="levels-grid">
                @forelse($major->levels as $level)
                    @php($delegates = $level->clinicalDelegates)
                    <div class="level-card">
                        <div class="level-head">
                            <h4>{{ $level->name }}</h4>
                            <span class="delegate-count">{{ $delegates->count() }} مندوب</span>
                        </div>

                        @if($delegates->isEmpty())
                            <div class="empty-level">لم يتم تعيين مندوب عملي لهذا المستوى بعد.</div>
                        @else
                            <div class="delegate-list">
                                @foreach($delegates as $delegate)
                                    <div class="delegate-row">
                                        <div class="delegate-person">
                                            <div class="delegate-avatar">{{ mb_substr($delegate->student->name ?? '؟', 0, 1) }}</div>
                                            <div>
                                                <strong>{{ $delegate->student->name ?? 'غير معروف' }}</strong>
                                                <small>{{ $delegate->student->student_number ?? '-' }}</small>
                                            </div>
                                        </div>
                                        <form action="{{ route('admin.clinical-delegates.destroy', $delegate) }}" method="POST" onsubmit="return confirm('هل تريد إلغاء تعيين هذا المندوب العملي؟')">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn-remove">إلغاء</button>
                                        </form>
                                    </div>
                                @endforeach
                            </div>
                        @endif

                        <button type="button" class="btn-assign" @click="openModal('{{ $major->id }}', '{{ $level->id }}', @js($major->name), @js($level->name))">
                            <i class="fa-solid fa-plus"></i>
                            إضافة مندوب عملي لهذا المستوى
                        </button>
                    </div>
                @empty
                    <div class="empty-level">لا توجد مستويات داخل هذا التخصص.</div>
                @endforelse
            </div>
        </section>
    @empty
        <div class="major-card" style="padding: 2rem; text-align: center; color: #64748b;">
            لا توجد تخصصات مفعلة للتدريب العملي. فعّل خيار التدريب العملي من إدارة التخصصات أولًا.
        </div>
    @endforelse

    <div x-show="showAssignModal" class="modal-overlay" style="display: none;" x-transition.opacity.duration.200ms>
        <div class="modal-container" @click.away="showAssignModal = false" style="max-width: 520px;">
            <div class="modal-icon" style="background: #ecfdf5; color: #0f766e;">
                <i class="fa-solid fa-user-plus" style="font-size: 1.6rem;"></i>
            </div>
            <h3 class="modal-title">إضافة مندوب عملي</h3>
            <p class="modal-message">
                اختر طالبًا من <strong x-text="selectedMajorName"></strong> - <strong x-text="selectedLevelName"></strong>.
            </p>

            <form action="{{ route('admin.clinical-delegates.store') }}" method="POST">
                @csrf
                <input type="hidden" name="major_id" :value="selectedMajorId">
                <input type="hidden" name="level_id" :value="selectedLevelId">

                <div class="form-group" style="margin-top: 1rem;">
                    <label class="form-label">البحث عن طالب</label>
                    <input type="text" x-model="searchQuery" class="form-control" placeholder="اكتب الاسم أو رقم القيد...">
                </div>

                <div class="form-group">
                    <label class="form-label">الطالب</label>
                    <select name="student_id" class="form-control" required>
                        <option value="">-- اختر طالب --</option>
                        <template x-for="student in filteredStudents" :key="student.id">
                            <option :value="student.id" x-text="student.name + ' (' + (student.student_number || '-') + ')'"></option>
                        </template>
                    </select>
                    <template x-if="filteredStudents.length === 0">
                        <small style="color: #dc2626; margin-top: 0.35rem; display: block;">لا توجد نتائج مطابقة داخل هذا التخصص والمستوى.</small>
                    </template>
                </div>

                <div class="modal-actions" style="margin-top: 1.5rem;">
                    <button type="button" class="btn btn-secondary" @click="showAssignModal = false">إلغاء</button>
                    <button type="submit" class="btn btn-primary" :disabled="filteredStudents.length === 0">إضافة المندوب</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
