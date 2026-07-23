@extends('layouts.administrative')

@section('title', 'إدارة الطلاب - ' . $college->name)

@section('content')

<style>
    .page-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .page-header-icon {
        width: 56px;
        height: 56px;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
    }

    .page-header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .page-header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .stats-row {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1.5rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1.25rem;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
    }

    .stat-card:hover {
        transform: translateY(-5px);
        box-shadow: var(--shadow-md);
    }

    .stat-icon {
        width: 56px;
        height: 56px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
    }

    .stat-icon.green { background: rgba(16, 185, 129, 0.1); color: #10b981; }
    .stat-icon.blue { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }
    .stat-icon.purple { background: rgba(139, 92, 246, 0.1); color: #8b5cf6; }

    .stat-info h3 {
        font-size: 1.8rem;
        font-weight: 800;
        line-height: 1;
        margin-bottom: 0.4rem;
        color: var(--text-primary);
    }

    .stat-info p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        font-weight: 500;
    }

    .form-card {
        background: white;
        border-radius: 24px;
        border: 1px solid var(--border-color);
        padding: 2rem;
        box-shadow: var(--shadow-sm);
    }

    .form-card-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
        padding-bottom: 1.25rem;
        border-bottom: 1px solid var(--border-color);
    }

    .form-card-header .icon {
        width: 44px;
        height: 44px;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .form-card-header h3 {
        font-size: 1.25rem;
        font-weight: 700;
        margin: 0;
    }

    .input-with-icon {
        position: relative;
    }

    .input-with-icon .icon {
        position: absolute;
        right: 14px;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-light);
        display: flex;
        align-items: center;
    }

    .input-with-icon input,
    .input-with-icon select {
        padding-right: 2.75rem;
        border-radius: 12px;
        border: 2px solid #f1f5f9;
        transition: all 0.3s;
    }

    .input-with-icon input:focus,
    .input-with-icon select:focus {
        border-color: #10b981;
        box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.1);
    }

    .table-card {
        background: white;
        border-radius: 24px;
        border: 1px solid var(--border-color);
        padding: 2rem;
        box-shadow: var(--shadow-sm);
    }

    .table-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .table-card-header h3 {
        font-size: 1.25rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin: 0;
    }

    .count-badge {
        background: #f0fdf4;
        color: #166534;
        padding: 0.5rem 1rem;
        border-radius: 12px;
        font-size: 0.9rem;
        font-weight: 700;
        border: 1px solid #dcfce7;
    }

    .modern-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .modern-table thead th {
        background: #f8fafc;
        padding: 1.25rem 1rem;
        text-align: right;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        text-transform: uppercase;
        letter-spacing: 0.025em;
        border-bottom: 2px solid #f1f5f9;
    }

    .modern-table tbody td {
        padding: 1.25rem 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
        transition: all 0.2s;
    }

    .modern-table tbody tr:hover td {
        background: #fbfcfe;
    }

    .modern-table tbody tr:last-child td {
        border-bottom: none;
    }

    .action-btn {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        color: white;
    }

    .action-btn.view { background: #64748b; }
    .action-btn.edit { background: #3b82f6; }
    .action-btn.delete { background: #ef4444; }

    .action-btn:hover { transform: translateY(-2px); filter: brightness(1.1); }

    .btn-submit {
        width: 100%;
        padding: 1rem;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        border: none;
        border-radius: 14px;
        font-size: 1.1rem;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.3s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.75rem;
        box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.2);
    }

    .btn-submit:hover {
        transform: translateY(-2px);
        box-shadow: 0 20px 25px -5px rgba(16, 185, 129, 0.3);
    }

    .student-avatar {
        width: 48px;
        height: 48px;
        background: linear-gradient(135deg, #d1fae5, #a7f3d0);
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.1rem;
        font-weight: 800;
        color: #059669;
        box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);
    }

    .student-number {
        font-family: 'JetBrains Mono', monospace;
        background: #f8fafc;
        color: #475569;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
        font-size: 0.85rem;
        font-weight: 700;
        border: 1px solid #e2e8f0;
    }

    .badge-delegate {
        background: #fffbeb;
        color: #d97706;
        padding: 0.25rem 0.6rem;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 700;
        border: 1px solid #fef3c7;
        margin-right: 0.5rem;
    }
</style>

<div x-data="{ 
    showDeleteModal: false, 
    showEditModal: false,
    showDetailsModal: false,
    deleteUrl: '', 
    modalTitle: '', 
    modalMessage: '',
    
    editUrl: '',
    editName: '',
    editEmail: '',
    editStudentNumber: '',
    editLevelId: '',
    editGender: 'male',
    
    viewStudent: {},
    viewSubjects: [],
    viewDelegate: null
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة الطلاب</h1>
            <p>تثبيت وإدارة بيانات طلاب {{ $college->name }}</p>
        </div>
    </div>

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-card">
            <div class="stat-icon green">
                <i class="fas fa-users"></i>
            </div>
            <div class="stat-info">
                <h3>{{ $students->total() }}</h3>
                <p>إجمالي الطلاب</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue">
                <i class="fas fa-graduation-cap"></i>
            </div>
            <div class="stat-info">
                <h3>{{ $majors->count() }}</h3>
                <p>التخصصات بالكلية</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon purple">
                <i class="fas fa-user-shield"></i>
            </div>
            <div class="stat-info">
                <h3>{{ $students->where('role', \App\Enums\UserRole::DELEGATE)->count() }}</h3>
                <p>المندوبين</p>
            </div>
        </div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 2.5fr; gap: 2rem; align-items: start;">

        <!-- Create Form -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="icon">
                    <i class="fas fa-plus"></i>
                </div>
                <h3>تسجيل طالب جديد</h3>
            </div>

            <form action="{{ route('administrative.students.store') }}" method="POST">
                @csrf

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">التخصص والمستوى</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-layer-group"></i></span>
                        <select name="level_id" id="level_id" class="form-control" required>
                            <option value="">اختر التخصص والمستوى...</option>
                            @foreach($majors as $major)
                            <optgroup label="{{ $major->name }}">
                                @foreach($major->levels as $level)
                                <option value="{{ $level->id }}" {{ old('level_id') == $level->id ? 'selected' : '' }}>
                                    {{ $level->name }}
                                </option>
                                @endforeach
                            </optgroup>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">الاسم الكامل</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-user"></i></span>
                        <input type="text" name="name" class="form-control" placeholder="اسم الطالب الرباعي..." value="{{ old('name') }}" required>
                    </div>
                </div>

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">الرقم الجامعي</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-id-card"></i></span>
                        <input type="text" name="student_number" class="form-control" placeholder="مثال: 44100123" value="{{ old('student_number') }}" required>
                    </div>
                </div>

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">البريد الإلكتروني</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-envelope"></i></span>
                        <input type="email" name="email" class="form-control" placeholder="name@college.edu" value="{{ old('email') }}" required>
                    </div>
                </div>

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">الجنس</label>
                    <select name="gender" class="form-control" required>
                        <option value="male">ذكر</option>
                        <option value="female">أنثى</option>
                    </select>
                </div>

                <div class="form-group mb-5">
                    <label class="form-label font-weight-bold mb-2">كلمة المرور</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-lock"></i></span>
                        <input type="password" name="password" class="form-control" placeholder="8 أحرف على الأقل..." required>
                    </div>
                </div>

                <button type="submit" class="btn-submit">
                    <i class="fas fa-check-circle"></i>
                    <span>تأكيد التسجيل</span>
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3>
                    <i class="fas fa-list-ul" style="color: var(--primary-color);"></i>
                    قائمة الطلاب المسجلين
                </h3>
                <span class="count-badge">{{ $students->total() }} طالب منضم</span>
            </div>

            <div class="table-responsive">
                <table class="modern-table">
                    <thead>
                        <tr>
                            <th>الطالب</th>
                            <th>الرقم الجامعي</th>
                            <th>الجنس</th>
                            <th>التخصص / المستوى</th>
                            <th style="width: 150px;">الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($students as $student)
                        <tr>
                            <td>
                                <div style="display: flex; align-items: center; gap: 1rem;">
                                    <div class="student-avatar">{{ mb_substr($student->name, 0, 1) }}</div>
                                    <div>
                                        <div style="font-weight: 700; color: #1e293b;">
                                            {{ $student->name }}
                                            @if($student->role === \App\Enums\UserRole::DELEGATE)
                                                <span class="badge-delegate">مندوب</span>
                                            @endif
                                        </div>
                                        <div style="font-size: 0.8rem; color: #64748b;">{{ $student->email }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <span class="student-number">{{ $student->student_number }}</span>
                            </td>
                            <td>
                                <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.35rem 0.75rem; border-radius: 999px; background: {{ $student->gender === 'female' ? '#fdf2f8' : '#eff6ff' }}; color: {{ $student->gender === 'female' ? '#db2777' : '#2563eb' }}; font-size: 0.8rem; font-weight: 700;">
                                    {{ $student->gender === 'female' ? 'أنثى' : 'ذكر' }}
                                </span>
                            </td>
                            <td>
                                <div style="font-weight: 700; color: #334155;">{{ $student->major->name ?? '-' }}</div>
                                <div style="font-size: 0.8rem; color: #64748b;">{{ $student->level->name ?? '-' }}</div>
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.4rem;">
                                    <button @click="
                                        showDetailsModal = true;
                                        viewStudent = {
                                            name: '{{ $student->name }}',
                                        email: '{{ $student->email }}',
                                        student_number: '{{ $student->student_number }}',
                                        level: '{{ $student->level->name ?? '-' }}',
                                        major: '{{ $student->major->name ?? '-' }}'
                                    };
                                        viewSubjects = {{ json_encode($student->level ? $student->level->terms->flatMap->subjects->map(function($s) {
                                            return [
                                                'name' => $s->name,
                                                'code' => $s->code,
                                                'doctor' => $s->doctor ? $s->doctor->name : 'غير محدد',
                                                'term' => $s->term->name
                                            ];
                                        }) : []) }};
                                    " class="action-btn view" title="تفاصيل">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                    
                                    <button @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل بيانات: {{ $student->name }}';
                                        editUrl = '{{ route('administrative.students.update', $student) }}';
                                        editName = '{{ $student->name }}';
                                        editEmail = '{{ $student->email }}';
                                        editStudentNumber = '{{ $student->student_number }}';
                                        editLevelId = '{{ $student->level_id }}';
                                        editGender = '{{ $student->gender ?? 'male' }}';
                                    " class="action-btn edit" title="تعديل">
                                        <i class="fas fa-edit"></i>
                                    </button>

                                    <button @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('administrative.students.destroy', $student) }}';
                                        modalTitle = 'حذف الطالب: {{ $student->name }}';
                                        modalMessage = 'سيتم حذف حساب الطالب وجميع بياناته المرتبطة. هل أنت متأكد؟';
                                    " class="action-btn delete" title="حذف">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>

                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" style="text-align: center; padding: 4rem;">
                                <img src="{{ asset('img/empty.svg') }}" alt="" style="width: 120px; opacity: 0.2; margin-bottom: 1rem;">
                                <div style="color: #94a3b8; font-weight: 600;">لا يوجد طلاب مسجلين في الكلية حالياً</div>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div style="margin-top: 2rem;">
                {{ $students->links() }}
            </div>
        </div>
    </div>

    <!-- Modals -->
    <x-delete-modal />

    <x-edit-modal>
        <form :action="editUrl" method="POST">
            @csrf
            @method('PUT')

            <div class="form-group mb-3">
                <label class="form-label">التخصص والمستوى</label>
                <select name="level_id" class="form-control" x-model="editLevelId" required>
                    <option value="">اختر التخصص والمستوى...</option>
                    @foreach($majors as $major)
                    <optgroup label="{{ $major->name }}">
                        @foreach($major->levels as $level)
                        <option value="{{ $level->id }}">{{ $level->name }}</option>
                        @endforeach
                    </optgroup>
                    @endforeach
                </select>
            </div>

            <div class="form-group mb-3">
                <label class="form-label">الاسم الكامل</label>
                <input type="text" name="name" class="form-control" x-model="editName" required>
            </div>

            <div class="form-group mb-3">
                <label class="form-label">الرقم الجامعي</label>
                <input type="text" name="student_number" class="form-control" x-model="editStudentNumber" required>
            </div>

            <div class="form-group mb-3">
                <label class="form-label">البريد الإلكتروني</label>
                <input type="email" name="email" class="form-control" x-model="editEmail" required>
            </div>

            <div class="form-group mb-3">
                <label class="form-label">الجنس</label>
                <select name="gender" class="form-control" x-model="editGender" required>
                    <option value="male">ذكر</option>
                    <option value="female">أنثى</option>
                </select>
            </div>

            <div class="form-group mb-4" style="background: #f8fafc; padding: 1rem; border-radius: 12px; border: 1px dashed #ced4da;">
                <label class="form-label" style="color: #64748b;">كلمة المرور الجديدة (اختياري)</label>
                <input type="password" name="password" class="form-control" placeholder="اتركه فارغاً للحفاظ على الكلمة الحالية">
            </div>

            <div class="modal-actions" style="display: flex; gap: 0.75rem;">
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 0.8rem; border-radius: 12px; font-weight: 700;">حفظ التغييرات</button>
                <button type="button" class="btn btn-secondary" @click="showEditModal = false" style="flex: 1; padding: 0.8rem; border-radius: 12px; font-weight: 600;">إلغاء</button>
            </div>
        </form>
    </x-edit-modal>

    <!-- Details Modal -->
    <div x-show="showDetailsModal" class="modal-overlay" style="display: none;"
        x-transition.opacity.duration.300ms>
        <div class="modal-container" style="max-width: 700px; padding: 0; overflow: hidden; border-radius: 24px;" @click.away="showDetailsModal = false">
            <div style="background: linear-gradient(135deg, #1e293b, #0f172a); color: white; padding: 2.5rem 2rem; position: relative;">
                <button @click="showDetailsModal = false" style="position: absolute; left: 1.5rem; top: 1.5rem; background: rgba(255,255,255,0.1); border: none; color: white; width: 32px; height: 32px; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center;">&times;</button>
                
                <div style="display: flex; align-items: center; gap: 1.5rem;">
                    <div style="width: 80px; height: 80px; background: rgba(255,255,255,0.1); border-radius: 20px; display: flex; align-items: center; justify-content: center; font-size: 2rem; font-weight: 800; border: 1px solid rgba(255,255,255,0.2);">
                        <span x-text="viewStudent.name ? viewStudent.name.charAt(0) : ''"></span>
                    </div>
                    <div>
                        <h2 x-text="viewStudent.name" style="margin: 0 0 0.5rem; font-size: 1.75rem; font-weight: 800;"></h2>
                <div style="display: flex; gap: 1rem; opacity: 0.8; font-size: 0.95rem;">
                    <span x-text="viewStudent.major"></span>
                    <span>•</span>
                    <span x-text="viewStudent.level"></span>
                    <span>•</span>
                    <span x-text="viewStudent.gender === 'female' ? 'أنثى' : 'ذكر'"></span>
                </div>
            </div>
        </div>
            </div>

            <div style="padding: 2rem;">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem;">
                    <div style="background: #f8fafc; padding: 1.25rem; border-radius: 16px; border: 1px solid #e2e8f0;">
                        <div style="color: #64748b; font-size: 0.8rem; font-weight: 700; margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">الرقم الجامعي</div>
                        <div x-text="viewStudent.student_number" style="font-weight: 700; font-size: 1.1rem; color: #1e293b; font-family: 'JetBrains Mono';"></div>
                    </div>
                    <div style="background: #f8fafc; padding: 1.25rem; border-radius: 16px; border: 1px solid #e2e8f0;">
                        <div style="color: #64748b; font-size: 0.8rem; font-weight: 700; margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">البريد الإلكتروني</div>
                        <div x-text="viewStudent.email" style="font-weight: 700; font-size: 1.1rem; color: #1e293b;"></div>
                    </div>
                    <div style="background: #f8fafc; padding: 1.25rem; border-radius: 16px; border: 1px solid #e2e8f0;">
                        <div style="color: #64748b; font-size: 0.8rem; font-weight: 700; margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">الجنس</div>
                        <div style="font-weight: 700; font-size: 1.1rem; color: #1e293b;" x-text="viewStudent.gender === 'female' ? 'أنثى' : 'ذكر'"></div>
                    </div>
                </div>

                <h4 style="font-weight: 800; color: #1e293b; margin-bottom: 1.25rem; display: flex; align-items: center; gap: 0.75rem;">
                    <div style="width: 8px; height: 8px; background: #10b981; border-radius: 50%;"></div>
                    المقررات الدراسية الحالية
                </h4>

                <div style="max-height: 300px; overflow-y: auto; padding-right: 0.5rem;">
                    <template x-for="subject in viewSubjects">
                        <div style="background: white; border: 1px solid #f1f5f9; padding: 1.25rem; border-radius: 16px; margin-bottom: 0.75rem; display: flex; justify-content: space-between; align-items: center; transition: all 0.2s;">
                            <div>
                                <div style="font-weight: 700; color: #1e293b; margin-bottom: 0.25rem;" x-text="subject.name"></div>
                                <div style="font-size: 0.8rem; color: #64748b;">
                                    كود: <span x-text="subject.code || '-'"></span> | <span x-text="subject.term"></span>
                                </div>
                            </div>
                            <div style="text-align: left; background: #f0fdf4; padding: 0.5rem 1rem; border-radius: 10px;">
                                <div style="font-size: 0.7rem; color: #166534; font-weight: 700;">أستاذ المادة</div>
                                <div style="font-weight: 700; font-size: 0.85rem; color: #10b981;" x-text="subject.doctor"></div>
                            </div>
                        </div>
                    </template>
                    <div x-show="viewSubjects.length === 0" style="text-align: center; padding: 3rem; background: #f8fafc; border-radius: 16px; color: #94a3b8;">
                        <i class="fas fa-book-open" style="font-size: 2rem; margin-bottom: 1rem; opacity: 0.3;"></i>
                        <div>لا توجد مواد مسجلة لهذا المستوى حالياً</div>
                    </div>
                </div>
            </div>
            
            <div style="background: #f1f5f9; padding: 1.5rem 2rem; display: flex; justify-content: flex-end;">
                <button @click="showDetailsModal = false" style="background: #1e293b; color: white; border: none; padding: 0.75rem 2rem; border-radius: 12px; font-weight: 700; cursor: pointer;">إغلاق النافذة</button>
            </div>
        </div>
    </div>


</div>

@endsection
