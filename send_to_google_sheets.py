import subprocess
import json
import requests
import os

WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbwLHMoFqrgsnabKeFaFez-nwRmQ5lqiEJSr4TuNu780A5_dSPdpMdaSUE5Lr9ng5p7HQQ/exec"

def get_ipv4():
    try:
        ipv4 = os.getenv("IP")  # Lấy IP từ biến môi trường
        return ipv4 if ipv4 else None
    except Exception as e:
        print("Lỗi lấy IP:", e)
        return None

def get_wallet_data():
    try:
        result = subprocess.check_output("docker exec myst cat /var/lib/mysterium-node/keystore/remember.json", shell=True)
        return result.decode().strip()
    except Exception as e:
        print("Lỗi lấy remember.json:", e)
        return None

def get_phase_data():
    try:
        file_list = subprocess.check_output("docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-", shell=True)
        file_name = file_list.decode().strip().split("\n")[0]
        phase_data = subprocess.check_output(f"docker exec myst cat /var/lib/mysterium-node/keystore/{file_name}", shell=True)
        return phase_data.decode().strip()
    except Exception as e:
        print("Lỗi lấy file UTC-:", e)
        return None

ipv4 = get_ipv4()
wallet_data = get_wallet_data()
phase_data = get_phase_data()

if not ipv4:
    print("Lỗi: Không lấy được IP! Kiểm tra biến môi trường IP.")
    exit()

if not wallet_data:
    print("Cảnh báo: Nội dung remember.json bị rỗng hoặc lỗi!")
if not phase_data:
    print("Cảnh báo: Nội dung UTC- bị rỗng hoặc lỗi!")

data = {
    "ipv4": ipv4,
    "wallet_data": wallet_data or "N/A",
    "phase_data": phase_data or "N/A"
}

print("Dữ liệu gửi đi:")
print(json.dumps(data, indent=2))

try:
    headers = {"Content-Type": "application/json; charset=utf-8"}
    response = requests.post(WEBHOOK_URL, json=data, headers=headers)
    print("Phản hồi từ server:", response.text)
except Exception as e:
    print("Lỗi khi gửi request:", e)
