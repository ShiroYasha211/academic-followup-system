@extends('layouts.delegate')

@section('title', 'إدارة تفويض الطلاب')

@section('content')
<style>
    .modal-overlay {
        backdrop-filter: blur(4px);
        background: rgba(15, 23, 42, 0.4);
    }
    
    .modal-container {
        animation: modalSlideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        border: 1px solid rgba(255, 255, 255, 0.2);
    }
    
    @keyframes modalSlideUp {
        from { transform: translateY(40px); opacity: 0; }
        to { transform: translateY(0); opacity: 1; }
    }

    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
        flex-wrap: wrap;
        gap: 1.5rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.8rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.3rem 0;
        letter-spacing: -0.5px;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.95rem;
        margin: 0;
    }

    .btn-primary-action {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-weight: 700;
        font-size: 0.9rem;
        cursor: pointer;
        transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        display: inline-flex;
        align-items: center;
        gap: 0.6rem;
        text-decoration: none;
        box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);
    }

    .btn-primary-action:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(79, 70, 229, 0.4);
        color: white;
    }

    .card-section {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .table-modern {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0 0.75rem;
    }

    .table-modern th {
        padding: 1rem 1.5rem;
        color: #64748b;
        font-weight: 700;
        text-transform: uppercase;
        font-size: 0.75rem;
        letter-spacing: 0.05em;
        border: none;
    }

    .table-modern tbody tr {
        background: white;
        transition: all 0.2s;
    }

    .table-modern tbody tr:hover {
        transform: scale(1.002);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    }

    .table-modern td {
        padding: 1.25rem 1.5rem;
        vertical-align: middle;
        border-top: 1px solid #f1f5f9;
        border-bottom: 1px solid #f1f5f9;
    }

    .table-modern td:first-child {
        border-right: 1px solid #f1f5f9;
        border-top-right-radius: 16px;
        border-bottom-right-radius: 16px;
    }

    .table-modern td:last-child {
        border-left: 1px solid #f1f5f9;
        border-top-left-radius: 16px;
        border-bottom-left-radius: 16px;
    }

    .status-badge {
        padding: 0.4rem 0.8rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .status-active { background: #ecfdf5; color: #059669; border: 1px solid #10b98133; }
    .status-expired { background: #f1f5f9; color: #64748b; border: 1px solid #cbd5e133; }
    .status-revoked { background: #fef2f2; color: #dc2626; border: 1px solid #ef444433; }

    .student-info {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .student-avatar {
        width: 40px;
        height: 40px;
        background: linear-gradient(135deg, #e0e7ff, #c7d2fe);
        color: #4338ca;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 1rem;
    }

    .form-label-premium {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 700;
        color: #334155;
        font-size: 0.9rem;
    }

    .form-input-premium {
        width: 100%;
        padding: 0.85rem 1rem;
        border: 2px solid #f1f5f9;
        border-radius: 14px;
        transition: all 0.2s;
        outline: none;
        background: #f8fafc;
    }

    .form-input-premium:focus {
        border-color: #6366f1;
        background: white;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
    }
</style>

<div x-data="{ showModal: false }">
    {{-- ====== Page Header ====== --}}
    <div class="clinical-page-header">
        <div class="right-side">
            <h1>نظام التفويض السريري 🔓</h1>
            <p>إدارة ومنح صلاحيات تسجيل الحالات للطلاب المتميزين</p>
        </div>
        <div class="left-side">
            <button @click="showModal = true" class="btn-primary-action">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                منح صلاحية جديدة
            </button>
        </div>
    </div>

    @if(session('success'))
        <div style="background: #ecfdf5; color: #065f46; padding: 1rem; border-radius: 16px; border: 1px solid #6ee7b7; margin-bottom: 1.5rem; font-weight: 600; display: flex; align-items: center; gap: 0.75rem;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"></polyline></svg>
            {{ session('success') }}
        </div>
    @endif

    @if(session('error'))
        <div style="background: #fef2f2; color: #991b1b; padding: 1rem; border-radius: 16px; border: 1px solid #fca5a5; margin-bottom: 1.5rem; font-weight: 600; display: flex; align-items: center; gap: 0.75rem;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
            {{ session('error') }}
        </div>
    @endif

    {{-- ====== Content Section ====== --}}
    <div class="card-section">
        <div style="overflow-x: auto;">
            <table class="table-modern">
                <thead>
                    <tr>
                        <th width="35%">الطالب المفوَّض</th>
                        <th width="20%">تاريخ المنح</th>
                        <th width="20%">وقت الانتهاء</th>
                        <th width="15%">الحالة</th>
                        <th width="10%" style="text-align: center;">إجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($subDelegations as $delegation)
                        <tr>
                            <td>
                                <div class="student-info">
                                    <div class="student-avatar">{{ mb_substr($delegation->student->name, 0, 1) }}</div>
                                    <div>
                                        <div style="font-weight: 800; color: #1e293b; font-size: 0.95rem;">{{ $delegation->student->name }}</div>
                                        <div style="font-size: 0.75rem; color: #64748b; font-weight: 600;">ID: {{ $delegation->student->university_id }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #475569; font-size: 0.85rem;">
                                    {{ $delegation->created_at->format('Y-m-d') }}
                                    <span style="display: block; font-size: 0.7rem; opacity: 0.7;">{{ $delegation->created_at->format('h:i A') }}</span>
                                </div>
                            </td>
                            <td>
                                <div style="font-weight: 700; color: #6366f1; font-size: 0.85rem;">
                                    {{ $delegation->expires_at ? $delegation->expires_at->format('Y-m-d') : 'دائم' }}
                                    @if($delegation->expires_at)
                                        <span style="display: block; font-size: 0.7rem; opacity: 0.7;">{{ $delegation->expires_at->format('h:i A') }}</span>
                                    @endif
                                </div>
                            </td>
                            <td>
                                @if($delegation->is_revoked)
                                    <span class="status-badge status-revoked">سحب الصلاحية</span>
                                @elseif($delegation->expires_at && $delegation->expires_at->isPast())
                                    <span class="status-badge status-expired">انتهت المدة</span>
                                @else
                                    <span class="status-badge status-active">فعّال الآن</span>
                                @endif
                            </td>
                            <td style="text-align: center;">
                                @if(!$delegation->is_revoked && (!$delegation->expires_at || $delegation->expires_at->isFuture()))
                                    <form action="{{ route('delegate.clinical.delegations.revoke', $delegation) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من سحب الصلاحية فوراً؟');">
                                        @csrf
                                        @method('PATCH')
                                        <button type="submit" style="background: #fef2f2; color: #ef4444; border: 1px solid #ef444433; padding: 0.5rem; border-radius: 10px; cursor: pointer; transition: all 0.2s;" title="إيقاف">
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                <circle cx="12" cy="12" r="10"></circle>
                                                <line x1="15" y1="9" x2="9" y2="15"></line>
                                                <line x1="9" y1="9" x2="15" y2="15"></line>
                                            </svg>
                                        </button>
                                    </form>
                                @else
                                    <span style="color: #cbd5e1;">-</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" style="text-align: center; padding: 4rem 1rem;">
                                <div style="width: 64px; height: 64px; background: #f8fafc; color: #cbd5e1; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem;">
                                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                        <circle cx="9" cy="7" r="4"></circle>
                                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                                        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                                    </svg>
                                </div>
                                <p style="color: #64748b; font-weight: 600;">لا يوجد طلاب مفوضون حالياً</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div style="margin-top: 1.5rem;">
            {{ $subDelegations->links() }}
        </div>
    </div>

    {{-- ====== Premium Modal ====== --}}
    <div x-show="showModal" 
         class="modal-overlay" 
         style="display: none; position: fixed; inset: 0; z-index: 9999; display: flex; align-items: center; justify-content: center; padding: 1.5rem;" 
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0"
         x-transition:enter-end="opacity-100"
         x-transition:leave="transition ease-in duration-200"
         x-transition:leave-start="opacity-100"
         x-transition:leave-end="opacity-0">
        
        <div class="modal-container" 
             @click.away="showModal = false" 
             style="background: white; border-radius: 32px; width: 100%; max-width: 500px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25); overflow: hidden;">
            
            <div style="background: linear-gradient(135deg, #4f46e5, #6366f1); padding: 2rem; color: white; position: relative; overflow: hidden;">
                <div style="position: absolute; top: -20px; right: -20px; width: 120px; height: 120px; background: rgba(255,255,255,0.1); border-radius: 50%;"></div>
                <h3 style="margin: 0; font-size: 1.4rem; font-weight: 850; letter-spacing: -0.5px;">منح صلاحية جديدة 🔐</h3>
                <p style="margin: 0.5rem 0 0 ; font-size: 0.9rem; opacity: 0.9;">اختر طالباً من دفعتك لمنحه صلاحية تسجيل الحالات</p>
                <button @click="showModal = false" style="position: absolute; top: 1.5rem; left: 1.5rem; background: rgba(0,0,0,0.2); border: none; width: 32px; height: 32px; border-radius: 50%; color: white; cursor: pointer; display: flex; align-items: center; justify-content: center; font-weight: 900;">&times;</button>
            </div>

            <form action="{{ route('delegate.clinical.delegations.store') }}" method="POST" style="padding: 2rem;">
                @csrf
                <div style="margin-bottom: 1.5rem;">
                    <label class="form-label-premium">اختيار الطالب</label>
                    <select name="student_id" class="form-input-premium" required>
                        <option value="" disabled selected>-- ابحث عن طالب --</option>
                        @foreach($students as $student)
                            <option value="{{ $student->id }}">{{ $student->name }} ({{ $student->university_id }})</option>
                        @endforeach
                    </select>
                </div>

                <div style="margin-bottom: 2rem;">
                    <label class="form-label-premium">فترة الصلاحية</label>
                    <select name="duration_hours" class="form-input-premium" required>
                        <option value="6">6 ساعات</option>
                        <option value="12">12 ساعة</option>
                        <option value="24" selected>يوم واحد (24 ساعة)</option>
                        <option value="48">يومين (48 ساعة)</option>
                        <option value="72">3 أيام</option>
                        <option value="168">أسبوع كامل</option>
                    </select>
                    <p style="font-size: 0.75rem; color: #64748b; margin-top: 0.5rem; font-weight: 500;">سيتحول حساب الطالب تلقائياً إلى وضع "المندوب الفرعي" طوال هذه الفترة.</p>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                    <button type="button" @click="showModal = false" style="padding: 0.85rem; border: none; border-radius: 14px; background: #f1f5f9; color: #475569; font-weight: 700; cursor: pointer; transition: all 0.2s;">إلغاء</button>
                    <button type="submit" style="padding: 0.85rem; border: none; border-radius: 14px; background: linear-gradient(135deg, #4f46e5, #6366f1); color: white; font-weight: 700; cursor: pointer; transition: all 0.2s; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.2);">تأكيد المنح</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
