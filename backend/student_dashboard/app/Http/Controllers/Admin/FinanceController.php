<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
    /**
     * Display the financial dashboard for admins.
     */
    public function index(Request $request)
    {
        // 1. Core Stats
        $stats = [
            'total_system_balance' => User::sum('balance'),
            'total_revenue' => Transaction::where('type', 'deposit')->sum('amount'),
            'total_payments' => Transaction::where('type', 'payment')->sum('amount'),
            'cards_sold_count' => Card::where('is_used', true)->count(),
        ];

        // 2. Transaction Query
        $query = Transaction::with('user')->latest();

        // Filtering
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('user', function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $transactions = $query->paginate(20)->withQueryString();

        return view('admin.finance.index', compact('stats', 'transactions'));
    }
}
