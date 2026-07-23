<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CardGenerationController extends Controller
{
    public function index()
    {
        $user = auth()->user();
        if (!$user->hasPermission('generate_cards')) {
            abort(403);
        }

        $cards = Card::where('generated_by_id', $user->id)->latest()->paginate(20);
        return view('student.cards.index', compact('cards'));
    }

    public function generate(Request $request)
    {
        $user = auth()->user();
        if (!$user->hasPermission('generate_cards')) {
            abort(403);
        }

        $request->validate([
            'count' => 'required|integer|min:1|max:100',
            'amount' => 'required|numeric|min:1',
        ], [
            'count.required' => 'يرجى تحديد عدد الكروت.',
            'count.integer' => 'عدد الكروت يجب أن يكون رقماً صحيحاً.',
            'count.min' => 'عدد الكروت يجب أن يكون 1 على الأقل.',
            'count.max' => 'يمكنك توليد 100 كرت كحد أقصى في المرة الواحدة.',
            'amount.required' => 'يرجى تحديد قيمة الكرت الواحد.',
            'amount.numeric' => 'قيمة الكرت يجب أن تكون رقماً.',
            'amount.min' => 'قيمة الكرت يجب أن تكون أكبر من صفر.',
        ]);

        $count = $request->count;
        $amount = $request->amount;
        $totalCost = $count * $amount;

        if ($user->balance < $totalCost) {
            return back()->with('error', "رصيدك غير كافٍ. اجمالي التكلفة {$totalCost} ريال، ورصيدك الحالي " . number_format($user->balance) . " ريال.");
        }

        try {
            DB::transaction(function () use ($user, $count, $amount, $totalCost) {
                // Record transaction (this handles increment/decrement and logging)
                $user->recordTransaction(
                    -$totalCost, 
                    'debit', 
                    'card_generation', 
                    "توليد عدد {$count} كرت بقيمة {$amount} ريال للكرت الواحد"
                );

                // Generate Cards
                $generated = 0;
                while ($generated < $count) {
                    $code = strtoupper(Str::random(12));
                    
                    if (!Card::where('code', $code)->exists()) {
                        Card::create([
                            'code' => $code,
                            'amount' => $amount,
                            'is_used' => false,
                            'generated_by_id' => $user->id,
                        ]);
                        $generated++;
                    }
                }
            });

            return back()->with('success', "تم توليد {$count} كرت بنجاح وتم خصم {$totalCost} ريال من رصيدك.");
        } catch (\Exception $e) {
            return back()->with('error', 'حدث خطأ أثناء توليد الكروت. يرجى المحاولة مرة أخرى.');
        }
    }
}
