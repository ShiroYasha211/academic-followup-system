@extends('layouts.administrative')

@section('title', 'شؤون الطلاب')

@section('content')

<style>
    .welcome-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
    }
    
    .welcome-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -20%;
        width: 100%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .stat-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        border: 1px solid rgba(226, 232, 240, 0.8);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
    }

    .stat-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
        border-color: var(--primary-color);
    }

    .stat-icon {
        width: 60px;
        height: 60px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
    }

    .filter-card {
        background: white;
        border-radius: 24px;
        padding: 2rem;
        margin-bottom: 2.5rem;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .custom-select {
        width: 100%;
        height: 48px;
        padding: 0 1rem;
        border: 1.5px solid #edf2f7;
        border-radius: 14px;
        background: #f8fafc;
        font-weight: 600;
        cursor: pointer;
        outline: none;
        appearance: none;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%234a5568' stroke-width='2'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: left 1rem center;
        background-size: 1.25rem;
        transition: all 0.2s;
    }

    .custom-select:focus {
        border-color: var(--primary-color);
        background-color: white;
        box-shadow: 0 0 0 4px rgba(67, 56, 202, 0.1);
    }

    .student-table-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .role-badge {
        padding: 0.4rem 0.75rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 800;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .role-badge.delegate { color: #0369a1; background: #e0f2fe; border: 1.5px solid #bae6fd; }
    .role-badge.practical { color: #15803d; background: #f0fdf4; border: 1.5px solid #bbf7d0; }
    .role-badge.student { color: #64748b; background: #f8fafc; border: 1.5px solid #e2e8f0; }

    .role-btn {
        flex: 1;
        padding: 0.6rem 0.4rem;
        font-size: 0.75rem;
        border-radius: 10px;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.4rem;
        border: 1.5px solid #edf2f7;
        background: white;
        color: #64748b;
    }

    .role-btn:hover:not(:disabled) {
        border-color: #cbd5e0;
        background: #f8fafc;
        transform: translateY(-1px);
    }

    .role-btn.active {
        cursor: default;
        opacity: 0.5;
    }

    .role-btn.academic:not(.active) { border-color: rgba(67, 56, 202, 0.2); color: var(--primary-color); }
    .role-btn.academic.active { background: var(--primary-color); color: white; border-color: var(--primary-color); }

    .role-btn.practical:not(.active) { border-color: rgba(16, 185, 129, 0.2); color: var(--success-color); }
    .role-btn.practical.active { background: var(--success-color); color: white; border-color: var(--success-color); }

    /* Permissions Button */
    .perm-btn {
        padding: 0.45rem 0.85rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.25s;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        border: 1.5px solid #c4b5fd;
        background: #f5f3ff;
        color: #7c3aed;
    }
    .perm-btn:hover {
        background: #7c3aed;
        color: white;
        border-color: #7c3aed;
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(124, 58, 237, 0.25);
    }

    /* ─── Permissions Modal ─── */
    .perm-overlay {
        position: fixed; inset: 0;
        background: rgba(15, 23, 42, 0.6);
        backdrop-filter: blur(4px);
        z-index: 9998;
        opacity: 0;
        transition: opacity 0.3s ease;
        pointer-events: none;
    }
    .perm-overlay.active { opacity: 1; pointer-events: auto; }

    .perm-modal {
        position: fixed;
        top: 50%; left: 50%;
        transform: translate(-50%, -50%) scale(0.9);
        background: white;
        border-radius: 28px;
        width: 680px;
        max-height: 85vh;
        overflow-y: auto;
        z-index: 9999;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        opacity: 0;
        transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1);
        pointer-events: none;
    }
    .perm-modal.active { opacity: 1; transform: translate(-50%, -50%) scale(1); pointer-events: auto; }

    .perm-modal-header {
        background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
        padding: 2rem 2.5rem;
        border-radius: 28px 28px 0 0;
        color: white;
        position: relative;
    }

    .perm-modal-close {
        position: absolute;
        top: 1.25rem; left: 1.25rem;
        width: 36px; height: 36px;
        border-radius: 12px;
        background: rgba(255,255,255,0.15);
        border: none;
        color: white;
        cursor: pointer;
        display: flex; align-items: center; justify-content: center;
        font-size: 1.1rem;
        transition: all 0.2s;
    }
    .perm-modal-close:hover { background: rgba(255,255,255,0.3); transform: scale(1.1); }

    .perm-modal-body { padding: 2rem 2.5rem; }

    /* Toggle Switch */
    .toggle-switch {
        position: relative;
        width: 48px; height: 26px;
        cursor: pointer;
    }
    .toggle-switch input { opacity: 0; width: 0; height: 0; }
    .toggle-slider {
        position: absolute; inset: 0;
        background: #e2e8f0;
        border-radius: 26px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .toggle-slider::before {
        content: '';
        position: absolute;
        height: 20px; width: 20px;
        right: 3px; bottom: 3px;
        background: white;
        border-radius: 50%;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        box-shadow: 0 2px 4px rgba(0,0,0,0.15);
    }
    .toggle-switch input:checked + .toggle-slider { background: #7c3aed; }
    .toggle-switch input:checked + .toggle-slider::before { transform: translateX(-22px); }

    /* Resource Row */
    .perm-resource-row {
        background: #fafbfc;
        border-radius: 16px;
        padding: 1.25rem 1.5rem;
        margin-bottom: 0.75rem;
        border: 1px solid #f1f5f9;
        transition: all 0.2s;
    }
    .perm-resource-row:hover { border-color: #e0d4f5; background: #faf8ff; }

    .perm-action-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
        margin-top: 1rem;
    }

    .perm-action-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        background: white;
        padding: 0.75rem 1rem;
        border-radius: 12px;
        border: 1px solid #f1f5f9;
    }

    .perm-action-label {
        font-size: 0.82rem;
        font-weight: 700;
        color: #475569;
    }

    /* Quick Actions */
    .perm-quick-actions {
        display: flex;
        gap: 0.75rem;
        margin-bottom: 1.5rem;
    }
    .perm-quick-btn {
        flex: 1;
        padding: 0.7rem;
        border-radius: 12px;
        font-size: 0.82rem;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        border: 1.5px solid #e2e8f0;
        background: white;
    }
    .perm-quick-btn.grant-all {
        color: #059669; border-color: #a7f3d0;
    }
    .perm-quick-btn.grant-all:hover {
        background: #059669; color: white; border-color: #059669;
    }
    .perm-quick-btn.revoke-all {
        color: #dc2626; border-color: #fecaca;
    }
    .perm-quick-btn.revoke-all:hover {
        background: #dc2626; color: white; border-color: #dc2626;
    }

    .perm-save-btn {
        width: 100%;
        padding: 1rem;
        background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
        color: white;
        border: none;
        border-radius: 14px;
        font-size: 1.05rem;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.3s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.75rem;
        margin-top: 1.5rem;
    }
    .perm-save-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(124, 58, 237, 0.3);
    }

    .perm-counter {
        background: rgba(255,255,255,0.2);
        padding: 0.25rem 0.75rem;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
    }
</style>

<!-- Welcome Hero -->
<div class="welcome-hero">
    <div style="position: relative; z-index: 1;">
        <h1 style="font-size: 2.25rem; font-weight: 800; margin-bottom: 0.5rem; letter-spacing: -0.02em;">بوابة إدارة الطلاب</h1>
        <p style="opacity: 0.85; font-size: 1.1rem; font-weight: 500;">إدارة شاملة لبيانات الطلاب، توزيع المناديب، ومتابعة القائمة الأكاديمية بكلية {{ auth()->user()->college->name }}</p>
    </div>
</div>

<!-- Stats Bar -->
<div style="display: grid; grid-template-columns: repeat({{ $has_clinical_major ? 3 : 2 }}, 1fr); gap: 1.5rem; margin-bottom: 2.5rem;">
    <div class="stat-card">
        <div class="stat-icon" style="background: #eef2ff; color: #4338ca;">
            <i class="fa-solid fa-user-graduate"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: #64748b; font-weight: 700;">إجمالي الطلاب</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: #1e293b;">{{ number_format($stats['total_students']) }}</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: #e0f2fe; color: #0369a1;">
            <i class="fa-solid fa-star"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: #64748b; font-weight: 700;">المناديب الأكاديميين</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: #1e293b;">{{ number_format($stats['academic_delegates']) }}</div>
        </div>
    </div>

    @if($has_clinical_major)
    <div class="stat-card">
        <div class="stat-icon" style="background: #f0fdf4; color: #15803d;">
            <i class="fa-solid fa-flask"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: #64748b; font-weight: 700;">مناديب العملي</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: #1e293b;">{{ number_format($stats['practical_delegates']) }}</div>
        </div>
    </div>
    @endif
</div>

<!-- Advanced Filter Center -->
<div class="filter-card">
    <form action="{{ route('administrative.delegates.index') }}" method="GET">
        <div style="display: grid; grid-template-columns: 2fr 1.2fr 1.2fr 1.2fr auto; gap: 1.25rem; align-items: flex-end;">
            <!-- Search -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: var(--text-primary);">البحث الذكي</label>
                <div style="position: relative;">
                    <input type="text" name="search" value="{{ request('search') }}" 
                           placeholder="الاسم، البريد، الرقم الجامعي..." 
                           style="width: 100%; height: 48px; padding: 0 1rem 0 3rem; border: 1.5px solid #edf2f7; border-radius: 14px; font-size: 0.95rem; outline: none; transition: all 0.3s ease; background: #f8fafc;">
                    <i class="fa-solid fa-magnifying-glass" style="position: absolute; left: 1.25rem; top: 50%; transform: translateY(-50%); color: #a0aec0; font-size: 1.1rem;"></i>
                </div>
            </div>

            <!-- Major Filter -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: var(--text-primary);">التخصص</label>
                <select name="major_id" class="custom-select" onchange="this.form.submit()">
                    <option value="">جميع التخصصات</option>
                    @foreach($majors as $major)
                        <option value="{{ $major->id }}" {{ request('major_id') == $major->id ? 'selected' : '' }}>{{ $major->name }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Level Filter -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: var(--text-primary);">المستوى</label>
                <select name="level_id" class="custom-select" {{ empty($levels) && !request('level_id') ? 'disabled' : '' }} onchange="this.form.submit()">
                    <option value="">جميع المستويات</option>
                    @foreach($levels as $level)
                        <option value="{{ $level->id }}" {{ request('level_id') == $level->id ? 'selected' : '' }}>{{ $level->name }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Role Filter -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: var(--text-primary);">التصنيف</label>
                <select name="role" class="custom-select" onchange="this.form.submit()">
                    <option value="all">الكل</option>
                    <option value="student" {{ request('role') == 'student' ? 'selected' : '' }}>طلاب فقط</option>
                    <option value="delegate" {{ request('role') == 'delegate' ? 'selected' : '' }}>مناديب</option>
                    @if($has_clinical_major)
                        <option value="practical_delegate" {{ request('role') == 'practical_delegate' ? 'selected' : '' }}>مناديب عملي</option>
                    @endif
                </select>
            </div>

            <!-- Clean Filters -->
            <div>
                <a href="{{ route('administrative.delegates.index') }}" title="إعادة تعيين" style="display: flex; align-items: center; justify-content: center; width: 48px; height: 48px; background: #fee2e2; color: #ef4444; border-radius: 14px; transition: all 0.2s; border: none;">
                    <i class="fa-solid fa-arrows-rotate"></i>
                </a>
            </div>
        </div>
    </form>
</div>

<!-- Students Table -->
<div class="student-table-card">
    <div class="table-responsive">
        <table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #fcfdfe; border-bottom: 2px solid #f1f5f9;">
                    <th style="padding: 1.25rem 2rem; text-align: right; font-weight: 800; font-size: 0.85rem; color: #64748b; text-transform: uppercase;">هوية الطالب</th>
                    <th style="padding: 1.25rem 1rem; text-align: right; font-weight: 800; font-size: 0.85rem; color: #64748b;">التخصص</th>
                    <th style="padding: 1.25rem 1rem; text-align: center; font-weight: 800; font-size: 0.85rem; color: #64748b;">المستوى</th>
                    <th style="padding: 1.25rem 1rem; text-align: center; font-weight: 800; font-size: 0.85rem; color: #64748b;">الدور الحالي</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: center; font-weight: 800; font-size: 0.85rem; color: #64748b; width: 280px;">تعديل الدور</th>
                    <th style="padding: 1.25rem 1rem; text-align: center; font-weight: 800; font-size: 0.85rem; color: #64748b; width: 120px;">الصلاحيات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($users as $user)
                    <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.2s;" onmouseover="this.style.background='#fcfdfe'" onmouseout="this.style.background='white'">
                        <td style="padding: 1.25rem 2rem;">
                            <div style="display: flex; align-items: center; gap: 1.25rem;">
                                <div style="width: 48px; height: 48px; border-radius: 14px; background: #f1f5f9; color: #4338ca; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 1.1rem; border: 1px solid #e2e8f0;">
                                    {{ mb_substr($user->name, 0, 1) }}
                                </div>
                                <div>
                                    <div style="font-weight: 700; color: #1e293b; font-size: 0.95rem; margin-bottom: 0.2rem;">{{ $user->name }}</div>
                                    <div style="font-size: 0.8rem; color: #64748b; display: flex; align-items: center; gap: 0.5rem;">
                                        <span>{{ $user->student_number ?? '---' }}</span>
                                        <span style="opacity: 0.3;">|</span>
                                        <span>{{ $user->email }}</span>
                                    </div>
                                </div>
                            </div>
                        </td>
                        <td style="padding: 1.25rem 1rem;">
                            <span style="font-weight: 600; color: #334155; font-size: 0.9rem;">{{ $user->major->name ?? '-' }}</span>
                        </td>
                        <td style="padding: 1.25rem 1rem; text-align: center;">
                            <span style="background: #f8fafc; color: #475569; padding: 0.35rem 0.85rem; border-radius: 8px; font-size: 0.8rem; font-weight: 700; border: 1px solid #e2e8f0;">
                                {{ $user->level->name ?? '-' }}
                            </span>
                        </td>
                        <td style="padding: 1.25rem 1rem; text-align: center;">
                            @if($user->role->value == 'delegate')
                                <span class="role-badge delegate"><i class="fa-solid fa-star"></i> مندوب</span>
                            @elseif($user->role->value == 'practical_delegate')
                                <span class="role-badge practical"><i class="fa-solid fa-flask"></i> مندوب عملي</span>
                            @else
                                <span class="role-badge student">طالب</span>
                            @endif
                        </td>
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            <form action="{{ route('administrative.delegates.update-role', $user->id) }}" method="POST" style="display: flex; gap: 0.5rem; justify-content: center;">
                                @csrf
                                @method('PATCH')
                                
                                <button type="submit" name="role" value="student" 
                                        class="role-btn {{ $user->role->value == 'student' ? 'active' : '' }}" 
                                        {{ $user->role->value == 'student' ? 'disabled' : '' }}>
                                    طالب
                                </button>
                                
                                <button type="submit" name="role" value="delegate" 
                                        class="role-btn academic {{ $user->role->value == 'delegate' ? 'active' : '' }}" 
                                        {{ $user->role->value == 'delegate' ? 'disabled' : '' }}>
                                    مندوب
                                </button>
                                
                                @if($user->major && $user->major->has_clinical)
                                    <button type="submit" name="role" value="practical_delegate" 
                                            class="role-btn practical {{ $user->role->value == 'practical_delegate' ? 'active' : '' }}" 
                                            {{ $user->role->value == 'practical_delegate' ? 'disabled' : '' }}>
                                        عملي
                                    </button>
                                @endif
                            </form>
                        </td>
                        <td style="padding: 1.25rem 1rem; text-align: center;">
                            @if(in_array($user->role->value, ['delegate', 'practical_delegate']))
                                @php
                                    $userPerms = $user->delegatePermissions->map(fn($p) => $p->resource . '.' . $p->action)->toArray();
                                    $permCount = count($userPerms);
                                @endphp
                                <button class="perm-btn" onclick="openPermModal({{ $user->id }}, '{{ addslashes($user->name) }}', {{ json_encode($userPerms) }})">
                                    <i class="fa-solid fa-shield-halved"></i>
                                    <span>{{ $permCount }}/12</span>
                                </button>
                            @else
                                <span style="font-size: 0.75rem; color: #94a3b8; font-weight: 600;">—</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" style="text-align: center; padding: 5rem 2rem;">
                            <div style="color: #cbd5e1; font-size: 3rem; margin-bottom: 1rem;"><i class="fa-solid fa-user-slash"></i></div>
                            <h3 style="color: #64748b; font-size: 1.1rem; font-weight: 700;">لا يوجد طلاب حالياً</h3>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    <div style="padding: 1.5rem 2rem; background: #fcfdfe; border-top: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between;">
        <div style="font-size: 0.85rem; color: #64748b; font-weight: 600;">
            إجمالي الصفوف: <span style="color: #1e293b;">{{ $users->total() }}</span>
        </div>
        <div>
            {{ $users->withQueryString()->links() }}
        </div>
    </div>
</div>

<!-- ═══════════ Permissions Modal ═══════════ -->
<div class="perm-overlay" id="permOverlay" onclick="closePermModal()"></div>
<div class="perm-modal" id="permModal">
    <div class="perm-modal-header">
        <button class="perm-modal-close" onclick="closePermModal()"><i class="fa-solid fa-xmark"></i></button>
        <div style="display: flex; align-items: center; gap: 1rem;">
            <div style="width: 50px; height: 50px; border-radius: 16px; background: rgba(255,255,255,0.15); display: flex; align-items: center; justify-content: center; font-size: 1.3rem;">
                <i class="fa-solid fa-shield-halved"></i>
            </div>
            <div>
                <h2 style="font-size: 1.3rem; font-weight: 800; margin: 0;">إدارة الصلاحيات</h2>
                <p style="opacity: 0.8; font-size: 0.9rem; margin: 0.25rem 0 0 0;" id="permModalName">—</p>
            </div>
        </div>
    </div>

    <div class="perm-modal-body">
        <form id="permForm" method="POST">
            @csrf

            <!-- Quick Actions -->
            <div class="perm-quick-actions">
                <button type="button" class="perm-quick-btn grant-all" onclick="toggleAllPerms(true)">
                    <i class="fa-solid fa-check-double"></i> تفعيل الكل
                </button>
                <button type="button" class="perm-quick-btn revoke-all" onclick="toggleAllPerms(false)">
                    <i class="fa-solid fa-ban"></i> تعطيل الكل
                </button>
            </div>

            @php
                $resources = \App\Models\DelegatePermission::RESOURCES;
                $actions = \App\Models\DelegatePermission::ACTIONS;
                $icons = \App\Models\DelegatePermission::RESOURCE_ICONS;
                $actionIcons = [
                    'create' => 'fa-solid fa-plus',
                    'update' => 'fa-solid fa-pen',
                    'delete' => 'fa-solid fa-trash',
                ];
                $actionColors = [
                    'create' => '#059669',
                    'update' => '#2563eb',
                    'delete' => '#dc2626',
                ];
            @endphp

            @foreach($resources as $resKey => $resLabel)
                <div class="perm-resource-row">
                    <div style="display: flex; align-items: center; gap: 0.75rem;">
                        <div style="width: 38px; height: 38px; border-radius: 12px; background: #f5f3ff; color: #7c3aed; display: flex; align-items: center; justify-content: center; font-size: 1rem;">
                            <i class="{{ $icons[$resKey] }}"></i>
                        </div>
                        <span style="font-weight: 800; color: #1e293b; font-size: 0.95rem;">{{ $resLabel }}</span>
                    </div>
                    <div class="perm-action-grid">
                        @foreach($actions as $actKey => $actLabel)
                            <div class="perm-action-item">
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <i class="{{ $actionIcons[$actKey] }}" style="color: {{ $actionColors[$actKey] }}; font-size: 0.75rem;"></i>
                                    <span class="perm-action-label">{{ $actLabel }}</span>
                                </div>
                                <label class="toggle-switch">
                                    <input type="checkbox" name="permissions[]" value="{{ $resKey }}.{{ $actKey }}" class="perm-checkbox" onchange="updatePermCounter()">
                                    <span class="toggle-slider"></span>
                                </label>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endforeach

            <button type="submit" class="perm-save-btn">
                <i class="fa-solid fa-floppy-disk"></i>
                حفظ الصلاحيات
                <span class="perm-counter" id="permCounter">0/12</span>
            </button>
        </form>
    </div>
</div>

@if(session('success'))
    <div style="position: fixed; bottom: 2rem; left: 2rem; background: #10b981; color: white; padding: 1rem 2rem; border-radius: 16px; box-shadow: 0 10px 25px rgba(16, 185, 129, 0.2); font-weight: 700; z-index: 1000; display: flex; align-items: center; gap: 1rem;" x-data="{ show: true }" x-show="show" x-init="setTimeout(() => show = false, 4000)">
        <i class="fa-solid fa-circle-check"></i>
        <span>{{ session('success') }}</span>
    </div>
@endif

@if(session('error'))
    <div style="position: fixed; bottom: 2rem; left: 2rem; background: #ef4444; color: white; padding: 1rem 2rem; border-radius: 16px; box-shadow: 0 10px 25px rgba(239, 68, 68, 0.2); font-weight: 700; z-index: 1000; display: flex; align-items: center; gap: 1rem;" x-data="{ show: true }" x-show="show" x-init="setTimeout(() => show = false, 4000)">
        <i class="fa-solid fa-circle-xmark"></i>
        <span>{{ session('error') }}</span>
    </div>
@endif

<script>
function openPermModal(userId, userName, currentPerms) {
    document.getElementById('permForm').action = '/administrative/delegates/' + userId + '/permissions';
    document.getElementById('permModalName').textContent = userName;

    // Reset all checkboxes
    document.querySelectorAll('.perm-checkbox').forEach(cb => cb.checked = false);

    // Set current permissions
    currentPerms.forEach(perm => {
        const cb = document.querySelector('.perm-checkbox[value="' + perm + '"]');
        if (cb) cb.checked = true;
    });

    updatePermCounter();

    document.getElementById('permOverlay').classList.add('active');
    document.getElementById('permModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closePermModal() {
    document.getElementById('permOverlay').classList.remove('active');
    document.getElementById('permModal').classList.remove('active');
    document.body.style.overflow = '';
}

function toggleAllPerms(state) {
    document.querySelectorAll('.perm-checkbox').forEach(cb => cb.checked = state);
    updatePermCounter();
}

function updatePermCounter() {
    const total = document.querySelectorAll('.perm-checkbox').length;
    const checked = document.querySelectorAll('.perm-checkbox:checked').length;
    document.getElementById('permCounter').textContent = checked + '/' + total;
}

// Close modal on Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closePermModal();
});
</script>

@endsection
