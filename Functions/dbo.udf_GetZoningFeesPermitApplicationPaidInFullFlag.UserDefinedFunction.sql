USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesPermitApplicationPaidInFullFlag]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesPermitApplicationPaidInFullFlag](@intFolderRSN INT)
	RETURNS VARCHAR(4)
AS
BEGIN
   /* Used by Infomaker zoning permit forms */
   DECLARE @varFeePaidFlag varchar(4)

   SELECT @varFeePaidFlag = ISNULL(MIN(AccountBill.PaidInFullFlag), 'Y')
     FROM Folder, AccountBill, AccountBillFee
    WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
      AND (Folder.FolderRSN = AccountBill.FolderRSN)
      AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
      AND (AccountBill.PaidInFullFlag <> 'C') 
      AND (AccountBillFee.FeeCode IN (80, 85, 86, 90, 95, 100, 105, 110, 130, 135, 136, 147, 150))
      AND (Folder.FolderRSN = @intFolderRSN); 

   IF @varFeePaidFlag = 'N' SELECT @varFeePaidFlag = 'No' 
   IF @varFeePaidFlag = 'Y' SELECT @varFeePaidFlag = 'Yes' 

	RETURN @varFeePaidFlag
END

GO
