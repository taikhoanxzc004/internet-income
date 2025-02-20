import subprocess
import json
import requests

# ==== CẤU HÌNH URL GOOGLE APPS SCRIPT ====
WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbyTXi_fn0NGs14tXBYD1lSVE_Y6yDlUz2w6QhN_t2usMSBu9LeWVfEH8TGgfHOnOgHU9Q/exec"  # Thay XXX bằng URL của bạn

# ==== HÀM LẤY CHÍNH XÁC IP V4 ====
def get_ipv4():
    try:
        ipv4 = subprocess.check_output("curl -s ifconfig.me", shell=True).decode().strip()
        if not ipv4:
            ipv4 = subprocess.check_output("curl -s https://checkip.amazonaws.com", shell=True).decode().strip()
        return ipv4
    except Exception as e:
        print("Lỗi lấy IP:", e)
        return None

# ==== HÀM LẤY NỘI DUNG remember.json ====
def get_wallet_data():
    try:
        result = subprocess.check_output("docker exec myst cat /var/lib/mysterium-node/keystore/remember.json", shell=True)
        return result.decode().strip()  # Trả về toàn bộ JSON dưới dạng chuỗi
    except Exception as e:
        print("Lỗi lấy remember.json:", e)
        return None

# ==== HÀM LẤY NỘI DUNG FILE UTC- ====
def get_phase_data():
    try:
        file_list = subprocess.check_output("docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-", shell=True)
        file_name = file_list.decode().strip().split("\n")[0]  # Lấy file đầu tiên nếu có nhiều file
        phase_data = subprocess.check_output(f"docker exec myst cat /var/lib/mysterium-node/keystore/{file_name}", shell=True)
        return phase_data.decode().strip()  # Trả về toàn bộ nội dung file UTC-
    except Exception as e:
        print("Lỗi lấy file UTC-:", e)
        return None

# ==== LẤY DỮ LIỆU & GỬI LÊN GOOGLE SHEETS ====
ipv4 = get_ipv4()
wallet_data = get_wallet_data()
phase_data = get_phase_data()

data = {
    "ipv4": ipv4,
    "wallet_data": wallet_data,
    "phase_data": phase_data
}

response = requests.post(WEBHOOK_URL, json=data)

print("Response:", response.text)
