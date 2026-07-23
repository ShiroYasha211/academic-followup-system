@extends('layouts.delegate')

@section('title', 'التكاليف الدراسية')

@section('content')

<style>
    /* Custom Styles for Assignments Page */
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2.5rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .task-card {
        background: white;
        border-radius: 16px;
        border: 1px solid rgba(226, 232, 240, 0.8);
        padding: 1.5rem;
        position: relative;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        flex-direction: column;
        height: 100%;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .task-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        border-color: var(--primary-color);
    }

    .card-badge {
        position: absolute;
        top: 1.5rem;
        left: 1.5rem;
        padding: 0.35rem 0.75rem;
        border-radius: 99px;
        font-size: 0.75rem;
        font-weight: 700;
        background: #eff6ff;
        color: var(--primary-color);
    }

    .task-date {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.85rem;
        font-weight: 600;
        color: var(--text-secondary);
        background: #f8fafc;
        padding: 0.5rem 1rem;
        border-radius: 8px;
        align-self: flex-start;
        margin-top: auto;
    }

    .task-date.urgent {
        background: #fef2f2;
        color: var(--danger-color);
    }

    .task-title {
        font-size: 1.25rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-top: 2rem;
        margin-bottom: 0.75rem;
        line-height: 1.4;
    }

    .task-desc {
        color: var(--text-secondary);
        font-size: 0.95rem;
        line-height: 1.6;
        margin-bottom: 1.5rem;
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    .task-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.5rem;
        padding-top: 1rem;
        border-top: 1px dashed var(--border-color);
        margin-top: 1rem;
    }

    .action-btn {
        width: 32px;
        height: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 8px;
        color: var(--text-secondary);
        transition: all 0.2s;
        border: 1px solid transparent;
        background: transparent;
    }

    .action-btn:hover {
        background: #f1f5f9;
        color: var(--primary-color);
    }

    .action-btn.delete:hover {
        background: #fee2e2;
        color: var(--danger-color);
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 2px dashed var(--border-color);
    }

    /* Modal Styling Fixes */
    .modal-overlay {
        display: flex;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        z-index: 999;
        align-items: center;
        justify-content: center;
        backdrop-filter: blur(4px);
    }

    .modal-container {
        background: white;
        width: 90%;
        max-width: 600px;
        border-radius: 16px;
        padding: 2rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        max-height: 90vh;
        overflow-y: auto;
    }
</style>

<div class="container" style="max-width: 100%;" x-data="assignmentManager()">

    <!-- Page Header -->
    <div class="page-header">
        <div>
            <h1 class="page-title">التكاليف الدراسية</h1>
            <p style="color: var(--text-secondary);">إدارة التكاليف والمهام المطلوبة من الطلاب</p>
        </div>
        <button type="button" class="btn btn-primary" @click="openCreateModal()" style="padding: 0.75rem 1.5rem; display: flex; align-items: center; gap: 0.5rem; font-weight: 700;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إضافة تكليف
        </button>
    </div>

    @if(session('success'))
    <div class="alert alert-success d-flex align-items-center gap-2 mb-4" role="alert">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        {{ session('success') }}
    </div>
    @endif

    <!-- Assignments Grid -->
    <div class="row" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 1.5rem;">

        @forelse($assignments as $assignment)
        <div class="task-card">
            <div class="card-badge">{{ $assignment->subject->name }}</div>

            <h3 class="task-title">{{ $assignment->title }}</h3>

            <p class="task-desc">{{ $assignment->description }}</p>

            <div style="margin-top: auto;">
                <div style="display: flex; justify-content: space-between; align-items: center;">

                    @php
                    $isOverdue = \Carbon\Carbon::parse($assignment->due_date)->isPast();
                    $isUpcoming = !\Carbon\Carbon::parse($assignment->due_date)->isPast() && \Carbon\Carbon::parse($assignment->due_date)->diffInDays(now()) <= 3;
                        @endphp

                        <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                        <div class="task-date {{ $isOverdue ? 'overdue' : ($isUpcoming ? 'upcoming' : '') }}">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="16" y1="2" x2="16" y2="6"></line>
                                <line x1="8" y1="2" x2="8" y2="6"></line>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                            <span>{{ \Carbon\Carbon::parse($assignment->due_date)->format('Y-m-d') }}</span>
                        </div>

                        <!-- Creator Badge -->
                        <span style="font-size: 0.75rem; color: var(--text-secondary); background: #f1f5f9; padding: 0.25rem 0.6rem; border-radius: 6px; display: inline-flex; align-items: center; gap: 0.25rem; width: fit-content;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                            بواسطة: {{ $assignment->creator->name ?? 'غير معروف' }}
                            @if($assignment->creator && $assignment->creator->role->value === 'doctor') (دكتور) @endif
                            @if($assignment->creator && $assignment->creator->role->value === 'admin') (إدارة) @endif
                        </span>

                        <!-- Countdown Timer -->
                        @if(!$isOverdue)
                        <div x-data="countdown('{{ \Carbon\Carbon::parse($assignment->due_date)->toIso8601String() }}')"
                            style="font-size: 0.8rem; font-weight: 600; color: #ef4444; display: flex; align-items: center; gap: 0.25rem;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                                <polyline points="12 6 12 12 16 14"></polyline>
                            </svg>
                            متبقي: <span x-text="timeLeft"></span>
                        </div>
                        @else
                        <div style="font-size: 0.8rem; font-weight: 600; color: var(--text-secondary);">انتهى التكليف</div>
                        @endif
                </div>

                <div class="task-actions" style="border: none; margin: 0; padding: 0;">
                    <button class="action-btn" @click='openEditModal(@json($assignment))' title="تعديل">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                    </button>

                    <form action="{{ route('delegate.assignments.destroy', $assignment->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا التكليف؟');" style="display: inline;">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="action-btn delete" title="حذف">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    @empty
    <div class="col-12" style="grid-column: 1 / -1;">
        <div class="empty-state">
            <style>
                /* Only apply text-center safely */
                .empty-state button {
                    display: inline-flex;
                }
            </style>
            <div style="color: #cbd5e1; margin-bottom: 1rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                </svg>
            </div>
            <h3 style="font-size: 1.25rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">لا توجد تكاليف حالياً</h3>
            <p style="color: var(--text-secondary); max-width: 400px; margin: 0 auto; margin-bottom: 1.5rem;">
                قائمة التكاليف فارغة. قم بإضافة تكاليف جديدة للمواد الدراسية.
            </p>
            <button @click="openCreateModal()" class="btn btn-primary" style="display: inline-flex; align-items: center; gap: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                إضافة تكليف جديد
            </button>
        </div>
    </div>
    @endforelse

