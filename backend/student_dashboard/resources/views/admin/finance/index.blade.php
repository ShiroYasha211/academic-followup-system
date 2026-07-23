@extends('layouts.admin')

@section('title', 'الإدارة المالية والأرباح')

@section('content')
<div class="finance-dashboard">
    <!-- Stats Cards -->
    <div class="stats-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;">
        <!-- Total Revenue -->
        <div class="stat-card" style="background: white; padding: 1.5rem; border-radius: 12px; box-shadow: var(--shadow-sm); border-right: 4px solid #059669;">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <p style="color: var(--text-secondary); font-size: 0.875rem; font-weight: 600; margin-bottom: 0.5rem;">إجمالي الإيرادات (الإيداعات)</p>
                    <h3 style="font-size: 1.5rem; font-weight: 700; color: #059669;">{{ number_format($stats['total_revenue'], 2) }} <span style="font-size: 0.875rem;">ريال</span></h3>
                </div>
                <div style="background: #ecfdf5; padding: 0.5rem; border-radius: 8px; color: #059669;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
                </div>
            </div>
        </div>

        <!-- Total System Balance -->
        <div class="stat-card" style="background: white; padding: 1.5rem; border-radius: 12px; box-shadow: var(--shadow-sm); border-right: 4px solid var(--primary-color);">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <p style="color: var(--text-secondary); font-size: 0.875rem; font-weight: 600; margin-bottom: 0.5rem;">إجمالي أرصدة النظام</p>
                    <h3 style="font-size: 1.5rem; font-weight: 700; color: var(--primary-color);">{{ number_format($stats['total_system_balance'], 2) }} <span style="font-size: 0.875rem;">ريال</span></h3>
                </div>
                <div style="background: #eef2ff; padding: 0.5rem; border-radius: 8px; color: var(--primary-color);">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
                </div>
            </div>
        </div>

        <!-- Cards Sold -->
        <div class="stat-card" style="background: white; padding: 1.5rem; border-radius: 12px; box-shadow: var(--shadow-sm); border-right: 4px solid #8b5cf6;">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <p style="color: var(--text-secondary); font-size: 0.875rem; font-weight: 600; margin-bottom: 0.5rem;">عدد الكروت المباعة</p>
                    <h3 style="font-size: 1.5rem; font-weight: 700; color: #8b5cf6;">{{ $stats['cards_sold_count'] }} <span style="font-size: 0.875rem;">كرت</span></h3>
                </div>
                <div style="background: #f5f3ff; padding: 0.5rem; border-radius: 8px; color: #8b5cf6;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                </div>
            </div>
        </div>

        <!-- Total Usage/Payments -->
        <div class="stat-card" style="background: white; padding: 1.5rem; border-radius: 12px; box-shadow: var(--shadow-sm); border-right: 4px solid #f97316;">
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <p style="color: var(--text-secondary); font-size: 0.875rem; font-weight: 600; margin-bottom: 0.5rem;">إجمالي المدفوعات (الاشتراكات)</p>
                    <h3 style="font-size: 1.5rem; font-weight: 700; color: #f97316;">{{ number_format(abs($stats['total_payments']), 2) }} <span style="font-size: 0.875rem;">ريال</span></h3>
                </div>
                <div style="background: #fff7ed; padding: 0.5rem; border-radius: 8px; color: #f97316;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
                </div>
            </div>
        </div>
    </div>

    <!-- Filters & Transactions -->
    <div class="card" style="background: white; border-radius: 12px; box-shadow: var(--shadow-sm); border: 1px solid var(--border-color); overflow: hidden;">
        <div class="card-header" style="padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
            <h4 style="margin: 0; font-weight: 700;">سجل الحركات المالية</h4>
            
            <form action="{{ route('admin.finance.index') }}" method="GET" style="display: flex; gap: 0.75rem; flex: 1; max-width: 850px; flex-wrap: wrap;">
                <select name="type" class="form-control" style="max-width: 130px;" onchange="this.form.submit()">
                    <option value="">كل الأنواع</option>
                    <option value="deposit" {{ request('type') == 'deposit' ? 'selected' : '' }}>إيداع (شحن)</option>
                    <option value="payment" {{ request('type') == 'payment' ? 'selected' : '' }}>مدفوعات (اشتراك)</option>
                    <option value="refund" {{ request('type') == 'refund' ? 'selected' : '' }}>مستردات</option>
                </select>
                
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <span style="font-size: 0.75rem; color: var(--text-secondary);">من:</span>
                    <input type="date" name="from_date" class="form-control" value="{{ request('from_date') }}" onchange="this.form.submit()">
                </div>

                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <span style="font-size: 0.75rem; color: var(--text-secondary);">إلى:</span>
                    <input type="date" name="to_date" class="form-control" value="{{ request('to_date') }}" onchange="this.form.submit()">
                </div>

                <input type="text" name="search" class="form-control" style="flex: 1; min-width: 150px;" placeholder="بحث..." value="{{ request('search') }}">
                <button type="submit" class="btn btn-primary">بحث</button>
                @if(request()->anyFilled(['type', 'search', 'from_date', 'to_date']))
                    <a href="{{ route('admin.finance.index') }}" class="btn btn-secondary">تفريغ</a>
                @endif
            </form>
        </div>

        <div class="table-responsive">
            <table class="table" style="width: 100%; border-collapse: collapse;">
                <thead style="background: #f8fafc;">
                    <tr>
                        <th style="padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary);">التاريخ</th>
                        <th style="padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary);">المستخدم</th>
                        <th style="padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary);">البيان</th>
                        <th style="padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary);">النوع</th>
                        <th style="padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary);">المبلغ</th>
                        <th style="padding: 1rem; text-align: right; font-weight: 600; color: var(--text-secondary);">الرصيد بعد</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($transactions as $transaction)
                    <tr style="border-bottom: 1px solid #f1f5f9;">
                        <td style="padding: 1rem; font-size: 0.875rem;">{{ $transaction->created_at->format('Y/m/d H:i') }}</td>
                        <td style="padding: 1rem;">
                            <div style="font-weight: 600;">{{ $transaction->user->name }}</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ $transaction->user->email }}</div>
                        </td>
                        <td style="padding: 1rem; font-size: 0.875rem;">{{ $transaction->description }}</td>
                        <td style="padding: 1rem;">
                            @php
                                $badgeStyle = match($transaction->type) {
                                    'deposit' => 'background: #ecfdf5; color: #059669;',
                                    'payment' => 'background: #eff6ff; color: #2563eb;',
                                    'refund' => 'background: #fef2f2; color: #dc2626;',
                                    default => 'background: #f1f5f9; color: #475569;'
                                };
                                $typeLabel = match($transaction->type) {
                                    'deposit' => 'إيداع',
                                    'payment' => 'اشتراك',
                                    'refund' => 'مسترد',
                                    default => 'تعديل'
                                };
                            @endphp
                            <span style="padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: 600; {{ $badgeStyle }}">
                                {{ $typeLabel }}
                            </span>
                        </td>
                        <td style="padding: 1rem; font-weight: 700; direction: ltr; text-align: right; color: {{ $transaction->amount > 0 ? '#059669' : '#dc2626' }}">
                            {{ number_format($transaction->amount, 2) }}
                        </td>
                        <td style="padding: 1rem; font-weight: 600;">{{ number_format($transaction->balance_after, 2) }}</td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" style="padding: 3rem; text-align: center; color: var(--text-secondary);">لا توجد حركات مالية مسجلة حالياً.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($transactions->hasPages())
        <div style="padding: 1.5rem; border-top: 1px solid var(--border-color);">
            {{ $transactions->links() }}
        </div>
        @endif
    </div>
</div>
@endsection
