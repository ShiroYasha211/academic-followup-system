<?php

namespace App\Http\Controllers\Administrative;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\DoctorStarWalletService;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class DoctorController extends Controller
{
    use LogsActivity;

    public function __construct(private readonly DoctorStarWalletService $wallets)
    {
    }

    public function index()
    {
        $college = auth()->user()->college;
        if (!$college) {
            abort(403, 'حسابك غير مرتبط بكلية. يرجى التواصل مع مدير النظام.');
        }

        $doctors = User::where('college_id', $college->id)
            ->where('role', UserRole::DOCTOR)
            ->with(['subjects.term.level.major', 'doctorStarWallet'])
            ->latest()
            ->paginate(15);

        foreach ($doctors->getCollection() as $doctor) {
            if (!$doctor->doctorStarWallet) {
                $doctor->setRelation('doctorStarWallet', $this->wallets->initialize($doctor));
            }
        }

        return view('administrative.doctors.index', compact('doctors', 'college'));
    }

    public function store(Request $request)
    {
        $college = auth()->user()->college;
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
        ], [
            'email.unique' => 'البريد الإلكتروني مسجل مسبقًا.',
        ]);

        $doctor = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => UserRole::DOCTOR,
            'college_id' => $college->id,
            'university_id' => $college->university_id,
            'status' => 'active',
        ]);
        $this->wallets->initialize($doctor, $request->user());

        $this->logCreate('Doctor', $doctor, "تمت إضافة الدكتور: {$doctor->name} بواسطة مسؤول الكلية");

        return redirect()->route('administrative.doctors.index')
            ->with('success', 'تمت إضافة الدكتور بنجاح.');
    }

    public function update(Request $request, User $doctor)
    {
        $college = auth()->user()->college;
        if ($doctor->college_id !== $college->id || $doctor->role !== UserRole::DOCTOR) {
            abort(403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $doctor->id,
            'password' => 'nullable|string|min:8',
        ]);

        $updateData = [
            'name' => $validated['name'],
            'email' => $validated['email'],
        ];
        if (!empty($validated['password'])) {
            $updateData['password'] = Hash::make($validated['password']);
        }

        $doctor->update($updateData);
        $this->logUpdate('Doctor', $doctor, "تم تعديل بيانات الدكتور: {$doctor->name} بواسطة مسؤول الكلية");

        return redirect()->route('administrative.doctors.index')
            ->with('success', 'تم تحديث بيانات الدكتور بنجاح.');
    }

    public function destroy(User $doctor)
    {
        $college = auth()->user()->college;
        if ($doctor->college_id !== $college->id || $doctor->role !== UserRole::DOCTOR) {
            return back()->with('error', 'لا يمكن حذف هذا المستخدم.');
        }

        $this->logDelete('Doctor', $doctor, "تم حذف الدكتور: {$doctor->name} بواسطة مسؤول الكلية");
        $doctor->delete();

        return redirect()->route('administrative.doctors.index')
            ->with('success', 'تم حذف الدكتور بنجاح.');
    }

    public function topUpStarWallet(Request $request, User $doctor)
    {
        $college = $request->user()->college;
        if (!$college || $doctor->college_id !== $college->id || $doctor->role !== UserRole::DOCTOR) {
            abort(403);
        }

        $validated = $request->validate([
            'amount' => 'required|integer|min:1|max:1000000',
            'reason' => 'required|string|max:255',
        ]);

        $wallet = $this->wallets->topUp(
            $request->user(),
            $doctor,
            $validated['amount'],
            $validated['reason'],
        );

        $this->logActivity(
            'doctor_star_wallet_top_up',
            'Doctor',
            $doctor,
            "تمت إضافة {$validated['amount']} نجمة إلى رصيد منح الدكتور {$doctor->name}. الرصيد الحالي: {$wallet->balance}.",
        );

        return back()->with(
            'success',
            "تمت إضافة {$validated['amount']} نجمة إلى رصيد الدكتور. الرصيد الحالي {$wallet->balance} نجمة.",
        );
    }
}
