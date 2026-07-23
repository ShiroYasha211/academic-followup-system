@extends('layouts.admin')

@section('title', 'طلبات تعديل الحضور')

@section('content')

<style>
    .attendance-edit-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .attendance-edit-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0;
    }

    .attendance-edit-subtitle {
        color: var(--text-secondary);
        margin-top: 0.45rem;
        max-width: 760px;
        line-height: 1.8;
    }

    .attendance-edit-stats {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 0.85rem;
        margin-bottom: 1.5rem;
    }

    .attendance-edit-stat {
        background: #fff;
        border: 1px solid var(--border-color);
        border-radius: 14px;
        padding: 1rem;
    }

    .attendance-edit-stat span {
        display: block;
        color: var(--text-secondary);
        font-size: 0.82rem;
        font-weight: 700;
        margin-bottom: 0.35rem;
    }

    .attendance-edit-stat strong {
        color: var(--text-primary);
        font-size: 1.55rem;
        font-weight: 900;
        font-variant-numeric: tabular-nums;
    }

    .manual-grant-grid {
        display: grid;
        grid-template-columns: minmax(260px, 1.15fr) minmax(320px, 1.7fr) minmax(160px, 0.65fr);
        gap: 1rem;
        align-items: start;
    }

    .scope-switch {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 0.5rem;
        margin-bottom: 1rem;
    }

    .scope-switch label {
        border: 1px solid var(--border-color);
        border-radius: 12px;
        padding: 0.75rem 0.8rem;
        cursor: pointer;
        background: #f8fafc;
        color: var(--text-secondary);
        font-weight: 800;
        text-align: center;
        transition: 0.2s ease;
    }

    .scope-switch input {
        display: none;
    }

    .scope-switch label:has(input:checked) {
        background: #eef2ff;
        border-color: #4f46e5;
        color: #3730a3;
    }

    .lookup-box {
        position: relative;
    }

    .lookup-box label,
    .grant-field label {
        display: block;
        font-size: 0.84rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.4rem;
    }

    .lookup-results {
        position: absolute;
        z-index: 30;
        inset-inline: 0;
        top: calc(100% + 0.35rem);
        background: #fff;
        border: 1px solid var(--border-color);
        border-radius: 14px;
        box-shadow: 0 18px 42px rgba(15, 23, 42, 0.14);
        max-height: 270px;
        overflow: auto;
        display: none;
    }

    .lookup-results.is-open {
        display: block;
    }

    .lookup-item {
        width: 100%;
        border: 0;
        background: transparent;
        text-align: start;
        padding: 0.8rem 0.9rem;
        cursor: pointer;
        border-bottom: 1px solid #f1f5f9;
    }

    .lookup-item:hover,
    .lookup-item:focus {
        background: #f8fafc;
        outline: none;
    }

    .lookup-item strong {
        display: block;
        color: var(--text-primary);
        font-size: 0.9rem;
        font-weight: 900;
    }

    .lookup-item span,
    .lookup-note {
        display: block;
        color: var(--text-secondary);
        font-size: 0.78rem;
        margin-top: 0.2rem;
    }

    .scope-panel {
        display: none;
    }

    .scope-panel.is-active {
        display: block;
    }

    .grant-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.6rem;
        margin-top: 1rem;
    }

    .grant-error {
        display: none;
        margin-top: 1rem;
        padding: 0.75rem 0.9rem;
        border-radius: 12px;
        background: #fef2f2;
        color: #b91c1c;
        font-size: 0.9rem;
        font-weight: 800;
    }

    .grant-error.is-visible {
        display: block;
    }

    .filter-row {
        display: flex;
        gap: 0.5rem;
        align-items: center;
        flex-wrap: wrap;
    }

    @media (max-width: 1100px) {
        .manual-grant-grid,
        .attendance-edit-stats {
            grid-template-columns: 1fr;
        }
    }
</style>

<div class="attendance-edit-header">
    <div>
        <h1 class="attendance-edit-title">طلبات تعديل الحضور</h1>
        <p class="attendance-edit-subtitle">
            فتح تعديل سجلات الحضور يتم من الأدمن الرئيسي فقط ولمدة محددة. استخدم البحث بدل القوائم الطويلة للوصول إلى الدكتور أو المندوب والمحاضرة المطلوبة بسرعة.
        </p>
    </div>
    <span class="badge badge-warning" style="font-size:0.9rem;">{{ $pendingCount }} طلب معلق</span>
