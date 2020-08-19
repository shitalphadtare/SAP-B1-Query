=================================================================================================================================================================================
-------------------------------------------------------------------Business Partner Master---------------------------------------------------------------------------------------
			------------------------------------block changes in Credit Limit or Commitment Limit----------------------------------
IF @object_type = '2' AND @transaction_type IN ('U', 'D')
BEGIN
IF exist (SELECT distinct T2.[CardCode]
FROM ACRD  T0 
left join ACRD  T1 on t0.[CardCode] = T1.[CardCode] and t0.loginstanc = t1.loginstanc-1
left JOIN OCRD T2 ON T0.cardcode = T2.CardCode 
WHERE  ((T2.CreditLine <> T1.CreditLine) or (T2.debtLine <> T1.debtLine)) and t0.CardCode=@list_of_cols_val_tab_del 
and t0.UserSign<>1)
BEGIN
		SET @error =1
		SET @error_message = 'You cannot change Credit Limit or Commitment Limit '
END
END



================================================================================================================================================================================
--------------------------------------------------------------SALES QUOTATION---------------------------------------------------------------------------------------------------------------  
				 -----------------Quotation mandetory for order ---
		  IF @transaction_type IN ('A','U') AND (@Object_type = '17') 
		BEGIN
			If Exists (Select T0.DocEntry from ORDR T0 Inner Join RDR1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
			@list_of_cols_val_tab_del and (T1.BaseEntry is null or T1.BaseEntry=''))
			BEGIN
				Select @error = 1, @error_message = 'ERROR: Please Add sales Quotation - Mandatory'
			END
		  END
			----------------To block addition of Sales Order where at least one ARI is open after its due date----------------------------- 
		  IF @transaction_type IN ('A') AND (@Object_type = '17') 
		 Begin
		  if exists (
				 select  rdr.docentry from ordr rdr
				left outer join OCRD crd on rdr.CardCode=crd.CardCode
				left outer join oinv inv on crd.CardCode=inv.CardCode and inv.DocStatus='O'
				where  rdr.DocEntry= @list_of_cols_val_tab_del and inv.DocDueDate<=GETDATE()
				and rdr.U_AllowOverdue<>'Y'
		  	    )
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
========================================================================================================================================================================				       
--------------------------------------------------SALES ORDER-------------------------------------------------------------------------------------------------------------
				       
============================================================================================================================================================================				       
----------------------------------------------------DELIVERY CHALLAN-------------------------------------------------------------------------------------------------------
				       
			------------------ORDER mandetory for DELIVERY -------------------------------------------------------

		IF @transaction_type IN ('A','U') AND (@Object_type = '15') 
		BEGIN
		If Exists (Select T0.DocEntry from ODLN T0 Inner Join DLN1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
		@list_of_cols_val_tab_del and T1.BaseType<>'17')
		BEGIN
				Select @error = 1, @error_message = 'ERROR: Please Add sales ORDER - Mandatory'
		END
		END

