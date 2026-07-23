<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found at " . $filePath . "\n");
}

$json = json_decode(file_get_contents($filePath), true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing JSON: " . json_last_error_msg() . "\n");
}

// Find the "User Management" folder
$userManagementIndex = -1;
foreach ($json['item'] as $index => $item) {
    if (str_contains($item['name'], 'User Management')) {
        $userManagementIndex = $index;
        break;
    }
}

if ($userManagementIndex === -1) {
    die("Error: 'User Management' folder not found in collection.\n");
}

$items = &$json['item'][$userManagementIndex]['item'];

// 1. Update "List Users" role description
foreach ($items as &$requestItem) {
    if ($requestItem['name'] === 'List Users') {
        foreach ($requestItem['request']['url']['query'] as &$queryParam) {
            if ($queryParam['key'] === 'role') {
                $queryParam['description'] = "student|doctor|delegate|practical_delegate|administrative|admin|all";
            }
        }
    }
}

// 2. Define New Requests
$newRequests = [
    [
        "name" => "Export Users CSV",
        "request" => [
            "method" => "GET",
            "header" => [
                ["key" => "Accept", "value" => "application/json"]
            ],
            "url" => [
                "raw" => "{{base_url}}/users/export?role=all",
                "host" => ["{{base_url}}"],
                "path" => ["users", "export"],
                "query" => [
                    ["key" => "role", "value" => "all", "description" => "Filter by role before export"]
                ]
            ],
            "description" => "تصدير قائمة المستخدمين الحالية إلى ملف CSV مع تطبيق الفلاتر المختارة."
        ]
    ],
    [
        "name" => "Reset User Password",
        "request" => [
            "method" => "POST",
            "header" => [
                ["key" => "Accept", "value" => "application/json"],
                ["key" => "Content-Type", "value" => "application/json"]
            ],
            "body" => [
                "mode" => "raw",
                "raw" => json_encode([
                    "new_password" => "new_secure_password_123"
                ], JSON_PRETTY_PRINT)
            ],
            "url" => [
                "raw" => "{{base_url}}/users/2/reset-password",
                "host" => ["{{base_url}}"],
                "path" => ["users", "2", "reset-password"]
            ],
            "description" => "تغيير كلمة المرور لمستخدم معين بواسطة الإدارة."
        ]
    ],
    [
        "name" => "Kick User Session",
        "request" => [
            "method" => "POST",
            "header" => [
                ["key" => "Accept", "value" => "application/json"]
            ],
            "url" => [
                "raw" => "{{base_url}}/users/2/kick",
                "host" => ["{{base_url}}"],
                "path" => ["users", "2", "kick"]
            ],
            "description" => "طرد المستخدم من كافة الجلسات النشطة حالياً."
        ]
    ],
    [
        "name" => "Activate Manual Subscription",
        "request" => [
            "method" => "POST",
            "header" => [
                ["key" => "Accept", "value" => "application/json"],
                ["key" => "Content-Type", "value" => "application/json"]
            ],
            "body" => [
                "mode" => "raw",
                "raw" => json_encode([
                    "days" => 30
                ], JSON_PRETTY_PRINT)
            ],
            "url" => [
                "raw" => "{{base_url}}/users/2/activate-subscription",
                "host" => ["{{base_url}}"],
                "path" => ["users", "2", "activate-subscription"]
            ],
            "description" => "تفعيل اشتراك يدوي للمستخدم لعدد معين من الأيام."
        ]
    ]
];

// 3. Append missing requests avoiding duplicates
foreach ($newRequests as $newReq) {
    $exists = false;
    foreach ($items as $existingReq) {
        if ($existingReq['name'] === $newReq['name']) {
            $exists = true;
            break;
        }
    }
    if (!$exists) {
        $items[] = $newReq;
    }
}

$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

if (file_put_contents($filePath, $jsonContent)) {
    echo "\n\033[32mSuccess: 'User Management' requests have been synchronized in Postman collection!\033[0m\n\n";
} else {
    echo "\n\033[31mError writing to the file.\033[0m\n\n";
}
