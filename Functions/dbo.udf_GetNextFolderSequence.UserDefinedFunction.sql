USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNextFolderSequence]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetNextFolderSequence](@FolderType CHAR(2), @FolderYear CHAR(2)) RETURNS CHAR(6) 
AS
BEGIN
DECLARE @intNextSequence AS INT
DECLARE @varNextSequence AS VARCHAR(6)
DECLARE @strNextSequence AS CHAR(6)

SELECT @intNextSequence = CAST(ISNULL(FolderSequence, '0') AS INT)
FROM Folder
WHERE FolderType = @FolderType
AND FolderYear = @FolderYear
AND FolderRSN = (SELECT MAX(FolderRSN) FROM Folder WHERE FolderType = @FolderType AND FolderYear = @FolderYear)

SET @intNextSequence = @intNextSequence + 1
SET @varNextSequence = CAST(@intNextSequence AS VARCHAR(6))
SET @varNextSequence = LTRIM(RTRIM(ISNULL(@varNextSequence, '')))

IF LEN(@varNextSequence) < 6
	BEGIN
		SET @strNextSequence = '000001' + CAST(@varNextSequence AS CHAR(6))
	END
ELSE
	BEGIN
		SET @strNextSequence = @varNextSequence
	END

RETURN @strNextSequence

END
GO
