USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZnDevelopmentReviewFee]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetZnDevelopmentReviewFee](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	DECLARE @varRetVal MONEY

	SELECT @varRetVal = SUM(AccountBillFee.FeeAmount)
          FROM Folder, AccountBill, AccountBillFee
         WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
           AND Folder.FolderRSN = AccountBill.FolderRSN
           AND AccountBillFee.BillNumber = AccountBill.BillNumber
           AND AccountBillFee.FeeCode IN(145, 146)
           AND Folder.FolderRSN = @intFolderRSN
/*         AND AccountBill.PaidInFullFlag <> 'C' */

	RETURN @varRetVal
END


GO
