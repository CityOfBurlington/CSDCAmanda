USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesDevelopmentReviewPaidInFullFlag]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesDevelopmentReviewPaidInFullFlag](@intFolderRSN INT)
RETURNS varchar(4)
AS
BEGIN
   /* Used by Infomaker permit forms */
   DECLARE @varDevelopmentReviewFeeFlag varchar(2) 
   DECLARE @varFeePaidFlag varchar(4)

   SELECT @varDevelopmentReviewFeeFlag = dbo.udf_ZoningDevReviewFeeFlag(@intFolderRSN)

   IF @varDevelopmentReviewFeeFlag = 'N' SELECT @varFeePaidFlag = 'NA' 
   ELSE
   BEGIN
	  SELECT @varFeePaidFlag = ISNULL(MIN(AccountBill.PaidInFullFlag), 'Y')
	    FROM Folder, AccountBill, AccountBillFee
	  WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
        AND (Folder.FolderRSN = AccountBill.FolderRSN)
        AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
        AND (AccountBill.PaidInFullFlag <> 'C') 
	    AND (AccountBillFee.FeeCode IN (145, 146))
        AND (Folder.FolderRSN = @intFolderRSN);

      IF @varFeePaidFlag = 'N' SELECT @varFeePaidFlag = 'No' 
      IF @varFeePaidFlag = 'Y' SELECT @varFeePaidFlag = 'Yes' 
   END

   RETURN @varFeePaidFlag
END

GO
