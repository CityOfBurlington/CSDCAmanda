USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_VB_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_VB_Folder]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

DECLARE @NextProcessRSN int

DECLARE @TodayQuarter INT
DECLARE @TodayYear INT
DECLARE @CurrFolderQuarter INT
DECLARE @CurrFolderYear CHAR(4)
DECLARE @strFolderQuarter VARCHAR(50)
DECLARE @strReference VARCHAR(50)

/* Figure out quarter and fiscal year */
SET @TodayQuarter = DATEPART(q, getdate())  /* Calendar Quarter for date procedure runs */
SET @TodayYear = DATEPART(yyyy,getdate())   /* Calendar Year for date procedure runs */
IF @TodayQuarter = 1
BEGIN
	SET @CurrFolderQuarter = 3
	SET @CurrFolderYear = @TodayYear
END
IF @TodayQuarter = 2
BEGIN
	SET @CurrFolderQuarter = 4
	SET @CurrFolderYear = @TodayYear
END
IF @TodayQuarter = 3
BEGIN
	SET @CurrFolderQuarter = 1
	SET @CurrFolderYear = @TodayYear + 1
END
IF @TodayQuarter = 4
BEGIN
	SET @CurrFolderQuarter = 2
	SET @CurrFolderYear = @TodayYear + 1
END
SET @strFolderQuarter = 'Quarter ' + CAST(@CurrFolderQuarter AS CHAR(1)) + ', ' + CAST(@CurrFolderYear AS CHAR(4))
SET @strReference = 'Qtr ' + CAST(@CurrFolderQuarter AS CHAR(1)) + ', ' + @CurrFolderYear

/* Set status to VB Investigation (25000) */
UPDATE Folder 
SET Folder.StatusCode = 25000, 
    Folder.ReferenceFile = @strReference, 
    Folder.FolderYear = RIGHT(@CurrFolderYear,2)
WHERE Folder.FolderRSN = @FolderRSN

/* Insert Folder Process VB Investigation (25000) */
SELECT @NextProcessRSN = MAX(ProcessRSN) + 1
FROM FolderProcess

BEGIN
    INSERT INTO FolderProcess 
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, DisplayOrder,
    PrintFlag, StatusCode, StampDate, StampUser) 
    VALUES ( @NextProcessRSN, @FolderRSN, 25000, 0, 0,
    'Y', 1, GetDate(), @UserId) 
END

/* Insert Folder Process VB Application (25010) */
SELECT @NextProcessRSN = MAX(ProcessRSN) + 1
FROM FolderProcess

BEGIN
    INSERT INTO FolderProcess 
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, DisplayOrder,
    PrintFlag, StatusCode, StampDate, StampUser, AssignedUser) 
    VALUES ( @NextProcessRSN, @FolderRSN, 25010, 0, 0,
    'Y', 1, GetDate(), @UserId, @UserId) 
END

/* Insert Folder Process Inspection (25030) */
SELECT @NextProcessRSN = MAX(ProcessRSN) + 1
FROM FolderProcess

BEGIN
    INSERT INTO FolderProcess 
    (ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, DisplayOrder,
    PrintFlag, StatusCode, StampDate, StampUser, AssignedUser) 
    VALUES ( @NextProcessRSN, @FolderRSN, 25030, 0, 0,
    'Y', 1, GetDate(), @UserId, @UserId) 
END

/* Set Folder Quarter Info field (25050) */
UPDATE FolderInfo 
SET InfoValue = @strFolderQuarter
WHERE infocode = 25050 AND FolderRSN = @FolderRSN


GO
