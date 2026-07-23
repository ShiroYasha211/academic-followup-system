@extends('layouts.student')
@section('title', 'رمز QR - تأكيد اليوم')
@section('content')
<style>
    .qr-page {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 60vh;
        text-align: center;
        padding: 2rem;
    }

    .qr-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        max-width: 480px;
        width: 100%;
        box-shadow: 0 8px 30px rgba(0, 0, 0, 0.06);
    }

    .qr-card h2 {
        font-size: 1.2rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .qr-card .subtitle {
        color: var(--text-secondary);
        font-size: 0.85rem;
        margin-bottom: 1.25rem;
    }

    .qr-container {
        background: white;
        border: 3px solid #e2e8f0;
        border-radius: 16px;
        padding: 1rem;
        display: inline-block;
        margin-bottom: 1.25rem;
    }

    .timer-badge {
        background: #fef3c7;
        color: #92400e;
        padding: 0.5rem 1rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 1rem;
    }

    .timer-badge.expired {
        background: #fee2e2;
        color: #991b1b;
    }

    .data-summary {
        text-align: right;
        background: #f8fafc;
        border-radius: 12px;
        padding: 1rem;
        margin-bottom: 1rem;
    }

    .summary-row {
        display: flex;
        justify-content: space-between;
        padding: 0.3rem 0;
        font-size: 0.82rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .summary-row:last-child {
        border-bottom: none;
    }

    .summary-row .lbl {
        color: var(--text-secondary);
        font-weight: 600;
    }

    .summary-row .val {
        color: var(--text-primary);
        font-weight: 700;
    }

    .signatures-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.5rem;
        margin-bottom: 1rem;
    }

    .sig-item {
        background: #f0fdf4;
        border: 1px solid #bbf7d0;
        border-radius: 8px;
        padding: 0.5rem;
        text-align: center;
        font-size: 0.78rem;
        font-weight: 700;
        color: #065f46;
    }

    .sig-item.empty {
        background: #fef3c7;
        border-color: #fde68a;
        color: #92400e;
    }

    .btn-back-link {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.6rem 1.5rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-regenerate {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.65rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.2);
        transition: all 0.2s;
    }

    .btn-regenerate:hover {
        transform: translateY(-1px);
        color: white;
        text-decoration: none;
    }

    .btn-cancel {
        background: #fef2f2;
        color: #dc2626;
        border: 1.5px solid #fca5a5;
        padding: 0.65rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-cancel:hover {
        background: #fee2e2;
        text-decoration: none;
    }

    .expired-actions {
        display: none;
        flex-direction: column;
        gap: 0.75rem;
        align-items: center;
        margin: 1rem 0;
    }

    .expired-msg {
        display: none;
        background: #fee2e2;
        color: #991b1b;
        border: 1px solid #fca5a5;
        padding: 0.75rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.88rem;
        margin-bottom: 0.75rem;
    }
</style>

<div class="qr-page">
    <div class="qr-card">
        <h2>🩺 رمز تأكيد اليوم السريري</h2>
        <p class="subtitle">أعرض هذا الرمز على الدكتور ليمسحه ويؤكد كل بياناتك دفعة واحدة</p>

        <div class="timer-badge" id="timer">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            <span id="countdown">30:00</span>
        </div>

        <div class="qr-container" id="qrSection">
            <div id="qrcode"></div>
        </div>

        {{-- Expired message and actions --}}
        <div class="expired-msg" id="expiredMsg">⚠️ انتهت صلاحية الباركود! اختر إجراء:</div>
        <div class="expired-actions" id="expiredActions">
            <a href="{{ route('student.clinical.daily-log.regenerate', $dailyLog->id) }}" class="btn-regenerate" onclick="event.preventDefault(); document.getElementById('regenerateForm').submit();">🔄 تجديد الباركود (رمز جديد)</a>
            <a href="#" class="btn-cancel" onclick="event.preventDefault(); if(confirm('هل أنت متأكد؟ سيتم حذف سجل اليوم بالكامل.')) document.getElementById('cancelForm').submit();">🗑 إلغاء السجل وحذفه</a>
        </div>

        <form id="regenerateForm" action="{{ route('student.clinical.daily-log.regenerate', $dailyLog->id) }}" method="POST" style="display:none;">@csrf</form>
        <form id="cancelForm" action="{{ route('student.clinical.daily-log.cancel', $dailyLog->id) }}" method="POST" style="display:none;">@csrf @method('DELETE')</form>

        {{-- Signatures summary --}}
        <div class="signatures-grid">
            <div class="sig-item">✅ حضور</div>
            <div class="sig-item {{ $dailyLog->history_count > 0 ? '' : 'empty' }}">📋 قصص مرضية ({{ $dailyLog->history_count }})</div>
            <div class="sig-item {{ $dailyLog->exam_count > 0 ? '' : 'empty' }}">🩺 فحوصات ({{ $dailyLog->exam_count }})</div>
            <div class="sig-item {{ $dailyLog->did_round ? '' : 'empty' }}">🔄 مرور {{ $dailyLog->did_round ? '✓' : '✗' }}</div>
        </div>

        <div class="data-summary">
            <div class="summary-row"><span class="val">{{ $dailyLog->trainingCenter->name ?? '-' }}</span><span class="lbl">المركز</span></div>
            <div class="summary-row"><span class="val">{{ $dailyLog->department->name ?? '-' }}</span><span class="lbl">القسم</span></div>
            <div class="summary-row"><span class="val">د. {{ $dailyLog->doctor->name ?? '-' }}</span><span class="lbl">الدكتور</span></div>
            <div class="summary-row"><span class="val">{{ $dailyLog->log_date->format('Y-m-d') }}</span><span class="lbl">التاريخ</span></div>
        </div>

        <a href="{{ route('student.clinical.index') }}" class="btn-back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            العودة للقسم العملي
        </a>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        new QRCode(document.getElementById("qrcode"), {
            text: "{{ $dailyLog->qr_token }}",
            width: 220,
            height: 220,
            colorDark: "#1e1b4b",
            colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.H
        });

        const createdAt = new Date("{{ $dailyLog->created_at->toIso8601String() }}");
        const expiresAt = new Date(createdAt.getTime() + 30 * 60 * 1000);

        function updateTimer() {
            const diff = expiresAt - new Date();
            if (diff <= 0) {
                document.getElementById('countdown').textContent = 'منتهي الصلاحية';
                document.getElementById('timer').classList.add('expired');
                document.getElementById('qrSection').style.display = 'none';
                document.getElementById('expiredMsg').style.display = 'block';
                document.getElementById('expiredActions').style.display = 'flex';
                return;
            }
            const m = Math.floor(diff / 60000),
                s = Math.floor((diff % 60000) / 1000);
            document.getElementById('countdown').textContent = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
        }
        updateTimer();
        setInterval(updateTimer, 1000);
    });
</script>
@endpush