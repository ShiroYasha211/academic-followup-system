@extends('layouts.student')

@section('title', 'رمز QR - تأكيد المهمة')

@section('content')
<style>
    .qr-page {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 65vh;
        text-align: center;
        padding: 2rem;
    }

    .qr-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2.5rem;
        max-width: 420px;
        width: 100%;
        box-shadow: 0 8px 30px rgba(0, 0, 0, 0.06);
    }

    .qr-card h2 {
        font-size: 1.3rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .qr-card .subtitle {
        color: var(--text-secondary);
        font-size: 0.88rem;
        margin-bottom: 1.5rem;
    }

    .qr-container {
        background: white;
        border: 3px solid #e2e8f0;
        border-radius: 16px;
        padding: 1.25rem;
        display: inline-block;
        margin-bottom: 1.5rem;
    }

    .qr-info {
        text-align: right;
        background: #f8fafc;
        border-radius: 12px;
        padding: 1rem;
        margin-bottom: 1.5rem;
    }

    .qr-info .info-row {
        display: flex;
        justify-content: space-between;
        padding: 0.35rem 0;
        font-size: 0.85rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .qr-info .info-row:last-child {
        border-bottom: none;
    }

    .qr-info .info-label {
        color: var(--text-secondary);
        font-weight: 600;
    }

    .qr-info .info-value {
        color: var(--text-primary);
        font-weight: 700;
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

    .btn-back-link {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.6rem 1.5rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
    }

    .btn-back-link:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }
</style>

<div class="qr-page">
    <div class="qr-card">
        <h2>🩺 رمز تأكيد المهمة</h2>
        <p class="subtitle">أعرض هذا الرمز على الدكتور ليقوم بمسحه وتأكيد إنجازك</p>

        {{-- Timer --}}
        <div class="timer-badge" id="timer">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            <span id="countdown">30:00</span>
        </div>

        {{-- QR Code --}}
        <div class="qr-container">
            <div id="qrcode"></div>
        </div>

        {{-- Info --}}
        <div class="qr-info">
            <div class="info-row">
                <span class="info-value">{{ $assignment->clinicalCase->patient_name ?? '-' }}</span>
                <span class="info-label">الحالة</span>
            </div>
            <div class="info-row">
                <span class="info-value">
                    @if($assignment->task_type == 'history_taking') قصة مرضية
                    @elseif($assignment->task_type == 'clinical_examination') فحص سريري
                    @else متابعة (Round) @endif
                </span>
                <span class="info-label">المهمة</span>
            </div>
            <div class="info-row">
                <span class="info-value">{{ $assignment->clinicalCase->trainingCenter->name ?? '-' }}</span>
                <span class="info-label">المركز</span>
            </div>
            <div class="info-row">
                <span class="info-value">{{ $assignment->clinicalCase->bodySystem->name ?? '-' }}</span>
                <span class="info-label">الجهاز</span>
            </div>
        </div>

        <a href="{{ route('student.clinical.index') }}" class="btn-back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            العودة للمهام
        </a>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Generate QR
        new QRCode(document.getElementById("qrcode"), {
            text: "{{ $logbook->qr_token }}",
            width: 220,
            height: 220,
            colorDark: "#1e1b4b",
            colorLight: "#ffffff",
            correctLevel: QRCode.CorrectLevel.H
        });

        // Countdown timer (30 min from creation)
        const createdAt = new Date("{{ $logbook->created_at->toIso8601String() }}");
        const expiresAt = new Date(createdAt.getTime() + 30 * 60 * 1000);

        function updateTimer() {
            const now = new Date();
            const diff = expiresAt - now;

            if (diff <= 0) {
                document.getElementById('countdown').textContent = 'منتهي الصلاحية';
                document.getElementById('timer').classList.add('expired');
                return;
            }

            const minutes = Math.floor(diff / 60000);
            const seconds = Math.floor((diff % 60000) / 1000);
            document.getElementById('countdown').textContent =
                String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
        }

        updateTimer();
        setInterval(updateTimer, 1000);
    });
</script>
@endpush