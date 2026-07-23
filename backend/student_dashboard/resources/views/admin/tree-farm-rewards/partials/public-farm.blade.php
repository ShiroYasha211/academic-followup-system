@php
    $formatFocusDuration = static function (int $seconds): string {
        $hours = intdiv($seconds, 3600);
        $minutes = intdiv($seconds % 3600, 60);

        if ($hours > 0 && $minutes > 0) {
            return number_format($hours) . ' س ' . $minutes . ' د';
        }

        if ($hours > 0) {
            return number_format($hours) . ' ساعة';
        }

        return $minutes . ' دقيقة';
    };

    $publicExportQuery = request()->except(['public_page']);
    $publicExportQuery['tab'] = 'public_farm';
@endphp

<style>
    .public-farm-shell {
        --farm-ink: #16352b;
        --farm-muted: #64748b;
        --farm-green: #247a56;
        --farm-green-dark: #155f43;
        --farm-soft: #edf7f1;
        --farm-line: #dce9e1;
    }

    .public-farm-hero {
        position: relative;
        overflow: hidden;
        padding: 1.7rem;
        color: #fff;
        background:
            radial-gradient(circle at 12% 12%, rgba(255, 255, 255, .18), transparent 24%),
            linear-gradient(135deg, #155f43 0%, #247a56 58%, #2e8b62 100%);
        border-radius: 1.35rem;
        box-shadow: 0 18px 42px rgba(21, 95, 67, .16);
    }

    .public-farm-hero::after {
        content: "";
        position: absolute;
        inset-inline-end: -3.5rem;
        bottom: -5.5rem;
        width: 14rem;
        height: 14rem;
        border: 1px solid rgba(255, 255, 255, .18);
        border-radius: 50%;
        box-shadow: 0 0 0 2.2rem rgba(255, 255, 255, .04), 0 0 0 4.4rem rgba(255, 255, 255, .025);
    }

    .public-farm-hero > * {
        position: relative;
        z-index: 1;
    }

    .public-farm-stat-grid {
        display: grid;
        grid-template-columns: repeat(5, minmax(0, 1fr));
        gap: .85rem;
    }

    .public-farm-stat {
        min-width: 0;
        padding: 1rem;
        background: #fff;
        border: 1px solid var(--farm-line);
        border-radius: 1rem;
        box-shadow: 0 8px 24px rgba(22, 53, 43, .055);
    }

    .public-farm-stat-value {
        color: var(--farm-ink);
        font-size: 1.35rem;
        line-height: 1.2;
        font-weight: 900;
        font-variant-numeric: tabular-nums;
        overflow-wrap: anywhere;
    }

    .public-farm-stat-label {
        margin-top: .3rem;
        color: var(--farm-muted);
        font-size: .75rem;
        font-weight: 700;
    }

    .public-farm-filter-panel,
    .public-farm-table,
    .public-university-panel {
        background: #fff;
        border: 1px solid var(--farm-line);
        border-radius: 1.15rem;
        box-shadow: 0 8px 26px rgba(22, 53, 43, .045);
    }

    .public-farm-filter-panel {
        padding: 1.15rem;
    }

    .public-farm-filter-panel .form-control,
    .public-farm-filter-panel .form-select {
        min-height: 2.75rem;
        border-color: #dce5e0;
        border-radius: .75rem;
        box-shadow: none;
    }

    .public-farm-filter-panel .form-control:focus,
    .public-farm-filter-panel .form-select:focus {
        border-color: #68a989;
        box-shadow: 0 0 0 .2rem rgba(36, 122, 86, .1);
    }

    .public-university-list {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: .8rem;
    }

    .public-university-item {
        padding: .9rem 1rem;
        background: #f8fbf9;
        border: 1px solid #e6efe9;
        border-radius: .85rem;
    }

    .public-farm-table {
        overflow: hidden;
    }

    .public-farm-table .table {
        min-width: 1050px;
    }

    .public-farm-table th {
        padding: .85rem 1rem;
        color: #52635c;
        background: #f5f9f6;
        border-bottom: 1px solid var(--farm-line);
        font-size: .76rem;
        font-weight: 800;
        white-space: nowrap;
    }

    .public-farm-table td {
        padding: .95rem 1rem;
        border-color: #edf2ef;
        vertical-align: middle;
    }

    .public-farm-avatar {
        display: grid;
        place-items: center;
        flex: 0 0 2.5rem;
        width: 2.5rem;
        height: 2.5rem;
        color: #fff;
        background: var(--farm-green);
        border-radius: .75rem;
        font-weight: 900;
    }

    .public-farm-status {
        display: inline-flex;
        align-items: center;
        gap: .35rem;
        padding: .3rem .55rem;
        border-radius: .5rem;
        font-size: .72rem;
        font-weight: 800;
    }

    .public-farm-status.is-visible {
        color: #166534;
        background: #dcfce7;
    }

    .public-farm-status.is-hidden {
        color: #9a3412;
        background: #ffedd5;
    }

    .public-farm-action {
        display: inline-grid;
        place-items: center;
        width: 2.25rem;
        height: 2.25rem;
        border: 1px solid #dce7e0;
        border-radius: .65rem;
        transition: transform .18s ease, border-color .18s ease, background .18s ease;
    }

    .public-farm-action:hover {
        transform: translateY(-1px);
        border-color: #8ab8a0;
        background: var(--farm-soft);
    }

    @media (max-width: 1199.98px) {
        .public-farm-stat-grid {
            grid-template-columns: repeat(3, minmax(0, 1fr));
        }

        .public-university-list {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }
    }

    @media (max-width: 767.98px) {
        .public-farm-stat-grid,
        .public-university-list {
            grid-template-columns: 1fr 1fr;
        }

        .public-farm-hero {
            padding: 1.3rem;
        }
    }

    @media (max-width: 479.98px) {
        .public-farm-stat-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<div class="tab-pane fade {{ $activeTreeFarmTab === 'public_farm' ? 'show active' : '' }}" id="public-farm-pane" role="tabpanel" aria-labelledby="public-farm-tab" tabindex="0">
    <section class="public-farm-shell">
        <div class="public-farm-hero mb-4">
            <div class="d-flex justify-content-between align-items-start gap-4 flex-wrap">
                <div style="max-width: 680px;">
                    <div class="d-flex align-items-center gap-2 mb-2">
                        <span class="d-inline-grid place-items-center bg-white bg-opacity-10 rounded-3 p-2">
                            <i class="fa-solid fa-earth-americas"></i>
                        </span>
                        <span class="small fw-bold text-white-50">المشاركة الجامعية</span>
                    </div>
                    <h2 class="h3 fw-black mb-2">المزرعة العامة</h2>
                    <p class="mb-0 text-white-50 lh-lg">
                        متابعة جلسات التركيز العامة، ترتيب الجامعات، والنباتات التي أضافها الطلاب إلى المجتمع الأكاديمي.
                    </p>
                </div>
                <a href="{{ route('admin.tree-farm-rewards.public-farm.export', $publicExportQuery) }}" class="btn btn-light fw-bold px-3 py-2 rounded-3">
                    <i class="fa-solid fa-file-excel text-success me-1"></i>
                    تصدير Excel
                </a>
            </div>
        </div>

        <div class="public-farm-stat-grid mb-4">
            <div class="public-farm-stat">
                <div class="public-farm-stat-value">{{ number_format($publicStats['participants']) }}</div>
                <div class="public-farm-stat-label">مشارك ظاهر ضمن النتائج</div>
            </div>
            <div class="public-farm-stat">
                <div class="public-farm-stat-value">{{ $formatFocusDuration($publicStats['focus_seconds']) }}</div>
                <div class="public-farm-stat-label">إجمالي التركيز العام</div>
            </div>
            <div class="public-farm-stat">
                <div class="public-farm-stat-value">{{ number_format($publicStats['sessions']) }}</div>
                <div class="public-farm-stat-label">جلسة عامة مسجلة</div>
            </div>
            <div class="public-farm-stat">
                <div class="public-farm-stat-value">{{ number_format($publicStats['plants']) }}</div>
                <div class="public-farm-stat-label">نبتة في المزرعة العامة</div>
            </div>
            <div class="public-farm-stat">
                <div class="public-farm-stat-value">{{ number_format($publicStats['universities']) }}</div>
                <div class="public-farm-stat-label">جامعة مشاركة</div>
            </div>
        </div>

        <form method="GET" action="{{ route('admin.tree-farm-rewards.index') }}" class="public-farm-filter-panel mb-4">
            <input type="hidden" name="tab" value="public_farm">
            <div class="d-flex align-items-center justify-content-between gap-3 mb-3 flex-wrap">
                <div>
                    <h3 class="h6 fw-bold mb-1">تصفية المشاركات</h3>
                    <p class="small text-muted mb-0">ابحث أكاديميًا أو اعرض نشاط فترة زمنية محددة.</p>
                </div>
                <a href="{{ route('admin.tree-farm-rewards.index', ['tab' => 'public_farm']) }}" class="btn btn-sm btn-light border rounded-3">
                    <i class="fa-solid fa-rotate-left me-1"></i>
                    إعادة ضبط
                </a>
            </div>

            <div class="row g-3">
                <div class="col-xl-4 col-md-6">
                    <label class="form-label small fw-bold">البحث</label>
                    <input type="search" name="public_search" value="{{ request('public_search') }}" class="form-control" placeholder="الاسم، الاسم المستعار، الرقم الجامعي">
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">الجامعة</label>
                    <select name="public_university_id" class="form-select">
                        <option value="">كل الجامعات</option>
                        @foreach($publicUniversities as $university)
                            <option value="{{ $university->id }}" @selected((string) request('public_university_id') === (string) $university->id)>{{ $university->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">الكلية</label>
                    <select name="public_college_id" class="form-select">
                        <option value="">كل الكليات</option>
                        @foreach($publicColleges as $college)
                            <option value="{{ $college->id }}" @selected((string) request('public_college_id') === (string) $college->id)>{{ $college->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">التخصص</label>
                    <select name="public_major_id" class="form-select">
                        <option value="">كل التخصصات</option>
                        @foreach($publicMajors as $major)
                            <option value="{{ $major->id }}" @selected((string) request('public_major_id') === (string) $major->id)>{{ $major->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">المستوى</label>
                    <select name="public_level_id" class="form-select">
                        <option value="">كل المستويات</option>
                        @foreach($publicLevels as $level)
                            <option value="{{ $level->id }}" @selected((string) request('public_level_id') === (string) $level->id)>{{ $level->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">من تاريخ</label>
                    <input type="date" name="public_from" value="{{ request('public_from') }}" class="form-control">
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">إلى تاريخ</label>
                    <input type="date" name="public_to" value="{{ request('public_to') }}" class="form-control">
                </div>
                <div class="col-xl-2 col-md-3">
                    <label class="form-label small fw-bold">الظهور</label>
                    <select name="public_visibility" class="form-select">
                        <option value="public" @selected(request('public_visibility', 'public') === 'public')>الظاهرون فقط</option>
                        <option value="hidden" @selected(request('public_visibility') === 'hidden')>المخفيون فقط</option>
                        <option value="all" @selected(request('public_visibility') === 'all')>الكل</option>
                    </select>
                </div>
                <div class="col-xl-3 col-md-4">
                    <label class="form-label small fw-bold">الترتيب</label>
                    <select name="public_sort" class="form-select">
                        <option value="focus" @selected($publicSort === 'focus')>مدة التركيز</option>
                        <option value="plants" @selected($publicSort === 'plants')>عدد النباتات</option>
                        <option value="sessions" @selected($publicSort === 'sessions')>عدد الجلسات</option>
                        <option value="latest" @selected($publicSort === 'latest')>آخر نشاط</option>
                    </select>
                </div>
                <div class="col-xl-3 col-md-5 d-flex align-items-end">
                    <button type="submit" class="btn btn-success w-100 rounded-3 py-2 fw-bold">
                        <i class="fa-solid fa-filter me-1"></i>
                        تطبيق الفلاتر
                    </button>
                </div>
            </div>
        </form>

        @if($publicUniversitySummary->isNotEmpty())
            <div class="public-university-panel p-3 p-lg-4 mb-4">
                <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
                    <div>
                        <h3 class="h6 fw-bold mb-1">أداء الجامعات</h3>
                        <p class="small text-muted mb-0">ملخص النشاط المطابق للفلاتر الحالية.</p>
                    </div>
                    <i class="fa-solid fa-building-columns text-success"></i>
                </div>
                <div class="public-university-list">
                    @foreach($publicUniversitySummary as $university)
                        <article class="public-university-item">
                            <div class="fw-bold text-dark text-truncate mb-2" title="{{ $university['university'] }}">{{ $university['university'] }}</div>
                            <div class="d-flex justify-content-between small text-muted gap-2">
                                <span>{{ number_format($university['participants']) }} مشارك</span>
                                <span>{{ $formatFocusDuration($university['focus_seconds']) }}</span>
                            </div>
                            <div class="d-flex justify-content-between small mt-2 gap-2">
                                <span class="text-success fw-bold">{{ number_format($university['plants']) }} نبتة</span>
                                <span class="text-muted">{{ number_format($university['sessions']) }} جلسة</span>
                            </div>
                        </article>
                    @endforeach
                </div>
            </div>
        @endif

        <div class="public-farm-table">
            <div class="p-3 p-lg-4 border-bottom d-flex align-items-center justify-content-between gap-3 flex-wrap">
                <div>
                    <h3 class="h6 fw-bold mb-1">المشاركون في المزرعة العامة</h3>
                    <p class="small text-muted mb-0">الاسم الحقيقي ظاهر للإدارة فقط؛ التطبيق يحترم الاسم المستعار المختار.</p>
                </div>
                <span class="small fw-bold text-muted">{{ number_format($publicProfiles->total()) }} نتيجة</span>
            </div>

            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead>
                        <tr>
                            <th>الطالب</th>
                            <th>المسار الأكاديمي</th>
                            <th>الاسم الظاهر</th>
                            <th>التركيز العام</th>
                            <th>الجلسات</th>
                            <th>النباتات</th>
                            <th>آخر نشاط</th>
                            <th>الظهور</th>
                            <th class="text-center">إجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($publicProfiles as $profile)
                            @php
                                $student = $profile->user;
                                $displayName = $profile->use_alias && $profile->public_name
                                    ? $profile->public_name
                                    : ($student?->name ?? 'مستخدم محذوف');
                                $lastActivity = $profile->last_public_activity_at
                                    ? \Illuminate\Support\Carbon::parse($profile->last_public_activity_at)
                                    : null;
                            @endphp
                            <tr>
                                <td>
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="public-farm-avatar">{{ mb_substr($student?->name ?? 'م', 0, 1) }}</div>
                                        <div class="min-w-0">
                                            <div class="fw-bold text-dark text-truncate" style="max-width: 190px;">{{ $student?->name ?? 'مستخدم محذوف' }}</div>
                                            <div class="small text-muted">{{ $student?->student_number ?: $student?->email }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div class="small fw-bold text-dark">{{ $student?->university?->name ?? 'غير محدد' }}</div>
                                    <div class="small text-muted mt-1">
                                        {{ collect([$student?->college?->name, $student?->major?->name, $student?->level?->name])->filter()->join(' · ') ?: 'المسار غير مكتمل' }}
                                    </div>
                                </td>
                                <td>
                                    <div class="fw-bold">{{ $displayName }}</div>
                                    @if($profile->use_alias && $profile->public_name)
                                        <div class="small text-muted">اسم مستعار</div>
                                    @else
                                        <div class="small text-muted">الاسم الحقيقي</div>
                                    @endif
                                </td>
                                <td class="fw-bold text-success">{{ $formatFocusDuration((int) ($profile->filtered_public_focus_seconds ?? 0)) }}</td>
                                <td>{{ number_format((int) ($profile->filtered_public_sessions_count ?? 0)) }}</td>
                                <td>{{ number_format((int) ($profile->filtered_public_plants_count ?? 0)) }}</td>
                                <td>
                                    @if($lastActivity)
                                        <div class="small fw-bold">{{ $lastActivity->format('Y/m/d') }}</div>
                                        <div class="small text-muted">{{ $lastActivity->format('h:i A') }}</div>
                                    @else
                                        <span class="text-muted">—</span>
                                    @endif
                                </td>
                                <td>
                                    <span class="public-farm-status {{ $profile->is_public ? 'is-visible' : 'is-hidden' }}">
                                        <i class="fa-solid {{ $profile->is_public ? 'fa-eye' : 'fa-eye-slash' }}"></i>
                                        {{ $profile->is_public ? 'ظاهر' : 'مخفي' }}
                                    </span>
                                </td>
                                <td>
                                    <div class="d-flex justify-content-center gap-2">
                                        <a href="{{ route('admin.tree-farm-rewards.public-farm.show', $profile) }}" class="public-farm-action text-success" title="عرض التفاصيل">
                                            <i class="fa-solid fa-arrow-up-right-from-square"></i>
                                        </a>
                                        <form method="POST" action="{{ route('admin.tree-farm-rewards.public-farm.visibility', $profile) }}" onsubmit="return confirm('{{ $profile->is_public ? 'إخفاء الطالب من المزرعة العامة؟' : 'إعادة إظهار الطالب في المزرعة العامة؟' }}')">
                                            @csrf
                                            <button type="submit" class="public-farm-action {{ $profile->is_public ? 'text-warning' : 'text-success' }}" title="{{ $profile->is_public ? 'إخفاء' : 'إظهار' }}">
                                                <i class="fa-solid {{ $profile->is_public ? 'fa-eye-slash' : 'fa-eye' }}"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="text-center py-5">
                                    <div class="d-inline-grid place-items-center rounded-4 bg-success-subtle text-success mb-3" style="width: 64px; height: 64px;">
                                        <i class="fa-solid fa-seedling fa-xl"></i>
                                    </div>
                                    <h4 class="h6 fw-bold">لا توجد مشاركات مطابقة</h4>
                                    <p class="small text-muted mb-0">غيّر الفلاتر أو تأكد أن الطلاب أكملوا جلسات بنمط المزرعة العامة.</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if($publicProfiles->hasPages())
                <div class="p-3 border-top bg-light">
                    {{ $publicProfiles->links() }}
                </div>
            @endif
        </div>
    </section>
</div>
