alter PROCEDURE [dbo].[SALES_REGISTER_BILLWISE_GST_V1] 
	 @FromDate datetime,
     @ToDate datetime
	
AS
BEGIN
	SET NOCOUNT ON;
		select sr.[Docentry],sr.[Invoice No],sr.[Invoice Date],sr.[DEL No],sr.[DEL Date],
		sr.[Customer Ref No],sr.[Customer Code],sr.[Customer Name],
sr.[Invoice Value],sr.[Discount Amount],sr.[Net Amount],
sum(sr.[CGST]) 'CGST',
sum(sr.[SGST/UGST]) 'SGST/UGST',
sum(sr.[IGST]) 'IGST',
sum(sr.[OTHER TAX]) 'OTHER TAX',
sum(sr.[Total Fright DocL]) 'Total Fright DocL'
,sr.[Round Off],sr.[Doc Total],sr.Remarks,sr.[DocTotal FC],sr.[GSTIN No],sr.[currency] from (
select * from 
(select
OI.Docentry as 'DocEntry',
(case when ((n2.beginstr='' or n2.beginstr is null) and (n2.Endstr='' or n2.Endstr is null)) then ISNULL(N2.SeriesName+'/', N'')+ CAST(OI.DocNum AS CHAR(20)) else
isnull(n2.beginstr,'')+CAST(OI.DocNum AS CHAR(4))+isnull('/'+n2.endstr,'') end) 'Invoice No',
Cast(CONVERT(VARCHAR,OI.DocDate,105) as char(40)) as 'Invoice Date',
(select  SUBSTRING(
(SELECT  distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7))) + ', ' AS 'data()' 
FROM  ODLN inner join inv1  on  ODLN.Docentry=inv1.baseentry  and inv1.docentry=oi.docentry 
  left outer join  NNM1 on NNM1.Series=ODLN.Series
FOR XML PATH('')) ,1,len((SELECT distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7)) )+ ', ' AS 'data()'  
FROM  ODLN inner join inv1  on   ODLN.Docentry=inv1.baseentry  and inv1.docentry=oi.docentry 
left outer join  NNM1 on NNM1.Series=ODLN.Series
FOR XML PATH('') ))-1
))as 'DEL No',
(select  SUBSTRING(
(SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()' 
FROM  ODLN inner join inv1  on   ODLN.Docentry=inv1.baseentry
where inv1.docentry=oi.docentry
FOR XML PATH('')) ,1,len((SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()'  
FROM  ODLN inner join inv1  on   ODLN.Docentry=inv1.baseentry            
where inv1.docentry=oi.docentry
FOR XML PATH('') ))-1
))as 'DEL Date',
OI.NumAtCard as 'Customer Ref No',
 OI.CardCode as 'Customer Code', 
 OI.CardName as 'Customer Name',
 -----new code 
 (select  sum( case when INV1.taxonly='Y' then 0 else  isnull(INV1.LineTotal,0) end)
 from INV1 inner join OINV on inv1.Docentry=OINV.Docentry  where inv1.Docentry= oi.docentry group by inv1.Docentry,oinv.doccur)  as 'Invoice Value', --tax only t 09-05-2020
 isnull(OI.discSum,0) as 'Discount Amount',
(select  sum( case when INV1.taxonly='Y' then 0 else 
(CASE when isnull(OINV.DiscPrcnt,0)=0 then isnull(INV1.LineTotal,0) else (isnull(INV1.LineTotal,0)-(isnull(INV1.LineTotal,0)*isnull(OINV.DiscPrcnt,0)/100)) End) end)
 from INV1 inner join OINV on inv1.Docentry=OINV.Docentry  where inv1.Docentry= oi.docentry group by inv1.Docentry,oinv.doccur)  as 'Net Amount', --tax only doclevel discount 09-05-2020
 --Item Level Tax
 isnull(CGST.TaxSum,0) AS 'CGST', 
 isnull(SGST.TaxSum,0) AS 'SGST/UGST', 
 isnull(IGST.TaxSum,0) AS 'IGST',
 isnull(OTHER.TaxSum,0) AS 'OTHER TAX',
 --isnull(Oi.TotalExpns,0)  as 'Total Fright DocL',
 0 as 'Total Fright DocL', --changes for just freught only document on 15052020
 oi.rounddif as 'Round Off', 
