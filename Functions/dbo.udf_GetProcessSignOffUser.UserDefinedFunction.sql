USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessSignOffUser]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetProcessSignOffUser](@FolderRSN INT, @ProcessCode INT) RETURNS VARCHAR(60)
AS
BEGIN
	DECLARE @SignoffUser VARCHAR(60)
	
        SET @SignoffUser = ' '
	SELECT @SignoffUser = ValidUser.UserName + ', ' + ValidUser.UserTitle 
	FROM FolderProcess, ValidUser
	WHERE FolderProcess.ProcessCode = @ProcessCode
	AND FolderRSN = @FolderRSN
        AND FolderProcess.SignOffUser = ValidUser.UserID

	RETURN @SignoffUser
END


GO
