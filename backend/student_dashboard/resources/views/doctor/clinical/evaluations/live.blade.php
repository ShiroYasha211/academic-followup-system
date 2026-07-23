@extends('layouts.doctor')
@section('title', 'تقييم مباشر')
@section('content')
<style>
    .live-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.5rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .live-header .info h2 {
        font-size: 1.4rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0;
    }

    .live-header .info p {
        color: var(--text-secondary);
        font-size: 0.88rem;
        margin: 0.1rem 0 0 0;
    }

    .timer-box {
        background: #0f172a;
        color: #22d3ee;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-size: 2rem;
        font-weight: 800;
        font-family: 'Courier New', monospace;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .timer-box.warning {
        color: #fbbf24;
    }

    .timer-box.danger {
        color: #ef4444;
        animation: pulse 1s infinite;
    }

    @keyframes pulse {

        0%,
        100% {
            opacity: 1;
        }

        50% {
            opacity: 0.6;
        }
    }

    .student-badge {
        background: #ede9fe;
        color: #7c3aed;
        padding: 0.35rem 0.85rem;
        border-radius: 8px;
        font-weight: 700;
        font-size: 0.9rem;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .checklist-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 0.85rem;
        border-radius: 12px;
        border: 1px solid #f1f5f9;
        margin-bottom: 0.5rem;
        transition: all 0.15s;
    }

    .checklist-item:hover {
        background: #fafbfe;
        border-color: #e2e8f0;
    }

    .item-number {
        font-weight: 700;
        color: var(--text-secondary);
        min-width: 28px;
        text-align: center;
        font-size: 0.88rem;
    }

    .item-desc {
        flex: 1;
        font-size: 0.92rem;
        font-weight: 600;
        color: var(--text-primary);
    }

    .item-marks {
        font-size: 0.78rem;
        color: var(--text-secondary);
        min-width: 50px;
        text-align: center;
    }

    .score-btns {
        display: flex;
        gap: 0.35rem;
    }

    .score-btn {
        padding: 0.35rem 0.65rem;
        border-radius: 7px;
        border: 1.5px solid #e2e8f0;
        background: white;
        font-weight: 600;
        font-size: 0.78rem;
        cursor: pointer;
        transition: all 0.15s;
    }

    .score-btn:hover {
        border-color: #cbd5e1;
    }

    .score-btn.done.active {
        background: #d1fae5;
        border-color: #059669;
        color: #065f46;
    }

    .score-btn.partial.active {
        background: #fef3c7;
        border-color: #d97706;
        color: #92400e;
    }

    .score-btn.not_done.active {
        background: #fee2e2;
        border-color: #ef4444;
        color: #991b1b;
    }

    .feedback-area {
        width: 100%;
        padding: 0.75rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 10px;
        font-family: inherit;
        font-size: 0.9rem;
        resize: vertical;
        min-height: 80px;
    }

    .feedback-area:focus {
        outline: none;
        border-color: var(--primary-color);
    }

    .btn-submit-eval {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.85rem 2rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 1rem;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        width: 100%;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.25);
        transition: all 0.2s;
    }

    .btn-submit-eval:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.35);
    }
</style>

@php
$timerTypeVal = $request->timer_type ?? 'fixed';
$timeLimitMin = $checklist->time_limit_minutes ?? 15;
$timeLimitSec = $timeLimitMin * 60;
@endphp

<div class="live-header">
    <div class="info">
        <h2>🎯 تقييم مباشر: {{ $checklist->title }}</h2>
        <p><span class="student-badge">👤 {{ $student->name }}</span> · {{ $bodySystem->name ?? '' }} · {{ $checklist->skill_label }} · {{ $checklist->items->count() }} عنصر · <span style="background:#dbeafe;color:#1d4ed8;padding:0.15rem 0.5rem;border-radius:5px;font-weight:700;font-size:0.78rem;">{{ $timerTypeVal == 'open' ? '🔓 وقت مفتوح' : '⏱ وقت محدد' }}</span></p>
    </div>
    <div class="timer-box" id="timer">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <polyline points="12 6 12 12 16 14"></polyline>
        </svg>
        <span id="timer-display">{{ $timerTypeVal == 'open' ? '00:00' : sprintf('%02d', $timeLimitMin) . ':00' }}</span>
    </div>
</div>