(isnull(Oi.DocTotal,0)+isnull(oi.DpmAmnt,0)) as 'Doc Total',

 (select  crd1.gstRegnNo
 from crd1 inner join 
 ocrd on ocrd.cardcode=crd1.cardcode  where  ocrd.cardcode=oi.cardcode and crd1.AdresType='B' and oi.paytocode=crd1.Address)  'GSTIN No'
 ,Oi.Comments as 'Remarks',
 OI.DocCur as 'Currency',  
 (OI.DocTotalFc+oi.DpmAmntFC) as 'DocTotal FC'
 
from [dbo].[OINV] oi 
inner JOIN [dbo].[INV1] i1  ON  OI.DocEntry = I1.DocEntry --changes as per reliable if only fright is included not item 14/05/2020
LEFT OUTER JOIN OSTC O ON O.CODE = I1.TAXCODE 
left outer join OITM M1 ON I1.ItemCode=M1.ItemCode 

left outer JOIN ODLN OD on  I1.BASEENTRY = OD.DOCENTRY left outer JOIN NNM1 N1 ON N1.SERIES = OD.SERIES		
left outer JOIN NNM1 N2 ON N2.SERIES = OI.SERIES

left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry from inv4 CGST where CGST.Statype=-100 and CGST.ExpnsCode=-1 --for frrght only transaction
			group by docentry) as CGST on CGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from inv4 SGST where  SGST.Statype in (-110,-150) and SGST.ExpnsCode=-1 --for frrght only transaction
		  group by docentry) as SGST on SGST.docentry=oi.docentry --reverse charge --UGST
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from inv4 IGST where  IGST.Statype=-120  and IGST.ExpnsCode=-1 --for frrght only transaction
			group by docentry) as IGST on IGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from inv4 OTHER where  OTHER.Statype not in (-100,-110,-120,-150) and OTHER.ExpnsCode=-1 --for frrght only transaction
			group by docentry) as OTHER on OTHER.docentry=oi.docentry --OTHER AND reverse charge
LEFT OUTER JOIN  (SELECT     CardCode, Address, TaxId0, TaxId1, TaxId2, TaxId3 FROM  dbo.CRD7 AS crd7  WHERE     address <> '' AND  (AddrType = 'S')) AS crd7 ON OI.CardCode = crd7.CardCode AND OI.ShipToCode = crd7.Address    
where OI.CANCELED='N' and OI.DocDate>=@FromDate and Oi.DocDate<=@ToDate
 )sr group by sr.[DEL No],sr.[Invoice No],sr.[DEL Date],sr.[Invoice Date],sr.[currency],sr.[Customer Code],sr.[Customer Name],
sr.[Customer Ref No],sr.[Invoice Value],sr.[Docentry],sr.[Net Amount],sr.[Discount Amount],sr.[CGST],sr.[SGST/UGST],sr.[IGST],sr.[OTHER TAX],
sr.[Total Fright DocL],sr.[Round Off],sr.[Doc Total],sr.Remarks,sr.[DocTotal FC],sr.[GSTIN No]

