USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CountFolderProcessAppeals]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_CountFolderProcessAppeals](@intFolderRSN INT) RETURNS INT
AS

BEGIN
--	Declare the return variable here
    /* This is probably not used as the result does not mean much. */
	DECLARE @intAppeals INT
	SET @intAppeals = 0

	SELECT @intAppeals = COUNT(*) FROM FolderProcessAttempt 
	WHERE FolderRSN = @intFolderRSN 
	AND ResultCode IN (100,5005,5028,10015,10016,10034,20078,20081,20104,20105)  

	SET @intAppeals = ISNULL(@intAppeals, 0)
	RETURN @intAppeals
--
END

GO
