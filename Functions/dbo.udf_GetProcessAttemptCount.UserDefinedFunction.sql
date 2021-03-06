USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAttemptCount]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProcessAttemptCount](@intFolderRSN INT, @intProcessRSN int)
RETURNS INT
AS
BEGIN
	DECLARE @intAttemptCount int
	SET @intAttemptCount = 0

	SELECT @intAttemptCount = COUNT(*)
	FROM FolderProcessAttempt
	WHERE FolderProcessAttempt.ProcessRSN = @intProcessRSN
	AND FolderProcessAttempt.FolderRSN = @intFolderRSN

	RETURN @intAttemptCount
END
GO