</div>

<div class="attendance-edit-stats">
    <div class="attendance-edit-stat">
        <span>طلبات معلقة</span>
        <strong>{{ $pendingCount }}</strong>
    </div>
    <div class="attendance-edit-stat">
        <span>صلاحيات نشطة الآن</span>
        <strong>{{ $activePermissionsCount }}</strong>
    </div>
    <div class="attendance-edit-stat">
        <span>تنتهي خلال ساعتين</span>
        <strong>{{ $expiringPermissionsCount }}</strong>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
@endif

@if(session('error'))
    <div class="alert alert-danger">{{ session('error') }}</div>
@endif

@if($errors->any())
    <div class="alert alert-danger">
        <ul style="margin:0; padding-right:1.25rem;">
            @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<div class="card" style="margin-bottom:1.5rem;">
    <div style="border-bottom:1px solid var(--border-color); padding-bottom:1rem; margin-bottom:1rem;">
        <h3 style="font-size:1.1rem; font-weight:800; color:var(--text-primary); margin:0;">فتح تعديل يدوي</h3>
        <p style="font-size:0.9rem; color:var(--text-secondary); margin-top:0.35rem;">
            ابحث بالاسم أو البريد أو اسم المادة أو تاريخ المحاضرة. النتائج تظهر حسب الطلب ولا يتم تحميل كل السجلات داخل الصفحة.
        </p>
    </div>

    <form action="{{ route('admin.attendance-edit-requests.grant') }}" method="POST" id="manualGrantForm">
        @csrf
        <input type="hidden" name="user_id" id="manual_user_id" value="{{ old('user_id') }}">
        <input type="hidden" name="lecture_id" id="manual_lecture_id" value="{{ old('lecture_id') }}">
        <input type="hidden" name="subject_id" id="manual_subject_id" value="{{ old('subject_id') }}">
        <input type="hidden" name="qr_attendance_session_id" id="manual_qr_attendance_session_id" value="{{ old('qr_attendance_session_id') }}">

        <div class="manual-grant-grid">
            <div>
                <div class="lookup-box">
                    <label for="manual_user_search">الدكتور أو المندوب</label>
                    <input
                        id="manual_user_search"
                        class="form-control lookup-input"
                        type="search"
                        autocomplete="off"
                        placeholder="اكتب الاسم أو البريد..."
                        data-url="{{ route('admin.attendance-edit-requests.lookup-users') }}"
                        data-target="manual_user_id"
                        required
                    >
                    <div class="lookup-results"></div>
                    <span class="lookup-note">النتائج مقتصرة على الدكاترة والمندوبين.</span>
                </div>
            </div>

            <div>
                <div class="scope-switch">
                    <label>
                        <input type="radio" name="scope_type" value="lecture" @checked(old('scope_type', 'lecture') === 'lecture')>
                        محاضرة محددة
                    </label>
                    <label>
                        <input type="radio" name="scope_type" value="subject_date" @checked(old('scope_type') === 'subject_date')>
                        مادة وتاريخ
                    </label>
                    <label>
                        <input type="radio" name="scope_type" value="qr" @checked(old('scope_type') === 'qr')>
                        جلسة QR
                    </label>
                </div>

                <div class="scope-panel" data-scope-panel="lecture">
                    <div class="lookup-box">
                        <label for="manual_lecture_search">المحاضرة</label>
                        <input
                            id="manual_lecture_search"
                            class="form-control lookup-input"
                            type="search"
                            autocomplete="off"
                            placeholder="ابحث باسم المادة، عنوان المحاضرة، الرقم أو التاريخ..."
                            data-url="{{ route('admin.attendance-edit-requests.lookup-lectures') }}"
                            data-target="manual_lecture_id"
                        >
                        <div class="lookup-results"></div>
                    </div>
                </div>

                <div class="scope-panel" data-scope-panel="subject_date">
                    <div style="display:grid; grid-template-columns:1fr 170px; gap:0.75rem;">
                        <div class="lookup-box">
                            <label for="manual_subject_search">المادة</label>
                            <input
                                id="manual_subject_search"
                                class="form-control lookup-input"
                                type="search"
                                autocomplete="off"
                                placeholder="اكتب اسم المادة أو كودها..."
                                data-url="{{ route('admin.attendance-edit-requests.lookup-subjects') }}"
                                data-target="manual_subject_id"
                            >
                            <div class="lookup-results"></div>
                        </div>
                        <div class="grant-field">
                            <label for="manual_date">التاريخ</label>
                            <input id="manual_date" type="date" name="date" class="form-control" value="{{ old('date') }}">
                        </div>
                    </div>
                </div>

                <div class="scope-panel" data-scope-panel="qr">
                    <div class="lookup-box">
                        <label for="manual_qr_search">جلسة QR</label>
                        <input
                            id="manual_qr_search"
                            class="form-control lookup-input"
                            type="search"
                            autocomplete="off"
                            placeholder="ابحث بعنوان الجلسة، المادة، المندوب أو التاريخ..."
                            data-url="{{ route('admin.attendance-edit-requests.lookup-qr-sessions') }}"
                            data-target="manual_qr_attendance_session_id"
                        >
                        <div class="lookup-results"></div>
                    </div>
                </div>
            </div>

            <div style="display:grid; gap:0.75rem;">
                <div class="grant-field">
                    <label for="manual_expires_hours">مدة الفتح بالساعات</label>
                    <input id="manual_expires_hours" type="number" name="expires_hours" class="form-control" min="1" max="168" value="{{ old('expires_hours', 2) }}" required>
                </div>
                <div class="grant-field">
                    <label for="manual_reason">سبب الفتح</label>
                    <input id="manual_reason" type="text" name="reason" class="form-control" value="{{ old('reason') }}" placeholder="مثال: تصحيح خطأ رصد">
                </div>
            </div>
        </div>

        <div class="grant-actions">
            <button class="btn btn-primary" type="submit">فتح التعديل</button>
        </div>
        <div class="grant-error" id="manualGrantError"></div>
    </form>
