@extends('layouts.admin')

@section('title', 'إدارة الكروت والترصيد')

@section('content')
<div style="margin-bottom: 2rem; display: flex; align-items: center; justify-content: space-between;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">إدارة الكروت (Vouchers)</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">توليد كروت شحن الرصيد ومتابعة استهلاكها في النظام</p>
    </div>
    <button onclick="document.getElementById('generateModal').style.display='flex'" class="btn" style="background: var(--primary-color); color: white; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 600; border: none; cursor: pointer; display: flex; align-items: center; gap: 0.5rem; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.2);">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M12 2v20M5 12h14"></path>
        </svg>
        توليد كروت جديدة
    </button>
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

<!-- Filters -->
<div class="card" style="padding: 1rem; border-radius: 15px; margin-bottom: 1.5rem;">
    <form method="GET" action="{{ route('admin.cards.index') }}" style="display:grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; align-items:end;">
        <div>
            <label style="display:block; margin-bottom:0.35rem; font-weight:700;">الحالة</label>
            <select name="status" class="form-control">
                <option value="">الكل</option>
                <option value="unused" @selected(request('status') === 'unused')>غير مستخدمة</option>
                <option value="used" @selected(request('status') === 'used')>مستخدمة</option>
            </select>
        </div>
        <div>
            <label style="display:block; margin-bottom:0.35rem; font-weight:700;">منشئ الكرت</label>
            <select name="generated_by_id" class="form-control">
                <option value="">الكل</option>
                @foreach($creators as $creator)
                    <option value="{{ $creator->id }}" @selected((string) request('generated_by_id') === (string) $creator->id)>{{ $creator->name }}</option>
                @endforeach
            </select>
        </div>
        <div>
            <label style="display:block; margin-bottom:0.35rem; font-weight:700;">مستخدم الكرت</label>
            <select name="used_by_id" class="form-control">
                <option value="">الكل</option>
                @foreach($redeemers as $redeemer)
                    <option value="{{ $redeemer->id }}" @selected((string) request('used_by_id') === (string) $redeemer->id)>{{ $redeemer->name }}</option>
                @endforeach
            </select>
        </div>
        <div>
            <label style="display:block; margin-bottom:0.35rem; font-weight:700;">بحث بالكود</label>
            <input type="text" name="search" value="{{ request('search') }}" class="form-control" placeholder="CARD123">
        </div>
        <div style="display:flex; gap:0.5rem;">
            <button type="submit" class="btn" style="background: var(--primary-color); color: white; flex:1;">تطبيق</button>
            <a href="{{ route('admin.cards.index') }}" class="btn" style="background:#f1f5f9; color:var(--text-secondary); flex:1; text-align:center;">إعادة</a>
        </div>
    </form>
</div>

<div class="card" style="padding: 0; border-radius: 20px; overflow: hidden; border: 1px solid #f1f5f9;">
    <table style="width: 100%; border-collapse: collapse; text-align: right;">
        <thead>
            <tr style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">الكود (Code)</th>
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">القيمة (Amount)</th>
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">الحالة</th>
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">منشئ الكرت</th>
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">المستخدم</th>
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">تاريخ الاستخدام</th>
                <th style="padding: 1.25rem; font-weight: 800; color: var(--text-secondary); font-size: 0.85rem;">إجراءات</th>
            </tr>
        </thead>
        <tbody>
            @foreach($cards as $card)
                <tr style="border-bottom: 1px solid #f8fafc; transition: background 0.2s;" onmouseover="this.style.background='#fcfdfe'" onmouseout="this.style.background='transparent'">
                    <td style="padding: 1.25rem;">
                        <span style="font-family: monospace; font-size: 1.1rem; font-weight: 800; color: var(--text-primary); background: #f1f5f9; padding: 0.25rem 0.5rem; border-radius: 5px;">{{ $card->code }}</span>
                    </td>
                    <td style="padding: 1.25rem; font-weight: 800; color: #10b981;">{{ number_format($card->amount) }} ريال</td>
                    <td style="padding: 1.25rem;">
                        <span style="padding: 0.35rem 0.75rem; border-radius: 20px; font-size: 0.75rem; font-weight: 800; {{ $card->is_used ? 'background: #fee2e2; color: #991b1b;' : 'background: #d1fae5; color: #065f46;' }}">
                            {{ $card->is_used ? 'مستخدم' : 'جاهز' }}
                        </span>
                    </td>
                    <td style="padding: 1.25rem; color: var(--text-primary); font-weight: 600;">
                        {{ $card->generatedBy->name ?? 'النظام' }}
                    </td>
                    <td style="padding: 1.25rem; color: var(--text-primary); font-weight: 600;">
                        {{ $card->usedBy->name ?? '-' }}
                    </td>
                    <td style="padding: 1.25rem; color: var(--text-secondary); font-size: 0.85rem;">
                        {{ $card->used_at ? $card->used_at->format('Y-m-d H:i') : '-' }}
                    </td>
                    <td style="padding: 1.25rem;">
                        @if(!$card->is_used)
                            <form action="{{ route('admin.cards.destroy', $card) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف الكرت؟')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" style="background: none; border: none; color: #ef4444; cursor: pointer; padding: 5px;">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="3 6 5 6 21 6"></polyline>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                    </svg>
                                </button>
                            </form>
                        @endif
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>
    <div style="padding: 1.5rem; background: #f8fafc; border-top: 1px solid #f1f5f9;">
        {{ $cards->links() }}
    </div>
</div>

<!-- Modal -->
<div id="generateModal" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(4px);">
    <div class="card" style="width: 400px; padding: 2rem; border-radius: 24px;">
        <h3 style="margin-bottom: 1.5rem; font-weight: 800; color: var(--text-primary);">توليد كروت شحن</h3>
        <form action="{{ route('admin.cards.generate') }}" method="POST">
            @csrf
            <div style="margin-bottom: 1.25rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 700;">عدد الكروت</label>
                <input type="number" name="count" value="10" min="1" max="100" required style="width: 100%; padding: 0.75rem; border: 1.5px solid #e2e8f0; border-radius: 10px; font-size: 1rem;">
            </div>
            <div style="margin-bottom: 2rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 700;">القيمة (ريال)</label>
                <input type="number" name="amount" value="1500" min="1" required style="width: 100%; padding: 0.75rem; border: 1.5px solid #e2e8f0; border-radius: 10px; font-size: 1rem;">
            </div>
            <div style="display: flex; gap: 1rem;">
                <button type="submit" class="btn" style="flex: 1; background: var(--primary-color); color: white; padding: 0.75rem; border-radius: 10px; font-weight: 700; border: none; cursor: pointer;">توليد الآن</button>
                <button type="button" onclick="document.getElementById('generateModal').style.display='none'" class="btn" style="flex: 1; background: #f1f5f9; color: var(--text-secondary); padding: 0.75rem; border-radius: 10px; font-weight: 700; border: none; cursor: pointer;">إلغاء</button>
            </div>
        </form>
    </div>
</div>
@endsection
