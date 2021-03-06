USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Update_FolderCondition_Log]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Update_FolderCondition_Log] (@intFolderRSN INT, @varLogText VARCHAR(400))
AS
BEGIN
	/* Used to append text into Folder.FolderConditions. Field is used as a log of permit application processing activity. */

	UPDATE Folder
	SET Folder.FolderCondition = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),Folder.FolderCondition)) + RTRIM(@varLogText))) 
	WHERE Folder.FolderRSN = @intFolderRSN
END

GO
