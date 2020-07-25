--DECLARE
--@StartDate DATETIME,
--@EndDate DATETIME,

--/* SELECT FROM [dbo].[OPCH] T4 */DECLARE @StartDate As DATETIME)/* WHERE */SET @StartDate = /* T4.DocDate */ '[%1]'
--/* SELECT FROM [dbo].[OPCH] T5 */DECLARE @EndDate As DATETIME/* WHERE */SET @EndDate = /* T5.DocDate */ '[%2]'


--@Dummy INTEGER
--SELECT TOP 1 @Dummy = DocNum FROM  OPCH T0 WHERE T0.DocDate >= [%1] AND ----T0.DocDate <= [%2]
--SELECT
--@StartDate= '[%1]',
--@EndDate = '[%2]'
Select * from (
SELECT T0.Docentry, 
(CASE  T0.gsttrantyp when 'GA' then 'Gst Tax Invoice'
 when 'GD' then 'Gst Debit Memo'
 when '--' then 'Bill Of Supply' 
  end) 'GST Transaction Type',	
CONVERT(VARCHAR(10), T0.DocDate, 3) AS 'Invoice Date', T0.DocNum as 'Invoice No',  
N1.SeriesName 'DocSeries',  N1.BeginStr 'DocSeriesPrefix', N1.EndStr 'DocSeriesSuffix',
SLP.SLPNAME 'SALES PERSON NAME',
T0.cardcode,
T0.CardName AS 'vendor Billing Name', 
T0.NumAtCard 'Vendor Bill No',
T7.BPGSTN 'Billing GSTIN', T7.LocStaGSTN 'State POS',  
(CASE WHEN T0.DocType = 'I' AND ITM.ItemClass = 2 THEN 'G' ELSE 'S' END) ItemType,
t1.itemcode 'item code',
T1.Dscription AS 'Item Description',  
(Case When T0.Doctype = 'I' Then 
   (CASE When ITM.ItemClass = 1 Then (Select ServCode from OSAC Where AbsEntry =(case when  T1.HsnEntry is  null then  ITM.SACEntry else T1.SACEntry end))  
  When ITM.ItemClass  = 2 Then (select ChapterID  from ochp where AbsEntry = (case when  T1.HsnEntry is  null then  ITM.chapterid else T1.HsnEntry end)) Else '' END)        
  Else (Case When T0.DocType = 'S' Then (Select ServCode from OSAC Where AbsEntry = T1.SACEntry) END) END) 'HSN/SAC Code' ,
(case when T0.doctype='S' then 1 else T1.Quantity end)'Quantity',  
(case when doctype='S' then T1.LineTotal else (T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end)) end)  'Unit Price',
(case when T0.doctype='S' then (T1.LineTotal) else (t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) end) 'ItemTotalBefDi',
(case when T0.doctype='S' then ((t1.Quantity*T1.linetotal)* T1.DiscPrcnt/100)+ (T1.Linetotal *T0.DiscPrcnt/100) else 
((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end)))* T1.DiscPrcnt/100)+ (T1.Linetotal *T0.DiscPrcnt/100) end)  'Item Discount',
(case when T0.doctype='S' then (T1.LineTotal)-(T1.Linetotal *T0.DiscPrcnt/100) else ((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end)))
 - (((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) * T1.DiscPrcnt/100) + (T1.Linetotal *T0.DiscPrcnt/100))) end)  ' Item Total After Discount',
(case when T1.taxonly='Y' then 0 else 
 (CASE when isnull(T0.DiscPrcnt,0)=0 then isnull(T1.LineTotal,0) else (isnull(T1.LineTotal,0)-(isnull(T1.LineTotal,0)*isnull(T0.DiscPrcnt,0)/100)) End) end) AS 'Basic Line Total', --TAX ONLY
