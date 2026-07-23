@extends('layouts.student')

@section('title', 'مسح كود الحضور')

@section('content')

<div class="container" style="max-width: 600px; margin: 0 auto; padding: 1rem;">

    <div class="card" style="text-align: center; padding: 2rem;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">تسجيل الحضور</h2>
        <p style="color: var(--text-secondary); margin-bottom: 2rem;">وجه الكاميرا نحو رمز QR الموجود على شاشة القاعة</p>

        <!-- Camera Container -->
        <div id="reader" style="width: 100%; border-radius: 12px; overflow: hidden; margin-bottom: 1.5rem; background: #000;"></div>

        <!-- Status Messages -->
        <div id="status-message" style="display: none; padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem;"></div>

        <!-- Manual Retry Button -->
        <button id="retry-btn" style="display: none;" class="btn btn-primary" onclick="window.location.reload()">
            مسح مرة أخرى
        </button>

        <a href="{{ route('student.dashboard') }}" class="btn btn-secondary" style="margin-top: 1rem; display: inline-block;">
            العودة للرئيسية
        </a>
    </div>

</div>

<!-- HTML5-QRCode Library -->
<script src="https://unpkg.com/html5-qrcode" type="text/javascript"></script>

<script>
    const html5QrCode = new Html5Qrcode("reader");
    let isScanning = true;

    const config = {
        fps: 10,
        qrbox: {
            width: 250,
            height: 250
        }
    };

    const onScanSuccess = async (decodedText, decodedResult) => {
        if (!isScanning) return;
        isScanning = false;

        // Stop scanning temporarily
        html5QrCode.pause();

        showMessage('جاري تسجيل الحضور...', 'info');

        try {
            const response = await fetch('/api/qr-attendance/scan', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    token: decodedText
                })
            });

            const contentType = response.headers.get('content-type') || '';
            if (!contentType.includes('application/json')) {
                throw new Error(`Unexpected response type: ${contentType || 'unknown'}`);
            }

            const data = await response.json();

            if (response.ok) {
                showMessage(`✅ ${data.message}<br><small>${data.subject} - ${data.date}</small>`, 'success');
                // Play success sound if desired

                // Stop camera completely
                html5QrCode.stop().then((ignore) => {
                    // QR Code scanning is stopped.
                    document.getElementById('reader').style.display = 'none';
                    document.getElementById('retry-btn').style.display = 'none'; // No retry needed on success
                }).catch((err) => {
                    // Stop failed, handle it.
                });

            } else {
                showMessage(`❌ ${data.message}`, 'error');
                // Resume scanning after 2 seconds
                setTimeout(() => {
                    isScanning = true;
                    html5QrCode.resume();
                    document.getElementById('status-message').style.display = 'none';
                }, 3000);
            }

        } catch (error) {
            console.error(error);
            showMessage('❌ خطأ في الاتصال بالسيرفر', 'error');
            setTimeout(() => {
                isScanning = true;
                html5QrCode.resume();
            }, 3000);
        }
    };

    const onScanFailure = (error) => {
        // handle scan failure, usually better to ignore and keep scanning.
        // console.warn(`Code scan error = ${error}`);
    };

    // Start scanning
    html5QrCode.start({
            facingMode: "environment"
        },
        config,
        onScanSuccess,
        onScanFailure
    ).catch(err => {
        console.error(err);
        showMessage('❌ لا يمكن الوصول للكاميرا. تأكد من منح الصلاحيات.', 'error');
        document.getElementById('retry-btn').style.display = 'inline-block';
    });

    function showMessage(msg, type) {
        const el = document.getElementById('status-message');
        el.style.display = 'block';
        el.innerHTML = msg;

        if (type === 'success') {
            el.style.backgroundColor = '#dcfce7'; // green-100
            el.style.color = '#166534'; // green-800
            el.style.border = '1px solid #bbf7d0';
        } else if (type === 'error') {
            el.style.backgroundColor = '#fee2e2'; // red-100
            el.style.color = '#991b1b'; // red-800
            el.style.border = '1px solid #fecaca';
        } else {
            el.style.backgroundColor = '#e0f2fe'; // blue-100
            el.style.color = '#075985'; // blue-800
            el.style.border = '1px solid #bae6fd';
        }
    }
</script>

@endsection
