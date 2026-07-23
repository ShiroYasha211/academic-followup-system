@extends('layouts.student')
@section('title', 'نتيجة التقييم التجريبي: ' . $evaluation->checklist->title)
@section('content')
<style>
    .result-header {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        margin-bottom: 2rem;
        text-align: center;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .main-score {
        font-size: 3.5rem;
        font-weight: 800;
        margin: 1rem 0;
        line-height: 1;
    }

    .grade-badge {
        display: inline-block;
        padding: 0.5rem 1.5rem;
        border-radius: 999px;
        color: white;
        font-weight: 800;
        font-size: 1.1rem;
        margin-top: 0.5rem;
    }

    .result-meta {
        display: flex;
        justify-content: center;
        gap: 2rem;
        margin-top: 2rem;
        color: #64748b;
        font-size: 0.95rem;
        flex-wrap: wrap;
    }

    .meta-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 2rem;
    }

    .chart-container {
        position: relative;
        height: 350px;
        width: 100%;
        display: flex;
        justify-content: center;
    }

    .btn-action {
        background: #f1f5f9;
        color: #334155;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: background 0.2s;
    }

    .btn-action:hover {
        background: #e2e8f0;
    }

    .btn-primary {
        background: #4f46e5;
        color: white;
    }

    .btn-primary:hover {
        background: #4338ca;
        color: white;
    }

    .header-actions {
        display: flex;
        justify-content: center;
        gap: 1rem;
        margin-top: 2rem;
        flex-wrap: wrap;
    }

    /* Checklist break down */
    .checklist-breakdown {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .breakdown-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 1.25rem;
        border-radius: 12px;
        border: 1px solid #e2e8f0;
        background: #fafbfe;
    }

    .item-desc {
        font-weight: 600;
        color: var(--text-primary);
    }

    .item-score {
        font-weight: 800;
    }

    .score-done {
        color: #059669;
    }

    .score-partial {
        color: #d97706;
    }

    .score-not_done {
        color: #dc2626;
    }
</style>

<div class="result-header">
    <h1 style="font-size: 1.4rem; font-weight: 700; color: #475569; margin:0;">نموذج: {{ $evaluation->checklist->title }}</h1>

    <div class="main-score" style="color: {{ $evaluation->grade_color }}">
        {{ number_format($evaluation->percentage, 0) }}<span style="font-size: 2rem;">%</span>
    </div>

    <div class="grade-badge" style="background: {{ $evaluation->grade_color }}">
        {{ $evaluation->grade_label }}
    </div>

    <div class="result-meta">
        <div class="meta-item">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            الوقت المستغرق: {{ $evaluation->formatted_time }} دقيقة
        </div>
        <div class="meta-item">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
            تاريخ المحاولة: {{ $evaluation->created_at->format('Y-m-d') }}
        </div>
    </div>

    <div class="header-actions">
        <a href="{{ route('student.clinical.mock.index') }}" class="btn-action">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="19" y1="12" x2="5" y2="12"></line>
                <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
            العودة للنماذج
        </a>
        <a href="{{ route('student.clinical.mock.take', $evaluation->checklist_id) }}" class="btn-action btn-primary">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="1 4 1 10 7 10"></polyline>
                <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"></path>
            </svg>
            إعادة المحاولة
        </a>
    </div>
</div>

@if(count($radarLabels) > 0)
<div class="card-section">
    <h3 style="font-weight: 800; margin-bottom: 1rem; text-align: center; color: var(--text-primary);">تحليل المهارات في هذه المحاولة (Radar)</h3>
    <div class="chart-container">
        <canvas id="skillsRadarChart"></canvas>
    </div>
</div>
@endif

