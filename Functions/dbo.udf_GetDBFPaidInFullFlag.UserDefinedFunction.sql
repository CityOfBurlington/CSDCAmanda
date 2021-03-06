USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetDBFPaidInFullFlag]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetDBFPaidInFullFlag](@intFolderRSN NUMERIC)
	RETURNS VARCHAR
AS
BEGIN
	DECLARE @varRetVal VARCHAR(10)
        DECLARE @FolderType VARCHAR(2)

        SELECT @FolderType = Folder.FolderType
        FROM Folder
        WHERE Folder.FolderRSN = @intFolderRSN

        IF @FolderType IN('ZA', 'ZB', 'ZF', 'ZH', 'Z1')
        BEGIN
           SELECT @varRetVal = 'Y'
        END
        ELSE
        BEGIN
	   SELECT @varRetVal = MIN(AccountBill.PaidInFullFlag)
	   FROM Folder, FolderProcess, AccountBill, AccountBillFee
	   WHERE (Folder.FolderRSN = AccountBillFee.FolderRSN)
	   AND (Folder.FolderRSN = AccountBill.FolderRSN)
	   AND (Folder.FolderRSN = FolderProcess.FolderRSN)
	   AND (FolderProcess.ProcessCode = 10005)
	   AND (AccountBill.PaidInFullFlag <> 'C')
	   AND (AccountBillFee.BillNumber = AccountBill.BillNumber)
	   AND (AccountBillFee.FeeCode IN (145,146))
	   AND (Folder.FolderRSN = @intFolderRSN)
        END

	RETURN @varRetVal
END

GO
