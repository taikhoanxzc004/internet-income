import requests
import json
import subprocess

# 🔑 API Key
API_KEY = "3a7ffa92-7e0e-49e3-9692-d46c53b1c14f"
GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbyrxChDhFuqxShFTHDGrIJhajOujym-j5I_CTLrXmRbRyEYZD7GvpswprAgXK4C3nFksA/exec"

def get_public_ip():
    """Lấy địa chỉ IP công khai"""
    try:
        return subprocess.check_output("curl -4 http://checkip.amazonaws.com", shell=True, text=True).strip()
    except:
        return None

def get_wallet_address():
    """Lấy địa chỉ ví từ Mysterium Node"""
    try:
        cmd = "docker exec myst cat /var/lib/mysterium-node/keystore/remember.json"
        output = subprocess.check_output(cmd, shell=True, text=True)
        return json.loads(output)["identity"]["address"]
    except:
        return None

def get_phase_id():
    """Lấy giá trị ID từ file keystore (UTC) của Mysterium Node"""
    try:
        cmd = "docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-"
        utc_file = subprocess.check_output(cmd, shell=True, text=True).strip().split("\n")[0]

        cmd_read = f"docker exec myst cat /var/lib/mysterium-node/keystore/{utc_file}"
        utc_content = subprocess.check_output(cmd_read, shell=True, text=True)

        return json.loads(utc_content).get("id", "unknown")  # Chỉ lấy giá trị ID
    except:
        return None

def send_data_to_google_sheets():
    """Gửi dữ liệu lên Google Apps Script"""
    ip = get_public_ip()
    wallet = get_wallet_address()
    phase = get_phase_id()

    if not ip or not wallet or not phase:
        print("❌ Lỗi: Không thể lấy đủ dữ liệu.")
        return

    data = {
        "ip": ip,
        "wallet": wallet,
        "phase": phase,
        "api_key": API_KEY
    }

    try:
        response = requests.post(GOOGLE_SCRIPT_URL, json=data)
        print("📤 Gửi dữ liệu đến Google Sheets:", json.dumps(data, indent=4))
        print("📩 Phản hồi từ Google:", response.text)
    except Exception as e:
        print("❌ Lỗi khi gửi dữ liệu:", str(e))

# Chạy script
if __name__ == "__main__":
    send_data_to_google_sheets()
