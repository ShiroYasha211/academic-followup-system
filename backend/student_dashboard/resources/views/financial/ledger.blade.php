@php
    $routeName = request()->route()?->getName() ?? '';
    $workspace = str_starts_with($routeName, 'administrative.')
        ? 'administrative'
        : (str_starts_with($routeName, 'doctor.')
            ? 'doctor'
            : (str_starts_with($routeName, 'delegate.')
                ? 'delegate'
                : 'student'));

    $layout = match ($workspace) {
        'doctor' => 'layouts.doctor',
        'delegate' => 'layouts.delegate',
        'administrative' => 'layouts.administrative',
        default => 'layouts.student',
    };

    $ledgerRoutePrefix = $workspace === 'administrative' ? 'administrative' : $workspace;
@endphp

@extends($layout)

@section('content')
<div class="container-fluid" style="padding: 2rem; direction: rtl; text-align: right;">
    <!-- PDF Download Button - Forced physically to the left -->
    <div style="display: flex; justify-content: flex-start; margin-bottom: 2rem;">
        <a href="{{ route($ledgerRoutePrefix . '.ledger.export') }}" class="btn" style="background: var(--primary-color); border: none; color: white; font-weight: 700; border-radius: 12px; display: inline-flex; align-items: center; gap: 0.6rem; padding: 0.8rem 1.75rem; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(79, 70, 229, 0.3);">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>
            </svg>
            <span>تحميل كشف الحساب (PDF)</span>
        </a>
    </div>

    <!-- Header Section -->
    <div class="row align-items-center mb-4">
        <div class="col-12 text-end">
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.25rem; display: flex; align-items: center; gap: 0.75rem; justify-content: flex-end;">
                السجل المالي (كشف الحساب)
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="color: var(--primary-color);">
                    <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
                </svg>
            </h1>
            <p style="color: var(--text-secondary); margin-bottom: 0;">تتبع جميع مدفوعاتك، عمليات الشحن، والاشتراكات بالتفصيل.</p>
        </div>
    </div>

    <!-- Balance Overview Card -->
    <div class="card mb-4" style="background: linear-gradient(135deg, var(--primary-color), #4338ca); border: none; border-radius: 20px; color: white;">
        <div class="card-body p-4">
            <div class="row align-items-center">
                <div class="col-md-6 text-md-end text-center mb-3 mb-md-0">
                    <span style="opacity: 0.9; font-size: 1rem; font-weight: 600;">الرصيد الحالي المتوفر</span>
                    <h2 style="font-size: 3rem; font-weight: 900; margin-top: 5px; margin-bottom: 0;">{{ number_format($user->balance, 2) }} <span style="font-size: 1.25rem;">ريال</span></h2>
                </div>
                <div class="col-md-6 text-md-start text-center">
                    <a href="{{ route($ledgerRoutePrefix . '.subscription.index') }}" class="btn" style="background: rgba(255,255,255,0.2); border: 1px solid rgba(255,255,255,0.3); color: white; border-radius: 12px; font-weight: 700; padding: 0.75rem 1.5rem; backdrop-filter: blur(5px);">
                        إدارة الاشتراكات والرصيد
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- Transactions Table -->
    <div class="card border-0" style="border-radius: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); overflow: hidden;">
        <div class="table-responsive">
            <table class="table mb-0" style="vertical-align: middle;">
                <thead style="background: #f8fafc;">
                    <tr>
                        <th style="padding: 1.25rem; border-bottom: 2px solid #edf2f7; color: #64748b; font-weight: 700;">التاريخ والوقت</th>
                        <th style="padding: 1.25rem; border-bottom: 2px solid #edf2f7; color: #64748b; font-weight: 700;">البيان (الوصف)</th>
                        <th style="padding: 1.25rem; border-bottom: 2px solid #edf2f7; color: #64748b; font-weight: 700;">المبلغ</th>
                        <th style="padding: 1.25rem; border-bottom: 2px solid #edf2f7; color: #64748b; font-weight: 700;">الرصيد السابق</th>
                        <th style="padding: 1.25rem; border-bottom: 2px solid #edf2f7; color: #64748b; font-weight: 700;">الرصيد الناتج</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($transactions as $transaction)
                    <tr style="transition: all 0.2s ease;">
                        <td style="padding: 1.25rem; border-bottom: 1px solid #f1f5f9;">
                            <div style="font-weight: 700; color: var(--text-primary);">{{ $transaction->created_at->translatedFormat('d M Y') }}</div>
                            <small style="color: #94a3b8;">{{ $transaction->created_at->format('h:i A') }}</small>
                        </td>
                        <td style="padding: 1.25rem; border-bottom: 1px solid #f1f5f9;">
                            <div style="font-weight: 600; color: var(--text-primary);">{{ $transaction->description }}</div>
                            <span class="badge" style="
                                background: {{ $transaction->type === 'deposit' ? '#dcfce7' : ($transaction->type === 'payment' ? '#fee2e2' : ($transaction->type === 'refund' ? '#e0f2fe' : '#f1f5f9')) }};
                                color: {{ $transaction->type === 'deposit' ? '#166534' : ($transaction->type === 'payment' ? '#b91c1c' : ($transaction->type === 'refund' ? '#0369a1' : '#475569')) }};
                                border-radius: 6px; padding: 4px 8px; font-size: 0.75rem; margin-top: 4px; border: 1px solid rgba(0,0,0,0.05);
                            ">
                                @if($transaction->type === 'deposit') إيداع (شحن)
                                @elseif($transaction->type === 'payment') مدفوعات
                                @elseif($transaction->type === 'refund') مستردات
                                @else تعديل رصيد @endif
                            </span>
                        </td>
                        <td style="padding: 1.25rem; border-bottom: 1px solid #f1f5f9;">
                            <div style="font-weight: 900; font-size: 1.1rem; color: {{ $transaction->amount > 0 ? '#10b981' : '#ef4444' }};">
                                {{ $transaction->amount > 0 ? '+' : '' }}{{ number_format($transaction->amount, 2) }}
                            </div>
                        </td>
                        <td style="padding: 1.25rem; border-bottom: 1px solid #f1f5f9; color: #64748b; font-weight: 500;">
                            {{ number_format($transaction->balance_before, 2) }}
                        </td>
                        <td style="padding: 1.25rem; border-bottom: 1px solid #f1f5f9; color: var(--text-primary); font-weight: 800;">
                            {{ number_format($transaction->balance_after, 2) }}
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="text-center" style="padding: 4rem;">
                            <div style="opacity: 0.3; margin-bottom: 1rem;">
                                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M21 12V7a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h7"/>
                                    <path d="M16 19h6M19 16l3 3-3 3"/>
                                </svg>
                            </div>
                            <h4 style="color: #94a3b8; font-weight: 600;">لا توجد حركات مالية مسجلة بعد.</h4>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($transactions->hasPages())
        <div class="p-4 border-top" style="background: #fafafa;">
            {{ $transactions->links() }}
        </div>
        @endif
    </div>
</div>

<style>
    .table tbody tr:hover {
        background: #fbfcfe;
    }
    .pagination {
        margin-bottom: 0;
        justify-content: center;
    }
</style>
@endsection
