USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOZoningCOOfficerForm]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOZoningCOOfficerForm](@intFolderRSN INT) 
RETURNS VARCHAR(60)
AS
BEGIN
    /* Used by UCO Infomaker forms. FolderRSN is intentionally not used. */
	DECLARE @ZoningCOUser VARCHAR(60)
	
    SET @ZoningCOUser = ' ' 

	SELECT @ZoningCOUser = ValidUser.UserName + ', ' + ValidUser.UserTitle 
      FROM ValidUser
     WHERE ValidUser.UserID = 'jfrancis' 

	RETURN @ZoningCOUser
END

GO
