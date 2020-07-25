alter PROCEDURE [dbo].[PURCHASE_REGISTER_BILLWISE_GST] 

	 @FromDate datetime,
     @ToDate datetime
     	
AS
BEGIN
	SET NOCOUNT ON;
		select * from (
select
OI.Docentry as 'DocEntry',
(case when ((n2.beginstr='' or n2.beginstr is null) and (n2.Endstr='' or n2.Endstr is null)) then ISNULL(N2.SeriesName+'/', N'')+ CAST(OI.DocNum AS CHAR(20)) else
isnull(n2.beginstr+'/','')+CAST(OI.DocNum AS CHAR(4))+isnull('/'+n2.endstr,'') end) 'Invoice No',
Cast(CONVERT(VARCHAR,OI.DocDate,105) as char(40)) as 'Invoice Date',
(select  SUBSTRING(
(SELECT  distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(OPDN.DocNum AS CHAR(7))) + ', ' AS 'data()' 
FROM  OPDN inner join PCH1  on  OPDN.Docentry=PCH1.baseentry  and PCH1.docentry=oi.docentry 
  left outer join  NNM1 on NNM1.Series=OPDN.Series
FOR XML PATH('')) ,1,len((SELECT distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(OPDN.DocNum AS CHAR(7)) )+ ', ' AS 'data()'  
FROM  OPDN inner join PCH1  on   OPDN.Docentry=PCH1.baseentry  and PCH1.docentry=oi.docentry 
left outer join  NNM1 on NNM1.Series=OPDN.Series
FOR XML PATH('') ))-1))as 'GRN No',
(select  SUBSTRING(
(SELECT  Distinct Cast(CONVERT(VARCHAR,OPDN.DocDate,105) as char(40)) + ', ' AS 'data()' 
FROM  OPDN inner join PCH1  on   OPDN.Docentry=PCH1.baseentry         
            where PCH1.docentry=oi.docentry
FOR XML PATH('')) ,1,len((SELECT  Distinct Cast(CONVERT(VARCHAR,OPDN.DocDate,105) as char(40)) + ', ' AS 'data()'  
FROM  OPDN inner join PCH1  on   OPDN.Docentry=PCH1.baseentry                      
 where PCH1.docentry=oi.docentry
FOR XML PATH('') ))-1))as 'GRN Date',
(case when OI.DocType='I' then 'ITEM' else 'SERVCE' end )as 'Document Type',
OI.NumAtCard as 'Vendor Ref No',
 OI.CardCode as 'Vendor Code', 
 OI.CardName as 'Vendor Name',
 
 -----Invoice Value 
 (select  
		sum(case when pch1.taxonly='Y' then 0 else  isnull(PCH1.LineTotal,0) end ) 
 from PCH1 inner join OPCH on PCH1.Docentry=OPCH.Docentry  
 where PCH1.Docentry= oi.docentry group by PCH1.Docentry)  as 'Invoice Value',--tax only  09-05-2020
 -----Discount Amount
 isnull(OI.discSum,0) as 'Discount Amount',
----Net Amount 
ISNULL((select  sum( case when pch1.taxonly='Y' then 0 else 
(CASE when isnull(OPCH.DiscPrcnt,0)=0 then isnull(PCH1.LineTotal,0) else (isnull(PCH1.LineTotal,0)-(isnull(PCH1.LineTotal,0)*isnull(OPCH.DiscPrcnt,0)/100)) End)
 end)
 from PCH1 inner join OPCH on PCH1.Docentry=OPCH.Docentry  where PCH1.Docentry= oi.docentry group by PCH1.Docentry),0) as 'Net Amount', --tax only doclevel discount 09-05-2020
 --Item Level Tax
 isnull(CGST.TaxSum,0) AS 'CGST', 
 isnull(SGST.TaxSum,0) AS 'SGST/UGST', 
 isnull(IGST.TaxSum,0) AS 'IGST',
 isnull(OTHER.TaxSum,0) AS 'OTHER TAX', --Other Tax
 isnull(Oi.TotalExpns,0)  as 'Total Fright DocL',
  T1.[WTAmnt] as TDS,
 oi.rounddif as 'Round Off', 
 isnull(Oi.DocTotal,0)+isnull(oi.DpmAmnt,0) as 'Doc Total',
  (select  crd1.gstRegnNo from crd1 inner join ocrd on ocrd.cardcode=crd1.cardcode  where  ocrd.cardcode=oi.cardcode and crd1.AdresType='B' and oi.paytocode=crd1.Address)  'GSTIN No',
 Oi.Comments as 'Remarks',
 OI.DocCur as 'Currency',  
 (OI.DocTotalFc+oi.DpmAmntFC) as 'DocTotal FC' --09-05-2020 Downpaymnet
 