(CASE WHEN  (T1.AssblValue > 0) THEN (T1.Quantity*T1.AssblValue) ELSE  
(CASE when isnull(T0.DiscPrcnt,0)=0 then isnull(T1.LineTotal,0) else (isnull(T1.LineTotal,0)-(isnull(T1.LineTotal,0)*isnull(T0.DiscPrcnt,0)/100)) End) end) 'Taxable Value',
T1.TaxCode,
isnull(CGST.taxRate,0) as 'CGST Rate',
isnull(CGST.TaxSum,0) AS 'CGST',
isnull(SGST.taxRate,0) as 'SGST/UGST Rate',
isnull(SGST.TaxSum,0) AS 'SGST/UGST', 
isnull(IGST.taxRate,0) as 'IGST Rate',
isnull(IGST.TaxSum,0) AS 'IGST',
isnull(OTHER.taxrate,0) as 'OTHER Rate', --other tax
Isnull(OTHER.taxsum,0) as 'OTHER', --other tax
(case when isnull(CGST.RvschrgTax,0) + isnull(SGST.RvschrgTax,0) + isnull(IGST.RvschrgTax,0)<> 0 then 'Y' else 'N' end) as 'Reverse Charge Flag',
isnull(CGST.RvschrgTax,0) as 'CGST Rev Tax',
isnull(SGST.RvschrgTax,0) as 'SGST/UGST Rev Tax',
isnull(IGST.RvschrgTax,0) as 'IGST Rev Tax',
((case when T0.doctype='S' then (T1.LineTotal)-(T1.Linetotal *T0.DiscPrcnt/100) else ((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) -
 (((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) * T1.DiscPrcnt/100) + (T1.Linetotal *T0.DiscPrcnt/100))) end) +isnull(CGST.TaxSum,0)+isnull(SGST.TaxSum,0)+isnull(IGST.TaxSum,0) ) as 'Total Incl GST',
T0.RevRefNo 'Original Invoice No', T0.RevRefDate 'Original Invoice Date', T7.BPGSTN 'Original vendor GSTIN',
T0.EComerGSTN 'ECommGSTN',	
CONVERT(VARCHAR(10),iv9.BsDocDate, 3) 'AdvancePaymentDocDate',
iv9.BaseDocNum 'AdvancePaymentDocNum',
T7.ImpORExp 'Flag Import Invoice',
Null as 'Import Type',
  T7.ImpExpNo 'Bill of Entry No', T7.ImpExpDate 'Bill of Entry Date' , T7.BPCountry 'vendor Country',  
T7.BPGSTN 'vendor GSTNo',
T0.Address 'Billing Address' , 
T7.CityB 'Billing City', T7.ZipCodeB 'Billing Pin Code' , T7.StateB 'Billing State', T0.ShipToCode 'Shipping Name', 
T0.Address2 'Shipping Address',
T7.CityS 'Shipping City', T7.ZipCodeS 'Shipping Pin Code', T7.BPStateCod 'Shipping State', T7.BPStatGSTN 'Shipping State Code', 
MONTH(T0.RevRefDate) as 'Revision_Month',
 (CASE WHEN T0.DutyStatus = 'Y' THEN 'WPAY'  ELSE 'WOPAY' END ) 'Duty_Status',
Null as 'Port Code',
 (select GSTType from OGTY where absentry=T7.BPGSTType ) as 'Vendor GST Type',
 T7.LocGSTN 'Location GSTNo',  T7.LocStatCod 'Location State' , 
