@extends('layouts.administrative')

@section('title', 'بث إعلان جديد')

@section('content')

<style>
    .page-header {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 20px;
        padding: 2rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .glass-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .form-label-premium {
        display: block;
        margin-bottom: 0.75rem;
        font-size: 0.95rem;
        font-weight: 800;
        color: #1e293b;
    }

    .input-premium {
        width: 100%;
        padding: 1rem 1.25rem;
        border: 1.5px solid #edf2f7;
        border-radius: 14px;
        background: #f8fafc;
        font-weight: 600;
        outline: none;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .input-premium:focus {
        border-color: #6366f1;
        background-color: white;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
    }

    select.input-premium {
        padding-top: 0;
        padding-bottom: 0;
        appearance: none;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%23475569' stroke-width='2'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: left 1rem center;
        background-size: 1.2rem;
    }

    .file-drop-area {
        border: 2px dashed #cbd5e1;
        border-radius: 20px;
        padding: 2rem;
        text-align: center;
        background: #f8fafc;
        transition: all 0.2s;
        cursor: pointer;
    }

    .file-drop-area:hover {
        border-color: #6366f1;
        background: #fdfefe;
    }

    .sidebar-card {
        background: #f8fafc;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid #e2e8f0;
    }
</style>

<div class="page-header">
    <div style="display: flex; justify-content: space-between; align-items: center;">
        <div>
            <nav style="margin-bottom: 1rem;">
                <a href="{{ route('administrative.notifications.index') }}" style="color: rgba(255,255,255,0.7); text-decoration: none; font-size: 0.9rem; font-weight: 600; display: flex; align-items: center; gap: 0.5rem;">
                    <i class="fa-solid fa-arrow-right"></i> العودة للمركز
                </a>
            </nav>
            <h1 style="font-size: 2rem; font-weight: 800; margin: 0;">بث إعلان جديد</h1>
        </div>
        <i class="fa-solid fa-paper-plane" style="font-size: 3rem; opacity: 0.2;"></i>
    </div>
</div>

<div x-data="notificationForm()">
    <form action="{{ route('administrative.notifications.store') }}" method="POST" enctype="multipart/form-data">
        @csrf

        <div style="display: grid; grid-template-columns: 1fr 340px; gap: 2rem;">
            
            <div style="display: flex; flex-direction: column; gap: 2rem;">
                <!-- Main Form Area -->
                <div class="glass-card">
                    <div style="margin-bottom: 2rem;">
                        <label class="form-label-premium">عنوان الإعلان</label>
                        <input type="text" name="title" value="{{ old('title') }}" required 
                               placeholder="أدخل عنواناً واضحاً وموجزاً..." class="input-premium">
                        @error('title') <span style="color: #e11d48; font-size: 0.85rem; font-weight: 700; margin-top: 0.5rem; display: block;">{{ $message }}</span> @enderror
                    </div>

                    <div style="margin-bottom: 2rem;">
                        <label class="form-label-premium">نص الإعلان بالتفصيل</label>
                        <textarea name="message" rows="12" required 
                                  placeholder="اكتب هنا محتوى الإعلان الذي سيظهر للطلاب..." class="input-premium" style="resize: vertical; min-height: 200px;">{{ old('message') }}</textarea>
                        @error('message') <span style="color: #e11d48; font-size: 0.85rem; font-weight: 700; margin-top: 0.5rem; display: block;">{{ $message }}</span> @enderror
                    </div>

                    <div>
                        <label class="form-label-premium">المرفقات (صور أو مستندات)</label>
                        <div class="file-drop-area" onclick="document.getElementById('attachment').click()">
                            <input type="file" name="attachment" id="attachment" style="display: none;" onchange="updateFileName(this)">
                            <div style="font-size: 2.5rem; color: #94a3b8; margin-bottom: 1rem;"><i class="fa-solid fa-cloud-arrow-up"></i></div>
                            <div style="font-weight: 800; color: #1e293b; margin-bottom: 0.25rem;">اسحب الملف هنا أو انقر للتصفح</div>
                            <div id="file_name_display" style="font-size: 0.85rem; color: #64748b; font-weight: 600;">PDF, JPG, PNG, DOCX (Max 10MB)</div>
                        </div>
                        @error('attachment') <span style="color: #e11d48; font-size: 0.85rem; font-weight: 700; margin-top: 0.5rem; display: block; text-align: center;">{{ $message }}</span> @enderror
                    </div>
                </div>
            </div>

            <!-- Settings Sidebar -->
            <div style="display: flex; flex-direction: column; gap: 1.5rem;">
                <div class="glass-card" style="padding: 1.5rem;">
                    <h3 style="font-size: 1.1rem; font-weight: 800; color: #1e293b; margin-bottom: 1.5rem; border-bottom: 2px solid #f1f5f9; padding-bottom: 1rem;">خيارات البث</h3>
                    
                    <div style="margin-bottom: 1.5rem;">
                        <label class="form-label-premium" style="font-size: 0.85rem;">نوع الإعلان</label>
                        <select name="type" x-model="type" class="input-premium" style="height: 48px; border-radius: 12px;">
                            <option value="announcement">📢 إعلان عام</option>
                            <option value="exam">📅 موعد اختبار</option>
                            <option value="assignment">📄 تكليف دراسي</option>
                            <option value="attendance">🛑 تنبيه حضور</option>
                            <option value="poll">📊 استفتاء للرأي</option>
                        </select>
                    </div>

                    <!-- Poll Settings -->
                    <template x-if="type == 'poll'">
                        <div style="margin-bottom: 1.5rem; background: #f1f5f9; padding: 1rem; border-radius: 16px; animation: slideIn 0.3s ease;">
                            <label class="form-label-premium" style="font-size: 0.85rem;">خيارات التصويت</label>
                            <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                                <template x-for="(option, index) in pollOptions" :key="index">
                                    <div style="display: flex; gap: 0.4rem;">
                                        <input type="text" name="poll_options[]" x-model="pollOptions[index]" placeholder="خيار التصويت..." class="input-premium" style="height: 40px; border-radius: 10px; font-size: 0.85rem;">
                                        <button type="button" @click="removeOption(index)" x-show="pollOptions.length > 2" style="width: 40px; height: 40px; border-radius: 10px; border: 1px solid #fecdd3; background: white; color: #e11d48;"><i class="fa-solid fa-trash"></i></button>
                                    </div>
                                </template>
                            </div>
                            <button type="button" @click="addOption" x-show="pollOptions.length < 8" style="margin-top: 0.75rem; width: 100%; height: 36px; border-radius: 10px; border: 1.5px dashed #cbd5e1; background: white; color: #64748b; font-size: 0.85rem; font-weight: 700; cursor: pointer;">+ إضافة خيار</button>
                        </div>
                    </template>

                    <div style="margin-bottom: 1.5rem;">
                        <label class="form-label-premium" style="font-size: 0.85rem;">الجمهور المستهدف</label>
                        <select name="target" x-model="target" class="input-premium" style="height: 48px; border-radius: 12px;">
                            <option value="all">الكل</option>
                            <option value="major">قسم معين</option>
                            <option value="level">مستوى محدد</option>
                            <option value="doctors">أعضاء التدريس</option>
                            <option value="delegates">المناديب</option>
                        </select>
                    </div>

                    <!-- Targeted Selectors -->
                    <template x-if="target == 'major' || target == 'level'">
                        <div style="margin-bottom: 1rem; animation: slideIn 0.2s ease;">
                            <label class="form-label-premium" style="font-size: 0.8rem;">اختر القسم</label>
                            <select name="major_id" x-model="majorId" class="input-premium" style="height: 44px; border-radius: 10px; font-size: 0.9rem;">
                                <option value="">--- القسم ---</option>
                                @foreach($majors as $major)
                                    <option value="{{ $major->id }}">{{ $major->name }}</option>
                                @endforeach
                            </select>
                        </div>
                    </template>

                    <template x-if="target == 'level'">
                        <div style="margin-bottom: 1rem; animation: slideIn 0.2s ease;">
                            <label class="form-label-premium" style="font-size: 0.8rem;">اختر المستوى</label>
                            <select name="level_id" id="level_select" class="input-premium" style="height: 44px; border-radius: 10px; font-size: 0.9rem;">
                                <option value="">--- المستوى ---</option>
                            </select>
                        </div>
                    </template>

                    <button type="submit" style="width: 100%; height: 54px; background: #1e1b4b; color: white; border: none; border-radius: 16px; font-weight: 800; font-size: 1.1rem; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; gap: 0.75rem;">
                        <i class="fa-solid fa-cloud-arrow-up"></i> بث الآن
                    </button>
                    <button type="button" onclick="history.back()" style="width: 100%; margin-top: 0.75rem; height: 50px; background: white; color: #64748b; border: 1.5px solid #edf2f7; border-radius: 16px; font-weight: 700; cursor: pointer;">إلغاء</button>
                </div>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<style>
    @keyframes slideIn { from { opacity: 0; transform: translateY(-5px); } to { opacity: 1; transform: translateY(0); } }
</style>
<script>
    function updateFileName(input) {
        const display = document.getElementById('file_name_display');
        if (input.files && input.files[0]) {
            display.innerHTML = `<span style="color: #10b981;"><i class="fa-solid fa-check"></i> تم اختيار: ${input.files[0].name}</span>`;
        }
    }

    document.addEventListener('alpine:init', () => {
        Alpine.data('notificationForm', () => ({
            target: '{{ old('target', 'all') }}',
            type: '{{ old('type', 'announcement') }}',
            majorId: '{{ old('major_id', '') }}',
            pollOptions: ['{{ old('poll_options.0', '') }}', '{{ old('poll_options.1', '') }}'],
            addOption() { if (this.pollOptions.length < 10) this.pollOptions.push(''); },
            removeOption(index) { if (this.pollOptions.length > 2) this.pollOptions.splice(index, 1); },
            init() {
                this.$watch('target', value => { if (value === 'level') this.$nextTick(() => this.loadLevels()); });
                this.$watch('majorId', value => { if (this.target === 'level') this.loadLevels(); });
            },
            loadLevels() {
                const ls = document.getElementById('level_select');
                if (!ls || !this.majorId) return;
                ls.innerHTML = '<option value="">جاري التحميل...</option>';
                fetch(`/administrative/majors/${this.majorId}/levels`, { headers: {'X-Requested-With': 'XMLHttpRequest'} })
                .then(r => r.json()).then(res => {
                    ls.innerHTML = '<option value="">--- المستوى ---</option>';
                    (res.data || []).forEach(l => {
                        const o = document.createElement('option'); o.value = l.id; o.textContent = l.name; ls.appendChild(o);
                    });
                });
            }
        }));
    });
</script>
@endpush

@endsection
