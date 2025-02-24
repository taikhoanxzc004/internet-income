const { chromium } = require('playwright');
const { execSync } = require('child_process');

// Lấy IP từ tham số dòng lệnh
const ip = process.argv[2];
if (!ip) {
    console.error("Vui lòng cung cấp IP khi chạy script: node playwright_automation.spec.js <IP>");
    process.exit(1);
}

function randomDelay(min = 1000, max = 3000) {
    return new Promise(resolve => setTimeout(resolve, Math.floor(Math.random() * (max - min + 1)) + min));
}

async function waitForElement(page, selector, timeout = 60000, retries = 3) {
    let attempts = 0;
    while (attempts < retries) {
        try {
            await page.waitForSelector(selector, { timeout });
            return await page.$(selector);
        } catch (error) {
            attempts++;
            console.log(`Attempt ${attempts} failed. Retrying...`);
            if (attempts >= retries) {
                throw new Error(`Element ${selector} not found after ${retries} attempts and ${timeout}ms timeout.`);
            }
        }
    }
}

async function navigateAndRefresh(page, url) {
    try {
        await page.goto(url, { waitUntil: 'load', timeout: 60000 });
    } catch (error) {
        console.log('Page load failed, retrying...');
        await page.reload({ waitUntil: 'load', timeout: 60000 });
    }
}

(async () => {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext();
    const page = await context.newPage();
    
    console.log(`Navigating to: http://${ip}:4449/#/quick-onboarding`);
    await navigateAndRefresh(page, `http://${ip}:4449/#/quick-onboarding`);

    await waitForElement(page, 'a:has-text("Start here")');
    await page.getByRole('link', { name: 'Start here' }).click();
    await randomDelay();
    
    await waitForElement(page, 'input[type="password"]');
    await page.getByRole('textbox').first().fill('mA7Q:[CpUZK8j%2!');
    await randomDelay();
    await page.getByRole('textbox').nth(1).fill('mA7Q:[CpUZK8j%2!');
    await randomDelay();
    await page.locator('input[type="text"]').fill('jTIvUBWag74pKNV9soh09EF3LyGkk0uLabkTX1tO');
    await randomDelay();
    await page.getByLabel('').check();
    await randomDelay();
    await page.getByRole('button', { name: 'CONFIRM' }).click();
    await randomDelay();

    await waitForElement(page, 'button:has-text("Deposit")');
    const depositButton = await page.$('button:has-text("Deposit")');
    const depositButtonText = await depositButton.textContent();
    const depositAmountMatch = depositButtonText.match(/\d+\.\d+/);
    if (!depositAmountMatch) {
        throw new Error("Không tìm thấy số MYST trên nút Deposit!");
    }
    const depositAmount = depositAmountMatch[0];
    console.log('Deposit amount:', depositAmount, 'MYST');

    await page.getByRole('button', { name: `Deposit ${depositAmount} MYST token` }).click();
    await randomDelay();
    await page.locator('circle').click();
    await randomDelay();

    console.log('Fetching Deposit Wallet...');
    const walletAddress = await page.textContent('text=0x');
    const walletMatch = walletAddress.match(/0x[a-fA-F0-9]{40}/);
    if (!walletMatch) {
        throw new Error("Không tìm thấy địa chỉ ví hợp lệ trên trang web!");
    }
    const depositWallet = walletMatch[0];
    console.log('Deposit Wallet:', depositWallet);

    console.log('Sending MYST via MetaMask...');
    execSync(`bash -c 'source ~/.bashrc && node ${__dirname}/metamask_auto_send.js ${depositWallet} ${depositAmount}'`, { stdio: 'inherit' });

    console.log('Waiting for MetaMask transaction to complete...');
    await page.waitForTimeout(60000);

    while (true) {
        const nextButton = await page.$('button:has-text("Next")');

        if (nextButton) {
            await nextButton.click();
            await randomDelay();
            console.log('Clicked NEXT button!');
            break;
        } else {
            console.log("Next button not found, refreshing page...");
            await page.reload({ waitUntil: 'load', timeout: 60000 });

            console.log("Waiting for Deposit button to appear...");
            await waitForElement(page, 'button:has-text("Deposit")');

            const depositButton = await page.$('button:has-text("Deposit")');
            if (depositButton) {
                await depositButton.click();
                await randomDelay();
                await page.locator('circle').click();
                await randomDelay();
                console.log("Re-clicked Deposit button after refresh.");
            }
            await page.waitForTimeout(60000);
        }
    }

    await waitForElement(page, 'input[placeholder="0x..."]');
    await page.fill('input[placeholder="0x..."]', '0xa0cc793446d04a6893c7cb2c4a437765c1d97330');
    await randomDelay();
    await page.getByRole('button', { name: 'Finish' }).click();
    await waitForElement(page, 'text=Node');
    await randomDelay();
    await page.waitForTimeout(3000);
    await page.goto(`http://${ip}:4449/#/node-claim?mmnApiKey=jTIvUBWag74pKNV9soh09EF3LyGkk0uLabkTX1tO`, { waitUntil: 'load' });
    await waitForElement(page, 'text=Node');
    await page.waitForTimeout(3000);
    console.log('Node activation process completed successfully.');
    
    await browser.close();
})();