</div>

@if($assignments->hasPages())
<div class="mt-4">
    {{ $assignments->links() }}
</div>
@endif

<!-- Alpine Modal -->
<div x-show="showModal" class="modal-overlay" style="display: none;" x-transition.opacity>
    <div class="modal-container" @click.away="showModal = false" x-transition.scale>
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
            <h3 class="font-weight-bold" style="font-size: 1.5rem; margin: 0;" x-text="modalTitle"></h3>
            <button type="button" @click="showModal = false" style="background: none; border: none; cursor: pointer; color: var(--text-secondary);">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>

        <form :action="formAction" method="POST">
            @csrf
            <input type="hidden" name="_method" :value="formMethod">

            <div class="row g-3" style="text-align: right;">
                <div class="col-md-12 mb-3">
                    <label class="form-label">المادة الدراسية</label>
                    <select name="subject_id" x-model="formData.subject_id" class="form-control" required style="height: 48px;">
                        <option value="" disabled>اختر المادة...</option>
                        @foreach($subjects as $subject)
                        <option value="{{ $subject->id }}">{{ $subject->name }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="col-md-12 mb-3">
                    <label class="form-label">آخر موعد للتسليم</label>
                    <input type="date" name="due_date" x-model="formData.due_date" class="form-control" required>
                </div>

                <div class="col-12 mb-3">
                    <label class="form-label">عنوان التكليف</label>
                    <input type="text" name="title" x-model="formData.title" class="form-control" required placeholder="مثال: الواجب الأول">
                </div>

                <div class="col-12 mb-3">
                    <label class="form-label">تفاصيل التكليف</label>
                    <textarea name="description" x-model="formData.description" class="form-control" rows="5" required placeholder="اكتب وصفاً دقيقاً للمطلوب..."></textarea>
                </div>
            </div>

            <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 2rem;">
                <button type="button" class="btn btn-secondary" @click="showModal = false">إلغاء</button>
                <button type="submit" class="btn btn-primary" style="min-width: 120px;">حفظ</button>
            </div>
        </form>
    </div>
</div>

</div>

<script>
    function assignmentManager() {
        return {
            showModal: false,
            modalTitle: 'إضافة تكليف جديد',
            formAction: "{{ route('delegate.assignments.store') }}",
            formMethod: 'POST',
            formData: {
                subject_id: '',
                due_date: '',
                title: '',
                description: ''
            },
            openCreateModal() {
                this.modalTitle = 'إضافة تكليف جديد';
                this.formAction = "{{ route('delegate.assignments.store') }}";
                this.formMethod = 'POST';
                this.formData = {
                    subject_id: '',
                    due_date: '',
                    title: '',
                    description: ''
                };
                this.showModal = true;
            },
            openEditModal(assignment) {
                this.modalTitle = 'تعديل التكليف';
                this.formAction = `/delegate/assignments/${assignment.id}`;
                this.formMethod = 'PUT';
                // Format Date for Input
                let dateVal = assignment.due_date ? new Date(assignment.due_date).toISOString().split('T')[0] : '';

                this.formData = {
                    subject_id: assignment.subject_id,
                    due_date: dateVal,
                    title: assignment.title,
                    description: assignment.description
                };
                this.showModal = true;
            }
        }
    }

    function countdown(endDate) {
        return {
            timeLeft: '',
            timer: null,
            init() {
                const end = new Date(endDate).getTime();
                this.update(end);
                this.timer = setInterval(() => {
                    this.update(end);
                }, 60000); // 1 minute
            },
            update(end) {
                const now = new Date().getTime();
                const distance = end - now;

                if (distance < 0) {
                    this.timeLeft = "انتهى";
                    clearInterval(this.timer);
                    return;
                }

                const days = Math.floor(distance / (1000 * 60 * 60 * 24));
                const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));

                if (days > 0) {
                    this.timeLeft = `${days} أيام و ${hours} ساعة`;
                } else if (hours > 0) {
                    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                    this.timeLeft = `${hours} ساعة و ${minutes} دقيقة`;
                } else {
                    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                    this.timeLeft = `${minutes} دقيقة`;
                }
            }
        }
    }
</script>

<!-- Add push styles if 'overdue' or 'upcoming' exists -->
@push('styles')
<style>
    .task-date.overdue {
        background: #fee2e2;
        color: #ef4444;
    }

    .task-date.upcoming {
        background: #fffbeb;
        color: #d97706;
    }
</style>
@endpush

@endsection