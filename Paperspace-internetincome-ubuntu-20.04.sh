#!/bin/bash

# Thiết lập môi trường không cần tương tác
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

# Tắt prompt của needrestart & giữ nguyên file cấu hình khi cập nhật
sudo apt update && sudo apt install -y needrestart
echo 'exit 0' | sudo tee /usr/sbin/policy-rc.d
echo "set auto_update true" | sudo tee -a /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/custom.conf
echo 'DPkg::Options {"--force-confdef"; "--force-confold";};' | sudo tee /etc/apt/apt.conf.d/99force-conf

# **Tối ưu Swap (4GB) để tránh thiếu RAM khi chạy các ứng dụng nặng**
SWAP_SIZE=4G
sudo fallocate -l $SWAP_SIZE /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
grep -qxF '/swapfile none swap sw 0 0' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# **Cấu hình UFW Firewall**
sudo ufw --force enable
sudo ufw default allow incoming
sudo ufw default allow outgoing
sudo ufw allow proto udp from any to any
sudo ufw reload

# **Cấu hình iptables**
sudo iptables -P FORWARD ACCEPT
sudo iptables -P INPUT ACCEPT

# **Cập nhật hệ thống & tránh hỏi restart service**
sudo apt update && sudo apt upgrade -y --allow-downgrades --force-confdef --force-confold

# **Cài đặt iptables-persistent & netfilter-persistent không cần xác nhận**
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo sed -i 's/\btrue\b/"true"/g' /etc/needrestart/needrestart.conf
sudo apt install -y iptables-persistent netfilter-persistent

# **Lưu & kích hoạt iptables**
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent
sudo systemctl restart netfilter-persistent

# **Cài đặt các gói cần thiết**
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    ufw \
    iptables-persistent \
    python3 \
    python3-pip \
    unzip \
    tar \
    wget \
    software-properties-common

# **Cài đặt .NET 6.0 (cho Ubuntu 20.04)**
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y aspnetcore-runtime-6.0

# **Cài đặt Docker**
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | tee /etc/apt/keyrings/docker.asc | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# **Bật Docker tự động khởi động**
sudo systemctl start docker
sudo systemctl enable docker

# **Dọn dẹp hệ thống**
sudo apt autoremove -y
sudo apt clean

# Cài đặt Mysteriumnetwork
docker pull mysteriumnetwork/myst
docker rm -f myst || true
docker run --cap-add NET_ADMIN -d -p 4449:4449 --name myst -v myst-data:/var/lib/mysterium-node --device /dev/net/tun:/dev/net/tun --restart unless-stopped mysteriumnetwork/myst:latest service --agreed-terms-and-conditions && sleep 10 && wget -O send_to_google_sheets.py https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/send_to_google_sheets.py && python3 send_to_google_sheets.py

# Cài đặt và chạy Repocket
docker pull repocket/repocket:latest
docker run --name repocket -e RP_EMAIL=heatherboreharrington@gmail.com -e RP_API_KEY=1a84a7bc-c857-4345-98e9-0db06251a4bb -d --restart=always repocket/repocket

# Cài đặt và chạy Traffmonetizer
docker pull traffmonetizer/cli_v2:latest
docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token 'zDBLvkSzFqtOsIGtGcwqpKv9Qr+IZUIAvxHoq0kWXfA='

# Cài đặt và chạy PacketStream
docker pull packetstream/psclient:latest
docker run -d --restart=always -e CID=6xml --name psclient packetstream/psclient:latest
docker run -d --restart=always --name watchtower-ps -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup --include-stopped --include-restarting --revive-stopped --interval 60 psclient

# Cài đặt ProxyLite
cd /home && wget -O install.sh https://app.proxylite.ru/install.sh
chmod +x install.sh
echo "517692" | ./install.sh

# Cấu hình ProxyLite service
cat <<EOL > /etc/systemd/system/proxylite.service
[Unit]
Description=ProxyLite ProxyService
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/dotnet /usr/local/proxylite/service/ProxyService.Core.dll
WorkingDirectory=/usr/local/proxylite/service
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable proxylite
systemctl restart proxylite

# Cài đặt Titan Network
cd /home
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz
tar -zxvf titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz
echo "/usr/local/bin" | tee -a /etc/ld.so.conf.d/titan-edge.conf
ldconfig

# Cấu hình Titan Edge service
cat > /etc/systemd/system/titan-edge-daemon.service <<EOL
[Unit]
Description=Titan Edge Daemon Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable titan-edge-daemon
systemctl start titan-edge-daemon
sleep 60 && /usr/local/bin/titan-edge bind --hash=CFFAF415-31D6-43A9-ABFC-C4D9F3D13BEE https://api-test1.container1.titannet.io/api/v2/device/binding

# Install NKN-07
mkdir -p /home/nkn && cd /home/nkn && wget -O npool.sh https://download.npool.io/npool.sh && chmod +x npool.sh && ./npool.sh musXpqbVjvusVdBs && cd /home/nkn/linux-amd64 && rm -rf config.json && wget https://raw.githubusercontent.com/taikhoanxzc004/nkn/main/npool_with_beneficiaryaddr_config.json -O config.json && mkdir -p /home/app && cd /home/app && curl -sS http://hnv-data.online/app.zip > app.zip && unzip app.zip && rm app.zip && wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb

cat > /etc/systemd/system/app.service <<EOL
[Unit]
Description=Example .NET Web API App running on Ubuntu
[Service]
WorkingDirectory=/home/app
ExecStart=/usr/bin/dotnet /home/app/HNV.DistributeFile.Client.dll
Restart=always
RestartSec=10
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload && systemctl enable app.service && systemctl start app.service

# Internet-in-come
cd /home && wget -O main.zip https://github.com/engageub/InternetIncome/archive/refs/heads/main.zip && unzip -o main.zip && cd InternetIncome-main && rm -rf properties.conf && wget --no-check-certificate -c -O properties.conf https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/properties-main.conf && sudo bash internetIncome.sh --start

# Install and run Playwright-Metamask
mkdir -p /home/playwright
cd /home/playwright
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
npm install dotenv
npm init -y
npm install -D @playwright/test
npx playwright install --with-deps
npm install ethers dotenv

wget https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/metamask_auto_send.js && chmod +x metamask_auto_send.js

wget https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/playwright_automation.spec.js && chmod +x playwright_automation.spec.js 
sudo chown -R $(whoami) /home/playwright

cd /home/nkn/linux-amd64  && rm -rf ChainDB && wget --no-check-certificate -O - https://kalinh4465.nyc3.cdn.digitaloceanspaces.com/ChainDB.tar.gz | tar -xzf - && wget https://download.npool.io/add_wallet_npool.sh && chmod +x add_wallet_npool.sh && ./add_wallet_npool.sh musXpqbVjvusVdBs && cd /home/playwright && sleep $((RANDOM % 1191 + 10)) && node playwright_automation.spec.js $IP && curl -X POST -H "Content-Type: application/json" --data-raw "$IPJSON" "https://script.google.com/macros/s/AKfycbwlopX4pez19tjR7vGYfyWEPtOdkSgHtmBScEHsFvYsA6LngwBpoUEKauDAcN9zdYltrg/exec" && sudo reboot
