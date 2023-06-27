*&---------------------------------------------------------------------*
*& Report ZTEST_CLEARING
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZTEST_CLEARING.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_budat LIKE bkpf-budat OBLIGATORY DEFAULT sy-datum.
PARAMETERS: p_bukrs LIKE bkpf-bukrs OBLIGATORY DEFAULT 'LU02'.
PARAMETERS: p_wrbtr LIKE bseg-wrbtr OBLIGATORY DEFAULT '1000'.
PARAMETERS: p_sgtxt LIKE bkpf-bktxt OBLIGATORY DEFAULT 'PAYMENTS:'.
PARAMETERS: p_glacc LIKE bseg-hkont OBLIGATORY DEFAULT '10001102'.
PARAMETERS: p_kunnr LIKE bseg-kunnr OBLIGATORY DEFAULT '1003601'.
PARAMETERS: p_waers LIKE bkpf-waers OBLIGATORY DEFAULT 'EUR'.
PARAMETERS: p_belnr LIKE bkpf-belnr OBLIGATORY DEFAULT '1800000726'.
PARAMETERS: p_gjahr LIKE bkpf-gjahr OBLIGATORY DEFAULT '2024'.
SELECTION-SCREEN END OF BLOCK blk1.

DATA: BEGIN OF ls_out,
        belnr TYPE belnr_d,
        gjahr TYPE gjahr,
        bukrs TYPE bukrs,
      END OF ls_out.

DATA:
  lt_open_item_tab TYPE postab_tab,
  ls_acchd         TYPE acchd,
  ls_accit         TYPE accit,
  ls_acccr         TYPE acccr,
  lt_acchd         TYPE acchd_t,
  lt_accit         TYPE accit_tab,
  lt_acccr         TYPE acccr_tab,
  lt_selection_tab TYPE selection_tab_t,
  ls_selection_tab TYPE selection_tab,
  ls_message       TYPE bal_s_msg,
  lv_difference    TYPE diffw,
  lv_kursf         TYPE kursf,
  lt_ausz2         TYPE  ausz2_tab,
  lt_ausz3         TYPE  ausz_clr_tab.

ls_selection_tab-fieldname = 'BELNR'.
ls_selection_tab-fieldtype = 'C'.
ls_selection_tab-fromvalue = p_belnr.
APPEND ls_selection_tab TO lt_selection_tab.

CONSTANTS: cv_clr_tran TYPE auglv VALUE 'EINGZAHL'.
DATA: it_sel  TYPE selection_tab_t,
      et_open TYPE postab_tab.

CALL FUNCTION 'FI_OPEN_ITEMS_SELECT'
  EXPORTING
    i_clr_trans              = cv_clr_tran
    i_bukrs                  = p_bukrs
    i_koart                  = 'D' "Customer
    i_konko                  = p_kunnr
    i_waers                  = p_waers
    i_blart                  = 'ZB'
    i_wwert                  = p_budat
    i_kursf                  = lv_kursf
    i_bldat                  = p_budat
    i_budat                  = p_budat
    it_selection_tab         = lt_selection_tab
  IMPORTING
    et_open_item_tab         = lt_open_item_tab
  EXCEPTIONS
    company_code_missing     = 1
    account_type_missing     = 2
    account_missing          = 3
    currency_key_missing     = 4
    translation_date_missing = 5
    OTHERS                   = 6.

ls_acchd-awtyp = 'BKPFF'.
ls_acchd-glvor = 'RFBU'.
APPEND ls_acchd TO lt_acchd.

MOVE-CORRESPONDING ls_acchd TO ls_accit.

READ TABLE lt_open_item_tab ASSIGNING FIELD-SYMBOL(<fs_open>) INDEX 1.
<fs_open>-diffw = 100.
<fs_open>-difhw = 100.
<fs_open>-xvort = abap_true.
<fs_open>-rstgn = 'DD'.

"First item
ls_accit-blart = 'DZ'.
ls_accit-posnr = 1.
ls_accit-bschl = 40.
ls_accit-hkont = p_glacc.

