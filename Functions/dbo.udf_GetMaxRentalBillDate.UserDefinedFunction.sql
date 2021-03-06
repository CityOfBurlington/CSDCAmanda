USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetMaxRentalBillDate]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetMaxRentalBillDate](@pPeopleRSN INT) RETURNS DATETIME
AS
BEGIN
	DECLARE @dtmRetVal DATETIME

	SELECT @dtmRetVal = MAX(AccountBillFee.StampDate)
	FROM AccountBillFee
	INNER JOIN Folder ON AccountBillFee.FolderRSN = Folder.FolderRSN
	WHERE Folder.FolderType = 'RB' 
	AND Folder.ReferenceFile = CAST(@pPeopleRSN AS VARCHAR(30))
	AND AccountBillFee.FeeCode IN(180, 181)

	RETURN @dtmRetVal
END


GO
