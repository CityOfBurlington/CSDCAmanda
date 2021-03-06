USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateFolderCondition]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  PROCEDURE [dbo].[usp_UpdateFolderCondition] (@FolderRSN INT, @Text VARCHAR(400))
AS
BEGIN
	DECLARE @FolderCondition VARCHAR(8000)

	SELECT @FolderCondition = ISNULL(FolderCondition, '')
	FROM Folder
	WHERE FolderRSN = @FolderRSN

	IF LEN(@FolderCondition) < 1 
		UPDATE Folder
		SET FolderCondition = dbo.FormatDateTime(GetDate(),  'MM/DD/YYYY HH:MM 12') + ' [' + SYSTEM_USER + ']: ' + @Text
		WHERE FolderRSN = @FolderRSN
	ELSE
		UPDATE Folder
		SET FolderCondition = CAST(FolderCondition AS VARCHAR(8000)) + char(13) + char(10) + dbo.FormatDateTime(GetDate(),  'MM/DD/YYYY HH:MM 12') + ' [' + SYSTEM_USER + ']: ' + @Text
		WHERE FolderRSN = @FolderRSN

END



GO
