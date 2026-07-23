<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Api\Delegate\DelegateApiController;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class FinancialController extends DelegateApiController
{
    public function ledger(Request $request)
    {
        $user = $request->user();

        $transactions = $user->transactions()
            ->latest()
            ->paginate(15);

        return $this->success([
            'balance' => $user->balance,
            'transactions' => $transactions,
        ]);
    }

    public function exportPdf(Request $request)
    {
        $user = $request->user();
        $transactions = $user->transactions()->latest()->get();
        $totalBalance = $user->balance;

        $user->name_fixed = \App\Helpers\ArabicHelper::fixArabic($user->name, true);

        foreach ($transactions as $transaction) {
            $transaction->description_fixed = \App\Helpers\ArabicHelper::fixArabic($transaction->description, true);
        }

        $account_statement_text = \App\Helpers\ArabicHelper::fixArabic('كشف الحساب المالي', true);
        $system_desc_text = \App\Helpers\ArabicHelper::fixArabic('نظام Moeen لإدارة الطلاب والعمليات المالية', true);

        $pdf = Pdf::loadView('reports.statement', compact(
            'user',
            'transactions',
            'totalBalance',
            'account_statement_text',
            'system_desc_text'
        ));

        $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
        $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
        $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');

        return $pdf
            ->setPaper('a4', 'portrait')
            ->download("delegate_statement_{$user->id}_" . date('Y-m-d') . '.pdf');
    }
}
