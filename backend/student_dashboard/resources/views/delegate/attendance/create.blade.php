@extends('layouts.delegate')

@section('title', ($isUnofficial ?? false) ? 'رصد محاضرة غير رسمية' : 'رصد الحضور')

@section('content')

<div class="container" style="max-width: 100%;" x-data="attendancePage()" x-cloak>

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                {{ ($isUnofficial ?? false) ? 'رصد محاضرة غير رسمية' : 'رصد الحضور' }}
            </h1>
            <p style="color: var(--text-secondary);">
                @if(($isUnofficial ?? false))
                    الجلسة: <span style="font-weight: 700; color: var(--primary-color);">محاضرة مستقلة غير مرتبطة بمادة</span>
                @else
                    المادة: <span style="font-weight: 700; color: var(--primary-color);">{{ $subject->name }}</span> ({{ $subject->code }})
                @endif
            </p>
        </div>
        <a href="{{ route('delegate.attendance.index') }}" class="btn btn-secondary" style="display: flex; align-items: center; gap: 0.5rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="19" y1="12" x2="5" y2="12"></line>
                <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
            عودة للحضور
        </a>
    </div>

    <form id="attendance-form" action="{{ $formAction }}" method="POST">
        @csrf
        <input type="hidden" name="gender_filter" value="{{ $genderFilter ?? 'all' }}">

        @if(!($isUnofficial ?? false) && !empty($prefill['from_qr']))
        <input type="hidden" name="qr_session_id" value="{{ request('qr_session_id') }}">
        @endif

        @php
            $missingScanStudents = collect($qrVerification['missing_scan_students'] ?? []);
            $sampleCheckStudents = collect($qrVerification['sample_check_students'] ?? []);
            $verificationMap = $missingScanStudents
                ->mapWithKeys(fn ($student) => [$student['student_id'] => 'missing_scan'])
                ->merge($sampleCheckStudents->mapWithKeys(fn ($student) => [$student['student_id'] => 'sample_check']));
        @endphp

        @if(!($isUnofficial ?? false) && !empty($prefill['from_qr']) && ($missingScanStudents->isNotEmpty() || $sampleCheckStudents->isNotEmpty()))
        <div class="card" style="margin-bottom: 1.5rem; border: 1px solid #dbeafe; background: linear-gradient(180deg, #f8fbff 0%, #ffffff 100%);">
            <div style="display:flex; justify-content:space-between; gap:1rem; align-items:flex-start; flex-wrap:wrap; margin-bottom:1.25rem;">
                <div>
                    <h3 style="margin:0 0 0.45rem; font-size:1.08rem; font-weight:800; color:#0f172a;">مراجعة جلسة QR قبل الحفظ النهائي</h3>
                    <p style="margin:0; color:#64748b; line-height:1.8;">
                        راجع الطلاب الذين لم يمسحوا الباركود أولًا، ثم عينة التحقق 2% من الماسحين، وبعدها عدّل الحالات داخل الجدول قبل الحفظ.
                    </p>
                </div>
                <div style="display:flex; gap:0.75rem; flex-wrap:wrap;">
                    <div style="min-width:140px; padding:0.9rem 1rem; border-radius:16px; background:#eff6ff;">
                        <div style="font-size:0.78rem; color:#64748b; font-weight:700;">غير الماسحين</div>
                        <div style="font-size:1.5rem; font-weight:900; color:#1d4ed8;">{{ $missingScanStudents->count() }}</div>
                    </div>
                    <div style="min-width:140px; padding:0.9rem 1rem; border-radius:16px; background:#ecfdf5;">
                        <div style="font-size:0.78rem; color:#64748b; font-weight:700;">عينة التحقق</div>
                        <div style="font-size:1.5rem; font-weight:900; color:#047857;">{{ $sampleCheckStudents->count() }}</div>
                    </div>
                </div>
            </div>

            <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(320px, 1fr)); gap:1rem;">
                <div style="border:1px solid #e2e8f0; border-radius:18px; overflow:hidden;">
                    <div style="padding:0.9rem 1rem; background:#f8fafc; font-weight:800; color:#0f172a;">طلاب لم يمسحوا QR</div>
                    <div style="max-height:220px; overflow:auto;">
                        @forelse($missingScanStudents as $student)
                            <div style="display:flex; justify-content:space-between; gap:0.75rem; align-items:center; padding:0.85rem 1rem; border-top:1px solid #f1f5f9;">
                                <div>
                                    <div style="font-weight:700; color:#0f172a;">{{ $student['name'] }}</div>
                                    <div style="font-family:monospace; font-size:0.8rem; color:#64748b;">{{ $student['student_number'] ?: 'بدون رقم قيد' }}</div>
                                </div>
                                <span style="padding:0.35rem 0.65rem; border-radius:999px; background:#fee2e2; color:#b91c1c; font-size:0.75rem; font-weight:800;">تأكيد غياب / تعديل</span>
                            </div>
                        @empty
                            <div style="padding:1rem; color:#64748b;">لا توجد حالات في هذه القائمة.</div>
                        @endforelse
                    </div>
                </div>

                <div style="border:1px solid #e2e8f0; border-radius:18px; overflow:hidden;">
                    <div style="padding:0.9rem 1rem; background:#f8fafc; font-weight:800; color:#0f172a;">عينة تحقق من الماسحين</div>
                    <div style="max-height:220px; overflow:auto;">
                        @forelse($sampleCheckStudents as $student)
                            <div style="display:flex; justify-content:space-between; gap:0.75rem; align-items:center; padding:0.85rem 1rem; border-top:1px solid #f1f5f9;">
                                <div>
                                    <div style="font-weight:700; color:#0f172a;">{{ $student['name'] }}</div>
                                    <div style="font-family:monospace; font-size:0.8rem; color:#64748b;">{{ $student['student_number'] ?: 'بدون رقم قيد' }}</div>
                                </div>
                                <span style="padding:0.35rem 0.65rem; border-radius:999px; background:#dcfce7; color:#166534; font-size:0.75rem; font-weight:800;">تأكيد حضور</span>
                            </div>
                        @empty
                            <div style="padding:1rem; color:#64748b;">لا توجد حالات في هذه القائمة.</div>
                        @endforelse
                    </div>
                </div>
            </div>
        </div>
        @endif

        <!-- Date Selection Card -->
        <div class="card" style="margin-bottom: 1.5rem;">
            <div style="display: flex; flex-wrap: wrap; gap: 1.5rem; align-items: flex-end;">

                <!-- Date Input -->
                <div style="flex: 1; min-width: 200px;">
                    <label for="date" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">تاريخ المحاضرة:</label>
                    <input type="date" name="date" id="date" value="{{ $prefill['date'] ?? date('Y-m-d') }}" required class="form-control" style="width: 100%;">
                </div>

                <!-- Lecture Title Input -->
                <div style="flex: 2; min-width: 300px;">
                    <label for="title" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">عنوان المحاضرة:</label>
                    <input type="text" name="title" id="title" value="{{ $prefill['title'] ?? old('title') }}" placeholder="مثال: مقدمة في الفيزياء، القانون الأول..." required class="form-control" style="width: 100%;">
                </div>

                <!-- Lecture Number Input -->
                <div style="flex: 0 0 150px;">
                    <label for="lecture_number" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">رقم المحاضرة:</label>
                    <input type="text" name="lecture_number" id="lecture_number" value="{{ $prefill['lecture_number'] ?? old('lecture_number') }}" placeholder="مثال: 1، 2..." class="form-control" style="width: 100%;">
                </div>

                <div style="flex: 0 0 180px;">
                    <label for="lecture_type" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">نوع المحاضرة:</label>
                    @if(($isUnofficial ?? false))
                        <input type="hidden" name="lecture_type" id="lecture_type" value="special">
                        <input type="text" class="form-control" value="محاضرة غير رسمية مستقلة" readonly style="width: 100%; background: #fff7ed; color: #c2410c; font-weight: 700;">
                    @else
                        <select name="lecture_type" id="lecture_type" class="form-control" style="width: 100%;">
                            <option value="official" {{ ($prefill['lecture_type'] ?? old('lecture_type', 'official')) === 'official' ? 'selected' : '' }}>محاضرة رسمية</option>
                            <option value="special" {{ ($prefill['lecture_type'] ?? old('lecture_type')) === 'special' ? 'selected' : '' }}>محاضرة خاصة سريعة</option>
                        </select>
                    @endif
                </div>

                <!-- Start Time Input (Optional) -->
                <div style="flex: 0 0 150px;">
                    <label for="start_time" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">وقت البداية: <span style="color: var(--text-secondary); font-size: 0.8rem;">(اختياري)</span></label>
                    <input type="time" name="start_time" id="start_time" value="{{ $prefill['start_time'] ?? old('start_time') }}" class="form-control" style="width: 100%;">
                </div>

                <!-- End Time Input (Optional) -->
                <div style="flex: 0 0 150px;">
                    <label for="end_time" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">وقت الانتهاء: <span style="color: var(--text-secondary); font-size: 0.8rem;">(اختياري)</span></label>
                    <input type="time" name="end_time" id="end_time" value="{{ $prefill['end_time'] ?? old('end_time') }}" class="form-control" style="width: 100%;">
                </div>

            </div>
        </div>

        <div class="card" style="margin-bottom: 1.5rem; background: #f8fafc; border: 1px solid #e2e8f0;">
            <div style="display: flex; justify-content: space-between; gap: 1rem; align-items: end; flex-wrap: wrap;">
                <div style="flex: 0 0 240px;">
                    <label for="gender_filter" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">فرز التحضير</label>
                    <select id="gender_filter" class="form-control" onchange="updateAttendanceFilter(this.value)">
                        <option value="all" {{ ($genderFilter ?? 'all') === 'all' ? 'selected' : '' }}>الكل</option>
                        <option value="male" {{ ($genderFilter ?? 'all') === 'male' ? 'selected' : '' }}>الأولاد فقط</option>
                        <option value="female" {{ ($genderFilter ?? 'all') === 'female' ? 'selected' : '' }}>البنات فقط</option>
                    </select>
                </div>
                <div style="flex: 1; min-width: 260px; color: var(--text-secondary); font-size: 0.9rem;">
                    يمكنك تحضير مجموعة واحدة الآن ثم إكمال المجموعة الأخرى لاحقًا، وسيتم دمج السجلات لنفس المحاضرة.
                </div>
            </div>
        </div>

        <!-- Student List Card -->
        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary); display: flex; align-items: center; gap: 0.5rem; margin: 0;">
                    <span>قائمة الطلاب</span>
                    <span class="badge badge-info">{{ $students->count() }} طالب</span>
                </h3>

                <!-- Bulk Selection Buttons -->
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    @unless($isUnofficial ?? false)
                        <button type="button" @click="openQrModal()" class="btn btn-sm" style="background: #6366f1; color: white; display: flex; align-items: center; gap: 0.3rem; padding: 0.4rem 0.8rem; font-size: 0.85rem;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="3" width="7" height="7"></rect>
                                <rect x="14" y="3" width="7" height="7"></rect>
                                <rect x="14" y="14" width="7" height="7"></rect>
                            </svg>
                            تحضير بـ QR
                        </button>
                        <button type="button" @click="openDesktopPairingModal()" class="btn btn-sm" style="background: #0f172a; color: white; display: flex; align-items: center; gap: 0.3rem; padding: 0.4rem 0.8rem; font-size: 0.85rem;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="2.5" y="4" width="19" height="12" rx="2"></rect>
                                <path d="M8 20h8"></path>
                                <path d="M12 16v4"></path>
                            </svg>
                            ربط تطبيق العرض
                        </button>
                    @endunless
                    <button type="button" onclick="selectAll('present')" class="btn btn-sm" style="background: var(--success-color); color: white; display: flex; align-items: center; gap: 0.3rem; padding: 0.4rem 0.8rem; font-size: 0.85rem;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                        الكل حاضر
                    </button>
                    <button type="button" onclick="selectAll('absent')" class="btn btn-sm" style="background: var(--danger-color); color: white; display: flex; align-items: center; gap: 0.3rem; padding: 0.4rem 0.8rem; font-size: 0.85rem;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                        الكل غائب
                    </button>
                    <button type="button" onclick="selectAll('late')" class="btn btn-sm" style="background: var(--warning-color); color: white; display: flex; align-items: center; gap: 0.3rem; padding: 0.4rem 0.8rem; font-size: 0.85rem;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12 6 12 12 16 14"></polyline>
                        </svg>
                        الكل متأخر
                    </button>
                </div>
            </div>

            @if($students->isEmpty())
            <div style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                لا يوجد طلاب مسجلين في هذه الدفعة حالياً.
            </div>
            @else
            <div class="table-container">
                <div class="table-responsive">