Union all
---just only for freight only document
select
OI.Docentry as 'DocEntry',
(case when ((n2.beginstr='' or n2.beginstr is null) and (n2.Endstr='' or n2.Endstr is null)) then ISNULL(N2.SeriesName+'/', N'')+ CAST(OI.DocNum AS CHAR(20)) else
isnull(n2.beginstr,'')+CAST(OI.DocNum AS CHAR(4))+isnull('/'+n2.endstr,'') end) 'Invoice No',
Cast(CONVERT(VARCHAR,OI.DocDate,105) as char(40)) as 'Invoice Date',
(select  SUBSTRING(
(SELECT  distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7))) + ', ' AS 'data()' 
FROM  ODLN inner join inv1  on  ODLN.Docentry=inv1.baseentry  and inv1.docentry=oi.docentry 
  left outer join  NNM1 on NNM1.Series=ODLN.Series
FOR XML PATH('')) ,1,len((SELECT distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7)) )+ ', ' AS 'data()'  
FROM  ODLN inner join inv1  on   ODLN.Docentry=inv1.baseentry  and inv1.docentry=oi.docentry 
left outer join  NNM1 on NNM1.Series=ODLN.Series
FOR XML PATH('') ))-1
))as 'DEL No',
(select  SUBSTRING(
(SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()' 
FROM  ODLN inner join inv1  on   ODLN.Docentry=inv1.baseentry
where inv1.docentry=oi.docentry
FOR XML PATH('')) ,1,len((SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()'  
FROM  ODLN inner join inv1  on   ODLN.Docentry=inv1.baseentry            
where inv1.docentry=oi.docentry
FOR XML PATH('') ))-1
))as 'DEL Date',
OI.NumAtCard as 'Customer Ref No',
 OI.CardCode as 'Customer Code', 
 OI.CardName as 'Customer Name',
 -----new code 
 (select  sum( case when INV1.taxonly='Y' then 0 else  isnull(INV1.LineTotal,0) end)
 from INV1 inner join OINV on inv1.Docentry=OINV.Docentry  where inv1.Docentry= oi.docentry group by inv1.Docentry,oinv.doccur)  as 'Invoice Value', --tax only t 09-05-2020
 isnull(OI.discSum,0) as 'Discount Amount',
(select  sum( case when INV1.taxonly='Y' then 0 else 
(CASE when isnull(OINV.DiscPrcnt,0)=0 then isnull(INV1.LineTotal,0) else (isnull(INV1.LineTotal,0)-(isnull(INV1.LineTotal,0)*isnull(OINV.DiscPrcnt,0)/100)) End) end)
 from INV1 inner join OINV on inv1.Docentry=OINV.Docentry  where inv1.Docentry= oi.docentry group by inv1.Docentry,oinv.doccur)  as 'Net Amount', --tax only doclevel discount 09-05-2020
 --Item Level Tax
 isnull(CGST.TaxSum,0) AS 'CGST', 
 isnull(SGST.TaxSum,0) AS 'SGST/UGST', 
 isnull(IGST.TaxSum,0) AS 'IGST',
 isnull(OTHER.TaxSum,0) AS 'OTHER TAX',
isnull(Oi.TotalExpns,0)  as 'Total Fright DocL',--changes for just freught only document on 15052020
 oi.rounddif as 'Round Off', 
(isnull(Oi.DocTotal,0)+isnull(oi.DpmAmnt,0)) as 'Doc Total',

 (select  crd1.gstRegnNo
 from crd1 inner join 
 ocrd on ocrd.cardcode=crd1.cardcode  where  ocrd.cardcode=oi.cardcode and crd1.AdresType='B' and oi.paytocode=crd1.Address)  'GSTIN No'
 ,Oi.Comments as 'Remarks',
 OI.DocCur as 'Currency',  
 (OI.DocTotalFc+oi.DpmAmntFC) as 'DocTotal FC'
 
