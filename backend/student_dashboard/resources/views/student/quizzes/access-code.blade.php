@extends('layouts.student')

@section('title', 'رمز الدخول مطلوب')

@section('content')
<style>
    .access-container {
        max-width: 500px;
        margin: 4rem auto;
        text-align: center;
    }

    .access-card {
        background: white;
        border-radius: 24px;
        padding: 3rem 2rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        border: 1px solid #e2e8f0;
    }

    .access-icon {
        width: 80px;
        height: 80px;
        background: #fef3c7;
        color: #d97706;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 2rem;
        margin: 0 auto 1.5rem;
    }

    .access-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 0.5rem;
    }

    .access-subtitle {
        color: #64748b;
        font-size: 0.95rem;
        margin-bottom: 2rem;
    }

    .code-input-wrapper {
        position: relative;
        margin-bottom: 1.5rem;
    }

    .code-input {
        width: 100%;
        padding: 1rem;
        border: 2px solid #e2e8f0;
        border-radius: 16px;
        font-size: 1.5rem;
        font-weight: 800;
        text-align: center;
        letter-spacing: 0.5rem;
        text-transform: uppercase;
        transition: all 0.2s;
    }

    .code-input:focus {
        outline: none;
        border-color: #6366f1;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
    }

    .btn-start {
        width: 100%;
        padding: 1rem;
        background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
        color: white;
        border: none;
        border-radius: 16px;
        font-weight: 700;
        font-size: 1.1rem;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
    }

    .btn-start:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 20px rgba(79, 70, 229, 0.3);
    }

    .alert-error {
        background: #fee2e2;
        color: #ef4444;
        padding: 0.75rem;
        border-radius: 12px;
        font-size: 0.85rem;
        margin-bottom: 1.5rem;
        font-weight: 600;
    }
</style>

<div class="access-container">
    <div class="access-card">
        <div class="access-icon">
            <i class="fa-solid fa-lock"></i>
        </div>
        <h1 class="access-title">رمز الدخول مطلوب</h1>
        <p class="access-subtitle">هذا الكويز محمي برمز دخول. يرجى الحصول على الرمز من الدكتور المختص لبدء الاختبار.</p>

        @if(session('error'))
            <div class="alert-error">
                <i class="fa-solid fa-circle-exclamation me-1"></i> {{ session('error') }}
            </div>
        @endif

        <form action="{{ route('student.quizzes.take', $quiz) }}" method="GET">
            <div class="code-input-wrapper">
                <input type="text" 
                       name="access_code" 
                       class="code-input" 
                       placeholder="XXXXXX" 
                       maxlength="6" 
                       required 
                       autocomplete="off"
                       autofocus>
            </div>
            
            <button type="submit" class="btn-start">
                <i class="fa-solid fa-door-open"></i> دخول الاختبار
            </button>
        </form>

        <a href="{{ route('student.quizzes.index') }}" class="text-secondary small mt-4 d-block" style="text-decoration: none;">
            <i class="fa-solid fa-arrow-right me-1"></i> العودة لقائمة الكويزات
        </a>
    </div>
</div>
@endsection
