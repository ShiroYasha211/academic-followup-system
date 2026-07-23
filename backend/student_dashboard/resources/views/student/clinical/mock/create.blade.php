@extends('layouts.student')
@section('title', 'إنشاء نموذج تجريبي مخصص')
@section('content')
<style>
    .create-header {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        margin-bottom: 2rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .form-group {
        margin-bottom: 1.5rem;
    }

    .form-label {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 600;
        color: #334155;
    }

    .form-control {
        width: 100%;
        padding: 0.75rem 1rem;
        border: 1px solid #cbd5e1;
        border-radius: 10px;
        font-family: inherit;
        transition: border-color 0.2s, box-shadow 0.2s;
    }

    .form-control:focus {
        outline: none;
        border-color: #4f46e5;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .btn-create {
        background: #4f46e5;
        color: white;
        border: none;
        padding: 0.75rem 2rem;
        border-radius: 10px;
        font-weight: 700;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 1rem;
        transition: background 0.2s;
    }

    .btn-create:hover {
        background: #4338ca;
    }

    .btn-action {
        background: #f1f5f9;
        color: #334155;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: background 0.2s;
    }

    .btn-action:hover {
        background: #e2e8f0;
    }

    .header-actions {
        display: flex;
        justify-content: flex-end;
        gap: 1rem;
        margin-top: 2rem;
        flex-wrap: wrap;
    }

    .items-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 2rem;
    }

    .item-row {
        display: flex;
        gap: 1rem;
        align-items: flex-start;
        padding: 1rem;
        background: #f8fafc;
        border: 1px dashed #cbd5e1;
        border-radius: 12px;
        margin-bottom: 1rem;
        position: relative;
    }

    .btn-remove-item {
        background: #fee2e2;
        color: #ef4444;
        border: none;
        width: 36px;
        height: 36px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: background 0.2s;
        margin-top: 28px;
    }

    .btn-remove-item:hover {
        background: #fecaca;
    }

    .btn-add-item {
        background: #f0fdf4;
        color: #16a34a;
        border: 2px dashed #bbf7d0;
        width: 100%;
        padding: 1rem;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        transition: all 0.2s;
        margin-bottom: 1rem;
    }

    .btn-add-item:hover {
        background: #dcfce7;
        border-color: #86efac;
    }

    .sub-item-row {
        display: flex;
        gap: 0.75rem;
        align-items: center;
        background: white;
        padding: 0.75rem;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
        margin-top: 0.5rem;
    }

    .btn-add-sub {
        background: transparent;
        color: #64748b;
        border: 1px dashed #cbd5e1;
        padding: 0.4rem 0.8rem;
        border-radius: 6px;
        font-size: 0.8rem;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        margin-top: 0.75rem;
        transition: all 0.2s;
    }

    .btn-add-sub:hover {
        background: white;
        color: #4f46e5;
        border-color: #4f46e5;
    }

    .error-text {
        color: #ef4444;
        font-size: 0.85rem;
        margin-top: 0.25rem;
    }
</style>