from [dbo].[OINV] oi 
left outer JOIN NNM1 N2 ON N2.SERIES = OI.SERIES
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry from inv4 CGST where CGST.Statype=-100 and CGST.ExpnsCode<>-1 --for frrght only transaction
			group by docentry) as CGST on CGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from inv4 SGST where  SGST.Statype in (-110,-150) and SGST.ExpnsCode<>-1 --for frrght only transaction
		  group by docentry) as SGST on SGST.docentry=oi.docentry --reverse charge --UGST
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from inv4 IGST where  IGST.Statype=-120  and IGST.ExpnsCode<>-1 --for frrght only transaction
			group by docentry) as IGST on IGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from inv4 OTHER where  OTHER.Statype not in (-100,-110,-120,-150) and OTHER.ExpnsCode<>-1 --for frrght only transaction
			group by docentry) as OTHER on OTHER.docentry=oi.docentry --OTHER AND reverse charge	
INNER join(select INV3.docentry, sum(case when INV3.Fixcurr='INR' then isnull((INV3.LineTotal),0) else isnull((INV3.totalsumsy),0) end) as DocLevFreight
from INV3 where INV3.ExpnsCode!='' Group by INV3.docentry ) DocLevFreight  on oi.docentry=DocLevFreight.docentry 
LEFT OUTER JOIN  (SELECT     CardCode, Address, TaxId0, TaxId1, TaxId2, TaxId3 FROM  dbo.CRD7 AS crd7  WHERE     address <> '' AND  (AddrType = 'S')) AS crd7 ON OI.CardCode = crd7.CardCode AND OI.ShipToCode = crd7.Address    
where OI.CANCELED='N' and OI.DocDate>=@FromDate and Oi.DocDate<=@ToDate
--------------------------------------------------------------------------------------------------------------------------
union all

select * from (select
OI.Docentry as 'DocEntry',
(case when ((n2.beginstr='' or n2.beginstr is null) and (n2.Endstr='' or n2.Endstr is null)) then ISNULL(N2.SeriesName+'/', N'')+ CAST(OI.DocNum AS CHAR(20)) else
isnull(n2.beginstr,'')+CAST(OI.DocNum AS CHAR(4))+isnull('/'+n2.endstr,'') end) 'Invoice No',
Cast(CONVERT(VARCHAR,OI.DocDate,105) as char(10)) as 'Invoice Date',
(select  SUBSTRING(
(SELECT  distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7))) + ', ' AS 'data()' 
FROM  ODLN inner join RIN1  on  ODLN.Docentry=RIN1.baseentry  and RIN1.docentry=oi.docentry 
  left outer join  NNM1 on NNM1.Series=ODLN.Series          
FOR XML PATH('')) ,1,len((SELECT distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7)) )+ ', ' AS 'data()'  
FROM  ODLN inner join RIN1  on   ODLN.Docentry=RIN1.baseentry  and RIN1.docentry=oi.docentry 
left outer join  NNM1 on NNM1.Series=ODLN.Series
FOR XML PATH('') ))-1))as 'DEL No',
(select  SUBSTRING(
(SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()' 
FROM  ODLN inner join RIN1  on   ODLN.Docentry=RIN1.baseentry
where RIN1.docentry=oi.docentry
FOR XML PATH('')) ,1,len((SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()'  
FROM  ODLN inner join RIN1  on   ODLN.Docentry=RIN1.baseentry                     
 where RIN1.docentry=oi.docentry
FOR XML PATH('') ))-1))as 'DEL Date',
 OI.NumAtCard as 'Customer Ref No',
 OI.CardCode as 'Customer Code', 
 OI.CardName as 'Customer Name',
  ---new code
  (select  sum(case when RIN1.taxonly='Y' then 0 else  isnull(RIN1.LineTotal,0) end)
 from RIN1 inner join ORIN on RIN1.Docentry=ORIN.Docentry  where RIN1.Docentry= oi.docentry group by RIN1.Docentry,oRIN.doccur)  *(-1) as 'Invoice Value', --tax only 09-05-2020
 isnull(OI.discSum,0) *(-1) as 'Discount Amount',
