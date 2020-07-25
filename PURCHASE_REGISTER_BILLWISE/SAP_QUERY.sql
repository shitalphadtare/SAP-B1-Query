/* SELECT FROM [dbo].[OPCH] T0 */DECLARE @FromDate As Date/* WHERE */SET @FromDate = /* T0.DocDate */ '[%0]'
/* SELECT FROM [dbo].[OPCH] T0 */DECLARE @ToDate As Date/* WHERE */SET @ToDate = /* T0.DocDate */ '[%1]'

EXEC [dbo].[PURCHASE_REGISTER_BILLWISE_GST]  @FromDate,@ToDate

/* SELECT FROM [dbo].[OPCH] T0 */DECLARE @FromDate As Date/* WHERE */SET @FromDate = /* T0.DocDate */ '[%0]'
/* SELECT FROM [dbo].[OPCH] T0 */DECLARE @ToDate As Date/* WHERE */SET @ToDate = /* T0.DocDate */ '[%1]'

EXEC [dbo].[PURCHASE_REGISTER_BILLWISE_GST_v1]  @FromDate,@ToDate