============================================================================================================================================================================						       
----------------------------------------------------AR INVOICE--------------------------------------------------------------------------------------------------------------

			------------------------DELIVERY mandetory for inVOICE---------------------------
		  IF @transaction_type IN ('A','U') AND (@Object_type = '13') 
		BEGIN
			If Exists (Select T0.DocEntry from OINV T0 Inner Join INV1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
			@list_of_cols_val_tab_del and (T1.BaseEntry is null or T1.BaseEntry=''))
			BEGIN
				Select @error = 1, @error_message = 'ERROR: Please Add DELIVERY - Mandatory'
			END
		  END
		-------------------------------AR Invoice quantity is over Sales order quantity-----------------------------------------
		IF @transaction_type IN ('A', 'U') AND (@Object_type = '13')
		begin
		declare @CountI int;
		declare @l int;
		declare @n int;
		declare @Dtotal numeric(16,2);
		declare @Itotal numeric(16,2);
		declare @SalesQty numeric(16,2);
		declare @CNT1 int; 

		set @l=0;
		select @CNT1=count(*) from(select A1.ItemCode,A1.DocEntry,A1.VisOrder,A1.BaseLine from inv1 A1  where A1.DocEntry=@list_of_cols_val_tab_del)A 
								       Left join RDR1 B on A.DocEntry=B.TrgetEntry 
		  where A.BaseLine is null and A.ItemCode<>B.ItemCode
		if @CNT1 > 0
		begin
		select @error='45', @error_message=' AR Invoice should be based on Sales Order' 
		end 

		----SO count Vis Order
		set @CountI=(select Count(VisOrder) from INV1 where  DocEntry=@list_of_cols_val_tab_del ) ;
		while(@l<@CountI)
		begin

		select @Dtotal=(select sum(rr1.quantity)-
		----invoice qty
		isnull((select sum(quantity) 
		from oinv inv inner join inv1 on inv.docentry=inv1.docentry
		where inv1.baseentry=rr1.docentry and inv1.basetype=17 and inv1.Baseline=rr1.LineNum
		and inv.DocEntry<@list_of_cols_val_tab_del and canceled='N'),0)+
		---credit qty
		-----credit Note
		isnull((select sum(rin1.quantity) from orin
		inner join rin1 on orin.docentry=rin1.docentry
		left outer join inv1 on  inv1.docentry=rin1.baseentry and inv1.linenum=rin1.baseline and inv1.objtype=rin1.basetype
		where inv1.baseentry=rr1.docentry and inv1.baseline=rr1.linenum and inv1.basetype=rr1.objtype and orin.canceled='N'),0)

		from rdr1 rr1 where DocEntry in
		(Select distinct BaseEntry from INV1 where DocEntry=@list_of_cols_val_tab_del and BaseType=17 and linenum=@l)
		AND RR1.LINENUM=(Select distinct baseline from INV1 where DocEntry=@list_of_cols_val_tab_del and BaseType=17 and linenum=@l)
		group by docentry,rr1.linenum,rr1.objtype
		)
		select @Itotal=(select sum(Quantity) from inv1 where DocEntry=@list_of_cols_val_tab_del and BaseType=17 and linenum=@l)
		select @n=(select distinct linenum from inv1 where DocEntry=@list_of_cols_val_tab_del and BaseType=17 and linenum=@l)
		if @Dtotal<@Itotal 
		BEGIN
		SET @Error = 10
		SET @error_message = 'AR Invoice quantity is over Sales order quantity at line number ' + cast(@n+1 as varchar ) + ' by ' +CAST((@Itotal-@Dtotal) AS VARCHAR) + ' Qty'
		END
		Set @l = @l + 1
		end
		SELECT @error, @error_message
		End
		
				------------------------------------Freight tax should match with item tax-----------------------
		IF   @transaction_type IN('A','U') AND  @object_type in('13')
		begin
		declare @CNT3 int
		select  @CNT3=count(*) from(select A1.TaxCode,A1.DocEntry,A2.TfcId from INV1 A1 Left Join OSTC A2 on A1.TaxCode=A2.Code
					    where A1.DocEntry=@list_of_cols_val_tab_del)A inner join INV3 B on A.DocEntry=B.DocEntry
					    Left Join OSTc A3 on B.TaxCode=A3.Code where A.TfcId<>A3.TfcId
		if @CNT3 > 0
		begin
		select @error='45', @error_message='Freight tax should match with item tax'
		end
		end		
		
===================================================================================================================================================================================		
---------------------------------------------------AR CREDIT NOTE----------------------------------------------------------------------------------------------------------==
			------------------------------------Freight tax should match with item tax-----------------------	       
		IF   @transaction_type IN('A','U') AND  @object_type in('14')
		begin
		declare @CNT4 int
		select  @CNT4=count(*) from(select A1.TaxCode,A1.DocEntry,A2.TfcId from RIN1 A1 Left Join OSTC A2 on A1.TaxCode=A2.Code where A1.DocEntry=@list_of_cols_val_tab_del)A 
		inner join RIN3 B on A.DocEntry=B.DocEntry  Left Join OSTc A3 on B.TaxCode=A3.Code where A.TfcId<>A3.TfcId
		if @CNT4 > 0
		begin
		select @error='45', @error_message='Freight tax should match with item tax'
		end
		end				       

