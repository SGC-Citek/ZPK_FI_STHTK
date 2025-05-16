@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sổ chi tiết tài khoản - RAW'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_FI_STHTK_RAW
  with parameters
    P_Ledger       : fins_ledger,
    P_IncRev       : zde_boolean,
    P_CurrencyType : zde_curr_type
  as select from I_GLAccountLineItem
    inner join   I_GLAccountLineItem as OffsettingLine on  I_GLAccountLineItem.SourceLedger       = OffsettingLine.SourceLedger
                                                       and I_GLAccountLineItem.CompanyCode        = OffsettingLine.CompanyCode
                                                       and I_GLAccountLineItem.FiscalYear         = OffsettingLine.FiscalYear
                                                       and I_GLAccountLineItem.AccountingDocument = OffsettingLine.AccountingDocument
                                                       and I_GLAccountLineItem.LedgerGLLineItem   = OffsettingLine.OffsettingLedgerGLLineItem
                                                       and I_GLAccountLineItem.Ledger             = OffsettingLine.Ledger
{
  key I_GLAccountLineItem.CompanyCode,
  key I_GLAccountLineItem.AccountingDocument,
  key I_GLAccountLineItem.LedgerGLLineItem as LedgerGLLineItemRaw,
  key I_GLAccountLineItem.FiscalYear,
      I_GLAccountLineItem.LedgerGLLineItem,
      I_GLAccountLineItem.FiscalPeriod,
      I_GLAccountLineItem.PostingDate,
      I_GLAccountLineItem.DocumentDate,
      I_GLAccountLineItem.GLAccount,
      OffsettingLine.GLAccount             as OffsettingAccount,
      case when $parameters.P_CurrencyType = 'I'
            then I_GLAccountLineItem.CompanyCodeCurrency
            else I_GLAccountLineItem.TransactionCurrency
      end                                  as TransactionCurrency,
      I_GLAccountLineItem.CompanyCodeCurrency,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when $parameters.P_CurrencyType = 'I'
            then I_GLAccountLineItem.DebitAmountInCoCodeCrcy
            else I_GLAccountLineItem.DebitAmountInTransCrcy
      end                                  as DebitAmountInTransCrcy,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      I_GLAccountLineItem.DebitAmountInCoCodeCrcy,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when $parameters.P_CurrencyType = 'I'
            then I_GLAccountLineItem.CreditAmountInCoCodeCrcy
            else I_GLAccountLineItem.CreditAmountInTransCrcy
      end                                  as CreditAmountInTransCrcy,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      I_GLAccountLineItem.CreditAmountInCoCodeCrcy
}
where
          I_GLAccountLineItem.Ledger              = $parameters.P_Ledger
  and     I_GLAccountLineItem.SourceLedger        = $parameters.P_Ledger
  and(
    (
          $parameters.P_IncRev                    =  'Y'
    )
    or(
          $parameters.P_IncRev                    =  'N'
      and I_GLAccountLineItem.IsReversal          is initial
      and I_GLAccountLineItem.IsReversed          is initial
    )
  )
  and(
    (
          $parameters.P_CurrencyType              =  'I'
    )
    or(
          $parameters.P_CurrencyType              =  'E'
      and I_GLAccountLineItem.TransactionCurrency <> I_GLAccountLineItem.CompanyCodeCurrency
    )
  )
