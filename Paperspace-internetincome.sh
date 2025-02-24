# Cập nhật hệ thống và cài đặt firewall
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

sudo ufw --force enable && sudo ufw default allow incoming && sudo ufw default allow outgoing && sudo ufw allow proto udp from any to any
sudo ufw reload
iptables -P FORWARD ACCEPT && iptables -P INPUT ACCEPT
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent && sudo systemctl restart netfilter-persistent

# Tắt prompt của needrestart v2+
echo 'exit 0' > /usr/sbin/policy-rc.d
echo "set auto_update true" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/custom.conf

# Cấu hình APT để không hỏi trong quá trình cài đặt
echo 'DPkg::Options {"--force-confdef"; "--force-confold";}' > /etc/apt/apt.conf.d/99force-conf

# Cập nhật danh sách package
apt-get update && apt-get upgrade -y 

# Cài đặt các gói cần thiết
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    ufw \
    iptables-persistent \
    python3 \
    python3-pip \
    unzip \
    aspnetcore-runtime-6.0 \
    tar \
    wget

# Tạo thư mục chứa khóa GPG của Docker
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | tee /etc/apt/keyrings/docker.asc | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Thêm repository chính thức của Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Cập nhật lại danh sách package
apt-get update

# Cài đặt Docker
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl start docker
systemctl enable docker

# Cài đặt Mysteriumnetwork-01
docker pull mysteriumnetwork/myst
docker rm -f myst || true
docker run --cap-add NET_ADMIN -d -p 4449:4449 --name myst -v myst-data:/var/lib/mysterium-node --device /dev/net/tun:/dev/net/tun --restart unless-stopped mysteriumnetwork/myst:latest service --agreed-terms-and-conditions

# Chờ một chút trước khi chạy script Python
sleep 10
wget -O send_to_google_sheets.py https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/send_to_google_sheets.py && python3 send_to_google_sheets.py || echo "Lỗi khi tải hoặc chạy send_to_google_sheets.py"

# Cài đặt và chạy Repocket-02
docker pull repocket/repocket:latest
docker run --name repocket -e RP_EMAIL=heatherboreharrington@gmail.com -e RP_API_KEY=1a84a7bc-c857-4345-98e9-0db06251a4bb -d --restart=always repocket/repocket

# Cài đặt và chạy Traffmonetizer-03
docker pull traffmonetizer/cli_v2:latest
docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token 'zDBLvkSzFqtOsIGtGcwqpKv9Qr+IZUIAvxHoq0kWXfA='

# Cài đặt Titan Network-05
cd /home
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz
tar -zxvf titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz
echo "/usr/local/bin" | tee -a /etc/ld.so.conf.d/titan-edge.conf
ldconfig
systemctl daemon-reload
systemctl enable titan-edge-daemon
systemctl start titan-edge-daemon

# Cập nhật Google Sheet
IP=$(curl -4 -s ifconfig.me | awk '{print $1}')
curl -L -X POST -H "Content-Type: application/json" \
    -d "$(jq -n --arg ip "$IP" '{ip: $ip}')" \
    "https://script.google.com/macros/s/AKfycbwlopX4pez19tjR7vGYfyWEPtOdkSgHtmBScEHsFvYsA6LngwBpoUEKauDAcN9zdYltrg/exec"
