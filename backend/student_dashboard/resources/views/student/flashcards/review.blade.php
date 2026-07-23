@extends('layouts.student')

@section('title', 'مراجعة - Oneline Shot')

@push('styles')
<style>
    [x-cloak] { display: none !important; }
    .review-shell { max-width: 960px; margin: 0 auto; }
    .review-card { min-height: 430px; border-radius: 28px; }
    .review-face { min-height: 320px; border-radius: 24px; }
    .option-tile { cursor: pointer; transition: .2s ease; }
    .option-tile:hover { transform: translateY(-2px); }
    .option-tile.selected { border-color: #4f46e5 !important; background: #eef2ff !important; }
    .response-btn { font-weight: 800; border-radius: 16px; padding: .95rem 1rem; }
</style>
@endpush

@section('content')
<div class="review-shell py-4" x-data="reviewSession()" x-cloak>
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <a href="{{ route('student.flashcards.show', $flashcard) }}" class="btn btn-light border rounded-3 fw-bold">إنهاء</a>
        <div class="fw-black text-dark">
            <span x-text="currentIndex + 1"></span>
            /
            <span x-text="totalItems"></span>
        </div>
        <div class="badge text-white px-3 py-2" style="background: {{ $flashcard->color }};">{{ $flashcard->title }}</div>
    </div>

    <div class="card border-0 shadow-sm review-card">
        <div class="card-body p-4 p-md-5">
            @if($items->count() > 0)
                <div class="progress mb-4" style="height: 8px;">
                    <div class="progress-bar" role="progressbar" :style="'width:' + (((currentIndex + 1) / totalItems) * 100) + '%'" style="background: {{ $flashcard->color }};"></div>
                </div>

                <div class="review-face border p-4 d-flex flex-column justify-content-center" :style="'border-color:' + currentItemColor">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <span class="badge text-white" :style="'background:' + currentItemColor" x-text="currentItem?.item_type_label ?? ''"></span>
                        <span class="badge bg-light text-dark" x-text="currentItem?.pack?.title ?? '{{ $flashcard->title }}'"></span>
                    </div>

                    <template x-if="currentType === 'flash_card'">
                        <div>
                            <div class="text-secondary small fw-bold mb-2" x-text="isFlipped ? 'الوجه الخلفي' : 'الوجه الأمامي'"></div>
                            <div class="display-6 fw-black text-dark mb-4" x-text="isFlipped ? currentItem?.back_content : currentItem?.front_content"></div>
                            <button class="btn btn-outline-primary rounded-3 fw-bold" @click="isFlipped = !isFlipped" x-text="isFlipped ? 'إظهار الوجه الأمامي' : 'إظهار الوجه الخلفي'"></button>
                        </div>
                    </template>

                    <template x-if="currentType === 'one_line'">
                        <div>
                            <div class="text-secondary small fw-bold mb-2">نص سريع</div>
                            <div class="display-6 fw-black text-dark" x-text="currentItem?.front_content"></div>
                        </div>
                    </template>

                    <template x-if="currentType === 'qa'">
                        <div>
                            <div class="text-secondary small fw-bold mb-2">السؤال</div>
                            <div class="h2 fw-black text-dark mb-4" x-text="currentItem?.front_content"></div>
                            <template x-if="!qaChecked">
                                <div>
                                    <label class="form-label fw-bold">إجابتك</label>
                                    <textarea class="form-control form-control-lg" rows="3" x-model="userAnswer"></textarea>
                                    <button class="btn btn-primary rounded-3 fw-bold mt-3" @click="checkQaAnswer()" :disabled="!userAnswer.trim()">تحقق من الإجابة</button>
                                </div>
                            </template>
                            <template x-if="qaChecked">
                                <div class="alert alert-light border rounded-4">
                                    <div class="fw-bold text-secondary mb-2">الإجابة النموذجية</div>
                                    <div class="fw-black text-dark mb-2" x-text="currentItem?.back_content"></div>
                                    <div class="small" :class="qaExactMatch ? 'text-success' : 'text-warning'" x-text="qaExactMatch ? 'مطابقة تامة' : 'راجع الفرق ثم قيّم صعوبتها'"></div>
                                </div>
                            </template>
                        </div>
                    </template>

                    <template x-if="currentType === 'mcq'">
                        <div>
                            <div class="text-secondary small fw-bold mb-2">سؤال اختيارات</div>
                            <div class="h2 fw-black text-dark mb-4" x-text="currentItem?.front_content"></div>
                            <div class="row g-3">
                                <template x-for="(option, index) in (currentItem?.options || [])" :key="index">
                                    <div class="col-md-6">
                                        <div class="border rounded-4 p-3 bg-light option-tile"
                                             :class="{ 'selected': selectedOption === index }"
                                             @click="selectedOption = index">
                                            <div class="fw-bold text-dark" x-text="option"></div>
                                        </div>
                                    </div>
                                </template>
                            </div>
                            <template x-if="selectedOption !== null">
                                <div class="alert alert-light border rounded-4 mt-4 mb-0">
                                    <div class="fw-bold text-secondary mb-2">الاختيار الصحيح</div>
                                    <div class="fw-black" :class="selectedOption === currentItem?.correct_option ? 'text-success' : 'text-danger'">
                                        <span x-text="(currentItem?.correct_option ?? 0) + 1"></span>
                                        <span class="ms-2" x-text="selectedOption === currentItem?.correct_option ? 'إجابة صحيحة' : 'يمكنك الآن تقييم مستوى الصعوبة'"></span>
                                    </div>
                                </div>
                            </template>
                        </div>
                    </template>
                </div>

                <div class="row g-3 mt-3" x-show="canRateCurrent()" x-cloak>
                    <div class="col-md-4">
                        <button class="btn btn-success w-100 response-btn" @click="submitResponse('easy')" :disabled="isSubmitting">سهل</button>
                        <div class="small text-secondary mt-1 text-center">يخفف من الظهور</div>
                    </div>
                    <div class="col-md-4">
                        <button class="btn btn-warning w-100 response-btn" @click="submitResponse('medium')" :disabled="isSubmitting">متوسط</button>
                        <div class="small text-secondary mt-1 text-center">ظهور متوازن</div>
                    </div>
                    <div class="col-md-4">
                        <button class="btn btn-danger w-100 response-btn" @click="submitResponse('hard')" :disabled="isSubmitting">صعب</button>
                        <div class="small text-secondary mt-1 text-center">أولوية أعلى في التكرار</div>
                    </div>
                </div>

                <div class="d-flex justify-content-between align-items-center mt-4">
                    <button class="btn btn-light border rounded-3 fw-bold" @click="prev()" :disabled="currentIndex === 0 || isSubmitting">السابق</button>
                    <div class="small text-secondary">
                        <template x-if="currentItem?.user_progress?.last_response">
                            <span>آخر تقييم: <strong x-text="responseLabel(currentItem.user_progress.last_response)"></strong></span>
                        </template>
                    </div>
                    <button class="btn btn-light border rounded-3 fw-bold" @click="next()" :disabled="currentIndex >= totalItems - 1 || isSubmitting">التالي</button>
                </div>
            @else
                <div class="text-center py-5">
                    <h3 class="fw-black text-dark mb-2">لا توجد عناصر للمراجعة</h3>
                    <p class="text-secondary mb-4">أضف عناصر أو حزمًا فرعية أولًا.</p>
                    <a href="{{ route('student.flashcards.show', $flashcard) }}" class="btn btn-primary rounded-3 fw-bold">العودة للحزمة</a>
                </div>
            @endif
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
function reviewSession() {
    return {
        items: @json($items->values()),
        currentIndex: 0,
        isFlipped: false,
        userAnswer: '',
        qaChecked: false,
        qaExactMatch: false,
        selectedOption: null,
        isSubmitting: false,
        totalItems: {{ $items->count() }},
        progressUrl: "{{ route('student.flashcards.progress') }}",

        get currentItem() {
            return this.items[this.currentIndex] || null;
        },

        get currentType() {
            return this.currentItem?.resolved_item_type || this.currentItem?.item_type || 'flash_card';
        },

        get currentItemColor() {
            return this.currentItem?.resolved_color || "{{ $flashcard->color }}";
        },

        canRateCurrent() {
            if (!this.currentItem) return false;
            if (this.currentType === 'flash_card') return this.isFlipped;
            if (this.currentType === 'one_line') return true;
            if (this.currentType === 'qa') return this.qaChecked;
            if (this.currentType === 'mcq') return this.selectedOption !== null;
            return false;
        },

        checkQaAnswer() {
            const expected = (this.currentItem?.back_content || '').trim().toLowerCase();
            const answer = this.userAnswer.trim().toLowerCase();
            this.qaExactMatch = expected !== '' && expected === answer;
            this.qaChecked = true;
        },

        async submitResponse(level) {
            if (this.isSubmitting || !this.currentItem) return;
            this.isSubmitting = true;

            try {
                const response = await fetch(this.progressUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        item_id: this.currentItem.id,
                        response_level: level
                    })
                });

                if (response.ok) {
                    if (this.currentIndex < this.totalItems - 1) {
                        this.next();
                    } else {
                        window.location.href = "{{ route('student.flashcards.show', $flashcard) }}?finished=1";
                    }
                }
            } finally {
                this.isSubmitting = false;
            }
        },

        next() {
            if (this.currentIndex < this.totalItems - 1) {
                this.currentIndex++;
                this.resetState();
            }
        },

        prev() {
            if (this.currentIndex > 0) {
                this.currentIndex--;
                this.resetState();
            }
        },

        resetState() {
            this.isFlipped = false;
            this.userAnswer = '';
            this.qaChecked = false;
            this.qaExactMatch = false;
            this.selectedOption = null;
        },

        responseLabel(level) {
            if (level === 'easy') return 'سهل';
            if (level === 'medium') return 'متوسط';
            if (level === 'hard') return 'صعب';
            return level;
        }
    };
}
</script>
@endpush
