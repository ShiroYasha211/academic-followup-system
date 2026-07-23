@extends('layouts.doctor')

@section('title', 'رصد الحضور')

@section('content')
<div class="container" style="max-width: 100%;" x-data="attendancePage('{{ $genderFilter ?? 'all' }}')" x-cloak>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; gap: 1rem; flex-wrap: wrap;">
        <div>
            <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">رصد الحضور</h1>
            <p style="color: var(--text-secondary); margin: 0;">
                المادة: <span style="font-weight: 700; color: var(--primary-color);">{{ $subject->name }}</span> ({{ $subject->code }})
            </p>
        </div>
        <a href="{{ route('doctor.attendance.index') }}" class="btn btn-secondary">عودة للحضور</a>
    </div>

    <form id="attendance-form" action="{{ route('doctor.attendance.store', $subject->id) }}" method="POST">
        @csrf
        <input type="hidden" id="gender_filter_input" name="gender_filter" x-model="genderTab" value="{{ $genderFilter ?? 'all' }}">

        @if(!empty($prefill['from_qr']))
            <input type="hidden" name="qr_session_id" value="{{ request('qr_session_id') }}">
        @endif

        @php
            $missingScanStudents = collect($qrVerification['missing_scan_students'] ?? []);
            $sampleCheckStudents = collect($qrVerification['sample_check_students'] ?? []);
            $verificationMap = $missingScanStudents
                ->mapWithKeys(fn ($student) => [$student['student_id'] => 'missing_scan'])
                ->merge($sampleCheckStudents->mapWithKeys(fn ($student) => [$student['student_id'] => 'sample_check']));
        @endphp

        @if(!empty($prefill['from_qr']) && ($missingScanStudents->isNotEmpty() || $sampleCheckStudents->isNotEmpty()))
            <div class="card" style="margin-bottom: 1.5rem; border: 1px solid #dbeafe; background: linear-gradient(180deg, #f8fbff 0%, #ffffff 100%);">
                <div style="display:flex; justify-content:space-between; gap:1rem; align-items:flex-start; flex-wrap:wrap; margin-bottom:1.25rem;">
                    <div>
                        <h3 style="margin:0 0 0.45rem; font-size:1.08rem; font-weight:800; color:#0f172a;">مراجعة جلسة QR قبل الحفظ النهائي</h3>
                        <p style="margin:0; color:#64748b; line-height:1.8;">
                            ظهرت هنا قائمتان للمراجعة: الطلاب الذين لم يمسحوا الباركود، وعينة تحقق بنسبة 2% من الطلاب الذين مسحوا الباركود. راجعهم داخل الجدول قبل حفظ الحضور.
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

        <div class="card" style="margin-bottom: 1.5rem;">
            <div style="display: flex; flex-wrap: wrap; gap: 1.5rem; align-items: flex-end;">
                <div style="flex: 1; min-width: 200px;">
                    <label for="date" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">تاريخ المحاضرة:</label>
                    <input type="date" name="date" id="date" value="{{ $prefill['date'] ?? date('Y-m-d') }}" required class="form-control" style="width: 100%;">
                </div>

                <div style="flex: 2; min-width: 300px;">
                    <label for="title" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">عنوان المحاضرة:</label>
                    <input type="text" name="title" id="title" value="{{ $prefill['title'] ?? old('title') }}" placeholder="مثال: مراجعة الباب الأول" required class="form-control" style="width: 100%;">
                </div>

                <div style="flex: 0 0 150px;">
                    <label for="lecture_number" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">رقم المحاضرة:</label>
                    <input type="text" name="lecture_number" id="lecture_number" value="{{ $prefill['lecture_number'] ?? old('lecture_number') }}" placeholder="1، 2..." class="form-control" style="width: 100%;">
                </div>

                <div style="flex: 0 0 180px;">
                    <label for="lecture_type" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">نوع المحاضرة:</label>
                    <select name="lecture_type" id="lecture_type" class="form-control" style="width: 100%;">
                        <option value="official" {{ ($prefill['lecture_type'] ?? old('lecture_type', 'official')) === 'official' ? 'selected' : '' }}>محاضرة رسمية</option>
                        <option value="special" {{ ($prefill['lecture_type'] ?? old('lecture_type')) === 'special' ? 'selected' : '' }}>محاضرة خاصة سريعة</option>
                    </select>
                </div>

                <div style="flex: 0 0 150px;">
                    <label for="start_time" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">وقت البداية <span style="color: var(--text-secondary); font-size: 0.8rem;">(اختياري)</span></label>
                    <input type="time" name="start_time" id="start_time" value="{{ $prefill['start_time'] ?? old('start_time') }}" class="form-control" style="width: 100%;">
                </div>

                <div style="flex: 0 0 150px;">
                    <label for="end_time" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">وقت الانتهاء <span style="color: var(--text-secondary); font-size: 0.8rem;">(اختياري)</span></label>
                    <input type="time" name="end_time" id="end_time" value="{{ $prefill['end_time'] ?? old('end_time') }}" class="form-control" style="width: 100%;">
                </div>
            </div>
        </div>

        <div class="card" style="margin-bottom: 1.5rem; background: #f8fafc; border: 1px solid #e2e8f0;">
            <div style="display: flex; justify-content: space-between; gap: 1rem; align-items: end; flex-wrap: wrap;">
                <div style="flex: 1; min-width: 320px;">
                    <label style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.75rem;">فرز التحضير</label>
                    <div style="display: inline-flex; background: white; border: 1px solid #dbe4ee; border-radius: 12px; padding: 4px; gap: 4px; flex-wrap: wrap;">
                        <button type="button" @click="setGenderTab('all')" :class="genderTab === 'all' ? 'gender-tab active' : 'gender-tab'">الكل</button>
                        <button type="button" @click="setGenderTab('male')" :class="genderTab === 'male' ? 'gender-tab active' : 'gender-tab'">الأولاد</button>
                        <button type="button" @click="setGenderTab('female')" :class="genderTab === 'female' ? 'gender-tab active' : 'gender-tab'">البنات</button>
                    </div>
                </div>
                <div style="flex: 1; min-width: 260px; color: var(--text-secondary); font-size: 0.9rem;">
                    يمكنك تحضير الأولاد ثم الانتقال مباشرة إلى تبويب البنات بدون تحديث الصفحة أو فقدان البيانات.
                </div>
            </div>
        </div>

        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary); display: flex; align-items: center; gap: 0.5rem; margin: 0;">
                    <span>قائمة الطلاب</span>
                    <span class="badge badge-info" x-text="visibleStudentsLabel()"></span>
                </h3>

                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    <button type="button" @click="openDesktopPairingModal()" class="btn btn-sm" style="background: #0f172a; color: white;">ربط تطبيق العرض</button>
                    <button type="button" @click="openQrModal()" class="btn btn-sm" style="background: #6366f1; color: white;">تحضير بـ QR</button>
                    <button type="button" onclick="selectAll('present')" class="btn btn-sm" style="background: var(--success-color); color: white;">الكل حاضر</button>
                    <button type="button" onclick="selectAll('absent')" class="btn btn-sm" style="background: var(--danger-color); color: white;">الكل غائب</button>
                    <button type="button" onclick="selectAll('late')" class="btn btn-sm" style="background: var(--warning-color); color: white;">الكل متأخر</button>
                    <button type="button" onclick="selectAll('excused')" class="btn btn-sm" style="background: var(--info-color); color: white;">الكل بعذر</button>
                </div>
            </div>

            @if($students->isEmpty())
                <div style="text-align: center; padding: 3rem; color: var(--text-secondary);">لا يوجد طلاب مسجلين في هذا المستوى حالياً.</div>
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
                                    <th style="padding: 1rem; border-bottom: 1px solid var(--border-color); text-align: center;">بعذر</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($students as $index => $student)
                                    @php
                                        $record = $attendanceRecords ? ($attendanceRecords[$student->id] ?? null) : null;
                                        $defaultStatus = 'absent';
                                        $status = $record ? $record->status : $defaultStatus;
                                        $verificationType = $verificationMap[$student->id] ?? null;
                                    @endphp
                                    <tr x-show="shouldShowStudent('{{ $student->gender ?? 'male' }}')" style="border-bottom: 1px solid #f1f5f9; background: {{ $verificationType === 'missing_scan' ? '#fff7ed' : ($verificationType === 'sample_check' ? '#ecfdf5' : 'transparent') }};">
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; color: var(--text-secondary);">{{ $index + 1 }}</td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">
                                            <div style="font-weight: 600; display: flex; align-items: center; gap: 0.5rem;">
                                                {{ $student->name }}
                                                @if($record && $record->attendance_method === 'qr' && $record->status === 'present')
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
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;"><label class="status-label present"><input type="radio" name="attendance[{{ $student->id }}]" value="present" {{ $status == 'present' ? 'checked' : '' }}><span class="indicator"></span></label></td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;"><label class="status-label absent"><input type="radio" name="attendance[{{ $student->id }}]" value="absent" {{ $status == 'absent' ? 'checked' : '' }}><span class="indicator"></span></label></td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;"><label class="status-label late"><input type="radio" name="attendance[{{ $student->id }}]" value="late" {{ $status == 'late' ? 'checked' : '' }}><span class="indicator"></span></label></td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;"><label class="status-label excused"><input type="radio" name="attendance[{{ $student->id }}]" value="excused" {{ $status == 'excused' ? 'checked' : '' }}><span class="indicator"></span></label></td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>

                <div style="margin-top: 2rem; padding-top: 1rem; border-top: 1px solid var(--border-color);">
                    <div style="margin-bottom: 1.5rem;">
                        <label for="description" style="font-weight: 700; color: var(--text-primary); display: block; margin-bottom: 0.5rem;">ملاحظات المحاضرة (اختياري)</label>
                        <textarea name="description" id="description" rows="3" class="form-control" style="width: 100%; resize: vertical;" placeholder="أكتب أي ملاحظات مهمة تخص هذه المحاضرة...">{{ $prefill['description'] ?? old('description') }}</textarea>
                        <p style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.25rem;">ستظهر هذه الملاحظات للطلاب في صفحة المحاضرات.</p>
                    </div>
                    <button type="submit" class="btn btn-primary" style="width: 100%; padding: 0.75rem; font-size: 1rem; font-weight: 700;">حفظ سجل الحضور</button>
                </div>
            @endif
        </div>
    </form>

    @if($attendanceRecords && $attendanceRecords->isNotEmpty())
        <form action="{{ route('doctor.attendance-edit-requests.store') }}" method="POST" class="card" style="margin-top: 1.5rem; border: 1px solid #fed7aa; background: #fff7ed;">
            @csrf
            <input type="hidden" name="subject_id" value="{{ $subject->id }}">
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

    <div x-show="showQrModal" style="display: none;" class="qr-modal-overlay" x-transition.opacity>
        <div @click.away="closeQrModal()" style="background: white; border-radius: 16px; width: 100%; max-width: 480px; padding: 2rem; max-height: 90vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);">
            <div style="text-align: center;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.5rem;">
                    <h3 style="margin: 0; font-size: 1.15rem; font-weight: 700;">تحضير سريع بـ QR</h3>
                    <button @click="closeQrModal()" style="background: none; border: none; cursor: pointer; padding: 4px; color: var(--text-secondary);">×</button>
                </div>
                <div x-show="qrLoading" style="padding: 3rem; display: none;"><div style="color: var(--text-secondary); font-size: 0.95rem;">جاري بدء الجلسة...</div></div>
                <div x-show="qrActive && !qrLoading" style="display: none;">
                    <p style="color: var(--text-secondary); margin-bottom: 1rem; font-size: 0.9rem;">اعرض الكود للطلاب لمسحه، ويتجدد كل 10 ثوانٍ.</p>
                    <div id="qrcode" style="display: flex; justify-content: center; margin-bottom: 1.5rem;"></div>
                    <div style="height: 4px; background: #e2e8f0; border-radius: 2px; margin-bottom: 1.5rem; overflow: hidden;"><div style="height: 100%; background: #6366f1; transition: width 0.1s linear;" :style="'width: ' + timerWidth + '%'"></div></div>
                    <div style="display: flex; justify-content: center; gap: 2rem; margin-bottom: 1.5rem; background: #f8fafc; padding: 1rem; border-radius: 8px;">
                        <div><div style="font-size: 1.5rem; font-weight: 700; color: #10b981;" x-text="scannedCount"></div><div style="font-size: 0.85rem; color: var(--text-secondary);">حضور</div></div>
                        <div><div style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);" x-text="totalStudents"></div><div style="font-size: 0.85rem; color: var(--text-secondary);">إجمالي الطلاب</div></div>
                    </div>
                    <button @click="finalizeQrSession()" class="btn btn-danger" :disabled="qrFinalizing" style="width: 100%; padding: 0.65rem; font-weight: 600;"><span x-show="qrFinalizing" style="display: none;">جاري الإنهاء...</span><span x-show="!qrFinalizing" style="display: inline;">إنهاء المسح وتعبئة القائمة</span></button>
                </div>
                <div x-show="qrError" style="padding: 2rem; display: none;"><div style="color: var(--danger-color); font-size: 0.95rem; margin-bottom: 1rem;" x-text="qrError"></div><button @click="showQrModal = false" class="btn btn-secondary">إغلاق</button></div>
            </div>
        </div>
    </div>

    <div x-show="showDesktopPairingModal" style="display: none;" class="qr-modal-overlay" x-transition.opacity>
        <div @click.away="closeDesktopPairingModal()" style="background: white; border-radius: 18px; width: 100%; max-width: 520px; padding: 2rem; max-height: 90vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(15, 23, 42, 0.28);">
            <div style="display:flex; align-items:center; justify-content:space-between; gap:1rem; margin-bottom:1.25rem;">
                <div>
                    <h3 style="margin:0 0 0.35rem; font-size:1.12rem; font-weight:800; color:#0f172a;">ربط تطبيق العرض</h3>
                    <p style="margin:0; color:#64748b; line-height:1.8;">استخدم هذا الرمز داخل تطبيق Windows لبدء عرض QR من شاشة الكمبيوتر أو البروجكتر.</p>
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
                    <div>2. أدخل رمز الربط كما هو.</div>
                    <div>3. اختر المادة وابدأ الجلسة لعرض QR مباشرة للطلاب.</div>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .qr-modal-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.6); z-index: 9999; display: flex !important; align-items: center; justify-content: center; }
    .qr-modal-overlay[style*="display: none"] { display: none !important; }
    [x-cloak] { display: none !important; }
    .status-label { display: inline-block; cursor: pointer; position: relative; width: 24px; height: 24px; }
    .status-label input { display: none; }
    .status-label .indicator { position: absolute; top: 0; left: 0; width: 24px; height: 24px; border-radius: 50%; border: 2px solid #cbd5e1; background: white; transition: all 0.2s; }
    .status-label input:checked + .indicator::after { content: ''; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 10px; height: 10px; background: white; border-radius: 50%; opacity: 0.8; }
    .status-label.present input:checked + .indicator { background-color: var(--success-color); border-color: var(--success-color); }
    .status-label.absent input:checked + .indicator { background-color: var(--danger-color); border-color: var(--danger-color); }
    .status-label.late input:checked + .indicator { background-color: var(--warning-color); border-color: var(--warning-color); }
    .status-label.excused input:checked + .indicator { background-color: var(--info-color); border-color: var(--info-color); }
    .gender-tab {
        border: 0;
        background: transparent;
        color: #475569;
        padding: 0.55rem 1rem;
        border-radius: 9px;
        font-weight: 700;
        font-size: 0.9rem;
        cursor: pointer;
        transition: 0.2s ease;
    }
    .gender-tab.active {
        background: #2563eb;
        color: white;
        box-shadow: 0 8px 20px rgba(37, 99, 235, 0.18);
    }
</style>

<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script>
    function attendancePage(initialGenderTab) {
        return {
            genderTab: initialGenderTab || 'all',
            showQrModal: false, qrLoading: false, qrActive: false, qrFinalizing: false, qrError: '', showDesktopPairingModal: false, desktopPairingLoading: false, desktopPairingError: '', desktopPairingCode: '', desktopPairingRawCode: '', desktopPairingExpiresAt: '',
            sessionId: null, qrObject: null, timerWidth: 100, scannedCount: 0, totalStudents: {{ $students->count() }},
            maleStudents: {{ $students->where('gender', 'male')->count() }},
            femaleStudents: {{ $students->where('gender', 'female')->count() }},
            tokenInterval: null, statusInterval: null, animationInterval: null,
            setGenderTab(tab) {
                this.genderTab = tab;
            },
            shouldShowStudent(gender) {
                return this.genderTab === 'all' || gender === this.genderTab;
            },
            visibleStudentsLabel() {
                if (this.genderTab === 'male') return `${this.maleStudents} طالب`;
                if (this.genderTab === 'female') return `${this.femaleStudents} طالب`;
                return `${this.totalStudents} طالب`;
            },
            openQrModal() {
                const title = document.getElementById('title').value;
                if (!title) { showToast('يرجى إدخال عنوان المحاضرة أولاً.'); document.getElementById('title').focus(); return; }
                this.showQrModal = true; this.qrError = ''; this.qrActive = false; this.qrLoading = true; this.scannedCount = 0; this.startQrSession();
            },
            closeQrModal() {
                if (this.qrActive && !confirm('هل أنت متأكد من إغلاق نافذة QR؟ سيتم إيقاف الجلسة.')) return;
                if (this.qrActive) this.stopIntervals();
                this.showQrModal = false; this.qrActive = false;
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
                    subject_id: '{{ $subject->id }}',
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
                    const response = await fetch('{{ route('doctor.desktop.pairing-code') }}', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': '{{ csrf_token() }}' },
                        body: JSON.stringify(sessionPayload)
                    });
                    const data = await response.json();
                    if (!response.ok || !data.success) { this.desktopPairingError = data.message || 'تعذر إنشاء رمز الربط.'; return; }
                    this.desktopPairingCode = data.data.display_code || data.data.code || '';
                    this.desktopPairingRawCode = data.data.code || '';
                    this.desktopPairingExpiresAt = data.data.expires_at ? new Date(data.data.expires_at).toLocaleTimeString('ar-YE', { hour: '2-digit', minute: '2-digit' }) : '';
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
                const formData = { subject_id: '{{ $subject->id }}', date: document.getElementById('date').value, title: document.getElementById('title').value, lecture_number: document.getElementById('lecture_number').value || null, lecture_type: document.getElementById('lecture_type').value || 'official' };
                try {
                    const response = await fetch('/api/qr-attendance/start', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': '{{ csrf_token() }}' }, body: JSON.stringify(formData) });
                    const data = await response.json();
                    if (!response.ok) { this.qrLoading = false; this.qrError = data.message || 'حدث خطأ غير متوقع'; return; }
                    this.sessionId = data.session_id; this.qrLoading = false; this.qrActive = true;
                    this.$nextTick(() => {
                        const qrContainer = document.getElementById('qrcode');
                        if (qrContainer) qrContainer.innerHTML = '';
                        this.qrObject = new QRCode(document.getElementById('qrcode'), { text: data.token, width: 256, height: 256, colorDark: '#000000', colorLight: '#ffffff', correctLevel: QRCode.CorrectLevel.H });
                        this.startRotation(); this.startPollingStatus();
                    });
                } catch (error) { console.error(error); this.qrLoading = false; this.qrError = 'تعذر الاتصال بالخادم'; }
            },
            startRotation() {
                let seconds = 10; this.timerWidth = 100;
                this.tokenInterval = setInterval(async () => {
                    this.timerWidth = 100; seconds = 10;
                    try {
                        const response = await fetch(`/api/qr-attendance/${this.sessionId}/token`);
                        const data = await response.json();
                        if (response.ok && this.qrObject) { this.qrObject.clear(); this.qrObject.makeCode(data.token); }
                    } catch (e) { console.error('Failed to rotate token', e); }
                }, 10000);
                this.animationInterval = setInterval(() => { seconds -= 0.1; if (seconds < 0) seconds = 0; this.timerWidth = (seconds / 10) * 100; }, 100);
            },
            startPollingStatus() {
                this.statusInterval = setInterval(async () => {
                    try {
                        const response = await fetch(`/api/qr-attendance/${this.sessionId}/status`);
                        const data = await response.json();
                        if (response.ok) { this.scannedCount = data.scanned_count; this.totalStudents = data.total_students; }
                    } catch (e) { console.error('Failed to fetch status', e); }
                }, 3000);
            },
            stopIntervals() {
                if (this.tokenInterval) clearInterval(this.tokenInterval);
                if (this.statusInterval) clearInterval(this.statusInterval);
                if (this.animationInterval) clearInterval(this.animationInterval);
                this.tokenInterval = null; this.statusInterval = null; this.animationInterval = null;
            },
            async finalizeQrSession() {
                if (!confirm('هل أنت متأكد من إنهاء جلسة QR؟ سيتم تعيين الطلاب الذين لم يمسحوا الكود كغائبين تلقائيًا.')) return;
                this.qrFinalizing = true; this.stopIntervals();
                try {
                    const finalizeResponse = await fetch(`/api/qr-attendance/${this.sessionId}/finalize`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': '{{ csrf_token() }}' } });
                    const finalizeData = await finalizeResponse.json();
                    if (!finalizeResponse.ok) { this.qrError = finalizeData.message || 'حدث خطأ أثناء إنهاء الجلسة'; this.qrFinalizing = false; this.qrActive = false; return; }
                    const statusResponse = await fetch(`/api/qr-attendance/${this.sessionId}/status`);
                    const statusData = await statusResponse.json();
                    if (statusResponse.ok && statusData.students) {
                        statusData.students.forEach(student => {
                            const presentRadio = document.querySelector(`input[name="attendance[${student.id}]"][value="present"]`);
                            const absentRadio = document.querySelector(`input[name="attendance[${student.id}]"][value="absent"]`);
                            if (student.status === 'present' && presentRadio) presentRadio.checked = true;
                            else if (absentRadio) absentRadio.checked = true;
                        });
                        showToast(`تم تحديث القائمة: ${statusData.scanned_count} حاضر، و${statusData.total_students - statusData.scanned_count} غائب.`);
                    }
                    let hiddenInput = document.querySelector('input[name="qr_session_id"]');
                    if (!hiddenInput) { hiddenInput = document.createElement('input'); hiddenInput.type = 'hidden'; hiddenInput.name = 'qr_session_id'; document.getElementById('attendance-form').appendChild(hiddenInput); }
                    hiddenInput.value = this.sessionId;
                    this.showQrModal = false; this.qrActive = false; this.qrFinalizing = false;
                } catch (error) { console.error(error); this.qrError = 'حدث خطأ أثناء إنهاء الجلسة'; this.qrFinalizing = false; this.qrActive = false; }
            }
        }
    }
    function selectAll(status) {
        document.querySelectorAll(`input[type="radio"][value="${status}"]`).forEach(radio => { radio.checked = true; });
        const messages = { present: 'تم تحديد جميع الطلاب كحاضرين.', absent: 'تم تحديد جميع الطلاب كغائبين.', late: 'تم تحديد جميع الطلاب كمتأخرين.', excused: 'تم تحديد جميع الطلاب كمعذورين.' };
        showToast(messages[status] || 'تم تحديث القائمة.');
    }
    function showToast(message) {
        let toast = document.getElementById('bulk-toast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'bulk-toast';
            toast.style.cssText = 'position: fixed; bottom: 2rem; left: 50%; transform: translateX(-50%); background: #1e293b; color: white; padding: 0.75rem 1.5rem; border-radius: 8px; font-size: 0.9rem; z-index: 10000; opacity: 0; transition: opacity 0.3s;';
            document.body.appendChild(toast);
        }
        toast.textContent = message; toast.style.opacity = '1'; setTimeout(() => { toast.style.opacity = '0'; }, 2000);
    }
</script>
@endsection