'AP Invoice' as 'Doc Type',
T0.DocDueDate 'Invoice Due Date',
T0.Comments 
FROM OPCH T0 
left outer join OCRD on OCRD.CardCode=T0.CardCode
left outer join OCRG on OCRG.GroupCode=OCRD.GroupCode
Left Join CRD7 C7 On T0.CardCode =C7.CardCode And T0.ShipToCode = C7.Address and C7.AddrType = 'S'
INNER JOIN PCH1 T1 ON T0.DocEntry = T1.DocEntry 
LEFT OUTER JOIN OSLP SLP ON SLP.SLPCODE=T0.SLPCODE
LEFT OUTER JOIN OITM ITM on (ITM.ItemCode = T1.ItemCode)
left outer join NNM1 N1 on N1.Series=T0.Series 
left outer join PCH9 iv9 on t0.docentry=iv9.docentry and iv9.objtype='203' --and t1.linenum=iv9.linenum
left outer JOIN PCH12 T7 ON T0.DocEntry = T7.DocEntry 
Left Join PCH4 CGST ON T1.DocEntry = CGST.DocEntry And T1.LineNum = CGST.LineNum And CGST.StaType = -100 AND CGST.RelateType = 1 AND CGST.ExpnsCode=-1
Left Join PCH4 SGST ON T1.DocEntry = SGST.DocEntry And T1.LineNum = SGST.LineNum And SGST.StaType in (-110,-150) AND SGST.RelateType = 1 AND  SGST.ExpnsCode=-1 --addedded ugst
Left Join PCH4 IGST ON T1.DocEntry = IGST.DocEntry And T1.LineNum = IGST.LineNum And IGST.StaType =-120 AND IGST.RelateType =1 AND IGST.ExpnsCode=-1
Left outer join (select taxrate,sum(TaxSum) 'TaxSum',LineNum,DocEntry from PCH4 where statype not in (-100,-110,-150,-120) and RelateType =1 and ExpnsCode=-1  --added Other Tax
				group by taxrate,LineNum,DocEntry) OTHER ON OTHER.LineNum=t1.LineNum and OTHER.DocEntry=t1.DocEntry
WHERE T0.DocDate >= [%1]AND T0.DocDate <= [%2] AND T0.canceled = 'N'  
----------------------------------------------------------------------------------
Union all

SELECT T0.Docentry,
(CASE  T0.gsttrantyp when 'GA' then 'Gst Tax Invoice'
 when 'GD' then 'Gst Debit Memo'
 when '--' then 'Bill Of Supply' 
  end) 'GST Transaction Type',
 CONVERT(VARCHAR(10), T0.DocDate, 3) AS 'Invoice Date', T0.DocNum as 'Invoice No',
N1.SeriesName 'DocSeries',  N1.BeginStr 'DocSeriesPrefix', N1.EndStr 'DocSeriesSuffix',
SLP.SLPNAME 'SALES PERSON NAME',
T0.cardcode,
T0.CardName AS 'vendor Billing Name', 
T0.NumAtCard 'Vendor Bill No',
T7.BPGSTN 'Billing GSTIN', T7.LocStaGSTN 'State POS',  
'S' as 'ItemType',
'Freight' 'item code',
  T4.ExpnsName  AS 'Item Description', 
 (select SacCode from OEXD where T4.ExpnsName = OEXD.EXPNSNAME) as 'HSN/SAC Code',
