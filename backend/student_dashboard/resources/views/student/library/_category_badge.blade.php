@switch($category)
@case('lectures')
<span style="display: inline-flex; align-items: center; gap: 0.35rem; background: rgba(59, 130, 246, 0.1); color: #3b82f6; padding: 0.3rem 0.75rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">
    <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> محاضرات
</span>
@break
@case('summaries')
<span style="display: inline-flex; align-items: center; gap: 0.35rem; background: rgba(16, 185, 129, 0.1); color: #10b981; padding: 0.3rem 0.75rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">
    <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> ملخصات
</span>
@break
@case('exams')
<span style="display: inline-flex; align-items: center; gap: 0.35rem; background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 0.3rem 0.75rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">
    <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> اختبارات
</span>
@break
@case('references')
<span style="display: inline-flex; align-items: center; gap: 0.35rem; background: rgba(245, 158, 11, 0.1); color: #f59e0b; padding: 0.3rem 0.75rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">
    <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> مراجع
</span>
@break
@default
<span style="display: inline-flex; align-items: center; gap: 0.35rem; background: #f1f5f9; color: #64748b; padding: 0.3rem 0.75rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">
    <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> أخرى
</span>
@endswitch