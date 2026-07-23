@extends('layouts.admin')

@section('title', 'إعدادات النظام')

@section('content')

<style>
    /* Premium Page Header */
    .premium-header {
        background: white;
        border-radius: 20px;
        border: 1px solid rgba(226, 232, 240, 0.8);
        padding: 1.5rem 2rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        margin-bottom: 2rem;
        box-shadow: 0 4px 20px -2px rgba(148, 163, 184, 0.04);
    }

    .premium-header-icon {
        width: 52px;
        height: 52px;
        background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 14px rgba(99, 102, 241, 0.35);
    }

    .premium-header-text h1 {
        font-size: 1.35rem;
        font-weight: 850;
        color: var(--text-primary);
        margin: 0 0 0.25rem 0;
    }

    .premium-header-text p {
        color: var(--text-secondary);
        font-size: 0.85rem;
        margin: 0;
    }

    /* Premium Alert Layouts */
    .premium-alert {
        padding: 1.25rem 1.5rem;
        border-radius: 16px;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        font-weight: 500;
        font-size: 0.95rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.02);
    }

    .premium-alert-success {
        background: #f0fdf4;
        border: 1px solid #bbf7d0;
        color: #166534;
    }

    .premium-alert-error {
        background: #fef2f2;
        border: 1px solid #fecaca;
        color: #991b1b;
    }

    .premium-alert-icon {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border-radius: 8px;
        flex-shrink: 0;
    }

    .premium-alert-success .premium-alert-icon {
        background: #dcfce7;
        color: #166534;
    }

    .premium-alert-error .premium-alert-icon {
        background: #fee2e2;
        color: #991b1b;
    }

    /* Premium Settings Layout Grid */
    .settings-grid {
        display: grid;
        grid-template-columns: 300px 1fr;
        gap: 2rem;
        align-items: start;
    }

    @media (max-width: 992px) {
        .settings-grid {
            grid-template-columns: 1fr;
            gap: 1.5rem;
        }
    }

    /* Sidebar Navigation panel */
    .settings-sidebar {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        background: white;
        padding: 1.25rem;
        border-radius: 24px;
        border: 1px solid rgba(226, 232, 240, 0.8);
        box-shadow: 0 4px 24px -2px rgba(148, 163, 184, 0.06);
    }

    .settings-nav-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem;
        border-radius: 16px;
        background: transparent;
        border: 1px solid transparent;
        color: var(--text-secondary);
        text-align: right;
        cursor: pointer;
        transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        width: 100%;
        outline: none;
    }

    .settings-nav-item:hover {
        background: #f8fafc;
        color: var(--text-primary);
    }

    .settings-nav-item.active {
        background: linear-gradient(135deg, #f0f4ff 0%, #e0e7ff 100%);
        border-color: rgba(99, 102, 241, 0.2);
        color: #4338ca;
    }

    .settings-nav-item.active .nav-icon-box {
        background: #6366f1;
        color: white;
        box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
    }

    .nav-icon-box {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #f1f5f9;
        color: #64748b;
        transition: all 0.25s;
        flex-shrink: 0;
    }

    .nav-item-details {
        display: flex;
        flex-direction: column;
        gap: 0.15rem;
        overflow: hidden;
        text-align: right;
    }

    .nav-item-title {
        font-weight: 750;
        font-size: 0.95rem;
        white-space: nowrap;
        text-overflow: ellipsis;
        overflow: hidden;
    }

    .nav-item-desc {
        font-size: 0.75rem;
        color: #94a3b8;
        white-space: nowrap;
        text-overflow: ellipsis;
        overflow: hidden;
    }

    /* Main Settings Content Area */
    .settings-main {
        background: white;
        border-radius: 24px;
        border: 1px solid rgba(226, 232, 240, 0.8);
        box-shadow: 0 4px 24px -2px rgba(148, 163, 184, 0.06);
        padding: 2rem;
        min-height: 500px;
        display: flex;
        flex-direction: column;
    }

    .panel-header {
        display: flex;
        align-items: center;
        gap: 1.25rem;
        padding-bottom: 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        margin-bottom: 2rem;
    }

    .panel-header-icon {
        width: 52px;
        height: 52px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .panel-title-text h2 {
        font-size: 1.35rem;
        font-weight: 850;
        color: var(--text-primary);
        margin: 0 0 0.25rem 0;
    }

    .panel-title-text p {
        font-size: 0.85rem;
        color: var(--text-secondary);
        margin: 0;
    }

    /* Setting Cards (Double-Bezel Design) */
    .setting-card {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 18px;
        padding: 1.5rem;
        margin-bottom: 1.25rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 2rem;
        transition: all 0.25s ease;
    }

    .setting-card:hover {
        background: #f1f5f9;
        border-color: #cbd5e1;
        transform: translateY(-2px);
        box-shadow: 0 6px 15px rgba(148, 163, 184, 0.05);
    }

    @media (max-width: 768px) {
        .setting-card {
            flex-direction: column;
            align-items: stretch;
            gap: 1.25rem;
        }
    }

    .setting-meta {
        flex: 1;
    }

    .setting-label {
        font-size: 0.975rem;
        font-weight: 750;
        color: var(--text-primary);
        margin-bottom: 0.35rem;
    }

    .setting-description {
        font-size: 0.85rem;
        color: var(--text-secondary);
        line-height: 1.55;
        margin: 0;
    }

    .setting-input-wrapper {
        min-width: 280px;
        display: flex;
        justify-content: flex-end;
    }

    @media (max-width: 768px) {
        .setting-input-wrapper {
            min-width: 100%;
            justify-content: flex-start;
        }
    }

    /* Custom Input Styling */
    .custom-input {
        width: 100%;
        padding: 0.75rem 1.15rem;
        border: 1.5px solid #cbd5e1;
        border-radius: 12px;
        font-size: 0.925rem;
        background: white;
        color: var(--text-primary);
        transition: all 0.25s ease;
    }

    .custom-input:focus {
        border-color: #6366f1;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
        outline: none;
    }

    /* Custom Textarea Styling */
    .custom-textarea {
        width: 100%;
        min-height: 120px;
        padding: 0.75rem 1.15rem;
        border: 1.5px solid #cbd5e1;
        border-radius: 12px;
        font-size: 0.925rem;
        background: white;
        color: var(--text-primary);
        transition: all 0.25s ease;
        resize: vertical;
        line-height: 1.6;
    }

    .custom-textarea:focus {
        border-color: #6366f1;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
        outline: none;
    }

    /* Custom Select Styling */
    .custom-select-wrapper {
        position: relative;
        width: 100%;
    }

    .custom-select {
        width: 100%;
        padding: 0.75rem 2.5rem 0.75rem 1.15rem;
        border: 1.5px solid #cbd5e1;
        border-radius: 12px;
        font-size: 0.925rem;
        background: white;
        color: var(--text-primary);
        transition: all 0.25s ease;
        appearance: none;
        cursor: pointer;
    }

    .custom-select:focus {
        border-color: #6366f1;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
        outline: none;
    }

    .custom-select-arrow {
        position: absolute;
        top: 50%;
        right: 1.15rem;
        transform: translateY(-50%);
        color: #64748b;
        pointer-events: none;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    /* Favicon Dropzone Widget */
    .favicon-dropzone {
        display: flex;
        align-items: center;
        gap: 1.25rem;
        padding: 0.5rem 0.75rem;
        background: white;
        border: 1.5px dashed #cbd5e1;
        border-radius: 14px;
        width: 100%;
        transition: all 0.2s ease;
    }

    .favicon-dropzone:hover {
        border-color: #6366f1;
        background: rgba(99, 102, 241, 0.01);
    }

    .favicon-preview-box {
        width: 52px;
        height: 52px;
        border-radius: 10px;
        overflow: hidden;
        background: #f1f5f9;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .favicon-preview-box img {
        max-width: 100%;
        max-height: 100%;
        object-fit: contain;
    }

    .favicon-upload-btn {
        position: relative;
        overflow: hidden;
        cursor: pointer;
        background: #f1f5f9;
        color: #475569;
        font-weight: 700;
        font-size: 0.85rem;
        padding: 0.5rem 1rem;
        border-radius: 8px;
        border: 1px solid #cbd5e1;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        margin: 0;
    }

    .favicon-upload-btn:hover {
        background: #e2e8f0;
        color: var(--text-primary);
    }

    .favicon-upload-btn input[type="file"] {
        position: absolute;
        top: 0;
        left: 0;
        opacity: 0;
        width: 100%;
        height: 100%;
        cursor: pointer;
    }

    /* Premium Switch (Toggle) */
    .premium-switch {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        cursor: pointer;
        margin: 0;
    }

    .premium-switch-control {
        position: relative;
        width: 52px;
        height: 28px;
        background: #cbd5e1;
        border-radius: 100px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .premium-switch-knob {
        position: absolute;
        top: 3px;
        left: 3px;
        width: 22px;
        height: 22px;
        background: white;
        border-radius: 50%;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.15);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    input[type="checkbox"]:checked + .premium-switch-control {
        background: #10b981;
    }

    input[type="checkbox"]:checked + .premium-switch-control .premium-switch-knob {
        left: 27px;
    }

    .premium-switch-label {
        font-size: 0.875rem;
        font-weight: 700;
        transition: color 0.2s;
        user-select: none;
        min-width: 45px;
        text-align: right;
    }

    .premium-switch-label.on {
        color: #10b981;
    }

    .premium-switch-label.off {
        color: #64748b;
    }

    /* Floating / Sticky Save Bar */
    .sticky-save-bar {
        position: sticky;
        bottom: -2rem;
        background: rgba(255, 255, 255, 0.85);
        backdrop-filter: blur(16px);
        -webkit-backdrop-filter: blur(16px);
        border-top: 1px solid #f1f5f9;
        padding: 1.25rem 2rem;
        margin: auto -2rem -2rem -2rem;
        border-bottom-left-radius: 24px;
        border-bottom-right-radius: 24px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 -8px 30px rgba(148, 163, 184, 0.08);
        z-index: 10;
        gap: 1rem;
    }

    @media (max-width: 768px) {
        .sticky-save-bar {
            flex-direction: column;
            align-items: stretch;
            padding: 1.25rem;
            margin: 1.5rem -2rem -2rem -2rem;
        }
    }

    .save-info {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: #64748b;
        font-size: 0.875rem;
    }

    .save-info svg {
        color: #6366f1;
        flex-shrink: 0;
    }

    .actions-container {
        display: flex;
        gap: 0.75rem;
    }

    @media (max-width: 768px) {
        .actions-container {
            justify-content: flex-end;
        }
    }

    .btn-premium-reset {
        background: #f1f5f9;
        color: #475569;
        border: 1px solid #e2e8f0;
        padding: 0.75rem 1.5rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.9rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-premium-reset:hover {
        background: #e2e8f0;
        color: var(--text-primary);
    }

    .btn-premium-save {
        background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
        color: white;
        border: none;
        padding: 0.75rem 2rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.9rem;
        cursor: pointer;
        box-shadow: 0 4px 14px rgba(99, 102, 241, 0.3);
        transition: all 0.25s;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-premium-save:hover {
        box-shadow: 0 6px 20px rgba(99, 102, 241, 0.4);
        transform: translateY(-1px);
    }

    .btn-premium-save:active {
        transform: translateY(1px);
    }
</style>

<!-- Page Header -->
<div class="premium-header">
    <div class="premium-header-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="3"></circle>
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
        </svg>
    </div>
    <div class="premium-header-text">
        <h1>إعدادات النظام</h1>
        <p>تعديل وإدارة المعطيات والخيارات العامة والأكاديمية ونظام الهدايا والدعم الفني للمنصة</p>
    </div>
</div>

<!-- Alert notifications -->
@if(session('success'))
<div class="premium-alert premium-alert-success">
    <div class="premium-alert-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
    </div>
    <span>{{ session('success') }}</span>
</div>
@endif

@if($errors->any())
<div class="premium-alert premium-alert-error">
    <div class="premium-alert-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
        </svg>
    </div>
    <div style="display: flex; flex-direction: column; gap: 0.25rem;">
        <strong style="font-weight: 750;">تعذر حفظ الإعدادات:</strong>
        <ul style="margin: 0; padding-right: 1.25rem; font-size: 0.9rem;">
            @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
</div>
@endif

<form action="{{ route('admin.settings.update') }}" method="POST" enctype="multipart/form-data">
    @csrf
    @method('PUT')

    <div x-data="{ activeTab: sessionStorage.getItem('adminSettingsTab') || 'general' }" 
         x-init="$watch('activeTab', val => sessionStorage.setItem('adminSettingsTab', val))">
        
        <div class="settings-grid">
            
            <!-- Sidebar Navigation -->
            <div class="settings-sidebar">
                <div class="settings-nav">
                    @foreach($settings as $group => $groupSettings)
                    <button type="button" 
                            class="settings-nav-item" 
                            :class="{ 'active': activeTab === '{{ $group }}' }" 
                            @click="activeTab = '{{ $group }}'">
                        
                        <div class="nav-icon-box">
                            @if($group === 'general')
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="3"></circle>
                                <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
                            </svg>
                            @elseif($group === 'academic')
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                                <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                            </svg>
                            @elseif($group === 'support')
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                            </svg>
                            @elseif($group === 'stars')
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                            </svg>
                            @else
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="12" y1="16" x2="12" y2="12"></line>
                                <line x1="12" y1="8" x2="12.01" y2="8"></line>
                            </svg>
                            @endif
                        </div>
                        
                        <div class="nav-item-details">
                            <span class="nav-item-title">{{ \App\Models\Setting::getGroupLabel($group) }}</span>
                            <span class="nav-item-desc">
                                @if($group === 'general')
                                الهوية والمظهر العام
                                @elseif($group === 'academic')
                                الأنظمة واللوائح التعليمية
                                @elseif($group === 'support')
                                قنوات الدعم والمساعدة
                                @elseif($group === 'stars')
                                نظام نجوم الطلاب
                                @elseif($group === 'access')
                                فتح وإغلاق دخول الموقع
                                @elseif($group === 'owner')
                                خيارات عرض خاصة بمالك النظام
                                @else
                                خيارات وخلفيات إضافية
                                @endif
                            </span>
                        </div>
                        
                    </button>
                    @endforeach
                </div>
            </div>

            <!-- Main Panels Container -->
            <div class="settings-main">
                
                @foreach($settings as $group => $groupSettings)
                <div class="settings-panel" 
                     x-show="activeTab === '{{ $group }}'" 
                     x-transition:enter="transition ease-out duration-250" 
                     x-transition:enter-start="opacity-0 transform translate-x-4" 
                     x-transition:enter-end="opacity-100 transform translate-x-0" 
                     style="display: none;">
                    
                    <div class="panel-header">
                        <div class="panel-header-icon" style="background: {{ $group === 'general' ? 'rgba(99, 102, 241, 0.08)' : ($group === 'academic' ? 'rgba(16, 185, 129, 0.08)' : ($group === 'support' ? 'rgba(37, 99, 235, 0.08)' : 'rgba(245, 158, 11, 0.08)')) }}; color: {{ $group === 'general' ? '#6366f1' : ($group === 'academic' ? '#10b981' : ($group === 'support' ? '#2563eb' : '#f59e0b')) }};">
                            @if($group === 'general')
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="3"></circle>
                                <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
                            </svg>
                            @elseif($group === 'academic')
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                                <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                            </svg>
                            @elseif($group === 'support')
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                            </svg>
                            @elseif($group === 'stars')
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                            </svg>
                            @else
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="12" y1="16" x2="12" y2="12"></line>
                                <line x1="12" y1="8" x2="12.01" y2="8"></line>
                            </svg>
                            @endif
                        </div>
                        <div class="panel-title-text">
                            <h2>{{ \App\Models\Setting::getGroupLabel($group) }}</h2>
                            <p>
                                @if($group === 'general')
                                تعديل الهوية البصرية الأساسية والأيقونة الخاصة بالنظام والمظهر العام.
                                @elseif($group === 'academic')
                                ضوابط العمليات التعليمية والمستويات والأنشطة الأكاديمية.
                                @elseif($group === 'support')
                                تحديد وسائل وخطوط الدعم الفني، وخصوصيات الإشعارات والملاحظات للطلاب.
                                @elseif($group === 'stars')
                                إدارة فترات وحصص الهدايا اليومية والحدود المسموح بها للنجوم التقديرية.
                                @elseif($group === 'access')
                                التحكم في إمكانية دخول الطلاب والدكاترة والمندوبين ومسؤولي الكليات إلى واجهة الموقع، مع بقاء دخول الأدمن الرئيسي متاحًا دائمًا.
                                @elseif($group === 'owner')
                                إعدادات خاصة بمالك النظام لا تظهر لبقية الأدمن، وتستخدم لتجهيز عرض مختصر دون تعطيل الصفحات أو تغيير الصلاحيات.
                                @else
                                خيارات ضبط المعطيات العامة المتنوعة.
                                @endif
                            </p>
                        </div>
                    </div>

                    <div class="settings-list">
                        @foreach($groupSettings as $setting)
                        <div class="setting-card">
                            
                            <div class="setting-meta">
                                <h4 class="setting-label">{{ $setting->label }}</h4>
                                <p class="setting-description">{{ $setting->description }}</p>
                            </div>
                            
                            <div class="setting-input-wrapper">
                                @if($setting->type === 'boolean')
                                <div style="display: flex; align-items: center; gap: 0.75rem; justify-content: flex-end;">
                                    <input type="hidden" name="{{ $setting->key }}" value="0">
                                    <label class="premium-switch">
                                        <input type="checkbox" name="{{ $setting->key }}" value="1" class="premium-switch-input" {{ $setting->value ? 'checked' : '' }} style="position: absolute; opacity: 0; width: 0; height: 0;">
                                        <div class="premium-switch-control">
                                            <div class="premium-switch-knob"></div>
                                        </div>
                                        <span class="premium-switch-label {{ $setting->value ? 'on' : 'off' }}">
                                            {{ $setting->value ? 'مفعّل' : 'معطّل' }}
                                        </span>
                                    </label>
                                </div>
                                
                                @elseif($setting->key === 'app_favicon')
                                <div class="favicon-dropzone">
                                    <div class="favicon-preview-box">
                                        @if($setting->value)
                                        <img src="{{ asset('storage/' . $setting->value) }}" alt="Favicon" id="favicon-preview">
                                        @else
                                        <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2">
                                            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                                            <circle cx="8.5" cy="8.5" r="1.5"></circle>
                                            <polyline points="21 15 16 10 5 21"></polyline>
                                        </svg>
                                        @endif
                                    </div>
                                    <div style="display: flex; flex-direction: column; gap: 0.25rem;">
                                        <label class="favicon-upload-btn">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                                <polyline points="17 8 12 3 7 8"></polyline>
                                                <line x1="12" y1="3" x2="12" y2="15"></line>
                                            </svg>
                                            <span>اختر ملف</span>
                                            <input type="file" name="{{ $setting->key }}" accept="image/*" class="favicon-input-file">
                                        </label>
                                        <span style="font-size: 0.7rem; color: #94a3b8;" class="favicon-file-name">لم يتم اختيار صورة</span>
                                    </div>
                                </div>
                                
                                @elseif($setting->key === 'student_star_gift_period')
                                <div class="custom-select-wrapper">
                                    <select name="{{ $setting->key }}" class="custom-select">
                                        <option value="daily" @selected($setting->value === 'daily')>يومي</option>
                                        <option value="weekly" @selected($setting->value === 'weekly')>أسبوعي</option>
                                        <option value="monthly" @selected($setting->value === 'monthly')>شهري</option>
                                        <option value="custom" @selected($setting->value === 'custom')>فترة مخصصة</option>
                                    </select>
                                    <span class="custom-select-arrow">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                            <polyline points="6 9 12 15 18 9"></polyline>
                                        </svg>
                                    </span>
                                </div>
                                
                                @elseif($setting->key === 'owner_default_university_id')
                                <div class="custom-select-wrapper">
                                    <select name="{{ $setting->key }}" class="custom-select">
                                        <option value="">بدون جامعة افتراضية</option>
                                        @foreach(\App\Models\Academic\University::orderBy('name')->get(['id', 'name']) as $university)
                                            <option value="{{ $university->id }}" @selected((string) $setting->value === (string) $university->id)>
                                                {{ $university->name }}
                                            </option>
                                        @endforeach
                                    </select>
                                    <span class="custom-select-arrow">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                            <polyline points="6 9 12 15 18 9"></polyline>
                                        </svg>
                                    </span>
                                </div>

                                @elseif($setting->type === 'number')
                                <input
                                    type="number"
                                    name="{{ $setting->key }}"
                                    value="{{ $setting->value }}"
                                    class="custom-input"
                                    min="{{ $setting->key === 'student_star_gift_limit' || $setting->key === 'student_star_gift_custom_days' ? 1 : null }}"
                                    max="{{ $setting->key === 'student_star_gift_custom_days' ? 365 : null }}"
                                >
                                
                                @elseif($setting->key === 'support_notice')
                                <textarea name="{{ $setting->key }}" rows="4" class="custom-textarea">{{ $setting->value }}</textarea>
                                
                                @else
                                <input type="text" name="{{ $setting->key }}" value="{{ $setting->value }}" class="custom-input">
                                @endif
                            </div>
                            
                        </div>
                        @endforeach
                    </div>
                    
                </div>
                @endforeach

                <!-- Sticky Bottom Actions Bar -->
                <div class="sticky-save-bar">
                    <div class="save-info">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"></circle>
                            <line x1="12" y1="8" x2="12" y2="12"></line>
                            <line x1="12" y1="16" x2="12.01" y2="16"></line>
                        </svg>
                        <span>يرجى مراجعة وتعديل الخيارات المطلوبة ثم النقر لحفظ كافة المدخلات</span>
                    </div>
                    <div class="actions-container">
                        <button type="reset" class="btn-premium-reset">إلغاء التغييرات</button>
                        <button type="submit" class="btn-premium-save">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                            </svg>
                            <span>حفظ الإعدادات</span>
                        </button>
                    </div>
                </div>

            </div>

        </div>

    </div>
</form>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Toggle Switch handler
        document.querySelectorAll('.premium-switch-input').forEach(toggle => {
            toggle.addEventListener('change', function() {
                const labelSpan = this.closest('.premium-switch').querySelector('.premium-switch-label');
                if (this.checked) {
                    labelSpan.textContent = 'مفعّل';
                    labelSpan.className = 'premium-switch-label on';
                } else {
                    labelSpan.textContent = 'معطّل';
                    labelSpan.className = 'premium-switch-label off';
                }
            });
        });

        // Live Favicon preview
        document.querySelectorAll('.favicon-input-file').forEach(input => {
            input.addEventListener('change', function(e) {
                const fileNameSpan = this.closest('.favicon-dropzone').querySelector('.favicon-file-name');
                const previewImg = this.closest('.favicon-dropzone').querySelector('#favicon-preview');
                const previewBox = this.closest('.favicon-dropzone').querySelector('.favicon-preview-box');
                
                if (e.target.files.length > 0) {
                    const file = e.target.files[0];
                    fileNameSpan.textContent = file.name;
                    
                    const reader = new FileReader();
                    reader.onload = function(event) {
                        if (previewImg) {
                            previewImg.src = event.target.result;
                        } else {
                            previewBox.innerHTML = `<img src="${event.target.result}" alt="Favicon" id="favicon-preview">`;
                        }
                    };
                    reader.readAsDataURL(file);
                } else {
                    fileNameSpan.textContent = 'لم يتم اختيار صورة';
                }
            });
        });

        // Dynamic form reset handler
        document.querySelector('form').addEventListener('reset', function() {
            setTimeout(() => {
                // Restore toggle labels
                document.querySelectorAll('.premium-switch-input').forEach(toggle => {
                    const labelSpan = toggle.closest('.premium-switch').querySelector('.premium-switch-label');
                    if (toggle.checked) {
                        labelSpan.textContent = 'مفعّل';
                        labelSpan.className = 'premium-switch-label on';
                    } else {
                        labelSpan.textContent = 'معطّل';
                        labelSpan.className = 'premium-switch-label off';
                    }
                });

                // Restore favicon filenames
                document.querySelectorAll('.favicon-file-name').forEach(nameSpan => {
                    nameSpan.textContent = 'لم يتم اختيار صورة';
                });
            }, 50);
        });
    });
</script>

@endsection