===================================================================================================================================================================
----------------------------------------------------PURCHASE REQUEST----------------------------------------------------------------------------------------------------------
				---------------------------------Posting Date Should Be Todays Date-----------------------------
		IF  @transaction_type in ('A', 'U') AND (@object_type = '1470000113' ) 
		if Exists ( select*from OPRQ T0 
		inner join PRQ1 T1 on T0.DocEntry=T1.DocEntry 

		Where  convert(date,T0.DocDate)<>convert(date,GETDATE()) 
		  and T0.docentry=@list_of_cols_val_tab_del)
		begin
		SET @error=7
		SET @error_message = 'Posting Date Should Be Todays Date' 
		end 

		IF  @transaction_type in ('A', 'U') AND (@object_type = '112' ) 
		if Exists ( select*from ODRF T0 
		inner join DRF1 T1 on T0.DocEntry=T1.DocEntry and T1."BaseType"='1470000113'

		Where   convert(date,T0.DocDate)<>convert(date,GETDATE())  and T0.docentry=@list_of_cols_val_tab_del)
		begin
		SET @error=7
		SET @error_message = 'Posting Date Should Be Todays Date' 
		end	
			   
=============================================================================================================================================================================			   
---------------------------------------------------PURCHASE QUOTATION-------------------------------------------------------------------------------------------------------------
				       
================================================================================================================================================================================
--------------------------------------------------PURCHASE ORDER---------------------------------------------------------------------------------------------------------------
				       -------------------PURCHASE ORDER VALIDATION - MANDATORY PROJECT CODE-------------------------------------

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
				       ---------------------------------Payment Terms in Purchase Order-----------------------------------------------------
		IF (@object_type in ('22') and @transaction_type in ('A', 'U'))
		BEGIN
		  If Exists (Select T0.DocEntry from OPOR T0  Where T0.DocEntry =
		       @list_of_cols_val_tab_del and T0.U_terms_pay is null)
		      BEGIN
			    Select @error = -1, @error_message = 'Please Select Payment Terms......'
		    END
		END
				------------------------PURCHASE REQUEST IS MANDATORY---------------------------
		IF @transaction_type IN ('A','U') AND (@Object_type = '22') 
		BEGIN
		if Exists(select T0.DocEntry from opor T0  Where T0.DocEntry = @list_of_cols_val_tab_del and T0.DocType='I')
		begin
		If Exists (Select T0.DocEntry from opor T0 Inner Join por1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
		@list_of_cols_val_tab_del and T1.BaseType<>'1470000113')
		BEGIN
		Select @error = 1, @error_message = 'ERROR: Please Add Purchase request - Mandatory'
		END
		END
		end
								     
============================================================================================================================================================================								     
---------------------------------------------------GRPO------------------------------------------------------------------------------------------------------------------------
				         -----------------po mandetory for GRN ---
		  IF @transaction_type IN ('A','U') AND (@Object_type = '20') 
		BEGIN
			If Exists (Select T0.DocEntry from OPDN T0 Inner Join PDN1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
			@list_of_cols_val_tab_del and T1.BaseType<>'22')
			BEGIN
				Select @error = 1, @error_message = 'ERROR: Please Add Purchase order - Mandatory'
			END
		  END
						     	--------------GRN Without PO--------------------------
		 IF @transaction_type IN ('A','U') AND (@Object_type = '20') 
		BEGIN
		If Exists (Select T0.DocEntry from OPDN T0 Inner Join PDN1 T1 on T0.DocEntry = T1.DocEntry Where T0.DocEntry =
				@list_of_cols_val_tab_del and T1.BaseType not in ('22','20'))
					BEGIN
					Select @error = 1, @error_message = 'ERROR: Please Add Purchase ORDER - Mandatory'
					END
		  END
			-----Goods receipt - Price should  greater than Zero - end -------

		IF (@object_type = '59') and (@transaction_type IN (N'A', N'U')) 
		BEGIN 
		IF EXISTS (SELECT distinct T0.Docentry from oign T0 Inner Join ign1 T1 ON T0.Docentry=T1.Docentry 
			where T1.DocEntry = @list_of_cols_val_tab_del and (isnull(T1.StockPrice,0)=0 or T1.StockPrice is null)) 
			BEGIN 
			Select @error = 10, @error_message = N'Price should be greater than zero !'
			end
		END