<div x-data="mockChecklistForm()">
    <div class="create-header">
        <div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem;">
            <div style="width: 48px; height: 48px; border-radius: 12px; background: rgba(79, 70, 229, 0.1); color: #4f46e5; display: flex; align-items: center; justify-content: center;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 20h9"></path>
                    <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path>
                </svg>
            </div>
            <div>
                <h1 style="font-size: 1.4rem; font-weight: 800; color: #1e293b; margin: 0;">نموذج تجريبي مخصص (Private)</h1>
                <p style="color: #64748b; margin: 0.25rem 0 0 0; font-size: 0.95rem;">قم ببناء نموذج التقييم الخاص بك للتدرب عليه بشكل شخصي. هذا النموذج سيظهر لك أنت فقط ولن يراه الطلاب الآخرون.</p>
            </div>
        </div>
    </div>

    @if ($errors->any())
    <div style="background: #fef2f2; border: 1px solid #fecaca; padding: 1rem 1.5rem; border-radius: 12px; margin-bottom: 2rem; color: #b91c1c;">
        <ul style="margin: 0; padding-right: 1.5rem;">
            @foreach ($errors->all() as $error)
            <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
    @endif

    <form action="{{ route('student.clinical.mock.store_custom') }}" method="POST">
        @csrf

        <div class="items-section">
            <h3 style="font-weight: 800; margin-bottom: 1.5rem; color: #1e293b;">معلومات النموذج الأساسية</h3>

            <div class="form-group">
                <label class="form-label" for="title">موضوع التقييم (العنوان) <span style="color: #ef4444;">*</span></label>
                <input type="text" id="title" name="title" class="form-control" required placeholder="مثال: فحص الجهاز التنفسي، استجواب مريض سكري..." value="{{ old('title') }}">
            </div>

            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label" for="description">ملاحظات قصيرة (اختياري)</label>
                <textarea id="description" name="description" class="form-control" rows="2" placeholder="أية تفاصيل إضافية تود تذكرها عن هذا التقييم...">{{ old('description') }}</textarea>
            </div>
        </div>

        <div class="items-section">
            <h3 style="font-weight: 800; margin-bottom: 0.5rem; color: #1e293b;">بنود التقييم السريري (الأسئلة)</h3>
            <p style="color: #64748b; margin-bottom: 1.5rem; font-size: 0.9rem;">أضف الخطوات أو المهارات المراد التدرب عليها وتقييمها، مع تحديد العلامة العظمى لكل عنصر.</p>

            <template x-for="(item, index) in items" :key="item.id">
                <div class="item-row" style="flex-direction: column;">
                    <div style="display: flex; gap: 1rem; width: 100%; align-items: flex-start;">
                        <div style="flex: 1;">
                            <label class="form-label" x-text="`عنوان رئيسي رقم ${index + 1}`"></label>
                            <input type="text" class="form-control" x-model="item.description" :name="`items[${index}][description]`" required placeholder="مثال: الفحص العام، استجواب المريض..." oninvalid="this.setCustomValidity('يرجى وصف البند')" oninput="this.setCustomValidity('')">
                        </div>

                        <div style="width: 120px;">
                            <label class="form-label">الدرجة الكلية</label>
                            <input type="number" class="form-control" x-model="item.marks" :name="`items[${index}][marks]`" :class="{'border-red-500': !isSubmarksValid(index)}" required min="1" step="0.5">
                        </div>

                        <button type="button" class="btn-remove-item" @click="removeItem(item.id)" x-show="items.length > 1" title="حذف هذا البند">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M3 6h18"></path>
                                <path d="M19 6L18 20a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path>
                            </svg>
                        </button>
                    </div>

                    <div style="width: 100%; padding-right: 2rem; border-right: 2px dashed #cbd5e1; margin-top: 0.5rem;" x-show="item.sub_items.length > 0">
                        <template x-for="(sub, sIndex) in item.sub_items" :key="sub.id">
                            <div class="sub-item-row">
                                <span style="color:#94a3b8; font-weight:bold;">↳</span>
                                <input type="text" class="form-control" style="font-size: 0.85rem; padding: 0.5rem;" x-model="sub.description" :name="`items[${index}][sub_items][${sIndex}][description]`" required placeholder="بند فرعي (مثال: غسيل اليدين)...">
                                <input type="number" class="form-control" style="width: 80px; font-size: 0.85rem; padding: 0.5rem;" x-model="sub.marks" :name="`items[${index}][sub_items][${sIndex}][marks]`" required min="1" step="0.5" placeholder="الدرجة">
                                <button type="button" class="btn-remove-item" style="width: 28px; height: 28px; margin-top: 0;" @click="removeSubItem(index, sub.id)" title="حذف الفرع">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"></path><path d="M19 6L18 20a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg>
                                </button>
                            </div>
                        </template>
                        
                        <div x-show="!isSubmarksValid(index)" style="color: #ef4444; font-size: 0.8rem; margin-top: 0.5rem;">
                            ⚠️ مجموع درجات البنود الفرعية لا يطابق الدرجة الكلية للبند الرئيسي!
                        </div>
                    </div>

                    <button type="button" class="btn-add-sub" @click="addSubItem(index)">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                        إضافة تفصيل فرعي
                    </button>
                </div>
            </template>

            <button type="button" class="btn-add-item" @click="addItem()">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                إضافة بند تقييم جديد
            </button>

            <div style="background: #f8fafc; padding: 1rem; border-radius: 10px; margin-top: 1rem; text-align: left;">
                <strong style="color: #475569;">مجموع درجات النموذج: <span x-text="totalMarks" style="color: #0f172a; font-size: 1.2rem;"></span> بونط</strong>
            </div>

        </div>

        <div class="header-actions">
            <a href="{{ route('student.clinical.mock.index') }}" class="btn-action">
                إلغاء الأمر
            </a>
            <button type="submit" class="btn-create" :disabled="items.length === 0">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                    <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    <polyline points="7 3 7 8 15 8"></polyline>
                </svg>
                حفظ وإنشاء النموذج
            </button>
        </div>
    </form>
</div>

<script>
    document.addEventListener('alpine:init', () => {
        Alpine.data('mockChecklistForm', () => ({
            nextId: Date.now(),
            items: [{
                    id: Date.now(),
                    description: '',
                    marks: 10,
                    sub_items: []
                }
            ],

            addItem() {
                this.items.push({
                    id: ++this.nextId,
                    description: '',
                    marks: 10,
                    sub_items: []
                });
            },

            removeItem(id) {
                if (this.items.length > 1) {
                    this.items = this.items.filter(item => item.id !== id);
                }
            },

            addSubItem(index) {
                this.items[index].sub_items.push({
                    id: ++this.nextId,
                    description: '',
                    marks: 2
                });
            },

            removeSubItem(itemIndex, subId) {
                this.items[itemIndex].sub_items = this.items[itemIndex].sub_items.filter(sub => sub.id !== subId);
            },

            isSubmarksValid(index) {
                const item = this.items[index];
                if (item.sub_items.length === 0) return true;
                const subTotal = item.sub_items.reduce((sum, sub) => sum + (parseFloat(sub.marks) || 0), 0);
                return subTotal === parseFloat(item.marks);
            },

            get totalMarks() {
                return this.items.reduce((sum, item) => sum + (parseFloat(item.marks) || 0), 0);
            }
        }));
    });
</script>
@endsection