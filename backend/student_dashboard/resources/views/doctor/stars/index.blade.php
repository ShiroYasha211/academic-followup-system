@extends('layouts.doctor')

@section('title', 'منح النجوم ⭐')

@section('content')
<style>
    .star-grant-header {
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 25px rgba(245,158,11,0.3);
    }

    .star-grant-header::before { content: ''; position: absolute; top: -50%; right: -10%; width: 300px; height: 300px; background: rgba(255,255,255,0.08); border-radius: 50%; }
    .star-grant-header-content { position: relative; z-index: 1; }
    .star-grant-header h1 { font-size: 2rem; font-weight: 800; margin-bottom: 0.25rem; }
    .star-grant-header p { opacity: 0.85; }

    .grant-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        max-width: 700px;
    }

    .grant-card-title { font-weight: 800; font-size: 1.1rem; color: #1e293b; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.5rem; }
    .grant-card-title i { color: #f59e0b; }

    .student-checkboxes {
        max-height: 350px;
        overflow-y: auto;
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.5rem;
    }

    .student-check-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.6rem 0.75rem;
        border-radius: 10px;
        transition: background 0.15s;
        cursor: pointer;
    }

    .student-check-item:hover { background: #f8fafc; }

    .student-check-item input { width: 18px; height: 18px; accent-color: #f59e0b; cursor: pointer; }
    .student-check-item label { font-weight: 600; font-size: 0.9rem; color: #334155; cursor: pointer; flex: 1; }
    .student-check-item .stars-count { font-size: 0.8rem; color: #f59e0b; font-weight: 700; }

    .form-control-star, .form-select-star {
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.7rem 1rem;
        font-size: 0.9rem;
        transition: border-color 0.2s;
    }

    .form-control-star:focus, .form-select-star:focus { border-color: #f59e0b; box-shadow: 0 0 0 4px rgba(245,158,11,0.1); }

    .btn-grant {
        background: linear-gradient(135deg, #f59e0b, #d97706);
        color: white;
        border: none;
        padding: 0.85rem 2rem;
        border-radius: 14px;
        font-weight: 700;
        font-size: 1rem;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-grant:hover { transform: translateY(-2px); box-shadow: 0 10px 25px rgba(245,158,11,0.3); color: white; }

    .select-all-btn {
        background: #fef3c7;
        color: #92400e;
        border: none;
        padding: 0.4rem 0.8rem;
        border-radius: 8px;
        font-weight: 700;
        font-size: 0.8rem;
        cursor: pointer;
        transition: all 0.15s;
    }

    .select-all-btn:hover { background: #fde68a; }

    .wallet-summary {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 0.75rem;
        margin-bottom: 1.5rem;
    }

    .wallet-metric {
        background: #fffbeb;
        border: 1px solid #fde68a;
        border-radius: 14px;
        padding: 0.9rem;
    }

    .wallet-metric span { display: block; color: #92400e; font-size: 0.78rem; font-weight: 700; }
    .wallet-metric strong { color: #78350f; font-size: 1.25rem; font-weight: 900; }
</style>

<div class="star-grant-header">
    <div class="star-grant-header-content">
        <h1><i class="fa-solid fa-star me-2"></i>منح النجوم</h1>
        <p>كافئ طلابك بنجوم على أدائهم المميز</p>
    </div>
</div>

<div class="grant-card" x-data="{ selectAll: false }">
    <div class="grant-card-title"><i class="fa-solid fa-gift"></i> منح نجوم للطلاب</div>

    <div class="wallet-summary">
        <div class="wallet-metric">
            <span>الرصيد المتاح</span>
            <strong>{{ $wallet->balance }}</strong>
        </div>
        <div class="wallet-metric">
            <span>إجمالي المخصص</span>
            <strong>{{ $wallet->total_allocated }}</strong>
        </div>
        <div class="wallet-metric">
            <span>إجمالي الممنوح</span>
            <strong>{{ $wallet->total_spent }}</strong>
        </div>
    </div>

    <form action="{{ route('doctor.stars.grant') }}" method="POST"
          x-data="{ amount: 5, selectedCount: 0, balance: {{ $wallet->balance }} }"
          @change="selectedCount = document.querySelectorAll('.student-cb:checked').length">
        @csrf

        <div class="mb-3">
            <label class="form-label" style="font-weight: 700;">عدد النجوم لكل طالب *</label>
            <input type="number" name="amount" x-model.number="amount" class="form-control form-control-star" min="1" max="100" value="5" required style="max-width: 200px;">
        </div>

        <div class="mb-3">
            <label class="form-label" style="font-weight: 700;">سبب المنح (اختياري)</label>
            <input type="text" name="description" class="form-control form-control-star" placeholder="مثال: تميز في الكويز، مشاركة ممتازة..." maxlength="200">
        </div>

        <div class="mb-3">
            <div class="d-flex justify-content-between align-items-center mb-2">
                <label class="form-label mb-0" style="font-weight: 700;">اختر الطلاب *</label>
                <button type="button" class="select-all-btn" @click="selectAll = !selectAll; document.querySelectorAll('.student-cb').forEach(cb => cb.checked = selectAll); selectedCount = document.querySelectorAll('.student-cb:checked').length">
                    <i class="fa-solid fa-check-double me-1"></i> <span x-text="selectAll ? 'إلغاء الكل' : 'تحديد الكل'"></span>
                </button>
            </div>
            <div class="student-checkboxes">
                @forelse($students as $stu)
                <div class="student-check-item">
                    <input type="checkbox" name="student_ids[]" value="{{ $stu->id }}" id="stu_{{ $stu->id }}" class="student-cb">
                    <label for="stu_{{ $stu->id }}">{{ $stu->name }} <small class="text-muted">({{ $stu->student_number }})</small></label>
                    <span class="stars-count">⭐ {{ $stu->stars_balance }}</span>
                </div>
                @empty
                <div style="text-align: center; padding: 2rem; color: #94a3b8;">
                    <i class="fa-solid fa-users-slash d-block mb-2" style="font-size: 1.5rem;"></i>
                    لا يوجد طلاب مسجلين في نفس الدفعات
                </div>
                @endforelse
            </div>
        </div>

        <div class="mb-3 rounded-3 border p-3" style="background:#f8fafc;">
            <strong>تكلفة العملية: <span x-text="selectedCount * amount"></span> نجمة</strong>
            <div class="small text-muted mt-1">
                الرصيد بعد المنح:
                <span x-text="Math.max(0, balance - (selectedCount * amount))"></span>
                نجمة
            </div>
            <div class="small text-danger mt-1" x-show="selectedCount * amount > balance">
                الرصيد المتاح لا يكفي لتنفيذ هذه العملية.
            </div>
        </div>

        <button type="submit" class="btn-grant"
                :disabled="selectedCount === 0 || amount < 1 || selectedCount * amount > balance"
                :style="(selectedCount === 0 || selectedCount * amount > balance) ? 'opacity:.5;cursor:not-allowed' : ''">
            <i class="fa-solid fa-paper-plane"></i> منح النجوم
        </button>
    </form>
</div>
@endsection
