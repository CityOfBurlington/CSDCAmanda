USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[OpenProcess]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[OpenProcess](@intFolderRSN INT, @intProcessCode int)
AS
BEGIN
	UPDATE FolderProcess
	SET StatusCode = 1, EndDate = NULL
	WHERE FolderProcess.ProcessCode = @intProcessCode
	AND FolderProcess.FolderRSN = @intFolderRSN
END




GO
