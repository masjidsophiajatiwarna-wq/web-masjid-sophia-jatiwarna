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

        // Tier 4: Fetch from Serverless Endpoint /api/config
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
            console.warn('[EnvLoader] /api/config notice:', err);
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
            console.warn('[EnvLoader] Supabase runtime configuration not available.');
            return null;
        }

        if (window.supabase && typeof window.supabase.createClient === 'function') {
            return window.supabase.createClient(config.supabaseUrl, config.supabaseAnonKey);
        } else {
            console.warn('[EnvLoader] @supabase/supabase-js library not loaded on page.');
            return null;
        }
    }

    window.MasjidConfig = {
        loadConfig,
        initSupabaseClient
    };
})(typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : this));
