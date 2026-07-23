@extends('layouts.doctor')

@section('title', 'ماسح السجل السريري')

@section('content')
<style>
    .scanner-shell {
        display: grid;
        grid-template-columns: 360px 1fr;
        gap: 1.5rem;
        align-items: start;
    }

    @media (max-width: 992px) {
        .scanner-shell {
            grid-template-columns: 1fr;
        }
    }

    .scanner-card,
    .review-card {
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 20px;
        box-shadow: 0 12px 32px rgba(15, 23, 42, 0.05);
    }

    .scanner-card {
        padding: 1.25rem;
        position: sticky;
        top: 1.5rem;
    }

    .review-card {
        padding: 1.5rem;
    }

    .section-label {
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        color: #64748b;
        margin-bottom: 0.35rem;
        font-weight: 700;
    }

    .page-title {
        font-size: 1.7rem;
        font-weight: 800;
        margin-bottom: 0.35rem;
        color: #0f172a;
    }

    .page-subtitle {
        color: #475569;
        font-size: 0.92rem;
        margin-bottom: 1.25rem;
    }

    #scanner-container {
        border: 2px dashed #cbd5e1;
        border-radius: 16px;
        overflow: hidden;
        background: #f8fafc;
        min-height: 300px;
        margin-bottom: 1rem;
    }

    .manual-box {
        display: grid;
        grid-template-columns: 1fr auto;
        gap: 0.75rem;
    }

    .manual-box input,
    .diagnosis-input,
    .notes-input {
        width: 100%;
        border: 1px solid #dbe2ea;
        border-radius: 12px;
        padding: 0.8rem 0.9rem;
        background: #fff;
        font: inherit;
    }

    .primary-btn,
    .secondary-btn,
    .danger-btn {
        border: none;
        border-radius: 12px;
        padding: 0.8rem 1rem;
        font-weight: 700;
        cursor: pointer;
        transition: transform 0.15s ease, box-shadow 0.15s ease;
    }

    .primary-btn:hover,
    .secondary-btn:hover,
    .danger-btn:hover {
        transform: translateY(-1px);
    }

    .primary-btn {
        background: linear-gradient(135deg, #1d4ed8, #2563eb);
        color: #fff;
        box-shadow: 0 10px 20px rgba(37, 99, 235, 0.18);
    }

    .secondary-btn {
        background: #eef2ff;
        color: #3730a3;
    }

    .danger-btn {
        background: #fef2f2;
        color: #b91c1c;
        border: 1px solid #fecaca;
    }

    .review-empty {
        min-height: 420px;
        display: flex;
        align-items: center;
        justify-content: center;
        text-align: center;
        color: #64748b;
        border: 2px dashed #e2e8f0;
        border-radius: 18px;
        background: linear-gradient(180deg, #f8fafc, #ffffff);
    }

    .info-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 0.9rem;
        margin-bottom: 1.25rem;
    }

    .info-box {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.9rem 1rem;
    }

    .info-box .label {
        color: #64748b;
        font-size: 0.78rem;
        margin-bottom: 0.25rem;
    }

    .info-box .value {
        color: #0f172a;
        font-weight: 700;
    }

    .status-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.35rem 0.7rem;
        border-radius: 999px;
        font-size: 0.82rem;
        font-weight: 700;
        background: #fef3c7;
        color: #92400e;
    }

    .status-pill.confirmed {
        background: #dcfce7;
        color: #166534;
    }

    .status-pill.partial {
        background: #dbeafe;
        color: #1d4ed8;
    }

    .group-card {
        border: 1px solid #e2e8f0;
        border-radius: 18px;
        padding: 1rem 1.1rem;
        margin-bottom: 1rem;
        background: #fff;
    }

    .group-card.confirmed {
        border-color: #86efac;
        background: #f0fdf4;
    }

    .group-head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
        margin-bottom: 0.85rem;
    }

    .group-title {
        font-weight: 800;
        color: #0f172a;
    }

    .group-count {
        font-size: 0.8rem;
        color: #64748b;
    }

    .group-toggle {
        display: inline-flex;
        align-items: center;
        gap: 0.65rem;
        font-weight: 700;
        color: #0f172a;
    }

    .items-list {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-bottom: 0.85rem;
    }

    .item-pill {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        color: #334155;
        padding: 0.35rem 0.7rem;
        border-radius: 999px;
        font-size: 0.8rem;
    }

    .item-pill.confirmed {
        background: #dcfce7;
        border-color: #86efac;
        color: #166534;
    }

    .diagnosis-wrap {
        display: none;
        margin-top: 0.85rem;
    }

    .diagnosis-wrap.active {
        display: block;
    }

    .actions-row {
        display: flex;
        gap: 0.75rem;
        margin-top: 1.2rem;
        flex-wrap: wrap;
    }

    .alert-box {
        display: none;
        margin-top: 1rem;
        padding: 0.85rem 1rem;
        border-radius: 12px;
        font-weight: 700;
    }

    .alert-box.success {
        display: none;
        background: #dcfce7;
        color: #166534;
    }

    .alert-box.error {
        display: none;
        background: #fee2e2;
        color: #991b1b;
    }
