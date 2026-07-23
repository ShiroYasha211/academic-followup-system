@extends('layouts.admin')

@section('title', 'إدارة المستخدمين')

@section('content')
@php
    $currentRole = request('role', 'all');
    $roleTabs = [
        'all' => 'الكل',
        'admin' => 'المدراء',
        'doctor' => 'الدكاترة',
        'delegate' => 'المندوبون',
        'student' => 'الطلاب',
        'administrative' => 'الإداريون',
    ];
@endphp

<div class="container-fluid px-0" x-data="{ selectedUsers: [], selectAll: false }">
    <style>
        .users-toolbar-card,
        .users-table-card,
        .users-stat-card {
            border: 0;
            box-shadow: 0 0.5rem 1.25rem rgba(15, 23, 42, 0.06);
            border-radius: 1rem;
        }

        .users-stat-card .label {
            font-size: 0.72rem;
            color: #64748b;
            margin-bottom: 0.15rem;
        }

        .users-stat-card .value {
            font-size: 1.35rem;
            font-weight: 700;
            line-height: 1.1;
            color: #0f172a;
        }

        .users-filter-form .form-label {
            font-size: 0.75rem;
            color: #64748b;
            margin-bottom: 0.35rem;
            font-weight: 600;
        }

        .users-filter-form .form-control,
        .users-filter-form .form-select,
        .users-filter-form .btn {
            min-height: 2.55rem;
        }

        .users-role-pills .nav-link {
            border-radius: 999px;
            padding: 0.45rem 0.9rem;
            font-size: 0.82rem;
            font-weight: 600;
            color: #475569;
            background: #f8fafc;
        }

        .users-role-pills .nav-link.active {
            color: #fff;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
        }

        .users-table {
            margin-bottom: 0;
            --bs-table-bg: transparent;
        }

        .users-table thead th {
            font-size: 0.73rem;
            color: #64748b;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.02em;
            white-space: nowrap;
            padding-top: 0.85rem;
            padding-bottom: 0.85rem;
        }

        .users-table tbody td {
            padding-top: 0.9rem;
            padding-bottom: 0.9rem;
            vertical-align: middle;
            font-size: 0.88rem;
        }

        .users-table tbody tr:hover {
            background: rgba(37, 99, 235, 0.03);
        }

        .user-avatar {
            width: 2.25rem;
            height: 2.25rem;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            font-weight: 700;
            flex: 0 0 auto;
        }

        .user-block .name {
            font-weight: 700;
            color: #0f172a;
            line-height: 1.2;
        }

        .user-block .meta,
        .academic-block .meta {
            font-size: 0.75rem;
            color: #64748b;
            line-height: 1.2;
        }

        .academic-block .title {
            font-weight: 600;
            color: #0f172a;
            line-height: 1.2;
        }

        .compact-badge {
            font-size: 0.72rem;
            font-weight: 700;
            padding: 0.35rem 0.55rem;
            border-radius: 999px;
        }

        .bulk-toolbar {
            border: 1px dashed #cbd5e1;
            background: #f8fafc;
            border-radius: 0.85rem;
            padding: 0.75rem 0.9rem;
        }

        .table-actions .dropdown-toggle::after {
            display: none;
        }

        .table-actions .btn {
            min-width: auto;
        }

        @media (max-width: 1199.98px) {
            .users-table-wrapper {
                overflow-x: auto;
            }
        }
    </style>

    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
        <div>
            <h1 class="h4 fw-bold mb-1">إدارة المستخدمين</h1>
            <p class="text-muted small mb-0">صفحة مضغوطة لإدارة الحسابات بدون تكدس بصري أو عناصر ضخمة.</p>
        </div>
        <a href="{{ route('admin.users.export', request()->only(['role', 'search', 'university_id', 'major_id'])) }}" class="btn btn-success btn-sm px-3">
            تصدير Excel
        </a>
    </div>

    @if(session('success'))
        <div class="alert alert-success py-2 small">{{ session('success') }}</div>
    @endif

    @if(session('error'))
        <div class="alert alert-danger py-2 small">{{ session('error') }}</div>
    @endif

    <div class="row g-3 mb-3">
        <div class="col-sm-6 col-xl-3">
            <div class="card users-stat-card">
                <div class="card-body py-3">
                    <div class="label">إجمالي النتائج</div>
                    <div class="value">{{ $users->total() }}</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="card users-stat-card">
                <div class="card-body py-3">
                    <div class="label">النشطون في الصفحة</div>
                    <div class="value">{{ $users->where('status', 'active')->count() }}</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="card users-stat-card">
                <div class="card-body py-3">
                    <div class="label">المشتركون</div>
                    <div class="value">{{ $users->filter(fn ($user) => $user->isSubscribed())->count() }}</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="card users-stat-card">
                <div class="card-body py-3">
                    <div class="label">الدكاترة الإداريون</div>
                    <div class="value">{{ $users->where('administrative_access', true)->count() }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="card users-toolbar-card mb-3">
        <div class="card-body p-3">
            <form action="{{ route('admin.users.index') }}" method="GET" class="users-filter-form row g-2 align-items-end">
                <div class="col-md-4 col-xl-3">
                    <label class="form-label">بحث</label>
                    <input type="text" name="search" value="{{ request('search') }}" class="form-control form-control-sm" placeholder="اسم أو بريد إلكتروني">
                </div>
                <div class="col-sm-6 col-md-2 col-xl-2">
                    <label class="form-label">الدور</label>
                    <select name="role" class="form-select form-select-sm">
                        @foreach($roleTabs as $value => $label)
                            <option value="{{ $value }}" @selected($currentRole === $value)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-sm-6 col-md-3 col-xl-2">
                    <label class="form-label">الجامعة</label>
                    <select name="university_id" class="form-select form-select-sm">
                        <option value="">الكل</option>
                        @foreach($universities as $university)
                            <option value="{{ $university->id }}" @selected((string) request('university_id') === (string) $university->id)>{{ $university->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-sm-6 col-md-3 col-xl-2">
                    <label class="form-label">التخصص</label>
                    <select name="major_id" class="form-select form-select-sm">
                        <option value="">الكل</option>
                        @foreach($majors as $major)
                            <option value="{{ $major->id }}" @selected((string) request('major_id') === (string) $major->id)>{{ $major->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-sm-6 col-md-12 col-xl-3">
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary btn-sm flex-grow-1">تطبيق</button>
                        <a href="{{ route('admin.users.index') }}" class="btn btn-outline-secondary btn-sm flex-grow-1">إعادة ضبط</a>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <ul class="nav users-role-pills flex-wrap gap-2 mb-3">
        @foreach($roleTabs as $value => $label)
            <li class="nav-item">
                <a class="nav-link {{ $currentRole === $value || ($value === 'all' && !$currentRole) ? 'active' : '' }}"
                   href="{{ route('admin.users.index', array_filter([
                       'role' => $value,
                       'search' => request('search'),
                       'university_id' => request('university_id'),
                       'major_id' => request('major_id'),
                   ])) }}">
                    {{ $label }}
                </a>
            </li>
        @endforeach
    </ul>

    <div class="card users-table-card">
        <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
            <div>
                <div class="fw-bold">قائمة المستخدمين</div>
                <div class="text-muted small">كل السجلات والإجراءات الأساسية في شاشة واحدة.</div>
            </div>
            <span class="badge text-bg-primary compact-badge">{{ $users->total() }}</span>
        </div>

        <div class="card-body pt-0">
            <div class="bulk-toolbar my-3 d-flex flex-wrap justify-content-between align-items-center gap-2"
                 x-show="selectedUsers.length > 0" x-cloak>
                <div class="fw-semibold small">تم تحديد <span x-text="selectedUsers.length"></span> مستخدم</div>
                <div class="d-flex flex-wrap gap-2">
                    <form action="{{ route('admin.users.bulk-activate') }}" method="POST" class="d-inline-block">
                        @csrf
                        <template x-for="id in selectedUsers" :key="'activate-' + id">
                            <input type="hidden" name="ids[]" :value="id">
                        </template>
                        <button type="submit" class="btn btn-success btn-sm">تفعيل</button>
                    </form>
                    <form action="{{ route('admin.users.bulk-deactivate') }}" method="POST" class="d-inline-block">
                        @csrf
                        <template x-for="id in selectedUsers" :key="'deactivate-' + id">
                            <input type="hidden" name="ids[]" :value="id">
                        </template>
                        <button type="submit" class="btn btn-warning btn-sm">تعطيل</button>
                    </form>
                    <form action="{{ route('admin.users.bulk-delete') }}" method="POST" class="d-inline-block" onsubmit="return confirm('هل أنت متأكد من حذف المستخدمين المحددين؟');">
                        @csrf
                        <template x-for="id in selectedUsers" :key="'delete-' + id">
                            <input type="hidden" name="ids[]" :value="id">
                        </template>
                        <button type="submit" class="btn btn-danger btn-sm">حذف</button>
                    </form>
                    <button type="button" class="btn btn-outline-secondary btn-sm" @click="selectedUsers = []; selectAll = false">إلغاء</button>
                </div>
            </div>

            <div class="users-table-wrapper">
                <table class="table users-table align-middle">
                    <thead class="table-light">
                        <tr>
                            <th style="width: 42px;">
                                <input type="checkbox"
                                       class="form-check-input"
                                       x-model="selectAll"
                                       @change="selectedUsers = selectAll ? [{{ $users->pluck('id')->filter(fn($id) => $id != auth()->id())->join(',') }}] : []">
                            </th>
                            <th>المستخدم</th>
                            <th>البيانات الأكاديمية</th>
                            <th>الدور</th>
                            <th>الاشتراك</th>
                            <th>الحالة</th>
                            <th>التسجيل</th>
                            <th class="text-end" style="width: 72px;">إجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($users as $user)
                            <tr>
                                <td>
                                    @if($user->id !== auth()->id())
                                        <input type="checkbox" class="form-check-input" value="{{ $user->id }}" x-model.number="selectedUsers">
                                    @endif
                                </td>
                                <td>
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="user-avatar"
                                             style="background: {{ $user->role->value == 'admin' ? '#1f2937' : ($user->role->value == 'doctor' ? '#2563eb' : ($user->role->value == 'delegate' ? '#0891b2' : '#64748b')) }};">
                                            {{ mb_substr($user->name, 0, 1) }}
                                        </div>
                                        <div class="user-block">
                                            <div class="name">{{ $user->name }}</div>
                                            <div class="meta">{{ $user->email }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div class="academic-block">
                                        <div class="title">{{ $user->university->name ?? '-' }}</div>
                                        <div class="meta">{{ $user->college->name ?? '-' }}</div>
                                        <div class="meta mt-1">{{ $user->major->name ?? '-' }} | {{ $user->level->name ?? '-' }}</div>
                                    </div>
                                </td>
                                <td>
                                    @if($user->role->value === 'admin')
                                        <span class="badge text-bg-dark compact-badge">مدير</span>
                                    @elseif($user->role->value === 'doctor')
                                        <span class="badge text-bg-primary compact-badge">دكتور</span>
                                        @if($user->administrative_access)
                                            <div class="mt-1">
                                                <span class="badge text-bg-secondary compact-badge">مسؤول إداري</span>
                                            </div>
                                        @endif
                                    @elseif($user->role->value === 'delegate')
                                        <span class="badge text-bg-info compact-badge">مندوب</span>
                                    @elseif($user->role->value === 'practical_delegate')
                                        <span class="badge text-bg-success compact-badge">مندوب عملي</span>
                                    @elseif($user->role->value === 'administrative')
                                        <span class="badge text-bg-secondary compact-badge">إداري</span>
                                    @else
                                        <span class="badge text-bg-light compact-badge">طالب</span>
                                    @endif
                                </td>
                                <td>
                                    @if($user->isSubscribed())
                                        <span class="badge text-bg-success compact-badge">
                                            @if($user->subscribed_until)
                                                حتى {{ $user->subscribed_until->format('Y/m/d') }}
                                            @else
                                                دائم
                                            @endif
                                        </span>
                                    @else
                                        <span class="badge text-bg-light compact-badge">غير مشترك</span>
                                    @endif
                                </td>
                                <td>
                                    @if($user->status === 'active')
                                        <span class="badge text-bg-success compact-badge">فعال</span>
                                    @else
                                        <span class="badge text-bg-danger compact-badge">موقوف</span>
                                    @endif
                                </td>
                                <td class="text-muted small">{{ $user->created_at?->format('Y/m/d') ?? '-' }}</td>
                                <td class="text-end">
                                    @if($user->id !== auth()->id())
                                        <div class="dropdown table-actions">
                                            <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                                                ⋮
                                            </button>
                                            <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0">
                                                <li>
                                                    <button type="button"
                                                            class="dropdown-item"
                                                            data-bs-toggle="modal"
                                                            data-bs-target="#resetPasswordModal"
                                                            data-user-id="{{ $user->id }}"
                                                            data-user-name="{{ $user->name }}">
                                                        كلمة السر
                                                    </button>
                                                </li>
                                                @if($user->role->value !== 'admin')
                                                    <li>
                                                        <button type="button"
                                                                class="dropdown-item"
                                                                data-bs-toggle="modal"
                                                                data-bs-target="#activateSubscriptionModal"
                                                                data-user-id="{{ $user->id }}"
                                                                data-user-name="{{ $user->name }}">
                                                            تفعيل الاشتراك
                                                        </button>
                                                    </li>
                                                @endif
                                                <li>
                                                    <button type="button"
                                                            class="dropdown-item"
                                                            data-bs-toggle="modal"
                                                            data-bs-target="#kickUserModal"
                                                            data-user-id="{{ $user->id }}"
                                                            data-user-name="{{ $user->name }}">
                                                        طرد من الجلسة
                                                    </button>
                                                </li>
                                                <li><hr class="dropdown-divider"></li>
                                                <li>
                                                    <form action="{{ route('admin.users.status', $user->id) }}" method="POST">
                                                        @csrf
                                                        @method('PATCH')
                                                        <button type="submit" class="dropdown-item">
                                                            {{ $user->status === 'active' ? 'إيقاف الحساب' : 'تفعيل الحساب' }}
                                                        </button>
                                                    </form>
                                                </li>
                                                <li>
                                                    <form action="{{ route('admin.users.destroy', $user->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا المستخدم؟');">
                                                        @csrf
                                                        @method('DELETE')
                                                        <button type="submit" class="dropdown-item text-danger">حذف</button>
                                                    </form>
                                                </li>
                                            </ul>
                                        </div>
                                    @else
                                        <span class="text-muted small">حسابك</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="8" class="text-center py-5 text-muted">لا يوجد مستخدمون ضمن هذه التصفية.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <div class="card-footer bg-white border-0 pt-0">
            {{ $users->withQueryString()->links('pagination::bootstrap-5') }}
        </div>
    </div>
</div>

<div class="modal fade" id="resetPasswordModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content border-0 shadow">
            <form id="resetPasswordForm" method="POST">
                @csrf
                <div class="modal-header">
                    <h5 class="modal-title">إعادة تعيين كلمة المرور</h5>
                    <button type="button" class="btn-close m-0" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p class="text-muted small mb-3">المستخدم: <strong id="resetUserName"></strong></p>
                    <label class="form-label small">كلمة المرور الجديدة</label>
                    <input type="text" name="new_password" class="form-control" minlength="8" required placeholder="8 أحرف أو أكثر">
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">إلغاء</button>
                    <button type="submit" class="btn btn-primary btn-sm">حفظ</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade" id="activateSubscriptionModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content border-0 shadow">
            <form id="activateSubscriptionForm" method="POST">
                @csrf
                @method('PATCH')
                <div class="modal-header">
                    <h5 class="modal-title">تفعيل الاشتراك</h5>
                    <button type="button" class="btn-close m-0" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p class="text-muted small mb-3">المستخدم: <strong id="activateUserName"></strong></p>
                    <label class="form-label small">عدد الأيام</label>
                    <input type="number" name="days" class="form-control" min="1" max="3650" value="30" required>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">إلغاء</button>
                    <button type="submit" class="btn btn-success btn-sm">تفعيل</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade" id="kickUserModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content border-0 shadow">
            <form id="kickUserForm" method="POST">
                @csrf
                <div class="modal-header">
                    <h5 class="modal-title">طرد من الجلسة</h5>
                    <button type="button" class="btn-close m-0" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <p class="mb-0 small">سيتم تسجيل خروج المستخدم فورًا: <strong id="kickUserName"></strong></p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">إلغاء</button>
                    <button type="submit" class="btn btn-dark btn-sm">تنفيذ</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    const resetModal = document.getElementById('resetPasswordModal');
    if (resetModal) {
        resetModal.addEventListener('show.bs.modal', event => {
            const button = event.relatedTarget;
            const userId = button.getAttribute('data-user-id');
            const userName = button.getAttribute('data-user-name');
            document.getElementById('resetUserName').textContent = userName;
            document.getElementById('resetPasswordForm').action = `{{ url('admin/users') }}/${userId}/reset-password`;
        });
    }

    const activateModal = document.getElementById('activateSubscriptionModal');
    if (activateModal) {
        activateModal.addEventListener('show.bs.modal', event => {
            const button = event.relatedTarget;
            const userId = button.getAttribute('data-user-id');
            const userName = button.getAttribute('data-user-name');
            document.getElementById('activateUserName').textContent = userName;
            document.getElementById('activateSubscriptionForm').action = `{{ url('admin/users') }}/${userId}/activate-subscription`;
        });
    }

    const kickModal = document.getElementById('kickUserModal');
    if (kickModal) {
        kickModal.addEventListener('show.bs.modal', event => {
            const button = event.relatedTarget;
            const userId = button.getAttribute('data-user-id');
            const userName = button.getAttribute('data-user-name');
            document.getElementById('kickUserName').textContent = userName;
            document.getElementById('kickUserForm').action = `{{ url('admin/users') }}/${userId}/kick`;
        });
    }
</script>
@endpush
