@extends('layouts.admin')

@section('title', 'نقل المندوبية')

@section('content')
<div style="margin-bottom: 2rem;">
    <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">نقل المندوبية</h1>
    <p style="color: var(--text-secondary); margin-top: 0.5rem;">اختر الدفعة التي ترغب في نقل مسؤولية المندوب الخاص بها</p>
</div>

@if(session('success'))
    <div style="padding: 1rem; background: #d1fae5; color: #065f46; border-radius: 12px; margin-bottom: 1.5rem; font-weight: 600;">
        {{ session('success') }}
    </div>
@endif

@if(session('error'))
    <div style="padding: 1rem; background: #fee2e2; color: #991b1b; border-radius: 12px; margin-bottom: 1.5rem; font-weight: 600;">
        {{ session('error') }}
    </div>
@endif

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 1.5rem;">
    @foreach($delegates as $batchKey => $batchDelegates)
        @php
            $firstDelegate = $batchDelegates->first();
            $major = $firstDelegate->major;
            $level = $firstDelegate->level;
        @endphp
        <div class="card" style="padding: 1.5rem; border-radius: 20px; border: 1px solid #f1f5f9; transition: all 0.3s ease;">
            <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1.5rem;">
                <div>
                    <span style="font-size: 0.75rem; padding: 0.25rem 0.6rem; background: rgba(79, 70, 229, 0.1); color: var(--primary-color); border-radius: 8px; font-weight: 800; display: inline-block; margin-bottom: 0.5rem;">
                        {{ $major->name ?? 'تخصص غير محدد' }}
                    </span>
                    <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">{{ $level->name ?? 'مستوى غير محدد' }}</h3>
                </div>
                <div style="width: 48px; height: 48px; background: #f8fafc; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: var(--text-secondary);">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="9" cy="7" r="4"></circle>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    </svg>
                </div>
            </div>

            <div style="background: #f8fafc; border-radius: 12px; padding: 1.25rem; margin-bottom: 1.5rem;">
                <div style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.5rem;">المندوب الحالي:</div>
                @foreach($batchDelegates as $delegate)
                    <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.5rem;">
                        <div style="width: 32px; height: 32px; border-radius: 50%; background: var(--primary-color); color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.8rem;">
                            {{ mb_substr($delegate->name, 0, 1) }}
                        </div>
                        <div>
                            <div style="font-weight: 700; font-size: 0.95rem; color: var(--text-primary);">{{ $delegate->name }}</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ $delegate->email }}</div>
                        </div>
                    </div>
                @endforeach
            </div>

            <a href="{{ route('admin.delegates.transfer.show', ['major' => $major->id, 'level' => $level->id]) }}" 
               class="btn" 
               style="width: 100%; display: flex; align-items: center; justify-content: center; gap: 0.5rem; background: var(--primary-color); color: white; padding: 0.85rem; border-radius: 12px; font-weight: 600; text-decoration: none; transition: all 0.2s;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="16 3 21 3 21 8"></polyline>
                    <line x1="4" y1="20" x2="21" y2="3"></line>
                    <polyline points="21 16 21 21 16 21"></polyline>
                    <line x1="15" y1="15" x2="21" y2="21"></line>
                </svg>
                نقل المندوبية
            </a>
        </div>
    @endforeach
</div>

@if($delegates->isEmpty())
    <div style="padding: 5rem 2rem; text-align: center; background: white; border-radius: 20px; border: 1px dashed #cbd5e1;">
        <div style="color: #cbd5e1; margin-bottom: 1rem;">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
            </svg>
        </div>
        <div style="font-size: 1.25rem; font-weight: 700; color: var(--text-primary);">لا يوجد مناديب مسجلين حالياً</div>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">سيظهر المناديب هنا بمجرد تعيينهم في النظام</p>
    </div>
@endif
@endsection
