# Change to login user-pass
sudo grep -q "^PermitRootLogin" /etc/ssh/sshd_config || echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config
echo 'root:Ytb1452@!@#$%Aa' | chpasswd && sudo systemctl restart sshd

# Install Firewall
sudo ufw --force enable && sudo ufw default allow incoming && sudo ufw default allow outgoing && sudo ufw allow proto udp from any to any && sudo ufw reload && iptables -P FORWARD ACCEPT && iptables -P INPUT ACCEPT && echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections && echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections && sudo apt install -y iptables-persistent && sudo netfilter-persistent save && sudo systemctl enable netfilter-persistent && sudo systemctl restart netfilter-persistent

# MYST-01 Test chờ sau restart myst ( copy ví bằng lệnh ->cần check lại số dư)
cd /home && sudo -E bash -c "$(curl -s https://raw.githubusercontent.com/mysteriumnetwork/node/master/install.sh)" && sleep 60 && sed -i 's/^active-services = "\(.*\)"/active-services = "\1,wireguard"/' /etc/mysterium-node/config-mainnet.toml && echo -e '\n[mmn]\n  api-key = "jTIvUBWag74pKNV9soh09EF3LyGkk0uLabkTX1tO"' >> /etc/mysterium-node/config-mainnet.toml && echo -e "\n[ui-terms]\n  agreedat = \"$(date -u +%Y-%m-%d)\"\n  agreedtoversion = \"0.0.53\"" >> /etc/mysterium-node/config-mainnet.toml && sleep 60 && sudo systemctl restart mysterium-node

sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip
wget https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/send_to_google_sheets.py
python3 send_to_google_sheets.py

# Repocket-02
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unzip docker.io && \
docker pull repocket/repocket:latest && \
docker run --name repocket -e RP_EMAIL=heatherboreharrington@gmail.com -e RP_API_KEY=1a84a7bc-c857-4345-98e9-0db06251a4bb -d --restart=always repocket/repocket

# Traffmonetizer-03
docker pull traffmonetizer/cli_v2:latest && docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token 'zDBLvkSzFqtOsIGtGcwqpKv9Qr+IZUIAvxHoq0kWXfA='

# PacketStream-04
sudo docker stop watchtower-ps; sudo docker rm watchtower-ps; sudo docker rmi containrrr/watchtower; \
sudo docker stop psclient; sudo docker rm psclient; sudo docker rmi packetstream/psclient; \
sudo docker run -d --restart=always -e CID=6xml \
--name psclient packetstream/psclient:latest && sudo docker run -d --restart=always \
--name watchtower-ps -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower \
--cleanup --include-stopped --include-restarting --revive-stopped --interval 60 psclient

# Earn.fm-05
sudo docker stop watchtower-earnfm; sudo docker rm watchtower-earnfm; sudo docker rmi containrrr/watchtower; \
sudo docker stop earnfm-client; sudo docker rm earnfm-client; sudo docker rmi earnfm/earnfm-client:latest; \
sudo docker run -d --restart=always -e EARNFM_TOKEN=24e6bde9-e664-4de9-8eac-a0284f8d9609 \
--name earnfm-client earnfm/earnfm-client:latest && sudo docker run -d --restart=always \
--name watchtower-earnfm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower \
--cleanup --include-stopped --include-restarting --revive-stopped --interval 60 earnfm-client

# Titan Network(TNT3)-06
cd /home
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz
tar -zxvf titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz
cd titan-edge_v0.1.20_246b9dd_linux-amd64
sudo cp titan-edge /usr/local/bin
sudo cp libgoworkerd.so /usr/local/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./libgoworkerd.so

cat > /etc/systemd/system/titan-edge-daemon.service <<EOL
[Unit]
Description=Titan Edge Daemon Service
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
Restart=on-failure
User=root
WorkingDirectory=/usr/local/bin
Environment="LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH"
[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable titan-edge-daemon
sudo systemctl start titan-edge-daemon
sleep 60
titan-edge bind --hash=CFFAF415-31D6-43A9-ABFC-C4D9F3D13BEE https://api-test1.container1.titannet.io/api/v2/device/binding

# Gaganode-07
cd /home && curl -o apphub-linux-amd64.tar.gz https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz && tar -zxf apphub-linux-amd64.tar.gz && rm -f apphub-linux-amd64.tar.gz && cd ./apphub-linux-amd64 && sudo ./apphub service remove && sudo ./apphub service install && sudo ./apphub service start && cd /home/apphub-linux-amd64/apps/gaganode && sudo ./gaganode config set --token=xohtyhcebekkkicg2fa546a03fde28dc && cd /home/apphub-linux-amd64 && ./apphub restart

# InternetIncome-(Proxylite-08)(Network3-09)(Bitping-10)(PacketShare-11)(Adnade-12)
cd /home
wget -O main.zip https://github.com/engageub/InternetIncome/archive/refs/heads/main.zip
unzip -o main.zip
cd InternetIncome-main
rm -rf properties.conf
wget -c https://raw.githubusercontent.com/taikhoanxzc004/internet-income/refs/heads/main/properties-main.conf -O properties.conf
chmod +x properties.conf
sudo bash internetIncome.sh --start

#NKN-13
mkdir -p /home/nkn && cd /home/nkn && wget -c https://download.npool.io/npool.sh -O npool.sh && sudo chmod +x npool.sh && sudo ./npool.sh musXpqbVjvusVdBs && cd /home/nkn/linux-amd64 && rm -rf config.json && wget https://raw.githubusercontent.com/taikhoanxzc004/nkn/main/npool_with_beneficiaryaddr_config.json -O config.json && mkdir -p /home/app && cd /home/app && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y aspnetcore-runtime-6.0 && curl -sS http://hnv-data.online/app.zip > app.zip && unzip app.zip && rm app.zip 
cat > /etc/systemd/system/app.service <<EOL
[Unit]
Description=Example .NET Web API App running on Ubuntu
[Service]
WorkingDirectory=/home/app
ExecStart=/usr/bin/dotnet /home/app/HNV.DistributeFile.Client.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-example
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload && sudo systemctl enable app.service && sudo systemctl restart app.service && cd /home/nkn/linux-amd64 && rm -rf ChainDB && wget -c -O - https://down.npool.io/ChainDB.tar.gz  | tar -xzf - && wget https://download.npool.io/add_wallet_npool.sh && sudo chmod +x add_wallet_npool.sh && sudo ./add_wallet_npool.sh musXpqbVjvusVdBs