(select  sum( case when RIN1.taxonly='Y' then 0 else 
(CASE when isnull(ORIN.DiscPrcnt,0)=0 then isnull(RIN1.LineTotal,0) else (isnull(RIN1.LineTotal,0)-(isnull(RIN1.LineTotal,0)*isnull(ORIN.DiscPrcnt,0)/100)) End)
 end )from RIN1 inner join ORIN on RIN1.Docentry=ORIN.Docentry  where RIN1.Docentry= oi.docentry group by RIN1.Docentry,oRIN.doccur) *(-1) as 'Net Amount', --tax only doclevel discount 09-05-2020
 isnull(CGST.TaxSum,0)*(-1) AS 'CGST', 
 isnull(SGST.TaxSum,0)*(-1) AS 'SGST/UGST', 
 isnull(IGST.TaxSum,0)*(-1) AS 'IGST',
 isnull(OTHER.TaxSum,0)*(-1) AS 'OTHER TAX',
 0 as 'Total Fright DocL', 
 oi.RoundDif*(-1) as 'Round Off',
(isnull(Oi.DocTotal,0)+isnull(oi.DpmAmnt,0)) *(-1) as 'Doc Total',
 (select  crd1.gstRegnNo
 from crd1 inner join 
 ocrd on ocrd.cardcode=crd1.cardcode  where  ocrd.cardcode=oi.cardcode and crd1.AdresType='B' and oi.PayToCode=crd1.Address)  'GSTIN No'
, Oi.Comments as 'Remarks',
 OI.DocCur as 'Currency',
 (OI.DocTotalFc+oi.DpmAmntFC)  *(-1) as 'DocTotal FC'
from [dbo].[ORIN] oi 
INNER JOIN [dbo].[RIN1] i1  ON  OI.DocEntry = I1.DocEntry 
LEFT OUTER JOIN OSTC O ON O.CODE = I1.TAXCODE 
LEFT outer join OITM M1 ON I1.ItemCode=M1.ItemCode 	
left outer JOIN NNM1 N2 ON N2.SERIES = OI.SERIES

left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry from rin4 CGST where CGST.Statype=-100 and CGST.ExpnsCode=-1
			group by docentry) as CGST on CGST.docentry=i1.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from rin4 SGST where  SGST.Statype in (-110,-150) and sgst.ExpnsCode=-1 
			group by docentry) as SGST on SGST.docentry=i1.docentry --reverse charge --UGST
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from rin4 IGST where  IGST.Statype=-120 and IGST.ExpnsCode=-1 
			group by docentry) as IGST on IGST.docentry=i1.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from rin4 OTHER where  OTHER.Statype not in (-100,-110,-120,-150) and OTHER.ExpnsCode=-1 
			group by docentry) as OTHER on OTHER.docentry=i1.docentry --OTHER AND reverse charge

left outer join (select RIN2.docentry, sum(case when RIN2.Fixcurr='INR' then isnull((RIN2.LineTotal),0) else isnull((RIN2.Totalsumsy),0) end) as LLFreTot 		
from RIN2 where RIN2.ExpnsCode!=''  Group by RIN2.docentry) LLFreTot  on I1.docentry=LLFreTot.docentry --and ItmCST.TaxType IN (4) and ItmCST.RelateType =1

--left outer join(select RIN3.docentry, sum(case when RIN3.Fixcurr='INR' then isnull((RIN3.LineTotal),0) else isnull((RIN3.Totalsumsy),0) end) as DocLevFreight
--from RIN3 where RIN3.ExpnsCode!='' and RIn3.basetype<>203 Group by RIN3.docentry ) DocLevFreight  on oi.docentry=DocLevFreight.docentry --basetype<>203 14052020

LEFT OUTER JOIN  (SELECT     CardCode, Address, TaxId0, TaxId1, TaxId2, TaxId3 FROM  dbo.CRD7 AS crd7  WHERE     address <> '' AND  (AddrType = 'S')) AS crd7 ON OI.CardCode = crd7.CardCode AND OI.ShipToCode = crd7.Address    
where OI.CANCELED='N' and OI.DocDate>=@FromDate and Oi.DocDate<=@ToDate and i1.basetype<>203  --09-05-2020  

 )sr group by sr.[DEL No],sr.[Invoice No],sr.[DEL Date],sr.[Invoice Date],sr.[currency],sr.[Customer Code],sr.[Customer Name],
