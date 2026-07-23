<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Models\Transaction;
use App\Models\Card;
use Illuminate\Http\Request;

class FinanceController extends AdminApiController
{
    public function index(Request $request)
    {
        $stats = [
            'total_system_balance' => User::sum('balance'),
            'total_revenue' => Transaction::where('type', 'deposit')->sum('amount'),
            'total_payments' => Transaction::where('type', 'payment')->sum('amount'),
            'cards_sold_count' => Card::where('is_used', true)->count(),
        ];

        return $this->success($stats);
    }

    public function transactions(Request $request)
    {
        $query = Transaction::with('user')->latest();

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

        return $this->paginated($query->paginate($request->per_page ?? 20));
    }
}
