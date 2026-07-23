<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Card;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CardGenerationController extends DoctorApiController
{
    public function index(Request $request)
    {
        $user = $request->user();

        if (!$user->hasPermission('generate_cards')) {
            return $this->error('ليس لديك صلاحية لتوليد الكروت.', 403);
        }

        $cards = Card::where('generated_by_id', $user->id)
            ->latest()
            ->paginate($request->integer('per_page', 20));

        return $this->success([
            'balance' => $user->balance,
            'cards' => $cards,
        ]);
    }

    public function generate(Request $request)
    {
        $user = $request->user();

        if (!$user->hasPermission('generate_cards')) {
            return $this->error('ليس لديك صلاحية لتوليد الكروت.', 403);
        }

        $validated = $request->validate([
            'count' => 'required|integer|min:1|max:100',
            'amount' => 'required|numeric|min:1',
        ]);

        $totalCost = $validated['count'] * $validated['amount'];

        if ($user->balance < $totalCost) {
            return $this->error("رصيدك غير كافٍ. إجمالي التكلفة {$totalCost} ريال.");
        }

        DB::transaction(function () use ($user, $validated, $totalCost) {
            $user->recordTransaction(
                -$totalCost,
                'debit',
                'card_generation',
                "توليد عدد {$validated['count']} كرت بقيمة {$validated['amount']} ريال للكرت الواحد"
            );

            $generated = 0;
            while ($generated < $validated['count']) {
                $code = strtoupper(Str::random(12));

                if (!Card::where('code', $code)->exists()) {
                    Card::create([
                        'code' => $code,
                        'amount' => $validated['amount'],
                        'is_used' => false,
                        'generated_by_id' => $user->id,
                    ]);
                    $generated++;
                }
            }
        });

        return $this->success([
            'balance' => $user->fresh()->balance,
        ], "تم توليد {$validated['count']} كروت بنجاح.");
    }
}
