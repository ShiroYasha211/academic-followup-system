@extends('layouts.admin')

@section('title', 'طلبات إنشاء حساب')

@section('content')

<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">طلبات إنشاء حساب</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">مراجعة واعتماد الحسابات الجديدة المعلقة.</p>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
@endif

@if(session('error'))
    <div class="alert alert-danger">{{ session('error') }}</div>
@endif

<div class="card">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 1rem;">
        <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">الحسابات قيد المراجعة</h3>
        <span class="badge badge-warning" style="font-size: 0.85rem;">{{ $pendingRequests->total() }} طلب</span>
    </div>

    <div class="table-container">
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th style="width: 50px;">#</th>
                        <th>المستخدم</th>
                        <th>نوع الحساب</th>
                        <th>البيانات الأكاديمية</th>
                        <th>تاريخ الطلب</th>
                        <th style="width: 170px; text-align: center;">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($pendingRequests as $request)
                        <tr>
                            <td>{{ $loop->iteration + ($pendingRequests->currentPage() - 1) * $pendingRequests->perPage() }}</td>
                            <td>
                                <div style="font-weight: 700; color: var(--text-primary);">{{ $request->name }}</div>
                                <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ $request->email }}</div>
                            </td>
                            <td>
                                @if($request->role->value === 'doctor')
                                    <span class="badge badge-primary">دكتور</span>
                                @elseif($request->role->value === 'delegate')
                                    <span class="badge badge-info">مندوب</span>
                                @elseif($request->role->value === 'student')
                                    <span class="badge" style="background:#f1f5f9; color:#64748b;">طالب</span>
                                @else
                                    <span class="badge">{{ $request->role->value }}</span>
                                @endif
                            </td>
                            <td>
                                @if(in_array($request->role->value, ['student', 'delegate']))
                                    <div style="font-size: 0.9rem; color: var(--text-primary);">
                                        <strong>الجامعة:</strong> {{ $request->university->name ?? '-' }}<br>
                                        <strong>الكلية:</strong> {{ $request->college->name ?? '-' }}<br>
                                        <strong>التخصص:</strong> {{ $request->major->name ?? '-' }}<br>
                                        <strong>المستوى:</strong> {{ $request->level->name ?? '-' }}<br>
                                        <strong>الرقم الجامعي:</strong> {{ $request->student_number ?? '-' }}
                                    </div>
                                @elseif($request->role->value === 'doctor')
                                    <div style="font-size: 0.9rem; color: var(--text-primary);">
                                        <strong>الجامعة:</strong> {{ $request->university->name ?? '-' }}<br>
                                        <strong>الكلية:</strong> {{ $request->college->name ?? '-' }}
                                    </div>
                                @else
                                    <span style="color: var(--text-light); font-size: 0.85rem;">-</span>
                                @endif
                            </td>
                            <td style="color: var(--text-secondary); font-size: 0.9rem;">
                                {{ $request->created_at->format('Y/m/d H:i') }}<br>
                                <span style="font-size: 0.8rem;">{{ $request->created_at->diffForHumans() }}</span>
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem; justify-content: center;">
                                    <form action="{{ route('admin.registration_requests.approve', $request->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من اعتماد وتفعيل هذا الحساب؟');">
                                        @csrf
                                        <button type="submit" class="btn" style="padding: 0.5rem 1rem; background: #d1fae5; color: #059669; font-size: 0.9rem; font-weight: bold;">
                                            اعتماد
                                        </button>
                                    </form>

                                    <form action="{{ route('admin.registration_requests.reject', $request->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من رفض وحذف هذا الطلب؟');">
                                        @csrf
                                        <button type="submit" class="btn" style="padding: 0.5rem 1rem; background: #fee2e2; color: #dc2626; font-size: 0.9rem; font-weight: bold;">
                                            رفض
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                                لا توجد طلبات معلقة حاليًا.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div style="padding-top: 1.5rem;">
        {{ $pendingRequests->links('pagination::bootstrap-5') }}
    </div>
</div>

@endsection
