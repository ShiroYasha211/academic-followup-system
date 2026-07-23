<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Card;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CardController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = Card::with(['usedBy:id,name,email', 'generatedBy:id,name,email'])->latest();

        if ($request->has('status')) {
            if ($request->status == 'used') {
                $query->where('is_used', true);
            } elseif ($request->status == 'unused') {
                $query->where('is_used', false);
            }
        }

        if ($request->has('search')) {
            $query->where('code', 'like', "%{$request->search}%");
        }

        if ($request->filled('generated_by_id')) {
            $query->where('generated_by_id', $request->integer('generated_by_id'));
        }

        if ($request->filled('used_by_id')) {
            $query->where('used_by_id', $request->integer('used_by_id'));
        }

        return $this->paginated($query->paginate($request->per_page ?? 30));
    }

    public function generate(Request $request)
    {
        $request->validate([
            'count' => 'required|integer|min:1|max:500',
            'amount' => 'required|numeric|min:1',
        ]);

        $count = $request->count;
        $amount = $request->amount;
        $generated = 0;
        $codes = [];

        while ($generated < $count) {
            $code = strtoupper(Str::random(12));
            
            if (!Card::where('code', $code)->exists()) {
                Card::create([
                    'code' => $code,
                    'amount' => $amount,
                    'is_used' => false,
                ]);
                $codes[] = $code;
                $generated++;
            }
        }

        ActivityLog::log('create', 'Card', null, "Batch ($count)", "توليد {$count} كرت عبر الـ API بقيمة {$amount} ريال.");

        return $this->success($codes, "تم توليد {$count} كروت بنجاح.");
    }

    public function destroy(Card $card)
    {
        if ($card->is_used) {
            return $this->error('لا يمكن حذف كرت تم استخدامه بالفعل.', 422);
        }

        $card->delete();
        ActivityLog::log('delete', 'Card', $card->id, $card->code, "حذف كرت غير مستخدم عبر الـ API: {$card->code}");

        return $this->success(null, 'تم حذف الكرت بنجاح.');
    }
}
