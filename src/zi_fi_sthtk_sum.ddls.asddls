@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sổ chi tiết tài khoản - SUM'
define view entity ZI_FI_STHTK_SUM
  with parameters
    P_Ledger       : fins_ledger,
    P_IncRev       : zde_boolean,
    P_CurrencyType : zde_curr_type
  as select from    ZI_FI_STHTK_RAW (   P_Ledger        : $parameters.P_Ledger,
                                        P_IncRev        : $parameters.P_IncRev,
                                        P_CurrencyType  : $parameters.P_CurrencyType ) as data
    left outer join I_GlAccountTextInCompanycode                                       as GLAccountText     on  data.GLAccount         = GLAccountText.GLAccount
                                                                                                            and data.CompanyCode       = GLAccountText.CompanyCode
                                                                                                            and GLAccountText.Language = $session.system_language
    left outer join I_GlAccountTextInCompanycode                                       as OffsettingAccText on  data.OffsettingAccount     = OffsettingAccText.GLAccount
                                                                                                            and data.CompanyCode           = OffsettingAccText.CompanyCode
                                                                                                            and OffsettingAccText.Language = $session.system_language
{
  key data.CompanyCode,
  key data.FiscalYear,
  key data.GLAccount,
  key data.OffsettingAccount,
      GLAccountText.GLAccountLongName,
      OffsettingAccText.GLAccountLongName  as OffsettingAccountLongName,
      data.FiscalPeriod,
      data.PostingDate,
      data.DocumentDate,
      data.TransactionCurrency,
      data.CompanyCodeCurrency,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( data.DebitAmountInTransCrcy )   as DebitAmountInTransCrcy,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      sum( data.DebitAmountInCoCodeCrcy )  as DebitAmountInCoCodeCrcy,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      sum( data.CreditAmountInTransCrcy )  as CreditAmountInTransCrcy,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      sum( data.CreditAmountInCoCodeCrcy ) as CreditAmountInCoCodeCrcy
}
group by
  data.CompanyCode,
  data.FiscalYear,
  data.GLAccount,
  data.OffsettingAccount,
  GLAccountText.GLAccountLongName,
  OffsettingAccText.GLAccountLongName,
  data.FiscalPeriod,
  data.PostingDate,
  data.DocumentDate,
  data.TransactionCurrency,
  data.CompanyCodeCurrency
