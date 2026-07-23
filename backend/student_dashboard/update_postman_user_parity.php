<?php

$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

if (!file_exists($filePath)) {
    die("Error: Postman collection file not found.\n");
}

$json = json_decode(file_get_contents($filePath), true);

// 1. Find the Folders
$folders = ['👨‍🎓 Students', '👨‍🏫 Doctors', '🤝 Delegates'];
$folderItems = [];

foreach ($json['item'] as $index => $item) {
    if (in_array($item['name'], $folders)) {
        $folderItems[$item['name']] = &$json['item'][$index]['item'];
    }
}

// 2. Add 'Show' to Doctors
if (isset($folderItems['👨‍🏫 Doctors'])) {
    $hasShow = false;
    foreach ($folderItems['👨‍🏫 Doctors'] as $req) {
        if ($req['name'] === 'Show Doctor Details') $hasShow = true;
    }
    if (!$hasShow) {
        array_splice($folderItems['👨‍🏫 Doctors'], 1, 0, [[
            "name" => "Show Doctor Details",
            "request" => [
                "method" => "GET",
                "header" => [["key" => "Accept", "value" => "application/json"]],
                "url" => [
                    "raw" => "{{base_url}}/doctors/1",
                    "host" => ["{{base_url}}"],
                    "path" => ["doctors", "1"]
                ]
            ]
        ]]);
    }
}

// 3. Add 'Show' to Delegates
if (isset($folderItems['🤝 Delegates'])) {
    $hasShow = false;
    foreach ($folderItems['🤝 Delegates'] as $req) {
        if ($req['name'] === 'Show Delegate Details') $hasShow = true;
    }
    if (!$hasShow) {
        array_splice($folderItems['🤝 Delegates'], 1, 0, [[
            "name" => "Show Delegate Details",
            "request" => [
                "method" => "GET",
                "header" => [["key" => "Accept", "value" => "application/json"]],
                "url" => [
                    "raw" => "{{base_url}}/delegates/1",
                    "host" => ["{{base_url}}"],
                    "path" => ["delegates", "1"]
                ]
            ]
        ]]);
    }
}

// 4. Add 'Update Permissions' to Students
if (isset($folderItems['👨‍🎓 Students'])) {
    $hasPerms = false;
    foreach ($folderItems['👨‍🎓 Students'] as $req) {
        if ($req['name'] === 'Update Student Permissions') $hasPerms = true;
    }
    if (!$hasPerms) {
        $folderItems['👨‍🎓 Students'][] = [
            "name" => "Update Student Permissions",
            "request" => [
                "method" => "POST",
                "header" => [
                    ["key" => "Accept", "value" => "application/json"],
                    ["key" => "Content-Type", "value" => "application/json"]
                ],
                "body" => [
                    "mode" => "raw",
                    "raw" => json_encode([
                        "permissions" => ["can_post_materials", "can_edit_schedule"]
                    ], JSON_PRETTY_PRINT)
                ],
                "url" => [
                    "raw" => "{{base_url}}/students/1/permissions",
                    "host" => ["{{base_url}}"],
                    "path" => ["students", "1", "permissions"]
                ]
            ],
            "description" => "تحديث صلاحيات الطالب أو المندوب للتحكم في الوصول للمواد أو الجدول."
        ];
    }
}

$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
file_put_contents($filePath, $jsonContent);

echo "\n\033[32mSuccess: Doctor, Student, and Delegate APIs have been synchronized in Postman with Full Deletion support!\033[0m\n\n";