</style>

<div class="mb-4 d-flex justify-content-between align-items-start flex-wrap gap-3">
    <div>
        <div class="section-label">Clinical review</div>
        <h1 class="page-title">اعتماد السجل العملي</h1>
        <p class="page-subtitle">امسح QR ثم اختر الأقسام المعتمدة فعليًا وأضف التشخيص لكل قسم عند الحاجة.</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
        <a href="{{ route('doctor.clinical.manual-attendance') }}" class="secondary-btn text-decoration-none">تحضير يدوي</a>
        <a href="{{ route('doctor.clinical.index') }}" class="secondary-btn text-decoration-none">القسم العملي</a>
    </div>
</div>

<div class="scanner-shell">
    <section class="scanner-card">
        <div class="section-label">Scan QR</div>
        <div id="scanner-container"></div>
        <div class="manual-box">
            <input type="text" id="qr-input" placeholder="ألصق رمز QR هنا أو امسحه بالكاميرا">
            <button type="button" class="primary-btn" onclick="processManualInput()">بحث</button>
        </div>
        <div id="successAlert" class="alert-box success"></div>
        <div id="errorAlert" class="alert-box error"></div>
    </section>

    <section class="review-card">
        <div id="reviewEmpty" class="review-empty">
            <div>
                <div class="fw-bold mb-2">لا يوجد سجل محمّل بعد</div>
                <div>بعد المسح ستظهر بيانات الطالب والأقسام القابلة للاعتماد هنا.</div>
            </div>
        </div>

        <div id="reviewPanel" style="display:none;">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-3">
                <div>
                    <div class="section-label">Daily log</div>
                    <h2 class="h4 mb-1" id="studentName"></h2>
                    <div class="text-muted small" id="studentNumber"></div>
                </div>
                <span class="status-pill" id="statusPill"></span>
            </div>

            <div class="info-grid" id="infoGrid"></div>

            <div id="groupsContainer"></div>

            <div class="mt-3">
                <label class="form-label fw-bold">ملاحظات الدكتور</label>
                <textarea id="doctorNotes" class="notes-input" rows="3" placeholder="ملاحظات عامة على السجل"></textarea>
            </div>

            <div class="actions-row">
                <button type="button" class="primary-btn" onclick="submitReview('confirm')">اعتماد المختار</button>
                <button type="button" class="danger-btn" onclick="submitReview('reject')">رفض السجل</button>
            </div>
        </div>
    </section>
</div>
@endsection

