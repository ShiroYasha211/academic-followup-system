<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>معاينة - {{ $flashcard->title }}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.rtl.min.css">
    <style>
        body { background: #f8fafc; }
        .preview-card { border-radius: 24px; }
    </style>
</head>
<body>
    <div class="container py-5">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 fw-bold mb-1">{{ $flashcard->title }}</h1>
                <div class="text-secondary">{{ $items->count() }} عنصر داخل المعاينة</div>
            </div>
            <a href="{{ route('admin.flashcards.show', $flashcard) }}" class="btn btn-light border fw-bold">العودة</a>
        </div>

        <div class="row g-3">
            @foreach($items as $item)
                <div class="col-lg-6">
                    <div class="card preview-card border-0 shadow-sm h-100">
                        <div class="card-body p-4">
                            <div class="d-flex flex-wrap gap-2 mb-3">
                                <span class="badge text-white" style="background: {{ $item->resolved_color }};">{{ $item->item_type_label }}</span>
                                <span class="badge bg-light text-dark">{{ $item->priority_text }}</span>
                                <span class="badge bg-light text-secondary">{{ $item->pack->title }}</span>
                            </div>
                            <div class="fw-bold text-dark mb-3">{{ $item->front_content }}</div>
                            @if($item->back_content)
                                <div class="text-secondary mb-3">{{ $item->back_content }}</div>
                            @endif
                            @if($item->resolved_item_type === 'mcq' && is_array($item->options))
                                <ul class="list-group list-group-flush">
                                    @foreach($item->options as $index => $option)
                                        <li class="list-group-item px-0 {{ $index === (int) $item->correct_option ? 'text-success fw-bold' : '' }}">
                                            {{ $option }}
                                        </li>
                                    @endforeach
                                </ul>
                            @endif
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    </div>
</body>
</html>
