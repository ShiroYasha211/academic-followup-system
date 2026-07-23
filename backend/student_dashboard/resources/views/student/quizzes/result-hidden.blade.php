@extends('layouts.student')

@section('title', 'نتائج الكويز')

@section('content')
<div style="max-width: 500px; margin: 4rem auto; text-align: center;">
    <div style="background: white; border-radius: 24px; padding: 3rem; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <div style="font-size: 4rem; color: #94a3b8; margin-bottom: 1.5rem;">
            <i class="fa-solid fa-eye-slash"></i>
        </div>
        <h2 style="font-size: 1.5rem; font-weight: 800; color: #1e293b; margin-bottom: 0.5rem;">النتائج مخفية</h2>
        <p style="color: #64748b; margin-bottom: 1.5rem;">لقد أكملت هذا الكويز بنجاح. النتائج الحالية مخفية بقرار من الدكتور.</p>

        <div style="background: #f8fafc; border-radius: 14px; padding: 1rem; margin-bottom: 1.5rem;">
            <div style="font-size: 0.85rem; color: #475569; font-weight: 600;">{{ $quiz->title }}</div>
            <div style="font-size: 0.75rem; color: #94a3b8;">تم التسليم {{ $attempt->submitted_at?->diffForHumans() ?? '—' }}</div>
        </div>

        <a href="{{ route('student.quizzes.index') }}" style="background: #f1f5f9; color: #475569; padding: 0.6rem 1.5rem; border-radius: 12px; font-weight: 700; text-decoration: none; display: inline-flex; align-items: center; gap: 0.4rem;">
            <i class="fa-solid fa-arrow-right"></i> العودة للكويزات
        </a>
    </div>
</div>
@endsection