<div class="card-section">
    <h3 style="font-weight: 800; margin-bottom: 1.5rem; color: var(--text-primary);">تفصيل الدرجات حسب البنود</h3>
    <div class="checklist-breakdown">
        @php
            $mainItems = $evaluation->checklist->items->whereNull('parent_id');
            $scoresMap = $evaluation->scores->keyBy('checklist_item_id');
        @endphp

        @foreach($mainItems as $mainItem)
            @php
                $subItems = $evaluation->checklist->items->where('parent_id', $mainItem->id);
                $hasSubitems = $subItems->count() > 0;
                $mainScore = $scoresMap->get($mainItem->id);
            @endphp
            
            <div class="breakdown-item" style="flex-direction: column; align-items: stretch; gap: 0.5rem; {{ $hasSubitems ? 'background: #f8fafc; border: 1.5px solid #cbd5e1; border-right: 4px solid var(--primary-color); padding: 1rem;' : '' }}">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div class="item-desc" style="{{ $hasSubitems ? 'font-size: 1.05rem; font-weight: 800;' : '' }}">{{ $mainItem->description }}</div>
                    
                    @if($hasSubitems)
                        <div class="item-score" style="color: var(--primary-color);">العلامة القصوى: {{ $mainItem->marks }}</div>
                    @else
                        <div class="item-score score-{{ $mainScore->score_label ?? 'not_done' }}">
                            @if(($mainScore->score_label ?? '') == 'done')
                                أُنجِز بالكامل ({{ $mainScore->marks_obtained ?? 0 }}/{{ $mainItem->marks }})
                            @elseif(($mainScore->score_label ?? '') == 'partial')
                                أُنجِز جزئياً ({{ $mainScore->marks_obtained ?? 0 }}/{{ $mainItem->marks }})
                            @else
                                لم يُنجَز (0/{{ $mainItem->marks }})
                            @endif
                        </div>
                    @endif
                </div>

                @if(!$hasSubitems && $mainScore && $mainScore->notes)
                <div style="background: #f1f5f9; padding: 0.75rem 1rem; border-radius: 8px; font-size: 0.85rem; color: #475569; display: flex; gap: 0.5rem; align-items: flex-start; margin-top: 0.5rem;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink: 0; margin-top: 0.1rem; color: #64748b;">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2-2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                    <div>
                        <strong>ملاحظاتك الذاتية:</strong>
                        <span style="font-style: italic;">"{{ $mainScore->notes }}"</span>
                    </div>
                </div>
                @endif
            </div>

            @if($hasSubitems)
                <div style="display: flex; flex-direction: column; gap: 0.5rem; padding-right: 2.5rem; border-right: 2px dashed #e2e8f0; margin-right: 1.5rem; margin-bottom: 1rem;">
                    @foreach($subItems as $subItem)
                        @php $subScore = $scoresMap->get($subItem->id); @endphp
                        <div class="breakdown-item" style="background: white; border: 1px solid #e2e8f0; flex-direction: column; align-items: stretch; gap: 0.5rem; padding: 0.75rem 1rem;">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <div class="item-desc" style="font-size: 0.9rem; color: #475569;">
                                    <span style="color:#94a3b8; font-weight:bold; margin-left: 0.25rem;">↳</span>
                                    {{ $subItem->description }}
                                </div>
                                <div class="item-score score-{{ $subScore->score_label ?? 'not_done' }}" style="font-size: 0.85rem;">
                                    @if(($subScore->score_label ?? '') == 'done')
                                    كامل ({{ $subScore->marks_obtained ?? 0 }}/{{ $subItem->marks }})
                                    @elseif(($subScore->score_label ?? '') == 'partial')
                                    جزئي ({{ $subScore->marks_obtained ?? 0 }}/{{ $subItem->marks }})
                                    @else
                                    لا (0/{{ $subItem->marks }})
                                    @endif
                                </div>
                            </div>
                            
                            @if($subScore && $subScore->notes)
                            <div style="background: #f1f5f9; padding: 0.5rem 0.75rem; border-radius: 6px; font-size: 0.8rem; color: #475569; display: flex; gap: 0.5rem; align-items: flex-start; margin-top: 0.25rem;">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink: 0; margin-top: 0.1rem; color: #64748b;">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2-2h14a2 2 0 0 0 2-2v-7"></path>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                </svg>
                                <div>
                                    <strong>ملاحظة:</strong>
                                    <span style="font-style: italic;">"{{ $subScore->notes }}"</span>
                                </div>
                            </div>
                            @endif
                        </div>
                    @endforeach
                </div>
            @endif
        @endforeach
    </div>
</div>

@if(count($radarLabels) > 0)
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        const ctx = document.getElementById('skillsRadarChart').getContext('2d');
        const data = {
            labels: @json($radarLabels),
            datasets: [{
                label: 'مستوى الأداء (%)',
                data: @json($radarData),
                fill: true,
                backgroundColor: 'rgba(5b, 130, 246, 0.2)',
                borderColor: 'rgba(59, 130, 246, 1)',
                pointBackgroundColor: 'rgba(59, 130, 246, 1)',
                pointBorderColor: '#fff',
                pointHoverBackgroundColor: '#fff',
                pointHoverBorderColor: 'rgba(59, 130, 246, 1)',
                borderWidth: 2,
            }]
        };

        const config = {
            type: 'radar',
            data: data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    r: {
                        angleLines: {
                            color: 'rgba(0,0,0,0.1)'
                        },
                        grid: {
                            color: 'rgba(0,0,0,0.1)'
                        },
                        pointLabels: {
                            font: {
                                family: "'Cairo', sans-serif",
                                size: 13,
                                weight: 'bold'
                            },
                            color: '#475569'
                        },
                        ticks: {
                            min: 0,
                            max: 100,
                            stepSize: 20,
                            display: false
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return ' ' + context.parsed.r + '%';
                            }
                        },
                        titleFont: {
                            family: "'Cairo', sans-serif"
                        },
                        bodyFont: {
                            family: "'Cairo', sans-serif",
                            size: 14
                        }
                    }
                }
            }
        };

        new Chart(ctx, config);
    });
</script>
@endif
@endsection