ls_accit-gkoar = 'D'.
ls_accit-gkont = p_kunnr.
ls_accit-kunnr = p_kunnr.
"ls_accit-prctr = ls_open-prctr.
CALL FUNCTION 'FI_POSTING_KEY_DATA'
  EXPORTING
    i_bschl = ls_accit-bschl
  IMPORTING
    e_koart = ls_accit-koart
    e_shkzg = ls_accit-shkzg.

ls_accit-xblnr = 'TestRef'.
ls_accit-bldat = p_budat.
ls_accit-budat = p_budat.
ls_accit-zfbdt = p_budat.
ls_accit-bukrs = p_bukrs.
ls_accit-wwert = p_budat.
ls_accit-awref = 'TestRef'.
APPEND ls_accit TO lt_accit.

MOVE-CORRESPONDING ls_accit TO ls_acccr.
ls_acccr-curtp = '00'.
ls_acccr-waers = p_waers.
ls_acccr-wrbtr = 1900.
ls_acccr-kursf = lv_kursf.
APPEND ls_acccr TO lt_acccr.

"Second Line
ls_accit-posnr = 2.
ls_accit-koart = 'D'.
ls_accit-bschl = '15'.
SELECT SINGLE akont FROM knb1 INTO ls_accit-hkont
  WHERE bukrs = p_bukrs AND
        kunnr = p_kunnr.
CALL FUNCTION 'FI_POSTING_KEY_DATA'
  EXPORTING
    i_bschl = ls_accit-bschl
  IMPORTING
    e_koart = ls_accit-koart
    e_shkzg = ls_accit-shkzg.
APPEND ls_accit TO lt_accit.
MOVE-CORRESPONDING ls_accit TO ls_acccr.
ls_acccr-curtp = '00'.
ls_acccr-waers = p_waers.
ls_acccr-wrbtr = -1000.
APPEND ls_acccr TO lt_acccr.


CALL FUNCTION 'FI_CLEARING_CREATE'
  EXPORTING
    i_clr_trans      = cv_clr_tran
    it_open_item_tab = lt_open_item_tab
    "i_diff_tc        = i_diff_tc "Clearing/payment difference in document currency
  IMPORTING
    et_ausz2         = lt_ausz2
    et_ausz3         = lt_ausz3
  CHANGING
    ct_acchd         = lt_acchd
    ct_accit         = lt_accit
    ct_acccr         = lt_acccr.

READ TABLE lt_accit ASSIGNING FIELD-SYMBOL(<fs>) INDEX 2.
<fs>-prctr = 'LU02SCC400'.
READ TABLE lt_accit ASSIGNING <fs> INDEX 3.
<fs>-prctr = 'LU02SCC400'.

CALL FUNCTION 'AC_DOCUMENT_CREATE'
  EXPORTING
    i_free_table = ' '
  TABLES
    t_acchd      = lt_acchd
    t_accit      = lt_accit
    t_acccr      = lt_acccr
    t_ausz2      = lt_ausz2
    t_ausz3      = lt_ausz3.

READ TABLE lt_acchd INDEX 1 INTO ls_acchd.
READ TABLE lt_accit INDEX 1 INTO ls_accit.

TABLES: t003.
DATA: lv_belnr TYPE belnr_d.

CALL FUNCTION 'FI_DOCUMENT_TYPE_DATA'
  EXPORTING
    i_blart = 'DZ'
  IMPORTING
    e_t003  = t003.

CALL FUNCTION 'RF_GET_DOCUMENT_NUMBER'
  EXPORTING
    company         = p_bukrs
    range           = t003-numkr
    year            = p_gjahr
  IMPORTING
    document_number = lv_belnr.

ls_acchd-awref = lv_belnr.
ls_acchd-aworg = |{ p_bukrs }{ p_gjahr }|.

CALL FUNCTION 'AC_DOCUMENT_POST'
  EXPORTING
    i_awtyp = ls_acchd-awtyp
    i_awref = ls_acchd-awref
    i_aworg = ls_acchd-aworg.

COMMIT WORK.
