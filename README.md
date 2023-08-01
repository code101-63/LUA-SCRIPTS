Company Taxation Script
A server-side script designed to handle the taxation of companies with mega_companies. This script calculates and collects taxes, handles special cases like zero or negative balances, sends tax reports to Discord, and more.

Features

1. Company Taxation System

Tax Calculation
- Calculates the tax for each company based on a predefined tax rate.
Tax Collection
- Collects the tax from all companies, considering exemptions.
- Zero or Negative Balance Handling
- Special handling for companies with zero or negative balances.
Tax Transfer
- Transfers the total collected tax to a specified tax collection company (e.g., Government Treasury).

2. Discord Notification

Tax Report
- Sends a detailed tax report to a Discord channel via a webhook.
Negative Balance Alert
- Sends an alert to Discord if a company has been in a negative balance for a specified number of days, suggesting possible closure.
Configurable Settings
- Tax Rate
- Exempt Companies
- Tax Schedule (in hours)
- Company List

4. Error Handling

Error Reporting
- Includes error handling and reporting for various possible issues.
- Safe Execution: Utilizes pcall for safe execution of potentially problematic code sections.

Utilizes External Libraries and Modules
- Interacts with an external module, mega_companies, for fetching and modifying company details.
- Uses a JSON library to encode data for Discord notifications.

Continuous Operation
- Runs in a continuous loop via a Citizen thread, regularly executing the tax collection and notification functionalities according to the configured schedule.
