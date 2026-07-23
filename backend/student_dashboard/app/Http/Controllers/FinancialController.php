<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Transaction;
use Barryvdh\DomPDF\Facade\Pdf;

class FinancialController extends Controller
{
    /**
     * Show the user's financial ledger (account statement).
     */
    public function ledger()
    {
        $user = auth()->user();
        $transactions = $user->transactions()
            ->latest()
            ->paginate(15);

        return view('financial.ledger', compact('user', 'transactions'));
    }

    /**
     * Export the account statement to PDF.
     */
    public function exportPdf()
    {
        $user = auth()->user();
        // Get transactions with latest first
        $transactions = $user->transactions()->latest()->get();
        $totalBalance = $user->balance;

        // Apply Arabic reshaping and reversal to text fields
        // We reverse because DomPDF doesn't handle Arabic RTL correctly
        $user->name_fixed = \App\Helpers\ArabicHelper::fixArabic($user->name, true);
        
        foreach ($transactions as $transaction) {
            $transaction->description_fixed = \App\Helpers\ArabicHelper::fixArabic($transaction->description, true);
        }

        // Also fix the system title and other static text if needed
        $account_statement_text = \App\Helpers\ArabicHelper::fixArabic('كشف الحساب المالي', true);
        $system_desc_text = \App\Helpers\ArabicHelper::fixArabic('نظام Attendify الذكي لإدارة الطلاب والعمليات المالية', true);

        // Create PDF with robust options
        $pdf = Pdf::loadView('reports.statement', compact(
            'user', 
            'transactions', 
            'totalBalance', 
            'account_statement_text', 
            'system_desc_text'
        ));
        
        // DomPDF Options for better character support
        $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
        $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
        $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');

        return $pdf->setPaper('a4', 'portrait')->download("كشف_حساب_{$user->id}_" . date('Y-m-d') . ".pdf");
    }
}
