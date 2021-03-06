USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningDevReviewFeeExists]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningDevReviewFeeExists](@intFolderRSN INT)
	RETURNS int
AS
BEGIN
	DECLARE @intDRFCount int

    SET @intDRFCount = 0

	SELECT @intDRFCount = COUNT(*)
	FROM Folder, AccountBill, AccountBillFee
	WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	AND (Folder.FolderRSN = AccountBill.FolderRSN)
	AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
    AND (AccountBill.PaidInFullFlag <> 'C') 
	AND (AccountBillFee.FeeCode IN (145, 146))
	AND (Folder.FolderRSN = @intFolderRSN);

	RETURN @intDRFCount
END
GO
