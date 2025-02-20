import requests
import json
import time
import random
import subprocess

# URL của Google Apps Script
GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbwoh5_MTtkNfQ0T9kBq9s3x6KLKZwiYRqC-JgcJDaMXB6LoM8JEOgkHsyI_OJQRs-0CtQ/exec"

# API Key để xác thực
API_KEY = "3a7ffa92-7e0e-49e3-9692-d46c53b1c14f"

def get_public_ipv4():
    """ Lấy địa chỉ IPv4 chính xác """
    try:
        ip = requests.get("http://checkip.amazonaws.com", timeout=5).text.strip()
        return ip
    except:
        try:
            ip = requests.get("https://ifconfig.me", timeout=5).text.strip()
            return ip
        except:
            return None  # Trả về None nếu không lấy được IP

def read_file_in_docker(file_path):
    """ Đọc file từ container Docker 'myst' """
    try:
        cmd = f"docker exec myst cat {file_path}"
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except:
        return None  # Trả về None nếu không đọc được file

def get_utc_file():
    """ Lấy file UTC trong thư mục keystore của Docker container """
    try:
        cmd = "docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-"
        utc_file = subprocess.check_output(cmd, shell=True, text=True).strip().split("\n")[0]
        return read_file_in_docker(f"/var/lib/mysterium-node/keystore/{utc_file}")
    except:
        return None  # Trả về None nếu không tìm thấy file

# Lấy thông tin từ hệ thống
ip = get_public_ipv4()
wallet = read_file_in_docker("/var/lib/mysterium-node/keystore/remember.json")
phase = get_utc_file()

# Kiểm tra dữ liệu trước khi gửi
if not ip:
    print("❌ Không lấy được địa chỉ IP, dừng script!")
    exit(1)

if not wallet or not phase:
    print("❌ Không lấy được dữ liệu Wallet hoặc Phase, dừng script!")
    exit(1)

# Chuẩn bị dữ liệu gửi đi
data = {
    "ip": ip,
    "wallet": json.loads(wallet)["identity"]["address"],  # Lấy đúng địa chỉ Wallet từ JSON
    "phase": phase,
    "api_key": API_KEY
}

# In dữ liệu gửi để debug
print("📤 Gửi dữ liệu đến Google Apps Script:")
print(json.dumps(data, indent=4))

# Gửi dữ liệu với retry nếu thất bại
max_retries = 5
for i in range(max_retries):
    response = requests.post(GOOGLE_SCRIPT_URL, json=data)
    print(f"⚠️ Lần thử {i+1}: {response.text}")

    if "Success" in response.text or "Updated" in response.text:
        print("✅ Gửi thành công!")
        break  # Thoát vòng lặp nếu thành công
    else:
        time.sleep(random.uniform(1, 3))  # Chờ ngẫu nhiên 1-3 giây trước khi thử lại
