@if(session('success'))
<div class="alert alert-success alert-dismissible fade show border-0 shadow-sm mb-4" role="alert" style="border-radius: 12px; background: #f0fdf4; color: #166534;">
    <div class="d-flex align-items-center">
        <div class="alert-icon-wrap me-3" style="background: #dcfce7; padding: 10px; border-radius: 10px;">
            <i class="fas fa-check-circle" style="font-size: 1.2rem;"></i>
        </div>
        <div>
            <h6 class="alert-heading mb-1 fw-bold">نجاح العملية</h6>
            <p class="mb-0 small">{{ session('success') }}</p>
        </div>
    </div>
    <button type="button" class="btn-close shadow-none" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
@endif

@if(session('error'))
<div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm mb-4" role="alert" style="border-radius: 12px; background: #fef2f2; color: #991b1b;">
    <div class="d-flex align-items-center">
        <div class="alert-icon-wrap me-3" style="background: #fee2e2; padding: 10px; border-radius: 10px;">
            <i class="fas fa-exclamation-circle" style="font-size: 1.2rem;"></i>
        </div>
        <div>
            <h6 class="alert-heading mb-1 fw-bold">خطأ في التنفيذ</h6>
            <p class="mb-0 small">{{ session('error') }}</p>
        </div>
    </div>
    <button type="button" class="btn-close shadow-none" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
@endif

@if(session('info'))
<div class="alert alert-info alert-dismissible fade show border-0 shadow-sm mb-4" role="alert" style="border-radius: 12px; background: #f0f9ff; color: #075985;">
    <div class="d-flex align-items-center">
        <div class="alert-icon-wrap me-3" style="background: #e0f2fe; padding: 10px; border-radius: 10px;">
            <i class="fas fa-info-circle" style="font-size: 1.2rem;"></i>
        </div>
        <div>
            <h6 class="alert-heading mb-1 fw-bold">تنبيه</h6>
            <p class="mb-0 small">{{ session('info') }}</p>
        </div>
    </div>
    <button type="button" class="btn-close shadow-none" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
@endif

@if ($errors->any())
<div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm mb-4" role="alert" style="border-radius: 12px; background: #fef2f2; color: #991b1b;">
    <div class="d-flex align-items-center">
        <div class="alert-icon-wrap me-3" style="background: #fee2e2; padding: 10px; border-radius: 10px;">
            <i class="fas fa-times-circle" style="font-size: 1.2rem;"></i>
        </div>
        <div>
            <h6 class="alert-heading mb-1 fw-bold">خطأ في البيانات</h6>
            <ul class="mb-0 ps-3 small">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    </div>
    <button type="button" class="btn-close shadow-none" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
@endif

<style>
    .alert {
        transition: transform 0.3s ease-out, opacity 0.3s ease-out;
    }
    .alert:hover {
        transform: translateY(-2px);
    }
    .btn-close:focus {
        box-shadow: none;
    }
</style>