1  'Quantity', 
T3.LineTotal  'Unit Price', T3.LineTotal  'ItemTotalBefDi',
Null 'Item Discount', T3.LineTotal 'Item Total After Discount',
T3.LineTotal AS 'Basic Line Total', 
T3.Linetotal  'Taxable Value',
T3.TaxCode,
isnull(CGST.taxRate,0) as 'CGST Rate',
isnull(CGST.TaxSum,0) AS 'CGST',
isnull(SGST.taxRate,0) as 'SGST/UGST Rate',
isnull(SGST.TaxSum,0) AS 'SGST/UGST', 
isnull(IGST.taxRate,0) as 'IGST Rate',
isnull(IGST.TaxSum,0) AS 'IGST',
isnull(OTHER.taxrate,0) as 'OTHER Rate', --other tax
Isnull(OTHER.taxsum,0) as 'OTHER', --other tax
(case when isnull(CGST.RvschrgTax,0) + isnull(SGST.RvschrgTax,0) + isnull(IGST.RvschrgTax,0)<> 0 then 'Y' else 'N' end) as 'Reverse Charge Flag',
isnull(CGST.RvschrgTax,0) as 'CGST Rev Tax',
isnull(SGST.RvschrgTax,0) as 'SGST/UGST Rev Tax',
isnull(IGST.RvschrgTax,0) as 'IGST Rev Tax',
isnull(T3.LineTotal,0)+isnull(CGST.TaxSum,0)+isnull(SGST.TaxSum,0)+isnull(IGST.TaxSum,0) as 'Total Incl GST',
T0.RevRefNo 'Original Invoice No', T0.RevRefDate 'Original Invoice Date', T7.BPGSTN 'Original vendor GSTIN',
null 'ECommGSTN',		
null 'AdvancePaymentDocDate',	
null 'AdvancePaymentDocNum',
T7.ImpORExp 'Flag Import Invoice',
Null as 'Import Type',
T7.ImpExpNo 'Bill of Entry No', T7.ImpExpDate 'Bill of Entry Date' , T7.BPCountry 'vendor Country',  
T7.BPGSTN 'vendor GSTNo', 
T0.Address 'Billing Address' , 
 T7.CityB 'Billing City', T7.ZipCodeB 'Billing Pin Code' , T7.StateB 'Billing State', T0.ShipToCode 'Shipping Name', 
T0.Address2 'Shipping Address',
T7.CityS 'Shipping City', T7.ZipCodeS 'Shipping Pin Code', T7.BPStateCod 'Shipping State', T7.BPStatGSTN 'Shipping State Code', 
MONTH(T0.RevRefDate) as 'Revision_Month',
 (CASE WHEN T0.DutyStatus = 'Y' THEN 'WPAY'
  ELSE 'WOPAY' 
  END ) 'Duty_Status',
Null as 'Port Code',
 (select GSTType from OGTY where absentry=T7.BPGSTType ) as 'Vendor GST Type',
T7.LocGSTN 'Location GSTNo', T7.LocStatCod 'Location State' , 
'AP Invoice' as 'Doc Type',
T0.DocDueDate 'Invoice Due Date',  
T0.Comments 
FROM OPCH T0 
left outer join OCRD on OCRD.CardCode=T0.CardCode
left outer join OCRG on OCRG.GroupCode=OCRD.GroupCode
LEFT OUTER JOIN OSLP SLP ON SLP.SLPCODE=T0.SLPCODE
Left Join CRD7 C7 On T0.CardCode =C7.CardCode And T0.ShipToCode = C7.Address and C7.AddrType = 'S'
left outer join NNM1 N1 on N1.Series=T0.Series 
INNER JOIN PCH3 T3 ON T0.DocEntry = T3.DocEntry 
left outer JOIN PCH12 T7 ON T0.DocEntry = T7.DocEntry 
Inner Join  OEXD T4 On T3.ExpnsCode = T4.ExpnsCode
Left Join PCH4 CGST ON T3.DocEntry = CGST.DocEntry And T3.ExpnsCode = CGST.ExpnsCode And CGST.StaType = -100 AND CGST.ExpnsCode<>-1
Left Join PCH4 SGST ON T3.DocEntry = SGST.DocEntry And T3.ExpnsCode = SGST.ExpnsCode And SGST.StaType in (-110,-150) AND SGST.ExpnsCode<>-1   --UGST Tax Added
Left Join PCH4 IGST ON T3.DocEntry = IGST.DocEntry And T3.ExpnsCode = IGST.ExpnsCode And IGST.StaType = -120 AND IGST.ExpnsCode<>-1
Left outer join (select taxrate,sum(TaxSum) 'TaxSum',ExpnsCode,DocEntry from PCH4 where statype not in (-100,-110,-150,-120) and ExpnsCode<>-1  --added Other Tax
				group by taxrate,ExpnsCode,DocEntry) OTHER ON OTHER.ExpnsCode=t3.ExpnsCode and OTHER.DocEntry=t3.DocEntry
