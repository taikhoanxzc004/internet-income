import requests
import json
import time
import random
import subprocess

GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbxp571hXbW6gezLdCe5aImBe6MkoGYYNopUWx0QAvKy7gtK1uniYIj5RDNrnqNPo6h1XA/exec"
API_KEY = "3a7ffa92-7e0e-49e3-9692-d46c53b1c14f"

def get_public_ipv4():
    """ Lấy địa chỉ IP công khai """
    try:
        return requests.get("http://checkip.amazonaws.com", timeout=5).text.strip()
    except:
        try:
            return requests.get("https://ifconfig.me", timeout=5).text.strip()
        except:
            return None

def run_docker_command(command):
    """ Chạy lệnh Docker và xử lý lỗi """
    try:
        return subprocess.check_output(command, shell=True, text=True).strip()
    except:
        return None

def get_wallet():
    """ Lấy dữ liệu Wallet từ container Docker """
    return run_docker_command("docker exec myst cat /var/lib/mysterium-node/keystore/remember.json")

def get_phase():
    """ Lấy dữ liệu Phase từ container Docker """
    utc_file = run_docker_command("docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-")
    if utc_file:
        return run_docker_command(f"docker exec myst cat /var/lib/mysterium-node/keystore/{utc_file}")
    return None

# Lấy thông tin cần gửi
ip = get_public_ipv4()
wallet = get_wallet()
phase = get_phase()

if ip and wallet and phase:
    data = {"ip": ip, "wallet": wallet, "phase": phase}
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}

    max_retries = 5
    for i in range(max_retries):
        try:
            response = requests.post(GOOGLE_SCRIPT_URL, json=data, headers=headers, timeout=10)
            if response.status_code == 200 and ("Updated" in response.text or "Added" in response.text):
                print("✅ Dữ liệu đã được cập nhật:", response.text)
                break
            else:
                print(f"⚠️ Lần thử {i+1} thất bại: {response.text}")
        except requests.exceptions.RequestException as e:
            print(f"❌ Lỗi mạng: {e}")

        time.sleep(random.uniform(1, 3))  # Giảm nguy cơ bị chặn API
else:
    print("❌ Không thể gửi dữ liệu vì thiếu thông tin hợp lệ.")
