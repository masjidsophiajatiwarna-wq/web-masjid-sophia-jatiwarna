# -*- coding: utf-8 -*-
"""
IndexNow URL Submission Script
Masjid Musafir Sophia Jatiwarna
Mengirimkan URL sitemap secara instan ke search engine Bing, Yandex, dan protokol IndexNow.
"""

import os
import sys
import glob
import xml.etree.ElementTree as ET
import json
import requests

def get_indexnow_key():
    # Cari file key *.txt di root direktori (panjang hex 32 karakter)
    key_files = glob.glob("*.txt")
    for kf in key_files:
        basename = os.path.splitext(os.path.basename(kf))[0]
        if len(basename) == 32 and all(c in "0123456789abcdefABCDEF" for c in basename):
            with open(kf, "r", encoding="utf-8") as f:
                content = f.read().strip()
                if content == basename:
                    return basename, kf
    # Fallback jika nama file spesifik
    if os.path.exists("3c0606547e9f4e598bddd982c65cf8f0.txt"):
        with open("3c0606547e9f4e598bddd982c65cf8f0.txt", "r", encoding="utf-8") as f:
            content = f.read().strip()
            return content, "3c0606547e9f4e598bddd982c65cf8f0.txt"
    return None, None

def get_sitemap_urls(host="masjidsophia.com"):
    urls = []
    if os.path.exists("sitemap.xml"):
        try:
            tree = ET.parse("sitemap.xml")
            root = tree.getroot()
            namespace = {"ns": "http://www.sitemaps.org/schemas/sitemap/0.9"}
            for loc in root.findall(".//ns:loc", namespace):
                url = loc.text.strip()
                # Pastikan netloc sesuai dengan host domain agar tidak ditolak dengan status 422
                if url.startswith(f"https://{host}/") or url.startswith(f"http://{host}/"):
                    urls.append(url)
        except Exception as e:
            print(f"[WARN] Gagal membaca sitemap.xml: {e}")

    # Default URLs jika sitemap kosong / gagal
    if not urls:
        urls = [
            f"https://{host}/",
            f"https://{host}/galeri",
            f"https://{host}/artikel"
        ]
    return urls

def submit_indexnow(host="masjidsophia.com"):
    key, key_file = get_indexnow_key()
    if not key:
        print("[ERROR] File kunci IndexNow (*.txt) tidak ditemukan di direktori root.")
        return False

    urls = get_sitemap_urls(host)
    key_location = f"https://{host}/{key_file}"

    payload = {
        "host": host,
        "key": key,
        "keyLocation": key_location,
        "urlList": urls
    }

    print("=== PENGIRIMAN INDEXNOW INSTANT SEARCH ENGINE ===")
    print(f"[INFO] Host Domain   : {host}")
    print(f"[INFO] Key File     : {key_file}")
    print(f"[INFO] Key Location : {key_location}")
    print(f"[INFO] Total URLs   : {len(urls)}")
    for u in urls:
        print(f"       - {u}")

    endpoints = [
        ("IndexNow.org", "https://api.indexnow.org/indexnow"),
        ("Microsoft Bing", "https://www.bing.com/indexnow")
    ]

    all_success = True
    headers = {"Content-Type": "application/json; charset=utf-8"}

    for name, endpoint in endpoints:
        print(f"\n[INFO] Mengirim payload ke {name} ({endpoint})...")
        try:
            resp = requests.post(endpoint, json=payload, headers=headers, timeout=15)
            if resp.status_code in [200, 202]:
                print(f"[SUCCESS] {name} merespons dengan HTTP {resp.status_code} ({resp.reason}).")
                print("          URL berhasil diterima ke dalam antrean pengindeksan instan.")
            else:
                print(f"[FAILED] {name} merespons dengan HTTP {resp.status_code}: {resp.text}")
                all_success = False
        except Exception as err:
            print(f"[ERROR] Koneksi ke {name} gagal: {err}")
            all_success = False

    print("\n=== RINGKASAN SUBMISI INDEXNOW ===")
    if all_success:
        print("[SELESAI] Seluruh endpoint IndexNow berhasil dihubungi.")
    else:
        print("[SELESAI DENGAN CATATAN] Terdapat endpoint yang mengembalikan respon non-200.")
    return all_success

if __name__ == "__main__":
    submit_indexnow()
