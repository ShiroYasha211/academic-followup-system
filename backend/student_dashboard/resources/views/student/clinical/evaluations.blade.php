@extends('layouts.student')
@section('title', 'تقييماتي السريرية')
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

    .stats-row {
        display: flex;
        gap: 1rem;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
    }

    .stat-card {
        flex: 1;
        min-width: 140px;
        background: white;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        padding: 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .stat-icon {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-icon.blue {
        background: #dbeafe;
        color: #3b82f6;
    }

    .stat-icon.green {
        background: #d1fae5;
        color: #059669;
    }

    .stat-icon.purple {
        background: #ede9fe;
        color: #7c3aed;
    }

    .stat-info .stat-number {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        line-height: 1;
    }

    .stat-info .stat-label {
        font-size: 0.8rem;
        color: var(--text-secondary);
        margin-top: 0.15rem;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .eval-card {
        background: #fafbfe;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 1.25rem;
        margin-bottom: 1rem;
        transition: all 0.2s;
    }

    .eval-card:hover {
        border-color: #c7d2fe;
        box-shadow: 0 2px 12px rgba(79, 70, 229, 0.06);
    }

    .eval-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        margin-bottom: 0.75rem;
    }

    .eval-title {
        font-weight: 700;
        font-size: 1rem;
        color: var(--text-primary);
    }

    .grade-badge {
        padding: 0.3rem 0.7rem;
        border-radius: 8px;
        font-weight: 700;
        font-size: 0.85rem;
        color: white;
    }

    .eval-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        font-size: 0.82rem;
        color: var(--text-secondary);
    }

    .pct-bar {
        height: 8px;
        border-radius: 4px;
        background: #e2e8f0;
        overflow: hidden;
        margin-top: 0.75rem;
    }

    .pct-bar .fill {
        height: 100%;
        border-radius: 4px;
        transition: width 0.4s;
    }

    .view-link {
        color: var(--primary-color);
        font-weight: 600;
        font-size: 0.85rem;
        text-decoration: none;
        margin-top: 0.5rem;
        display: inline-block;
    }

    .view-link:hover {
        text-decoration: underline;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>تقييماتي السريرية 📊</h1>
        <p>نتائج التقييمات العملية وملاحظات الدكاترة</p>
    </div>
    <div class="left-side"><a href="{{ route('student.clinical.index') }}" class="btn-back"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg> القسم السريري</a></div>
</div>

<div class="stats-row">
    <div class="stat-card">
        <div class="stat-icon blue"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 11l3 3L22 4"></path>
                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
            </svg></div>
        <div class="stat-info">
            <div class="stat-number">{{ $totalEvals }}</div>
            <div class="stat-label">عدد التقييمات</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon green"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
            </svg></div>
        <div class="stat-info">
            <div class="stat-number">{{ number_format($avgPercentage, 0) }}%</div>
            <div class="stat-label">متوسط النتيجة</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon purple"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
            </svg></div>
        <div class="stat-info">
            <div class="stat-number">{{ $excellentCount }}</div>
            <div class="stat-label">تقدير ممتاز</div>
        </div>
    </div>
</div>

@if(count($radarLabels) > 0)
<div class="card-section" style="margin-bottom: 1.75rem;">
    <h3 style="font-weight: 700; margin-bottom: 1rem; text-align: center; color: var(--text-primary);">تحليل المهارات السريرية (OSCE Radar)</h3>
    <div style="position: relative; height: 350px; width: 100%; display: flex; justify-content: center;">
        <canvas id="skillsRadarChart"></canvas>
    </div>
</div>
@endif

<div class="card-section">
    @forelse($evaluations as $ev)
    <div class="eval-card">
        <div class="eval-header">
            <div>
                <div class="eval-title">{{ $ev->checklist->title ?? '-' }}</div>
                <div class="eval-meta" style="margin-top: 0.35rem;">
                    <span>👨‍⚕️ د. {{ $ev->doctor->name ?? '-' }}</span>
                    <span>⏱ {{ $ev->formatted_time }}</span>
                    <span>📅 {{ $ev->created_at->format('Y-m-d') }}</span>
                </div>
            </div>
            <span class="grade-badge" style="background: {{ $ev->grade_color }};">{{ $ev->grade_label }} — {{ $ev->percentage }}%</span>
        </div>
        <div class="pct-bar">
            <div class="fill" style="width:{{ $ev->percentage }}%;background:{{ $ev->grade_color }};"></div>
        </div>
        @if($ev->doctor_feedback)<p style="font-size:0.82rem; color:#475569; margin:0.75rem 0 0 0; background:#f1f5f9; padding:0.5rem 0.75rem; border-radius:8px;"><strong>ملاحظة:</strong> {{ Str::limit($ev->doctor_feedback, 100) }}</p>@endif
        <a href="{{ route('student.clinical.evaluations.show', $ev->id) }}" class="view-link">عرض التفاصيل ←</a>
    </div>
    @empty
    <div style="text-align:center;color:var(--text-secondary);padding:3rem;">
        <p>لا توجد تقييمات بعد. سيقوم الدكتور بتقييمك عند التدريب السريري.</p>
    </div>
    @endforelse
</div>

@if(count($radarLabels) > 0)
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        const ctx = document.getElementById('skillsRadarChart').getContext('2d');
        const data = {
            labels: @json($radarLabels),
            datasets: [{
                label: 'مستوى إتقان المهارة (%)',
                data: @json($radarData),
                fill: true,
                backgroundColor: 'rgba(79, 70, 229, 0.2)',
                borderColor: 'rgba(79, 70, 229, 1)',
                pointBackgroundColor: 'rgba(79, 70, 229, 1)',
                pointBorderColor: '#fff',
                pointHoverBackgroundColor: '#fff',
                pointHoverBorderColor: 'rgba(79, 70, 229, 1)',
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
                            display: false // Hide numbers on web axes for cleaner look
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false // Hide legend to save space
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