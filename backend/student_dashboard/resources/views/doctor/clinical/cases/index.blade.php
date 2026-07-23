@php
    $layout = 'layouts.doctor';
    if (request()->is('delegate/*')) $layout = 'layouts.delegate';
    elseif (request()->is('student/*')) $layout = 'layouts.student';
@endphp
@extends($layout)

@section('title', 'قائمة الحالات المرضية')

@section('content')
<style>
    .assignments-trigger {
        display: flex;
        align-items: center;
        gap: 6px;
        font-weight: 800;
        cursor: pointer;
        padding: 4px 8px;
        border-radius: 8px;
        transition: all 0.2s;
        border: 1px solid transparent;
    }

    .assignments-trigger:hover {
        background: rgba(37, 99, 235, 0.05);
        border-color: rgba(37, 99, 235, 0.1);
    }
    
    .assignments-trigger.active {
        background: rgba(37, 99, 235, 0.1);
        border-color: rgba(37, 99, 235, 0.2);
    }
    
    .modal-overlay {
        backdrop-filter: blur(4px);
    }
    
    .modal-container {
        animation: modalSlideUp 0.3s ease-out;
    }
    
    @keyframes modalSlideUp {
        from { transform: translateY(20px); opacity: 0; }
        to { transform: translateY(0); opacity: 1; }
    }

    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.6rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.15rem 0;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        margin: 0;
    }

    .clinical-page-header .left-side {
        display: flex;
        gap: 0.75rem;
        align-items: center;
    }

    .btn-back {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1.1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    .btn-primary-action {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.6rem 1.3rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        cursor: pointer;
        transition: all 0.25s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.25);
    }

    .btn-primary-action:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.35);
        color: white;
        text-decoration: none;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
    }

    /* --- Filters --- */
    .filter-bar {
        background: linear-gradient(135deg, #f8fafc, #f1f5f9);
        padding: 1.25rem;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        margin-bottom: 1.5rem;
    }

    .filter-bar .filter-title {
        font-size: 0.85rem;
        font-weight: 700;
        color: var(--text-secondary);
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.4rem;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    .filter-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 0.85rem;
        align-items: end;
    }

    .filter-group label {
        display: block;
        font-size: 0.8rem;
        font-weight: 600;
        color: #64748b;
        margin-bottom: 0.35rem;
    }

    .filter-group input,
    .filter-group select {
        width: 100%;
        padding: 0.55rem 0.75rem;
        font-size: 0.88rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 9px;
        background: white;
        transition: all 0.2s;
        font-family: inherit;
    }

    .filter-group input:focus,
    .filter-group select:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.08);
    }

    .filter-actions {
        display: flex;
        gap: 0.5rem;
        align-items: flex-end;
    }

    .btn-filter {
        background: var(--primary-color);
        color: white;
        border: none;
        padding: 0.55rem 1.25rem;
        border-radius: 9px;
        font-weight: 600;
        font-size: 0.85rem;
        cursor: pointer;
        transition: all 0.2s;
        white-space: nowrap;
    }

    .btn-filter:hover {
        background: #4338ca;
    }

    .btn-filter-reset {
        background: white;
        color: #64748b;
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1rem;
        border-radius: 9px;
        font-weight: 600;
        font-size: 0.85rem;
        text-decoration: none;
        transition: all 0.2s;
        white-space: nowrap;
        display: inline-flex;
        align-items: center;
    }

    .btn-filter-reset:hover {
        background: #f8fafc;
        border-color: #cbd5e1;
        color: var(--text-primary);
        text-decoration: none;
    }

    /* --- Table --- */
    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.25rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .section-title {
        font-size: 1rem;
        font-weight: 700;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .table-modern {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .table-modern th {
        background: #f8fafc;
        font-weight: 600;
        color: var(--text-secondary);
        padding: 0.85rem 1rem;
        text-align: right;
        font-size: 0.82rem;
        border-bottom: 2px solid #e2e8f0;
    }

    .table-modern td {
        padding: 0.85rem 1rem;
        vertical-align: middle;
        border-bottom: 1px solid #f1f5f9;
        font-size: 0.9rem;
        color: var(--text-primary);
    }

    .table-modern tr:hover td {
        background: #fafbfe;
    }

    .table-modern tr:last-child td {
        border-bottom: none;
    }

    .patient-name {
        font-weight: 700;
        color: var(--primary-color);
    }

    .badge-status {
        padding: 0.25rem 0.55rem;
        border-radius: 6px;
        font-weight: 700;
        font-size: 0.78rem;
    }

    .badge-status.active {
        background: #d1fae5;
        color: #065f46;
    }

    .badge-status.discharged {
        background: #f1f5f9;
        color: #475569;
    }

    .badge-status.transferred {
        background: #fef3c7;
        color: #92400e;
    }

    .badge-system {
        background: #e0e7ff;
        color: #4338ca;
        padding: 0.2rem 0.5rem;
        border-radius: 5px;
        font-size: 0.78rem;
        font-weight: 600;
    }

    .badge-doctor {
        background: #f0fdf4;
        color: #166534;
        padding: 0.2rem 0.5rem;
        border-radius: 5px;
        font-size: 0.78rem;
        font-weight: 600;
    }

    .action-btn {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        margin-left: 0.2rem;
        text-decoration: none;
    }

    .action-btn.edit {
        background: #eff6ff;
        color: #3b82f6;
    }

    .action-btn.edit:hover {
        background: #dbeafe;
        color: #2563eb;
    }

    .action-btn.delete {
        background: #fef2f2;
        color: #ef4444;
    }

    .action-btn.delete:hover {
        background: #fee2e2;
        color: #dc2626;
    }

    .alert-banner {
        padding: 0.85rem 1.25rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .alert-banner.success {
        background: #d1fae5;
        color: #065f46;
        border: 1px solid #6ee7b7;
    }
</style>

<div x-data="{ 
    showAssignmentsModal: false, 
    selectedCaseName: '',
    selectedAssignments: [],
    showRejectModal: false,
    caseToReject: null,
    rejectionReason: '',
    openAssignments(caseName, assignments) {
        this.selectedCaseName = caseName;
        this.selectedAssignments = assignments;
        this.showAssignmentsModal = true;
    },
    openRejectModal(caseId) {
        this.caseToReject = caseId;
        this.rejectionReason = '';
        this.showRejectModal = true;
    }
}">
    {{-- ====== Page Header ====== --}}
    <div class="clinical-page-header">
        <div class="right-side">
            <h1>الحالات المرضية 🛏️</h1>
            <p>إدارة وتشخيص الحالات السريرية في مراكز التدريب</p>
        </div>
        @php
            $routePrefix = request()->is('student/*') ? 'student' : (request()->is('delegate/*') ? 'delegate' : 'doctor');
        @endphp
        <div class="left-side">
            <a href="{{ route($routePrefix . '.clinical.cases.create') }}" class="btn-primary-action">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                إدراج حالة جديدة
            </a>
            <a href="{{ route('doctor.clinical.index') }}" class="btn-back">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="15 18 9 12 15 6"></polyline>
                </svg>
                القسم العملي
            </a>
        </div>
    </div>

    @if(session('success'))
    <div class="alert-banner success">✅ {{ session('success') }}</div>
    @endif

    {{-- ====== Filter Bar ====== --}}
    <div class="filter-bar">
        <div class="filter-title">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"></polygon>
            </svg>
            تصفية وبحث
        </div>
        <form action="{{ route($routePrefix . '.clinical.cases.index') }}" method="GET">
            <div class="filter-grid">
                <div class="filter-group">
                    <label>اسم المريض</label>
                    <input type="text" name="patient_name" value="{{ request('patient_name') }}" placeholder="ابحث بالاسم...">
                </div>
                <div class="filter-group">
                    <label>المركز (المستشفى)</label>
                    <select name="training_center_id" class="select2">
                        <option value="">الكل</option>
                        @foreach($centers as $center)
                        <option value="{{ $center->id }}" {{ request('training_center_id') == $center->id ? 'selected' : '' }}>{{ $center->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="filter-group">
                    <label>القسم الطبي</label>
                    <select name="clinical_department_id" class="select2">
                        <option value="">الكل</option>
                        @foreach($departments as $dept)
                        <option value="{{ $dept->id }}" {{ request('clinical_department_id') == $dept->id ? 'selected' : '' }}>{{ $dept->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="filter-group">
                    <label>الجهاز المرضي</label>
                    <select name="body_system_id" class="select2">
                        <option value="">الكل</option>
                        @foreach($systems as $sys)
                        <option value="{{ $sys->id }}" {{ request('body_system_id') == $sys->id ? 'selected' : '' }}>{{ $sys->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="filter-actions">
                    <button type="submit" class="btn-filter">بحث</button>
                    <a href="{{ route($routePrefix . '.clinical.cases.index') }}" class="btn-filter-reset">إعادة ضبط</a>
                </div>
            </div>
        </form>
    </div>

    {{-- ====== Table ====== --}}
    <div class="card-section">
        <div class="section-header">
            <h3 class="section-title">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
                    <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
                </svg>
                سجل الحالات السريرية
            </h3>
        </div>

        <div style="overflow-x: auto;">
            <div class="table-responsive">
                <table class="table-modern">
                    <thead>
                        <tr>
                            <th width="5%">#</th>
                            <th width="15%">اسم الحالة/المريض</th>
                            <th width="8%">العمر/الجنس</th>
                            <th width="20%">المركز (القسم)</th>
                            <th width="12%">الجهاز المرضي</th>
                            <th width="15%">بواسطة</th>
                            <th width="10%">الموكلين</th>
                            <th width="10%">التاريخ</th>
                            <th width="5%">الحالة</th>
                            <th width="10%" style="text-align: center;">إجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($cases as $case)
                        <tr>
                            <td>{{ $loop->iteration + $cases->firstItem() - 1 }}</td>
                            <td class="patient-name">{{ $case->patient_name }}</td>
                            <td>
                                {{ $case->age ?? '-' }} <br>
                                <span style="font-size: 0.78rem; color: var(--text-secondary);">
                                    @if($case->gender == 'male') ذكر @elseif($case->gender == 'female') أنثى @else - @endif
                                </span>
                            </td>
                            <td>
                                <div style="font-weight: 600;">{{ $case->trainingCenter->name ?? '-' }}</div>
                                <div style="font-size: 0.78rem; color: var(--text-secondary);">{{ $case->clinicalDepartment->name ?? '-' }}</div>
                            </td>
                            <td><span class="badge-system">{{ $case->bodySystem->name ?? '-' }}</span></td>
                            <td>
                                <div class="badge-doctor" style="display: flex; flex-direction: column; gap: 2px; align-items: start; padding: 0.4rem 0.6rem;">
                                    <span style="font-weight: 700;">{{ $case->doctor->name ?? 'غير محدد' }}</span>
                                    @if($case->doctor)
                                        <span style="font-size: 0.65rem; opacity: 0.8; background: rgba(0,0,0,0.05); padding: 1px 5px; border-radius: 4px; font-weight: 500;">
                                            @if($case->doctor->role->value === 'doctor')
                                                👨‍🏫 دكتور
                                            @elseif($case->doctor->isClinicalDelegate())
                                                🎓 مندوب
                                            @else
                                                👨‍🎓 مندوب فرعي
                                            @endif
                                        </span>
                                    @endif
                                </div>
                            </td>
                            <td>
                                <div @click="openAssignments('{{ addslashes($case->patient_name) }}', {{ json_encode($case->assignments) }})" 
                                     class="assignments-trigger"
                                     :class="{ 'active': selectedCaseName === '{{ addslashes($case->patient_name) }}' }"
                                     style="color: {{ $case->assignments_count > 0 ? '#2563eb' : '#94a3b8' }};"
                                     title="انقر لعرض قائمة الطلاب">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                        <circle cx="9" cy="7" r="4"></circle>
                                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                                        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                                    </svg>
                                    <span style="font-size: 0.95rem;">{{ $case->assignments_count }}</span>
                                </div>
                            </td>
                            <td style="font-size: 0.82rem; color: var(--text-secondary);">{{ $case->created_at->format('Y-m-d') }}</td>
                            <td>
                                @if($case->status == 'active')
                                <span class="badge-status active">نشطة</span>
                                @elseif($case->status == 'discharged')
                                <span class="badge-status discharged">مُخلى</span>
                                @else
                                <span class="badge-status transferred">محول</span>
                                @endif
                            </td>
                            <td style="text-align: center; white-space: nowrap;">
                                {{-- Actions --}}

                                <a href="{{ route($routePrefix . '.clinical.cases.edit', $case->id) }}" class="action-btn edit" title="تعديل">
                                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                    </svg>
                                </a>
                                <form action="{{ route($routePrefix . '.clinical.cases.destroy', $case->id) }}" method="POST" style="display:inline;" onsubmit="return confirm('هل أنت متأكد من مسح الحالة؟')">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="action-btn delete" title="مسح">
                                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <polyline points="3 6 5 6 21 6"></polyline>
                                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                        </svg>
                                    </button>
                                </form>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="10" style="text-align: center; color: var(--text-secondary); padding: 3rem 1rem;">
                                <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" style="color: #cbd5e1; margin-bottom: 0.75rem;">
                                    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
                                    <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
                                </svg>
                                <p>لا توجد حالات سريرية مسجلة في النظام حالياً.</p>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Assignments Modal -->
    <div x-show="showAssignmentsModal" class="modal-overlay" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 9999; display: flex; align-items: center; justify-content: center; padding: 1rem;" x-transition.opacity>
        <div class="modal-container" @click.away="showAssignmentsModal = false" style="background: white; border-radius: 20px; width: 100%; max-width: 800px; max-height: 90vh; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1);">
            <div style="padding: 1.5rem; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; background: #f8fafc;">
                <div>
                    <h3 style="margin: 0; font-size: 1.2rem; font-weight: 800; color: var(--text-primary);">الطلاب الموكلون بالحالة</h3>
                    <p style="margin: 5px 0 0; font-size: 0.9rem; color: #6366f1; font-weight: 600;" x-text="selectedCaseName"></p>
                </div>
                <button @click="showAssignmentsModal = false" style="background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #64748b;">&times;</button>
            </div>
            
            <div style="padding: 1.5rem; overflow-y: auto; flex: 1;">
                <template x-if="selectedAssignments.length > 0">
                    <table style="width: 100%; border-collapse: collapse; min-width: 500px;">
                        <thead>
                            <tr style="border-bottom: 2px solid #f1f5f9;">
                                <th style="text-align: right; padding: 12px; font-size: 0.85rem; color: #64748b;">اسم الطالب</th>
                                <th style="text-align: right; padding: 12px; font-size: 0.85rem; color: #64748b;">التخصص / المستوى</th>
                                <th style="text-align: right; padding: 12px; font-size: 0.85rem; color: #64748b;">بواسطة الدكتور</th>
                                <th style="text-align: right; padding: 12px; font-size: 0.85rem; color: #64748b;">التاريخ</th>
                            </tr>
                        </thead>
                        <tbody>
                            <template x-for="assign in selectedAssignments" :key="assign.id">
                                <tr style="border-bottom: 1px solid #f8fafc;">
                                    <td style="padding: 12px;">
                                        <div style="font-weight: 700; color: var(--primary-color);" x-text="assign.student.name"></div>
                                        <div style="font-size: 0.75rem; color: #94a3b8;" x-text="assign.student.student_number || '#'"></div>
                                    </td>
                                    <td style="padding: 12px;">
                                        <div style="font-weight: 600;" x-text="assign.student.major.name"></div>
                                        <div style="font-size: 0.75rem; color: #64748b;" x-text="'المستوى ' + assign.student.level.name"></div>
                                    </td>
                                    <td style="padding: 12px;">
                                        <span style="background: #f0fdf4; color: #166534; padding: 3px 8px; border-radius: 5px; font-size: 0.8rem; font-weight: 600;" x-text="assign.assigner.name"></span>
                                    </td>
                                    <td style="padding: 12px; font-size: 0.85rem; color: #64748b;" x-text="new Date(assign.created_at).toLocaleDateString('ar-EG')"></td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </template>
                <template x-if="selectedAssignments.length === 0">
                    <div style="text-align: center; padding: 3rem; color: #94a3b8;">
                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 1rem; opacity: 0.5;">
                            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                            <circle cx="9" cy="7" r="4"></circle>
                        </svg>
                        <p>لا يوجد طلاب موكلون لهذه الحالة حالياً.</p>
                    </div>
                </template>
            </div>
            
            <div style="padding: 1.25rem; border-top: 1px solid #e2e8f0; text-align: left; background: #f8fafc;">
                <button @click="showAssignmentsModal = false" style="background: #64748b; color: white; border: none; padding: 0.6rem 1.5rem; border-radius: 10px; font-weight: 600; cursor: pointer;">إغلاق</button>
            </div>
        </div>
    </div>
    </div>
</div>
@endsection

@push('scripts')
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
<script>
    $(document).ready(function() {
        $('.select2').select2({
            dir: "rtl",
            width: '100%'
        });
    });
</script>
@endpush