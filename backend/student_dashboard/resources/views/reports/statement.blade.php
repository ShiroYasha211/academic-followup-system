<!DOCTYPE html>
<html lang="ar">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>كشف حساب - {{ $user->name }}</title>
    <style>
        /* Force font subsetting for Arabic by using DejaVu Sans as primary for shaped forms */
        @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap');

        @page {
            margin: 0;
        }

        body {
            /* Use DejaVu Sans first for shaped Arabic characters to avoid question marks */
            font-family: 'DejaVu Sans', 'Cairo', sans-serif;
            margin: 0;
            padding: 0;
            background-color: #ffffff;
            color: #1e293b;
            font-size: 11px;
            line-height: 1.6;
            /* Use LTR globally because text is manually reversed for RTL */
            direction: ltr;
            text-align: right;
        }

        .header-banner {
            background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%);
            color: white;
            padding: 40px 50px;
            text-align: right;
        }

        .header-banner h1 {
            margin: 0;
            font-size: 26px;
            font-weight: 700;
        }

        .header-banner p {
            margin: 5px 0 0 0;
            opacity: 0.9;
            font-size: 13px;
        }

        .container {
            padding: 40px 50px;
        }

        .info-grid {
            width: 100%;
            margin-bottom: 30px;
            border-collapse: collapse;
        }

        .info-card {
            background-color: #f8fafc;
            border-radius: 12px;
            padding: 15px;
            border: 1px solid #e2e8f0;
            text-align: right;
        }

        .label {
            color: #64748b;
            font-size: 9px;
            font-weight: 700;
            margin-bottom: 4px;
        }

        .value {
            color: #1e293b;
            font-size: 13px;
            font-weight: 700;
        }

        .summary-box {
            background: #ffffff;
            border: 2px solid #4f46e5;
            border-radius: 16px;
            padding: 20px;
            text-align: center;
            margin-bottom: 30px;
        }

        .summary-box .balance {
            font-size: 32px;
            font-weight: 700;
            color: #4f46e5;
        }

        .section-title {
            font-size: 16px;
            font-weight: 700;
            color: #334155;
            margin-bottom: 15px;
            padding-right: 12px;
            border-right: 4px solid #4f46e5;
            text-align: right;
        }

        table.transactions {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }

        table.transactions th {
            background-color: #f1f5f9;
            padding: 12px 15px;
            font-weight: 700;
            text-align: right;
            color: #475569;
            border-bottom: 1px solid #e2e8f0;
        }

        table.transactions td {
            padding: 12px 15px;
            border-bottom: 1px solid #f1f5f9;
            color: #334155;
            text-align: right;
        }

        .amount-in { color: #059669; font-weight: 700; }
        .amount-out { color: #dc2626; font-weight: 700; }

        .type-badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 9px;
            background: #f1f5f9;
        }

        .footer {
            margin-top: 50px;
            text-align: center;
            color: #94a3b8;
            font-size: 9px;
        }

        .page-number:after { content: counter(page); }
    </style>
</head>
<body>
    <div class="header-banner">
        <h1>{{ $account_statement_text }}</h1>
        <p>{{ $system_desc_text }}</p>
    </div>

    <div class="container">
        <table class="info-grid">
            <tr>
                <td width="33.33%">
                    <div class="info-card">
                        <div class="label">{{ \App\Helpers\ArabicHelper::fixArabic('اسم المستخدم', true) }}</div>
                        <div class="value">{{ $user->name_fixed }}</div>
                    </div>
                </td>
                <td width="33.33%">
                    <div class="info-card" style="margin: 0 10px;">
                        <div class="label">{{ \App\Helpers\ArabicHelper::fixArabic('تاريخ التقرير', true) }}</div>
                        <div class="value">{{ date('Y/m/d H:i') }}</div>
                    </div>
                </td>
                <td width="33.33%">
                    <div class="info-card">
                        <div class="label">{{ \App\Helpers\ArabicHelper::fixArabic('رقم الحساب', true) }}</div>
                        <div class="value">#{{ str_pad($user->id, 6, '0', STR_PAD_LEFT) }}</div>
                    </div>
                </td>
            </tr>
        </table>

        <div class="summary-box">
            <div class="label" style="font-size: 11px;">{{ \App\Helpers\ArabicHelper::fixArabic('إجمالي الرصيد الحالي المتوفر', true) }}</div>
            <div class="balance">{{ number_format($totalBalance, 2) }} {{ \App\Helpers\ArabicHelper::fixArabic('ريال', true) }}</div>
        </div>

        <div class="section-title">{{ \App\Helpers\ArabicHelper::fixArabic('تفاصيل الحركات المالية الأخيرة', true) }}</div>

        <table class="transactions">
            <thead>
                <tr>
                    <th width="20%">{{ \App\Helpers\ArabicHelper::fixArabic('التاريخ', true) }}</th>
                    <th width="40%">{{ \App\Helpers\ArabicHelper::fixArabic('البيان / الوصف', true) }}</th>
                    <th width="20%">{{ \App\Helpers\ArabicHelper::fixArabic('المبلغ', true) }}</th>
                    <th width="20%">{{ \App\Helpers\ArabicHelper::fixArabic('الرصيد المتبقي', true) }}</th>
                </tr>
            </thead>
            <tbody>
                @foreach($transactions as $transaction)
                <tr>
                    <td>{{ $transaction->created_at->format('Y/m/d H:i') }}</td>
                    <td>
                        <div style="font-weight: 700;">{{ $transaction->description_fixed }}</div>
                        <span class="type-badge">
                            @if($transaction->type === 'deposit') {{ \App\Helpers\ArabicHelper::fixArabic('إيداع', true) }}
                            @elseif($transaction->type === 'payment') {{ \App\Helpers\ArabicHelper::fixArabic('مدفوعات', true) }}
                            @elseif($transaction->type === 'refund') {{ \App\Helpers\ArabicHelper::fixArabic('مستردات', true) }}
                            @else {{ \App\Helpers\ArabicHelper::fixArabic('تعديل', true) }} @endif
                        </span>
                    </td>
                    <td class="{{ $transaction->amount > 0 ? 'amount-in' : 'amount-out' }}">
                        {{ $transaction->amount > 0 ? '+' : '' }}{{ number_format($transaction->amount, 2) }}
                    </td>
                    <td style="font-weight: 700;">{{ number_format($transaction->balance_after, 2) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <div class="footer">
            <p>{{ \App\Helpers\ArabicHelper::fixArabic('تم توليد هذا التقرير آلياً بواسطة نظام Attendify في', true) }} {{ date('Y-m-d H:i') }}</p>
            <p>{{ \App\Helpers\ArabicHelper::fixArabic('صفحة رقم', true) }} <span class="page-number"></span></p>
        </div>
    </div>
</body>
</html>
