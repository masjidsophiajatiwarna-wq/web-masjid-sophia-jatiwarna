/**
 * env-loader.js - Dynamic Configuration & Environment Loader
 * Web Portal Masjid Musafir Sophia Jatiwarna
 * 
 * Secure Zero-Hardcode Architecture:
 * 1. Loads configuration at runtime from /api/config (Vercel Serverless Function).
 * 2. Caches configuration in sessionStorage to minimize network latency.
 * 3. Supports offline local development via gitignored config.local.js (window.__ENV__).
 * 4. Fallbacks gracefully if backend is offline.
 * 5. Absolutely ZERO keys hardcoded into git-tracked files.
 */
(function(window) {
    'use strict';

    const CACHE_KEY = 'masjid_sophia_env_config';

    async function loadConfig() {
        // Tier 1: Check in-memory cache
        if (window.__MASJID_CONFIG__ && window.__MASJID_CONFIG__.supabaseUrl && window.__MASJID_CONFIG__.supabaseAnonKey) {
            return window.__MASJID_CONFIG__;
        }

        // Tier 2: Check sessionStorage cache
        try {
            const cached = sessionStorage.getItem(CACHE_KEY);
            if (cached) {
                const parsed = JSON.parse(cached);
                if (parsed.supabaseUrl && parsed.supabaseAnonKey) {
                    window.__MASJID_CONFIG__ = parsed;
                    return parsed;
                }
            }
        } catch (e) {}

        // Tier 3: Check window.__ENV__ (loaded from gitignored config.local.js for offline local dev)
        if (window.__ENV__ && window.__ENV__.SUPABASE_URL && window.__ENV__.SUPABASE_ANON_KEY) {
            const envConf = {
                supabaseUrl: window.__ENV__.SUPABASE_URL,
                supabaseAnonKey: window.__ENV__.SUPABASE_ANON_KEY
            };
            window.__MASJID_CONFIG__ = envConf;
            return envConf;
        }

        // Tier 4: Fetch from Serverless Endpoint /api/config (only on http/https)
        if (window.location && window.location.protocol && window.location.protocol.startsWith('http')) {
            try {
                const res = await fetch('/api/config');
                if (res.ok) {
                    const data = await res.json();
                    if (data && data.supabaseUrl && data.supabaseAnonKey) {
                        window.__MASJID_CONFIG__ = data;
                        try {
                            sessionStorage.setItem(CACHE_KEY, JSON.stringify(data));
                        } catch (e) {}
                        return data;
                    }
                }
            } catch (err) {
                // Silently fallback without polluting console
            }
        }

        // Tier 5: LocalStorage manual override (masjid_sophia_custom_env)
        try {
            const localCustom = localStorage.getItem('masjid_sophia_custom_env');
            if (localCustom) {
                const parsed = JSON.parse(localCustom);
                if (parsed.supabaseUrl && parsed.supabaseAnonKey) {
                    window.__MASJID_CONFIG__ = parsed;
                    return parsed;
                }
            }
        } catch (e) {}

        return null;
    }

    // Helper to initialize or get a Supabase client instance
    async function initSupabaseClient() {
        const config = await loadConfig();
        if (!config || !config.supabaseUrl || !config.supabaseAnonKey) {
            return null;
        }

        if (window.supabase && typeof window.supabase.createClient === 'function') {
            return window.supabase.createClient(config.supabaseUrl, config.supabaseAnonKey);
        } else {
            return null;
        }
    }

    // =========================================================================
    // UNIVERSAL MAINTENANCE MODE GUARD & ADMIN PREVIEW BYPASS ENGINE
    // =========================================================================
    async function checkMaintenanceGuard() {
        if (typeof window === 'undefined') return;
        const path = (window.location.pathname || '').toLowerCase();
        
        // Lewati halaman admin, pemeliharaan, dan progress plan
        if (path.includes('admin') || path.includes('maintenance') || path.includes('progdev')) {
            return;
        }

        const urlParams = new URLSearchParams(window.location.search);
        const previewQuery = urlParams.get('preview');
        
        // Simpan parameter preview ke sessionStorage agar sesi pratinjau tim bertahan saat berpindah halaman dalam tab yang sama
        if (previewQuery) {
            try {
                sessionStorage.setItem('masjid_sophia_preview_role', previewQuery);
            } catch (e) {}
        }

        let previewRole = previewQuery;
        if (!previewRole) {
            try {
                previewRole = sessionStorage.getItem('masjid_sophia_preview_role');
            } catch (e) {}
        }

        const hasPreviewAccess = !!previewRole;
        let hasAdminSession = false;
        try {
            hasAdminSession = !!(localStorage.getItem('masjid_sophia_auth_session') || localStorage.getItem('masjid_sophia_current_user') || localStorage.getItem('sb-vwhphwhkclnuzrghyffg-auth-token'));
        } catch (e) {}

        function showAdminPreviewBanner(roleName) {
            if (document.getElementById('dkm-maintenance-preview-banner')) return;
            const displayRole = roleName ? roleName.toUpperCase() : 'PENGURUS DKM';
            const banner = document.createElement('div');
            banner.id = 'dkm-maintenance-preview-banner';
            banner.style.cssText = 'position: fixed; top: 0; left: 0; right: 0; z-index: 999999; background: #FEF3C7; color: #92400E; font-size: 0.82rem; font-weight: 700; padding: 0.45rem 1rem; text-align: center; border-bottom: 2px solid #F59E0B; display: flex; align-items: center; justify-content: center; gap: 0.75rem; box-shadow: 0 4px 12px rgba(0,0,0,0.1); font-family: system-ui, sans-serif;';
            banner.innerHTML = `<span><i class="fa-solid fa-triangle-exclamation" style="color: #D97706; margin-right: 0.35rem;"></i><strong>Mode Pemeliharaan Aktif (Pratinjau ${displayRole}):</strong> Pengunjung umum dialihkan ke maintenance.html. Anda melihat halaman ini sebagai Pratinjau Pengurus DKM.</span><a href="https://admin.masjidsophia.com/admin#media" style="background: #D97706; color: #FFFFFF; text-decoration: none; padding: 0.2rem 0.6rem; border-radius: 6px; font-size: 0.74rem; font-weight: 700;">Kelola di Admin</a>`;
            if (document.body) {
                document.body.appendChild(banner);
                document.body.style.paddingTop = (parseInt(document.body.style.paddingTop || '0') + 36) + 'px';
            } else {
                document.addEventListener('DOMContentLoaded', () => {
                    document.body.appendChild(banner);
                    document.body.style.paddingTop = (parseInt(document.body.style.paddingTop || '0') + 36) + 'px';
                });
            }
        }

        try {
            // SUPABASE SSOT (Single Source of Truth) - Kueri langsung remote Supabase
            const sb = await initSupabaseClient();
            if (sb) {
                const { data, error } = await sb
                    .from('homepage_media')
                    .select('meta_json')
                    .eq('kategori', 'HOMEPAGE_CONFIG_MASTER')
                    .limit(1);

                if (!error && data && data.length > 0) {
                    let cfg = data[0].meta_json;
                    if (typeof cfg === 'string') {
                        try { cfg = JSON.parse(cfg); } catch (e) {}
                    }
                    if (cfg) {
                        const isMaint = cfg.site_status === 'MAINTENANCE' || cfg.is_maintenance === true;
                        if (isMaint) {
                            if (hasPreviewAccess || hasAdminSession) {
                                showAdminPreviewBanner(previewRole);
                            } else {
                                window.location.replace('/maintenance.html');
                                return;
                            }
                        } else {
                            const banner = document.getElementById('dkm-maintenance-preview-banner');
                            if (banner) banner.remove();
                        }
                    }
                }

                // Listener Realtime CDC
                sb.channel('global-maintenance-sync')
                    .on('postgres_changes', {
                        event: '*',
                        schema: 'public',
                        table: 'homepage_media',
                        filter: 'kategori=eq.HOMEPAGE_CONFIG_MASTER'
                    }, payload => {
                        if (payload && payload.new) {
                            let cfg = payload.new.meta_json;
                            if (typeof cfg === 'string') {
                                try { cfg = JSON.parse(cfg); } catch (e) {}
                            }
                            if (cfg) {
                                const isMaint = cfg.site_status === 'MAINTENANCE' || cfg.is_maintenance === true;
                                if (isMaint) {
                                    if (hasPreviewAccess || hasAdminSession) {
                                        showAdminPreviewBanner(previewRole);
                                    } else {
                                        window.location.replace('/maintenance.html');
                                    }
                                } else {
                                    const banner = document.getElementById('dkm-maintenance-preview-banner');
                                    if (banner) banner.remove();
                                }
                            }
                        }
                    })
                    .subscribe();
            }
        } catch (err) {
            console.debug('[Maintenance Guard Error]', err);
        }
    }

    // Jalankan guard segera jika di peramban
    if (typeof window !== 'undefined') {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', checkMaintenanceGuard);
        } else {
            checkMaintenanceGuard();
        }
    }

    window.MasjidConfig = {
        loadConfig,
        initSupabaseClient,
        checkMaintenanceGuard
    };
})(typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : this));
