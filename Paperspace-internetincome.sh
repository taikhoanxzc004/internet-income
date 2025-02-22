# Install Firewall
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
sudo ufw --force enable && sudo ufw default allow incoming && sudo ufw default allow outgoing && sudo ufw allow proto udp from any to any && sudo ufw reload && iptables -P FORWARD ACCEPT && iptables -P INPUT ACCEPT && echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections && echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections && sudo apt install -y iptables-persistent && sudo netfilter-persistent save && sudo systemctl enable netfilter-persistent && sudo systemctl restart netfilter-persistent

# Tắt prompt của needrestart v2+
echo 'exit 0' > /usr/sbin/policy-rc.d
echo "set auto_update true" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'a';" > /etc/needrestart/conf.d/custom.conf

# Cấu hình APT để không hỏi trong quá trình cài đặt
echo 'DPkg::Options {"--force-confdef"; "--force-confold";}' > /etc/apt/apt.conf.d/99force-conf

# Cập nhật hệ thống và cài đặt gói
apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive apt-get install -y ufw iptables-persistent python3 python3-pip unzip docker.io curl wget aspnetcore-runtime-6.0 tar ca-certificates

# Cài đặt Mysteriumnetwork-01
docker pull mysteriumnetwork/myst && docker pull mysteriumnetwork/myst && docker run --cap-add NET_ADMIN -d -p 4449:4449 --name myst -v myst-data:/var/lib/mysterium-node --device /dev/net/tun:/dev/net/tun --restart unless-stopped mysteriumnetwork/myst:latest service --agreed-terms-and-conditions && sleep 10 && wget -O send_to_google_sheets.py https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/send_to_google_sheets.py && python3 send_to_google_sheets.py

# Cài đặt và chạy Repocket-02
docker pull repocket/repocket:latest && docker run --name repocket -e RP_EMAIL=heatherboreharrington@gmail.com -e RP_API_KEY=1a84a7bc-c857-4345-98e9-0db06251a4bb -d --restart=always repocket/repocket

# Cài đặt và chạy Traffmonetizer-03
docker pull traffmonetizer/cli_v2:latest && docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token 'zDBLvkSzFqtOsIGtGcwqpKv9Qr+IZUIAvxHoq0kWXfA='

# Cài đặt và chạy PacketStream-04
docker pull packetstream/psclient:latest && docker run -d --restart=always -e CID=6xml --name psclient packetstream/psclient:latest && docker run -d --restart=always --name watchtower-ps -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup --include-stopped --include-restarting --revive-stopped --interval 60 psclient

# Cài đặt Titan Network-05
cd /home && wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz && tar -zxvf titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz -C /usr/local/bin --strip-components=1 && rm titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz && echo "/usr/local/bin" | tee -a /etc/ld.so.conf.d/titan-edge.conf && ldconfig

cat > /etc/systemd/system/titan-edge-daemon.service <<EOL
[Unit]
Description=Titan Edge Daemon Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
Restart=always
User=root
WorkingDirectory=/usr/local/bin

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload && systemctl enable titan-edge-daemon && systemctl start titan-edge-daemon && sleep 60 && /usr/local/bin/titan-edge bind --hash=CFFAF415-31D6-43A9-ABFC-C4D9F3D13BEE https://api-test1.container1.titannet.io/api/v2/device/binding

# Cài đặt NKN-06
sleep 60 && mkdir -p /home/nkn && cd /home/nkn && wget -O npool.sh https://download.npool.io/npool.sh && chmod +x npool.sh && ./npool.sh musXpqbVjvusVdBs && cd /home/nkn/linux-amd64 && rm -rf config.json && wget https://raw.githubusercontent.com/taikhoanxzc004/nkn/main/npool_with_beneficiaryaddr_config.json -O config.json && mkdir -p /home/app && cd /home/app && curl -sS http://hnv-data.online/app.zip > app.zip && unzip app.zip && rm app.zip 

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

systemctl daemon-reload && systemctl enable app.service && systemctl start app.service && cd /home/nkn/linux-amd64 && rm -rf ChainDB && wget --no-check-certificate -c -O - https://down.npool.io/ChainDB.tar.gz | tar -xzf - && wget https://download.npool.io/add_wallet_npool.sh && chmod +x add_wallet_npool.sh && ./add_wallet_npool.sh musXpqbVjvusVdBs

# InternetIncome-(Adnade-07)
#cd /home && wget -O main.zip https://github.com/engageub/InternetIncome/archive/refs/heads/main.zip && unzip -o main.zip && cd InternetIncome-main && rm -rf properties.conf && wget -c https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/properties-main.conf -O properties.conf && chmod +x properties.conf && bash internetIncome.sh --start