=============================================================================================================================================================================									   
-------------------------------------------------AP INVOICE--------------------------------------------------------------------------------------------------------------------				       
					
   				----------------------GRN mandetory for PI ------------------------------

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

				----------------------------AP WITHOUT PO--------------------------------------------------------
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

			-----------------------AP InvoiceFreight tax should match with item tax----------------------------

		IF   @transaction_type IN('A','U') AND  @object_type in('18')
		begin
		declare @CNT int
		select  @CNT=count(*) from(select A1.TaxCode,A1.DocEntry,A2.TfcId from PCH1 A1 Left Join OSTC A2 on A1.TaxCode=A2.Code where A1.DocEntry=@list_of_cols_val_tab_del)A inner join PCH3 B on A.DocEntry=B.DocEntry  Left Join OSTc A3 on B.TaxCode=A3.Code where A.TfcId<>A3.TfcId
		if @CNT > 0
			begin
			select @error='45', @error_message='Freight tax should match with item tax'
			end
		end
			------------------ A/P Invoice date is greater than or equal to GRPO ---
		IF @transaction_type = 'A' AND @Object_type = '18'
		BEGIN
		     IF EXISTS (SELECT T0.DocDate FROM OPCH T0 INNER JOIN
				 PCH1 T1 ON T0.DocEntry = T1.DocEntry INNER JOIN
			     PDN1 T2 ON T1.BaseEntry = T2.DocEntry AND T1.BaseType = T2.ObjType INNER JOIN
			     OPDN T3 ON T2.DocEntry = T3.DocEntry
			     WHERE T0.DocDate < T3.DocDate AND T0.DocEntry = @list_of_cols_val_tab_del)
		     BEGIN
				SELECT @Error = 2, @error_message = 'AP Invoice Docdate Should be Greter Than GRPO Docdate.'
		     END
		END

=============================================================================================================================================================================									   
---------------------------------------------------------------------AP CREDIT MEMO-------------------------------------------------------------------------------------------
			-------------------------------Freight tax should match with item tax------------------------------
		IF   @transaction_type IN('A','U') AND  @object_type in('19')
		begin
		declare @CNT2 int
		select  @CNT2=count(*) from(select A1.TaxCode,A1.DocEntry,A2.TfcId from RPC1 A1 Left Join OSTC A2 on A1.TaxCode=A2.Code 
					    where A1.DocEntry=@list_of_cols_val_tab_del)A inner join RPC3 B on A.DocEntry=B.DocEntry  
					Left Join OSTc A3 on B.TaxCode=A3.Code where A.TfcId<>A3.TfcId
		if @CNT2 > 0
			begin
				select @error='45', @error_message='Freight tax should match with item tax'
			end
		end

			----------------------------Vendor Reference number should not same------------------------------------
		if @object_type ='18' and @transaction_type in ('A','U')
		BEGIN
		If exists(
			 SELECT Distinct 'Error' FROM OPCH T0 , OPCH T1 
			 where t0.CardCode = t1.CardCode and Isnull(T0.NumAtCard,'') = Isnull(t1.NumAtCard,'')
			 and t0.DocEntry = @list_of_cols_val_tab_del and t1.DocEntry <> @list_of_cols_val_tab_del)
			begin
				SET @error = 50
				SET @error_message = 'Reference number should not same.'
			end
		END
			--------------------------------Vendor Ref Number is Mandatory---------------------------------------------
		IF @transaction_type IN ('A','U') AND (@Object_type = '18') 
		  BEGIN
			Declare @NumAtCard as nvarchar(100)
			Select @NumAtCard=NumAtCard from OPCH where DocEntry = @list_of_cols_val_tab_del
			If @NumAtCard Is Null or @NumAtCard=''
			   begin
				   set @error = 51
				   set @error_message ='Vendor Ref Number is Mandatory'
			   end
		end
						  
						  
						  
===============================================================================================================================================================================						  
----------------------------------------------------------------INVENTORY TRANSFER----------------------------------------------------------------------------------
		-------------------Inventory Transfer can't cancelled after posting A/R Invoice---------------------------

		IF @transaction_type IN ('C') AND (@Object_type = '67') 
		 Begin
		     declare @user3 int
		     declare @user4 int
		      Set @user3 = ( select count(T1.DocEntry) from OWTR T0 Left Join OINV T1 on T0.DocEntry=T1.BaseEntry and T1.BaseType=67 Where T0.DocEntry=@list_of_cols_val_tab_del)
		      if  @user3  >0
			    begin
				SElect @error = 0406,
				@error_message= 'Tax Invoice alredy generated !! User can not cancel Inventory Transfer '
			    end
		END
						  
						  
						  
/****************************************************************all in one **************************************************/

		-------------------------------------PROJECT CODE MANDATORY-------------------------------------------------------------

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