<table style="width: 100%; border-collapse: separate; border-spacing: 0;">
                    <thead>
                        <tr style="background-color: #f8fafc; text-align: right;">
                            <th style="padding: 1rem; border-bottom: 1px solid var(--border-color); width: 60px;">#</th>
                            <th style="padding: 1rem; border-bottom: 1px solid var(--border-color);">الطالب</th>
                            <th style="padding: 1rem; border-bottom: 1px solid var(--border-color);">الجنس</th>
                            <th style="padding: 1rem; border-bottom: 1px solid var(--border-color); text-align: center;">حاضر</th>
                            <th style="padding: 1rem; border-bottom: 1px solid var(--border-color); text-align: center;">غائب</th>
                            <th style="padding: 1rem; border-bottom: 1px solid var(--border-color); text-align: center;">تأخر</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($students as $index => $student)
                        @php
                        $record = $attendanceRecords ? ($attendanceRecords[$student->id] ?? null) : null;
                        // Default logic: records are respected in review mode, otherwise students start absent.
                        $defaultStatus = 'absent';
                        $status = $record ? $record->status : $defaultStatus;
                        $verificationType = $verificationMap[$student->id] ?? null;
                        @endphp
                        <tr style="border-bottom: 1px solid #f1f5f9; background: {{ $verificationType === 'missing_scan' ? '#fff7ed' : ($verificationType === 'sample_check' ? '#ecfdf5' : 'transparent') }};">
                            <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; color: var(--text-secondary);">{{ $index + 1 }}</td>
                            <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">
                                <div style="font-weight: 600; display: flex; align-items: center; gap: 0.5rem;">
                                    {{ $student->name }}
                                    @if($record && $record->status == 'present')
                                    <span style="font-size: 0.7rem; background-color: #dcfce7; color: #166534; padding: 2px 6px; border-radius: 4px; border: 1px solid #bbf7d0;">QR</span>
                                    @endif
                                    @if($verificationType === 'missing_scan')
                                    <span style="font-size: 0.7rem; background-color: #ffedd5; color: #c2410c; padding: 2px 6px; border-radius: 4px; border: 1px solid #fdba74;">تحقق غياب</span>
                                    @elseif($verificationType === 'sample_check')
                                    <span style="font-size: 0.7rem; background-color: #d1fae5; color: #047857; padding: 2px 6px; border-radius: 4px; border: 1px solid #86efac;">عينة 2%</span>
                                    @endif
                                </div>
                                <div style="font-family: monospace; font-size: 0.8rem; color: var(--text-secondary);">{{ $student->student_number }}</div>
                            </td>
                            <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">
                                <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.3rem 0.7rem; border-radius: 999px; background: {{ $student->gender === 'female' ? '#fdf2f8' : '#eff6ff' }}; color: {{ $student->gender === 'female' ? '#db2777' : '#2563eb' }}; font-size: 0.78rem; font-weight: 700;">
                                    {{ $student->gender === 'female' ? 'أنثى' : 'ذكر' }}
                                </span>
                            </td>

                            <!-- Radio Buttons -->
                            <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;">
                                <label class="status-label present">
                                    <input type="radio" name="attendance[{{ $student->id }}]" value="present" {{ $status == 'present' ? 'checked' : '' }}>
                                    <span class="indicator"></span>
                                </label>
                            </td>
                            <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;">
                                <label class="status-label absent">
                                    <input type="radio" name="attendance[{{ $student->id }}]" value="absent" {{ $status == 'absent' ? 'checked' : '' }}>
                                    <span class="indicator"></span>
                                </label>
                            </td>
                            <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;">
                                <label class="status-label late">
                                    <input type="radio" name="attendance[{{ $student->id }}]" value="late" {{ $status == 'late' ? 'checked' : '' }}>
                                    <span class="indicator"></span>
                                </label>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
