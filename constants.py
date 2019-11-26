# this dictionary has the FRED code as key and a tuple as the values
# the values are the long description followed by a short variable name
NIPA_VARS = {
    'CON5201A027NBEA':
        ('Contributions for government social insurance: Employee and' +
         ' self-employed contributions: Federal social insurance ' +
         'funds: Old-age, survivors, disability, and hospital ' +
         'insurance: Self-employed', 'si_contrib'),
    'PCE': ('Personal Consumption Expenditures', 'pce'),
    'G170091A027NBEA': (
        'Government consumption expenditures: Education', 'educ_exp'),
    'PCEPI': (
        'Personal Consumption Expenditures: Chain-type Price Index',
        'pce_pi'),
    'PINCOME': ('Personal Income', 'income'),
    'A033RC1A027NBEA': ('National income: Compensation of employees',
                        'emp_comp'),
    'A4102C1A027NBEA': (
        'Gross domestic income: Compensation of employees, paid: ' +
        'Wages and salaries', 'wages'),
    'A132RC1': ('Compensation of Employees, Received: Wage and Salary' +
                'Disbursements: Private Industries', 'wages_private'),
    'B202RC1Q027SBEA': (
        'Compensation of employees: Wages and salaries: Government',
        'wages_govt'),
    'A038RC1Q027SBEA': (
        'Compensation of employees: Supplements to wages and salaries',
        'wage_supp'),
    'L306051A027NBEA': (
        'Supplements to wages and salaries: Pension, profit-sharing, ' +
        'and other retirement benefit plans: Old-age, survivors, and ' +
        'disability insurance', 'retire_comp'),
    'B039RC1M027SBEA': (
        'Compensation of employees: Supplements to wages and ' +
        'salaries: Employer contributions for government social ' +
        'insurance', 'comp_si'),
    'A1645C1A027NBEA': (
        'National income: Domestic business: Noncorporate business: ' +
        'Sole proprietorships and partnerships: Proprietors income ' +
        'with IVA and CCAdj', 'ncorp_bus_inc'),
    'BOGZ1FA136111103Q': (
        "Farm business; proprietors' income with IVA and CCAdj, Flow",
        'farm_inc'),
    'A1646C1A027NBEA': (
        "National income: Domestic business: Noncorporate business: " +
        "Sole proprietorships and partnerships: Proprietors' income " +
        "with IVA and CCAdj: Nonfarm", 'ncorp_bus_inc_no_farm'),
    'RENTIN': (
        'Rental Income of Persons with Capital Consumption Adjustment',
        'rent'),
    'PIROA': ('Personal Income Receipts on Assets', 'asset_income'),
    'PII': (
        'Personal Income Receipts on Assets: Personal Interest Income',
        'interest_income'),
    'B703RC1Q027SBEA': (
        'Personal income receipts on assets: Personal dividend income',
        'dividend_income'),
    'PCTR': ('Personal Current Transfer Receipts', 'transfers'),
    'A063RC1Q027SBEA': (
        'Personal current transfer receipts: Government social ' +
        'benefits to persons', 'social_benefits'),
    'W823RC1Q027SBEA': (
        'Personal current transfer receipts: Government social ' +
        'benefits to persons: Social security', 'social_security'),
    'W824RC1A027NBEA': (
        'Personal current transfer receipts: Government social ' +
        'benefits to persons: Medicare', 'medicare'),
    'W729RC1Q027SBEA': (
        'Personal current transfer receipts: Government social ' +
        'benefits to persons: Medicaid', 'medicaid'),
    'W825RC1Q027SBEA': (
        'Personal current transfer receipts: Government social ' +
        'benefits to persons: Unemployment insurance', 'unemp_ins'),
    'W826RC1Q027SBEA': (
        "Personal current transfer receipts: Government social " +
        "benefits to persons: Veterans' benefits", 'veterns_benefits'),
    'W827RC1Q027SBEA': (
        'Personal current transfer receipts: Government social ' +
        'benefits to persons: Other', 'social_benefits_other'),
    'B931RC1Q027SBEA': (
        'Personal current transfer receipts: Other current transfer ' +
        'receipts, from business (net)', 'business_transfers'),
}

