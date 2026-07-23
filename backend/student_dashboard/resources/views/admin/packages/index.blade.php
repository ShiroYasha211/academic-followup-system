@extends('layouts.admin')

@section('title', 'إدارة باقات الاشتراك')

@section('content')
<div style="margin-bottom: 2rem; display: flex; align-items: center; justify-content: space-between;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">إدارة باقات الاشتراك</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">تحكم في أسعار الاشتراكات حسب كل رتبة ومدة الصلاحية</p>
    </div>
    <a href="{{ route('admin.packages.create') }}" class="btn" style="background: var(--primary-color); color: white; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.2);">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
        إضافة باقة جديدة
    </a>
</div>

@if(session('success'))
    <div style="padding: 1rem; background: #d1fae5; color: #065f46; border-radius: 12px; margin-bottom: 1.5rem; font-weight: 600;">
        {{ session('success') }}
    </div>
@endif

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1.5rem;">
    @foreach($packages as $package)
        <div class="card" style="padding: 0; overflow: hidden; border-radius: 20px; border: 1px solid #f1f5f9; position: relative;">
            <div style="padding: 1.5rem; background: #f8fafc; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center;">
                <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--text-primary);">{{ $package->name }}</h3>
                
                <form action="{{ route('admin.packages.toggle', $package) }}" method="POST">
                    @csrf
                    @method('PATCH')
                    <button type="submit" class="btn" style="padding: 0.35rem 0.75rem; border-radius: 20px; font-size: 0.75rem; font-weight: 800; border: none; cursor: pointer; transition: all 0.2s; {{ $package->is_active ? 'background: #d1fae5; color: #065f46;' : 'background: #fee2e2; color: #991b1b;' }}">
                        {{ $package->is_active ? 'نشطة (إيقاف؟)' : 'متوقفة (تفعيل؟)' }}
                    </button>
                </form>
            </div>
            
            <div style="padding: 1.5rem;">
                <div style="margin-bottom: 1.25rem;">
                    <a href="{{ route('admin.packages.subscribers', $package) }}" style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; background: #eff6ff; color: #1e40af; border-radius: 12px; text-decoration: none; font-weight: 700; transition: all 0.2s; border: 1px solid #dbeafe;">
                        <div style="display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                <circle cx="9" cy="7" r="4"></circle>
                                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                            </svg>
                            <span>المشتركين</span>
                        </div>
                        <span style="background: white; padding: 2px 10px; border-radius: 20px; font-size: 0.8rem;">{{ $package->activeSubscribersCount() }}</span>
                    </a>
                </div>

                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 0.5rem; margin-bottom: 1.5rem;">
                    <div style="padding: 0.75rem 0.5rem; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; text-align: center;">
                        <div style="font-size: 0.65rem; color: var(--text-secondary); margin-bottom: 0.25rem;">طالب</div>
                        <div style="font-size: 1rem; font-weight: 800; color: var(--primary-color);">{{ number_format($package->price_student) }} <small style="font-size: 0.6rem;">ريال</small></div>
                    </div>
                    <div style="padding: 0.75rem 0.5rem; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; text-align: center;">
                        <div style="font-size: 0.65rem; color: var(--text-secondary); margin-bottom: 0.25rem;">دكتور</div>
                        <div style="font-size: 1rem; font-weight: 800; color: #0891b2;">{{ number_format($package->price_doctor) }} <small style="font-size: 0.6rem;">ريال</small></div>
                    </div>
                    <div style="padding: 0.75rem 0.5rem; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; text-align: center;">
                        <div style="font-size: 0.65rem; color: var(--text-secondary); margin-bottom: 0.25rem;">مندوب</div>
                        <div style="font-size: 1rem; font-weight: 800; color: #f59e0b;">{{ number_format($package->price_delegate) }} <small style="font-size: 0.6rem;">ريال</small></div>
                    </div>
                    <div style="padding: 0.75rem 0.5rem; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; text-align: center;">
                        <div style="font-size: 0.65rem; color: var(--text-secondary); margin-bottom: 0.25rem;">إداري</div>
                        <div style="font-size: 1rem; font-weight: 800; color: #6366f1;">{{ number_format($package->price_administrative) }} <small style="font-size: 0.6rem;">ريال</small></div>
                    </div>
                </div>

                <div style="display: flex; align-items: center; gap: 0.75rem; color: var(--text-secondary); font-size: 0.9rem; margin-bottom: 1.5rem;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    <span>المدة: <strong>{{ $package->duration_days }}</strong> يوم</span>
                </div>

                <div style="display: flex; gap: 0.75rem;">
                    <a href="{{ route('admin.packages.edit', $package) }}" class="btn" style="flex: 1; text-align: center; border: 1px solid #e2e8f0; color: var(--text-primary); padding: 0.75rem; border-radius: 10px; font-weight: 600; text-decoration: none;">تعديل</a>
                    <form action="{{ route('admin.packages.destroy', $package) }}" method="POST" style="display: inline;" onsubmit="return confirm('هل أنت متأكد من حذف هذه الباقة؟')">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="btn" style="background: #fee2e2; color: #991b1b; padding: 0.75rem; border-radius: 10px; border: none; cursor: pointer;">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                        </button>
                    </form>
                </div>
            </div>
        </div>
    @endforeach
</div>

@if($packages->isEmpty())
    <div style="text-align: center; padding: 5rem 2rem; background: white; border-radius: 20px; border: 1px dashed #e2e8f0;">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5" style="margin-bottom: 1.5rem;">
            <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
            <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
        </svg>
        <h3 style="color: var(--text-primary); font-size: 1.25rem;">لا توجد باقات حالياً</h3>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">ابدأ بإضافة أول باقة اشتراك في النظام</p>
    </div>
@endif
@endsection