</div>
            </div>

            <div style="margin-top: 2rem; padding-top: 1rem; border-top: 1px solid var(--border-color);">

                <!-- Lecture Notes -->
                <div style="margin-bottom: 1.5rem;">
                    <label for="description" style="font-weight: 700; color: var(--text-primary); display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary-color)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                            <line x1="16" y1="13" x2="8" y2="13"></line>
                            <line x1="16" y1="17" x2="8" y2="17"></line>
                            <polyline points="10 9 9 9 8 9"></polyline>
                        </svg>
                        ملاحظات المحاضرة (اختياري)
                    </label>
                    <textarea name="description" id="description" rows="3" class="form-control"
                        style="width: 100%; resize: vertical; border-radius: 8px; border: 1px solid #e2e8f0; padding: 0.75rem;"
                        placeholder="أكتب هنا أي ملاحظات مهمة من الدكتور تخص هذه المحاضرة... مثلاً: الفصل الثالث مهم للاختبار، يجب مراجعة التمارين...">{{ old('description') }}</textarea>
                    <p style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.25rem;">
                        ستظهر هذه الملاحظات للطلاب في صفحة المحاضرات وفي مركز الدراسة
                    </p>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; padding: 0.75rem; font-size: 1rem; font-weight: 700;">
                    حفظ سجل الحضور
                </button>
            </div>
            @endif
        </div>
    </form>

    @if($attendanceRecords && $attendanceRecords->isNotEmpty())
        <form action="{{ route('delegate.attendance-edit-requests.store') }}" method="POST" class="card" style="margin-top: 1.5rem; border: 1px solid #fed7aa; background: #fff7ed;">
            @csrf
            @if($subject)
                <input type="hidden" name="subject_id" value="{{ $subject->id }}">
            @endif
            <input type="hidden" name="date" value="{{ $prefill['date'] ?? request('date') ?? date('Y-m-d') }}">
            <input type="hidden" name="title" value="{{ $prefill['title'] ?? old('title') }}">
            @if(request('lecture_id'))
                <input type="hidden" name="lecture_id" value="{{ request('lecture_id') }}">
            @endif
            @if(request('qr_session_id'))
                <input type="hidden" name="qr_attendance_session_id" value="{{ request('qr_session_id') }}">
            @endif

            <div style="display:grid; grid-template-columns:1fr auto; gap:1rem; align-items:end;">
                <div>
                    <label for="attendance_edit_reason" style="font-weight: 800; color: #9a3412; display:block; margin-bottom:0.45rem;">طلب فتح تعديل الحضور</label>
                    <textarea id="attendance_edit_reason" name="reason" rows="2" required class="form-control" style="width:100%;" placeholder="اكتب سبب طلب فتح التعديل من الأدمن الرئيسي..."></textarea>
                </div>
                <button type="submit" class="btn" style="background:#f97316; color:white; font-weight:800; padding:0.75rem 1rem;">إرسال الطلب</button>
            </div>
        </form>
    @endif

    <!-- QR Code Modal (Integrated into Create Page) -->
    @unless($isUnofficial ?? false)
    <div x-show="showQrModal" style="display: none;"
        class="qr-modal-overlay"
        x-transition.opacity>
        <div @click.away="closeQrModal()"
            style="background: white; border-radius: 16px; width: 100%; max-width: 480px; padding: 2rem; max-height: 90vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);">

            <!-- QR Active Phase -->
            <div style="text-align: center;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.5rem;">
                    <h3 style="margin: 0; font-size: 1.15rem; font-weight: 700;">تحضير سريع بـ QR</h3>
                    <button @click="closeQrModal()" style="background: none; border: none; cursor: pointer; padding: 4px; color: var(--text-secondary);">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                    </button>
                </div>

                {{-- Loading State --}}
                <div x-show="qrLoading" style="padding: 3rem; display: none;">
                    <div style="color: var(--text-secondary); font-size: 0.95rem;">جاري بدء الجلسة...</div>
                </div>

                {{-- Active QR State --}}
                <div x-show="qrActive && !qrLoading" style="display: none;">
                    <p style="color: var(--text-secondary); margin-bottom: 1rem; font-size: 0.9rem;">اعرض الكود للطلاب لمسحه — يتجدد كل 10 ثواني</p>

                    <!-- QR Code Display -->
                    <div id="qrcode" style="display: flex; justify-content: center; margin-bottom: 1.5rem;"></div>

                    <!-- Timer Bar -->
                    <div style="height: 4px; background: #e2e8f0; border-radius: 2px; margin-bottom: 1.5rem; overflow: hidden;">
                        <div style="height: 100%; background: #6366f1; transition: width 0.1s linear;" :style="'width: ' + timerWidth + '%'"></div>
                    </div>

                    <!-- Stats -->
                    <div style="display: flex; justify-content: center; gap: 2rem; margin-bottom: 1.5rem; background: #f8fafc; padding: 1rem; border-radius: 8px;">
                        <div>
                            <div style="font-size: 1.5rem; font-weight: 700; color: #10b981;" x-text="scannedCount"></div>
                            <div style="font-size: 0.85rem; color: var(--text-secondary);">حضور</div>
                        </div>
                        <div>
                            <div style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);" x-text="totalStudents"></div>
                            <div style="font-size: 0.85rem; color: var(--text-secondary);">إجمالي الطلاب</div>
                        </div>
                    </div>

                    <button @click="finalizeQrSession()" class="btn btn-danger" :disabled="qrFinalizing"
                        style="width: 100%; padding: 0.65rem; font-weight: 600;">
                        <span x-show="qrFinalizing" style="display: none;">جاري الإنهاء...</span>
                        <span x-show="!qrFinalizing" style="display: inline;">إنهاء المسح وتعبئة القائمة</span>
                    </button>
                </div>

                {{-- Error State --}}
                <div x-show="qrError" style="padding: 2rem; display: none;">
                    <div style="color: var(--danger-color); font-size: 0.95rem; margin-bottom: 1rem;" x-text="qrError"></div>
                    <button @click="showQrModal = false" class="btn btn-secondary">إغلاق</button>
                </div>
            </div>
        </div>
    </div>
    @endunless

    @unless($isUnofficial ?? false)
    <div x-show="showDesktopPairingModal" style="display: none;" class="qr-modal-overlay" x-transition.opacity>
        <div @click.away="closeDesktopPairingModal()" style="background: white; border-radius: 18px; width: 100%; max-width: 520px; padding: 2rem; max-height: 90vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(15, 23, 42, 0.28);">
            <div style="display:flex; align-items:center; justify-content:space-between; gap:1rem; margin-bottom:1.25rem;">
                <div>
                    <h3 style="margin:0 0 0.35rem; font-size:1.12rem; font-weight:800; color:#0f172a;">ربط تطبيق العرض</h3>
                    <p style="margin:0; color:#64748b; line-height:1.8;">أدخل هذا الرمز في تطبيق Windows لبدء إنشاء وعرض QR من الشاشة الكبيرة.</p>
                </div>
                <button type="button" @click="closeDesktopPairingModal()" style="background:none; border:none; cursor:pointer; color:#64748b; font-size:1.4rem; line-height:1;">×</button>
            </div>

            <div x-show="desktopPairingLoading" style="display:none; padding:2rem 1rem; text-align:center; color:#64748b;">جارٍ إنشاء رمز الربط...</div>

            <div x-show="desktopPairingError" style="display:none; margin-bottom:1rem; padding:0.85rem 1rem; border-radius:14px; background:#fff1f2; color:#be123c; border:1px solid #fecdd3;" x-text="desktopPairingError"></div>

            <div x-show="!desktopPairingLoading && desktopPairingCode" style="display:none;">
                <div style="padding:1.25rem; border-radius:18px; background:linear-gradient(135deg, #0f172a 0%, #1e293b 100%); color:white; text-align:center; margin-bottom:1rem;">
                    <div style="font-size:0.82rem; opacity:0.8; margin-bottom:0.45rem;">رمز الربط</div>
                    <div style="font-size:2rem; font-weight:900; letter-spacing:0.18em;" x-text="desktopPairingCode"></div>
                    <div style="margin-top:0.65rem; font-size:0.82rem; opacity:0.78;">ينتهي عند <span x-text="desktopPairingExpiresAt"></span></div>
                </div>

                <div style="display:flex; gap:0.75rem; flex-wrap:wrap; margin-bottom:1rem;">
                    <button type="button" @click="copyDesktopPairingCode()" class="btn btn-sm" style="background:#2563eb; color:white; flex:1; min-width:160px;">نسخ الرمز</button>
                    <button type="button" @click="openDesktopPairingModal()" class="btn btn-sm" style="background:#e2e8f0; color:#0f172a; flex:1; min-width:160px;">تحديث الرمز</button>
                </div>

                <div style="padding:1rem 1.1rem; border-radius:16px; background:#f8fafc; border:1px solid #e2e8f0; color:#475569; line-height:1.85;">
                    <div style="font-weight:800; color:#0f172a; margin-bottom:0.5rem;">خطوات سريعة</div>
                    <div>1. افتح تطبيق العرض على الكمبيوتر.</div>
                    <div>2. أدخل الرمز كما هو.</div>
                    <div>3. اختر المادة ثم ابدأ الجلسة لعرض QR على البروجكتر.</div>
                </div>
            </div>
        </div>
    </div>
    @endunless

