<?php

// Path to the postman collection file
$filePath = __DIR__ . '/Attendify_Admin_API.postman_collection.json';

// Ensure the file exists
if (!file_exists($filePath)) {
    die("Error: Postman collection file not found at " . $filePath . "\n");
}

// Read the collection JSON
$json = json_decode(file_get_contents($filePath), true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing JSON: " . json_last_error_msg() . "\n");
}

// Define the Quizzes Folder to append
$quizzesMenu = [
    "name" => "13. Quizzes Management",
    "description" => "Admin API endpoints for managing quizzes, models, and assigning targets.",
    "item" => [
        [
            "name" => "1. Get All Quizzes",
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
                    "raw" => "{{base_url}}/api/admin/quizzes",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes" ]
                ]
            ]
        ],
        [
            "name" => "2. Get Single Quiz Details & Models",
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
                    "raw" => "{{base_url}}/api/admin/quizzes/1",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes", "1" ]
                ]
            ]
        ],
        [
            "name" => "3. Create Quiz (Models, Questions, Options)",
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
                        "subject_id" => null,
                        "title" => "General Knowledge Quiz",
                        "description" => "A test quiz for all universities",
                        "time_limit_minutes" => 30,
                        "shuffle_questions" => true,
                        "shuffle_options" => true,
                        "results_visibility" => "public",
                        "models" => [
                            [
                                "name" => "Form A",
                                "questions" => [
                                    [
                                        "question_text" => "What is 2+2?",
                                        "question_type" => "multiple_choice",
                                        "score" => 2,
                                        "options" => [
                                            [ "option_text" => "3", "is_correct" => false ],
                                            [ "option_text" => "4", "is_correct" => true ]
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        "targets" => [
                            [
                                "university_id" => null,
                                "college_id" => null,
                                "major_id" => null,
                                "level_id" => null
                            ]
                        ]
                    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/quizzes",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes" ]
                ]
            ]
        ],
        [
            "name" => "4. Delete Quiz",
            "request" => [
                "auth" => [
                    "type" => "bearer",
                    "bearer" => [
                        [ "key" => "token", "value" => "{{admin_token}}", "type" => "string" ]
                    ]
                ],
                "method" => "DELETE",
                "header" => [
                    [ "key" => "Accept", "value" => "application/json", "type" => "text" ]
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/quizzes/1",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes", "1" ]
                ]
            ]
        ],
        [
            "name" => "5. Publish Quiz",
            "request" => [
                "auth" => [
                    "type" => "bearer",
                    "bearer" => [
                        [ "key" => "token", "value" => "{{admin_token}}", "type" => "string" ]
                    ]
                ],
                "method" => "POST",
                "header" => [
                    [ "key" => "Accept", "value" => "application/json", "type" => "text" ]
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/quizzes/1/publish",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes", "1", "publish" ]
                ]
            ]
        ],
        [
            "name" => "6. Close Quiz",
            "request" => [
                "auth" => [
                    "type" => "bearer",
                    "bearer" => [
                        [ "key" => "token", "value" => "{{admin_token}}", "type" => "string" ]
                    ]
                ],
                "method" => "POST",
                "header" => [
                    [ "key" => "Accept", "value" => "application/json", "type" => "text" ]
                ],
                "url" => [
                    "raw" => "{{base_url}}/api/admin/quizzes/1/close",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes", "1", "close" ]
                ]
            ]
        ],
        [
            "name" => "7. Get Quiz Results & Student Attempts",
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
                    "raw" => "{{base_url}}/api/admin/quizzes/1/results",
                    "host" => [ "{{base_url}}" ],
                    "path" => [ "api", "admin", "quizzes", "1", "results" ]
                ]
            ]
        ]
    ]
];

// Check if Quizzes Management folder already exists to avoid duplicates
$folderExists = false;
foreach ($json['item'] ?? [] as $index => $item) {
    if (str_contains(strtolower($item['name']), 'quizzes')) {
        // Overwrite existing
        $json['item'][$index] = $quizzesMenu;
        $folderExists = true;
        break;
    }
}

if (!$folderExists) {
    // Append to the root items
    $json['item'][] = $quizzesMenu;
}

// Verify auth header placement (sometimes postman wraps root array uniquely)
$jsonContent = json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

if (file_put_contents($filePath, $jsonContent)) {
    echo "\n\033[32mSuccess: 'Quizzes Management' API endpoints have been injected into Postman collection!\033[0m\n\n";
} else {
    echo "\n\033[31mError writing to the file.\033[0m\n\n";
}
