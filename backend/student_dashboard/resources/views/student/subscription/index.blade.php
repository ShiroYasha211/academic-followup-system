@php
    $prefix = request()->routeIs('doctor.*') ? 'doctor' : (request()->routeIs('delegate.*') ? 'delegate' : (request()->routeIs('administrative.*') ? 'administrative' : 'student'));
@endphp
@extends('layouts.' . $prefix)

@section('title', 'إدارة الاشتراك والرصيد')

@section('content')
<div x-data="{ 
    showConfirm: false, 
    pkgName: '', 
    pkgPrice: '', 
    pkgDuration: '', 
    pkgId: '',
    confirmSubscribe(id, name, price, duration) {
        this.pkgId = id;
        this.pkgName = name;
        this.pkgPrice = price;
        this.pkgDuration = duration;
        this.showConfirm = true;
    }
}">
    <div style="margin-bottom: 2rem;">
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">الاشتراك والرصيد</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">اشحن رصيدك وفعل اشتراكك للاستمتاع بكافة مميزات النظام</p>
    </div>

    <!-- Balance & Status Cards -->
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 2.5rem;">
        <!-- Balance Card -->
        <div class="card" style="padding: 2rem; border-radius: 24px; background: linear-gradient(135deg, var(--primary-color), #4338ca); color: white; display: flex; align-items: center; justify-content: space-between; overflow: hidden; position: relative;">
            <div style="position: absolute; right: -20px; top: -20px; opacity: 0.1;">
                <svg width="150" height="150" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1.41 16.09V20h-2.67v-1.93c-1.71-.36-3.16-1.46-3.27-3.4h1.96c.1 1.05.82 1.87 2.21 1.87 1.15 0 1.94-.51 1.94-1.31 0-2.43-3.09-1.39-3.09-4.32 0-1.14.73-2.16 2.25-2.52V7h2.67v1.92c1.47.3 2.54 1.25 2.74 2.82h-1.92c-.17-.89-.95-1.45-1.85-1.45-1.12 0-1.78.53-1.78 1.26 0 2.25 3.09 1.29 3.09 4.22.01 1.14-.72 2.05-2.26 2.45z"/>
                </svg>
            </div>
            <div style="position: relative; z-index: 1;">
                <div style="font-size: 1rem; opacity: 0.9; margin-bottom: 0.5rem;">رصيدك الحالي</div>
                <div style="font-size: 2.5rem; font-weight: 800;">{{ number_format($user->balance) }} <small style="font-size: 1rem;">ريال</small></div>
            </div>
            <button onclick="document.getElementById('redeemSection').scrollIntoView({behavior: 'smooth'})" class="btn" style="background: rgba(255,255,255,0.2); color: white; border: 1px solid rgba(255,255,255,0.3); padding: 0.75rem 1.25rem; border-radius: 12px; font-weight: 700; cursor: pointer; backdrop-filter: blur(10px);">
                شحن الرصيد
            </button>
        </div>

        <!-- Subscription Status Card -->
        <div class="card" style="padding: 2rem; border-radius: 24px; border: 2px solid {{ $user->isSubscribed() ? '#d1fae5' : '#fee2e2' }}; background: white; display: flex; align-items: center; gap: 1.5rem;">
            <div style="width: 64px; height: 64px; border-radius: 20px; background: {{ $user->isSubscribed() ? '#ecfdf5' : '#fef2f2' }}; color: {{ $user->isSubscribed() ? '#10b981' : '#ef4444' }}; display: flex; align-items: center; justify-content: center;">
                @if($user->isSubscribed())
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                        <polyline points="22 4 12 14.01 9 11.01"></polyline>
                    </svg>
                @else
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                @endif
            </div>
            <div>
                <div style="font-size: 0.9rem; color: var(--text-secondary); margin-bottom: 0.25rem;">حالة الاشتراك</div>
                <div style="font-size: 1.25rem; font-weight: 800; color: var(--text-primary);">
                    {{ $user->isSubscribed() ? 'مشترك فعال' : 'غير مشترك' }}
                </div>
                @if($user->subscribed_until)
                    <div style="font-size: 0.85rem; color: var(--text-secondary); margin-top: 0.25rem;">
                        ينتهي في: <span style="font-weight: 700; color: var(--text-primary);">{{ $user->subscribed_until->format('Y-m-d') }}</span>
                    </div>
                @endif
            </div>
        </div>
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

    <!-- Packages Section -->
    <div style="margin-bottom: 3rem;">
        <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
            <h2 style="font-size: 1.25rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0; display: flex; align-items: center; gap: 0.5rem;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--primary-color)" stroke-width="2">
                    <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
                    <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
                </svg>
                باقات الاشتراك المتاحة
            </h2>

            <!-- Global Auto-Renew Toggle -->
            <form action="{{ route($prefix . '.subscription.toggleAutoRenew') }}" method="POST" class="card" style="padding: 0.75rem 1.25rem; border-radius: 12px; border: 1px solid #e2e8f0; background: #f8fafc; margin: 0;">
                @csrf
                <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-size: 0.9rem; font-weight: 700; color: var(--text-primary);">
                    <input type="checkbox" name="auto_renew" {{ $user->auto_renew ? 'checked' : '' }} onchange="this.form.submit();" style="width: 18px; height: 18px; accent-color: var(--primary-color);">
                    تفعيل التجديد التلقائي للاشتراكات
                </label>
            </form>
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem;">
            @foreach($packages as $package)
                @php
                    $role = auth()->user()->role instanceof \App\Enums\UserRole ? auth()->user()->role->value : auth()->user()->role;
                    $price = $package->getPriceForRole($role);
                @endphp
                <div class="card" style="padding: 2rem; border-radius: 24px; border: 1px solid #f1f5f9; transition: all 0.3s ease; display: flex; flex-direction: column;">
                    <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem;">{{ $package->name }}</h3>
                    <p style="color: var(--text-secondary); font-size: 0.9rem; margin-bottom: 1.5rem; flex-grow: 1;">{{ $package->description ?? 'استكشف كافة المميزات والأدوات التعليمية في النظام.' }}</p>
                    
                    <div style="margin-bottom: 1.5rem;">
                        <span style="font-size: 2rem; font-weight: 800; color: var(--text-primary);">{{ number_format($price) }}</span>
                        <span style="color: var(--text-secondary); font-weight: 600;"> ريال / {{ $package->duration_days }} يوم</span>
                    </div>

                    <button type="button" 
                            @click="confirmSubscribe('{{ $package->id }}', '{{ $package->name }}', '{{ number_format($price) }}', '{{ $package->duration_days }}')"
                            class="btn" style="width: 100%; background: var(--primary-color); color: white; padding: 1rem; border-radius: 12px; font-weight: 700; border: none; cursor: pointer; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.1);">
                        اشترك الآن
                    </button>
                </div>
            @endforeach
        </div>
    </div>

    <!-- Redeem Card Section -->
    <div id="redeemSection" class="card" style="padding: 2.5rem; border-radius: 24px; background: #f8fafc; border: 1px solid #e2e8f0; max-width: 600px;">
        <h2 style="font-size: 1.15rem; font-weight: 800; color: var(--text-primary); margin-bottom: 1rem;">شحن رصيد بواسطة كرت</h2>
        <p style="color: var(--text-secondary); margin-bottom: 1.5rem; font-size: 0.9rem;">أدخل كود الكرت المكون من 12 حرفاً لشحن رصيدك المحفظة فوراً</p>

        <form action="{{ route($prefix . '.subscription.redeem') }}" method="POST" style="display: flex; gap: 1rem;">
            @csrf
            <input type="text" name="code" placeholder="XXXX-XXXX-XXXX" required maxlength="12" 
                   style="flex: 1; padding: 1rem; border: 2px solid #e2e8f0; border-radius: 12px; font-family: monospace; font-size: 1.2rem; font-weight: 800; text-transform: uppercase; outline: none; text-align: center;">
            <button type="submit" class="btn" style="background: #10b981; color: white; padding: 0 2rem; border-radius: 12px; font-weight: 700; border: none; cursor: pointer;">
                شحن
            </button>
        </form>
    </div>

    <!-- Confirmation Modal -->
    <div x-show="showConfirm" 
         class="modal-overlay"
         @click.self="showConfirm = false"
         x-transition.opacity
         style="display: none;">
        <div class="modal-container" style="max-width: 450px; padding: 2.5rem; text-align: center;">
            <div style="width: 80px; height: 80px; border-radius: 50%; background: #eff6ff; color: #3b82f6; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem;">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="16" x2="12" y2="12"></line>
                    <line x1="12" y1="8" x2="12.01" y2="8"></line>
                </svg>
            </div>
            
            <h3 style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary); margin-bottom: 1rem;">تأكيد الاشتراك</h3>
            <p style="color: var(--text-secondary); line-height: 1.6; margin-bottom: 2rem;">
                أنت على وشك الاشتراك في <strong style="color: var(--text-primary);" x-text="pkgName"></strong>.<br>
                سيتم خصم مبلغ <strong style="color: #ef4444;" x-text="pkgPrice + ' ريال'"></strong> من رصيدك مقابل اشتراك لمدة <span x-text="pkgDuration"></span> يوم.
            </p>

            <form action="{{ route($prefix . '.subscription.subscribe') }}" method="POST">
                @csrf
                <input type="hidden" name="package_id" :value="pkgId">
                <div style="display: flex; gap: 1rem;">
                    <button type="submit" class="btn btn-primary" style="flex: 1; padding: 1rem; border-radius: 12px; font-weight: 700; border: none; cursor: pointer;">
                        تأكيد وشراء
                    </button>
                    <button type="button" @click="showConfirm = false" class="btn btn-secondary" style="flex: 1; padding: 1rem; border-radius: 12px; font-weight: 700; border: none; cursor: pointer;">
                        إلغاء
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
