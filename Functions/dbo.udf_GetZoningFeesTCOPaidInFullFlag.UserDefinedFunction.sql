USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesTCOPaidInFullFlag]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesTCOPaidInFullFlag](@intFolderRSN INT)
RETURNS VARCHAR(4)
AS
BEGIN
   /* Used by Infomaker zoning_fee_report form, and Word Mailmerge Temp CO document */

   DECLARE @varCOFlag varchar(2) 
   DECLARE @varFeePaidFlag varchar(4)

   SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intFolderRSN)

   SELECT @varFeePaidFlag = ISNULL(MIN(AccountBill.PaidInFullFlag), 'X')
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN 
      AND Folder.FolderRSN = AccountBill.FolderRSN 
      AND AccountBillFee.BillNumber = AccountBill.BillNumber 
      AND AccountBill.PaidInFullFlag <> 'C' 
      AND AccountBillFee.FeeCode = 162           /* Temp CO Fee */
      AND Folder.FolderRSN = @intFolderRSN 

   IF ( @varCOFlag = 'N' OR @varFeePaidFlag = 'X' ) SELECT @varFeePaidFlag = 'NA'
   ELSE
   BEGIN
      IF @varFeePaidFlag = 'N' SELECT @varFeePaidFlag = 'No' 
      IF @varFeePaidFlag = 'Y' SELECT @varFeePaidFlag = 'Yes' 
   END

   RETURN @varFeePaidFlag
END
GO
