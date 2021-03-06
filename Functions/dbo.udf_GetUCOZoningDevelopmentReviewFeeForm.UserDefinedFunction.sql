USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOZoningDevelopmentReviewFeeForm]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOZoningDevelopmentReviewFeeForm](@intFolderRSN INT) 
RETURNS varchar(15)
AS
BEGIN
   /* Returns Development Review Fees due for a zoning permit in the UCO folder. 
      The permit's FolderRSN is entered into FolderProcessInfo for the process 
      that adds the mailmerge document (23005). Used by Word mailmerge documents. */

   DECLARE @moneyDevRevFeeDue money
   DECLARE @varDevRevFeeDue varchar(15)
   DECLARE @intPermitFolderRSN int 

   SET @moneyDevRevFeeDue = 0

   SELECT @intPermitFolderRSN = FolderProcessInfo.InfoValueNumeric
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.FolderRSN = @intFolderRSN
      AND FolderProcessInfo.InfoCode = 23005   /* Permit FolderRSN */
      AND FolderProcessInfo.ProcessRSN = 
          ( SELECT MAX(FolderProcess.ProcessRSN)  
              FROM FolderProcess 
             WHERE FolderProcess.FolderRSN = @intFolderRSN 
               AND FolderProcess.ProcessCode = 23005 )

	SELECT @moneyDevRevFeeDue = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
	  FROM Folder, AccountBill, AccountBillFee
	 WHERE Folder.FolderRSN = AccountBillFee.FolderRSN 
       AND Folder.FolderRSN = AccountBill.FolderRSN 
	   AND AccountBillFee.BillNumber = AccountBill.BillNumber 
       AND AccountBill.PaidInFullFlag = 'N' 
	   AND AccountBillFee.FeeCode IN (145, 146) 
	   AND Folder.FolderRSN = @intPermitFolderRSN 

   SELECT @varDevRevFeeDue = CAST(@moneyDevRevFeeDue AS varchar(15))

   RETURN @varDevRevFeeDue
END

GO
