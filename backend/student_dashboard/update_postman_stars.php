<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found at " . $filePath . "\n");
}

$json = json_decode(file_get_contents($filePath), true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing JSON: " . json_last_error_msg() . "\n");
}

// Define the Star Management Folder
$starsMenu = [
    "name" => "14. Star Management",
    "description" => "Admin API endpoints for listing eligible students and granting/deducting stars.",
    "item" => [
        [
            "name" => "1. Get Students for Star Granting",
            "request" => [
                "auth" => [
                    "type" => "bearer",
                    "bearer" => [
                        [ "key" => "token", "value" => "{{admin_token}}", "type" => "string" ]
                    ]
                ],
                "method" => "GET",
                "header" => [
                    [ "key" => "Accept", "value" => "application/json", "type" => "text" ]
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/stars/students?university_id=1&search=&per_page=20",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "stars", "students" ],
                    "query" => [
                        [ "key" => "university_id", "value" => "1", "description" => "Optional filter" ],
                        [ "key" => "college_id", "value" => "", "description" => "Optional filter" ],
                        [ "key" => "major_id", "value" => "", "description" => "Optional filter" ],
                        [ "key" => "level_id", "value" => "", "description" => "Optional filter" ],
                        [ "key" => "search", "value" => "", "description" => "Optional search term for name/email" ],
                        [ "key" => "per_page", "value" => "20" ]
                    ]
                ]
            ]
        ],
        [
            "name" => "2. Evaluate Students (Grant/Deduct Stars)",
            "request" => [
                "auth" => [
                    "type" => "bearer",
                    "bearer" => [
                        [ "key" => "token", "value" => "{{admin_token}}", "type" => "string" ]
                    ]
                ],
                "method" => "POST",
                "header" => [
                    [ "key" => "Accept", "value" => "application/json", "type" => "text" ],
                    [ "key" => "Content-Type", "value" => "application/json", "type" => "text" ]
                ],
                "body" => [
                    "mode" => "raw",
                    "raw" => json_encode([
                        "student_ids" => [1, 2, 3],
                        "amount" => 10,
                        "description" => "Active participation in the main event"
                    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/stars/grant",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "stars", "grant" ]
                ],
                "description" => "Grants (positive amount) or deducts (negative amount) stars from multiple students."
            ]
        ]
    ]
];

$folderExists = false;
foreach ($json['item'] ?? [] as $index => $item) {
    if (str_contains(strtolower($item['name']), 'star management')) {
        $json['item'][$index] = $starsMenu;
        $folderExists = true;
        break;
    }
}

if (!$folderExists) {
    $json['item'][] = $starsMenu;
}

$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

if (file_put_contents($filePath, $jsonContent)) {
    echo "\n\033[32mSuccess: 'Star Management' API endpoints have been injected into the Postman collection!\033[0m\n\n";
} else {
    echo "\n\033[31mError writing to the file.\033[0m\n\n";
}
