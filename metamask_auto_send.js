require("dotenv").config();
const { ethers } = require("ethers");

// Lấy danh sách API Keys từ biến môi trường
const INFURA_KEYS = process.env.INFURA_KEYS.split(",");
const MYST_CONTRACT = "0x1379E8886A944d2D9d440b3d88DF536Aea08d9F3";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Chọn API Key ngẫu nhiên từ danh sách
function getRandomApiKey() {
    return INFURA_KEYS[Math.floor(Math.random() * INFURA_KEYS.length)];
}

// Tạo provider từ API Key
function createProvider(apiKey) {
    return new ethers.JsonRpcProvider(`https://polygon-mainnet.infura.io/v3/${apiKey}`);
}

// Kiểm tra API Key có bị rate limit không
async function checkApiKey(apiKey) {
    const provider = createProvider(apiKey);
    try {
        await provider.getBlockNumber();
        return provider; // API Key hoạt động tốt
    } catch (error) {
        console.warn(`🚨 API Key ${apiKey} bị lỗi hoặc rate limit.`);
        return null; // API Key bị lỗi
    }
}

// Chọn API Key hợp lệ
async function getValidProvider() {
    for (let i = 0; i < INFURA_KEYS.length; i++) {
        const apiKey = getRandomApiKey();
        const provider = await checkApiKey(apiKey);
        if (provider) {
            console.log(`✅ Dùng API Key: ${apiKey}`);
            return provider;
        }
    }
    throw new Error("❌ Không có API Key nào hoạt động!");
}

// Hàm lấy giá gas động từ mạng
async function getGasFees(provider) {
    const feeData = await provider.getFeeData();

    let baseFee = feeData.gasPrice || ethers.parseUnits("50", "gwei"); // Fallback 50 Gwei
    baseFee = ethers.toBigInt(baseFee);

    const maxFeePerGas = baseFee * BigInt(2);
    const maxPriorityFeePerGas = baseFee * BigInt(3) / BigInt(2);

    console.log(`⛽ Giá gas: ${ethers.formatUnits(baseFee, "gwei")} Gwei`);
    return { maxFeePerGas, maxPriorityFeePerGas };
}

// Hàm gửi MYST
async function sendMyst(toAddress, amount) {
    try {
        const provider = await getValidProvider();
        const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
        const contract = new ethers.Contract(MYST_CONTRACT, [
            "function transfer(address to, uint256 amount) public returns (bool)",
            "function balanceOf(address owner) view returns (uint256)"
        ], wallet);

        // Kiểm tra số dư MYST của ví
        const balance = await contract.balanceOf(wallet.address);
        console.log(`📌 Số dư MYST: ${ethers.formatUnits(balance, 18)}`);

        if (balance < ethers.parseUnits(amount.toString(), 18)) {
            console.log("⚠ Không đủ MYST để gửi!");
            return;
        }

        // Lấy phí gas động
        const { maxFeePerGas, maxPriorityFeePerGas } = await getGasFees(provider);

        // Gửi MYST
        const tx = await contract.transfer(toAddress, ethers.parseUnits(amount.toString(), 18), {
            maxFeePerGas,
            maxPriorityFeePerGas,
        });

        console.log(`⏳ Đang gửi ${amount} MYST tới ${toAddress}...`);
        console.log(`📝 Tx Hash: ${tx.hash}`);

        await tx.wait();
        console.log(`✅ Giao dịch hoàn tất! Hash: ${tx.hash}`);
    } catch (error) {
        console.error("❌ Lỗi:", error);
    }
}

// Nhận địa chỉ ví và số lượng MYST từ command line
const args = process.argv.slice(2);
if (args.length < 2) {
    console.log("Thiếu tham số. Cú pháp: node script.js <ví> <số lượng>");
    process.exit(1);
}

const recipient = args[0];
const amountToSend = parseFloat(args[1]);

sendMyst(recipient, amountToSend);
