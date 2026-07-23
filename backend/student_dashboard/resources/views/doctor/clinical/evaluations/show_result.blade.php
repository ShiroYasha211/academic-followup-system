@extends('layouts.doctor')
@section('title', 'تفاصيل التقييم')
@section('content')
<style>
    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.6rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.15rem 0;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        margin: 0;
    }

    .btn-back {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1.1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    .result-summary {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .summary-card {
        background: white;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        padding: 1.25rem;
        text-align: center;
    }

    .summary-card .val {
        font-size: 1.8rem;
        font-weight: 800;
        line-height: 1;
    }

    .summary-card .lbl {
        font-size: 0.82rem;
        color: var(--text-secondary);
        margin-top: 0.25rem;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .score-row {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 0.75rem;
        border-radius: 10px;
        margin-bottom: 0.4rem;
    }

    .score-row:nth-child(even) {
        background: #fafbfe;
    }

    .score-row .num {
        min-width: 28px;
        font-weight: 700;
        color: var(--text-secondary);
        text-align: center;
    }

    .score-row .desc {
        flex: 1;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .score-row .marks {
        min-width: 80px;
        text-align: center;
        font-size: 0.82rem;
    }

    .score-badge {
        padding: 0.2rem 0.5rem;
        border-radius: 5px;
        font-weight: 700;
        font-size: 0.78rem;
    }

    .score-badge.done {
        background: #d1fae5;
        color: #065f46;
    }

    .score-badge.partial {
        background: #fef3c7;
        color: #92400e;
    }

    .score-badge.not_done {
        background: #fee2e2;
        color: #991b1b;
    }

    .feedback-box {
        background: #f8fafc;
        border-radius: 12px;
        padding: 1rem;
        font-size: 0.9rem;
        color: var(--text-primary);
        line-height: 1.6;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>تفاصيل التقييم 📋</h1>
        <p>{{ $evaluation->checklist->title ?? '-' }} — {{ $evaluation->student->name ?? '-' }}</p>
    </div>
    <div class="left-side"><a href="{{ route('doctor.clinical.evaluations.results') }}" class="btn-back"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg> النتائج</a></div>
</div>

<div class="result-summary">
    <div class="summary-card">
        <div class="val" style="color:{{ $evaluation->grade_color }};">{{ $evaluation->percentage }}%</div>
        <div class="lbl">النسبة</div>
    </div>
    <div class="summary-card">
        <div class="val">{{ $evaluation->total_score }}/{{ $evaluation->max_score }}</div>
        <div class="lbl">الدرجة</div>
    </div>
    <div class="summary-card">
        <div class="val" style="color:{{ $evaluation->grade_color }};">{{ $evaluation->grade_label }}</div>
        <div class="lbl">التقدير</div>
    </div>
    <div class="summary-card">
        <div class="val">{{ $evaluation->formatted_time }}</div>
        <div class="lbl">الوقت المستغرق</div>
    </div>
</div>

<div class="card-section">
    <h3 style="font-weight:700; margin-bottom:1rem;">عناصر التقييم</h3>
    @php
        // Organize items into a tree for display
        $mainItems = $evaluation->checklist->items->whereNull('parent_id');
        $scoresMap = $evaluation->scores->keyBy('checklist_item_id');
    @endphp

    @foreach($mainItems as $mainItem)
        @php
            $subItems = $evaluation->checklist->items->where('parent_id', $mainItem->id);
            $hasSubitems = $subItems->count() > 0;
            // If it's a main item with NO children, it should have a score itself
            $mainScore = $scoresMap->get($mainItem->id);
        @endphp
        
        <div class="score-row" style="{{ $hasSubitems ? 'background: #f8fafc; border: 1.5px solid #cbd5e1; border-right: 4px solid var(--primary-color); padding: 1rem;' : '' }}">
            <span class="num">{{ $loop->iteration }}</span>
            <span class="desc" style="{{ $hasSubitems ? 'font-size: 1.05rem; font-weight: 800;' : '' }}">{{ $mainItem->description }}</span>
            
            @if($hasSubitems)
                <span class="marks" style="font-weight: 800; color: var(--primary-color);">{{ $mainItem->marks }} د</span>
            @else
                <span class="marks">{{ $mainScore->marks_obtained ?? 0 }}/{{ $mainItem->marks }}</span>
                <span class="score-badge {{ $mainScore->score ?? 'not_done' }}">{{ $mainScore ? $mainScore->score_label : 'لم يقيّم' }}</span>
            @endif
        </div>

        @if($hasSubitems)
            <div style="padding-right: 2.5rem; border-right: 2px dashed #e2e8f0; margin-right: 1.5rem; margin-bottom: 1rem;">
                @foreach($subItems as $subItem)
                    @php $subScore = $scoresMap->get($subItem->id); @endphp
                    <div class="score-row" style="background: white; border: 1px solid #e2e8f0; margin-top: 0.25rem;">
                        <span style="color:#94a3b8; font-weight:bold;">↳</span>
                        <span class="desc" style="font-size: 0.88rem; color: #475569;">{{ $subItem->description }}</span>
                        <span class="marks">{{ $subScore->marks_obtained ?? 0 }}/{{ $subItem->marks }}</span>
                        <span class="score-badge {{ $subScore->score ?? 'not_done' }}">{{ $subScore ? $subScore->score_label : 'لم يقيّم' }}</span>
                    </div>
                @endforeach
            </div>
        @endif
    @endforeach
</div>

@if($evaluation->doctor_feedback)
<div class="card-section">
    <h3 style="font-weight:700; margin-bottom:0.75rem;">ملاحظات الدكتور</h3>
    <div class="feedback-box">{{ $evaluation->doctor_feedback }}</div>
</div>
@endif
@endsection