from [dbo].[OPCH] oi 
INNER JOIN [dbo].[PCH1] i1  ON  OI.DocEntry = I1.DocEntry 
LEFT OUTER JOIN OSTC O ON O.CODE = I1.TAXCODE 
Left join OITM M1 ON I1.ItemCode=M1.ItemCode --and M1.itmsGrpCod Not IN(123)
LEFT OUTER JOIN PCH5 T1 ON oi.DocEntry = T1.AbsEntry  
left outer JOIN OPDN OD on  I1.BASEENTRY = OD.DOCENTRY 
left outer JOIN NNM1 N1 ON N1.SERIES = OD.SERIES		
left outer JOIN NNM1 N2 ON N2.SERIES = OI.SERIES
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry from PCH4 CGST where CGST.Statype=-100 group by docentry) as CGST on CGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from PCH4 SGST where  SGST.Statype in (-110,-150) group by docentry) as SGST on SGST.docentry=oi.docentry --reverse charge --UGST
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from PCH4 IGST where  IGST.Statype=-120 group by docentry) as IGST on IGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from PCH4 OTHER where  OTHER.Statype not in (-100,-110,-120,-150) group by docentry) as OTHER on OTHER.docentry=oi.docentry --OTHER AND reverse charge

left outer join(select PCH3.docentry, sum(case when PCH3.Fixcurr='INR' then isnull((PCH3.LineTotal),0) else isnull((PCH3.totalsumsy),0) end) as DocLevFreight
from PCH3 where PCH3.ExpnsCode!='' Group by PCH3.docentry ) DocLevFreight  on I1.docentry=DocLevFreight.docentry 
LEFT OUTER JOIN  (SELECT CardCode, Address, TaxId0, TaxId1, TaxId2, TaxId3 FROM  CRD7 AS crd7  
					WHERE address <> '' AND  (AddrType = 'S')) AS crd7 ON OI.CardCode = crd7.CardCode AND OI.ShipToCode = crd7.Address    
where OI.CANCELED='N'and OI.DocType IN('I','S') and OI.DocDate>=@FromDate and Oi.DocDate<=@ToDate
--------------------------------------------------------------------------------------------------------------------------
union all

select
OI.Docentry as 'DocEntry',
(case when ((n2.beginstr='' or n2.beginstr is null) and (n2.Endstr='' or n2.Endstr is null)) then ISNULL(N2.SeriesName+'/', N'')+ CAST(OI.DocNum AS CHAR(20)) else
isnull(n2.beginstr,'')+CAST(OI.DocNum AS CHAR(4))+isnull('/'+n2.endstr,'') end) 'Invoice No',
Cast(CONVERT(VARCHAR,OI.DocDate,105) as char(10)) as 'Invoice Date',
(select  SUBSTRING((SELECT  distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(OPDN.DocNum AS CHAR(7))) + ', ' AS 'data()' 
FROM  OPDN inner join RPC1  on  OPDN.Docentry=RPC1.baseentry  and RPC1.docentry=oi.docentry 
  left outer join  NNM1 on NNM1.Series=OPDN.Series
  FOR XML PATH('')) ,1,len((SELECT distinct ISNULL(NNM1.SeriesName, N'')+'/'+ ( Cast(OPDN.DocNum AS CHAR(7)) )+ ', ' AS 'data()'  
FROM  OPDN inner join RPC1  on   OPDN.Docentry=RPC1.baseentry  and RPC1.docentry=oi.docentry 
left outer join  NNM1 on NNM1.Series=OPDN.Series
FOR XML PATH('') ))-1))as 'GRN No',
(select  SUBSTRING((SELECT  Distinct Cast(CONVERT(VARCHAR,OPDN.DocDate,105) as char(40)) + ', ' AS 'data()' 
FROM  OPDN inner join RPC1  on OPDN.Docentry=RPC1.baseentry
where RPC1.docentry=oi.docentry
FOR XML PATH('')) ,1,len((SELECT  Distinct Cast(CONVERT(VARCHAR,OPDN.DocDate,105) as char(40)) + ', ' AS 'data()'  
FROM  OPDN inner join RPC1  on OPDN.Docentry=RPC1.baseentry                   
 where RPC1.docentry=oi.docentry FOR XML PATH('') ))-1))as 'GRN Date',
(case when OI.DocType='I' then 'ITEM' else 'SERVCE' end )as 'Document Type',
 OI.NumAtCard as 'Vendor Ref No',
 OI.CardCode as 'Vendor Code', 
 OI.CardName as 'Vendor Name',
  ---new code
  (select  sum(case when RPC1.taxonly='Y' then 0 else   isnull(RPC1.LineTotal,0) end ) 
	from RPC1 
	inner join ORPC on RPC1.Docentry=ORPC.Docentry  where RPC1.Docentry= oi.docentry group by RPC1.Docentry,ORPC.doccur)  *(-1) as 'Invoice Value', --tax only  09-05-2020
 isnull(OI.discSum,0) *(-1) as 'Discount Amount',
