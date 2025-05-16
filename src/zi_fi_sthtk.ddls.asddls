@EndUserText.label: 'Sổ chi tiết tài khoản'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_FI_STHTK'
@UI: {
    headerInfo: {
        typeName: 'Sổ chi tiết tài khoản',
        typeNamePlural: 'Sổ chi tiết tài khoản',
        title: {
            type: #STANDARD,
            label: 'Sổ chi tiết tài khoản'
        }
    }
}
define custom entity ZI_FI_STHTK
  with parameters
    @Consumption:{
    valueHelpDefinition: [{ entity: {
    name: 'ZI_LedgerVH',
    element: 'Ledger'
    } }]
    }
    @EndUserText.label: 'Ledger'
    P_Ledger    : fins_ledger,
    // tham số 7
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_SUBLEVEL_VH',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Display Subtotal'
    P_SubLevel  : zde_sublevel,
    // tham số 9
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_YES_NO_VH',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Include Reversed Documents'
    P_IncRev    : zde_yes_no,
    @Consumption.valueHelpDefinition: [{ entity: {
    name: 'ZFI_I_YES_NO_VH',
    element: 'value_low'
    } }]
    @EndUserText.label: 'Ngày giờ in'
    P_PrintDate : zde_yes_no
{
  key TransactionCurrency       : waers;
      // tham số 1
      @Consumption              : {
      valueHelpDefinition       : [ {
      entity                    :{
      name                      :'I_CompanyCodeStdVH',
      element                   :'CompanyCode' }
      }],
      filter                    :{ mandatory:true } }
      @UI                       : {
      selectionField            : [ { position: 10 } ] }
      @EndUserText.label        : 'CompanyCode'
  key CompanyCode               : bukrs;
      // tham số 5
      @Consumption              : {
//      filter                    : { mandatory: true },
      valueHelpDefinition       : [ {
      entity                    : { name: 'ZI_FI_STHTK_ACC_VH', element: 'Account' },
      additionalBinding         : [ 
      {parameter                : 'SubLevel', localParameter: 'P_SubLevel', usage: #FILTER_AND_RESULT}
      ]
      }]
      }

      @UI                       : {
      selectionField            : [ { position: 50 } ] }
      @EndUserText.label        : 'G/L Accounts'
  key GLAccount                 : zde_racct;
      // tham số 4
      @Consumption.filter       : {
      selectionType             : #SINGLE,
      mandatory                 :true
      }
      @UI                       : {
      selectionField            : [ { position: 40 } ] }
      @EndUserText.label        : 'Fiscal Year'
  key FiscalYear                : fis_gjahr_no_conv;
  key IsTotal                   : abap.char(1);
  key IsSubTotal                : abap.char(1);
  key NoTitle                   : abap.numc(1);
      // tham số 8
      @Consumption              : {
      valueHelpDefinition       : [ { entity :
      {
      name                      :'I_GLAccountStdVH',
      element                   :'GLAccount' }
      } ]
      }
      @UI                       : {
      selectionField            : [ { position: 80 } ] }
      @EndUserText.label        : 'Offsetting Account'
  key OffsettingAccount         : zde_racct;
      // tham số 3
      @Consumption.filter       : {
      selectionType             : #INTERVAL
      }
      @UI                       : {
      selectionField            : [ { position: 30 } ] }
      @EndUserText.label        : 'Period'
      FiscalPeriod              : fins_fiscalperiod;
      // tham số 2
      @Consumption.filter       : {
      selectionType             : #INTERVAL,
      mandatory                 :true
      }
      @UI                       : {
      selectionField            : [ { position: 20 } ] }
      @EndUserText.label        : 'Posting Date'
      PostingDate               : fis_budat;
      CompanyCodeCurrency       : waers;
      GLAccountLongName         : abap.char(50);
      OffsettingAccountLongName : abap.char(50);
      ObjectText                : abap.char(100);
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      DebitAmountInTransCrcy    : abap.curr(23, 2);
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      DebitAmountInCoCodeCrcy   : abap.curr(23, 2);
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      CreditAmountInTransCrcy   : abap.curr(23, 2);
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      CreditAmountInCoCodeCrcy  : abap.curr(23, 2);

      IsBeg                     : abap.char(1);
}