</div>

<!-- Overwrite Confirmation Modal -->
<div id="overwrite-modal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000; justify-content: center; align-items: center;">
    <div style="background: white; padding: 2rem; border-radius: 12px; width: 90%; max-width: 500px; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);">
        <h3 style="margin-top: 0; font-size: 1.25rem; font-weight: 700; color: var(--text-primary);">تنبيه: تحضير مكرر ⚠️</h3>
        <p style="color: var(--text-secondary); margin: 1rem 0;">
            تم العثور على سجل حضور سابق لهذا اليوم بعنوان: <br>
            <strong id="existing-title" style="color: var(--primary-color);"></strong>
        </p>
        <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
            هل تريد استبدال البيانات السابقة بالبيانات الجديدة؟
        </p>
        <div style="display: flex; gap: 1rem; justify-content: flex-end;">
            <button onclick="cancelOverwrite()" class="btn btn-secondary">إلغاء</button>
            <button onclick="confirmOverwrite()" class="btn btn-primary">نعم، استبدال</button>
        </div>
    </div>

<style>
    /* QR Modal Overlay - centered */
    .qr-modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.6);
        z-index: 9999;
        display: flex !important;
        align-items: center;
        justify-content: center;
    }
    .qr-modal-overlay[style*="display: none"] {
        display: none !important;
    }

    /* Custom Radio Styling */
    .status-label {
        display: inline-block;
        cursor: pointer;
        position: relative;
        width: 24px;
        height: 24px;
    }

    .status-label input {
        display: none;
    }

    .status-label .indicator {
        position: absolute;
        top: 0;
        left: 0;
        width: 24px;
        height: 24px;
        border-radius: 50%;
        border: 2px solid #cbd5e1;
        background: white;
        transition: all 0.2s;
    }

    /* Hover effects */
    .status-label:hover .indicator {
        border-color: var(--text-secondary);
    }

    /* Checked States */
    .status-label.present input:checked+.indicator {
        background-color: var(--success-color);
        border-color: var(--success-color);
        box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
    }

    .status-label.absent input:checked+.indicator {
        background-color: var(--danger-color);
        border-color: var(--danger-color);
        box-shadow: 0 0 0 2px rgba(220, 38, 38, 0.2);
    }

    .status-label.late input:checked+.indicator {
        background-color: var(--warning-color);
        border-color: var(--warning-color);
        box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2);
    }

    .status-label.excused input:checked+.indicator {
        background-color: var(--info-color);
        border-color: var(--info-color);
        box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
    }

    /* Inner dot for generic checked (optional, but solid color usually clearer) */
    .status-label input:checked+.indicator::after {
        content: '';
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 10px;
        height: 10px;
        background: white;
        border-radius: 50%;
        opacity: 0.8;
    }
