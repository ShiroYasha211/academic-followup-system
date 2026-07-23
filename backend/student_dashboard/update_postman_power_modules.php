<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found at " . $filePath . "\n");
}

$json = json_decode(file_get_contents($filePath), true);

$powerModules = [
    [
        "name" => "17. Delegate Transfer",
        "item" => [
            ["name" => "List Batches with Delegates", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/delegate-transfer"]]],
            ["name" => "Batch Details (Current vs Eligible)", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/delegate-transfer/1/1"]]],
            ["name" => "Execute Transfer (Swap Roles)", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["old_delegate_id" => 1, "new_delegate_id" => 2, "major_id" => 1, "level_id" => 1], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/delegate-transfer/execute"]
            ]]
        ]
    ],
    [
        "name" => "18. Subscription Packages",
        "item" => [
            ["name" => "List Packages", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/packages"]]],
            ["name" => "Create Package", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode([
                    "name" => "باقة السنة الدراسية", "price_student" => 50, "price_doctor" => 0, 
                    "price_delegate" => 30, "price_administrative" => 40, "duration_days" => 365, "is_active" => true
                ], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/packages"]
            ]],
            ["name" => "Toggle Status", "request" => ["method" => "POST", "url" => ["raw" => "{{base_url}}/packages/1/toggle"]]],
            ["name" => "List Subscribers", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/packages/1/subscribers"]]],
            ["name" => "Cancel Subscription (with Refund)", "request" => [
                "method" => "POST",
                "url" => ["raw" => "{{base_url}}/subscriptions/1/cancel?refund=1"]
            ]]
        ]
    ],
    [
        "name" => "19. Recharge Cards",
        "item" => [
            ["name" => "List Cards", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/cards?status=unused&search="]]],
            ["name" => "Generate Bulk Cards", "request" => [
                "method" => "POST",
                "body" => ["mode" => "raw", "raw" => json_encode(["count" => 10, "amount" => 100], JSON_PRETTY_PRINT)],
                "url" => ["raw" => "{{base_url}}/cards/generate"]
            ]]
        ]
    ],
    [
        "name" => "20. Financial Management",
        "item" => [
            ["name" => "Financial Stats Overview", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/finance/stats"]]],
            ["name" => "Transaction History (Search & Filter)", "request" => ["method" => "GET", "url" => ["raw" => "{{base_url}}/finance/transactions?type=deposit&search="]]]
        ]
    ]
];

// Clean items structure and add headers
foreach ($powerModules as &$folder) {
    foreach ($folder['item'] as &$item) {
        $item['request']['header'] = [["key" => "Accept", "value" => "application/json"], ["key" => "Content-Type", "value" => "application/json"]];
    }
}

// Inject or Update
foreach ($powerModules as $newFolder) {
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

echo "\n\033[32mSuccess: 4 Power Modules (17-20) have been synchronized in Postman!\033[0m\n\n";
