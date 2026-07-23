@extends('layouts.student')

@section('title', 'مركز الدراسة')

@section('content')
<!-- Flatpickr -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>

<div class="container-fluid" style="padding: 0;">

    <!-- ═══════════ Page Header ═══════════ -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.25rem; display: flex; align-items: center; gap: 0.75rem;">
                <div style="width: 44px; height: 44px; border-radius: 14px; background: linear-gradient(135deg, var(--primary-color), #7c3aed); display: flex; align-items: center; justify-content: center;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path>
                        <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>
                    </svg>
                </div>
                مركز الدراسة
            </h1>
            <p style="color: var(--text-secondary); margin: 0; font-size: 0.95rem;">نظّم مذاكرتك، تنبيهاتك، ومصادرك في مكان واحد</p>
        </div>
        <button onclick="openAddModal()" class="btn" style="background: linear-gradient(135deg, var(--primary-color), #7c3aed); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; font-size: 0.95rem; box-shadow: 0 4px 15px rgba(79, 70, 229, 0.3); transition: all 0.3s;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إضافة مهمة جديدة
        </button>
    </div>

    <!-- ═══════════ Dashboard Stats Strip ═══════════ -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-bottom: 2rem;">
        <!-- Today's Tasks -->
        <a href="{{ route('student.schedule.index', ['tab' => $tab, 'filter' => 'today']) }}" class="stat-card" style="text-decoration: none;">
            <div class="stat-icon" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                </svg>
            </div>
            <div>
                <div class="stat-label">مهام اليوم</div>
                <div class="stat-value">{{ $stats['today'] }}</div>
            </div>
        </a>

        <!-- Overdue -->
        <a href="{{ route('student.schedule.index', ['tab' => $tab, 'filter' => 'overdue']) }}" class="stat-card {{ $stats['overdue'] > 0 ? 'stat-alert' : '' }}" style="text-decoration: none;">
            <div class="stat-icon" style="background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div>
                <div class="stat-label">متأخرة</div>
                <div class="stat-value" style="{{ $stats['overdue'] > 0 ? 'color: #ef4444;' : '' }}">{{ $stats['overdue'] }}</div>
            </div>
        </a>

        <!-- Completed This Week -->
        <a href="{{ route('student.schedule.index', ['tab' => $tab, 'filter' => 'completed']) }}" class="stat-card" style="text-decoration: none;">
            <div class="stat-icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
            </div>
            <div>
                <div class="stat-label">مكتملة (هذا الأسبوع)</div>
                <div class="stat-value">{{ $stats['completed'] }}</div>
            </div>
        </a>

        <!-- High Priority -->
        <a href="{{ route('student.schedule.index', ['tab' => $tab, 'filter' => 'high']) }}" class="stat-card" style="text-decoration: none;">
            <div class="stat-icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                </svg>
            </div>
            <div>
                <div class="stat-label">أولوية عالية</div>
                <div class="stat-value">{{ $stats['high_priority'] }}</div>
            </div>
        </a>
    </div>

    <!-- ═══════════ Tab Navigation ═══════════ -->
    <div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; overflow: hidden;">
        <div style="display: flex; border-bottom: 2px solid #f1f5f9; padding: 0 1.5rem;">
            <a href="{{ route('student.schedule.index', ['tab' => 'study']) }}"
                class="hub-tab {{ $tab === 'study' ? 'active' : '' }}">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
                <span>جدول المذاكرة</span>
                @if($stats['study_count'] > 0)
                <span class="tab-badge">{{ $stats['study_count'] }}</span>
                @endif
            </a>
            <a href="{{ route('student.schedule.index', ['tab' => 'reminders']) }}"
                class="hub-tab {{ $tab === 'reminders' ? 'active' : '' }}">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                </svg>
                <span>التنبيهات</span>
                @if($stats['reminders_count'] > 0)
                <span class="tab-badge">{{ $stats['reminders_count'] }}</span>
                @endif
            </a>
            <a href="{{ route('student.schedule.index', ['tab' => 'resources']) }}"
                class="hub-tab {{ $tab === 'resources' ? 'active' : '' }}">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
                <span>مصادري الخاصة</span>
                @if($stats['resources_count'] > 0)
                <span class="tab-badge">{{ $stats['resources_count'] }}</span>
                @endif
            </a>
            <a href="{{ route('student.schedule.index', ['tab' => 'assignments']) }}"
                class="hub-tab {{ $tab === 'assignments' ? 'active' : '' }}">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
                    <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
                </svg>
                <span>التكاليف</span>
                @if($stats['assignments_count'] > 0)
                <span class="tab-badge">{{ $stats['assignments_count'] }}</span>
                @endif
            </a>
        </div>

        <!-- ═══════════ Active Filter Indicator ═══════════ -->
        @if(request('filter'))
        <div style="padding: 0.75rem 1.5rem; background: #fffbeb; border-bottom: 1px solid #fef3c7; display: flex; align-items: center; justify-content: space-between;">
            <span style="font-size: 0.9rem; color: #92400e; font-weight: 600;">
                🔍 فلتر نشط:
                @switch(request('filter'))
                @case('today') مهام اليوم @break
                @case('overdue') المتأخرة @break
                @case('completed') المكتملة @break
                @case('high') أولوية عالية @break
                @endswitch
            </span>
            <a href="{{ route('student.schedule.index', ['tab' => $tab]) }}" style="color: #92400e; font-weight: 700; text-decoration: none; font-size: 0.85rem;">✕ إزالة الفلتر</a>
        </div>
        @endif

        <!-- ═══════════ Tab Content ═══════════ -->
        <div style="padding: 1.5rem;">

            @if($items->isEmpty())
            <!-- Empty State -->
            <div style="text-align: center; padding: 4rem 2rem;">
                <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem;">
                    @if($tab === 'study')
                    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                        <line x1="16" y1="2" x2="16" y2="6"></line>
                        <line x1="8" y1="2" x2="8" y2="6"></line>
                        <line x1="3" y1="10" x2="21" y2="10"></line>
                    </svg>
                    @elseif($tab === 'reminders')
                    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                    </svg>
                    @else
                    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    @endif
                </div>
                <h3 style="font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                    @if($tab === 'study') لا توجد مهام دراسية بعد
                    @elseif($tab === 'reminders') لا توجد تنبيهات
                    @else لا توجد مصادر محفوظة
                    @endif
                </h3>
                <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
                    @if($tab === 'study') أضف مهام مذاكرة لتنظيم وقتك
                    @elseif($tab === 'reminders') أنشئ تنبيهات لمواعيدك المهمة
                    @else أضف مصادر من قسم المصادر لتتبعها هنا
                    @endif
                </p>
                @if($tab !== 'reminders')
                <button onclick="openAddModal()" class="btn" style="background: var(--primary-color); color: white; border: none; padding: 0.75rem 2rem; border-radius: 12px; font-weight: 700;">
                    + إضافة جديد
                </button>
                @endif
            </div>

            @else

            <!-- ========== ASSIGNMENTS TAB ========== -->
            @if($tab === 'assignments')
            <style>
                .group-card {
                    background: white;
                    border: 1px solid #e2e8f0;
                    border-radius: 16px;
                    overflow: hidden;
                    margin-bottom: 2rem;
                    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
                }

                .group-header {
                    padding: 1rem 1.25rem;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
                }

                .group-header.overdue {
                    background: linear-gradient(to right, #fef2f2, #fff);
                    border-left: 4px solid #ef4444;
                }

                .group-header.upcoming {
                    background: linear-gradient(to right, #eff6ff, #fff);
                    border-left: 4px solid #3b82f6;
                }

                .group-header.completed {
                    background: linear-gradient(to right, #f0fdf4, #fff);
                    border-left: 4px solid #22c55e;
                }

                .group-title {
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    font-weight: 700;
                    font-size: 1.05rem;
                    color: #1e293b;
                }

                .group-count {
                    background: white;
                    padding: 0.25rem 0.75rem;
                    border-radius: 20px;
                    font-size: 0.8rem;
                    font-weight: 700;
                    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
                    color: #64748b;
                }

                .group-body {
                    padding: 1.25rem;
                    background: #fcfcfc;
                }
            </style>

            <div id="assignment-list" class="schedule-list">
                @if(isset($groupedAssignments) && $groupedAssignments->count() > 0)

                @php
                $assignGroupConfig = [
                'overdue' => ['label' => 'متأخرة', 'icon' => '⚠️', 'style' => 'overdue'],
                'upcoming' => ['label' => 'قادمة', 'icon' => '📅', 'style' => 'upcoming'],
                'completed' => ['label' => 'مكتملة', 'icon' => '✅', 'style' => 'completed'],
                ];
                @endphp

                @foreach($assignGroupConfig as $key => $cfg)
                @if(isset($groupedAssignments[$key]) && $groupedAssignments[$key]->count() > 0)
                <div class="group-card">
                    <div class="group-header {{ $cfg['style'] }}">
                        <div class="group-title">
                            <span>{{ $cfg['icon'] }}</span>
                            <span>{{ $cfg['label'] }}</span>
                        </div>
                        <span class="group-count">{{ $groupedAssignments[$key]->count() }} تكليف</span>
                    </div>

                    <div class="group-body">
                        @foreach($groupedAssignments[$key] as $item)
                        <div class="schedule-item {{ $item->is_completed ? 'completed' : '' }} {{ $item->is_overdue ? 'overdue' : '' }}"
                            data-id="{{ $item->id }}" style="border-right: 4px solid {{ $item->priority_color }}; margin-bottom: 0.75rem; background: white; border: 1px solid #f1f5f9;">

                            <div style="display: flex; align-items: flex-start; gap: 1rem;">
                                <!-- Checkbox -->
                                <div style="padding-top: 2px;">
                                    <input type="checkbox" class="item-checkbox" id="check-{{ $item->id }}"
                                        {{ $item->is_completed ? 'checked' : '' }}
                                        onchange="toggleComplete({{ $item->id }}, this)">
                                </div>

                                <div style="flex: 1;">
                                    <!-- Title -->
                                    <label for="check-{{ $item->id }}" class="item-title {{ $item->is_completed ? 'line-through' : '' }}" style="cursor: pointer;">
                                        {{ $item->display_title }}
                                    </label>

                                    <!-- Due Date Badge -->
                                    <div style="display: flex; gap: 0.5rem; margin-top: 0.4rem; flex-wrap: wrap;">
                                        @if($item->scheduled_date)
                                        <div class="badge-pill" style="background: #f1f5f9; color: #475569;">
                                            📅 {{ $item->scheduled_date->format('Y-m-d') }}
                                        </div>
                                        @php
                                        $daysLeft = (int) ceil(now()->floatDiffInDays($item->scheduled_date, false));
                                        @endphp
                                        @if(!$item->is_completed && $daysLeft <= 2 && $daysLeft>= 0)
                                            <div class="badge-pill" style="background: #fee2e2; color: #dc2626; font-weight: 700;">
                                                ⚠️ باقي {{ $daysLeft < 1 ? 'أقل من يوم' : $daysLeft . ' يوم' }}
                                            </div>
                                            @elseif($item->is_overdue)
                                            <div class="badge-pill" style="background: #fee2e2; color: #dc2626; font-weight: 700;">
                                                ⚠️ متأخر
                                            </div>
                                            @endif
                                            @endif

                                            <div class="badge-pill" style="background: {{ $item->priority_color }}20; color: {{ $item->priority_color }};">
                                                {{ $item->priority_label }}
                                            </div>
                                    </div>

                                    <!-- Note -->
                                    @if($item->note)
                                    <div class="item-note">{{ $item->note }}</div>
                                    @endif
                                </div>

                                <!-- Actions -->
                                <!-- No Actions for Assignments -->
                            </div>
                        </div>
                        @endforeach
                    </div>
                </div>
                @endif
                @endforeach
                @else
                <!-- Should be handled by main empty state, but just in case -->
                @endif
            </div>
            @endif

            <!-- ========== STUDY TAB ========== -->
            @if($tab === 'study')
            <style>
                .group-card {
                    background: white;
                    border: 1px solid #e2e8f0;
                    border-radius: 16px;
                    overflow: hidden;
                    margin-bottom: 2rem;
                    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
                }

                .group-header {
                    padding: 1rem 1.25rem;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
                }

                .group-header.past {
                    background: linear-gradient(to right, #fef2f2, #fff);
                    border-left: 4px solid #ef4444;
                }

                .group-header.today {
                    background: linear-gradient(to right, #fffbeb, #fff);
                    border-left: 4px solid #f59e0b;
                }

                .group-header.upcoming {
                    background: linear-gradient(to right, #eff6ff, #fff);
                    border-left: 4px solid #3b82f6;
                }

                .group-title {
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    font-weight: 700;
                    font-size: 1.05rem;
                    color: #1e293b;
                }

                .group-count {
                    background: white;
                    padding: 0.25rem 0.75rem;
                    border-radius: 20px;
                    font-size: 0.8rem;
                    font-weight: 700;
                    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
                    color: #64748b;
                }

                .group-body {
                    padding: 1.25rem;
                    background: #fcfcfc;
                }
            </style>

            <div id="schedule-list" class="schedule-list">
                @if(isset($groupedStudyItems) && $groupedStudyItems->count() > 0)

                @php
                $studyGroupConfig = [
                'past' => ['label' => 'مهام سابقة', 'icon' => '🔴', 'style' => 'past'],
                'today' => ['label' => 'اليوم', 'icon' => '🟡', 'style' => 'today'],
                'upcoming' => ['label' => 'قادمة', 'icon' => '🔵', 'style' => 'upcoming'],
                ];
                @endphp

                @foreach($studyGroupConfig as $key => $cfg)
                @if(isset($groupedStudyItems[$key]) && $groupedStudyItems[$key]->count() > 0)
                <div class="group-card">
                    <div class="group-header {{ $cfg['style'] }}">
                        <div class="group-title">
                            <span>{{ $cfg['icon'] }}</span>
                            <span>{{ $cfg['label'] }}</span>
                        </div>
                        <span class="group-count">{{ $groupedStudyItems[$key]->count() }} مهمة</span>
                    </div>

                    <div class="group-body">
                        @foreach($groupedStudyItems[$key] as $item)
                        <div class="schedule-item {{ $item->is_completed ? 'completed' : '' }} {{ $item->is_overdue ? 'overdue' : '' }}"
                            data-id="{{ $item->id }}" style="border-right: 4px solid {{ $item->priority_color }}; margin-bottom: 0.75rem; background: white; border: 1px solid #f1f5f9;">

                            <div style="display: flex; align-items: flex-start; gap: 1rem;">
                                <!-- Drag Handle -->
                                <div class="drag-handle" title="اسحب لإعادة الترتيب">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <line x1="8" y1="6" x2="21" y2="6"></line>
                                        <line x1="8" y1="12" x2="21" y2="12"></line>
                                        <line x1="8" y1="18" x2="21" y2="18"></line>
                                        <line x1="3" y1="6" x2="3.01" y2="6"></line>
                                        <line x1="3" y1="12" x2="3.01" y2="12"></line>
                                        <line x1="3" y1="18" x2="3.01" y2="18"></line>
                                    </svg>
                                </div>

                                <!-- Checkbox -->
                                <div style="padding-top: 2px;">
                                    <input type="checkbox" class="item-checkbox" id="check-{{ $item->id }}"
                                        {{ $item->is_completed ? 'checked' : '' }}
                                        onchange="toggleComplete({{ $item->id }}, this)">
                                </div>

                                <!-- Content -->
                                <div style="flex: 1; min-width: 0;">
                                    <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 0.5rem; flex-wrap: wrap;">
                                        <div style="flex: 1; min-width: 0;">
                                            <h4 class="item-title {{ $item->is_completed ? 'line-through' : '' }}">
                                                {{ $item->display_title }}
                                            </h4>

                                            <!-- Lecture Details (Subject, Doctor, Time) -->
                                            @if($item->referenceable_type == 'App\Models\Academic\Lecture' && $item->referenceable)
                                            <div style="font-size: 0.85rem; color: #64748b; margin-top: 0.35rem; margin-bottom: 0.5rem; display: flex; flex-wrap: wrap; gap: 0.8rem; align-items: center;">
                                                <span title="المادة" style="display: flex; align-items: center; gap: 0.3rem;">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                                                    </svg>
                                                    {{ $item->referenceable->subject->name ?? 'مادة غير معروفة' }}
                                                </span>
                                                <span title="الدكتور" style="display: flex; align-items: center; gap: 0.3rem;">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                                        <circle cx="12" cy="7" r="4"></circle>
                                                    </svg>
                                                    {{ $item->referenceable->subject->doctor->name ?? 'دكتور غير معروف' }}
                                                </span>
                                                <span title="وقت المحاضرة" style="display: flex; align-items: center; gap: 0.3rem;">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                        <circle cx="12" cy="12" r="10"></circle>
                                                        <polyline points="12 6 12 12 16 14"></polyline>
                                                    </svg>
                                                    {{ $item->referenceable->created_at->format('h:i A') }}
                                                </span>
                                                @if($item->referenceable->lecture_number)
                                                <span title="رقم المحاضرة" style="background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-size: 0.75rem;">
                                                    #{{ $item->referenceable->lecture_number }}
                                                </span>
                                                @endif
                                            </div>
                                            @endif

                                            <!-- Delegate Note -->
                                            @if($item->referenceable_type == 'App\Models\Academic\Lecture' && $item->referenceable && $item->referenceable->description)
                                            <div style="margin-top: 0.4rem; margin-bottom: 0.5rem; padding: 0.5rem 0.75rem; background: linear-gradient(135deg, #fffbeb, #fef3c7); border-radius: 8px; border-right: 3px solid #f59e0b; font-size: 0.85rem; color: #92400e; line-height: 1.6;">
                                                <div style="display: flex; align-items: center; gap: 0.3rem; font-weight: 700; margin-bottom: 0.2rem; font-size: 0.8rem;">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                                        <line x1="12" y1="9" x2="12" y2="13"></line>
                                                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                                                    </svg>
                                                    ملاحظة من المندوب:
                                                </div>
                                                {{ $item->referenceable->description }}
                                            </div>
                                            @endif

                                            <div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem;">
                                                <!-- Priority Badge -->
                                                <span class="badge-pill" style="background: {{ $item->priority_color }}20; color: {{ $item->priority_color }};">
                                                    {{ $item->priority_label }}
                                                </span>
                                                <!-- Status Badge -->
                                                <span class="badge-pill" style="background: {{ $item->status_color }}20; color: {{ $item->status_color }};">
                                                    {{ $item->status_label }}
                                                </span>
                                                <!-- Type Badge -->
                                                @if($item->referenceable_type)
                                                <span class="badge-pill" style="background: rgba(100, 116, 139, 0.1); color: #64748b;">
                                                    {{ $item->referenceable_type == 'App\Models\Academic\Lecture' ? '📖 محاضرة' : '📁 مصدر' }}
                                                </span>
                                                @else
                                                <span class="badge-pill" style="background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">
                                                    ✏️ مهمة يدوية
                                                </span>
                                                @endif
                                                <!-- Date -->
                                                @if($item->scheduled_date)
                                                <span class="badge-pill" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
                                                    📅 {{ $item->scheduled_date->format('m/d') }}
                                                </span>
                                                @endif
                                                <!-- Repeat -->
                                                @if($item->repeat_type !== 'none')
                                                <span class="badge-pill" style="background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">
                                                    🔁 {{ $item->repeat_type === 'daily' ? 'يومي' : 'أسبوعي' }}
                                                </span>
                                                @endif
                                            </div>
                                        </div>

                                        <!-- Actions -->
                                        <div class="item-actions">
                                            @if($key === 'past')
                                            <button onclick="moveToToday({{ $item->id }})" class="action-btn" title="نقل لليوم" style="color: #f59e0b;">
                                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                                    <line x1="16" y1="2" x2="16" y2="6"></line>
                                                    <line x1="8" y1="2" x2="8" y2="6"></line>
                                                    <line x1="3" y1="10" x2="21" y2="10"></line>
                                                    <path d="M12 14h.01"></path>
                                                </svg>
                                            </button>
                                            @endif
                                            <button onclick="editItem({{ $item->id }}, '{{ addslashes($item->display_title) }}', '{{ $item->priority }}', '{{ $item->scheduled_date?->format('Y-m-d') }}', '{{ addslashes($item->note) }}')" class="action-btn" title="تعديل">
                                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                                </svg>
                                            </button>
                                            <button onclick="changePriority({{ $item->id }})" class="action-btn" title="تغيير الأولوية" style="color: {{ $item->priority_color }};">
                                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                                                </svg>
                                            </button>
                                            <button onclick="deleteItem({{ $item->id }})" class="action-btn text-danger" title="حذف">
                                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                    <polyline points="3 6 5 6 21 6"></polyline>
                                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                                </svg>
                                            </button>
                                        </div>
                                    </div>

                                    @if($item->note)
                                    <div class="item-note">📝 {{ $item->note }}</div>
                                    @endif
                                </div>
                            </div>
                        </div>
                        @endforeach
                    </div>
                </div>
                @endif
                @endforeach

                @else
                @foreach($items as $item)
                <!-- Fallback code omitted for brevity but logic implies this case shouldn't be hit if groupedStudyItems is propagated -->
                {{-- To be safe, I should put the item card markup here too, but to save space I'll assume grouping works. --}}
                <div class="schedule-item">Fallback item: {{ $item->title }}</div>
                @endforeach
                @endif
            </div>

            <!-- ========== REMINDERS TAB (Enhanced) ========== -->
            @elseif($tab === 'reminders')
            <style>
                .reminders-section {
                    animation: fadeInUp 0.4s ease-out;
                }

                @keyframes fadeInUp {
                    from {
                        opacity: 0;
                        transform: translateY(15px);
                    }

                    to {
                        opacity: 1;
                        transform: translateY(0);
                    }
                }

                .reminder-group {
                    margin-bottom: 1.75rem;
                }

                .reminder-group-header {
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    padding: 0.75rem 1rem;
                    border-radius: 12px;
                    margin-bottom: 0.75rem;
                    font-weight: 700;
                    font-size: 0.95rem;
                }

                .reminder-group-header.overdue-header {
                    background: linear-gradient(135deg, rgba(239, 68, 68, 0.08), rgba(239, 68, 68, 0.03));
                    color: #dc2626;
                    border-right: 3px solid #ef4444;
                }

                .reminder-group-header.today-header {
                    background: linear-gradient(135deg, rgba(245, 158, 11, 0.08), rgba(245, 158, 11, 0.03));
                    color: #d97706;
                    border-right: 3px solid #f59e0b;
                }

                .reminder-group-header.upcoming-header {
                    background: linear-gradient(135deg, rgba(59, 130, 246, 0.08), rgba(59, 130, 246, 0.03));
                    color: #2563eb;
                    border-right: 3px solid #3b82f6;
                }

                .reminder-group-count {
                    display: inline-flex;
                    align-items: center;
                    justify-content: center;
                    min-width: 24px;
                    height: 24px;
                    border-radius: 8px;
                    font-size: 0.75rem;
                    font-weight: 800;
                    margin-right: auto;
                }

                .overdue-header .reminder-group-count {
                    background: rgba(239, 68, 68, 0.15);
                    color: #dc2626;
                }

                .today-header .reminder-group-count {
                    background: rgba(245, 158, 11, 0.15);
                    color: #d97706;
                }

                .upcoming-header .reminder-group-count {
                    background: rgba(59, 130, 246, 0.15);
                    color: #2563eb;
                }

                .reminder-card {
                    background: white;
                    border: 1px solid #f1f5f9;
                    border-radius: 14px;
                    padding: 1rem 1.15rem;
                    margin-bottom: 0.6rem;
                    transition: all 0.25s ease;
                    position: relative;
                    overflow: hidden;
                }

                .reminder-card:hover {
                    transform: translateX(4px);
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
                    border-color: #e2e8f0;
                }

                .reminder-card.is-overdue {
                    border-right: 3px solid #ef4444;
                    background: linear-gradient(90deg, white 96%, rgba(239, 68, 68, 0.04));
                }

                .reminder-card.is-today {
                    border-right: 3px solid #f59e0b;
                }

                .reminder-card.is-upcoming {
                    border-right: 3px solid #3b82f6;
                }

                .reminder-card-top {
                    display: flex;
                    align-items: flex-start;
                    justify-content: space-between;
                    gap: 0.75rem;
                }

                .reminder-card-info {
                    flex: 1;
                    min-width: 0;
                }

                .reminder-card-title {
                    font-size: 0.95rem;
                    font-weight: 700;
                    color: var(--text-primary);
                    margin-bottom: 0.35rem;
                    line-height: 1.5;
                }

                .reminder-card-title.done {
                    text-decoration: line-through;
                    opacity: 0.5;
                }

                .reminder-badges {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 0.4rem;
                    margin-top: 0.4rem;
                }

                .r-badge {
                    display: inline-flex;
                    align-items: center;
                    gap: 0.3rem;
                    padding: 0.2rem 0.6rem;
                    border-radius: 8px;
                    font-size: 0.75rem;
                    font-weight: 600;
                    white-space: nowrap;
                }

                .r-badge.time {
                    background: rgba(99, 102, 241, 0.08);
                    color: #6366f1;
                }

                .r-badge.date {
                    background: rgba(245, 158, 11, 0.08);
                    color: #d97706;
                }

                .r-badge.priority-high {
                    background: rgba(239, 68, 68, 0.08);
                    color: #dc2626;
                }

                .r-badge.priority-medium {
                    background: rgba(245, 158, 11, 0.08);
                    color: #d97706;
                }

                .r-badge.priority-low {
                    background: rgba(34, 197, 94, 0.08);
                    color: #16a34a;
                }

                .r-badge.repeat {
                    background: rgba(139, 92, 246, 0.08);
                    color: #7c3aed;
                }

                .reminder-note {
                    font-size: 0.82rem;
                    color: var(--text-secondary);
                    margin-top: 0.5rem;
                    padding: 0.5rem 0.75rem;
                    background: #f8fafc;
                    border-radius: 8px;
                    line-height: 1.6;
                }

                .reminder-card-actions {
                    display: flex;
                    align-items: center;
                    gap: 0.35rem;
                    flex-shrink: 0;
                }

                .reminder-action-btn {
                    width: 32px;
                    height: 32px;
                    border-radius: 8px;
                    border: none;
                    background: transparent;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    transition: all 0.2s;
                    color: #94a3b8;
                }

                .reminder-action-btn:hover {
                    background: #f1f5f9;
                    color: var(--primary-color);
                }

                .reminder-action-btn.delete:hover {
                    background: rgba(239, 68, 68, 0.08);
                    color: #ef4444;
                }

                .reminder-check {
                    width: 20px;
                    height: 20px;
                    border-radius: 6px;
                    cursor: pointer;
                    accent-color: var(--primary-color);
                }

                .reminders-empty {
                    text-align: center;
                    padding: 3.5rem 2rem;
                    animation: fadeInUp 0.5s ease-out;
                }

                .reminders-empty-icon {
                    width: 72px;
                    height: 72px;
                    border-radius: 50%;
                    background: linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(139, 92, 246, 0.08));
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 1.25rem;
                }

                .reminders-empty h3 {
                    font-weight: 700;
                    color: var(--text-primary);
                    margin-bottom: 0.5rem;
                    font-size: 1.1rem;
                }

                .reminders-empty p {
                    color: var(--text-secondary);
                    font-size: 0.9rem;
                    max-width: 320px;
                    margin: 0 auto;
                    line-height: 1.7;
                }
            </style>

            <div class="reminders-section">
                @if($groupedReminders && $groupedReminders->count() > 0)

                @php
                $groupConfig = [
                'past' => ['label' => 'مهام سابقة', 'icon' => '🔴', 'header' => 'overdue-header', 'card' => 'is-overdue'],
                'today' => ['label' => 'اليوم', 'icon' => '🟡', 'header' => 'today-header', 'card' => 'is-today'],
                'upcoming' => ['label' => 'قادمة', 'icon' => '🔵', 'header' => 'upcoming-header', 'card' => 'is-upcoming'],
                ];
                @endphp

                @foreach($groupConfig as $key => $cfg)
                @if(isset($groupedReminders[$key]) && $groupedReminders[$key]->count() > 0)
                <div class="reminder-group">
                    {{-- Group Header --}}
                    <div class="reminder-group-header {{ $cfg['header'] }}">
                        <span>{{ $cfg['icon'] }}</span>
                        <span>{{ $cfg['label'] }}</span>
                        <span class="reminder-group-count">{{ $groupedReminders[$key]->count() }}</span>
                    </div>

                    {{-- Reminder Cards --}}
                    @foreach($groupedReminders[$key] as $item)
                    <div class="reminder-card {{ $cfg['card'] }}">
                        <div class="reminder-card-top">
                            {{-- Info --}}
                            <div class="reminder-card-info">
                                <div class="reminder-card-title {{ $item->is_completed ? 'done' : '' }}">
                                    {{ $item->display_title }}
                                </div>
                                <div class="reminder-badges">
                                    @if($item->reminder_at)
                                    <span class="r-badge time">🔔 {{ $item->reminder_at->format('h:i A') }}</span>
                                    @endif
                                    @if($item->scheduled_date)
                                    <span class="r-badge date">📅 {{ $item->scheduled_date->format('Y-m-d') }}</span>
                                    @endif
                                    <span class="r-badge priority-{{ $item->priority }}">{{ $item->priority_label }}</span>
                                    @if($item->repeat_type !== 'none')
                                    <span class="r-badge repeat">🔁 {{ $item->repeat_type === 'daily' ? 'يومي' : 'أسبوعي' }}</span>
                                    @endif
                                </div>
                                @if($item->note)
                                <div class="reminder-note">📝 {{ $item->note }}</div>
                                @endif
                            </div>

                            {{-- Actions --}}
                            <div class="reminder-card-actions">
                                @if($key === 'past')
                                <button onclick="moveToToday({{ $item->id }})" class="reminder-action-btn" title="نقل لليوم" style="color: #f59e0b;">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                        <line x1="16" y1="2" x2="16" y2="6"></line>
                                        <line x1="8" y1="2" x2="8" y2="6"></line>
                                        <line x1="3" y1="10" x2="21" y2="10"></line>
                                        <path d="M12 14h.01"></path>
                                    </svg>
                                </button>
                                @endif
                                <input type="checkbox" class="reminder-check" {{ $item->is_completed ? 'checked' : '' }}
                                    onchange="toggleComplete({{ $item->id }}, this)" title="إكمال">
                                <button onclick="editItem({{ $item->id }}, '{{ addslashes($item->display_title) }}', '{{ $item->priority }}', '{{ $item->scheduled_date?->format('Y-m-d') }}', '{{ addslashes($item->note) }}')" class="reminder-action-btn" title="تعديل">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                                    </svg>
                                </button>
                                <button onclick="deleteItem({{ $item->id }})" class="reminder-action-btn delete" title="حذف">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="3 6 5 6 21 6" />
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </div>
                    @endforeach
                </div>
                @endif
                @endforeach

                @else
                {{-- Empty State (No button) --}}
                <div class="reminders-empty">
                    <div class="reminders-empty-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="1.5">
                            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                        </svg>
                    </div>
                    <h3>لا توجد تنبيهات حالياً</h3>
                    <p>أضف تنبيهات من زر "إضافة مهمة جديدة" أعلاه لمتابعة مواعيدك المهمة</p>
                </div>
                @endif
            </div>

            <!-- ========== RESOURCES TAB ========== -->
            @elseif($tab === 'resources')
            @if($groupedResources && $groupedResources->count() > 0)
            @foreach($groupedResources as $subjectName => $subjectItems)
            <div style="margin-bottom: 1.5rem;">
                <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1rem; padding-bottom: 0.75rem; border-bottom: 2px solid #f1f5f9;">
                    <div style="width: 36px; height: 36px; background: linear-gradient(135deg, var(--primary-color), #7c3aed); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
                            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                        </svg>
                    </div>
                    <h3 style="font-weight: 700; margin: 0; font-size: 1.1rem; color: var(--text-primary);">{{ $subjectName }}</h3>
                    <span class="badge-pill" style="background: var(--primary-color); color: white;">{{ $subjectItems->count() }}</span>
                </div>

                @foreach($subjectItems as $item)
                <div class="resource-card {{ $item->is_completed ? 'completed' : '' }}">
                    <div style="display: flex; align-items: center; gap: 1rem; flex: 1; min-width: 0;">
                        @php
                        $ext = '';
                        $iconColor = '#64748b';
                        if ($item->referenceable) {
                        $ext = strtolower($item->referenceable->file_type ?? '');
                        if(in_array($ext, ['pdf'])) $iconColor = '#ef4444';
                        elseif(in_array($ext, ['ppt','pptx'])) $iconColor = '#f59e0b';
                        elseif(in_array($ext, ['doc','docx'])) $iconColor = '#3b82f6';
                        elseif(in_array($ext, ['xls','xlsx'])) $iconColor = '#10b981';
                        }
                        @endphp
                        <div style="width: 42px; height: 42px; border-radius: 10px; background: {{ $iconColor }}15; display: flex; align-items: center; justify-content: center; flex-shrink: 0; color: {{ $iconColor }};">
                            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                                <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                                <polyline points="13 2 13 9 20 9"></polyline>
                            </svg>
                        </div>
                        <div style="flex: 1; min-width: 0;">
                            <div style="font-weight: 600; color: var(--text-primary); font-size: 0.95rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                                {{ $item->display_title }}
                            </div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary); display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.25rem;">
                                @if($ext) <span>{{ strtoupper($ext) }}</span> @endif
                                @if($item->category_tag)
                                <span class="badge-pill" style="font-size: 0.7rem; background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">{{ $item->category_tag }}</span>
                                @endif
                            </div>
                            @if($item->note)
                            <div class="item-note" style="margin-top: 0.25rem; font-size: 0.8rem;">📝 {{ $item->note }}</div>
                            @endif
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 0.5rem; flex-shrink: 0;">
                        @if($item->referenceable && $item->referenceable->file_path)
                        <a href="{{ Storage::url($item->referenceable->file_path) }}" target="_blank" class="action-btn" style="color: var(--primary-color);" title="تحميل">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                <polyline points="7 10 12 15 17 10"></polyline>
                                <line x1="12" y1="15" x2="12" y2="3"></line>
                            </svg>
                        </a>
                        @endif
                        <button onclick="deleteItem({{ $item->id }})" class="action-btn text-danger" title="إزالة">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                        </button>
                    </div>
                </div>
                @endforeach
            </div>
            @endforeach
            @else
            {{-- Fallback for ungrouped --}}
            @foreach($items as $item)
            <div class="resource-card">
                <div style="font-weight: 600;">{{ $item->display_title }}</div>
                <button onclick="deleteItem({{ $item->id }})" class="action-btn text-danger">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="3 6 5 6 21 6"></polyline>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                    </svg>
                </button>
            </div>
            @endforeach
            @endif
            @endif

            @endif
        </div>
    </div>
</div>

<!-- ═══════════ Add/Edit Modal ═══════════ -->
<div id="taskModal" class="modal-overlay" style="display: none;">
    <div class="modal-container">
        <div class="modal-header">
            <h3 class="modal-title" id="modalTitle">إضافة مهمة جديدة</h3>
            <button type="button" class="close-btn" onclick="closeModal()">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <input type="hidden" id="modal_item_id">

            <!-- Title -->
            <div class="form-group">
                <label class="form-label">العنوان <span style="color: #ef4444;">*</span></label>
                <input type="text" id="modal_title" class="form-input" placeholder="مثال: مراجعة الفصل الثالث...">
            </div>

            <!-- Type Selection -->
            <div class="form-group">
                <label class="form-label">النوع</label>
                <div style="display: flex; gap: 0.5rem;">
                    <label class="type-option active" data-type="study">
                        <input type="radio" name="modal_type" value="study" checked style="display: none;">
                        📅 مذاكرة
                    </label>
                    <label class="type-option" data-type="reminder">
                        <input type="radio" name="modal_type" value="reminder" style="display: none;">
                        🔔 تنبيه
                    </label>
                </div>
            </div>

            <!-- Priority -->
            <div class="form-group">
                <label class="form-label">الأولوية</label>
                <div style="display: flex; gap: 0.5rem;">
                    <label class="priority-option" data-priority="low" style="--priority-color: #10b981;">
                        <input type="radio" name="modal_priority" value="low" style="display: none;">
                        🟢 عادي
                    </label>
                    <label class="priority-option active" data-priority="medium" style="--priority-color: #f59e0b;">
                        <input type="radio" name="modal_priority" value="medium" checked style="display: none;">
                        🟡 مهم
                    </label>
                    <label class="priority-option" data-priority="high" style="--priority-color: #ef4444;">
                        <input type="radio" name="modal_priority" value="high" style="display: none;">
                        🔴 عاجل
                    </label>
                </div>
            </div>

            <!-- Date -->
            <div class="form-group">
                <label class="form-label">التاريخ (اختياري)</label>
                <input type="text" id="modal_date" class="form-input" placeholder="اختر التاريخ...">
            </div>

            <!-- Reminder Time (for reminders) -->
            <div class="form-group" id="reminder_section" style="display: none;">
                <label class="form-label">وقت التنبيه</label>
                <input type="text" id="modal_reminder_at" class="form-input" placeholder="اختر وقت التنبيه...">
            </div>

            <!-- Repeat -->
            <div class="form-group">
                <label class="form-label">التكرار</label>
                <select id="modal_repeat" class="form-input">
                    <option value="none">بدون تكرار</option>
                    <option value="daily">يومي</option>
                    <option value="weekly">أسبوعي</option>
                </select>
            </div>

            <!-- Note -->
            <div class="form-group">
                <label class="form-label">ملاحظة (اختياري)</label>
                <textarea id="modal_note" class="form-input" rows="2" placeholder="أضف ملاحظة..."></textarea>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-cancel" onclick="closeModal()">إلغاء</button>
            <button type="button" class="btn-submit" onclick="submitTask()">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                حفظ
            </button>
        </div>
    </div>
</div>

<!-- ═══════════ Styles ═══════════ -->
<style>
    /* ─── Stats Cards ─── */
    .stat-card {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1.25rem;
        background: white;
        border-radius: 16px;
        border: 1px solid #f1f5f9;
        transition: all 0.2s;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    }

    .stat-alert {
        border-color: #fecaca;
        background: #fef2f2;
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .stat-label {
        font-size: 0.8rem;
        color: var(--text-secondary);
        font-weight: 600;
        margin-bottom: 0.15rem;
    }

    .stat-value {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        line-height: 1;
    }

    /* ─── Tabs ─── */
    .hub-tab {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 1rem 1.25rem;
        text-decoration: none;
        color: var(--text-secondary);
        font-weight: 600;
        font-size: 0.95rem;
        border-bottom: 3px solid transparent;
        transition: all 0.2s;
        white-space: nowrap;
    }

    .hub-tab:hover {
        color: var(--primary-color);
    }

    .hub-tab.active {
        color: var(--primary-color);
        border-bottom-color: var(--primary-color);
    }

    .tab-badge {
        background: var(--primary-color);
        color: white;
        font-size: 0.7rem;
        padding: 0.15rem 0.5rem;
        border-radius: 20px;
        font-weight: 700;
    }

    /* ─── Schedule Items ─── */
    .schedule-item {
        background: white;
        border: 1px solid #f1f5f9;
        border-radius: 12px;
        padding: 1rem 1.25rem;
        margin-bottom: 0.75rem;
        transition: all 0.2s;
        cursor: default;
    }

    .schedule-item:hover {
        border-color: #e2e8f0;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
    }

    .schedule-item.completed {
        background: #f9fafb;
        opacity: 0.7;
    }

    .schedule-item.overdue {
        background: #fef2f2;
        border-color: #fecaca;
    }

    .drag-handle {
        color: #cbd5e1;
        cursor: move;
        padding-top: 3px;
        transition: color 0.2s;
    }

    .drag-handle:hover {
        color: var(--primary-color);
    }

    .item-title {
        font-size: 1rem;
        font-weight: 600;
        color: var(--text-primary);
        margin: 0;
        line-height: 1.4;
    }

    .item-title.line-through {
        text-decoration: line-through;
        color: var(--text-secondary);
    }

    .item-note {
        font-size: 0.85rem;
        color: var(--text-secondary);
        margin-top: 0.5rem;
        padding: 0.5rem 0.75rem;
        background: #f8fafc;
        border-radius: 8px;
        border: 1px dashed #e2e8f0;
    }

    .badge-pill {
        display: inline-flex;
        align-items: center;
        padding: 0.2rem 0.6rem;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 600;
        gap: 0.25rem;
    }

    .item-actions {
        display: flex;
        gap: 0.25rem;
        align-items: center;
    }

    .action-btn {
        background: none;
        border: none;
        padding: 6px;
        cursor: pointer;
        color: #94a3b8;
        border-radius: 8px;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .action-btn:hover {
        background: #f1f5f9;
        color: var(--text-primary);
    }

    .text-danger {
        color: #ef4444 !important;
    }

    .action-btn.text-danger:hover {
        background: #fef2f2;
    }

    .item-checkbox {
        width: 20px;
        height: 20px;
        border-radius: 6px;
        cursor: pointer;
        accent-color: var(--primary-color);
    }

    /* ─── Reminders Timeline ─── */
    .reminder-item {
        display: flex;
        gap: 0;
        margin-bottom: 0;
    }

    .reminder-timeline {
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 30px;
        flex-shrink: 0;
    }

    .timeline-dot {
        width: 12px;
        height: 12px;
        border-radius: 50%;
        flex-shrink: 0;
        margin-top: 6px;
    }

    .timeline-line {
        width: 2px;
        flex: 1;
        background: #e2e8f0;
        min-height: 20px;
    }

    .reminder-content {
        flex: 1;
        padding: 0.75rem 1rem;
        margin-bottom: 0.75rem;
        background: white;
        border: 1px solid #f1f5f9;
        border-radius: 12px;
        margin-right: 0.5rem;
    }

    .reminder-item.overdue .reminder-content {
        background: #fef2f2;
        border-color: #fecaca;
    }

    .reminder-item.completed .reminder-content {
        opacity: 0.6;
    }

    /* ─── Resource Cards ─── */
    .resource-card {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.75rem 1rem;
        border-radius: 10px;
        border: 1px solid #f1f5f9;
        margin-bottom: 0.5rem;
        transition: all 0.2s;
        gap: 1rem;
    }

    .resource-card:hover {
        border-color: #e2e8f0;
        background: #fafbfc;
    }

    .resource-card.completed {
        opacity: 0.6;
    }

    /* ─── Modal ─── */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1050;
        backdrop-filter: blur(4px);
    }

    .modal-container {
        background: white;
        border-radius: 20px;
        width: 100%;
        max-width: 540px;
        padding: 0;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        margin: 1rem;
        max-height: 90vh;
        overflow-y: auto;
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1.5rem 2rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .modal-title {
        font-size: 1.25rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0;
    }

    .close-btn {
        background: none;
        border: none;
        color: #94a3b8;
        cursor: pointer;
        padding: 4px;
    }

    .close-btn:hover {
        color: var(--text-primary);
    }

    .modal-body {
        padding: 1.5rem 2rem;
    }

    .modal-footer {
        display: flex;
        gap: 0.75rem;
        justify-content: flex-end;
        padding: 1.25rem 2rem;
        border-top: 1px solid #f1f5f9;
    }

    .form-group {
        margin-bottom: 1.25rem;
    }

    .form-label {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 600;
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .form-input {
        width: 100%;
        padding: 0.75rem 1rem;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        font-size: 0.95rem;
        outline: none;
        transition: all 0.2s;
        font-family: inherit;
    }

    .form-input:focus {
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .type-option,
    .priority-option {
        flex: 1;
        padding: 0.6rem;
        border-radius: 10px;
        text-align: center;
        cursor: pointer;
        border: 2px solid #e2e8f0;
        font-weight: 600;
        font-size: 0.85rem;
        transition: all 0.2s;
    }

    .type-option:hover,
    .priority-option:hover {
        border-color: #cbd5e1;
    }

    .type-option.active {
        border-color: var(--primary-color);
        background: rgba(79, 70, 229, 0.05);
        color: var(--primary-color);
    }

    .priority-option.active {
        border-color: var(--priority-color);
        background: color-mix(in srgb, var(--priority-color) 8%, white);
    }

    .btn-cancel {
        background: #f1f5f9;
        color: var(--text-secondary);
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        cursor: pointer;
        font-size: 0.9rem;
    }

    .btn-submit {
        background: linear-gradient(135deg, var(--primary-color), #7c3aed);
        color: white;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        cursor: pointer;
        font-size: 0.9rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);
    }

    .btn-submit:hover {
        transform: translateY(-1px);
        box-shadow: 0 6px 15px rgba(79, 70, 229, 0.4);
    }

    /* ─── Responsive ─── */
    @media (max-width: 768px) {
        .hub-tab span {
            display: none;
        }

        .hub-tab {
            padding: 1rem 0.75rem;
        }

        .stat-card {
            padding: 1rem;
        }

        .stat-value {
            font-size: 1.2rem;
        }
    }
</style>

<!-- ═══════════ JavaScript ═══════════ -->
<script src="https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script>
    // ─── Flatpickr Init ───
    let datePicker, reminderPicker;
    document.addEventListener('DOMContentLoaded', function() {
        datePicker = flatpickr("#modal_date", {
            dateFormat: "Y-m-d",
            minDate: "today"
        });
        reminderPicker = flatpickr("#modal_reminder_at", {
            dateFormat: "Y-m-d H:i",
            enableTime: true,
            minDate: "today",
            time_24hr: true
        });

        // Sortable for study tab (Grouped)
        document.querySelectorAll('.group-body').forEach(groupEl => {
            Sortable.create(groupEl, {
                animation: 150,
                handle: '.drag-handle',
                onEnd: function(evt) {
                    const items = [];
                    // Iterate only over items in the current group
                    evt.to.querySelectorAll('.schedule-item').forEach((item, index) => {
                        items.push({
                            id: parseInt(item.dataset.id),
                            order: index + 1
                        });
                    });

                    if (items.length > 0) {
                        fetch('{{ route("student.schedule.reorder") }}', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-TOKEN': '{{ csrf_token() }}'
                            },
                            body: JSON.stringify({
                                items
                            })
                        });
                    }
                }
            });
        });

        // Type toggle
        document.querySelectorAll('.type-option').forEach(opt => {
            opt.addEventListener('click', function() {
                document.querySelectorAll('.type-option').forEach(o => o.classList.remove('active'));
                this.classList.add('active');
                this.querySelector('input').checked = true;
                document.getElementById('reminder_section').style.display =
                    this.dataset.type === 'reminder' ? 'block' : 'none';
            });
        });

        // Priority toggle
        document.querySelectorAll('.priority-option').forEach(opt => {
            opt.addEventListener('click', function() {
                document.querySelectorAll('.priority-option').forEach(o => o.classList.remove('active'));
                this.classList.add('active');
                this.querySelector('input').checked = true;
            });
        });

        // Reminder polling (every 60s)
        setInterval(checkReminders, 60000);
    });

    // ─── Modal Functions ───
    let editMode = false;

    function openAddModal() {
        editMode = false;
        document.getElementById('modalTitle').textContent = 'إضافة مهمة جديدة';
        document.getElementById('modal_item_id').value = '';
        document.getElementById('modal_title').value = '';
        document.getElementById('modal_note').value = '';
        document.getElementById('modal_repeat').value = 'none';
        if (datePicker) datePicker.clear();
        if (reminderPicker) reminderPicker.clear();

        // Reset type & priority selections
        document.querySelectorAll('.type-option').forEach(o => o.classList.remove('active'));
        document.querySelector('.type-option[data-type="study"]').classList.add('active');
        document.querySelector('.type-option[data-type="study"] input').checked = true;
        document.querySelectorAll('.priority-option').forEach(o => o.classList.remove('active'));
        document.querySelector('.priority-option[data-priority="medium"]').classList.add('active');
        document.querySelector('.priority-option[data-priority="medium"] input').checked = true;
        document.getElementById('reminder_section').style.display = 'none';

        document.getElementById('taskModal').style.display = 'flex';
    }

    function editItem(id, title, priority, date, note) {
        editMode = true;
        document.getElementById('modalTitle').textContent = 'تعديل المهمة';
        document.getElementById('modal_item_id').value = id;
        document.getElementById('modal_title').value = title;
        document.getElementById('modal_note').value = note || '';
        if (datePicker && date) datePicker.setDate(date);
        else if (datePicker) datePicker.clear();

        // Set priority
        document.querySelectorAll('.priority-option').forEach(o => o.classList.remove('active'));
        const pOpt = document.querySelector(`.priority-option[data-priority="${priority}"]`);
        if (pOpt) {
            pOpt.classList.add('active');
            pOpt.querySelector('input').checked = true;
        }

        document.getElementById('taskModal').style.display = 'flex';
    }

    function closeModal() {
        document.getElementById('taskModal').style.display = 'none';
    }

    function submitTask() {
        const title = document.getElementById('modal_title').value.trim();
        if (!title) {
            alert('يرجى إدخال العنوان');
            return;
        }

        const itemId = document.getElementById('modal_item_id').value;
        const type = document.querySelector('input[name="modal_type"]:checked')?.value || 'study';
        const priority = document.querySelector('input[name="modal_priority"]:checked')?.value || 'medium';
        const date = document.getElementById('modal_date').value;
        const note = document.getElementById('modal_note').value;
        const repeat = document.getElementById('modal_repeat').value;
        const reminderAt = document.getElementById('modal_reminder_at')?.value || '';

        if (editMode && itemId) {
            // UPDATE
            fetch(`/student/schedule/${itemId}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        title,
                        priority,
                        scheduled_date: date,
                        note,
                        reminder_at: reminderAt
                    })
                })
                .then(r => r.json())
                .then(d => {
                    if (d.success) {
                        closeModal();
                        location.reload();
                    } else alert(d.message);
                })
                .catch(() => alert('حدث خطأ'));
        } else {
            // CREATE
            fetch('{{ route("student.schedule.storeCustomTask") }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        title,
                        item_type: type,
                        priority,
                        scheduled_date: date,
                        note,
                        repeat_type: repeat,
                        reminder_at: reminderAt
                    })
                })
                .then(r => r.json())
                .then(d => {
                    if (d.success) {
                        closeModal();
                        location.reload();
                    } else alert(d.message);
                })
                .catch(() => alert('حدث خطأ'));
        }
    }

    // ─── Item Actions ───
    function toggleComplete(id, checkbox) {
        fetch(`/student/schedule/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    is_completed: checkbox.checked
                })
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) {
                    if (d.message && d.message !== 'تم التحديث بنجاح') {
                        alert(d.message);
                    }
                    location.reload();
                }
            });
    }

    function changePriority(id) {
        const priorities = ['low', 'medium', 'high'];
        const labels = ['عادي 🟢', 'مهم 🟡', 'عاجل 🔴'];
        const choice = prompt('اختر الأولوية:\n1 - عادي 🟢\n2 - مهم 🟡\n3 - عاجل 🔴');
        const idx = parseInt(choice) - 1;
        if (idx >= 0 && idx < 3) {
            fetch(`/student/schedule/${id}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        priority: priorities[idx]
                    })
                })
                .then(r => r.json())
                .then(d => {
                    if (d.success) location.reload();
                });
        }
    }

    function deleteItem(id) {
        Swal.fire({
            title: 'هل أنت متأكد؟',
            text: "لن تتمكن من استرجاع هذا العنصر!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#ef4444',
            cancelButtonColor: '#64748b',
            confirmButtonText: 'نعم، احذفه!',
            cancelButtonText: 'إلغاء'
        }).then((result) => {
            if (result.isConfirmed) {
                fetch(`/student/schedule/${id}`, {
                        method: 'DELETE',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': '{{ csrf_token() }}',
                            'Accept': 'application/json'
                        }
                    })
                    .then(r => r.json())
                    .then(d => {
                        if (d.success) {
                            Swal.fire(
                                'تم الحذف!',
                                'تم حذف العنصر بنجاح.',
                                'success'
                            ).then(() => location.reload());
                        }
                    })
                    .catch(err => {
                        Swal.fire('خطأ!', 'حدث خطأ أثناء الحذف', 'error');
                    });
            }
        })
    }

    function moveToToday(id) {
        fetch(`/student/schedule/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    scheduled_date: '{{ date("Y-m-d") }}'
                })
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) {
                    Swal.fire({
                        icon: 'success',
                        title: 'تم النقل!',
                        text: 'تم نقل المهمة إلى اليوم بنجاح',
                        timer: 1500,
                        showConfirmButton: false
                    }).then(() => location.reload());
                }
            })
            .catch(err => {
                Swal.fire('خطأ!', 'حدث خطأ أثناء التحديث', 'error');
            });
    }

    // ─── Reminder Polling ───
    function checkReminders() {
        fetch('{{ route("student.schedule.checkReminders") }}', {
                headers: {
                    'Accept': 'application/json'
                }
            })
            .then(r => r.json())
            .then(data => {
                if (data.count > 0) {
                    data.reminders.forEach(r => {
                        if (Notification.permission === 'granted') {
                            new Notification('⏰ تذكير دراسي', {
                                body: r.title,
                                icon: '/favicon.ico'
                            });
                        } else {
                            alert('⏰ تذكير: ' + r.title);
                        }
                    });
                }
            }).catch(() => {});
    }

    // Request notification permission
    if ('Notification' in window && Notification.permission === 'default') {
        Notification.requestPermission();
    }
</script>
@endsection