</div>

<div class="card" style="margin-bottom:1.5rem;">
    <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border-color); padding-bottom:1rem; margin-bottom:1rem; gap:1rem; flex-wrap:wrap;">
        <h3 style="font-size:1.1rem; font-weight:800; color:var(--text-primary); margin:0;">طلبات الفتح</h3>
        <form method="GET" class="filter-row">
            <select name="status" class="form-control" onchange="this.form.submit()">
                <option value="pending" @selected($status === 'pending')>المعلقة</option>
                <option value="approved" @selected($status === 'approved')>المقبولة</option>
                <option value="rejected" @selected($status === 'rejected')>المرفوضة</option>
                <option value="all" @selected($status === 'all')>الكل</option>
            </select>
        </form>
    </div>

    <div class="table-container">
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>المستخدم</th>
                        <th>النطاق</th>
                        <th>السبب</th>
                        <th>الحالة</th>
                        <th>تاريخ الطلب</th>
                        <th style="width:260px; text-align:center;">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($requests as $editRequest)
                        <tr>
                            <td>
                                <div style="font-weight:800;">{{ $editRequest->requester?->name ?? '-' }}</div>
                                <div style="font-size:0.85rem; color:var(--text-secondary);">
                                    {{ $editRequest->requester?->role?->value ?? '-' }}
                                    @if($editRequest->requester?->major || $editRequest->requester?->level)
                                        - {{ $editRequest->requester?->major?->name ?? '-' }} / {{ $editRequest->requester?->level?->name ?? '-' }}
                                    @endif
                                </div>
                            </td>
                            <td style="font-size:0.9rem;">
                                <strong>المادة:</strong> {{ $editRequest->subject?->name ?? 'غير رسمي / غير محدد' }}<br>
                                <strong>المحاضرة:</strong> {{ $editRequest->lecture?->title ?? $editRequest->qrSession?->title ?? $editRequest->title ?? '-' }}<br>
                                <strong>التاريخ:</strong> {{ $editRequest->date?->format('Y-m-d') ?? $editRequest->lecture?->date?->format('Y-m-d') ?? $editRequest->qrSession?->date?->format('Y-m-d') ?? '-' }}
                            </td>
                            <td style="max-width:280px;">{{ $editRequest->reason }}</td>
                            <td>
                                @if($editRequest->status === 'pending')
                                    <span class="badge badge-warning">معلق</span>
                                @elseif($editRequest->status === 'approved')
                                    <span class="badge badge-success">مقبول</span>
                                @elseif($editRequest->status === 'rejected')
                                    <span class="badge badge-danger">مرفوض</span>
                                @else
                                    <span class="badge">{{ $editRequest->status }}</span>
                                @endif
                                @if($editRequest->admin_note)
                                    <div style="font-size:0.8rem; color:var(--text-secondary); margin-top:0.35rem;">{{ $editRequest->admin_note }}</div>
                                @endif
                            </td>
                            <td style="font-size:0.85rem; color:var(--text-secondary);">
                                {{ $editRequest->created_at->format('Y-m-d H:i') }}<br>
                                {{ $editRequest->created_at->diffForHumans() }}
                            </td>
                            <td>
                                @if($editRequest->status === 'pending')
                                    <div style="display:grid; gap:0.5rem;">
                                        <form action="{{ route('admin.attendance-edit-requests.approve', $editRequest) }}" method="POST" style="display:grid; grid-template-columns:80px 1fr auto; gap:0.4rem;">
                                            @csrf
                                            <input type="number" name="expires_hours" class="form-control" min="1" max="168" value="2" title="الساعات">
                                            <input type="text" name="admin_note" class="form-control" placeholder="ملاحظة اختيارية">
                                            <button class="btn" style="background:#d1fae5; color:#059669;" type="submit">قبول</button>
                                        </form>
                                        <form action="{{ route('admin.attendance-edit-requests.reject', $editRequest) }}" method="POST" style="display:grid; grid-template-columns:1fr auto; gap:0.4rem;">
                                            @csrf
                                            <input type="text" name="admin_note" class="form-control" placeholder="سبب الرفض">
                                            <button class="btn" style="background:#fee2e2; color:#dc2626;" type="submit">رفض</button>
                                        </form>
                                    </div>
                                @else
                                    <span style="color:var(--text-secondary); font-size:0.85rem;">تمت المراجعة</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" style="text-align:center; padding:3rem; color:var(--text-secondary);">لا توجد طلبات ضمن هذا الفلتر.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div style="padding-top:1rem;">
        {{ $requests->links('pagination::bootstrap-5') }}
    </div>