sr.[Customer Ref No],sr.[Invoice Value],sr.[Docentry],sr.[Net Amount],sr.[Discount Amount],sr.[CGST],sr.[SGST/UGST],sr.[IGST],sr.[OTHER TAX],
sr.[Total Fright DocL],sr.[Round Off],sr.[Doc Total],sr.Remarks,sr.[DocTotal FC],sr.[GSTIN No]

UNION all

select
OI.Docentry as 'DocEntry',
(case when ((n2.beginstr='' or n2.beginstr is null) and (n2.Endstr='' or n2.Endstr is null)) then ISNULL(N2.SeriesName+'/', N'')+ CAST(OI.DocNum AS CHAR(20)) else
isnull(n2.beginstr,'')+CAST(OI.DocNum AS CHAR(4))+isnull('/'+n2.endstr,'') end) 'Invoice No',
Cast(CONVERT(VARCHAR,OI.DocDate,105) as char(10)) as 'Invoice Date',
(select  SUBSTRING(
(SELECT  distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7))) + ', ' AS 'data()' 
FROM  ODLN inner join RIN1  on  ODLN.Docentry=RIN1.baseentry  and RIN1.docentry=oi.docentry 
  left outer join  NNM1 on NNM1.Series=ODLN.Series          
FOR XML PATH('')) ,1,len((SELECT distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(ODLN.DocNum AS CHAR(7)) )+ ', ' AS 'data()'  
FROM  ODLN inner join RIN1  on   ODLN.Docentry=RIN1.baseentry  and RIN1.docentry=oi.docentry 
left outer join  NNM1 on NNM1.Series=ODLN.Series
FOR XML PATH('') ))-1))as 'DEL No',
(select  SUBSTRING(
(SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()' 
FROM  ODLN inner join RIN1  on   ODLN.Docentry=RIN1.baseentry
where RIN1.docentry=oi.docentry
FOR XML PATH('')) ,1,len((SELECT  Distinct Cast(CONVERT(VARCHAR,ODLN.DocDate,105) as char(40)) + ', ' AS 'data()'  
FROM  ODLN inner join RIN1  on   ODLN.Docentry=RIN1.baseentry                     
 where RIN1.docentry=oi.docentry
FOR XML PATH('') ))-1))as 'DEL Date',
 OI.NumAtCard as 'Customer Ref No',
 OI.CardCode as 'Customer Code', 
 OI.CardName as 'Customer Name',
  ---new code
  (select  sum(case when RIN1.taxonly='Y' then 0 else  isnull(RIN1.LineTotal,0) end)
 from RIN1 inner join ORIN on RIN1.Docentry=ORIN.Docentry  where RIN1.Docentry= oi.docentry group by RIN1.Docentry,oRIN.doccur)  *(-1) as 'Invoice Value', --tax only 09-05-2020
 isnull(OI.discSum,0) *(-1) as 'Discount Amount',
(select  sum( case when RIN1.taxonly='Y' then 0 else 
(CASE when isnull(ORIN.DiscPrcnt,0)=0 then isnull(RIN1.LineTotal,0) else (isnull(RIN1.LineTotal,0)-(isnull(RIN1.LineTotal,0)*isnull(ORIN.DiscPrcnt,0)/100)) End)
 end )from RIN1 inner join ORIN on RIN1.Docentry=ORIN.Docentry  where RIN1.Docentry= oi.docentry group by RIN1.Docentry,oRIN.doccur) *(-1) as 'Net Amount', --tax only doclevel discount 09-05-2020
 isnull(CGST.TaxSum,0)*(-1) AS 'CGST', 
 isnull(SGST.TaxSum,0)*(-1) AS 'SGST/UGST', 
 isnull(IGST.TaxSum,0)*(-1) AS 'IGST',
 isnull(OTHER.TaxSum,0)*(-1) AS 'OTHER TAX',
 isnull(Oi.TotalExpns,0)*(-1)as 'Total Fright DocL', 
 oi.RoundDif*(-1) as 'Round Off',
