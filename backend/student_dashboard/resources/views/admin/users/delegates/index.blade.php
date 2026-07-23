@extends('layouts.admin')

@section('title', 'إدارة المندوبين')

@section('content')

<style>
    .page-header { display: flex; align-items: center; gap: 1rem; margin-bottom: 2rem; }
    .page-header-icon { width: 56px; height: 56px; background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); border-radius: 16px; display: flex; align-items: center; justify-content: center; color: white; box-shadow: 0 4px 12px -2px rgba(139, 92, 246, 0.4); }
    .page-header-text h1 { font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem; }
    .page-header-text p { color: var(--text-secondary); font-size: 0.9rem; }
    .stats-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 2rem; }
    .stat-card { background: white; border-radius: 16px; padding: 1.25rem; border: 1px solid var(--border-color); display: flex; align-items: center; gap: 1rem; }
    .stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
    .stat-icon.purple { background: rgba(139, 92, 246, 0.1); color: #8b5cf6; }
    .stat-icon.blue { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }
    .stat-icon.amber { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
    .stat-info h3 { font-size: 1.75rem; font-weight: 700; line-height: 1; margin-bottom: 0.25rem; }
    .stat-info p { color: var(--text-secondary); font-size: 0.85rem; }
    .form-card, .table-card { background: white; border-radius: 20px; border: 1px solid var(--border-color); padding: 1.5rem; }
    .form-card-header, .table-card-header { display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1.5rem; padding-bottom: 1rem; border-bottom: 1px solid var(--border-color); }
    .form-card-header .icon { width: 40px; height: 40px; background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); border-radius: 10px; display: flex; align-items: center; justify-content: center; color: white; }
    .modern-table { width: 100%; border-collapse: separate; border-spacing: 0; }
    .modern-table thead th { background: #f8fafc; padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary); font-size: 0.85rem; border-bottom: 1px solid var(--border-color); }
    .modern-table tbody td { padding: 1rem; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
    .modern-table tbody tr:hover { background: #fafafa; }
    .action-btn { padding: 0.5rem 0.875rem; border-radius: 8px; font-size: 0.8rem; font-weight: 600; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 0.35rem; }
    .action-btn.view { background: #f3f4f6; color: #6b7280; }
    .action-btn.edit { background: #eff6ff; color: #3b82f6; }
    .action-btn.delete { background: #fef2f2; color: #ef4444; }
    .btn-submit { width: 100%; padding: 0.875rem; background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); color: white; border: none; border-radius: 12px; font-size: 1rem; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; }
    .delegate-avatar { width: 40px; height: 40px; background: linear-gradient(135deg, #ede9fe, #ddd6fe); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.9rem; font-weight: 700; color: #7c3aed; }
</style>

<div x-data="{ showDeleteModal: false, showEditModal: false, deleteUrl: '', modalTitle: '', modalMessage: '', editUrl: '', editName: '', editEmail: '', editStudentNumber: '', editGender: '', editLevelId: '' }">
    <div class="page-header">
        <div class="page-header-icon"><i class="fas fa-user-check"></i></div>
        <div class="page-header-text">
            <h1>إدارة المندوبين</h1>
            <p>إنشاء وتعديل المندوبين ببيانات طالب كاملة، بما فيها الجنس.</p>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success" style="margin-bottom: 1.5rem;">{{ session('success') }}</div>
    @endif

    @if(session('error'))
        <div class="alert alert-danger" style="margin-bottom: 1.5rem;">{{ session('error') }}</div>
    @endif

    @if($errors->any())
        <div class="alert alert-danger" style="margin-bottom: 1.5rem;">
            <ul style="margin: 0;">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="stats-row">
        <div class="stat-card"><div class="stat-icon purple"><i class="fas fa-user-check"></i></div><div class="stat-info"><h3>{{ $delegates->total() }}</h3><p>إجمالي المندوبين</p></div></div>
        <div class="stat-card"><div class="stat-icon blue"><i class="fas fa-layer-group"></i></div><div class="stat-info"><h3>{{ \App\Models\Academic\Level::count() }}</h3><p>إجمالي المستويات</p></div></div>
        <div class="stat-card"><div class="stat-icon amber"><i class="fas fa-circle-info"></i></div><div class="stat-info"><h3>{{ max(\App\Models\Academic\Level::count() - $delegates->total(), 0) }}</h3><p>دفعات بدون مندوب</p></div></div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 1.5rem; align-items: start;">
        <div class="form-card">
            <div class="form-card-header"><div class="icon"><i class="fas fa-plus"></i></div><h3>إضافة مندوب جديد</h3></div>
            <form action="{{ route('admin.delegates.store') }}" method="POST">
                @csrf
                <div class="form-group">
                    <label for="level_id" class="form-label">الدفعة التي يمثلها</label>
                    <select name="level_id" id="level_id" class="form-control" required>
                        <option value="">اختر الدفعة...</option>
                        @foreach($universities as $university)
                            <optgroup label="{{ $university->name }}">
                                @foreach($university->colleges as $college)
                                    @foreach($college->majors as $major)
                                        @foreach($major->levels as $level)
                                            <option value="{{ $level->id }}">{{ $level->name }} - {{ $major->name }} ({{ $college->name }})</option>
                                        @endforeach
                                    @endforeach
                                @endforeach
                            </optgroup>
                        @endforeach
                    </select>
                </div>
                <div class="form-group mt-3"><label for="name" class="form-label">الاسم الكامل</label><input type="text" name="name" id="name" class="form-control" required></div>
                <div class="form-group mt-3"><label for="email" class="form-label">البريد الإلكتروني</label><input type="email" name="email" id="email" class="form-control" required></div>
                <div class="form-group mt-3"><label for="student_number" class="form-label">رقم القيد الجامعي</label><input type="text" name="student_number" id="student_number" class="form-control" required></div>
                <div class="form-group mt-3"><label for="gender" class="form-label">الجنس</label><select name="gender" id="gender" class="form-control" required><option value="">اختر الجنس...</option><option value="male">ذكر</option><option value="female">أنثى</option></select></div>
                <div class="form-group mt-3"><label for="password" class="form-label">كلمة المرور</label><input type="password" name="password" id="password" class="form-control" required></div>
                <button type="submit" class="btn-submit mt-3"><i class="fas fa-save"></i> حفظ المندوب</button>
            </form>
        </div>

        <div class="table-card">
            <div class="table-card-header"><h3><i class="fas fa-list"></i> قائمة المندوبين</h3></div>
            <div class="table-responsive">
                <table class="modern-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>المندوب</th>
                            <th>الدفعة</th>
                            <th>الجنس</th>
                            <th>الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($delegates as $delegate)
                            <tr>
                                <td>{{ $loop->iteration }}</td>
                                <td>
                                    <div style="display:flex; align-items:center; gap:.75rem;">
                                        <div class="delegate-avatar">{{ mb_substr($delegate->name, 0, 1) }}</div>
                                        <div>
                                            <div style="font-weight:600;">{{ $delegate->name }}</div>
                                            <div style="font-size:.8rem; color:var(--text-secondary);">{{ $delegate->email }}</div>
                                            <div style="font-size:.8rem; color:var(--text-secondary);">{{ $delegate->student_number }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div style="font-weight:600;">{{ $delegate->level->name ?? '-' }}</div>
                                    <div style="font-size:.8rem; color:var(--text-secondary);">{{ $delegate->major->name ?? '' }}</div>
                                </td>
                                <td>{{ $delegate->gender === 'female' ? 'أنثى' : 'ذكر' }}</td>
                                <td>
                                    <div style="display:flex; gap:.5rem;">
                                        <button type="button" class="action-btn edit" @click="showEditModal = true; modalTitle = 'تعديل: {{ $delegate->name }}'; editUrl = '{{ route('admin.delegates.update', $delegate) }}'; editName = @js($delegate->name); editEmail = @js($delegate->email); editStudentNumber = @js($delegate->student_number); editGender = @js($delegate->gender ?? ''); editLevelId = @js((string) $delegate->level_id);"><i class="fas fa-pen"></i> تعديل</button>
                                        <button type="button" class="action-btn delete" @click="showDeleteModal = true; deleteUrl = '{{ route('admin.delegates.destroy', $delegate) }}'; modalTitle = 'حذف {{ $delegate->name }}'; modalMessage = 'هل أنت متأكد من حذف هذا المندوب؟';"><i class="fas fa-trash"></i> حذف</button>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="5" style="text-align: center; padding: 3rem; color: var(--text-secondary);">لا يوجد مندوبون مسجلون</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
            <div style="margin-top: 1.5rem;">{{ $delegates->links() }}</div>
        </div>
    </div>

    <x-delete-modal />
    <x-edit-modal>
        <form :action="editUrl" method="POST">
            @csrf
            @method('PUT')
            <div class="form-group">
                <label for="edit_level_id" class="form-label">الدفعة التي يمثلها</label>
                <select name="level_id" id="edit_level_id" class="form-control" x-model="editLevelId" required>
                    <option value="">اختر الدفعة...</option>
                    @foreach($universities as $university)
                        <optgroup label="{{ $university->name }}">
                            @foreach($university->colleges as $college)
                                @foreach($college->majors as $major)
                                    @foreach($major->levels as $level)
                                        <option value="{{ $level->id }}">{{ $level->name }} - {{ $major->name }} ({{ $college->name }})</option>
                                    @endforeach
                                @endforeach
                            @endforeach
                        </optgroup>
                    @endforeach
                </select>
            </div>
            <div class="form-group mt-3"><label for="edit_name" class="form-label">الاسم الكامل</label><input type="text" name="name" id="edit_name" class="form-control" x-model="editName" required></div>
            <div class="form-group mt-3"><label for="edit_email" class="form-label">البريد الإلكتروني</label><input type="email" name="email" id="edit_email" class="form-control" x-model="editEmail" required></div>
            <div class="form-group mt-3"><label for="edit_student_number" class="form-label">رقم القيد الجامعي</label><input type="text" name="student_number" id="edit_student_number" class="form-control" x-model="editStudentNumber" required></div>
            <div class="form-group mt-3"><label for="edit_gender" class="form-label">الجنس</label><select name="gender" id="edit_gender" class="form-control" x-model="editGender" required><option value="">اختر الجنس...</option><option value="male">ذكر</option><option value="female">أنثى</option></select></div>
            <div class="form-group mt-3"><label for="edit_password" class="form-label">كلمة المرور الجديدة (اختياري)</label><input type="password" name="password" id="edit_password" class="form-control"></div>
            <div class="modal-actions mt-4"><button type="button" class="btn btn-secondary" @click="showEditModal = false">إلغاء</button><button type="submit" class="btn btn-primary">حفظ التغييرات</button></div>
        </form>
    </x-edit-modal>
</div>

@endsection
