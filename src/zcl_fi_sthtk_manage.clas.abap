CLASS zcl_fi_sthtk_manage DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: gt_data     TYPE TABLE OF zi_fi_sthtk.
    CLASS-METHODS:
      get_instance
        RETURNING
          VALUE(ro_instance) TYPE REF TO zcl_fi_sthtk_manage,
      get_data
        IMPORTING io_request TYPE REF TO if_rap_query_request
        EXPORTING et_data    LIKE gt_data.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: instance TYPE REF TO zcl_fi_sthtk_manage.
ENDCLASS.



CLASS ZCL_FI_STHTK_MANAGE IMPLEMENTATION.


  METHOD get_data.
    DATA: lv_ledger            TYPE fins_ledger,
          lv_sublevel          TYPE zde_sublevel,
          lv_increv            TYPE zde_boolean,
          lr_companycode       TYPE RANGE OF bukrs,
          lr_fiscalyear        TYPE RANGE OF fis_gjahr_no_conv,
          lv_fiscalyear        TYPE fis_gjahr_no_conv,
          lr_fiscalperiod      TYPE RANGE OF fins_fiscalperiod,
          lr_postingdate       TYPE RANGE OF fis_budat,
          lr_glaccount         TYPE RANGE OF zde_racct,
          lr_glaccount_raw     TYPE RANGE OF zde_racct,
          lr_offsettingaccount TYPE RANGE OF zde_racct.

    DATA: lt_data_raw     TYPE TABLE OF zi_fi_sthtk,
          lt_data_beg     TYPE TABLE OF zi_fi_sthtk,
          lt_data_inp     TYPE TABLE OF zi_fi_sthtk,
          lt_data         TYPE TABLE OF zi_fi_sthtk,
          lt_data_sum_beg TYPE TABLE OF zi_fi_sthtk,
          lt_data_sum_inp TYPE TABLE OF zi_fi_sthtk,
          lt_data_sum_end TYPE TABLE OF zi_fi_sthtk,
          ls_data         TYPE zi_fi_sthtk.

    " get filter by parameter -----------------------
    DATA(lt_paramater) = io_request->get_parameters( ).
    IF lt_paramater IS NOT INITIAL.
      LOOP AT lt_paramater REFERENCE INTO DATA(ls_parameter).
        CASE ls_parameter->parameter_name.
          WHEN 'P_LEDGER'.
            lv_ledger       = ls_parameter->value.
          WHEN 'P_SUBLEVEL'.
            lv_sublevel      = ls_parameter->value.
          WHEN 'P_INCREV'.
            lv_increv       = ls_parameter->value.
        ENDCASE.
      ENDLOOP.
    ENDIF.
    TRY.
        DATA(lt_filter_cond) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_sel_option).
    ENDTRY.
    IF lt_filter_cond IS NOT INITIAL.
      LOOP AT lt_filter_cond REFERENCE INTO DATA(ls_filter_cond).
        CASE ls_filter_cond->name.
          WHEN 'COMPANYCODE'.
            lr_companycode          = CORRESPONDING #( ls_filter_cond->range[] ) .
          WHEN 'POSTINGDATE'.
            lr_postingdate          = CORRESPONDING #( ls_filter_cond->range[] ) .
          WHEN 'FISCALPERIOD'.
            lr_fiscalperiod         = CORRESPONDING #( ls_filter_cond->range[] ) .
          WHEN 'FISCALYEAR'.
            lr_fiscalyear           = CORRESPONDING #( ls_filter_cond->range[] ) .
          WHEN 'GLACCOUNT'.
            lr_glaccount_raw        = CORRESPONDING #( ls_filter_cond->range[] ) .
          WHEN 'OFFSETTINGACCOUNT'.
            lr_offsettingaccount    = CORRESPONDING #( ls_filter_cond->range[] ) .
          WHEN OTHERS.
        ENDCASE.
      ENDLOOP.
    ENDIF.
    " get filter by parameter -----------------------

    DATA: lv_fromdate TYPE dats,
          lv_todate   TYPE dats.

    lv_fromdate = lr_postingdate[ 1 ]-low.
    lv_todate   = lr_postingdate[ 1 ]-high.

    lv_fiscalyear = lr_fiscalyear[ 1 ]-low.

    CASE lv_sublevel.
      WHEN '1' OR '2'.
        SELECT DISTINCT saknr_parent
          FROM ztb_saknr_parent
          WHERE saknr_parent IN @lr_glaccount_raw
          INTO TABLE @DATA(lt_parent_acc).
        IF sy-subrc EQ 0.
          LOOP AT lt_parent_acc INTO DATA(ls_parent_acc).
            APPEND VALUE #( sign = 'I' option = 'CP' low = ls_parent_acc-saknr_parent && '*' ) TO lr_glaccount.
          ENDLOOP.
        ENDIF.

        SELECT *
          FROM ztb_saknr_parent
          INTO TABLE @DATA(lt_saknr_parent).
        IF sy-subrc EQ 0.
          SORT lt_saknr_parent BY saknr_parent.
        ENDIF.
      WHEN '9'.
        lr_glaccount = lr_glaccount_raw.
    ENDCASE.

