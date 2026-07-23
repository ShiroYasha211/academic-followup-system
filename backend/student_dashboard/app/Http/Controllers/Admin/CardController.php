<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CardController extends Controller
{
    public function index(Request $request)
    {
        $query = Card::with(['usedBy', 'generatedBy'])->latest();

        if ($request->has('status')) {
            if ($request->status == 'used') {
                $query->where('is_used', true);
            } elseif ($request->status == 'unused') {
                $query->where('is_used', false);
            }
        }

        if ($request->filled('generated_by_id')) {
            $query->where('generated_by_id', $request->integer('generated_by_id'));
        }

        if ($request->filled('used_by_id')) {
            $query->where('used_by_id', $request->integer('used_by_id'));
        }

        if ($request->filled('search')) {
            $query->where('code', 'like', '%' . $request->search . '%');
        }

        $cards = $query->paginate(30)->withQueryString();
        $creatorIds = Card::whereNotNull('generated_by_id')->distinct()->pluck('generated_by_id');
        $usedByIds = Card::whereNotNull('used_by_id')->distinct()->pluck('used_by_id');

        $creators = User::whereIn('id', $creatorIds)->orderBy('name')->get(['id', 'name']);
        $redeemers = User::whereIn('id', $usedByIds)->orderBy('name')->get(['id', 'name']);

        return view('admin.cards.index', compact('cards', 'creators', 'redeemers'));
    }

    public function generate(Request $request)
    {
        $request->validate([
            'count' => 'required|integer|min:1|max:100',
            'amount' => 'required|numeric|min:1',
        ]);

        $count = $request->count;
        $amount = $request->amount;
        $generated = 0;

        while ($generated < $count) {
            $code = strtoupper(Str::random(12));
            
            // Ensure uniqueness
            if (!Card::where('code', $code)->exists()) {
                Card::create([
                    'code' => $code,
                    'amount' => $amount,
                    'is_used' => false,
                ]);
                $generated++;
            }
        }

        return redirect()->route('admin.cards.index')->with('success', "تم توليد {$count} كرت بنجاح بقيمة {$amount} ريال.");
    }

    public function destroy(Card $card)
    {
        if ($card->is_used) {
            return back()->with('error', 'لا يمكن حذف كرت تم استخدامه بالفعل.');
        }

        $card->delete();
        return back()->with('success', 'تم حذف الكرت بنجاح.');
    }
}
