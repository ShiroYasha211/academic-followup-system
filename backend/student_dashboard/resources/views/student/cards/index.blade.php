@php
    $layout = 'layouts.' . (auth()->user()->role->value === 'doctor' ? 'doctor' : (auth()->user()->role->value === 'delegate' ? 'delegate' : 'student'));
@endphp

@extends($layout)

@section('title', 'توليد الكروت')

@section('content')
<style>
    /* Premium Theming Variables */
    :root {
        --royal-gradient: linear-gradient(135deg, #4338ca 0%, #6366f1 100%);
        --soft-bg: #f8fafc;
        --card-gap: 1.5rem;
    }

    /* Page container spacing */
    .page-content-wrapper {
        padding-top: 1rem;
        padding-bottom: 4rem;
        max-width: 1600px;
        margin: 0 auto;
    }

    /* Stat Cards */
    .stat-card {
        background: white;
        border-radius: var(--radius-md);
        padding: 1.75rem;
        border: 1px solid var(--border-color);
        box-shadow: var(--shadow-sm);
        display: flex;
        align-items: center;
        gap: 1.5rem;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        height: 100%;
    }

    .stat-card:hover {
        transform: translateY(-4px);
        box-shadow: var(--shadow-md);
    }

    .stat-icon {
        width: 56px;
        height: 56px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.6rem;
        flex-shrink: 0;
    }

    /* Refined Form Styles */
    .card-premium {
        background: white;
        border-radius: var(--radius-lg);
        border: 1px solid var(--border-color);
        box-shadow: var(--shadow-md);
        overflow: hidden;
        height: 100%;
        display: flex;
        flex-direction: column;
        margin-bottom: 1.5rem;
    }

    .card-premium-header {
        background: var(--soft-bg);
        padding: 1.5rem;
        border-bottom: 1px solid var(--border-color);
    }

    .form-label-bold {
        font-weight: 700;
        color: var(--text-primary);
        font-size: 1rem;
        margin-bottom: 0.75rem;
        display: block;
    }

    /* Enhanced RTL Input Group - Fixed Alignment */
    .input-group-premium {
        position: relative;
        display: flex;
        align-items: center;
        direction: ltr !important; /* Force LTR for number inputs to keep unit on left */
    }

    .input-group-premium .form-control {
        border-radius: 12px !important;
        padding: 1rem 1.25rem;
        padding-left: 65px; /* Space for the unit */
        background: #fcfdfe;
        border: 1.5px solid #e2e8f0;
        font-weight: 700;
        font-size: 1.2rem;
        text-align: left;
        width: 100%;
    }

    .input-group-premium .form-control:focus {
        border-color: var(--primary-color);
        background: white;
        box-shadow: 0 0 0 4px rgba(67, 56, 202, 0.1);
    }

    .input-addon-unit {
        position: absolute;
        left: 12px;
        z-index: 5;
        font-weight: 800;
        color: var(--primary-color);
        pointer-events: none;
        font-size: 0.9rem;
        background: rgba(67, 56, 202, 0.08);
        padding: 6px 12px;
        border-radius: 8px;
    }

    /* Calculator Area */
    .calc-box {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 1.75rem;
        margin-top: 2rem;
    }

    .total-amount-display {
        font-size: 2.25rem;
        font-weight: 900;
        color: var(--primary-color);
        display: block;
        margin-top: 5px;
        letter-spacing: -1px;
    }

    /* Table Enhancements */
    .table-premium thead th {
        background: var(--soft-bg);
        padding: 1.25rem 1.5rem;
        font-weight: 800;
        color: var(--secondary-color);
        border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
        font-size: 0.95rem;
    }

    .table-premium tbody td {
        padding: 1.5rem;
        vertical-align: middle;
    }

    .card-code-display {
        background: #f1f5f9;
        border: 1px dashed #cbd5e1;
        padding: 0.75rem 1.25rem;
        border-radius: 12px;
        font-family: 'DM Mono', monospace;
        color: var(--primary-color);
        font-weight: 800;
        letter-spacing: 1.5px;
        font-size: 1.1rem;
        display: inline-block;
    }

    .btn-copy-mini {
        width: 42px;
        height: 42px;
        padding: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 12px;
        background: white;
        border: 1.5px solid #e2e8f0;
        color: var(--secondary-color);
        transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    }

    .btn-copy-mini:hover {
        background: var(--primary-color);
        color: white;
        border-color: var(--primary-color);
        transform: scale(1.15) rotate(5deg);
    }

    .btn-generate {
        background: var(--royal-gradient);
        border: none;
        color: white;
        font-weight: 800;
        padding: 1.25rem;
        border-radius: 16px;
        transition: all 0.3s ease;
        box-shadow: 0 8px 20px rgba(67, 56, 202, 0.25);
        font-size: 1.1rem;
        text-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .btn-generate:hover {
        transform: translateY(-3px);
        box-shadow: 0 12px 25px rgba(67, 56, 202, 0.35);
    }

    /* Section headers */
    .section-title-wrapper {
        margin-bottom: 2.5rem;
    }
    
    .section-icon-box {
        width: 48px;
        height: 48px;
        background: var(--royal-gradient);
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-size: 1.25rem;
        margin-bottom: 1rem;
    }
</style>

<div class="page-content-wrapper">
    <div class="section-title-wrapper">
        <div class="section-icon-box">
            <i class="fa-solid fa-wand-sparkles"></i>
        </div>
        <h2 class="fw-bold mb-2">توليد كروت الشحن الذكية</h2>
        <p class="text-secondary lead fs-6">نظام متطور لإنتاج كروت الشحن المخصصة مع ربط مالي مباشر بحسابك.</p>
    </div>

    <!-- Stats Bar -->
    <div class="row g-4 mb-5">
        <div class="col-md-4">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(67, 56, 202, 0.1); color: #4338ca;">
                    <i class="fa-solid fa-wallet"></i>
                </div>
                <div>
                    <span class="text-secondary small d-block mb-1">رصيدك المتاح حالياً</span>
                    <h4 class="fw-bold mb-0 text-dark">{{ number_format(Auth::user()->balance) }} <small class="fw-normal small">ريال</small></h4>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                    <i class="fa-solid fa-ticket"></i>
                </div>
                <div>
                    <span class="text-secondary small d-block mb-1">إجمالي الكروت التي أنتجتها</span>
                    <h4 class="fw-bold mb-0 text-dark">{{ $cards->total() }} <small class="fw-normal small">كرت</small></h4>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                    <i class="fa-solid fa-clock-rotate-left"></i>
                </div>
                <div>
                    <span class="text-secondary small d-block mb-1">آخر نشاط توليد</span>
                    <h4 class="fw-bold mb-0 text-dark">
                        @if($cards->first())
                            {{ $cards->first()->created_at->diffForHumans() }}
                        @else
                            --
                        @endif
                    </h4>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-5">
        <!-- Generation Control -->
        <div class="col-xl-4">
            <div class="card-premium">
                <div class="card-premium-header">
                    <h5 class="fw-bold mb-0"><i class="fa-solid fa-sliders me-2"></i> إعدادات الإنتاج</h5>
                </div>
                <div class="p-4 flex-grow-1">
                    <form action="{{ route(auth()->user()->role->value . '.cards.generate.store') }}" method="POST" id="cardGenForm">
                        @csrf
                        
                        <div class="mb-4">
                            <label class="form-label-bold">فئة الكرت (القيمة بالريال)</label>
                            <div class="input-group-premium">
                                <span class="input-addon-unit">ريال</span>
                                <input type="number" name="amount" id="amount" class="form-control" placeholder="0" min="1" required>
                            </div>
                        </div>

                        <div class="mb-4">
                            <label class="form-label-bold">عدد الكروت المطلوب إنتاجها</label>
                            <div class="input-group-premium">
                                <span class="input-addon-unit">كرت</span>
                                <input type="number" name="count" id="count" class="form-control" placeholder="0" min="1" max="100" required>
                            </div>
                            <div class="form-text small mt-3"><i class="fa-solid fa-circle-info me-2 text-primary"></i> الحد الأقصى للجلسة الواحدة هو 100 كرت.</div>
                        </div>

                        <div class="calc-box">
                            <div class="d-flex justify-content-between align-items-center">
                                <span class="text-secondary fw-bold small text-uppercase">التكلفة النهائية</span>
                                <div class="text-end">
                                    <span id="total_cost" class="total-amount-display">0 ريال</span>
                                </div>
                            </div>
                        </div>

                        <button type="submit" class="btn btn-generate w-100 mt-5">
                            تأكيد وتوليد الكروت <i class="fa-solid fa-bolt-lightning ms-2"></i>
                        </button>
                        
                        <div class="text-center mt-4 text-secondary" style="font-size: 0.85rem; border-top: 1px solid #f1f5f9; pt-3;">
                            <i class="fa-solid fa-shield-halved me-1 text-success"></i> معاملة آمنة تماماً
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- History View -->
        <div class="col-xl-8">
            <div class="card-premium">
                <div class="card-premium-header d-flex justify-content-between align-items-center">
                    <h5 class="fw-bold mb-0 text-dark">
                        <i class="fa-solid fa-clock-rotate-left me-2 text-primary"></i> 
                        سجل العمليات الأخير
                    </h5>
                    <div class="d-flex gap-3">
                        <div class="text-center">
                            <div class="small text-secondary mb-1">جاهز</div>
                            <span class="badge" style="background: rgba(14, 165, 233, 0.1); color: #0ea5e9; padding: 0.5rem 1rem; border-radius: 8px;">{{ $cards->where('is_used', false)->count() }}</span>
                        </div>
                        <div class="text-center">
                            <div class="small text-secondary mb-1">مستخدم</div>
                            <span class="badge" style="background: rgba(16, 185, 129, 0.1); color: #10b981; padding: 0.5rem 1rem; border-radius: 8px;">{{ $cards->where('is_used', true)->count() }}</span>
                        </div>
                    </div>
                </div>
                
                <div class="table-responsive flex-grow-1">
                    <table class="table table-premium align-middle mb-0">
                        <thead>
                            <tr>
                                <th class="text-center">كود الكرت</th>
                                <th>القيمة</th>
                                <th>الحالة</th>
                                <th class="text-center">نسخ</th>
                                <th class="text-end">تاريخ الإنتاج</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($cards as $card)
                            <tr class="border-bottom">
                                <td class="text-center">
                                    <span class="card-code-display">{{ $card->code }}</span>
                                </td>
                                <td>
                                    <div class="fw-bold text-dark fs-5">{{ number_format($card->amount) }} <span class="fw-normal text-secondary small">ريال</span></div>
                                </td>
                                <td>
                                    @if($card->is_used)
                                        <div class="d-flex align-items-center text-danger small">
                                            <i class="fa-solid fa-circle-check me-2"></i> تم الشحن
                                        </div>
                                    @else
                                        <div class="d-flex align-items-center text-success small">
                                            <i class="fa-solid fa-circle-dot me-2 animation-pulse"></i> متاح للتوزيع
                                        </div>
                                    @endif
                                </td>
                                <td class="text-center">
                                    <button class="btn-copy-mini btn mx-auto shadow-none" onclick="handleCopy(this, '{{ $card->code }}')" title="نسخ الكود">
                                        <i class="fa-regular fa-copy"></i>
                                    </button>
                                </td>
                                <td class="text-end">
                                    <div class="text-dark fw-bold small">{{ $card->created_at->format('Y/m/d') }}</div>
                                    <div class="text-secondary" style="font-size: 0.75rem;">{{ $card->created_at->format('h:i A') }}</div>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="5" class="py-5 text-center text-secondary">
                                    <div class="py-5">
                                        <i class="fa-solid fa-receipt d-block mb-3" style="font-size: 4rem; opacity: 0.1;"></i>
                                        <h5 class="fw-bold text-dark">لا توجد كروت مولدة حتى الآن</h5>
                                        <p class="mb-0">سجل عملياتك سيظهر هنا فور البدء في الإنتاج.</p>
                                    </div>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                @if($cards->hasPages())
                    <div class="p-4 border-top bg-light">
                        {{ $cards->links() }}
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script>
    const amountInput = document.getElementById('amount');
    const countInput = document.getElementById('count');
    const totalCostDisplay = document.getElementById('total_cost');
    const costProgress = document.getElementById('cost_progress');
    const balanceWarning = document.getElementById('balance_warning');
    const userBalance = {{ Auth::user()->balance }};

    function updateCalc() {
        const amount = parseFloat(amountInput.value) || 0;
        const count = parseInt(countInput.value) || 0;
        const total = amount * count;

        // Update Text
        totalCostDisplay.innerText = total.toLocaleString() + ' ريال';

        // Feedback Logic
        if (total > userBalance) {
            totalCostDisplay.style.color = '#e11d48';
        } else if (total > 0) {
            totalCostDisplay.style.color = '#4338ca';
        } else {
            totalCostDisplay.style.color = '#1e293b';
        }
    }

    amountInput.addEventListener('input', updateCalc);
    countInput.addEventListener('input', updateCalc);

    function handleCopy(btn, code) {
        navigator.clipboard.writeText(code).then(() => {
            const originalIcon = btn.innerHTML;
            btn.innerHTML = '<i class="fa-solid fa-check"></i>';
            btn.style.backgroundColor = '#22c55e';
            btn.style.color = 'white';
            btn.style.borderColor = '#22c55e';

            setTimeout(() => {
                btn.innerHTML = originalIcon;
                btn.style.backgroundColor = 'white';
                btn.style.color = '#64748b';
                btn.style.borderColor = '#e2e8f0';
            }, 2000);
        });
    }
</script>
@endpush
@endsection
