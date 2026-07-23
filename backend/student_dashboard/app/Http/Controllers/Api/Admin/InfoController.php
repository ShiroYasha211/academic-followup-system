<?php

namespace App\Http\Controllers\Api\Admin;

use Illuminate\Http\Request;

class InfoController extends AdminApiController
{
    /**
     * GET /api/admin/info/developer
     */
    public function developer()
    {
        return $this->success([
            'name' => 'Mohammed Alhemyari',
            'title' => 'System Developer & Programmer',
            'bio' => 'Providing advanced and integrated software solutions for institutions and companies, with a focus on high quality, excellent performance, and exceptional user experience.',
            'contacts' => [
                'whatsapp' => '+967 773 468 708',
                'whatsapp_url' => 'https://wa.me/967773468708',
                'email' => 'alhemyarimohammed211@gmail.com',
                'github' => 'ShiroYasha211',
                'github_url' => 'https://github.com/ShiroYasha211',
                'linkedin_url' => 'https://linkedin.com/in/mohammed-alhemyari',
            ],
            'copyright' => '© ' . date('Y') . ' Mohammed Alhemyari - All Rights Reserved'
        ]);
    }

    /**
     * GET /api/admin/info/system
     */
    public function system()
    {
        return $this->success([
            'version' => '2.5.0',
            'laravel_version' => app()->version(),
            'php_version' => phpversion(),
            'environment' => app()->environment(),
            'last_sync' => now()->toDateTimeString(),
        ]);
    }
}
