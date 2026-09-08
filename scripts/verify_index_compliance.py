# -*- coding: utf-8 -*-
"""
Verification & Compliance Test Suite for Masjid Sophia Jatiwarna
- Strict No-Emoji Check (index.html, docs)
- No Admin Link Leak on Public Portal (index.html)
- Zero-Leak Hardcoded Secrets Check
- HTML Structural & Link Integrity Check
"""
import os
import re
import sys
from pathlib import Path

def test_no_emojis(file_paths):
    emoji_pattern = re.compile(
        r'[\U0001F600-\U0001F64F]'  # emoticons
        r'|[\U0001F300-\U0001F5FF]'  # symbols & pictographs
        r'|[\U0001F680-\U0001F6FF]'  # transport & map
        r'|[\U0001F1E0-\U0001F1FF]'  # flags
        r'|[\U0001F900-\U0001F9FF]'  # supplemental symbols
        r'|[\U0001FA70-\U0001FAFF]'  # symbols and pictographs ext-a
        r'|[\U00002600-\U000026FF]'  # misc symbols (warning, coffee, etc)
        r'|[\U00002700-\U000027BF]'  # dingbats
    )
    failed = False
    for path in file_paths:
        p = Path(path)
        if not p.exists():
            continue
        content = p.read_text(encoding='utf-8')
        emojis = emoji_pattern.findall(content)
        if emojis:
            hex_codes = [hex(ord(c)) for c in set(emojis)]
            print(f"[FAIL] Emoji/Dingbat found in {path}: {len(emojis)} occurrences -> {hex_codes}")
            failed = True
        else:
            print(f"[PASS] No emojis in {path}")
    return not failed

def test_no_admin_links_in_index():
    index_path = Path('index.html')
    content = index_path.read_text(encoding='utf-8')
    admin_links = re.findall(r'href=[\"\'][^\"\']*admin[^\"\']*[\"\']', content, re.IGNORECASE)
    if admin_links:
        print(f"[FAIL] Direct admin links found in index.html: {admin_links}")
        return False
    print("[PASS] Public portal index.html is completely free of admin navigation links.")
    return True

def test_no_hardcoded_secrets(file_paths):
    secret_patterns = [
        re.compile(r'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+'),
        re.compile(r'private_[a-zA-Z0-9_]{15,}'),
    ]
    failed = False
    for path in file_paths:
        p = Path(path)
        if not p.exists():
            continue
        content = p.read_text(encoding='utf-8')
        for sp in secret_patterns:
            matches = sp.findall(content)
            if matches:
                print(f"[FAIL] Potential secret found in {path}: {matches}")
                failed = True
        if not failed:
            print(f"[PASS] Zero hardcoded secrets in {path}")
    return not failed

def test_index_structure():
    content = Path('index.html').read_text(encoding='utf-8')
    checks = [
        ('<!DOCTYPE html>', 'DOCTYPE declaration'),
        ('<html lang="id">', 'HTML lang id'),
        ('env-loader.js', 'Dynamic env loader script'),
        ('window.MasjidConfig.initSupabaseClient', 'Dynamic Supabase initialization'),
        ('id="hero-slider-container"', 'Hero banner slider container'),
        ('id="hero-slides-wrapper"', 'Hero slides wrapper'),
        ('id="jadwal-shalat"', 'Prayer schedule section'),
        ('id="agenda-kajian"', 'Kajian agenda section'),
        ('id="galeri-dokumentasi"', 'Gallery section'),
        ('id="program-filantropi"', 'Donations section'),
        ('id="layanan-musafir"', 'Musafir facilities section'),
        ('id="warta-berita"', 'Dakwah news section'),
        ('id="complaint-modal"', 'Complaint/aspirasi modal popup'),
        ('id="lightbox-modal"', 'Gallery lightbox modal'),
        ('ik.imagekit.io/masjidsophia', 'ImageKit CDN reference')
    ]
    all_ok = True
    found_ids = set(re.findall(r'id=["\']([^"\']+)["\']', content))
    print(f"Total Unique IDs in index.html: {len(found_ids)}")
    for needle, desc in checks:
        if needle in content:
            print(f"[PASS] Found: {desc}")
        else:
            print(f"[FAIL] Missing: {desc}")
            all_ok = False
    return all_ok

def test_admin_index_sync():
    index_text = Path('index.html').read_text(encoding='utf-8')
    admin_text = Path('admin.html').read_text(encoding='utf-8')
    table_pattern = re.compile(r"""\.from\(["']([a-zA-Z0-9_]+)["']\)""")
    channel_pattern = re.compile(r"""\.channel\(["']([^"']+)["']\)""")

    index_tables = set(table_pattern.findall(index_text))
    admin_tables = set(table_pattern.findall(admin_text))
    shared_tables = [
        'jadwal_shalat_petugas',
        'homepage_media',
        'kajian_acara_ibadah',
        'artikel_berita',
        'donations',
        'feedback_complaints'
    ]
    all_ok = True
    for tbl in shared_tables:
        if tbl in index_tables and tbl in admin_tables:
            print(f"[PASS] Bidirectional Table Sync: {tbl}")
        else:
            print(f"[FAIL] Missing sync for table: {tbl}")
            all_ok = False

    index_channels = set(channel_pattern.findall(index_text))
    if len(index_channels) >= 6:
        print(f"[PASS] Supabase Realtime CDC Channels: {len(index_channels)} active channels subscribed")
    else:
        print(f"[FAIL] Incomplete CDC Channels: found only {len(index_channels)}")
        all_ok = False
    return all_ok

