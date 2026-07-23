<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found.\n");
}

$json = json_decode(file_get_contents($filePath), true);

$finalModules = [
    [
        "name" => "21. Practical Delegates",
        "item" => [
            ["name" => "List Clinical Majors", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/clinical-delegates"]]],
            ["name" => "Assign Practical Delegate", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["major_id" => 1, "student_id" => 1], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/clinical-delegates"]
            ]],
            ["name" => "Remove Delegate", "request" => ["method" => "DELETE", "url" => ["raw" => "{{base_url}}/clinical-delegates/1"]]]
        ]
    ],
    [
        "name" => "22. Reports & Statistics",
        "item" => [
            ["name" => "System Overview Stats", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/reports/system-overview"]]],
            ["name" => "Subject Attendance Report", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/reports/subject?subject_id=1"]]],
            ["name" => "Threshold (Warning) Report", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/reports/threshold?level_id=1&threshold=25"]]],
            ["name" => "Doctor Performance", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/reports/doctor-performance"]]]
        ]
    ],
    [
        "name" => "23. Activity Log",
        "item" => [
            ["name" => "View Logs (Filterable)", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/activities?action=create&model_type=Package"]]],
            ["name" => "Cleanup Old Logs", "request" => ["method" => "POST", "url" => ["raw" => "{{base_url}}/activities/cleanup"]]]
        ]
    ],
    [
        "name" => "24. Storage Management",
        "item" => [
            ["name" => "Global Storage Stats", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/storage/stats"]]],
            ["name" => "List All System Files", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/storage/files?type=resource&search="]]],
            ["name" => "Delete File (Free up Space)", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["type" => "resource", "id" => 1], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/storage/delete"]
            ]]
        ]
    ]
];

// Add headers to all
foreach ($finalModules as &$folder) {
    foreach ($folder['item'] as &$item) {
        $item['request']['header'] = [["key" => "Accept", "value" => "application/json"], ["key" => "Content-Type", "value" => "application/json"]];
    }
}

// Inject
foreach ($finalModules as $newFolder) {
    $exists = false;
    foreach ($json['item'] as $idx => $existing) {
        if ($existing['name'] === $newFolder['name']) {
            $json['item'][$idx] = $newFolder;
            $exists = true;
            break;
        }
    }
    if (!$exists) $json['item'][] = $newFolder;
}

$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
file_put_contents($filePath, $jsonContent);

echo "\n\033[32mFinal Success: All 24 Admin Modules have been synchronized in Postman!\033[0m\n\n";
