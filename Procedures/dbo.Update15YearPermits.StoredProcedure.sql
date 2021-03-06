USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Update15YearPermits]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[Update15YearPermits] AS

BEGIN

DECLARE @ConstFolder int
DECLARE @CCounter int
DECLARE @EPCount int

DECLARE ConstFolders_CUR CURSOR FOR
SELECT DISTINCT Folder.FolderRSN
FROM Folder, ValidFolder
WHERE FolderGroupCode = 1
AND Folder.FolderType = ValidFolder.FolderType
AND Folder.Issuedate < getdate() - 5475
and Folder.StatusCode = 30002
and Folder.FolderType <> 'EP'
and Folder.FolderRSN = 23150

SELECT @CCounter = 0

OPEN ConstFolders_CUR
FETCH NEXT FROM ConstFolders_CUR INTO
@ConstFolder

WHILE @@Fetch_Status = 0
BEGIN

SELECT @EPCount = Count(*)
FROM Folder
WHERE Folder.ParentRSN = @ConstFolder
AND Folder.FolderType = 'EP'

IF @EPCount = 0
BEGIN
DECLARE @Process int

DECLARE FindFolderProcess_CUR CURSOR FOR
SELECT FolderProcess.ProcessRSN
FROM FolderProcess
WHERE FolderProcess.FolderRSN = @ConstFolder
AND FolderProcess.StatusCode = 1

OPEN FindFolderProcess_CUR
FETCH FindFolderProcess_CUR INTO
@Process

WHILE @@Fetch_Status = 0

BEGIN
DECLARE @AttemptRSN int
SELECT @AttemptRSN= IsNull(Max(AttemptRSN),0)
FROM FolderProcessAttempt
WHERE folderProcessAttempt.FolderRSN = @ConstFolder
AND FolderProcessAttempt.ProcessRSN = @Process

INSERT INTO
FolderProcessAttempt
(ProcessRSN, FolderRSN, AttemptRSN, AttemptDate,AttemptBy, StampDate, ResultCode)

VALUES (@process, @constfolder, @AttemptRSN +1, getdate(),'SA',getdate(), 190)

UPDATE
FolderProcess
SET FolderProcess.EndDate = getdate(), StatusCode =2
WHERE FolderProcess.FolderRSN = @Constfolder
AND FolderProcess.ProcessRSN = @Process

FETCH FindFolderProcess_CUR INTO
@Process

END

CLOSE FindFolderProcess_CUR
DEALLOCATE FindFolderProcess_CUR

DECLARE @Statement VarChar(2000)
SELECT @Statement = ClauseText
from ValidClause
WHERE ClauseRSN = 340

UPDATE
Folder
SET Folder.FolderCondition = @Statement, Folder.StatusCode = 2, Folder.FinalDate = Getdate()
WHERE Folder.FolderRSN = @ConstFolder

SELECT @CCounter = @Ccounter +1
IF @Ccounter >100
BEGIN
COMMIT TRANSACTION
BEGIN TRANSACTION
SELECT @CCounter = 0
END

COMMIT TRANSACTION
BEGIN TRANSACTION

END
FETCH NEXT FROM ConstFolders_CUR INTO
@ConstFolder

END
COMMIT TRANSACTION

CLOSE ConstFolders_CUR
DEALLOCATE ConstFolders_CUR
END


GO