WHERE T0.DocDate >= [%1]AND T0.DocDate <= [%2] AND T0.canceled = 'N' 
-------------------------------------------------------------------------------------------

union all

SELECT T0.Docentry,
(CASE  T0.gsttrantyp when 'GA' then 'Gst Tax Invoice'
 when 'GD' then 'Gst Debit Memo'
 when '--' then 'Bill Of Supply' 
  end) 'GST Transaction Type',
CONVERT(VARCHAR(10), T0.DocDate, 3) AS 'Invoice Date', T0.DocNum as 'Invoice No',
N1.SeriesName 'DocSeries',  N1.BeginStr 'DocSeriesPrefix', N1.EndStr 'DocSeriesSuffix',
SLP.SLPNAME 'SALES PERSON NAME',
T0.cardcode,
T0.CardName AS 'vendor Billing Name', 
T0.NumAtCard 'Vendor Bill No',
T7.BPGSTN 'Billing GSTIN', T7.LocStaGSTN 'State POS',  
(CASE WHEN T0.DocType = 'I' AND ITM.ItemClass = 2 THEN 'G' ELSE 'S' END) ItemType,
t1.itemcode 'item code',
T1.Dscription AS 'Item Description', 
(Case When T0.Doctype = 'I' Then 
(CASE When ITM.ItemClass = 1 Then (Select ServCode from OSAC Where AbsEntry =(case when  T1.HsnEntry is  null then  ITM.SACEntry else T1.SACEntry end))  
  When ITM.ItemClass  = 2 Then (select ChapterID  from ochp where AbsEntry = (case when  T1.HsnEntry is  null then  ITM.chapterid else T1.HsnEntry end)) Else '' END)      
  Else (Case When T0.DocType = 'S' Then (Select ServCode from OSAC Where AbsEntry = T1.SACEntry) END)
 END) 'HSN/SAC Code',