</style>

<!-- QR Code Library -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>

<script>
    function attendancePage() {
        return {
            showQrModal: false,
            qrLoading: false,
            qrActive: false,
            qrFinalizing: false,
            qrError: '',
            showDesktopPairingModal: false,
            desktopPairingLoading: false,
            desktopPairingError: '',
            desktopPairingCode: '',
            desktopPairingRawCode: '',
            desktopPairingExpiresAt: '',
            sessionId: null,
            qrObject: null,
            timerWidth: 100,
            scannedCount: 0,
            totalStudents: {{ $students->count() }},
            subjectId: @json($subject?->id),
            tokenInterval: null,
            statusInterval: null,
            animationInterval: null,

            openQrModal() {
                const title = document.getElementById('title').value;
                if (!title) {
                    showToast('يرجى إدخال عنوان المحاضرة أولاً ⚠️');
                    document.getElementById('title').focus();
                    return;
                }

                this.showQrModal = true;
                this.qrError = '';
                this.qrActive = false;
                this.qrLoading = true;
                this.scannedCount = 0;

                this.startQrSession();
            },

            closeQrModal() {
                if (this.qrActive) {
                    if (!confirm('هل أنت متأكد من إغلاق نافذة QR؟ سيتم إيقاف الجلسة.')) return;
                    this.stopIntervals();
                }
                this.showQrModal = false;
                this.qrActive = false;
            },

            async openDesktopPairingModal() {
                this.showDesktopPairingModal = true;
                this.desktopPairingLoading = true;
                this.desktopPairingError = '';
                this.desktopPairingCode = '';
                this.desktopPairingRawCode = '';
                this.desktopPairingExpiresAt = '';
                const sessionPayload = {
                    device_name: 'Classroom Display',
                    subject_id: this.subjectId,
                    date: document.getElementById('date').value,
                    title: document.getElementById('title').value,
                    lecture_number: document.getElementById('lecture_number').value || null,
                };
                if (!sessionPayload.date || !sessionPayload.title) {
                    this.desktopPairingLoading = false;
                    this.desktopPairingError = 'أدخل تاريخ المحاضرة وعنوانها قبل إنشاء رمز الربط.';
                    return;
                }

                try {
                    const response = await fetch('{{ route('delegate.desktop.pairing-code') }}', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': '{{ csrf_token() }}'
                        },
                        body: JSON.stringify(sessionPayload)
                    });

                    const data = await response.json();

                    if (!response.ok || !data.success) {
                        this.desktopPairingError = data.message || 'تعذر إنشاء رمز الربط.';
                        return;
                    }

                    this.desktopPairingCode = data.data.display_code || data.data.code || '';
                    this.desktopPairingRawCode = data.data.code || '';
                    this.desktopPairingExpiresAt = data.data.expires_at
                        ? new Date(data.data.expires_at).toLocaleTimeString('ar-YE', { hour: '2-digit', minute: '2-digit' })
                        : '';
                } catch (error) {
                    console.error(error);
                    this.desktopPairingError = 'تعذر الاتصال بالخادم أثناء إنشاء رمز الربط.';
                } finally {
                    this.desktopPairingLoading = false;
                }
            },

            closeDesktopPairingModal() {
                this.showDesktopPairingModal = false;
            },

            async copyDesktopPairingCode() {
                const value = this.desktopPairingRawCode || this.desktopPairingCode;
                if (!value) return;

                try {
                    await navigator.clipboard.writeText(value);
                    showToast('تم نسخ رمز الربط.');
                } catch (error) {
                    console.error(error);
                    showToast('تعذر نسخ الرمز تلقائيًا.');
                }
            },

            async startQrSession() {
                const formData = {
                    subject_id: this.subjectId,
                    date: document.getElementById('date').value,
                    title: document.getElementById('title').value,
                    lecture_number: document.getElementById('lecture_number').value || null,
                    lecture_type: document.getElementById('lecture_type').value || 'official',
                };

                try {
                    const response = await fetch('/api/qr-attendance/start', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': '{{ csrf_token() }}'
                        },
                        body: JSON.stringify(formData)
                    });

                    const data = await response.json();

                    if (!response.ok) {
                        this.qrLoading = false;
                        this.qrError = data.message || 'حدث خطأ ما';
                        return;
                    }

                    this.sessionId = data.session_id;
                    this.qrLoading = false;
                    this.qrActive = true;

                    // Initialize QR code
                    this.$nextTick(() => {
                        const qrContainer = document.getElementById('qrcode');
                        if (qrContainer) qrContainer.innerHTML = '';
                        this.qrObject = new QRCode(document.getElementById("qrcode"), {
                            text: data.token,
                            width: 256,
                            height: 256,
                            colorDark: "#000000",
                            colorLight: "#ffffff",
                            correctLevel: QRCode.CorrectLevel.H
                        });

                        this.startRotation();
                        this.startPollingStatus();
                    });

                } catch (error) {
                    console.error(error);
                    this.qrLoading = false;
                    this.qrError = 'حدث خطأ في الاتصال بالخادم';
                }
            },

            startRotation() {
                let seconds = 10;
                this.timerWidth = 100;

                // Token rotation every 10 seconds
                this.tokenInterval = setInterval(async () => {
                    this.timerWidth = 100;
                    seconds = 10;

                    try {
                        const response = await fetch(`/api/qr-attendance/${this.sessionId}/token`);
                        const data = await response.json();

                        if (response.ok && this.qrObject) {
                            this.qrObject.clear();
                            this.qrObject.makeCode(data.token);
                        }
                    } catch (e) {
                        console.error('Failed to rotate token', e);
                    }
                }, 10000);

                // Animation interval for progress bar (saved reference for cleanup)
                this.animationInterval = setInterval(() => {
                    seconds -= 0.1;
                    if (seconds < 0) seconds = 0;
                    this.timerWidth = (seconds / 10) * 100;
                }, 100);
            },

            startPollingStatus() {
                this.statusInterval = setInterval(async () => {
                    try {
                        const response = await fetch(`/api/qr-attendance/${this.sessionId}/status`);
                        const data = await response.json();

                        if (response.ok) {
                            this.scannedCount = data.scanned_count;
                            this.totalStudents = data.total_students;
                        }
                    } catch (e) {
                        console.error('Failed to fetch status', e);
                    }
                }, 3000);
            },

            stopIntervals() {
                if (this.tokenInterval) clearInterval(this.tokenInterval);
                if (this.statusInterval) clearInterval(this.statusInterval);
                if (this.animationInterval) clearInterval(this.animationInterval);
                this.tokenInterval = null;
                this.statusInterval = null;
                this.animationInterval = null;
            },

            async finalizeQrSession() {
                if (!confirm('هل أنت متأكد من إنهاء جلسة QR؟ سيتم تجهيز قائمة غير الماسحين وعينة التحقق لمراجعتها قبل الحفظ النهائي.')) return;

                this.qrFinalizing = true;
                this.stopIntervals();

                try {
                    // First finalize the session
                    const finalizeResponse = await fetch(`/api/qr-attendance/${this.sessionId}/finalize`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': '{{ csrf_token() }}'
                        }
                    });

                    const finalizeData = await finalizeResponse.json();

                    if (!finalizeResponse.ok) {
                        this.qrError = finalizeData.message || 'حدث خطأ أثناء الإنهاء';
                        this.qrFinalizing = false;
                        this.qrActive = false;
                        return;
                    }

                    // Then fetch the final status to update the attendance form
                    const statusResponse = await fetch(`/api/qr-attendance/${this.sessionId}/status`);
                    const statusData = await statusResponse.json();

                    if (statusResponse.ok && statusData.students) {
                        // Update radio buttons based on QR scan results
                        statusData.students.forEach(student => {
                            const presentRadio = document.querySelector(`input[name="attendance[${student.id}]"][value="present"]`);
                            const absentRadio = document.querySelector(`input[name="attendance[${student.id}]"][value="absent"]`);

                            if (student.status === 'present' && presentRadio) {
                                presentRadio.checked = true;
                            } else if (absentRadio) {
                                absentRadio.checked = true;
                            }
                        });

                        const verification = statusData.verification || { summary: { missing_scan_count: 0, sample_check_count: 0 } };
                        showToast(`✅ تم تجهيز المراجعة: ${verification.summary.missing_scan_count} غير ماسح، و${verification.summary.sample_check_count} ضمن عينة التحقق.`);
                    }

                    // Add hidden field for QR session tracking
                    let hiddenInput = document.querySelector('input[name="qr_session_id"]');
                    if (!hiddenInput) {
                        hiddenInput = document.createElement('input');
                        hiddenInput.type = 'hidden';
                        hiddenInput.name = 'qr_session_id';
                        document.getElementById('attendance-form').appendChild(hiddenInput);
                    }
                    hiddenInput.value = this.sessionId;

                    // Close modal
                    this.showQrModal = false;
                    this.qrActive = false;
                    this.qrFinalizing = false;

                } catch (error) {
                    console.error(error);
                    this.qrError = 'حدث خطأ أثناء الإنهاء';
                    this.qrFinalizing = false;
                    this.qrActive = false;
                }
            }
        }
    }

    function selectAll(status) {
        // Get all radio buttons with the specified value
        const radios = document.querySelectorAll('input[type="radio"][value="' + status + '"]');
        radios.forEach(function(radio) {
            radio.checked = true;
        });

        // Show feedback toast
        const messages = {
            'present': 'تم تحديد جميع الطلاب كـ حاضرين ✓',
            'absent': 'تم تحديد جميع الطلاب كـ غائبين ✗',
            'late': 'تم تحديد جميع الطلاب كـ متأخرين ⏱'
        };

        showToast(messages[status]);
    }

    function updateAttendanceFilter(value) {
        const url = new URL(window.location.href);
        url.searchParams.set('gender_filter', value);
        window.location.href = url.toString();
    }

    function showToast(message) {
        // Create toast element if not exists
        let toast = document.getElementById('bulk-toast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'bulk-toast';
            toast.style.cssText = 'position: fixed; bottom: 2rem; left: 50%; transform: translateX(-50%); background: #1e293b; color: white; padding: 0.75rem 1.5rem; border-radius: 8px; font-size: 0.9rem; z-index: 1000; opacity: 0; transition: opacity 0.3s;';
            document.body.appendChild(toast);
        }

        toast.textContent = message;
        toast.style.opacity = '1';

        setTimeout(function() {
            toast.style.opacity = '0';
        }, 2000);
    }

    // Duplicate Check Logic
    const dateInput = document.getElementById('date');
    const titleInput = document.getElementById('title');
    const lectureNumberInput = document.getElementById('lecture_number');
    const modal = document.getElementById('overwrite-modal');
    const existingTitleSpan = document.getElementById('existing-title');
    let previousDate = dateInput.value;

    function checkAttendance() {
        const date = dateInput.value;
        if (!date) return;

        @if(!($isUnofficial ?? false))
        fetch(`{{ route('delegate.attendance.check', $subject->id) }}?date=${date}`)
            .then(response => response.json())
            .then(data => {
                if (data.exists) {
                    // Show warning
                    existingTitleSpan.textContent = data.title || 'بدون عنوان';
                    modal.style.display = 'flex';

                    // Pre-fill fields with existing data
                    if (data.title) titleInput.value = data.title;
                    if (data.lecture_number) lectureNumberInput.value = data.lecture_number;
                }
            })
            .catch(error => console.error('Error checking attendance:', error));
        @endif
    }

    @if(!($isUnofficial ?? false))
    dateInput.addEventListener('change', checkAttendance);

    if (dateInput.value) {
        checkAttendance();
    }
    @endif

    function confirmOverwrite() {
        modal.style.display = 'none';
        showToast('سيتم تحديث سجل الحضور والمحاضرة عند الحفظ.');
    }

    function cancelOverwrite() {
        modal.style.display = 'none';
        // If it was an accidentally selected date, maybe clear it?
        // But if it was the default today, clearing it is annoying.
        // Let's just notify.
        showToast('يرجى تغيير التاريخ لتجنب الاستبدال.');
    }
</script>

@endsection
