@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sổ tổng hợp tài khoản - Account Value Help'
@Metadata.ignorePropagatedAnnotations: true 
define view entity ZI_FI_STHTK_ACC_VH 
  as select from I_GlAccountTextInCompanycode
{
  key '9' as SubLevel,
  key GLAccount         as Account,
      GLAccountLongName as AccountLongName
}
where
      Language    = $session.system_language 
union select from ztb_saknr_parent
{
  key case when cast( saknr_parent as abap.int4 ) < 999 then '1' else '2' end as SubLevel,
  key saknr_parent as Account,
      txt50_skat   as AccountLongName
}