def test_files_existence():
    required_files = [
        'index.html',
        'admin.html',
        'galeri.html',
        'artikel.html',
        'artikel-detail.html',
        'vercel.json',
        'asset/js/env-loader.js',
        'implementation-plan.md',
        'progress-implementation-plan.html',
        'CHANGELOG.md'
    ]
    all_ok = True
    for rf in required_files:
        if Path(rf).exists():
            print(f"[PASS] File exists: {rf}")
        else:
            print(f"[FAIL] Missing file: {rf}")
            all_ok = False
    return all_ok

def test_no_admin_links_in_public_portals():
    public_files = ['index.html', 'galeri.html', 'artikel.html', 'artikel-detail.html']
    admin_pattern = re.compile(r'href=[\"\'][^\"\']*admin[^\"\']*[\"\']', re.IGNORECASE)
    all_ok = True
    for pf in public_files:
        p = Path(pf)
        if not p.exists():
            continue
        content = p.read_text(encoding='utf-8')
        matches = admin_pattern.findall(content)
        if matches:
            print(f"[FAIL] Direct admin links found in {pf}: {matches}")
            all_ok = False
        else:
            print(f"[PASS] Public portal {pf} is free of admin navigation links.")
    return all_ok

def test_standalone_pages_structure():
    pages_checks = {
        'galeri.html': [
            ('id="gallery-search-input"', 'Gallery search input'),
            ('id="gallery-items-grid"', 'Gallery items grid'),
            ('id="gallery-lightbox"', 'Gallery fullscreen lightbox viewer'),
            ('class="filter-pills"', 'Gallery category filter pills'),
            ('ik.imagekit.io/masjidsophia', 'ImageKit CDN reference')
        ],
        'artikel.html': [
            ('id="article-search-input"', 'Article search input'),
            ('id="featured-article-container"', 'Featured article showcase'),
            ('id="articles-items-grid"', 'Articles archive grid'),
            ('class="filter-pills"', 'Article category filter pills')
        ],
        'artikel-detail.html': [
            ('id="reading-progress-bar"', 'Sticky reading progress bar'),
            ('id="article-wrapper"', 'Article main wrapper'),
            ('id="article-content"', 'Rich-text article content container'),
            ('id="related-articles-grid"', 'Related articles grid'),
            ('id="share-wa"', 'WhatsApp share button'),
            ('id="share-fb"', 'Facebook share button'),
            ('id="share-tw"', 'X share button')
        ]
    }
    all_ok = True
    for filename, checks in pages_checks.items():
        p = Path(filename)
        if not p.exists():
            print(f"[FAIL] File not found: {filename}")
            all_ok = False
            continue
        content = p.read_text(encoding='utf-8')
        for needle, desc in checks:
            if needle in content:
                print(f"[PASS] [{filename}] Found: {desc}")
            else:
                print(f"[FAIL] [{filename}] Missing: {desc}")
                all_ok = False
    return all_ok

def test_vercel_routing():
    p = Path('vercel.json')
    if not p.exists():
        print("[FAIL] vercel.json not found")
        return False
    content = p.read_text(encoding='utf-8')
    checks = [
        ('"cleanUrls": true', 'Clean URLs enabled'),
        ('"trailingSlash": false', 'Trailing slash normalized'),
        ('"/galeri"', 'Galeri routing rewrite'),
        ('"/artikel"', 'Artikel routing rewrite'),
        ('"/artikel/:slug"', 'Artikel detail dynamic slug rewrite')
    ]
    all_ok = True
    for needle, desc in checks:
        if needle in content:
            print(f"[PASS] [vercel.json] Found: {desc}")
        else:
            print(f"[FAIL] [vercel.json] Missing: {desc}")
            all_ok = False
    return all_ok

if __name__ == '__main__':
    print("=== MASJID SOPHIA JATIWARNA COMPLIANCE & INTEGRITY TEST ===")
    target_docs = [
        'index.html',
        'galeri.html',
        'artikel.html',
        'artikel-detail.html',
        'admin.html',
        'implementation-plan.md',
        'progress-implementation-plan.html',
        'CHANGELOG.md'
    ]
    r0 = test_files_existence()
    r1 = test_no_emojis(target_docs)
    r2 = test_no_admin_links_in_public_portals()
    r3 = test_no_hardcoded_secrets(target_docs + ['scripts/batch_image_optimizer_imagekit.py', 'scripts/sync_manifest_to_supabase.py'])
    r4 = test_index_structure()
    r5 = test_standalone_pages_structure()
    r6 = test_vercel_routing()
    r7 = test_admin_index_sync()
    
    if r0 and r1 and r2 and r3 and r4 and r5 and r6 and r7:
        print("\n=== ALL COMPLIANCE & INTEGRITY TESTS PASSED (100%) ===")
        sys.exit(0)
    else:
        print("\n=== SOME TESTS FAILED ===")
        sys.exit(1)
