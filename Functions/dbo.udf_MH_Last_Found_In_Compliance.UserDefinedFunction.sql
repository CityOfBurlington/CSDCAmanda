USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_MH_Last_Found_In_Compliance]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[udf_MH_Last_Found_In_Compliance](@FolderRSN INT) RETURNS DATETIME
AS
BEGIN

	DECLARE @dtmRetVal DATETIME 

	SELECT @dtmRetVal = AttemptDate
	FROM FolderProcessAttempt
	WHERE FolderRSN = @FolderRSN
	AND ResultCode = 20046  /*Found in compliance*/

	RETURN @dtmRetVal

END
GO
