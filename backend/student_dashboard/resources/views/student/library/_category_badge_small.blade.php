@php
$catColors = [
'lectures' => ['bg' => 'rgba(59,130,246,0.1)', 'color' => '#3b82f6', 'label' => 'محاضرات'],
'summaries' => ['bg' => 'rgba(16,185,129,0.1)', 'color' => '#10b981', 'label' => 'ملخصات'],
'exams' => ['bg' => 'rgba(239,68,68,0.1)', 'color' => '#ef4444', 'label' => 'اختبارات'],
'references' => ['bg' => 'rgba(245,158,11,0.1)', 'color' => '#f59e0b', 'label' => 'مراجع'],
];
$cat = $catColors[$category] ?? ['bg' => '#f1f5f9', 'color' => '#64748b', 'label' => 'أخرى'];
@endphp
<span style="background: {{ $cat['bg'] }}; color: {{ $cat['color'] }}; padding: 0.1rem 0.5rem; border-radius: 8px; font-size: 0.7rem; font-weight: 700;">{{ $cat['label'] }}</span>