</div>

<div class="card">
    <div style="border-bottom:1px solid var(--border-color); padding-bottom:1rem; margin-bottom:1rem;">
        <h3 style="font-size:1.1rem; font-weight:800; color:var(--text-primary); margin:0;">الصلاحيات النشطة</h3>
    </div>

    <div class="table-container">
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>المستخدم</th>
                        <th>النطاق</th>
                        <th>فتح بواسطة</th>
                        <th>ينتهي في</th>
                        <th style="width:120px; text-align:center;">الإجراء</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($activePermissions as $permission)
                        <tr>
                            <td>
                                <div style="font-weight:800;">{{ $permission->user?->name ?? '-' }}</div>
                                <div style="font-size:0.85rem; color:var(--text-secondary);">{{ $permission->user?->role?->value ?? '-' }}</div>
                            </td>
                            <td style="font-size:0.9rem;">
                                <strong>المادة:</strong> {{ $permission->subject?->name ?? 'غير رسمي / غير محدد' }}<br>
                                <strong>المحاضرة:</strong> {{ $permission->lecture?->title ?? $permission->qrSession?->title ?? '-' }}<br>
                                <strong>التاريخ:</strong> {{ $permission->date?->format('Y-m-d') ?? $permission->lecture?->date?->format('Y-m-d') ?? $permission->qrSession?->date?->format('Y-m-d') ?? '-' }}
                            </td>
                            <td>{{ $permission->grantedBy?->name ?? '-' }}</td>
                            <td>
                                <div style="font-weight:800;">{{ $permission->expires_at->format('Y-m-d H:i') }}</div>
                                <div style="font-size:0.8rem; color:var(--text-secondary);">{{ $permission->expires_at->diffForHumans() }}</div>
                            </td>
                            <td style="text-align:center;">
                                <form action="{{ route('admin.attendance-edit-permissions.revoke', $permission) }}" method="POST" onsubmit="return confirm('إغلاق صلاحية التعديل الآن؟');">
                                    @csrf
                                    <button class="btn" style="background:#fee2e2; color:#dc2626;" type="submit">إغلاق</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" style="text-align:center; padding:3rem; color:var(--text-secondary);">لا توجد صلاحيات نشطة الآن.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div style="padding-top:1rem;">
        {{ $activePermissions->links('pagination::bootstrap-5') }}
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('manualGrantForm');
    const scopeInputs = [...document.querySelectorAll('input[name="scope_type"]')];
    const panels = [...document.querySelectorAll('[data-scope-panel]')];

    function activeScope() {
        return scopeInputs.find((input) => input.checked)?.value || 'lecture';
    }

    function syncScopePanels() {
        const scope = activeScope();
        panels.forEach((panel) => panel.classList.toggle('is-active', panel.dataset.scopePanel === scope));

        if (scope !== 'lecture') {
            document.getElementById('manual_lecture_id').value = '';
            document.getElementById('manual_lecture_search').value = '';
        }
        if (scope !== 'subject_date') {
            document.getElementById('manual_subject_id').value = '';
            document.getElementById('manual_subject_search').value = '';
            document.getElementById('manual_date').value = '';
        }
        if (scope !== 'qr') {
            document.getElementById('manual_qr_attendance_session_id').value = '';
            document.getElementById('manual_qr_search').value = '';
        }
    }

    scopeInputs.forEach((input) => input.addEventListener('change', syncScopePanels));
    syncScopePanels();

    function closeAllResults(except = null) {
        document.querySelectorAll('.lookup-results.is-open').forEach((box) => {
            if (box !== except) box.classList.remove('is-open');
        });
    }

    function renderResults(container, items, input, target) {
        container.innerHTML = '';
        if (!items.length) {
            const empty = document.createElement('div');
            empty.className = 'lookup-item';
            empty.innerHTML = '<strong>لا توجد نتائج</strong><span>جرّب كلمات بحث مختلفة أو تاريخًا آخر.</span>';
            container.appendChild(empty);
            container.classList.add('is-open');
            return;
        }

        items.forEach((item) => {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'lookup-item';
            const title = document.createElement('strong');
            title.textContent = item.label || '-';
            const meta = document.createElement('span');
            meta.textContent = item.meta || '';
            button.appendChild(title);
            button.appendChild(meta);
            button.addEventListener('click', () => {
                input.value = item.label || '';
                target.value = item.id || '';
                container.classList.remove('is-open');
                input.dataset.selectedLabel = item.label || '';
            });
            container.appendChild(button);
        });
        container.classList.add('is-open');
    }

    document.querySelectorAll('.lookup-input').forEach((input) => {
        const container = input.closest('.lookup-box').querySelector('.lookup-results');
        const target = document.getElementById(input.dataset.target);
        let timer = null;

        input.addEventListener('input', () => {
            target.value = '';
            clearTimeout(timer);
            const query = input.value.trim();
            if (query.length < 2) {
                container.classList.remove('is-open');
                container.innerHTML = '';
                return;
            }

            timer = setTimeout(async () => {
                const url = new URL(input.dataset.url, window.location.origin);
                url.searchParams.set('q', query);
                closeAllResults(container);

                try {
                    const response = await fetch(url.toString(), {
                        headers: { 'Accept': 'application/json' },
                    });
                    const payload = await response.json();
                    renderResults(container, payload.results || [], input, target);
                } catch (error) {
                    container.innerHTML = '<div class="lookup-item"><strong>تعذر البحث الآن</strong><span>تحقق من الاتصال ثم حاول مرة أخرى.</span></div>';
                    container.classList.add('is-open');
                }
            }, 260);
        });

        input.addEventListener('focus', () => {
            if (container.children.length > 0) {
                closeAllResults(container);
                container.classList.add('is-open');
            }
        });

        input.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                container.classList.remove('is-open');
            }
        });
    });

    document.addEventListener('click', (event) => {
        if (!event.target.closest('.lookup-box')) {
            closeAllResults();
        }
    });

    form.addEventListener('submit', (event) => {
        const scope = activeScope();
        const userId = document.getElementById('manual_user_id').value;
        const lectureId = document.getElementById('manual_lecture_id').value;
        const subjectId = document.getElementById('manual_subject_id').value;
        const date = document.getElementById('manual_date').value;
        const qrId = document.getElementById('manual_qr_attendance_session_id').value;

        const errorBox = document.getElementById('manualGrantError');
        if (!userId || (scope === 'lecture' && !lectureId) || (scope === 'subject_date' && (!subjectId || !date)) || (scope === 'qr' && !qrId)) {
            event.preventDefault();
            errorBox.textContent = 'يرجى اختيار المستخدم والنطاق المطلوب قبل فتح التعديل.';
            errorBox.classList.add('is-visible');
        } else {
            errorBox.classList.remove('is-visible');
        }
    });
});
</script>

@endsection