ISNULL((select  sum(case when RPC1.taxonly='Y' then 0 else 
(CASE when isnull(ORPC.DiscPrcnt,0)=0 then isnull(RPC1.LineTotal,0) else (isnull(RPC1.LineTotal,0)-(isnull(RPC1.LineTotal,0)*isnull(ORPC.DiscPrcnt,0)/100)) End) end)
 from RPC1 inner join ORPC on RPC1.Docentry=ORPC.Docentry  
 where RPC1.Docentry= oi.docentry group by RPC1.Docentry,ORPC.doccur),0) *(-1) as 'Net Amount', --tax only doc level discount 09-05-2020
 isnull(CGST.TaxSum,0)*(-1) AS 'CGST', 
 isnull(SGST.TaxSum,0)*(-1) AS 'SGST/UGST', 
 isnull(IGST.TaxSum,0)*(-1) AS 'IGST',
 isnull(OTHER.TaxSum,0)*(-1) AS 'OTHER TAX', --Other Tax
 isnull(Oi.TotalExpns,0)*(-1)as 'Total Fright DocL', 
  T1.[WTAmnt]*(-1) as TDS,
 oi.rounddif*(-1) as 'Round Off',
(isnull(Oi.DocTotal,0)+isnull(oi.DpmAmnt,0)) *(-1) as 'Doc Total',
 (select  crd1.gstRegnNo from crd1 inner join 
 ocrd on ocrd.cardcode=crd1.cardcode  where  ocrd.cardcode=oi.cardcode and crd1.AdresType='B' and oi.paytocode=crd1.Address)  'GSTIN No',
 Oi.Comments as 'Remarks',
 OI.DocCur as 'Currency',
 (OI.DocTotalFc+oi.DpmAmntFC)  *(-1) as 'DocTotal FC' --09-05-2020 downpayment
  
from [dbo].[ORPC] oi 
INNER JOIN [dbo].[RPC1] i1  ON  OI.DocEntry = I1.DocEntry --if only Freight included in document reliable 184 ORPC 14052020
LEFT OUTER JOIN OSTC O ON O.CODE = I1.TAXCODE 
left join OITM M1 ON I1.ItemCode=M1.ItemCode  
left outer JOIN OPDN OD on  I1.BASEENTRY = OD.DOCENTRY 
left outer JOIN NNM1 N1 ON N1.SERIES = OD.SERIES		
left outer JOIN NNM1 N2 ON N2.SERIES = OI.SERIES
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry from RPC4 CGST where CGST.Statype=-100 group by docentry) as CGST on CGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from RPC4 SGST where  SGST.Statype in (-110,-150) group by docentry) as SGST on SGST.docentry=oi.docentry --reverse charge --UGST
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from RPC4 IGST where  IGST.Statype=-120 group by docentry) as IGST on IGST.docentry=oi.docentry --reverse charge
left join (select (SUM(ISNULL(TaxSum, 0)) -sum(ISNULL(RvsChrgTax,0))) 'TaxSum',docentry  from RPC4 OTHER where  OTHER.Statype not in (-100,-110,-120,-150) group by docentry) as OTHER on OTHER.docentry=oi.docentry --OTHER AND reverse charge
left outer join (select RPC2.docentry, sum(case when RPC2.Fixcurr='INR' then isnull((RPC2.LineTotal),0) else isnull((RPC2.Totalsumsy),0) end) as LLFreTot 		
from RPC2 where RPC2.ExpnsCode!=''  Group by RPC2.docentry) LLFreTot  on I1.docentry=LLFreTot.docentry --and ItmCST.TaxType IN (4) and ItmCST.RelateType =1
left outer join(select RPC3.docentry, sum(case when RPC3.Fixcurr='INR' then isnull((RPC3.LineTotal),0) else isnull((RPC3.Totalsumsy),0) end) as DocLevFreight
from RPC3 where RPC3.ExpnsCode!='' and RPC3.basetype<>204 Group by RPC3.docentry ) DocLevFreight  on oi.docentry=DocLevFreight.docentry 
left outer JOIN rpc5 T1 ON oi.DocEntry = T1.AbsEntry  
LEFT OUTER JOIN  (SELECT     CardCode, Address, TaxId0, TaxId1, TaxId2, TaxId3 FROM  CRD7 AS crd7  
				 WHERE  address <> '' AND  (AddrType = 'S')) AS crd7 ON OI.CardCode = crd7.CardCode AND OI.ShipToCode = crd7.Address    
where OI.CANCELED='N'and OI.DocType IN('I','S') and OI.DocDate>=@FromDate and Oi.DocDate<=@ToDate  and i1.basetype<>204 --09052020
  
) as sr
group by sr.[GRN No],sr.[Invoice No],sr.[GRN Date],sr.[Invoice Date],sr.[currency],sr.[Document Type],sr.[Vendor Code],
sr.[Vendor Name],sr.[Vendor Ref No],sr.[Invoice Value],sr.[Docentry],sr.[Net Amount],sr.[Discount Amount],sr.[CGST],sr.[SGST/UGST],sr.[IGST],sr.[OTHER TAX],
sr.[Total Fright DocL],sr.[Round Off],sr.[Doc Total],sr.[GSTIN No],sr.Remarks,sr.[DocTotal FC],sr.[TDS]
order by sr.[Invoice Date],sr.[Docentry]
END
GO


