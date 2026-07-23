@extends('layouts.admin')

@section('title', 'المشتركين في باقة ' . $package->name)

@section('content')
<div style="margin-bottom: 2rem; display: flex; align-items: center; justify-content: space-between;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">المشتركين في باقة: {{ $package->name }}</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">عرض سجل كافة الطلاب الذين اشتركوا في هذه الباقة وإدارة اشتراكاتهم الحالية</p>
    </div>
    <a href="{{ route('admin.packages.index') }}" class="btn" style="background: #f1f5f9; color: var(--text-secondary); padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.5rem;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
        العودة للباقات
    </a>
</div>

@if(session('success'))
    <div style="padding: 1rem; background: #d1fae5; color: #065f46; border-radius: 12px; margin-bottom: 1.5rem; font-weight: 600;">
        {{ session('success') }}
    </div>
@endif

<div class="card" style="padding: 0; overflow: hidden; border-radius: 20px; border: 1px solid #f1f5f9;">
    <div class="table-container">
        <table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                    <th style="padding: 1.25rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 800; font-size: 0.85rem;">المستخدم</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: center; color: var(--text-secondary); font-weight: 800; font-size: 0.85rem;">عدد الاشتراكات</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: center; color: var(--text-secondary); font-weight: 800; font-size: 0.85rem;">إجمالي ما دفعه</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: center; color: var(--text-secondary); font-weight: 800; font-size: 0.85rem;">الحالة الحالية</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: center; color: var(--text-secondary); font-weight: 800; font-size: 0.85rem;">الإجراءات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($subscribers as $data)
                    @php
                        $user = $data['user'];
                        $currentSub = $data['current_subscription'];
                    @endphp
                    <tr style="border-bottom: 1px solid #f1f5f9; transition: all 0.2s;" onmouseover="this.style.background='#fcfdfe'" onmouseout="this.style.background='white'">
                        <td style="padding: 1.25rem 1.5rem;">
                            <div style="display: flex; align-items: center; gap: 1rem;">
                                <div style="width: 40px; height: 40px; border-radius: 10px; background: #eff6ff; color: #1e40af; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 1.1rem;">
                                    {{ mb_substr($user->name, 0, 1) }}
                                </div>
                                <div>
                                    <div style="font-weight: 700; color: var(--text-primary);">{{ $user->name }}</div>
                                    <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ $user->student_number }} | {{ $user->role->value }}</div>
                                </div>
                            </div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            <span style="padding: 0.25rem 0.75rem; background: #f1f5f9; border-radius: 20px; font-weight: 800; color: var(--text-primary);">{{ $data['count'] }}</span>
                        </td>
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            <div style="font-weight: 800; color: #10b981;">{{ number_format($data['total_paid']) }} ريال</div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            @if($currentSub)
                                <div style="display: inline-flex; flex-direction: column; align-items: center;">
                                    <span style="padding: 0.25rem 0.75rem; background: #d1fae5; color: #065f46; border-radius: 20px; font-size: 0.75rem; font-weight: 800;">نشط حالياً</span>
                                    <div style="font-size: 0.7rem; color: var(--text-secondary); margin-top: 0.25rem;">ينتهي: {{ $currentSub->ends_at->format('Y-m-d') }}</div>
                                </div>
                            @else
                                <span style="padding: 0.25rem 0.75rem; background: #f1f5f9; color: var(--text-secondary); border-radius: 20px; font-size: 0.75rem; font-weight: 700;">لا يوجد اشتراك فعال</span>
                            @endif
                        </td>
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            @if($currentSub)
                                <form action="{{ route('admin.subscriptions.cancel', $currentSub) }}" method="POST" style="display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                                    @csrf
                                    <div style="display: flex; align-items: center; gap: 0.5rem; background: #fff1f2; padding: 0.5rem; border-radius: 10px; border: 1px solid #fecaca;">
                                        <label style="display: flex; align-items: center; gap: 0.25rem; font-size: 0.75rem; font-weight: 700; color: #991b1b; cursor: pointer;">
                                            <input type="checkbox" name="refund" value="1" style="accent-color: #ef4444;">
                                            إرجاع المال؟
                                        </label>
                                        <button type="submit" class="btn" onclick="return confirm('هل أنت متأكد من إلغاء هذا الاشتراك؟ سيتم حرمان المستخدم من مميزات الباقة فوراً.')" style="background: #ef4444; color: white; padding: 0.4rem 0.8rem; border-radius: 8px; font-size: 0.75rem; font-weight: 800; border: none; cursor: pointer; transition: all 0.2s;">
                                            إلغاء الآن
                                        </button>
                                    </div>
                                </form>
                            @else
                                <span style="color: #cbd5e1;">-</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" style="padding: 5rem 1.5rem; text-align: center;">
                            <div style="color: var(--text-secondary); font-weight: 600;">لا يوجد سجل مشتركين لهذه الباقة حتى الآن</div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