(isnull(Oi.DocTotal,0)+isnull(oi.DpmAmnt,0)) *(-1) as 'Doc Total',
 (select  crd1.gstRegnNo
 from crd1 inner join 
 ocrd on ocrd.cardcode=crd1.cardcode  where  ocrd.cardcode=oi.cardcode and crd1.AdresType='B' and oi.PayToCode=crd1.Address)  'GSTIN No'
, Oi.Comments as 'Remarks',
 OI.DocCur as 'Currency',
 (OI.DocTotalFc+oi.DpmAmntFC)  *(-1) as 'DocTotal FC'
from [dbo].[ORIN] oi 
left outer JOIN NNM1 N2 ON N2.SERIES = OI.SERIES

left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry from rin4 CGST where CGST.Statype=-100 and CGST.ExpnsCode<>-1 --for frrght only transaction
			group by docentry) as CGST on CGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from rin4 SGST where  SGST.Statype in (-110,-150) and sgst.ExpnsCode<>-1  --for frrght only transaction
			group by docentry) as SGST on SGST.docentry=oi.docentry --reverse charge --UGST
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from rin4 IGST where  IGST.Statype=-120 and IGST.ExpnsCode<>-1  --for frrght only transaction
			group by docentry) as IGST on IGST.docentry=oi	.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from rin4 OTHER where  OTHER.Statype not in (-100,-110,-120,-150) and OTHER.ExpnsCode<>-1  --for frrght only transaction
			group by docentry) as OTHER on OTHER.docentry=oi.docentry --OTHER AND reverse charge

left outer join (select RIN2.docentry, sum(case when RIN2.Fixcurr='INR' then isnull((RIN2.LineTotal),0) else isnull((RIN2.Totalsumsy),0) end) as LLFreTot 		
from RIN2 where RIN2.ExpnsCode!=''  Group by RIN2.docentry) LLFreTot  on oi.docentry=LLFreTot.docentry --and ItmCST.TaxType IN (4) and ItmCST.RelateType =1

INNER join(select RIN3.docentry, sum(case when RIN3.Fixcurr='INR' then isnull((RIN3.LineTotal),0) else isnull((RIN3.Totalsumsy),0) end) as DocLevFreight
from RIN3 where RIN3.ExpnsCode!='' and RIn3.basetype<>203 Group by RIN3.docentry ) DocLevFreight  on oi.docentry=DocLevFreight.docentry --basetype<>203 14052020

LEFT OUTER JOIN  (SELECT     CardCode, Address, TaxId0, TaxId1, TaxId2, TaxId3 FROM  dbo.CRD7 AS crd7  WHERE     address <> '' AND  (AddrType = 'S')) AS crd7 ON OI.CardCode = crd7.CardCode AND OI.ShipToCode = crd7.Address    
where OI.CANCELED='N' and OI.DocDate>=@FromDate and Oi.DocDate<=@ToDate		
) as sr
group by sr.[DEL No],sr.[Invoice No],sr.[DEL Date],sr.[Invoice Date],sr.[currency],sr.[Customer Code],sr.[Customer Name],
sr.[Customer Ref No],sr.[Invoice Value],sr.[Docentry],sr.[Net Amount],sr.[Discount Amount]
--,sr.[CGST],sr.[SGST/UGST],sr.[IGST],sr.[OTHER TAX],sr.[Total Fright DocL]
,sr.[Round Off],sr.[Doc Total],sr.Remarks,sr.[DocTotal FC],sr.[GSTIN No]
order by sr.[Invoice Date]
END
GO


