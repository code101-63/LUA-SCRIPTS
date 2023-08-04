-- Import required libraries and modules
local CompaniesManager = exports['mega_companies']:api()
local json = require('json')

-- Constants
local discordWebhookUrl = "https://discord.com/api/webhooks/1126105864286244936/VHueRxRnNo9Hmd_E7_I2AQm1nyi91RgknQgcrys3HHJA0fJ48hIxr-tSwiASaBK3dTB5"

-- Helper Functions
local function table_contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

local function sendToDiscord(report)
    local payload = {
        embeds = {{
            title = "Company Tax Report",
            description = report,
            color = 3447003,
            footer = {
                text = "Report generated at: " .. os.date('%Y-%m-%d %H:%M:%S')
            }
        }}
    }
    PerformHttpRequest(discordWebhookUrl, function(err, text, headers)
        if err ~= 200 and err ~= 204 then 
            print("Error sending message to Discord: " .. err)
        end
    end, 'POST', json.encode(payload), {["Content-Type"] = 'application/json'})
end

local function calculateTax(company)
    local currentMoney = company.wallet
    if not currentMoney then
        print("Error: Company wallet not found for company ID: " .. company.id)
        return 0
    end

    -- Calculate tax amount and ensure it's positive
    local taxAmount = math.abs(currentMoney * Config.taxRate)
    return taxAmount
end

local function handleZeroNegativeBalances(company, taxAmount)
    local success, error = pcall(CompaniesManager.removeMoney, company.id, taxAmount)
    if not success then
        print("Error while handling zero or negative balance for company ID: " .. company.id .. ". Error: " .. tostring(error))
        return "Failed to tax company ID: " .. company.id .. ". Error: " .. tostring(error), 0
    end
    return nil, taxAmount
end

local function taxCompany(company)
    local lastTaxedTimestamp = company.lastTaxed or 0
    local currentTime = os.time()
    if currentTime - lastTaxedTimestamp < Config.taxSchedule * 3600 then
        return "Company " .. company.name .. " has already been taxed in this period.", 0
    end
    local taxAmount = calculateTax(company)
    local errorMessage, deductedTax = handleZeroNegativeBalances(company, taxAmount)
    if errorMessage then
        return errorMessage, 0
    end
    local updatedCompany = CompaniesManager.getCompany(company.id)
    return "Company: "..company.name.." Taxed successfully. Current balance: "..updatedCompany.wallet, deductedTax
end

local function notifyNegativeBalanceCompanies()
    for _, name in ipairs(Config.companies) do
        local company = CompaniesManager.getCompany(name)
        local daysInNegative = company.daysInNegative or 0
        if company and company.wallet < 0 and daysInNegative >= 30 then
            local message = "Company: " .. company.name .. " has been in negative balance for 30 days. Consider closure by the government."
            sendToDiscord(message)
        end
    end
end

local function taxAllCompanies()
    local report = ""
    local totalTaxAmount = 0
    for _, name in ipairs(Config.companies) do
        local company = CompaniesManager.getCompany(name)
        if company then
            local success, taxDetails, taxAmount = pcall(taxCompany, company)
            if success and taxDetails then
                report = report .. taxDetails .. "\n"
                totalTaxAmount = totalTaxAmount + (taxAmount or 0)
            end
        end
    end
    local taxCompany = CompaniesManager.getCompany(Config.taxCompany)
    if taxCompany then
        local success, error = pcall(CompaniesManager.addMoney, taxCompany.id, totalTaxAmount)
        if not success then
            print("Failed to transfer total tax to company ID: " .. taxCompany.id .. ". Error: " .. tostring(error))
        end
    else
        print("Tax company with ID: " .. Config.taxCompany .. " not found")
    end
    if #report > 0 then
        sendToDiscord(report)
    else
        sendToDiscord("No tax details to report.")
    end
end

-- Initialize the tax script
Citizen.CreateThread(function()
    while true do
        taxAllCompanies()
        notifyNegativeBalanceCompanies()
        Citizen.Wait(Config.taxSchedule * 3600000) -- Convert hours to milliseconds
    end
end)