(case when T0.doctype='S' then 1*(-1) else T1.Quantity*(-1) end)'Quantity', 
(case when doctype='S' then T1.LineTotal else (T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end)) end)  'Unit Price',
(case when T0.doctype='S' then T1.LineTotal*(-1) else (t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end)))*(-1) end) 'ItemTotalBefDi',
(case when T0.doctype='S' then ((t1.Quantity*T1.linetotal)* T1.DiscPrcnt/100)+ (T1.Linetotal *T0.DiscPrcnt/100) else ((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end)))* T1.DiscPrcnt/100)+ 
(T1.Linetotal *T0.DiscPrcnt/100) end)*(-1)  'Item Discount',
(case when T0.doctype='S' then (T1.LineTotal)-(T1.Linetotal *T0.DiscPrcnt/100) else ((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) - 
(((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) * T1.DiscPrcnt/100) + (T1.Linetotal *T0.DiscPrcnt/100))) end)*(-1)  ' Item Total After Discount',
(case when T1.taxonly='Y' then 0 else  (CASE when isnull(T0.DiscPrcnt,0)=0 then isnull(T1.LineTotal,0) else (isnull(T1.LineTotal,0)-(isnull(T1.LineTotal,0)*isnull(T0.DiscPrcnt,0)/100)) End) end)*-1 AS 'Basic Line Total', --Tax only doclevel discount
(CASE WHEN  (T1.AssblValue > 0) THEN (T1.Quantity*T1.AssblValue*-1) ELSE  
((CASE when isnull(T0.DiscPrcnt,0)=0 then isnull(T1.LineTotal,0) else (isnull(T1.LineTotal,0)-(isnull(T1.LineTotal,0)*isnull(T0.DiscPrcnt,0)/100)) End)*-1) end) 'Taxable Value',
T1.TaxCode,
isnull(CGST.taxRate,0) as 'CGST Rate',
isnull(CGST.TaxSum,0)*(-1) AS 'CGST',
isnull(SGST.taxRate,0) as 'SGST/UGST Rate',
isnull(SGST.TaxSum,0)*(-1) AS 'SGST/UGST', 
isnull(IGST.taxRate,0)  as 'IGST Rate',
isnull(IGST.TaxSum,0)*(-1) AS 'IGST',
isnull(OTHER.taxrate,0) as 'OTHER Rate', --Other Tax
Isnull(OTHER.taxsum,0)*(-1) as 'OTHER', --Other tax
(case when isnull(CGST.RvschrgTax,0) + isnull(SGST.RvschrgTax,0) + Isnull(IGST.RvschrgTax,0)<> 0 then 'Y' else 'N' end) as 'Reverse Charge Flag',
isnull(CGST.RvschrgTax,0)*(-1) as 'CGST Rev Tax',
isnull(SGST.RvschrgTax,0)*(-1) as 'SGST/UGST Rev Tax',
isnull(IGST.RvschrgTax,0)*(-1) as 'IGST Rev Tax',
((case when T0.doctype='S' then (T1.Linetotal)-(T1.Linetotal *T0.DiscPrcnt/100) else ((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) - (((t1.Quantity*(T1.PriceBefDi*(case when T1.Rate = 0 then 1 else T1.Rate end))) * T1.DiscPrcnt/100) + (T1.Linetotal *T0.DiscPrcnt/100))) end) +isnull(CGST.TaxSum,0)+isnull(SGST.TaxSum,0)+isnull(IGST.TaxSum,0) )*(-1) as 'Total Incl GST',
T0.RevRefNo 'Original Invoice No', T0.RevRefDate 'Original Invoice Date', T7.BPGSTN 'Original vendor GSTIN',
null 'ECommGSTN',		
null 'AdvancePaymentDocDate',	
null 'AdvancePaymentDocNum',
T7.ImpORExp 'Flag Import Invoice',
Null as 'Import Type',
T7.ImpExpNo 'Bill of Entry No', T7.ImpExpDate 'Bill of Entry Date' , T7.BPCountry 'vendor Country',  
T7.BPGSTN 'vendor GSTNo', 
T0.Address 'Billing Address' , 
 T7.CityB 'Billing City', T7.ZipCodeB 'Billing Pin Code' , T7.StateB 'Billing State', T0.ShipToCode 'Shipping Name', 
T0.Address2 'Shipping Address',
T7.CityS 'Shipping City', T7.ZipCodeS 'Shipping Pin Code', T7.BPStateCod 'Shipping State', T7.BPStatGSTN 'Shipping State Code', 
MONTH(T0.RevRefDate) as 'Revision_Month',
(CASE WHEN T0.DutyStatus = 'Y' THEN 'WPAY' ELSE 'WOPAY' END) 'Duty_Status',
Null as 'Port Code',
(select GSTType from OGTY where absentry=T7.BPGSTType ) as 'Vendor GST Type',
T7.LocGSTN 'Location GSTNo',  T7.LocStatCod 'Location State' , 
'AP Credit Memo' as 'Doc Type',
T0.DocDueDate 'Invoice Due Date',  
T0.Comments 
FROM ORPC T0 
left outer join OCRD on OCRD.CardCode=T0.CardCode
left outer join OCRG on OCRG.GroupCode=OCRD.GroupCode
Left Join CRD7 C7 On T0.CardCode =C7.CardCode And T0.ShipToCode = C7.Address and C7.AddrType = 'S'
INNER JOIN RPC1 T1 ON T0.DocEntry = T1.DocEntry 
LEFT OUTER JOIN OSLP SLP ON SLP.SLPCODE=T0.SLPCODE
LEFT OUTER JOIN OITM ITM on (ITM.ItemCode = T1.ItemCode)
left outer join NNM1 N1 on N1.Series=T0.Series 
left outer JOIN RPC12 T7 ON T0.DocEntry = T7.DocEntry 
Left Join RPC4 CGST ON T1.DocEntry = CGST.DocEntry And T1.LineNum = CGST.LineNum And CGST.StaType = -100 AND CGST.RelateType = 1 AND CGST.ExpnsCode=-1
Left Join RPC4 SGST ON T1.DocEntry = SGST.DocEntry And T1.LineNum = SGST.LineNum And SGST.StaType in (-110,-150) AND SGST.RelateType = 1 AND SGST.ExpnsCode=-1 --UGST Tax Added
Left Join RPC4 IGST ON T1.DocEntry = IGST.DocEntry And T1.LineNum = IGST.LineNum And IGST.StaType = -120 AND IGST.RelateType = 1 AND IGST.ExpnsCode=-1
Left outer join (select taxrate,sum(TaxSum) 'TaxSum',LineNum,DocEntry from RPC4 where statype not in (-100,-110,-150,-120) and RelateType =1 and ExpnsCode=-1  --added Other Tax
				group by taxrate,LineNum,DocEntry) OTHER ON OTHER.LineNum=t1.LineNum and OTHER.DocEntry=t1.DocEntry