@push('scripts')
<script src="https://unpkg.com/html5-qrcode@2.3.4/html5-qrcode.min.js"></script>
<script>
    let currentLog = null;

    document.addEventListener('DOMContentLoaded', () => {
        try {
            const scanner = new Html5QrcodeScanner('scanner-container', {
                fps: 10,
                qrbox: {
                    width: 250,
                    height: 250
                },
                rememberLastUsedCamera: true
            }, false);

            scanner.render(onScanSuccess, () => {});
        } catch (error) {
            showAlert('error', 'تعذر تهيئة الكاميرا. استخدم الإدخال اليدوي إذا لزم الأمر.');
        }
    });

    function onScanSuccess(token) {
        processToken(token);
    }

    function processManualInput() {
        processToken(document.getElementById('qr-input').value.trim());
    }

    function processToken(token) {
        if (!token) return;
        hideAlerts();

        fetch("{{ route('doctor.clinical.scanner.process') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                qr_token: token
            })
        }).then(r => r.json()).then(data => {
            if (!data.success) {
                showAlert('error', data.message || 'فشل تحميل السجل.');
                return;
            }

            currentLog = {
                id: data.log_id,
                ...data.data
            };
            renderReview(currentLog);
        }).catch(() => showAlert('error', 'تعذر الاتصال بالخادم.'));
    }

    function renderReview(log) {
        document.getElementById('reviewEmpty').style.display = 'none';
        document.getElementById('reviewPanel').style.display = 'block';
        document.getElementById('studentName').textContent = log.student_name || '-';
        document.getElementById('studentNumber').textContent = 'الرقم الجامعي: ' + (log.student_number || '-');

        const statusPill = document.getElementById('statusPill');
        statusPill.textContent = log.status_label || log.status;
        statusPill.className = 'status-pill';
        if (log.status === 'confirmed') statusPill.classList.add('confirmed');
        if (log.status === 'partially_confirmed') statusPill.classList.add('partial');

        document.getElementById('infoGrid').innerHTML = `
            <div class="info-box"><div class="label">المركز</div><div class="value">${escapeHtml(log.training_center || '-')}</div></div>
            <div class="info-box"><div class="label">القسم</div><div class="value">${escapeHtml(log.department || '-')}</div></div>
            <div class="info-box"><div class="label">الدكتور المختار</div><div class="value">${escapeHtml(log.doctor_name || '-')}</div></div>
            <div class="info-box"><div class="label">التاريخ</div><div class="value">${escapeHtml(log.log_date || '-')} ${escapeHtml(log.log_time || '')}</div></div>
        `;

        const groupsContainer = document.getElementById('groupsContainer');
        groupsContainer.innerHTML = '';

        (log.groups || []).forEach(group => {
            const card = document.createElement('div');
            card.className = 'group-card' + (group.confirmed ? ' confirmed' : '');
            card.innerHTML = `
                <div class="group-head">
                    <div>
                        <div class="group-title">${escapeHtml(group.label)}</div>
                        <div class="group-count">${group.count} عنصر</div>
                    </div>
                    <label class="group-toggle">
                        <input type="checkbox" data-group-toggle="${group.key}" ${group.confirmed ? 'checked' : ''}>
                        <span>اعتماد هذا القسم</span>
                    </label>
                </div>
                <div class="items-list">
                    ${(group.items || []).map(item => `<span class="item-pill ${item.is_confirmed ? 'confirmed' : ''}">${escapeHtml(item.label)}</span>`).join('')}
                </div>
                <div class="diagnosis-wrap ${group.confirmed ? 'active' : ''}" id="diagnosis-wrap-${group.key}">
                    <label class="form-label fw-bold">التشخيص لهذا القسم</label>
                    <textarea class="diagnosis-input" id="diagnosis-${group.key}" rows="3" placeholder="تشخيص اختياري لهذا القسم">${escapeHtml(group.diagnosis || '')}</textarea>
                </div>
            `;

            groupsContainer.appendChild(card);
        });

        document.getElementById('doctorNotes').value = log.doctor_notes || '';

        document.querySelectorAll('[data-group-toggle]').forEach(toggle => {
            toggle.addEventListener('change', function() {
                document.getElementById('diagnosis-wrap-' + this.dataset.groupToggle)
                    .classList.toggle('active', this.checked);
            });
        });
    }

    function submitReview(action) {
        if (!currentLog) return;

        const confirmations = {};
        document.querySelectorAll('[data-group-toggle]').forEach(toggle => {
            const key = toggle.dataset.groupToggle;
            confirmations[key] = {
                confirm: toggle.checked,
                diagnosis: document.getElementById('diagnosis-' + key)?.value || ''
            };
        });

        fetch("{{ route('doctor.clinical.scanner.confirm') }}", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                log_id: currentLog.id,
                action,
                doctor_notes: document.getElementById('doctorNotes').value,
                confirmations
            })
        }).then(r => r.json()).then(data => {
            if (!data.success) {
                showAlert('error', data.message || 'تعذر حفظ المراجعة.');
                return;
            }

            showAlert('success', data.message || 'تم حفظ المراجعة.');
            currentLog = null;
            document.getElementById('reviewPanel').style.display = 'none';
            document.getElementById('reviewEmpty').style.display = 'flex';
            document.getElementById('qr-input').value = '';
        }).catch(() => showAlert('error', 'تعذر الاتصال بالخادم.'));
    }

    function showAlert(type, message) {
        hideAlerts();
        const element = document.getElementById(type === 'success' ? 'successAlert' : 'errorAlert');
        element.textContent = message;
        element.style.display = 'block';
        setTimeout(() => {
            element.style.display = 'none';
        }, 5000);
    }

    function hideAlerts() {
        document.getElementById('successAlert').style.display = 'none';
        document.getElementById('errorAlert').style.display = 'none';
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }
</script>
@endpush
