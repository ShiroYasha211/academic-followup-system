@php
    $layout = 'layouts.doctor';
    if (request()->is('delegate/*')) $layout = 'layouts.delegate';
    elseif (request()->is('student/*')) $layout = 'layouts.student';
@endphp
@extends($layout)

@section('title', 'مراجعة الحالات المعلقة')

@section('content')
<style>
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
        font-weight: 850;
        color: var(--text-primary);
        margin: 0;
        letter-spacing: -0.5px;
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
        border: none;
    }

    .table-modern tbody tr {
        background: white;
        transition: all 0.2s;
    }

    .table-modern td {
        padding: 1.25rem 1.5rem;
        vertical-align: middle;
        border-top: 1px solid #f1f5f9;
        border-bottom: 1px solid #f1f5f9;
    }

    .table-modern td:first-child { border-right: 1px solid #f1f5f9; border-radius: 0 16px 16px 0; }
    .table-modern td:last-child { border-left: 1px solid #f1f5f9; border-radius: 16px 0 0 16px; }

    .status-badge {
        padding: 0.4rem 0.8rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .status-pending { background: #fffbeb; color: #d97706; border: 1px solid #f59e0b33; }
    .status-rejected { background: #fef2f2; color: #dc2626; border: 1px solid #ef444433; }

    .action-btn {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
        border: 1px solid transparent;
        cursor: pointer;
    }

    .btn-approve { background: #ecfdf5; color: #10b981; border-color: #10b98133; }
    .btn-approve:hover { background: #10b981; color: white; }
    .btn-reject { background: #fef2f2; color: #ef4444; border-color: #ef444433; }
    .btn-reject:hover { background: #ef4444; color: white; }
    
    .rejection-info {
        background: #fff1f2;
        border: 1px solid #fda4af;
        padding: 0.75rem;
        border-radius: 12px;
        margin-top: 0.5rem;
        font-size: 0.85rem;
        color: #9f1239;
    }
</style>

<div x-data="{ 
    showRejectModal: false, 
    caseToReject: null,
    rejectionReason: ''
}">
    <div class="clinical-page-header">
        <div class="right-side">
            <h1>📋 مراجعة الحالات المعلقة</h1>
            <p class="text-muted">هذه الحالات مضافة من قبل المندوبين الفرعيين وتنتظر الاعتماد لتظهر للجميع.</p>
        </div>
    </div>

    @if(session('success'))
        <div style="background: #ecfdf5; color: #065f46; padding: 1rem; border-radius: 16px; border: 1px solid #6ee7b7; margin-bottom: 1.5rem; font-weight: 600;">
            {{ session('success') }}
        </div>
    @endif

    <div class="card-section">
        <div style="overflow-x: auto;">
            <table class="table-modern">
                <thead>
                    <tr>
                        <th>المريض</th>
                        <th>بواسطة</th>
                        <th>التاريخ</th>
                        <th>الحالة</th>
                        <th style="text-align: center;">إجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($cases as $case)
                        <tr>
                            <td>
                                <div style="font-weight: 800; color: #1e293b;">{{ $case->patient_name }}</div>
                                <div style="font-size: 0.75rem; color: #64748b;">{{ $case->clinicalDepartment->name }} • {{ $case->trainingCenter->name }}</div>
                            </td>
                            <td>
                                <div style="font-weight: 600; font-size: 0.85rem;">{{ $case->doctor->name }}</div>
                                <div style="font-size: 0.7rem; color: #94a3b8;">{{ $case->doctor->university_id }}</div>
                            </td>
                            <td>
                                <div style="font-size: 0.85rem; font-weight: 500;">{{ $case->created_at->format('Y-m-d') }}</div>
                                <div style="font-size: 0.7rem; opacity: 0.6;">{{ $case->created_at->format('h:i A') }}</div>
                            </td>
                            <td>
                                @if($case->approval_status === 'pending')
                                    <span class="status-badge status-pending">قيد المراجعة</span>
                                @elseif($case->approval_status === 'rejected')
                                    <span class="status-badge status-rejected">مرفوضة</span>
                                @endif
                                
                                @if($case->approval_status === 'rejected' && $case->rejection_reason)
                                    <div class="rejection-info">
                                        <strong>سبب الرفض:</strong> {{ $case->rejection_reason }}
                                    </div>
                                @endif
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem; justify-content: center;">
                                    @if(Auth::user()->isClinicalDelegate() && $case->approval_status === 'pending')
                                        {{-- Actions for Main Delegate --}}
                                        <form action="{{ route('delegate.clinical.cases.approve', $case) }}" method="POST">
                                            @csrf
                                            <button type="submit" class="action-btn btn-approve" title="اعتماد">
                                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"></polyline></svg>
                                            </button>
                                        </form>
                                        
                                        <button @click="caseToReject = {{ $case->id }}; showRejectModal = true" class="action-btn btn-reject" title="رفض">
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                                        </button>
                                    @endif
                                    
                                    @if($case->doctor_id === Auth::id())
                                        {{-- Actions for the Sub-delegate who added it --}}
                                        <a href="{{ route(request()->is('student/*') ? 'student.clinical.cases.edit' : 'delegate.clinical.cases.edit', $case) }}" class="action-btn" style="background: #f1f5f9; color: #475569;" title="تعديل">
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                                        </a>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" style="text-align: center; padding: 4rem 1rem;">
                                <div style="color: #cbd5e1; margin-bottom: 1rem;">
                                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin: 0 auto;">
                                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                        <polyline points="14 2 14 8 20 8"></polyline>
                                        <path d="M9 15h6"></path>
                                        <path d="M9 19h6"></path>
                                    </svg>
                                </div>
                                <p style="color: #64748b; font-weight: 600;">لا توجد حالات معلقة حالياً</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div style="margin-top: 1.5rem;">
            {{ $cases->links() }}
        </div>
    </div>

    {{-- Rejection Modal --}}
    <div x-show="showRejectModal" 
         style="display: none; position: fixed; inset: 0; z-index: 9999; display: flex; align-items: center; justify-content: center; padding: 1.5rem; background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(4px);">
        <div @click.away="showRejectModal = false" style="background: white; border-radius: 24px; width: 100%; max-width: 450px; padding: 2rem; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);">
            <h3 style="margin-top: 0; font-weight: 850; color: #1e293b; margin-bottom: 1rem;">رفض الحالة ❌</h3>
            <p style="color: #64748b; font-size: 0.9rem; margin-bottom: 1.5rem;">يرجى كتابة سبب الرفض ليتمكن الطالب من تعديل الحالة.</p>
            
            <form :action="'{{ url('delegate/clinical/cases') }}/' + caseToReject + '/reject'" method="POST">
                @csrf
                <textarea name="rejection_reason" x-model="rejectionReason" class="form-control" rows="4" placeholder="مثلاً: البيانات غير مكتملة، القسم غير صحيح..." required style="border-radius: 12px; margin-bottom: 1.5rem;"></textarea>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                    <button type="button" @click="showRejectModal = false" style="padding: 0.75rem; border: none; border-radius: 12px; background: #f1f5f9; color: #475569; font-weight: 700;">إلغاء</button>
                    <button type="submit" style="padding: 0.75rem; border: none; border-radius: 12px; background: #dc2626; color: white; font-weight: 700;">تأكيد الرفض</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
