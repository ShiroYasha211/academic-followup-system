@extends('layouts.student')

@section('title', 'نجومي ⭐')

@section('content')
<style>
    .stars-header {
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 50%, #b45309 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 25px rgba(245,158,11,0.3);
    }

    .stars-header::before { content: ''; position: absolute; top: -50%; right: -10%; width: 350px; height: 350px; background: rgba(255,255,255,0.08); border-radius: 50%; }
    .stars-header-content { position: relative; z-index: 1; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1.5rem; }

    .stars-balance-big { font-size: 4rem; font-weight: 900; line-height: 1; }
    .stars-balance-label { font-size: 1.1rem; opacity: 0.85; font-weight: 600; }
    .stars-total-earned { font-size: 0.85rem; opacity: 0.7; margin-top: 0.5rem; }

    .stars-stats { display: flex; gap: 1.5rem; flex-wrap: wrap; }

    .star-stat-card {
        background: rgba(255,255,255,0.15);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255,255,255,0.2);
        border-radius: 16px;
        padding: 1.25rem 1.5rem;
        text-align: center;
        min-width: 120px;
    }

    .star-stat-value { font-size: 1.5rem; font-weight: 800; }
    .star-stat-label { font-size: 0.75rem; opacity: 0.8; }

    .content-grid { display: grid; grid-template-columns: 1fr 360px; gap: 1.5rem; }

    /* Transactions */
    .tx-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .tx-card-title {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        font-weight: 800;
        font-size: 1.05rem;
        color: #1e293b;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .tx-card-title i { color: #f59e0b; }

    .tx-list { list-style: none; padding: 0; margin: 0; }

    .tx-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        transition: background 0.15s;
    }

    .tx-item:hover { background: #f8fafc; }
    .tx-item:last-child { border-bottom: none; }

    .tx-icon {
        width: 40px;
        height: 40px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1rem;
        color: white;
        flex-shrink: 0;
    }

    .tx-info { flex: 1; }
    .tx-type { font-weight: 700; font-size: 0.9rem; color: #1e293b; }
    .tx-desc { font-size: 0.8rem; color: #64748b; }
    .tx-date { font-size: 0.7rem; color: #94a3b8; }

    .tx-amount { font-weight: 800; font-size: 1rem; text-align: left; }
    .tx-amount.positive { color: #059669; }
    .tx-amount.negative { color: #ef4444; }

    /* Honor Board */
    .honor-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .honor-card-title {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        font-weight: 800;
        font-size: 1.05rem;
        color: #1e293b;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        background: linear-gradient(135deg, #fffbeb, #fef3c7);
    }

    .honor-card-title i { color: #f59e0b; }

    .honor-list { list-style: none; padding: 0; margin: 0; }

    .honor-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.85rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .honor-item:last-child { border-bottom: none; }

    .honor-rank {
        width: 28px;
        height: 28px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 0.75rem;
        color: white;
        flex-shrink: 0;
    }

    .rank-1 { background: linear-gradient(135deg, #f59e0b, #d97706); }
    .rank-2 { background: linear-gradient(135deg, #94a3b8, #64748b); }
    .rank-3 { background: linear-gradient(135deg, #cd7f32, #a0522d); }
    .rank-default { background: #e2e8f0; color: #64748b; }

    .honor-name { font-weight: 700; font-size: 0.9rem; color: #1e293b; flex: 1; }
    .honor-name.is-me { color: #f59e0b; }

    .honor-stars {
        font-weight: 800;
        font-size: 0.9rem;
        color: #f59e0b;
        display: flex;
        align-items: center;
        gap: 0.25rem;
    }

    /* Gift Section */
    .gift-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-top: 1.5rem;
    }

    .gift-card-title {
        font-weight: 800;
        font-size: 1rem;
        color: #1e293b;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .gift-card-title i { color: #8b5cf6; }

    .gift-limit-card {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 0.75rem;
        padding: 1rem;
        margin-bottom: 1rem;
        background: #fffbeb;
        border: 1px solid #fde68a;
        border-radius: 16px;
    }

    .gift-limit-item {
        min-width: 0;
    }

    .gift-limit-value {
        color: #92400e;
        font-size: 1rem;
        font-weight: 800;
    }

    .gift-limit-label {
        color: #a16207;
        font-size: 0.75rem;
        margin-top: 0.15rem;
    }

    .gift-limit-progress {
        grid-column: 1 / -1;
        height: 7px;
        overflow: hidden;
        background: #fef3c7;
        border-radius: 999px;
    }

    .gift-limit-progress span {
        display: block;
        height: 100%;
        background: linear-gradient(90deg, #f59e0b, #d97706);
        border-radius: inherit;
    }

    .gift-limit-note {
        padding: 0.85rem 1rem;
        color: #92400e;
        background: #fffbeb;
        border: 1px solid #fde68a;
        border-radius: 12px;
        font-size: 0.85rem;
        font-weight: 600;
    }

    .empty-tx { text-align: center; padding: 3rem; color: #94a3b8; }

    @media (max-width: 992px) {
        .content-grid { grid-template-columns: 1fr; }
    }

    @media (max-width: 768px) {
        .stars-header { padding: 1.5rem; }
        .stars-balance-big { font-size: 3rem; }
        .gift-limit-card { grid-template-columns: 1fr; }
        .gift-limit-progress { grid-column: auto; }
    }
</style>

@if(session('success'))
<div class="alert alert-success border-0 rounded-3 mb-3">
    {{ session('success') }}
</div>
@endif

@if(session('error'))
<div class="alert alert-danger border-0 rounded-3 mb-3">
    {{ session('error') }}
</div>
@endif

@if($errors->any())
<div class="alert alert-danger border-0 rounded-3 mb-3">
    {{ $errors->first() }}
</div>
@endif

<div class="stars-header">
    <div class="stars-header-content">
        <div>
            <div class="stars-balance-big">⭐ {{ number_format($student->stars_balance) }}</div>
            <div class="stars-balance-label">رصيدك من النجوم</div>
            <div class="stars-total-earned">إجمالي المكتسبة: {{ number_format($student->total_stars_earned) }}</div>
        </div>
        <div class="stars-stats">
            <div class="star-stat-card">
                <div class="star-stat-value">{{ $transactions->where('amount', '>', 0)->count() }}</div>
                <div class="star-stat-label">مرات الاكتساب</div>
            </div>
            <div class="star-stat-card">
                <div class="star-stat-value">{{ $honorBoard->search(fn($u) => $u->id === $student->id) !== false ? $honorBoard->search(fn($u) => $u->id === $student->id) + 1 : '—' }}</div>
                <div class="star-stat-label">ترتيبك</div>
            </div>
        </div>
    </div>
</div>

<div class="content-grid">
    {{-- Transactions --}}
    <div>
        <div class="tx-card">
            <div class="tx-card-title"><i class="fa-solid fa-clock-rotate-left"></i> سجل المعاملات</div>

            @if($transactions->count() > 0)
            <ul class="tx-list">
                @foreach($transactions as $tx)
                <li class="tx-item">
                    <div class="tx-icon" style="background: {{ $tx->type_color }}">
                        <i class="fa-solid {{ $tx->type_icon }}"></i>
                    </div>
                    <div class="tx-info">
                        <div class="tx-type">{{ $tx->type_label }}</div>
                        @if($tx->description)
                        <div class="tx-desc">{{ $tx->description }}</div>
                        @endif
                        @if($tx->grantedBy)
                        <div class="tx-desc">من: {{ $tx->grantedBy->name }}</div>
                        @endif
                        <div class="tx-date">{{ $tx->created_at->diffForHumans() }}</div>
                    </div>
                    <div class="tx-amount {{ $tx->is_positive ? 'positive' : 'negative' }}">
                        {{ $tx->is_positive ? '+' : '' }}{{ $tx->amount }} ⭐
                    </div>
                </li>
                @endforeach
            </ul>

            <div class="p-3 d-flex justify-content-center">
                {{ $transactions->links() }}
            </div>
            @else
            <div class="empty-tx">
                <i class="fa-solid fa-star" style="font-size: 2rem; display: block; margin-bottom: 0.5rem;"></i>
                لا توجد معاملات بعد
            </div>
            @endif
        </div>

        {{-- Gift Section --}}
        <div class="gift-card">
            <div class="gift-card-title"><i class="fa-solid fa-gift"></i> أرسل نجوم لزميلك</div>

            @php
                $limitProgress = $giftLimit['maximum'] > 0
                    ? min(100, round(($giftLimit['used'] / $giftLimit['maximum']) * 100))
                    : 0;
                $maximumGift = min((int) $student->stars_balance, (int) $giftLimit['remaining']);
            @endphp

            <div class="gift-limit-card">
                <div class="gift-limit-item">
                    <div class="gift-limit-value">{{ number_format($giftLimit['maximum']) }}</div>
                    <div class="gift-limit-label">الحد خلال {{ $giftLimit['period_label'] }}</div>
                </div>
                <div class="gift-limit-item">
                    <div class="gift-limit-value">{{ number_format($giftLimit['used']) }}</div>
                    <div class="gift-limit-label">تم تحويله</div>
                </div>
                <div class="gift-limit-item">
                    <div class="gift-limit-value">{{ number_format($giftLimit['remaining']) }}</div>
                    <div class="gift-limit-label">المتبقي</div>
                </div>
                <div class="gift-limit-progress" aria-label="نسبة استخدام حد التحويل">
                    <span style="width: {{ $limitProgress }}%"></span>
                </div>
            </div>

            @if(!$giftLimit['enabled'])
                <div class="gift-limit-note">تحويل النجوم بين الطلاب متوقف حاليًا من إدارة النظام.</div>
            @elseif($giftLimit['remaining'] <= 0)
                <div class="gift-limit-note">
                    استهلكت الحد المتاح. سيتجدد في
                    {{ \Carbon\Carbon::parse($giftLimit['resets_at'])->translatedFormat('d M Y، h:i A') }}.
                </div>
            @elseif($student->stars_balance <= 0)
                <div class="gift-limit-note">لا يوجد في رصيدك نجوم متاحة للتحويل.</div>
            @else
            <form
                action="{{ route('student.stars.gift') }}"
                method="POST"
                onsubmit="return confirm('هل تريد تأكيد تحويل النجوم إلى الطالب المحدد؟')"
            >
                @csrf
                <div class="row g-2">
                    <div class="col-md-5">
                        <select name="recipient_id" class="form-select" required style="border-radius: 12px; border: 2px solid #e2e8f0;">
                            <option value="">— اختر الطالب —</option>
                            @foreach($peers as $peer)
                            <option value="{{ $peer->id }}" @selected(old('recipient_id') == $peer->id)>
                                {{ $peer->name }}{{ $peer->student_number ? ' - ' . $peer->student_number : '' }}
                            </option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-2">
                        <input type="number" name="amount" class="form-control" min="1" max="{{ $maximumGift }}" value="{{ old('amount') }}" placeholder="العدد" required style="border-radius: 12px; border: 2px solid #e2e8f0;">
                    </div>
                    <div class="col-md-3">
                        <input type="text" name="message" class="form-control" value="{{ old('message') }}" placeholder="رسالة (اختياري)" maxlength="200" style="border-radius: 12px; border: 2px solid #e2e8f0;">
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn w-100" style="background: linear-gradient(135deg, #8b5cf6, #7c3aed); color: white; border-radius: 12px; font-weight: 700;">
                            <i class="fa-solid fa-paper-plane"></i> أرسل
                        </button>
                    </div>
                </div>
            </form>
            @endif
        </div>
    </div>

    {{-- Honor Board --}}
    <div>
        <div class="honor-card">
            <div class="honor-card-title"><i class="fa-solid fa-crown"></i> لوحة الشرف</div>

            @if($honorBoard->count() > 0)
            <ul class="honor-list">
                @foreach($honorBoard as $i => $stu)
                <li class="honor-item">
                    <div class="honor-rank {{ $i < 3 ? 'rank-' . ($i + 1) : 'rank-default' }}">{{ $i + 1 }}</div>
                    <span class="honor-name {{ $stu->id === $student->id ? 'is-me' : '' }}">
                        {{ $stu->name }}
                        @if($stu->id === $student->id) <small>(أنت)</small> @endif
                    </span>
                    <span class="honor-stars">⭐ {{ $stu->stars_balance }}</span>
                </li>
                @endforeach
            </ul>
            @else
            <div class="empty-tx">
                <i class="fa-solid fa-crown" style="font-size: 2rem; display: block; margin-bottom: 0.5rem;"></i>
                لا يوجد طلاب في لوحة الشرف بعد
            </div>
            @endif
        </div>
    </div>
</div>
@endsection
