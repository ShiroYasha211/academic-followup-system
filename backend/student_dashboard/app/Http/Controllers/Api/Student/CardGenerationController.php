<?php

namespace App\Http\Controllers\Api\Student;

use Illuminate\Http\Request;
use App\Models\Card;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CardGenerationController extends StudentApiController
{
    /**
     * Get Student Generated Cards
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->hasPermission('generate_cards')) {
            return $this->error('ليس لديك صلاحية لتوليد الكروت.', 403);
        }

        $cards = Card::where('generated_by_id', $user->id)->latest()->paginate(20);

        return $this->success([
            'balance' => $user->balance,
            'cards' => $cards,
        ]);
    }

    /**
     * Generate Cards
     */
    public function generate(Request $request)
    {
        $user = $request->user();
        if (!$user->hasPermission('generate_cards')) {
            return $this->error('ليس لديك صلاحية لتوليد الكروت.', 403);
        }

        $request->validate([
            'count' => 'required|integer|min:1|max:100',
            'amount' => 'required|numeric|min:1',
        ], [
            'count.required' => 'يرجى تحديد عدد الكروت.',
            'count.integer' => 'عدد الكروت يجب أن يكون رقمًا صحيحًا.',
            'count.min' => 'يجب توليد كرت واحد على الأقل.',
            'count.max' => 'يمكن توليد 100 كرت كحد أقصى في العملية الواحدة.',
            'amount.required' => 'يرجى تحديد قيمة الكرت.',
            'amount.numeric' => 'قيمة الكرت يجب أن تكون رقمًا.',
            'amount.min' => 'قيمة الكرت يجب ألا تقل عن ريال واحد.',
        ]);

        $count = $request->count;
        $amount = $request->amount;
        $totalCost = $count * $amount;

        if ($user->balance < $totalCost) {
            return $this->error("رصيدك غير كافٍ. اجمالي التكلفة {$totalCost} ريال، ورصيدك الحالي " . number_format($user->balance) . " ريال.");
        }

        try {
            DB::transaction(function () use ($user, $count, $amount, $totalCost) {
                // Record transaction
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

            return $this->success([], "تم توليد {$count} كروت بنجاح بخصم {$totalCost} ريال.");
        } catch (\Exception $e) {
            return $this->error('حدث خطأ أثناء توليد الكروت. يرجى المحاولة مرة أخرى.');
        }
    }
}