WHERE T0.DocDate >= [%1]AND T0.DocDate <= [%2] AND T0.canceled = 'N'   and t1.basetype<>204
-------------------------------------------------------------------------------

Union all
SELECT T0.Docentry,
(CASE  T0.gsttrantyp when 'GA' then 'Gst Tax Invoice'
 when 'GD' then 'Gst Debit Memo'
 when '--' then 'Bill Of Supply' 
  end) 'GST Transaction Type',
 CONVERT(VARCHAR(10), T0.DocDate, 3) AS 'Invoice Date', T0.DocNum as 'Invoice No',
N1.SeriesName 'DocSeries',  N1.BeginStr 'DocSeriesPrefix', N1.EndStr 'DocSeriesSuffix',
SLP.SLPNAME 'SALES PERSON NAME',
T0.cardcode,
T0.CardName AS 'vendor Billing Name', 
T0.NumAtCard 'Vendor Bill No',
T7.BPGSTN 'Billing GSTIN', T7.LocStaGSTN 'State POS',  
'S' as 'ItemType',
'Freight' 'item code',
 T4.ExpnsName  AS 'Item Description', 
  (select SacCode from OEXD where T4.ExpnsName = OEXD.EXPNSNAME) as 'HSN/SAC Code',
-1  'Quantity', 
T3.LineTotal  'Unit Price', T3.LineTotal*-1 'ItemTotalBefDi',
Null 'Item Discount', T3.LineTotal*-1 'Item Total After Discount',
T3.LineTotal*-1 AS 'Basic Line Total',
(T3.Linetotal *-1) 'Taxable Value',
T3.TaxCode, 
isnull(CGST.taxRate,0)  as 'CGST Rate',
isnull(CGST.TaxSum,0)*(-1) AS 'CGST',
isnull(SGST.taxRate,0)  as 'SGST/UGST Rate',
isnull(SGST.TaxSum,0)*(-1) AS 'SGST/UGST', 
isnull(IGST.taxRate,0)  as 'IGST Rate',
isnull(IGST.TaxSum,0)*(-1) AS 'IGST',
isnull(OTHER.taxrate,0) as 'OTHER Rate',
Isnull(OTHER.taxsum,0)*(-1) as 'OTHER',
(case when isnull(CGST.RvschrgTax,0) + isnull(SGST.RvschrgTax,0) + isnull(IGST.RvschrgTax,0)<> 0 then 'Y' else 'N' end) as 'Reverse Charge Flag',
isnull(CGST.RvschrgTax,0)*(-1) as 'CGST Rev Tax',	
isnull(SGST.RvschrgTax,0)*(-1) as 'SGST Rev Tax',
isnull(IGST.RvschrgTax,0)*(-1) as 'IGST Rev Tax',
(isnull(T3.LineTotal,0)+isnull(CGST.TaxSum,0)+isnull(SGST.TaxSum,0)+isnull(IGST.TaxSum,0))*(-1) as 'Total Incl GST',
T0.RevRefNo 'Original Invoice No', T0.RevRefDate 'Original Invoice Date', T7.BPGSTN 'Original vendor GSTIN', 
null 'ECommGSTN',		
null 'AdvancePaymentDocDate',	
null 'AdvancePaymentDocNum',
T7.ImpORExp 'Flag Import Invoice',
Null as 'Import Type',
T7.ImpExpNo 'Bill of Entry No', T7.ImpExpDate 'Bill of Entry Date' , T7.BPCountry 'vendor Country',  
T7.BPGSTN 'vendor GSTNo',
T0.Address 'Billing Address' , 
 T7.CityB 'Billing City', T7.ZipCodeB 'Billing Pin Code' , T7.StateB 'Billing State', T0.ShipToCode 'Shipping Name', 