//union select from I_GLAccountLineItem
//  inner join      I_GLAccountLineItem as OffsettingLine on  I_GLAccountLineItem.SourceLedger       = OffsettingLine.SourceLedger
//                                                        and I_GLAccountLineItem.CompanyCode        = OffsettingLine.CompanyCode
//                                                        and I_GLAccountLineItem.FiscalYear         = OffsettingLine.FiscalYear
//                                                        and I_GLAccountLineItem.AccountingDocument = OffsettingLine.AccountingDocument
//                                                        and I_GLAccountLineItem.OffsettingAccount  = OffsettingLine.GLAccount
//                                                        and I_GLAccountLineItem.Ledger             = OffsettingLine.Ledger
//{
//  key I_GLAccountLineItem.CompanyCode,
//  key I_GLAccountLineItem.AccountingDocument,
//  key I_GLAccountLineItem.LedgerGLLineItem as LedgerGLLineItemRaw,
//  key I_GLAccountLineItem.FiscalYear,
//      I_GLAccountLineItem.LedgerGLLineItem,
//      I_GLAccountLineItem.FiscalPeriod,
//      I_GLAccountLineItem.PostingDate,
//      I_GLAccountLineItem.DocumentDate,
//      I_GLAccountLineItem.GLAccount,
//      OffsettingLine.GLAccount             as OffsettingAccount,
//      case when $parameters.P_CurrencyType = 'I'
//            then I_GLAccountLineItem.CompanyCodeCurrency
//            else I_GLAccountLineItem.TransactionCurrency
//      end                                  as TransactionCurrency,
//      I_GLAccountLineItem.CompanyCodeCurrency,
//      case when $parameters.P_CurrencyType = 'I'
//            then I_GLAccountLineItem.DebitAmountInCoCodeCrcy
//            else I_GLAccountLineItem.DebitAmountInTransCrcy
//      end                                  as DebitAmountInTransCrcy,
//      I_GLAccountLineItem.DebitAmountInCoCodeCrcy,
//      case when $parameters.P_CurrencyType = 'I'
//            then I_GLAccountLineItem.CreditAmountInCoCodeCrcy
//            else I_GLAccountLineItem.CreditAmountInTransCrcy
//      end                                  as CreditAmountInTransCrcy,
//      I_GLAccountLineItem.CreditAmountInCoCodeCrcy
//}
//where
//          I_GLAccountLineItem.Ledger              = $parameters.P_Ledger
//  and     I_GLAccountLineItem.SourceLedger        = $parameters.P_Ledger
//  and(
//    (
//          $parameters.P_IncRev                    =  'Y'
//    )
//    or(
//          $parameters.P_IncRev                    =  'N'
//      and I_GLAccountLineItem.IsReversal          is initial
//      and I_GLAccountLineItem.IsReversed          is initial
//    )
//  )
//  and(
//    (
//          $parameters.P_CurrencyType              =  'I'
//    )
//    or(
//          $parameters.P_CurrencyType              =  'E'
//      and I_GLAccountLineItem.TransactionCurrency <> I_GLAccountLineItem.CompanyCodeCurrency
//    )
//  )
//union select from I_GLAccountLineItem
//  inner join      I_GLAccountLineItem as OffsettingLine on  I_GLAccountLineItem.SourceLedger       = OffsettingLine.SourceLedger
//                                                        and I_GLAccountLineItem.CompanyCode        = OffsettingLine.CompanyCode
//                                                        and I_GLAccountLineItem.FiscalYear         = OffsettingLine.FiscalYear
//                                                        and I_GLAccountLineItem.AccountingDocument = OffsettingLine.AccountingDocument
//                                                        and I_GLAccountLineItem.LedgerGLLineItem   = OffsettingLine.OffsettingAccount
//                                                        and I_GLAccountLineItem.Ledger             = OffsettingLine.Ledger
//{
//  key I_GLAccountLineItem.CompanyCode,
//  key I_GLAccountLineItem.AccountingDocument,
//  key I_GLAccountLineItem.LedgerGLLineItem as LedgerGLLineItemRaw,
//  key I_GLAccountLineItem.FiscalYear,
//      I_GLAccountLineItem.LedgerGLLineItem,
//      I_GLAccountLineItem.FiscalPeriod,
//      I_GLAccountLineItem.PostingDate,
//      I_GLAccountLineItem.DocumentDate,
//      I_GLAccountLineItem.GLAccount,
//      OffsettingLine.GLAccount             as OffsettingAccount,
//      case when $parameters.P_CurrencyType = 'I'
//            then I_GLAccountLineItem.CompanyCodeCurrency
//            else I_GLAccountLineItem.TransactionCurrency
//      end                                  as TransactionCurrency,
//      I_GLAccountLineItem.CompanyCodeCurrency,
//      case when $parameters.P_CurrencyType = 'I'
//            then I_GLAccountLineItem.DebitAmountInCoCodeCrcy
//            else I_GLAccountLineItem.DebitAmountInTransCrcy
//      end                                  as DebitAmountInTransCrcy,
//      I_GLAccountLineItem.DebitAmountInCoCodeCrcy,
//      case when $parameters.P_CurrencyType = 'I'
//            then I_GLAccountLineItem.CreditAmountInCoCodeCrcy
//            else I_GLAccountLineItem.CreditAmountInTransCrcy
//      end                                  as CreditAmountInTransCrcy,
//      I_GLAccountLineItem.CreditAmountInCoCodeCrcy
//}
//where
//          I_GLAccountLineItem.Ledger              = $parameters.P_Ledger
//  and     I_GLAccountLineItem.SourceLedger        = $parameters.P_Ledger
//  and(
//    (
//          $parameters.P_IncRev                    =  'Y'
//    )
//    or(
//          $parameters.P_IncRev                    =  'N'
//      and I_GLAccountLineItem.IsReversal          is initial
//      and I_GLAccountLineItem.IsReversed          is initial
//    )
//  )
//  and(
//    (
//          $parameters.P_CurrencyType              =  'I'
//    )
//    or(
//          $parameters.P_CurrencyType              =  'E'
//      and I_GLAccountLineItem.TransactionCurrency <> I_GLAccountLineItem.CompanyCodeCurrency
//    )
//  )
