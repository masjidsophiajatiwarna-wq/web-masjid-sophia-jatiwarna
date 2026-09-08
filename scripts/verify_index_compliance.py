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

if __name__ == '__main__':
    print("=== MASJID SOPHIA JATIWARNA COMPLIANCE & INTEGRITY TEST ===")
    target_docs = [
        'index.html',
        'implementation-plan.md',
        'progress-implementation-plan.html',
        'CHANGELOG.md'
    ]
    r1 = test_no_emojis(target_docs)
    r2 = test_no_admin_links_in_index()
    r3 = test_no_hardcoded_secrets(target_docs + ['scripts/batch_image_optimizer_imagekit.py', 'scripts/sync_manifest_to_supabase.py'])
    r4 = test_index_structure()
    
    if r1 and r2 and r3 and r4:
        print("\n=== ALL COMPLIANCE & INTEGRITY TESTS PASSED ===")
        sys.exit(0)
    else:
        print("\n=== SOME TESTS FAILED ===")
        sys.exit(1)
