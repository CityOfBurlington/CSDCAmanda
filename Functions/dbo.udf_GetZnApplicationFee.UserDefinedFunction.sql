USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZnApplicationFee]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetZnApplicationFee](@intFolderRSN INT)
	RETURNS MONEY
AS
BEGIN
	/* Returns only the zoning permit application fee amount, 
	   exclusive of  filing fees. Used by CO Request Infomaker form. 
       Replaced by dbo.udf_GetZoningFeesPermitApplicationNoFF. */

	DECLARE @InDate datetime
	DECLARE @varRetVal MONEY

	SELECT @InDate = Folder.InDate
	  FROM Folder
	 WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @varRetVal = SUM(AccountBillFee.FeeAmount)
          FROM Folder, AccountBill, AccountBillFee
         WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
           AND Folder.FolderRSN = AccountBill.FolderRSN
           AND AccountBillFee.BillNumber = AccountBill.BillNumber
           AND AccountBill.PaidInFullFlag <> 'C'
           AND AccountBillFee.FeeCode IN(85,86,90,95,100,105,130,135,136,147)
           AND Folder.FolderRSN = @intFolderRSN

	/* Zoning permits converted from the previous Access database 
	   issued after July 1, 1998, have a $14 filing fee included in 
	   application fee. */

	IF @intFolderRSN < 105535 AND @InDate >= '7/1/1998'
	SELECT @varRetVal = @varRetVal - 14

	RETURN @varRetVal
END

GO
