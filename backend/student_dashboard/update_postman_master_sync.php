<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found.\n");
}

$json = json_decode(file_get_contents($filePath), true);

$finalModules = [
    [
        "name" => "25. Medical Departments",
        "item" => [
            ["name" => "List Departments", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/clinical/departments"]]],
            ["name" => "Create Department", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["name" => "Surgery", "description" => "General Surgery"], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/clinical/departments"]
            ]],
            ["name" => "Delete Department", "request" => ["method" => "DELETE", "url" => ["raw" => "{{base_url}}/clinical/departments/1"]]]
        ]
    ],
    [
        "name" => "26. Body Systems (Devices)",
        "item" => [
            ["name" => "List Systems", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/clinical/body-systems"]]],
            ["name" => "Create System", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["name" => "Cardiology", "description" => "Heart and vessels"], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/clinical/body-systems"]
            ]]
        ]
    ],
    [
        "name" => "27. Evaluation Checklists",
        "item" => [
            ["name" => "List Checklists", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/clinical/checklists"]]],
            ["name" => "Full Checklist Creation (Nested)", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode([
                    "title" => "History Taking",
                    "skill_type" => "history_taking",
                    "items" => [
                        [
                            "description" => "Patient Identification",
                            "marks" => 10,
                            "sub_items" => [
                                ["description" => "Ask Name", "marks" => 5],
                                ["description" => "Ask Age", "marks" => 5]
                            ]
                        ]
                    ]
                ], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/clinical/checklists"]
            ]]
        ]
    ],
    [
        "name" => "28. Protection & Security",
        "item" => [
            ["name" => "Change Current Admin Password", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["old_password" => "password", "new_password" => "new_secure_pass123", "new_password_confirmation" => "new_secure_pass123"], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/change-password"]
            ]]
        ]
    ],
    [
        "name" => "29. Developer & System Info",
        "item" => [
            ["name" => "Get Developer Info", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/info/developer"]]],
            ["name" => "System Status", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/info/system"]]]
        ]
    ],
    [
        "name" => "30. Advanced Settings",
        "item" => [
            ["name" => "Update Logo (Form-Data Support)", "request" => [
                "method" => "POST", 
                "description" => "Send as POST with _method: PUT and Multipart/form-data for file uploads",
                "body" => ["mode" => "formdata", "formdata" => [
                    ["key" => "site_logo", "type" => "file", "src" => ""],
                    ["key" => "_method", "value" => "PUT", "type" => "text"]
                ]],
                "url" => ["raw" => "{{base_url}}/settings"]
            ]]
        ]
    ]
];

// Add headers
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

echo "\n\033[32mFinal Mission Accomplished: All 30 Admin API Folders synchronized!\033[0m\n\n";
