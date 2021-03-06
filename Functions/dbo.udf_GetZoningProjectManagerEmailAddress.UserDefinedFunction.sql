USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningProjectManagerEmailAddress]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningProjectManagerEmailAddress](@intFolderRSN INT)
RETURNS VARCHAR(100)
AS
BEGIN 
	DECLARE @intDecisionProcessCode int
	DECLARE @varProjectManagerEmailAddress varchar(100)

	SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN) 
	
	SELECT @varProjectManagerEmailAddress = ValidUser.EmailAddress 
	FROM FolderProcess, ValidUser 
	WHERE FolderProcess.ProcessCode = @intDecisionProcessCode 
	AND FolderProcess.FolderRSN = @intFolderRSN 
	AND FolderProcess.SignOffUser = ValidUser.UserID 

	RETURN @varProjectManagerEmailAddress
END

GO
