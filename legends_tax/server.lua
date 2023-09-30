local CompaniesManager = exports['mega_companies']:api()

-- ====================
-- UTILITY FUNCTIONS
-- ====================

local function log(message)
    print("[Legends Tax]: " .. message)
end

local function isCompanyForSale(companyName)
    return string.match(companyName, "^For Sale:") ~= nil
end

local function isExempted(companyID)
    for _, exemptedID in ipairs(Config.ExemptedCompanies) do
        if exemptedID == companyID then
            return true
        end
    end
    return false
end

-- ====================
-- DATABASE OPERATIONS
-- ====================

local function getAllCompanies()
    return exports.oxmysql:fetchSync('SELECT * FROM company', {})
end

local function wasTaxedToday(companyID)
    local result = exports.oxmysql:fetchSync('SELECT last_taxed_date FROM company_tax_history WHERE company_id = @company_id', {
        ['@company_id'] = companyID
    })
    return result and result[1] and result[1].last_taxed_date == os.date('%Y-%m-%d')
end

local function markAsTaxedToday(companyID)
    exports.oxmysql:executeSync('REPLACE INTO company_tax_history (company_id, last_taxed_date) VALUES (@company_id, @date)', {
        ['@company_id'] = companyID,
        ['@date'] = os.date('%Y-%m-%d')
    })
end

-- ====================
-- TAXATION FUNCTIONS
-- ====================

local function getTaxRateBasedOnSize(company)
    return Config.TaxRates[company.size]
end

local function applyTaxToCompany(company)
    local taxRate = getTaxRateBasedOnSize(company)
    local taxAmount = company.wallet * (taxRate/100)
    if company.wallet >= taxAmount then
        CompaniesManager.removeMoney(company.id, taxAmount)
        CompaniesManager.addMoney(Config.TaxCollectionCompanyID, taxAmount)
        markAsTaxedToday(company.id)
        return taxAmount
    else
        setCompanyForSale(company.id)
        return 0
    end
end

local function setCompanyForSale(companyID)
    local company = CompaniesManager.getCompany(companyID)
    local newName = 'For Sale: ' .. company.name
    
    -- Update the name directly in the database
    exports.oxmysql:execute('UPDATE company SET name = @name WHERE id = @id', {
        ['@name'] = newName,
        ['@id'] = companyID
    })

    CompaniesManager.setEmployees(companyID, {})
    CompaniesManager.setMoney(companyID, 0)
    
    -- Update owner and price directly in the database
    exports.oxmysql:execute('UPDATE company SET owner = NULL, price = 15000 WHERE id = ?', {companyID})

    -- Assuming the updateCompany method might synchronize other changes
    CompaniesManager.updateCompany(companyID)
end



local function notifyOwner(companyID, taxAmount)
    local company = CompaniesManager.getCompany(companyID)
    TriggerClientEvent("vorp:TipRight", company.owner, 'Tax of $' .. taxAmount .. ' has been deducted from ' .. company.name, 5000)
end

-- ====================
-- MAIN TAX FUNCTION
-- ====================

function applyDailyTax()
    log("Starting daily tax application...")

    local allCompanies = getAllCompanies()
    local totalAmountTaxed = 0

    if not allCompanies or #allCompanies == 0 then
        log("No companies available for taxation.")
        return
    end

    for _, company in ipairs(allCompanies) do
        if isCompanyForSale(company.name) or company.wallet < 10 or isExempted(company.id) or wasTaxedToday(company.id) then
            goto continue
        end
        totalAmountTaxed = totalAmountTaxed + applyTaxToCompany(company)
        ::continue::
    end

    -- Updating government's treasury
    local gov_balance = exports.oxmysql:fetchSync('SELECT wallet FROM company WHERE id = ?', {Config.TaxCollectionCompanyID})[1].wallet
    local new_gov_balance = gov_balance + totalAmountTaxed
    exports.oxmysql:execute('UPDATE company SET wallet = ? WHERE id = ?', {new_gov_balance, Config.TaxCollectionCompanyID})

    log("Tax application completed. Total amount taxed: $" .. totalAmountTaxed)
end

-- ====================
-- SCHEDULER
-- ====================

Citizen.CreateThread(function()
    while true do
        log("Waiting 24 hours for the next tax cycle...")
        Citizen.Wait(86400000)
        applyDailyTax()
    end
end)

-- ====================
-- DISCORD
-- ====================

function SendTaxReportToDiscord(totalAmountTaxed)
    local webhookURL = Config.DiscordWebhookURL
    local smallCompanies = CountCompaniesBySize('small')
    local mediumCompanies = CountCompaniesBySize('medium')
    local largeCompanies = CountCompaniesBySize('large')
    local totalCompaniesTaxed = smallCompanies + mediumCompanies + largeCompanies
    local exemptCompanies = #Config.ExemptedCompanies

    print("Debugging Tax Report:")
    print("Total Amount Taxed: $" .. totalAmountTaxed)
    print("Small Companies: " .. smallCompanies)
    print("Medium Companies: " .. mediumCompanies)
    print("Large Companies: " .. largeCompanies)
    print("Webhook URL: " .. webhookURL)

    local messageContent = string.format([[
    Legends Tax Report

    Date and Time: %s
    Number of Small Companies: %d
    Number of Medium Companies: %d
    Number of Large Companies: %d
    Total Companies Taxed: %d
    Number of Exempt Companies: %d
    Total Amount Taxed: $%0.2f
    ]], os.date('%Y-%m-%d %H:%M:%S'), smallCompanies, mediumCompanies, largeCompanies, totalCompaniesTaxed, exemptCompanies, totalAmountTaxed)

    local payload = {
        ['content'] = messageContent
    }

    PerformHttpRequest(webhookURL, function(err, text, headers)
        print("Discord Response Error Code: " .. err)
        print("Discord Response Text: " .. text)
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end