FA_VARS = {
    'BOGZ1FL153064476Q': (
        'Households and nonprofit organizations; directly and ' +
        'indirectly held corporate equities as a percentage of total' +
        ' assets, Level, Quarterly, Not Seasonally Adjusted',
        'corp_equity_pct_total_assets'),
    'BOGZ1FL153064486Q': (
        'Households and nonprofit organizations; directly and ' +
        'indirectly held corporate equities as a percentage of total ' +
        'financial assets, Level, Quarterly, Not Seasonally Adjusted',
        'corp_equity_pct_fin_assets'),
    'BOGZ1FL153099475Q': (
        'Households and nonprofit organizations; other financial ' +
        'assets (B.101.e), Level, Quarterly, Not Seasonally Adjusted',
        'other_fin_assets'),
    'BOGZ1LM153064175Q': (
        'Households and nonprofit organizations; indirectly held ' +
        'corporate equities; asset, Market value levels, Quarterly, ' +
        'Not Seasonally Adjusted', 'corp_equity_indirect'),
    'BOGZ1LM153064475Q': (
        'Households and nonprofit organizations; directly and ' +
        'indirectly held corporate equities; asset, Market value ' +
        'levels, Quarterly, Not Seasonally Adjusted', 'corp_equity'),
    'BOGZ1LM223064213Q': (
        'State and local government employee retirement funds; ' +
        'corporate equities held indirectly through mutual funds; ' +
        'asset, Revaluation, Quarterly, Not Seasonally Adjusted',
        'stae_local_gov_corp_equity_mutual_fund'),
    'BOGZ1LM343064125Q': (
        'Federal government retirement funds; corporate equities ' +
        'held by Thrift Savings Plan; asset, Market value levels, ' +
        'Quarterly, Not Seasonally Adjusted', 'corp_equity_TSP'),
    'BOGZ1LM543064153Q': (
        'Life insurance companies; corporate equities held directly ' +
        'and indirectly through mutual funds; asset, Market value ' +
        'levels, Quarterly, Not Seasonally Adjusted',
        'life_ins_corp_equity_mutual_fund'),
    'BOGZ1LM573064175Q': (
        'Private defined contribution pension funds; corporate ' +
        'equities held directly and indirectly through mutual funds; ' +
        'asset, Market value levels, Quarterly, Not Seasonally ' +
        'Adjusted', 'priv_db_corp_equity_mutual_fund'),
    'BOGZ1LM653064155Q': (
        'Mutual funds; corporate equities indirectly held by ' +
        'households; asset, Market value levels, Quarterly, Not ' +
        'Seasonally Adjusted', 'corp_equity_mutual_fund'),
    'DABSHNO': (
        'Households and nonprofit organizations; total currency and ' +
        'deposits including money market fund shares; asset, Level, ' +
        'Quarterly, Not Seasonally Adjusted', 'hh_money'),
    'HNOCEA': (
        'Households and nonprofit organizations; corporate equities; ' +
        'asset, Market value levels, Quarterly, Not Seasonally ' +
        'Adjusted', 'corp_equity'),
    'HNODSAQ027S': (
        'Households and nonprofit organizations; debt securities; ' +
        'asset, Level, Quarterly, Not Seasonally Adjusted', 'debt'),
    'HNOLA': (
        'Households and nonprofit organizations; loans; asset, Level,' +
        ' Quarterly, Not Seasonally Adjusted', 'loans'),
    'TABSHNO': (
        'Households and nonprofit organizations; total assets, Level,' +
        ' Quarterly, Not Seasonally Adjusted', 'total_assets'),
    'TFAABSHNO': (
        'Households and nonprofit organizations; total financial ' +
        'assets, Level, Quarterly, Not Seasonally Adjusted',
        'total_fin_assets'),
    'TLBSHNO': (
        'Households and nonprofit organizations; total liabilities, ' +
        'Level, Quarterly, Not Seasonally Adjusted',
        'total_liabilities'),
    'TNWBSHNO': (
        'Households and nonprofit organizations; net worth, Level, '
        'Quarterly, Not Seasonally Adjusted', 'net_worth'),
    'TTABSHNO': (
        'Households and nonprofit organizations; nonfinancial assets,' +
        ' Level, Quarterly, Not Seasonally Adjusted',
        'total_nonfin_assets')}
