import subprocess
import json
import requests

WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbyLEYqz7ZHdAA00noVtr-ItbK19eHmUknQ4eGs5le31CNj_rSfuo5uvIjAeQirBtPQJxw/exec"

def get_ipv4():
    try:
        ipv4 = subprocess.check_output("curl -s ifconfig.me || curl -s https://checkip.amazonaws.com", shell=True).decode().strip()
        return ipv4.split("\n")[0].strip() if ipv4 else None
    except Exception as e:
        print("Lỗi lấy IP:", e)
        return None

def get_wallet_data():
    try:
        result = subprocess.check_output("docker exec myst cat /var/lib/mysterium-node/keystore/remember.json", shell=True)
        return json.loads(result.decode().strip())["identity"]["address"]
    except Exception as e:
        print("Lỗi lấy remember.json:", e)
        return None

def get_phase_data():
    try:
        file_list = subprocess.check_output("docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-", shell=True)
        file_name = file_list.decode().strip().split("\n")[0]
        phase_data = subprocess.check_output(f"docker exec myst cat /var/lib/mysterium-node/keystore/{file_name}", shell=True)
        return json.loads(phase_data.decode().strip())["address"]
    except Exception as e:
        print("Lỗi lấy file UTC-:", e)
        return None

ipv4 = get_ipv4()
wallet_data = get_wallet_data()
phase_data = get_phase_data()

if not ipv4:
    print("Lỗi: Không lấy được IP! Kiểm tra kết nối mạng hoặc lệnh curl.")
    exit()

data = {
    "ipv4": ipv4,
    "wallet_data": wallet_data or "N/A",
    "phase_data": phase_data or "N/A"
}

print("Dữ liệu gửi đi:", json.dumps(data, indent=2))

try:
    response = requests.post(WEBHOOK_URL, json=data)
    print("Phản hồi từ server:", response.text)
except Exception as e:
    print("Lỗi khi gửi request:", e)
