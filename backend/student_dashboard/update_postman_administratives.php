<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found at " . $filePath . "\n");
}

$json = json_decode(file_get_contents($filePath), true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing JSON: " . json_last_error_msg() . "\n");
}

// Define the Administrative Officials Menu
$adminMenu = [
    "name" => "16. Administrative Officials",
    "description" => "Admin API endpoints for managing College Admins (Administrative role).",
    "item" => [
        [
            "name" => "1. List Administrative Officials",
            "request" => [
                "method" => "GET",
                "header" => [
                    ["key" => "Accept", "value" => "application/json"]
                ],
                "url" => [
                    "raw" => "{{base_url}}/administratives?search=&college_id=&per_page=10",
                    "host" => ["{{base_url}}"],
                    "path" => ["administratives"],
                    "query" => [
                        ["key" => "search", "value" => "", "description" => "Search by name/email"],
                        ["key" => "college_id", "value" => "", "description" => "Filter by specific college"],
                        ["key" => "per_page", "value" => "10"]
                    ]
                ]
            ]
        ],
        [
            "name" => "2. Get Official Details",
            "request" => [
                "method" => "GET",
                "header" => [
                    ["key" => "Accept", "value" => "application/json"]
                ],
                "url" => [
                    "raw" => "{{base_url}}/administratives/1",
                    "host" => ["{{base_url}}"],
                    "path" => ["administratives", "1"]
                ]
            ]
        ],
        [
            "name" => "3. Create Administrative Official",
            "request" => [
                "method" => "POST",
                "header" => [
                    ["key" => "Accept", "value" => "application/json"],
                    ["key" => "Content-Type", "value" => "application/json"]
                ],
                "body" => [
                    "mode" => "raw",
                    "raw" => json_encode([
                        "name" => "Ahmed Administrator",
                        "email" => "ahmed_admin@example.com",
                        "password" => "password123",
                        "password_confirmation" => "password123",
                        "college_id" => 1,
                        "status" => "active"
                    ], JSON_PRETTY_PRINT)
                ],
                "url" => [
                    "raw" => "{{base_url}}/administratives",
                    "host" => ["{{base_url}}"],
                    "path" => ["administratives"]
                ]
            ]
        ],
        [
            "name" => "4. Update Administrative Official",
            "request" => [
                "method" => "PUT",
                "header" => [
                    ["key" => "Accept", "value" => "application/json"],
                    ["key" => "Content-Type", "value" => "application/json"]
                ],
                "body" => [
                    "mode" => "raw",
                    "raw" => json_encode([
                        "name" => "Ahmed Updated",
                        "email" => "ahmed_admin@example.com",
                        "college_id" => 1,
                        "status" => "active"
                    ], JSON_PRETTY_PRINT)
                ],
                "url" => [
                    "raw" => "{{base_url}}/administratives/1",
                    "host" => ["{{base_url}}"],
                    "path" => ["administratives", "1"]
                ]
            ]
        ],
        [
            "name" => "5. Delete Administrative Official",
            "request" => [
                "method" => "DELETE",
                "header" => [
                    ["key" => "Accept", "value" => "application/json"]
                ],
                "url" => [
                    "raw" => "{{base_url}}/administratives/1",
                    "host" => ["{{base_url}}"],
                    "path" => ["administratives", "1"]
                ]
            ]
        ]
    ]
];

$folderExists = false;
foreach ($json['item'] ?? [] as $index => $item) {
    if (str_contains(strtolower($item['name']), 'administrative officials')) {
        $json['item'][$index] = $adminMenu;
        $folderExists = true;
        break;
    }
}

if (!$folderExists) {
    $json['item'][] = $adminMenu;
}

$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

if (file_put_contents($filePath, $jsonContent)) {
    echo "\n\033[32mSuccess: 'Administrative Officials' API endpoints have been injected into the Postman collection!\033[0m\n\n";
} else {
    echo "\n\033[31mError writing to the file.\033[0m\n\n";
}
