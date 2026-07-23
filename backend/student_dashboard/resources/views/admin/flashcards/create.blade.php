@extends('layouts.admin')

@section('title', 'إنشاء Oneline Shot جديد')

@section('content')
<div class="mb-5">
    <!-- Page Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="fw-black mb-1">إطلاق حزمة Oneline Shot</h2>
            <p class="text-secondary m-0">قم بإعداد حزمة جديدة لنشر محتوى تعليمي تفاعلي للطلاب</p>
        </div>
        <a href="{{ route('admin.flashcards.index') }}" class="btn btn-light rounded-4 px-4 fw-bold border">
            <i class="fa-solid fa-arrow-right-long me-2"></i>
            رجوع للحزم
        </a>
    </div>

    @if($errors->any())
        <div class="alert alert-danger rounded-4 mb-4 border-0 shadow-sm p-4">
            <h6 class="fw-black mb-3"><i class="fa-solid fa-triangle-exclamation me-2"></i>يرجى تصحيح الأخطاء التالية:</h6>
            <ul class="mb-0 small">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('admin.flashcards.store') }}" method="POST">
        @csrf
        @include('admin.flashcards.form_fields')
</form>
</div>

<style>
    .fw-black { font-weight: 900 !important; }
    .premium-card {
        background: white;
        border: 1px solid #f1f5f9;
        border-radius: 24px;
        box-shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.05);
        transition: all 0.3s;
    }
</style>
@endsection
