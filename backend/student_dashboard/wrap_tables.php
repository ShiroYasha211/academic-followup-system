<?php
$dir = __DIR__ . '/resources/views';

$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS),
    RecursiveIteratorIterator::SELF_FIRST
);

$filesModified = 0;

foreach ($iterator as $file) {
    if ($file->isFile() && $file->getExtension() === 'php') {
        $content = file_get_contents($file->getPathname());
        
        // Skip files that are meant to be exported directly (PDF/Excel)
        if (strpos($file->getPathname(), 'pdf') !== false || strpos($file->getPathname(), 'export') !== false) {
            continue;
        }

        $originalContent = $content;

        // The goal is to wrap a <table>...</table> block in <div class="table-responsive">...</div>
        // But ONLY if it's not already inside a table-responsive or table-container div.
        
        // A simple approach using regex
        // Match <table ...> ... </table> in a greedy way considering multiple tables? No, non-greedy.
        // It's safer to just inject the wrapper. However, regex on HTML can be tricky.
        
        // Pattern: find <table ...> up to </table>
        $pattern = '/(<table\b[^>]*>.*?<\/table>)/is';
        
        $content = preg_replace_callback($pattern, function($matches) {
            $tableHTML = $matches[1];
            // If it already has something indicating it's wrapped (we'd need to look outside, which is hard in regex).
            // Let's just always wrap it if it doesn't already have a div class="table-responsive" wrapping it.
            // Actually, we can just replace ALL tables with the wrapper. If they get double-wrapped, it's harmless as overflow-x: auto on two divs doesn't break anything!
            return '<div class="table-responsive">' . "\n" . $tableHTML . "\n" . '</div>';
        }, $content);
        
        // Remove double wraps if they accidentally got created
        $content = str_replace('<div class="table-responsive">' . "\n" . '<div class="table-responsive">', '<div class="table-responsive">', $content);
        $content = str_replace('</div>' . "\n" . '</div>', '</div>', $content);

        // Also, replace Laravel's built in w-full or similar if it's there
        if ($content !== $originalContent) {
            file_put_contents($file->getPathname(), $content);
            $filesModified++;
        }
    }
}

echo "Modified $filesModified blade files to make tables responsive.\n";
