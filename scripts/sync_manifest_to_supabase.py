# -*- coding: utf-8 -*-
"""
Sync ImageKit Manifest to Supabase Database
Masjid Musafir Sophia Jatiwarna
"""
import os
import re
import json
import uuid
from datetime import datetime
from pathlib import Path
import requests

# 1. Read Credentials
with open('credentials.txt', 'r', encoding='utf-8') as f:
    cred_text = f.read()

sb_url_match = re.search(r'project_ID Supabase\s*:\s*([^\n\r]+)', cred_text)
anon_match = re.search(r'Anon_public_Key Supabase\s*:\s*([^\n\r]+)', cred_text)

if not sb_url_match:
    print("Error: Supabase config tidak ditemukan")
    exit(1)

SUPABASE_URL = f"https://{sb_url_match.group(1).strip()}.supabase.co"
SUPABASE_KEY = anon_match.group(1).strip()

HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates'
}

# 2. Read Manifest
manifest_path = Path('asset/imagekit-manifest.json')
if not manifest_path.exists():
    print("Manifest belum ada.")
    exit(1)

with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = json.load(f)

print(f"Total item manifest: {len(manifest)}")

# 3. Batch Insert into media_library
media_rows = []
for k, item in manifest.items():
    media_rows.append({
        'id': str(uuid.uuid4()),
        'file_name': item['file_name'],
        'public_url': item['cdn_url'],
        'file_size_kb': float(item.get('size_kb', 0)),
        'file_type': 'image/webp',
        'dimensions': item.get('dimensions', ''),
        'folder': item.get('subfolder', 'umum'),
        'imagekit_file_id': item.get('file_id', ''),
        'uploaded_at': item.get('uploaded_at', datetime.utcnow().isoformat())
    })

print(f"Memasukkan {len(media_rows)} berkas ke media_library...")
chunk_size = 25
for i in range(0, len(media_rows), chunk_size):
    chunk = media_rows[i:i+chunk_size]
    res = requests.post(f"{SUPABASE_URL}/rest/v1/media_library", headers=HEADERS, json=chunk)
    if res.status_code in (200, 201):
        print(f"  Inserted media_library {i+1} - {min(i+chunk_size, len(media_rows))}")
    else:
        print(f"  Note media_library: HTTP {res.status_code} {res.text[:100]}")

# 4. Curate Homepage Media (BANNER_HERO and GALERI_KEGIATAN)
homepage_items = []

# Hero Banner 1: Fasad Siang
fasad_items = [v for v in manifest.values() if v.get('category') == 'FASAD_MASJID']
if fasad_items:
    homepage_items.append({
        'id': str(uuid.uuid4()),
        'judul': 'Pusat Sujud & Rumah Singgah Ibadah 24 Jam',
        'subjudul': 'Menyediakan kenyamanan ibadah, istirahat musafir, serta ketenangan hati di jantung Jatiwarna, Kota Bekasi.',
        'kategori': 'BANNER_HERO',
        'media_url': fasad_items[0]['cdn_url'],
        'media_type': 'IMAGE',
        'action_link': '#program-filantropi',
        'action_label': 'Infaq Makan Siang Gratis',
        'order_index': 1,
        'is_active': True,
        'imagekit_file_id': fasad_items[0].get('file_id', '')
    })

# Hero Banner 2: Makan Siang Gratis
makan_items = [v for v in manifest.values() if v.get('category') == 'MAKAN_SIANG_GRATIS']
if makan_items:
    homepage_items.append({
        'id': str(uuid.uuid4()),
        'judul': '70+ Porsi Makan Siang Gratis Setiap Hari',
        'subjudul': 'Memuliakan musafir, dhuafa, dan pejuang nafkah jalanan dengan santapan bergizi ba\'da Shalat Dzuhur.',
        'kategori': 'BANNER_HERO',
        'media_url': makan_items[0]['cdn_url'],
        'media_type': 'IMAGE',
        'action_link': '#program-filantropi',
        'action_label': 'Salurkan Sedekah Makan',
        'order_index': 2,
        'is_active': True,
        'imagekit_file_id': makan_items[0].get('file_id', '')
    })

# Hero Banner 3: Santri Tahfidz
santri_items = [v for v in manifest.values() if v.get('category') == 'SANTRI_TAHFIDZ']
if santri_items:
    homepage_items.append({
        'id': str(uuid.uuid4()),
        'judul': 'Mencetak Generasi Qur\'ani Berakhlak Mulia',
        'subjudul': 'Beasiswa pembibitan penghafal Al-Qur\'an 30 Juz dan mutaba\'ah hafalan bersanad.',
        'kategori': 'BANNER_HERO',
        'media_url': santri_items[0]['cdn_url'],
        'media_type': 'IMAGE',
        'action_link': '#program-filantropi',
        'action_label': 'Dukung Santri Tahfidz',
        'order_index': 3,
        'is_active': True,
        'imagekit_file_id': santri_items[0].get('file_id', '')
    })

# Hero Banner 4: Ruang Shalat Utama
ruang_items = [v for v in manifest.values() if v.get('category') in ('RUANG_SHALAT', 'SUASANA_IBADAH')]
if ruang_items:
    homepage_items.append({
        'id': str(uuid.uuid4()),
        'judul': 'Ruang Shalat Sejuk, Bersih & Khusyuk',
        'subjudul': 'Karpet wangi, pendingin udara prima, dan lingkungan ibadah yang ramah keluarga.',
        'kategori': 'BANNER_HERO',
        'media_url': ruang_items[0]['cdn_url'],
        'media_type': 'IMAGE',
        'action_link': '#jadwal-shalat',
        'action_label': 'Jadwal Shalat Kemenag',
        'order_index': 4,
        'is_active': True,
        'imagekit_file_id': ruang_items[0].get('file_id', '')
    })

# Curated Gallery items across all categories
cat_sample_counts = {
    'FASAD_MASJID': 2,
    'MAKAN_SIANG_GRATIS': 4,
    'DAPUR_RELAWAN': 2,
    'SANTRI_TAHFIDZ': 3,
    'RUANG_SHALAT': 2,
    'SUASANA_IBADAH': 2,
    'FASILITAS_MUSAFIR': 3
}

gallery_order = 1
for cat, max_c in cat_sample_counts.items():
    matched = [v for v in manifest.values() if v.get('category') == cat]
    for item in matched[:max_c]:
        homepage_items.append({
            'id': str(uuid.uuid4()),
            'judul': item['file_name'].replace('_', ' ').replace('.webp', ''),
            'subjudul': f"Dokumentasi resmi kategori {cat.replace('_', ' ')}",
            'kategori': 'GALERI_KEGIATAN',
            'media_url': item['cdn_url'],
            'media_type': 'IMAGE',
            'action_link': item['cdn_url'],
            'action_label': 'Lihat Dokumentasi',
            'order_index': gallery_order,
            'is_active': True,
            'imagekit_file_id': item.get('file_id', '')
        })
        gallery_order += 1

print(f"Memasukkan {len(homepage_items)} item terkurasi ke homepage_media...")
res_hp = requests.post(f"{SUPABASE_URL}/rest/v1/homepage_media", headers=HEADERS, json=homepage_items)
if res_hp.status_code in (200, 201):
    print(f"Berhasil mengisi {len(homepage_items)} item ke homepage_media!")
else:
    print(f"Error homepage_media: HTTP {res_hp.status_code} {res_hp.text[:200]}")

print("=== SINKRONISASI MANIFEST SELESAI ===")
