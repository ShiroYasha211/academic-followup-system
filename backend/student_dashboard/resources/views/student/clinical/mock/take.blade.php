@extends('layouts.student')
@section('title', 'الاختبار التجريبي: ' . $checklist->title)
@section('content')
<style>
    .exam-header {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 1.5rem;
    }

    .exam-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.25rem 0;
    }

    .exam-desc {
        color: #64748b;
        font-size: 0.95rem;
        margin: 0;
    }

    /* Sticky Timer */
    .timer-badge {
        background: #fef2f2;
        border: 2px solid #ef4444;
        color: #b91c1c;
        padding: 0.75rem 1.5rem;
        border-radius: 12px;
        font-size: 1.5rem;
        font-weight: 800;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        position: sticky;
        top: 20px;
        z-index: 50;
        box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);
    }

    .timer-badge.warning {
        animation: pulse 1s infinite alternate;
    }

    @keyframes pulse {
        from {
            transform: scale(1);
            box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);
        }

        to {
            transform: scale(1.05);
            box-shadow: 0 8px 24px rgba(239, 68, 68, 0.3);
        }
    }

    .items-container {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        margin-bottom: 2rem;
    }

    .task-item {
        padding: 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        flex-direction: column;
        gap: 1rem;
        transition: background 0.2s;
    }

    .task-item:last-child {
        border-bottom: none;
    }

    .task-item:hover {
        background: #f8fafc;
    }

    .t-desc {
        font-size: 1.05rem;
        font-weight: 600;
        color: var(--text-primary);
        line-height: 1.5;
    }

    .t-max {
        font-size: 0.85rem;
        color: #64748b;
        background: #f1f5f9;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        display: inline-block;
    }

    /* Modern Radio Buttons for Scoring */
    .scoring-options {
        display: flex;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .score-radio {
        display: none;
    }

    .score-label {
        padding: 0.6rem 1.25rem;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.95rem;
        color: #64748b;
        cursor: pointer;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        align-items: center;
        justify-content: center;
        min-width: 120px;
    }

    /* Done (Green) */
    .score-radio[value="done"]:checked+.score-label {
        border-color: #10b981;
        background: #d1fae5;
        color: #047857;
    }

    /* Partial (Orange) */
    .score-radio[value="partial"]:checked+.score-label {
        border-color: #f59e0b;
        background: #fef3c7;
        color: #b45309;
    }

    /* Not Done (Red) */
    .score-radio[value="not_done"]:checked+.score-label {
        border-color: #ef4444;
        background: #fee2e2;
        color: #b91c1c;
    }

    .btn-submit {
        background: #4f46e5;
        color: white;
        border: none;
        padding: 1rem 2rem;
        border-radius: 12px;
        font-size: 1.1rem;
        font-weight: 800;
        cursor: pointer;
        transition: background 0.2s;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        width: 100%;
        justify-content: center;
        margin-bottom: 3rem;
    }

    .btn-submit:hover {
        background: #4338ca;
    }
</style>

<div x-data="mockExam({{ $checklist->time_limit_minutes ?? 10 }})">
    <!-- Timer Configuration Modal / Overlay -->
    <div x-show="status === 'pending'" style="background: white; border-radius: 20px; border: 1px solid #e2e8f0; padding: 3rem; text-align: center; max-width: 500px; margin: 2rem auto; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);">
        <div style="width: 80px; height: 80px; border-radius: 20px; background: #eef2ff; color: #4f46e5; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem auto;">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <h2 style="font-size: 1.5rem; font-weight: 800; color: #1e293b; margin-bottom: 0.5rem;">إعداد مؤقت الاختبار</h2>
        <p style="color: #64748b; margin-bottom: 2rem;">كيف تود حساب الوقت في هذه المحاولة؟</p>

        <div style="display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem; text-align: right;">
            <label style="display: flex; align-items: center; gap: 1rem; padding: 1rem; border: 2px solid #e2e8f0; border-radius: 12px; cursor: pointer; transition: all 0.2s;" :style="timerMode === 'official' ? 'border-color: #4f46e5; background: #f8fafc;' : ''">
                <input type="radio" value="official" x-model="timerMode" style="width: 1.2rem; height: 1.2rem; accent-color: #4f46e5;">
                <div style="flex:1;">
                    <div style="font-weight: 700; color: #1e293b; font-size: 1.05rem;">وقت الكلية الرسمي ({{ $checklist->time_limit_minutes ?? 10 }} دقيقة)</div>
                    <div style="color: #64748b; font-size: 0.85rem; margin-top: 0.25rem;">مؤقت تنازلي يحاكي ضغط الاختبار الحقيقي.</div>
                </div>
            </label>

            <label style="display: flex; align-items: center; gap: 1rem; padding: 1rem; border: 2px solid #e2e8f0; border-radius: 12px; cursor: pointer; transition: all 0.2s;" :style="timerMode === 'custom' ? 'border-color: #4f46e5; background: #f8fafc;' : ''">
                <input type="radio" value="custom" x-model="timerMode" style="width: 1.2rem; height: 1.2rem; accent-color: #4f46e5;">
                <div style="flex:1;">
                    <div style="font-weight: 700; color: #1e293b; font-size: 1.05rem; display: flex; align-items: center; gap: 0.5rem;">
                        وقت مخصص:
                        <input type="number" x-model.number="customMinutes" min="1" max="120" style="width: 70px; padding: 0.25rem; border: 1px solid #cbd5e1; border-radius: 6px; text-align: center;" @click.stop> دقيقة
                    </div>
                </div>
            </label>

            <label style="display: flex; align-items: center; gap: 1rem; padding: 1rem; border: 2px solid #e2e8f0; border-radius: 12px; cursor: pointer; transition: all 0.2s;" :style="timerMode === 'freebie' ? 'border-color: #4f46e5; background: #f8fafc;' : ''">
                <input type="radio" value="freebie" x-model="timerMode" style="width: 1.2rem; height: 1.2rem; accent-color: #4f46e5;">
                <div style="flex:1;">
                    <div style="font-weight: 700; color: #1e293b; font-size: 1.05rem;">توقيت حر (Stopwatch)</div>
                    <div style="color: #64748b; font-size: 0.85rem; margin-top: 0.25rem;">يبدأ بالعد من الصفر لمعرفة كم تستغرق من الوقت بدون ضغط الإغلاق التلقائي.</div>
                </div>
            </label>
        </div>

        <div style="display: flex; gap: 1rem;">
            <a href="{{ route('student.clinical.mock.index') }}" style="flex: 1; padding: 1rem; border-radius: 12px; background: #f1f5f9; color: #334155; font-weight: 700; text-decoration: none; display: flex; align-items: center; justify-content: center;">إلغاء</a>
            <button @click="startExam()" style="flex: 2; padding: 1rem; border-radius: 12px; background: #4f46e5; color: white; border: none; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; font-size: 1.05rem;">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polygon points="5 3 19 12 5 21 5 3"></polygon>
                </svg>
                بدء الاختبار
            </button>
        </div>
    </div>

    <!-- Active Exam Interface -->
    <div x-show="status === 'active'" style="display: none;" x-transition>
        <div class="exam-header">
            <div class="right-side">
                <h1 class="exam-title">{{ $checklist->title }}</h1>
                <p class="exam-desc">قيم أداءك بصدق للحصول على نتيجة تعكس مستواك الحقيقي.</p>
            </div>

            <div class="timer-badge" :class="{'warning': showAlert}">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                </svg>
                <span x-text="formattedTime" style="direction: ltr; font-variant-numeric: tabular-nums;"></span>
            </div>
        </div>

        <form x-ref="examForm" action="{{ route('student.clinical.mock.store') }}" method="POST">
            @csrf
            <input type="hidden" name="checklist_id" value="{{ $checklist->id }}">
            <input type="hidden" name="time_taken" x-model="timeTaken">

            <div class="items-container">
                @php
                    $mainItems = $checklist->items->whereNull('parent_id');
                @endphp

                @foreach($mainItems as $idx => $mainItem)
                    @php
                        $subItems = $checklist->items->where('parent_id', $mainItem->id);
                        $hasSubitems = $subItems->count() > 0;
                    @endphp

                    <div class="task-item" style="margin-top: {{ $loop->first ? '0' : '1rem' }}; {{ $hasSubitems ? 'background: #f8fafc; border: 1.5px solid #cbd5e1; border-right: 4px solid #4f46e5; border-radius: 12px; margin-inline: 1rem; margin-bottom: 1rem;' : '' }}">
                        <div>
                            <span style="font-weight:800; color:#4f46e5; margin-left:0.5rem; font-size: {{ $hasSubitems ? '1.2rem' : '1rem' }};">{{ $loop->iteration }}.</span>
                            <span class="t-desc" style="{{ $hasSubitems ? 'font-size: 1.15rem; font-weight: 800;' : '' }}">{{ $mainItem->description }}</span>
                            <div style="margin-top: 0.5rem;">
                                <span class="t-max" style="{{ $hasSubitems ? 'background: #e0e7ff; color: #3730a3; font-weight: 800;' : '' }}">العلامة القصوى: {{ $mainItem->marks }}</span>
                            </div>
                        </div>

                        @if(!$hasSubitems)
                            <div class="scoring-options">
                                <input type="radio" name="scores[{{ $mainItem->id }}][score]" value="done" id="score_{{ $mainItem->id }}_done" class="score-radio">
                                <label for="score_{{ $mainItem->id }}_done" class="score-label">أُنجِز بشكل كامل ✅</label>

                                <input type="radio" name="scores[{{ $mainItem->id }}][score]" value="partial" id="score_{{ $mainItem->id }}_partial" class="score-radio">
                                <label for="score_{{ $mainItem->id }}_partial" class="score-label">أُنجِز جزئياً ⚠️</label>

                                <input type="radio" name="scores[{{ $mainItem->id }}][score]" value="not_done" id="score_{{ $mainItem->id }}_not_done" class="score-radio" checked>
                                <label for="score_{{ $mainItem->id }}_not_done" class="score-label">لم يُنجَز ❌</label>
                            </div>

                            <div style="margin-top: 1rem; background: #fafbfe; border-radius: 10px; padding: 0.75rem; border: 1px dashed #cbd5e1;">
                                <label style="display: block; font-size: 0.85rem; font-weight: 700; color: #64748b; margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2-2h14a2 2 0 0 0 2-2v-7"></path>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                    </svg>
                                    ملاحظات التقييم (اختياري)
                                </label>
                                <input type="text" name="scores[{{ $mainItem->id }}][notes]" placeholder="دون أي ملاحظة تود تذكرها عن أدائك في هذا البند..." style="width: 100%; padding: 0.6rem 1rem; border: 1px solid #cbd5e1; border-radius: 8px; font-family: inherit; font-size: 0.9rem;" autocomplete="off">
                            </div>
                        @else
                            <div style="padding-right: 2rem; border-right: 2px dashed #cbd5e1; margin-right: 1rem; margin-top: 1rem; display: flex; flex-direction: column; gap: 1rem;">
                                @foreach($subItems as $subItem)
                                    <div style="background: white; border: 1px solid #e2e8f0; border-radius: 10px; padding: 1rem;">
                                        <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                                            <span style="color:#94a3b8; font-weight:bold;">↳</span>
                                            <span style="font-size: 1rem; font-weight: 700; color:var(--text-primary);">{{ $subItem->description }}</span>
                                            <span style="font-size: 0.85rem; color: #64748b; background: #f1f5f9; padding: 0.2rem 0.5rem; border-radius: 6px; margin-right: auto;">العلامة: {{ $subItem->marks }}</span>
                                        </div>

                                        <div class="scoring-options" style="gap: 0.5rem;">
                                            <input type="radio" name="scores[{{ $subItem->id }}][score]" value="done" id="score_{{ $subItem->id }}_done" class="score-radio">
                                            <label for="score_{{ $subItem->id }}_done" class="score-label" style="padding: 0.4rem 1rem; font-size: 0.85rem; min-width: 100px;">كامل ✅</label>

                                            <input type="radio" name="scores[{{ $subItem->id }}][score]" value="partial" id="score_{{ $subItem->id }}_partial" class="score-radio">
                                            <label for="score_{{ $subItem->id }}_partial" class="score-label" style="padding: 0.4rem 1rem; font-size: 0.85rem; min-width: 100px;">جزئي ⚠️</label>

                                            <input type="radio" name="scores[{{ $subItem->id }}][score]" value="not_done" id="score_{{ $subItem->id }}_not_done" class="score-radio" checked>
                                            <label for="score_{{ $subItem->id }}_not_done" class="score-label" style="padding: 0.4rem 1rem; font-size: 0.85rem; min-width: 100px;">لا ❌</label>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        @endif
                    </div>
                @endforeach
            </div>

            <button type="submit" class="btn-submit">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
                إنهاء المراجعة وإصدار النتيجة
            </button>
        </form>
    </div>
</div>

<script>
    document.addEventListener('alpine:init', () => {
        Alpine.data('mockExam', (officialMinutes) => ({
            status: 'pending', // pending, active, submitted
            timerMode: 'official', // official, custom, freebie
            customMinutes: officialMinutes,

            isCountDown: true,
            totalSeconds: 0,
            timeRemaining: 0,
            timeTaken: 0,
            timerInterval: null,

            startExam() {
                this.status = 'active';
                this.isCountDown = this.timerMode !== 'freebie';

                if (this.timerMode === 'official') {
                    this.totalSeconds = officialMinutes * 60;
                } else if (this.timerMode === 'custom') {
                    this.totalSeconds = (this.customMinutes || 1) * 60;
                } else {
                    this.totalSeconds = 0; // Starts at 0, counts up
                }

                this.timeRemaining = this.totalSeconds;
                this.timeTaken = 0;

                this.initTimer();
                this.setupUnloadWarning();
            },

            initTimer() {
                this.timerInterval = setInterval(() => {
                    if (this.isCountDown) {
                        this.timeRemaining--;
                        this.timeTaken++;

                        if (this.timeRemaining <= 0) {
                            clearInterval(this.timerInterval);
                            this.timeRemaining = 0;
                            this.status = 'submitted';
                            alert("انتهى وقت الاختبار التجريبي! سيتم التسليم الآن.");
                            this.$refs.examForm.submit();
                        }
                    } else {
                        // Stopwatch (Freebie Mode)
                        this.timeTaken++;
                        this.timeRemaining = this.timeTaken;
                    }
                }, 1000);
            },

            get formattedTime() {
                let m = Math.floor(this.timeRemaining / 60);
                let s = this.timeRemaining % 60;
                return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
            },

            get showAlert() {
                return this.isCountDown && this.timeRemaining <= 60 && this.timeRemaining > 0;
            },

            setupUnloadWarning() {
                window.addEventListener('beforeunload', (e) => {
                    if (this.status === 'active' && document.activeElement.type !== "submit") {
                        const confirmationMessage = 'أنت في منتصف إختبار تجريبي. هل أنت متأكد من رغبتك في المغادرة و فقدان تقدمك؟';
                        e.returnValue = confirmationMessage;
                        return confirmationMessage;
                    }
                });
            }
        }));
    });
</script>

@endsection