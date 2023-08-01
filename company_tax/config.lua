Config = {}

-- The tax rate to be applied to companies (expressed as a decimal)
Config.taxRate = 0.10

-- The schedule for tax application (in hours)
Config.taxSchedule = 12

-- The company to which all tax money is transferred
Config.taxCompany = "gov_treasury"

-- A list of companies exempted from tax (list the company names here)
Config.exemptCompanies = {}

-- A list of all company names in the server
Config.companies = {
    "val_horsetrainer", "val_saloon", "val_blacksmith", "val_blacksmith",
    "tw_horsetrainer", "tw_saloon", "tl_saloon", "straw_horsetrainer",
    "straw_blacksmith", "std_horsetrainer", "std_blacksmith", "rh_horsetrainer",
    "rh_saloon", "rs_horsetrainer", "rs_saloon", "rs_ranch", "rs_blacksmith",
    "std_tavern", "bw_horsetrainer", "bw_saloon", "bw_gunsmith",
    "bw_blacksmith", "std_saloon_a", "arma_saloon", "arma_blacksmith",
    "arma_bakery", "ann_saloon", "ann_blacksmith"
}
