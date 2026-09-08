# -*- coding: utf-8 -*-
"""
Batch Image Optimizer and ImageKit CDN Uploader
Masjid Musafir Sophia Jatiwarna
"""
import os
import re
import sys
import time
import json
import base64
import requests
from pathlib import Path
from PIL import Image

# 1. Load Credentials Safely
CRED_FILE = 'credentials.txt'
if not os.path.exists(CRED_FILE):
    print(f"Error: {CRED_FILE} tidak ditemukan.")
    sys.exit(1)

with open(CRED_FILE, 'r', encoding='utf-8') as f:
    cred_text = f.read()

priv_match = re.search(r'Private key[^\n:]*:\s*([^\n\r]+)', cred_text)
url_match = re.search(r'URL-endpoint:\s*([^\n\r]+)', cred_text)
sb_url_match = re.search(r'project_ID Supabase\s*:\s*([^\n\r]+)', cred_text)
sb_sec_match = re.search(r'Secret_key Supabase\s*:\s*([^\n\r]+)', cred_text)

if not priv_match:
    print("Error: Private key ImageKit tidak ditemukan di credentials.txt")
    sys.exit(1)

IMAGEKIT_PRIVATE_KEY = priv_match.group(1).strip()
IMAGEKIT_URL_ENDPOINT = url_match.group(1).strip() if url_match else 'https://ik.imagekit.io/masjidsophia'
SUPABASE_URL = f"https://{sb_url_match.group(1).strip()}.supabase.co" if sb_url_match else ''
SUPABASE_SERVICE_KEY = sb_sec_match.group(1).strip() if sb_sec_match else ''

AUTH_HEADER = 'Basic ' + base64.b64encode((IMAGEKIT_PRIVATE_KEY + ':').encode('utf-8')).decode('utf-8')
UPLOAD_ENDPOINT = 'https://upload.imagekit.io/api/v1/files/upload'

print("=== PIPELINE OPTIMASI & MIGRASI ASSET IMAGEKIT ===")
print(f"Endpoint ImageKit: {IMAGEKIT_URL_ENDPOINT}")

# 2. Folder Configuration
SRC_DIR = Path('asset/images')
DEST_WEBP_DIR = Path('asset/images_webp')
DEST_WEBP_DIR.mkdir(parents=True, exist_ok=True)

MANIFEST_FILE = Path('asset/imagekit-manifest.json')

# Existing Manifest if any
manifest = {}
if MANIFEST_FILE.exists():
    try:
        with open(MANIFEST_FILE, 'r', encoding='utf-8') as mf:
            manifest = json.load(mf)
        print(f"Manifest ditemukan: {len(manifest)} item sudah tercatat.")
    except Exception:
        manifest = {}

# Folder & Category Mapping
CATEGORY_MAP = {
    'Foto_Fasad_Masjid_Siang': ('FASAD_MASJID', '/masjid-sophia/fasad', 1920),
    'Foto_Fasad_Masjid_Malam': ('FASAD_MASJID', '/masjid-sophia/fasad', 1920),
    'Plang_Nama_&_Landmark': ('FASAD_MASJID', '/masjid-sophia/fasad', 1920),
    'Ruang_Shalat_Utama_&_Mihrab': ('RUANG_SHALAT', '/masjid-sophia/ibadah', 1920),
    'Suasana_Shalat_Berjamaah': ('SUASANA_IBADAH', '/masjid-sophia/ibadah', 1920),
    'Foto_Hidangan_Siap_Saji': ('MAKAN_SIANG_GRATIS', '/masjid-sophia/makan-siang', 1440),
    'Suasana_Makan_Bersama_Jamaah': ('MAKAN_SIANG_GRATIS', '/masjid-sophia/makan-siang', 1440),
    'Tim_Relawan_&_Dapur': ('DAPUR_RELAWAN', '/masjid-sophia/makan-siang', 1440),
    'Halaqah_Al-Quran_Bersama_Ustadz': ('SANTRI_TAHFIDZ', '/masjid-sophia/santri', 1440),
    'Ujian_Tasmi_&_Setoran_Hafalan': ('SANTRI_TAHFIDZ', '/masjid-sophia/santri', 1440),
    'Area_Wudhu_&_Kamar_Mandi': ('FASILITAS_MUSAFIR', '/masjid-sophia/fasilitas', 1440),
    'Dispenser_&_Air_Minum_Gratis': ('FASILITAS_MUSAFIR', '/masjid-sophia/fasilitas', 1440),
    'Area_Singgah_&_Istirahat_Musafir': ('FASILITAS_MUSAFIR', '/masjid-sophia/fasilitas', 1440),
    'Foto_Portrait_Imam_Rawatib': ('PORTRAIT_ASATIDZ', '/masjid-sophia/asatidz', 800),
    'Foto_Portrait_Asatidz_&_Penceramah': ('PORTRAIT_ASATIDZ', '/masjid-sophia/asatidz', 800)
}

