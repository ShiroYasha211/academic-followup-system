@extends(
    request()->is('admin/*') ? 'layouts.admin' : 
    (request()->is('doctor/*') ? 'layouts.doctor' : 
    (request()->is('delegate/*') ? 'layouts.delegate' : 
    (request()->is('administrative/*') ? 'layouts.administrative' : 'layouts.student')))
)

@section('title', 'تغيير كلمة المرور')

@section('content')
<div class="card" style="max-width: 600px; margin: 0 auto;">
    <div class="card-header">
        <h3 class="card-title">تغيير كلمة المرور</h3>
    </div>
    <div class="card-body">
        
        @if (session('success'))
            <div class="alert alert-success">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
                <span>{{ session('success') }}</span>
            </div>
        @endif

        @if ($errors->any())
            <div class="alert alert-error" style="background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem;">
                <ul style="padding-right: 1.5rem; margin: 0;">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route(
            request()->is('admin/*') ? 'admin.profile.password.update' : 
            (request()->is('doctor/*') ? 'doctor.profile.password.update' : 
            (request()->is('delegate/*') ? 'delegate.profile.password.update' : 
            (request()->is('administrative/*') ? 'administrative.profile.password.update' : 'student.profile.password.update')))
        ) }}" method="POST" x-data="{ showCurrent: false, showNew: false, showConfirm: false }">
            @csrf
            @method('PUT')

            <!-- Current Password -->
            <div class="form-group mb-4">
                <label for="current_password" class="form-label" style="font-weight: 600; margin-bottom: 0.5rem; display: block;">كلمة المرور الحالية</label>
                <div style="position: relative;">
                    <input :type="showCurrent ? 'text' : 'password'" name="current_password" id="current_password" class="form-control" required style="width: 100%; padding: 0.75rem 1rem; border: 1px solid var(--border-color); border-radius: 8px;">
                    <button type="button" @click="showCurrent = !showCurrent" style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: var(--text-secondary);">
                        <svg x-show="!showCurrent" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                        <svg x-cloak x-show="showCurrent" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>
                    </button>
                </div>
            </div>

            <!-- New Password -->
            <div class="form-group mb-4">
                <label for="password" class="form-label" style="font-weight: 600; margin-bottom: 0.5rem; display: block;">كلمة المرور الجديدة</label>
                <div style="position: relative;">
                    <input :type="showNew ? 'text' : 'password'" name="password" id="password" class="form-control" required minlength="8" style="width: 100%; padding: 0.75rem 1rem; border: 1px solid var(--border-color); border-radius: 8px;">
                    <button type="button" @click="showNew = !showNew" style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: var(--text-secondary);">
                        <svg x-show="!showNew" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                        <svg x-cloak x-show="showNew" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>
                    </button>
                </div>
                <small style="color: var(--text-secondary); margin-top: 0.5rem; display: block;">يجب أن تكون 8 أحرف على الأقل.</small>
            </div>

            <!-- Confirm New Password -->
            <div class="form-group mb-4">
                <label for="password_confirmation" class="form-label" style="font-weight: 600; margin-bottom: 0.5rem; display: block;">تأكيد كلمة المرور الجديدة</label>
                <div style="position: relative;">
                    <input :type="showConfirm ? 'text' : 'password'" name="password_confirmation" id="password_confirmation" class="form-control" required minlength="8" style="width: 100%; padding: 0.75rem 1rem; border: 1px solid var(--border-color); border-radius: 8px;">
                    <button type="button" @click="showConfirm = !showConfirm" style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: var(--text-secondary);">
                        <svg x-show="!showConfirm" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                        <svg x-cloak x-show="showConfirm" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>
                    </button>
                </div>
            </div>

            <button type="submit" class="btn btn-primary" style="width: 100%; padding: 0.75rem; font-size: 1.05rem; font-weight: bold; margin-top: 1rem;">
                حفظ كلمة المرور الجديدة
            </button>
        </form>
    </div>
</div>

<style>
    [x-cloak] { display: none !important; }
</style>
@endsection