T0.Address2 'Shipping Address',
T7.CityS 'Shipping City', T7.ZipCodeS 'Shipping Pin Code', T7.BPStateCod 'Shipping State', T7.BPStatGSTN 'Shipping State Code', 
MONTH(T0.RevRefDate) as 'Revision_Month',
 (CASE WHEN T0.DutyStatus = 'Y' THEN 'WPAY'
  ELSE 'WOPAY' 
  END ) 'Duty_Status',
Null as 'Port Code',
 (select GSTType from OGTY where absentry=T7.BPGSTType ) as 'Vendor GST Type',
T7.LocGSTN 'Location GSTNo',T7.LocStatCod 'Location State' , 
'AP Credit Memo' as 'Doc Type',
T0.DocDueDate 'Invoice Due Date',  
T0.Comments
FROM ORPC T0 
left outer join OCRD on OCRD.CardCode=T0.CardCode
left outer join OCRG on OCRG.GroupCode=OCRD.GroupCode
Left Join CRD7 C7 On T0.CardCode =C7.CardCode And T0.ShipToCode = C7.Address and C7.AddrType = 'S'
left outer  join NNM1 N1 on N1.Series=T0.Series 
INNER JOIN RPC3 T3 ON T0.DocEntry = T3.DocEntry and t3.BaseType<>204 --changes on 14052020
LEFT OUTER JOIN OSLP SLP ON SLP.SLPCODE=T0.SLPCODE
left outer JOIN RPC12 T7 ON T0.DocEntry = T7.DocEntry 
Inner Join  OEXD T4 On T3.ExpnsCode = T4.ExpnsCode
Left Join RPC4 CGST ON T3.DocEntry = CGST.DocEntry And T3.ExpnsCode = CGST.ExpnsCode And CGST.StaType = -100 AND CGST.ExpnsCode<>-1
Left Join RPC4 SGST ON T3.DocEntry = SGST.DocEntry And T3.ExpnsCode = SGST.ExpnsCode And SGST.StaType in (-110,-150) AND SGST.ExpnsCode<>-1 --UGST tax added
Left Join RPC4 IGST ON T3.DocEntry = IGST.DocEntry And T3.ExpnsCode = IGST.ExpnsCode And IGST.StaType = -120 AND IGST.ExpnsCode<>-1
Left outer join (select taxrate,sum(isnull(TaxSum,0)) 'TaxSum',ExpnsCode,DocEntry from RPC4 where statype not in (-100,-110,-150,-120) and ExpnsCode<>-1  --added Other Tax
				group by taxrate,ExpnsCode,DocEntry) OTHER ON OTHER.ExpnsCode=t3.ExpnsCode and OTHER.DocEntry=t3.DocEntry
WHERE T0.DocDate >= [%1]AND T0.DocDate <= [%2]AND T0.canceled = 'N'
) a order by a.docentry