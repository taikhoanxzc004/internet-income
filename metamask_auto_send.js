require("dotenv").config();
const { ethers } = require("ethers");

// Lấy thông tin từ .env
const INFURA_URL = process.env.INFURA_URL;
const MYST_CONTRACT = "0x1379E8886A944d2D9d440b3d88DF536Aea08d9F3";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Kết nối với mạng Polygon qua Infura
const provider = new ethers.JsonRpcProvider(INFURA_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// ABI của hợp đồng MYST
const MYST_ABI = [
    "function transfer(address to, uint256 amount) public returns (bool)",
    "function balanceOf(address owner) view returns (uint256)",
];

// Hàm lấy giá gas động từ mạng
async function getGasFees() {
    const feeData = await provider.getFeeData();
    
    // Kiểm tra nếu gasPrice bị null
    let baseFee = feeData.gasPrice;
    if (!baseFee) {
        console.warn("⚠ Không lấy được giá gas từ mạng, đặt mặc định 50 Gwei.");
        baseFee = ethers.parseUnits("50", "gwei"); // Fallback 50 Gwei
    }

    baseFee = ethers.toBigInt(baseFee); // Chuyển thành BigInt

    // Tính toán phí gas để ưu tiên giao dịch
    const maxFeePerGas = baseFee * BigInt(2); // Đặt cao hơn gấp đôi
    const maxPriorityFeePerGas = baseFee * BigInt(3) / BigInt(2); // Ưu tiên cho thợ đào

    console.log(`⛽ Giá gas hiện tại: ${ethers.formatUnits(baseFee, "gwei")} Gwei`);
    console.log(`🚀 Max Fee Per Gas: ${ethers.formatUnits(maxFeePerGas, "gwei")} Gwei`);
    console.log(`🔥 Max Priority Fee Per Gas: ${ethers.formatUnits(maxPriorityFeePerGas, "gwei")} Gwei`);

    return { maxFeePerGas, maxPriorityFeePerGas };
}

// Hàm gửi MYST
async function sendMyst(toAddress, amount) {
    try {
        const contract = new ethers.Contract(MYST_CONTRACT, MYST_ABI, wallet);

        // Kiểm tra số dư MYST của ví
        const balance = await contract.balanceOf(wallet.address);
        console.log(`📌 Số dư MYST: ${ethers.formatUnits(balance, 18)}`);

        if (balance < ethers.parseUnits(amount.toString(), 18)) {
            console.log("⚠ Không đủ MYST để gửi!");
            return;
        }

        // Lấy phí gas động
        const { maxFeePerGas, maxPriorityFeePerGas } = await getGasFees();

        // Gửi MYST với phí gas tối ưu
        const tx = await contract.transfer(toAddress, ethers.parseUnits(amount.toString(), 18), {
            maxFeePerGas,
            maxPriorityFeePerGas,
        });

        console.log(`⏳ Đang gửi ${amount} MYST tới ${toAddress}...`);
        console.log(`📝 Tx Hash: ${tx.hash}`);

        // Chờ xác nhận giao dịch
        await tx.wait();
        console.log(`✅ Giao dịch hoàn tất! Hash: ${tx.hash}`);
    } catch (error) {
        console.error("❌ Lỗi:", error);
    }
}

// Nhận địa chỉ ví và số lượng MYST từ command line
const args = process.argv.slice(2);
if (args.length < 2) {
    console.log("Thiếu tham số. Cú pháp: node metamask_auto_send.js <ví> <số lượng>");
    process.exit(1);
}

const recipient = args[0];
const amountToSend = parseFloat(args[1]);

sendMyst(recipient, amountToSend);
