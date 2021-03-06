USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNextFolderSeq]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetNextFolderSeq]() 
RETURNS CHAR(6)
AS
BEGIN
DECLARE @strYear char(2)
DECLARE @intSequence int
DECLARE @strSequence char(6)
DECLARE @intSequenceLength int

SELECT @strYear = FolderYear
FROM Folder
WHERE FolderRSN = (SELECT MAX(FolderRSN) FROM Folder)
 
SELECT @intSequence = CONVERT(INT, MAX(FolderSequence)) + 1
FROM Folder
WHERE FolderYear = @strYear
      IF @intSequence IS NULL
     BEGIN
     SELECT @intSequence = 100000
     END
 
SELECT @intSequenceLength = DATALENGTH(CONVERT(VARCHAR(6), @intSequence))
     IF @intSequenceLength < 6
     BEGIN
     SELECT @strSequence = SUBSTRING('000000', 1, (6 - @intSequenceLength)) + CONVERT(VARCHAR(6), @intSequence)
     END
          IF @intSequenceLength = 6
          BEGIN
          SELECT @strSequence = CONVERT(VARCHAR(6), @intSequence)
          END

RETURN @strSequence
END



GO