<form action="{{ route('doctor.clinical.evaluations.submit') }}" method="POST" id="eval-form">
    @csrf
    <input type="hidden" name="checklist_id" value="{{ $checklist->id }}">
    <input type="hidden" name="student_id" value="{{ $student->id }}">
    <input type="hidden" name="clinical_case_id" value="{{ $request->clinical_case_id }}">
    <input type="hidden" name="procedure_type" value="{{ $request->procedure_type }}">
    <input type="hidden" name="body_system_id" value="{{ $request->body_system_id }}">
    <input type="hidden" name="timer_type" value="{{ $timerTypeVal }}">
    <input type="hidden" name="time_taken_seconds" id="time-taken" value="0">

    <div class="card-section">
        @php
            $mainItems = $checklist->items->whereNull('parent_id');
        @endphp

        @foreach($mainItems as $mainItem)
            @php
                $subItems = $checklist->items->where('parent_id', $mainItem->id);
                $hasSubitems = $subItems->count() > 0;
            @endphp
            <div class="checklist-item" id="item-{{ $mainItem->id }}" style="margin-top: 1rem; {{ $hasSubitems ? 'background: #f8fafc; border: 1.5px solid #cbd5e1; border-right: 4px solid var(--primary-color);' : '' }}">
                <span class="item-number" style="{{ $hasSubitems ? 'color: var(--primary-color); font-size: 1rem;' : '' }}">{{ $loop->iteration }}</span>
                <span class="item-desc" style="{{ $hasSubitems ? 'font-size: 1.05rem;' : '' }}">{{ $mainItem->description }}</span>
                <span class="item-marks" style="{{ $hasSubitems ? 'font-weight: 800; color: var(--primary-color);' : '' }}">{{ $mainItem->marks }} د</span>
                
                @if(!$hasSubitems)
                <div class="score-btns">
                    <input type="hidden" name="scores[{{ $mainItem->id }}][score]" value="not_done" id="score-input-{{ $mainItem->id }}">
                    <button type="button" class="score-btn done" onclick="setScore({{ $mainItem->id }}, 'done', this)">✓ كامل</button>
                    <button type="button" class="score-btn partial" onclick="setScore({{ $mainItem->id }}, 'partial', this)">½ جزئي</button>
                    <button type="button" class="score-btn not_done active" onclick="setScore({{ $mainItem->id }}, 'not_done', this)">✗ لا</button>
                </div>
                @endif
            </div>

            @if($hasSubitems)
                <div style="padding-right: 2.5rem; border-right: 2px dashed #e2e8f0; margin-right: 1.5rem; margin-bottom: 1.5rem;">
                @foreach($subItems as $subItem)
                    <div class="checklist-item" id="item-{{ $subItem->id }}" style="background: white; border: 1px solid #e2e8f0; margin-top: 0.25rem;">
                        <span style="color:#94a3b8; font-weight:bold;">↳</span>
                        <span class="item-desc" style="font-size: 0.88rem; color: #475569;">{{ $subItem->description }}</span>
                        <span class="item-marks" style="color: #64748b;">{{ $subItem->marks }} د</span>
                        <div class="score-btns">
                            <input type="hidden" name="scores[{{ $subItem->id }}][score]" value="not_done" id="score-input-{{ $subItem->id }}">
                            <button type="button" class="score-btn done" onclick="setScore({{ $subItem->id }}, 'done', this)">✓ كامل</button>
                            <button type="button" class="score-btn partial" onclick="setScore({{ $subItem->id }}, 'partial', this)">½ جزئي</button>
                            <button type="button" class="score-btn not_done active" onclick="setScore({{ $subItem->id }}, 'not_done', this)">✗ لا</button>
                        </div>
                    </div>
                @endforeach
                </div>
            @endif
        @endforeach
    </div>

    <div class="card-section">
        <label style="font-weight:700; font-size:0.95rem; display:block; margin-bottom:0.5rem;">ملاحظات الدكتور (اختياري)</label>
        <textarea name="doctor_feedback" class="feedback-area" placeholder="ملاحظات عن أداء الطالب أو نقاط تحتاج تحسين..."></textarea>
    </div>

    <button type="submit" class="btn-submit-eval">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 11l3 3L22 4"></path>
            <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
        </svg>
        إنهاء التقييم وحفظ النتائج
    </button>
</form>
@endsection

@push('scripts')
<script>
    const timerType = '@php echo $timerTypeVal @endphp';
    const timeLimitSeconds = @php echo $timeLimitSec @endphp;
    let elapsedSeconds = 0;

    function updateTimer() {
        elapsedSeconds++;
        const display = document.getElementById('timer-display');
        const box = document.getElementById('timer');

        if (timerType === 'open') {
            // Count up (stopwatch)
            const m = Math.floor(elapsedSeconds / 60);
            const s = elapsedSeconds % 60;
            display.textContent = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
        } else {
            // Count down
            const remaining = Math.max(timeLimitSeconds - elapsedSeconds, 0);
            const m = Math.floor(remaining / 60);
            const s = remaining % 60;
            display.textContent = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');

            if (remaining <= 60) box.className = 'timer-box danger';
            else if (remaining <= timeLimitSeconds * 0.3) box.className = 'timer-box warning';

            if (remaining <= 0) {
                display.textContent = 'انتهى الوقت';
                return;
            }
        }
        setTimeout(updateTimer, 1000);
    }
    setTimeout(updateTimer, 1000);

    function setScore(itemId, score, btn) {
        document.getElementById('score-input-' + itemId).value = score;
        const btns = btn.parentElement.querySelectorAll('.score-btn');
        btns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
    }

    document.getElementById('eval-form').addEventListener('submit', function() {
        document.getElementById('time-taken').value = elapsedSeconds;
    });
</script>
@endpush