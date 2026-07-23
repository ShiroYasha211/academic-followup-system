<?php

namespace App\Services;

use App\Models\StudentNotification;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    public function sendStudentNotification(StudentNotification $notification): array
    {
        $notification->loadMissing('user');

        if (! $notification->user_id || ! $notification->user) {
            return ['sent' => 0, 'failed' => 0, 'skipped' => true, 'reason' => 'missing_recipient'];
        }

        return $this->sendToUser($notification->user, [
            'title' => $notification->title,
            'body' => $notification->message,
            'data' => $this->buildNotificationData($notification),
        ]);
    }

    public function sendBatchByBatchId(string $batchId): array
    {
        $notifications = StudentNotification::where('batch_id', $batchId)->with('user')->get();

        $sent = 0;
        $failed = 0;

        foreach ($notifications as $notification) {
            $result = $this->sendStudentNotification($notification);
            $sent += $result['sent'] ?? 0;
            $failed += $result['failed'] ?? 0;
        }

        return [
            'notifications' => $notifications->count(),
            'sent' => $sent,
            'failed' => $failed,
        ];
    }

    public function sendToUser(User $user, array $payload): array
    {
        $tokens = $user->devices()->pluck('device_token')->filter()->unique()->values();

        if ($tokens->isEmpty()) {
            Log::info('Push skipped because user has no registered device tokens.', [
                'user_id' => $user->id,
                'payload_type' => data_get($payload, 'data.type'),
            ]);

            return ['sent' => 0, 'failed' => 0, 'skipped' => true, 'reason' => 'no_device_tokens'];
        }

        if (! $this->isConfigured()) {
            Log::info('Push skipped because Firebase is not configured.', [
                'user_id' => $user->id,
                'tokens_count' => $tokens->count(),
            ]);

            return ['sent' => 0, 'failed' => 0, 'skipped' => true, 'reason' => 'firebase_not_configured'];
        }

        $accessToken = $this->getAccessToken();
        if (! $accessToken) {
            return ['sent' => 0, 'failed' => $tokens->count(), 'skipped' => false, 'reason' => 'access_token_failed'];
        }

        $sent = 0;
        $failed = 0;

        foreach ($tokens as $token) {
            $response = Http::withToken($accessToken)
                ->acceptJson()
                ->post($this->messagingEndpoint(), [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => (string) ($payload['title'] ?? ''),
                            'body' => (string) ($payload['body'] ?? ''),
                        ],
                        'data' => $this->normalizeData($payload['data'] ?? []),
                        'android' => [
                            'priority' => 'high',
                            'notification' => [
                                'sound' => 'default',
                                'channel_id' => 'default',
                            ],
                        ],
                        'apns' => [
                            'headers' => [
                                'apns-priority' => '10',
                            ],
                            'payload' => [
                                'aps' => [
                                    'sound' => 'default',
                                ],
                            ],
                        ],
                    ],
                ]);

            if ($response->successful()) {
                $sent++;
                continue;
            }

            $failed++;
            $this->handleFailedToken($token, $response->json());

            Log::warning('Push notification send failed.', [
                'user_id' => $user->id,
                'token_tail' => substr($token, -16),
                'status' => $response->status(),
                'body' => $response->json(),
            ]);
        }

        return ['sent' => $sent, 'failed' => $failed, 'skipped' => false];
    }

    public function isConfigured(): bool
    {
        $projectId = (string) config('services.firebase.project_id');
        $credentials = (string) config('services.firebase.credentials');

        return $projectId !== '' && $credentials !== '' && is_file($credentials);
    }

    protected function messagingEndpoint(): string
    {
        return 'https://fcm.googleapis.com/v1/projects/' . config('services.firebase.project_id') . '/messages:send';
    }

    protected function buildNotificationData(StudentNotification $notification): array
    {
        $workspace = match ($notification->user?->role?->value ?? $notification->user?->role) {
            'doctor' => 'doctor',
            'delegate', 'practical_delegate' => 'delegate',
            'admin' => 'admin',
            'administrative' => 'administrative',
            default => 'student',
        };

        $screen = $this->resolveScreen($notification->type, $workspace);

        return array_merge($notification->data ?? [], [
            'notification_id' => (string) $notification->id,
            'type' => (string) $notification->type,
            'batch_id' => (string) ($notification->batch_id ?? ''),
            'workspace' => $workspace,
            'screen' => $screen,
            'target_screen' => $screen,
            'title' => (string) $notification->title,
            'message' => (string) $notification->message,
        ]);
    }

    protected function resolveScreen(?string $type, string $workspace): string
    {
        return match ($type) {
            'message' => 'messages',
            'excuse' => 'excuses',
            'inquiry', 'doctor_inquiry' => 'inquiries',
            'star', 'stars' => 'stars',
            'quiz', 'quizzes' => 'quizzes',
            'grade_delegation' => 'authorized_grades',
            'administrative_access' => 'notifications',
            'flashcard_assignment' => 'flashcards',
            'assignment' => 'assignments',
            'study_reminder' => 'study_session',
            'schedule' => 'schedule',
            'reminder' => 'reminders',
            'attendance', 'attendance_confirmation', 'attendance_edit_request', 'absence_warning', 'lecture_report' => 'attendance',
            'resource' => 'resources',
            'library' => 'library',
            'rare_case', 'rare_cases' => 'rare_case',
            'clinical_assignment' => 'clinical',
            'exam', 'announcement', 'poll', 'alert' => $workspace === 'doctor' || $workspace === 'delegate' ? 'news' : 'news_hub',
            default => 'notifications',
        };
    }

    protected function normalizeData(array $data): array
    {
        $normalized = [];

        foreach ($data as $key => $value) {
            if (is_array($value) || is_object($value)) {
                $normalized[(string) $key] = json_encode($value, JSON_UNESCAPED_UNICODE);
            } elseif (is_bool($value)) {
                $normalized[(string) $key] = $value ? '1' : '0';
            } elseif ($value === null) {
                $normalized[(string) $key] = '';
            } else {
                $normalized[(string) $key] = (string) $value;
            }
        }

        return $normalized;
    }

    protected function handleFailedToken(string $token, ?array $body): void
    {
        $status = data_get($body, 'error.status');
        $message = (string) data_get($body, 'error.message', '');

        if (in_array($status, ['UNREGISTERED', 'INVALID_ARGUMENT'], true)
            || str_contains($message, 'registration token is not a valid FCM registration token')
            || str_contains($message, 'Requested entity was not found')) {
            UserDevice::where('device_token', $token)->delete();
        }
    }

    protected function getAccessToken(): ?string
    {
        $cacheKey = 'firebase_access_token_' . md5((string) config('services.firebase.project_id'));

        return Cache::remember($cacheKey, now()->addMinutes(50), function () {
            $credentialsPath = (string) config('services.firebase.credentials');
            if (! is_file($credentialsPath)) {
                return null;
            }

            $credentials = json_decode(file_get_contents($credentialsPath), true);
            if (! is_array($credentials) || empty($credentials['client_email']) || empty($credentials['private_key'])) {
                return null;
            }

            $now = time();
            $jwtHeader = $this->base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $jwtClaim = $this->base64UrlEncode(json_encode([
                'iss' => $credentials['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => $credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]));
            $unsignedJwt = $jwtHeader . '.' . $jwtClaim;

            $signature = '';
            $privateKey = openssl_pkey_get_private($credentials['private_key']);
            if (! $privateKey || ! openssl_sign($unsignedJwt, $signature, $privateKey, 'sha256WithRSAEncryption')) {
                return null;
            }

            $assertion = $unsignedJwt . '.' . $this->base64UrlEncode($signature);
            $response = Http::asForm()->post($credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $assertion,
            ]);

            if (! $response->successful()) {
                Log::warning('Firebase access token request failed.', ['body' => $response->json()]);
                return null;
            }

            return $response->json('access_token');
        });
    }

    protected function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
