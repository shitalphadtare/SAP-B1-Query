
 ----------------- . To block addition of Sales Order where at least one ARI is open after its due date 
  IF @transaction_type IN ('A') AND (@Object_type = '17') 
 Begin
  
  if exists (
 
 select  rdr.docentry from ordr rdr
left outer join OCRD crd on rdr.CardCode=crd.CardCode
left outer join oinv inv on crd.CardCode=inv.CardCode and inv.DocStatus='O'
where  rdr.DocEntry= @list_of_cols_val_tab_del and inv.DocDueDate<=GETDATE()
and rdr.U_AllowOverdue<>'Y')
          begin
            select @error = 1, @error_message = 'Cant Add...'
          end
 END

 

  -------------------Quotation mandetory for order ---
  IF @transaction_type IN ('A','U') AND (@Object_type = '17') 
BEGIN
	If Exists (Select T0.DocEntry from ORDR T0 Inner Join RDR1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
	@list_of_cols_val_tab_del and (T1.BaseEntry is null or T1.BaseEntry=''))
	BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add sales Quotation - Mandatory'
	END
  END

  -------------------DELIVERY mandetory for inVOICE---------------------------
  IF @transaction_type IN ('A','U') AND (@Object_type = '13') 
BEGIN
	If Exists (Select T0.DocEntry from OINV T0 Inner Join INV1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
	@list_of_cols_val_tab_del and (T1.BaseEntry is null or T1.BaseEntry=''))
	BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add DELIVERY - Mandatory'
	END
  END

  -------------------ORDER mandetory for DELIVERY ---
  IF @transaction_type IN ('A','U') AND (@Object_type = '15') 
BEGIN
	If Exists (Select T0.DocEntry from ODLN T0 Inner Join DLN1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
	@list_of_cols_val_tab_del and (T1.BaseEntry is null or T1.BaseEntry=''))
	BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add sales ORDER - Mandatory'
	END
  END


  -----------------po mandetory for GRN ---
  IF @transaction_type IN ('A','U') AND (@Object_type = '20') 
BEGIN
	If Exists (Select T0.DocEntry from OPDN T0 Inner Join PDN1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
	@list_of_cols_val_tab_del and T1.BaseType<>'22')
	BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add Purchase order - Mandatory'
	END
  END

  -----------------GRN mandetory for PI ---

IF @transaction_type IN ('A','U') AND (@Object_type = '18') 
BEGIN
if Exists(select T0.DocEntry from OPCH T0  Where T0.DocEntry = @list_of_cols_val_tab_del and T0.DocType='I')
begin
If Exists (Select T0.DocEntry from OPCH T0 Inner Join PCH1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
@list_of_cols_val_tab_del and T1.BaseType<>'20')
BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add Goods Receipt po - Mandatory'
END
END
end



  -----------------Quotation mandetory for order ---
  IF @transaction_type IN ('A','U') AND (@Object_type = '17') 
BEGIN
	If Exists (Select T0.DocEntry from ORDR T0 Inner Join RDR1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
	@list_of_cols_val_tab_del and (T1.BaseEntry is null or T1.BaseEntry=''))
	BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add sales Quotation - Mandatory'
	END
  END

  -----------------DELIVERY mandetory for inVOICE---------------------------
  IF @transaction_type IN ('A','U') AND (@Object_type = '13') 
BEGIN
	If Exists (Select T0.DocEntry from OINV T0 Inner Join INV1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
	@list_of_cols_val_tab_del  and T1.BaseType<>'15')
	BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add DELIVERY - Mandatory'
	END
  END

  -----------------ORDER mandetory for DELIVERY ---

IF @transaction_type IN ('A','U') AND (@Object_type = '15') 
BEGIN
If Exists (Select T0.DocEntry from ODLN T0 Inner Join DLN1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
@list_of_cols_val_tab_del and T1.BaseType<>'17')
BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add sales ORDER - Mandatory'
END
END


----------------------------------------------
IF @transaction_type IN ('A','U') AND (@Object_type = '18') 
BEGIN
declare @basetype nvarchar(10);
if Exists(select T0.DocEntry from OPCH T0  Where T0.DocEntry = @list_of_cols_val_tab_del and T0.DocType='S')
begin
select @basetype=T1.BaseType from PCH1 T1  Where T1.DocEntry =@list_of_cols_val_tab_del
if @basetype <>'20'
begin
if exists(select * from PCH1 T1 where T1.DocEntry=@list_of_cols_val_tab_del and T1.basetype<>'22')
BEGIN
		Select @error = 10, @error_message = 'ERROR: Please Add Purchase order - Mandatory'