# 3. Scan Raw Images
raw_files = []
for p in SRC_DIR.rglob('*'):
    if p.is_file() and p.suffix.lower() in ['.jpg', '.jpeg', '.png']:
        raw_files.append(p)

print(f"Total gambar mentah ditemukan: {len(raw_files)}")

success_count = 0
skip_count = 0
fail_count = 0

for idx, src_path in enumerate(raw_files, 1):
    subfolder_name = src_path.parent.name
    category, ik_folder, max_dim = CATEGORY_MAP.get(subfolder_name, ('DOKUMENTASI_MASJID', '/masjid-sophia/umum', 1440))
    
    clean_stem = re.sub(r'[^a-zA-Z0-9_-]', '_', src_path.stem)
    clean_stem = re.sub(r'_+', '_', clean_stem).strip('_')
    webp_filename = f"{clean_stem}.webp"
    
    target_subfolder = DEST_WEBP_DIR / subfolder_name
    target_subfolder.mkdir(parents=True, exist_ok=True)
    webp_path = target_subfolder / webp_filename
    
    # Check if already uploaded in manifest
    rel_key = f"{subfolder_name}/{webp_filename}"
    if rel_key in manifest and manifest[rel_key].get('cdn_url'):
        skip_count += 1
        continue
    
    print(f"[{idx}/{len(raw_files)}] Memproses: {subfolder_name}/{src_path.name} ...")
    
    # Step A: Convert to WebP
    try:
        with Image.open(src_path) as img:
            try:
                from PIL import ImageOps
                img = ImageOps.exif_transpose(img)
            except Exception:
                pass
            
            w, h = img.size
            if w > max_dim or h > max_dim:
                if w > h:
                    new_h = int((h * max_dim) / w)
                    new_w = max_dim
                else:
                    new_w = int((w * max_dim) / h)
                    new_h = max_dim
                img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
                w, h = new_w, new_h
            
            if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                pass
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            img.save(webp_path, format='WEBP', quality=85, method=6)
        
        webp_size_kb = round(os.path.getsize(webp_path) / 1024, 2)
    except Exception as e:
        print(f"   [GAGAL KONVERSI] {e}")
        fail_count += 1
        continue
    
    # Step B: Upload to ImageKit REST API
    uploaded = False
    for attempt in range(1, 4):
        try:
            with open(webp_path, 'rb') as f_upload:
                files_payload = {'file': (webp_filename, f_upload, 'image/webp')}
                data_payload = {
                    'fileName': webp_filename,
                    'folder': ik_folder,
                    'useUniqueFileName': 'false',
                    'tags': f"masjid-sophia,{category},{subfolder_name}"
                }
                res = requests.post(
                    UPLOAD_ENDPOINT,
                    headers={'Authorization': AUTH_HEADER},
                    files=files_payload,
                    data=data_payload,
                    timeout=45
                )
            
            if res.status_code in (200, 201):
                ik_data = res.json()
                manifest[rel_key] = {
                    'file_id': ik_data.get('fileId'),
                    'file_name': ik_data.get('name'),
                    'cdn_url': ik_data.get('url'),
                    'file_path': ik_data.get('filePath'),
                    'dimensions': f"{w}x{h}",
                    'width': w,
                    'height': h,
                    'size_kb': webp_size_kb,
                    'category': category,
                    'subfolder': subfolder_name,
                    'local_raw': str(src_path),
                    'local_webp': str(webp_path),
                    'uploaded_at': ik_data.get('createdAt') or time.strftime('%Y-%m-%dT%H:%M:%SZ')
                }
                print(f"   [BERHASIL UNGGAH] -> {ik_data.get('url')} ({webp_size_kb} KB)")
                uploaded = True
                success_count += 1
                break
            else:
                print(f"   [RETRY {attempt}] HTTP {res.status_code}: {res.text[:120]}")
                time.sleep(2)
        except Exception as e:
            print(f"   [RETRY {attempt}] Exception: {e}")
            time.sleep(2)
    
    if not uploaded:
        print(f"   [GAGAL UNGGAH SETELAH 3x RETRY]")
        fail_count += 1
    
    if idx % 10 == 0:
        with open(MANIFEST_FILE, 'w', encoding='utf-8') as mf:
            json.dump(manifest, mf, indent=2)

# Final Save Manifest
with open(MANIFEST_FILE, 'w', encoding='utf-8') as mf:
    json.dump(manifest, mf, indent=2)

print("\n=== RINGKASAN PIPELINE ===")
print(f"Total Berkas: {len(raw_files)}")
print(f"Berhasil Unggah: {success_count}")
print(f"Sudah Ada / Dilewati: {skip_count}")
print(f"Gagal: {fail_count}")
print(f"Manifest tersimpan di: {MANIFEST_FILE}")
