USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningProjectManagerName]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningProjectManagerName](@intFolderRSN INT)
RETURNS VARCHAR(100)
AS
BEGIN 
	DECLARE @intDecisionProcessCode int
	DECLARE @varProjectManagerName varchar(100)

	SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN) 
	
	SELECT @varProjectManagerName = ValidUser.UserName 
	FROM FolderProcess, ValidUser 
	WHERE FolderProcess.ProcessCode = @intDecisionProcessCode 
	AND FolderProcess.FolderRSN = @intFolderRSN 
	AND FolderProcess.SignOffUser = ValidUser.UserID 

	RETURN @varProjectManagerName
END

GO
