USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetAppealsYN]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetAppealsYN](@intFolderRSN INT) RETURNS VARCHAR(3)
AS

BEGIN
--	Declare the return variable here
	DECLARE @Appeals VARCHAR(3)
	DECLARE @intAppeals INT
	SET @Appeals = 'NO'
	SET @intAppeals = 0

	SELECT @intAppeals = COUNT(*) FROM FolderProcessAttempt 
	WHERE FolderRSN = @intFolderRSN 
	AND ResultCode IN (100,5005,5028,10015,10016,10034,20078,20081,20104,20105)  

	SET @intAppeals = ISNULL(@intAppeals, 0)
	If @intAppeals > 0 SET @Appeals = 'YES'
	RETURN @Appeals
--
END


GO