*    CHECK lr_glaccount IS NOT INITIAL.

    IF lr_fiscalperiod IS INITIAL.
      SELECT
        companycode,
        fiscalyear,
        glaccount,
        offsettingaccount,
        glaccountlongname,
        offsettingaccountlongname,
        fiscalperiod,
        postingdate,
        documentdate,
        transactioncurrency,
        companycodecurrency,
        debitamountintranscrcy,
        debitamountincocodecrcy,
        creditamountintranscrcy,
        creditamountincocodecrcy,
        ' ' AS isbeg
        FROM zi_fi_sthtk_sum( p_ledger = @lv_ledger, p_increv = @lv_increv, p_currencytype = 'I' )
        WHERE companycode         IN @lr_companycode
          AND fiscalyear          LE @lv_fiscalyear
          AND postingdate         LE @lv_todate
          AND glaccount           IN @lr_glaccount
          AND offsettingaccount   IN @lr_offsettingaccount
          INTO TABLE @DATA(lt_data_db).
    ELSE.
      SELECT
        companycode,
        fiscalyear,
        glaccount,
        offsettingaccount,
        glaccountlongname,
        offsettingaccountlongname,
        fiscalperiod,
        postingdate,
        documentdate,
        transactioncurrency,
        companycodecurrency,
        debitamountintranscrcy,
        debitamountincocodecrcy,
        creditamountintranscrcy,
        creditamountincocodecrcy,
        ' ' AS isbeg
        FROM zi_fi_sthtk_sum( p_ledger = @lv_ledger, p_increv = @lv_increv, p_currencytype = 'I' )
        WHERE companycode         IN @lr_companycode
          AND fiscalyear          LE @lv_fiscalyear
          AND postingdate         LT @lv_fromdate
          AND glaccount           IN @lr_glaccount
          AND offsettingaccount   IN @lr_offsettingaccount
          INTO TABLE @lt_data_db.
      SELECT
        companycode,
        fiscalyear,
        glaccount,
        offsettingaccount,
        glaccountlongname,
        offsettingaccountlongname,
        fiscalperiod,
        postingdate,
        documentdate,
        transactioncurrency,
        companycodecurrency,
        debitamountintranscrcy,
        debitamountincocodecrcy,
        creditamountintranscrcy,
        creditamountincocodecrcy,
        ' ' AS isbeg
        FROM zi_fi_sthtk_sum( p_ledger = @lv_ledger, p_increv = @lv_increv, p_currencytype = 'I' )
        WHERE companycode         IN @lr_companycode
          AND fiscalyear          LE @lv_fiscalyear
          AND fiscalperiod        IN @lr_fiscalperiod
          AND postingdate         GE @lv_fromdate
          AND postingdate         LE @lv_todate
          AND glaccount           IN @lr_glaccount
          AND offsettingaccount   IN @lr_offsettingaccount
          APPENDING TABLE @lt_data_db.
    ENDIF.
    CHECK lt_data_db IS NOT INITIAL.

    LOOP AT lt_data_db ASSIGNING FIELD-SYMBOL(<lfs_data_db>).
      CASE lv_sublevel.
        WHEN '1'.
          " 3 số
          <lfs_data_db>-glaccount           = <lfs_data_db>-glaccount+0(3).
          <lfs_data_db>-offsettingaccount   = <lfs_data_db>-offsettingaccount+0(3).
          CLEAR: <lfs_data_db>-glaccountlongname,
                 <lfs_data_db>-offsettingaccountlongname.
        WHEN '2'.
          " 4 số
          <lfs_data_db>-glaccount           = <lfs_data_db>-glaccount+0(4).
          <lfs_data_db>-offsettingaccount   = <lfs_data_db>-offsettingaccount+0(4).
          CLEAR: <lfs_data_db>-glaccountlongname,
                 <lfs_data_db>-offsettingaccountlongname.
        WHEN '9'.
      ENDCASE.

      IF <lfs_data_db>-postingdate < lv_fromdate.
        <lfs_data_db>-isbeg = 'X'.
      ELSE.
        CLEAR: <lfs_data_db>-isbeg.
      ENDIF.
    ENDLOOP.

    SELECT
      glaccount,
      offsettingaccount,
      glaccountlongname,
      offsettingaccountlongname,
      transactioncurrency,
      companycodecurrency,
      isbeg,
      SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
      SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
      SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
      SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
      FROM @lt_data_db AS data
      GROUP BY
      glaccount,
      offsettingaccount,
      glaccountlongname,
      offsettingaccountlongname,
      isbeg,
      transactioncurrency,
      companycodecurrency
      INTO CORRESPONDING FIELDS OF TABLE @lt_data_raw.

    CHECK sy-subrc = 0.

    SORT lt_data_raw BY glaccount.

    LOOP AT lt_data_raw ASSIGNING FIELD-SYMBOL(<lfs_data_raw>).
      READ TABLE lt_saknr_parent INTO DATA(ls_saknr_parent)
        WITH KEY saknr_parent = <lfs_data_raw>-glaccount BINARY SEARCH.
      IF sy-subrc EQ 0.
        <lfs_data_raw>-glaccountlongname = ls_saknr_parent-txt50_skat.
      ENDIF.

      READ TABLE lt_saknr_parent INTO ls_saknr_parent
        WITH KEY saknr_parent = <lfs_data_raw>-offsettingaccount BINARY SEARCH.
      IF sy-subrc EQ 0.
        <lfs_data_raw>-offsettingaccountlongname = ls_saknr_parent-txt50_skat.
      ENDIF.

      <lfs_data_raw>-creditamountintranscrcy *= -1.
      <lfs_data_raw>-creditamountincocodecrcy *= -1.

      IF <lfs_data_raw>-isbeg EQ 'X'.
        APPEND <lfs_data_raw> TO lt_data_beg.
      ELSE.
        APPEND <lfs_data_raw> TO lt_data_inp.
      ENDIF.
    ENDLOOP.

    SELECT DISTINCT
      glaccount,
      glaccountlongname
      FROM @lt_data_raw AS data
      INTO TABLE @DATA(lt_glaccount).
    IF sy-subrc EQ 0.
      LOOP AT lt_glaccount INTO DATA(ls_glaccount).
        ls_data-issubtotal = 'X'.
        ls_data-glaccount  = ls_glaccount-glaccount.
        CONCATENATE ls_glaccount-glaccount '-' ls_glaccount-glaccountlongname INTO ls_data-objecttext SEPARATED BY space.
        APPEND ls_data TO et_data.
        CLEAR: ls_data.
        " Số dư đầu kỳ (Opening Balance)
        SELECT
          'X' AS issubtotal,
          1 AS notitle,
          'Số dư đầu kỳ (Opening Balance)' AS objecttext,
          glaccount,
          transactioncurrency,
          companycodecurrency,
          SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
          SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
          SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
          SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
          FROM @lt_data_beg AS data
          WHERE glaccount = @ls_glaccount-glaccount
          GROUP BY
          glaccount,
          transactioncurrency,
          companycodecurrency
          INTO TABLE @DATA(lt_data_beg_subtotal).
        IF sy-subrc NE 0.
          SELECT DISTINCT
            'X' AS issubtotal,
            1 AS notitle,
            'Số dư đầu kỳ (Opening Balance)' AS objecttext,
            glaccount,
            transactioncurrency,
            companycodecurrency
            FROM @lt_data_inp AS data
            WHERE glaccount = @ls_glaccount-glaccount
            INTO CORRESPONDING FIELDS OF TABLE @lt_data_beg_subtotal.
        ENDIF.
        LOOP AT lt_data_beg_subtotal ASSIGNING FIELD-SYMBOL(<lfs_data_beg_subtotal>).
          IF <lfs_data_beg_subtotal>-debitamountintranscrcy - <lfs_data_beg_subtotal>-creditamountintranscrcy < 0.
            <lfs_data_beg_subtotal>-creditamountintranscrcy -= <lfs_data_beg_subtotal>-debitamountintranscrcy.
            <lfs_data_beg_subtotal>-debitamountintranscrcy  = 0.
            <lfs_data_beg_subtotal>-creditamountincocodecrcy -= <lfs_data_beg_subtotal>-debitamountincocodecrcy.
            <lfs_data_beg_subtotal>-debitamountincocodecrcy  = 0.
          ELSE.
            <lfs_data_beg_subtotal>-debitamountintranscrcy -= <lfs_data_beg_subtotal>-creditamountintranscrcy.
            <lfs_data_beg_subtotal>-creditamountintranscrcy = 0.
            <lfs_data_beg_subtotal>-debitamountincocodecrcy -= <lfs_data_beg_subtotal>-creditamountincocodecrcy.
            <lfs_data_beg_subtotal>-creditamountincocodecrcy = 0.
          ENDIF.
        ENDLOOP.

        " Cộng phát sinh (Total Transaction)
        SELECT
          'X' AS issubtotal,
          2 AS notitle,
          'Cộng phát sinh (Total Transaction)' AS objecttext,
          glaccount,
          transactioncurrency,
          companycodecurrency,
          SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
          SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
          SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
          SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
          FROM @lt_data_inp AS data
          WHERE glaccount = @ls_glaccount-glaccount
          GROUP BY
          glaccount,
          transactioncurrency,
          companycodecurrency
          INTO TABLE @DATA(lt_data_inp_subtotal).
        IF sy-subrc NE 0.
          SELECT DISTINCT
            'X' AS issubtotal,
            2 AS notitle,
            'Cộng phát sinh (Total Transaction)' AS objecttext,
            glaccount,
            transactioncurrency,
            companycodecurrency
            FROM @lt_data_beg AS data
            WHERE glaccount = @ls_glaccount-glaccount
            INTO CORRESPONDING FIELDS OF TABLE @lt_data_inp_subtotal.
        ENDIF.

        " Số dư cuối kỳ (Closing Balance)
        SELECT
          'X' AS issubtotal,
          3 AS notitle,
          'Số dư cuối kỳ (Closing Balance)' AS objecttext,
          glaccount,
          transactioncurrency,
          companycodecurrency,
          SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
          SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
          SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
          SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
          FROM @lt_data_raw AS data
          WHERE glaccount = @ls_glaccount-glaccount
          GROUP BY
          glaccount,
          transactioncurrency,
          companycodecurrency
          INTO TABLE @DATA(lt_data_raw_subtotal).

        LOOP AT lt_data_raw_subtotal ASSIGNING FIELD-SYMBOL(<lfs_data_raw_subtotal>).
          IF <lfs_data_raw_subtotal>-debitamountintranscrcy - <lfs_data_raw_subtotal>-creditamountintranscrcy < 0.
            <lfs_data_raw_subtotal>-creditamountintranscrcy -= <lfs_data_raw_subtotal>-debitamountintranscrcy.
            <lfs_data_raw_subtotal>-debitamountintranscrcy  = 0.
            <lfs_data_raw_subtotal>-creditamountincocodecrcy -= <lfs_data_raw_subtotal>-debitamountincocodecrcy.
            <lfs_data_raw_subtotal>-debitamountincocodecrcy  = 0.
          ELSE.
            <lfs_data_raw_subtotal>-debitamountintranscrcy -= <lfs_data_raw_subtotal>-creditamountintranscrcy.
            <lfs_data_raw_subtotal>-creditamountintranscrcy = 0.
            <lfs_data_raw_subtotal>-debitamountincocodecrcy -= <lfs_data_raw_subtotal>-creditamountincocodecrcy.
            <lfs_data_raw_subtotal>-creditamountincocodecrcy = 0.
          ENDIF.
        ENDLOOP.

        MOVE-CORRESPONDING lt_data_beg_subtotal TO lt_data.
        APPEND LINES OF lt_data TO et_data.
        APPEND LINES OF lt_data TO lt_data_sum_beg.
        MOVE-CORRESPONDING lt_data_inp_subtotal TO lt_data.
        APPEND LINES OF lt_data TO et_data.
        APPEND LINES OF lt_data TO lt_data_sum_inp.
        MOVE-CORRESPONDING lt_data_raw_subtotal TO lt_data.
        APPEND LINES OF lt_data TO et_data.
        APPEND LINES OF lt_data TO lt_data_sum_end.
      ENDLOOP.
    ENDIF.

    " Tổng số dư đầu kỳ (Opening Balance)
    SELECT
      'X' AS istotal,
      1 AS notitle,
      'Số dư đầu kỳ tổng (Beginning balance)' AS objecttext,
      transactioncurrency,
      companycodecurrency,
      SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
      SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
      SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
      SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
      FROM @lt_data_sum_beg AS data
      GROUP BY
      transactioncurrency,
      companycodecurrency
      INTO TABLE @DATA(lt_data_beg_total).
    IF sy-subrc NE 0.
      SELECT DISTINCT
        'X' AS istotal,
        1 AS notitle,
        'Số dư đầu kỳ tổng (Beginning balance)' AS objecttext,
        transactioncurrency,
        companycodecurrency
        FROM @lt_data_sum_inp AS data
        INTO CORRESPONDING FIELDS OF TABLE @lt_data_beg_total.
    ELSE.
      LOOP AT lt_data_beg_total ASSIGNING FIELD-SYMBOL(<lfs_data_beg_total>).
        IF <lfs_data_beg_total>-debitamountintranscrcy > <lfs_data_beg_total>-creditamountintranscrcy.
          <lfs_data_beg_total>-debitamountintranscrcy -= <lfs_data_beg_total>-creditamountintranscrcy.
          <lfs_data_beg_total>-creditamountintranscrcy = 0.
          <lfs_data_beg_total>-debitamountincocodecrcy -= <lfs_data_beg_total>-creditamountincocodecrcy.
          <lfs_data_beg_total>-creditamountincocodecrcy = 0.
        ELSE.
          <lfs_data_beg_total>-creditamountintranscrcy -= <lfs_data_beg_total>-debitamountintranscrcy.
          <lfs_data_beg_total>-debitamountintranscrcy   = 0.
          <lfs_data_beg_total>-creditamountincocodecrcy -= <lfs_data_beg_total>-debitamountincocodecrcy.
          <lfs_data_beg_total>-debitamountincocodecrcy   = 0.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " Tổng cộng phát sinh (Total Transaction)
    SELECT
      'X' AS istotal,
      2 AS notitle,
      'Cộng phát sinh tổng (Total Transaction)' AS objecttext,
      transactioncurrency,
      companycodecurrency,
      SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
      SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
      SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
      SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
      FROM @lt_data_sum_inp AS data
      GROUP BY
      transactioncurrency,
      companycodecurrency
      INTO TABLE @DATA(lt_data_inp_total).
    IF sy-subrc NE 0.
      SELECT DISTINCT
        'X' AS istotal,
        2 AS notitle,
        'Cộng phát sinh tổng (Total Transaction)' AS objecttext,
        transactioncurrency,
        companycodecurrency
        FROM @lt_data_sum_beg AS data
        INTO CORRESPONDING FIELDS OF TABLE @lt_data_inp_total.
    ENDIF.

    " Tổng số dư cuối kỳ (Closing Balance)
    SELECT
      'X' AS istotal,
      3 AS notitle,
      'Số dư cuối kỳ tổng (Closing balance)' AS objecttext,
      transactioncurrency,
      companycodecurrency,
      SUM( debitamountintranscrcy )   AS debitamountintranscrcy,
      SUM( debitamountincocodecrcy )  AS debitamountincocodecrcy,
      SUM( creditamountintranscrcy )  AS creditamountintranscrcy,
      SUM( creditamountincocodecrcy ) AS creditamountincocodecrcy
      FROM @lt_data_sum_end AS data
      GROUP BY
      transactioncurrency,
      companycodecurrency
      INTO TABLE @DATA(lt_data_raw_total).
    IF sy-subrc EQ 0.
      LOOP AT lt_data_raw_total ASSIGNING FIELD-SYMBOL(<lfs_data_raw_total>).
        IF <lfs_data_raw_total>-debitamountintranscrcy > <lfs_data_raw_total>-creditamountintranscrcy.
          <lfs_data_raw_total>-debitamountintranscrcy -= <lfs_data_raw_total>-creditamountintranscrcy.
          <lfs_data_raw_total>-creditamountintranscrcy = 0.
          <lfs_data_raw_total>-debitamountincocodecrcy -= <lfs_data_raw_total>-creditamountincocodecrcy.
          <lfs_data_raw_total>-creditamountincocodecrcy = 0.
        ELSE.
          <lfs_data_raw_total>-creditamountintranscrcy -= <lfs_data_raw_total>-debitamountintranscrcy.
          <lfs_data_raw_total>-debitamountintranscrcy   = 0.
          <lfs_data_raw_total>-creditamountincocodecrcy -= <lfs_data_raw_total>-debitamountincocodecrcy.
          <lfs_data_raw_total>-debitamountincocodecrcy   = 0.
        ENDIF.
      ENDLOOP.
    ENDIF.

    MOVE-CORRESPONDING lt_data_beg_total TO lt_data.
    APPEND LINES OF lt_data TO et_data.
    MOVE-CORRESPONDING lt_data_inp_total TO lt_data.
    APPEND LINES OF lt_data TO et_data.
    MOVE-CORRESPONDING lt_data_raw_total TO lt_data.
    APPEND LINES OF lt_data TO et_data.

    APPEND LINES OF lt_data_inp TO et_data.
  ENDMETHOD.


  METHOD get_instance.
    IF instance IS INITIAL.
      CREATE OBJECT instance.
    ENDIF.
    ro_instance = instance.
  ENDMETHOD.
ENDCLASS.
