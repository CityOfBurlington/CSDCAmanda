USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesPermitApplication]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesPermitApplication](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
   /* Totals Zoning Permit application fees, including the Filing Fee. Returns what was Billed. 
      Used by Infomaker zoning permit forms. */ 
      
   DECLARE @varFolderType varchar(4) 
   DECLARE @moneyPermitFeesPaid money

   SELECT @varFolderType = Folder.FolderType 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @varFolderType = 'ZZ'       /* Historic fees are not billed */
   BEGIN 
      SELECT @moneyPermitFeesPaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
        FROM AccountBillFee
       WHERE AccountBillFee.FolderRSN = @intFolderRSN
         AND AccountBillFee.FeeCode IN (80, 85, 86, 90, 95, 100, 105, 110, 130, 135, 136, 147, 150, 155)
   END
   ELSE
   BEGIN
      SELECT @moneyPermitFeesPaid = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
        FROM Folder, AccountBill, AccountBillFee
       WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
         AND Folder.FolderRSN = AccountBill.FolderRSN
         AND AccountBillFee.BillNumber = AccountBill.BillNumber
         AND AccountBill.PaidInFullFlag <> 'C' 
         AND AccountBillFee.FeeCode IN (80, 85, 86, 90, 95, 100, 105, 110, 130, 135, 136, 147, 150)
         AND Folder.FolderRSN = @intFolderRSN;
   END

	RETURN @moneyPermitFeesPaid
END

GO