END
END
END
END
-------------------------------------

IF @transaction_type IN ('A','U') AND (@Object_type IN('22','18','17','20','15','13','540000006','23','46','24','14','19','30','1470000113','67','202','60','59')) 
BEGIN
IF @object_type='17'
BEGIN
IF EXISTS(SELECT * FROM RDR1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 11, @error_message = 'ERROR: please select projectcode'
END
IF @object_type='18'
BEGIN
IF EXISTS(SELECT * FROM PCH1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 12, @error_message = 'ERROR: please select project code'
END
IF @object_type='20'
BEGIN
IF EXISTS(SELECT * FROM PDN1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 13, @error_message = 'ERROR: please select project code'
END
IF @object_type='15'
BEGIN
IF EXISTS(SELECT * FROM DLN1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 14, @error_message = 'ERROR: please select project code'
END
IF @object_type='13'
BEGIN
IF EXISTS(SELECT * FROM INV1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 15, @error_message = 'ERROR: please select project code'
END
IF @object_type='540000006'
BEGIN
IF EXISTS(SELECT * FROM PQT1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 16, @error_message = 'ERROR: please select project code'
END
IF @object_type='23'
BEGIN
IF EXISTS(SELECT * FROM QUT1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 17, @error_message = 'ERROR: please select project code'
END
IF @object_type='14'
BEGIN
IF EXISTS(SELECT * FROM RIN1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 18, @error_message = 'ERROR: please select project code'
END
IF @object_type='19'
BEGIN
IF EXISTS(SELECT * FROM RPC1 WHERE DOCENTRY=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 19, @error_message = 'ERROR: please select project code'
END
IF @object_type='46'
BEGIN
IF EXISTS(SELECT * FROM OVPM WHERE DOCENTRY=@list_of_cols_val_tab_del AND (ISNULL(PrjCode, '') = ''))
Select @error = 20, @error_message = 'ERROR: please select project code'
END
IF @object_type='24'
BEGIN
IF EXISTS(SELECT * FROM ORCT WHERE DOCENTRY=@list_of_cols_val_tab_del AND (ISNULL(PrjCode, '') = ''))
Select @error = 21, @error_message = 'ERROR: please select project code'
END
--IF @object_type='30'
--BEGIN
--IF EXISTS(SELECT * FROM JDT1 WHERE TransId=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
--Select @error = 22, @error_message = 'ERROR: please select project code'
--END
IF @object_type='1470000113'
BEGIN
IF EXISTS(SELECT * FROM PRQ1 WHERE DocEntry=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 23, @error_message = 'ERROR: please select project code'
END
IF @object_type='67'
BEGIN
IF EXISTS(SELECT * FROM WTR1 WHERE DocEntry=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 24, @error_message = 'ERROR: please select project code'
END
IF @object_type='59'
BEGIN
IF EXISTS(SELECT * FROM IGN1 WHERE DocEntry=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 27, @error_message = 'ERROR: please select project code'
END
IF @object_type='22'
BEGIN
IF EXISTS(SELECT * FROM POR1 WHERE DocEntry=@list_of_cols_val_tab_del AND  (ISNULL(Project, '') = ''))
Select @error = 28, @error_message = 'ERROR: please select project code'
END
end

--------------------



----END ---------------------PURCHASE ORDER VALIDATION - MANDATORY PROJECT CODE-------------------------------------

IF (:transaction_type='A' or :transaction_type='U') AND (:Object_type = '20')
then
SELECT T0."DocEntry" into GRN from OPDN T0 Inner Join PDN1 T1 ON T0."DocEntry"=T1."DocEntry" where
T0."DocEntry" = :list_of_cols_val_tab_del and T1."BaseType"=22;
(SELECT distinct T1."BaseEntry" into GRN from OPDN T0 Inner Join PDN1 T1 ON T0."DocEntry"=T1."DocEntry" where
T1."DocEntry" = :list_of_cols_val_tab_del  )
if GRN='' or GRN is null 
then
			error := 46;
          error_message := 'GRN cannot be posted without Purchaser Order...';
end if;
end if;


 ----Mandatory Vendor Reference No & Date in AP Invoice --------
 IF transaction_type ='A' AND (object_type = '18')
then
select OPCH."NumAtCard" into APDocType from OPCH  where  OPCH."DocType"='I' and OPCH."DocEntry"= :list_of_cols_val_tab_del;
select "U_BPRefDt" into APDocType1 from OPCH  where  "DocEntry"= :list_of_cols_val_tab_del and "DocType"='I';
if APDocType='' or APDocType is null 
then
		   error := 1;
           error_message := 'Vendor reference number';
end if;
--end if;
