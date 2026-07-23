<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found at " . $filePath . "\n");
}

$json = json_decode(file_get_contents($filePath), true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing JSON: " . json_last_error_msg() . "\n");
}

// Define the Registration Requests Menu
$regMenu = [
    "name" => "15. Registration Requests",
    "description" => "Admin API endpoints for managing pending user registrations.",
    "item" => [
        [
            "name" => "1. Get Pending Requests",
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
                    "raw" => "{{base_url}}/api/admin/registration-requests?search=&per_page=15",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "registration-requests" ],
                    "query" => [
                        [ "key" => "search", "value" => "", "description" => "Optional search term for name/email/phone" ],
                        [ "key" => "per_page", "value" => "15" ]
                    ]
                ]
            ]
        ],
        [
            "name" => "2. Approve Requests Bulk",
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
                        "user_ids" => [1, 2, 3]
                    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/registration-requests/approve",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "registration-requests", "approve" ]
                ]
            ]
        ],
        [
            "name" => "3. Reject Requests Bulk",
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
                        "user_ids" => [4, 5]
                    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/registration-requests/reject",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "registration-requests", "reject" ]
                ]
            ]
        ]
    ]
];

$folderExists = false;
foreach ($json['item'] ?? [] as $index => $item) {
    if (str_contains(strtolower($item['name']), 'registration requests')) {
        $json['item'][$index] = $regMenu;
        $folderExists = true;
        break;
    }
}

if (!$folderExists) {
    $json['item'][] = $regMenu;
}

$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

if (file_put_contents($filePath, $jsonContent)) {
    echo "\n\033[32mSuccess: 'Registration Requests' API endpoints have been injected into the Postman collection!\033[0m\n\n";
} else {
    echo "\n\033[31mError writing to the file.\033[0m\n\n";
}
