USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetInspectionRequestLetterDays]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetInspectionRequestLetterDays](@FolderRSN INT) RETURNS INT
AS
BEGIN

DECLARE @RetVal INT

SELECT @RetVal = ISNULL(FolderProcessAttempt.ResultCode, 0)
FROM Folder
INNER JOIN FolderProcess ON Folder.FolderRSN = FolderProcess.FolderRSN
LEFT OUTER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN AND FolderProcessAttempt.ResultCode = 20072 /*2nd Routine Insp Due Ltr Sent*/
WHERE Folder.FolderType = 'MH'
AND Folder.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode = 20028 /*Pre-Inspection*/

IF @RetVal > 0
	BEGIN
	SET @RetVal = 10
	END
ELSE
	BEGIN
	SET @RetVal = 14
	END 
RETURN @RetVal

END


GO
