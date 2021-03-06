USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QC_00020018]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QC_00020018]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
DECLARE @AttemptResult  int
DECLARE @CountCheckList float
DECLARE @Inspector      char(8)
DECLARE @NextFolderRSN  int
DECLARE @SeqNo          int
DECLARE @Seq            char(6)
DECLARE @SeqLength      int
DECLARE @TheYear        char(2)
DECLARE @FolderType     char(2)
DECLARE @SubCode        int
DECLARE @ChecklistCode  int
DECLARE @PropertyRSN    int
DECLARE @ParentRSN		INT

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT max(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 20043  /*violation(s) confirmed*/
BEGIN 
	SELECT @Inspector = FolderProcess.AssignedUser
	FROM FolderProcess
	WHERE FolderProcess.ProcessRSN = @ProcessRSN

	UPDATE Folder
	SET Folder.StatusCode = 220/*VIOLATION*/, 
	Folder.FinalDate = GETDATE()
	WHERE Folder.FolderRSN = @FolderRSN
	UPDATE FolderProcess
	SET FolderProcess.AssignedUser = @Inspector
	WHERE FolderProcess.FolderRSN IN (SELECT Folder.FolderRSN FROM Folder WHERE Folder.ParentRSN = @FolderRSN)
	AND FolderProcess.ProcessCode IN(20004, 20013, 20005, 20007, 20011, 20014, 20015, 20009, 20000, 20008, 20003)

        SELECT @NextProcessRSN = MAX(ProcessRSN) + 1 FROM FolderProcess 

	INSERT INTO FolderProcess
	(ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
	PrintFlag, StatusCode, StampDate, StampUser, AssignedUser) 
	VALUES ( @NextProcessRSN, @FolderRSN, 20030, 90, 
	'Y', 1, GetDate(), @UserId, @Inspector) 
END

IF @AttemptResult IN (20014, 20018) /*no violation or violation resolved*/
BEGIN
	/* Close the QC Folder */
	UPDATE Folder
	SET StatusCode = 2, FinalDate = getdate()
	WHERE Folder.FolderRSN = @FolderRSN

	/* Close the Q1 Folder */
	SELECT @ParentRSN = ParentRSN FROM Folder WHERE FolderRSN = @FolderRSN
    UPDATE Folder
	SET StatusCode = 2, FinalDate = getdate()
	WHERE Folder.FolderRSN = @ParentRSN
 
END

IF @AttemptResult IN (20005, 30111) /*Ticket Issued*/
BEGIN
     DECLARE @TicketNumber VARCHAR(200)
     DECLARE @MaxAttemptRSN INT
  
     SELECT @MaxAttemptRSN = MAX(AttemptRSN) 
     FROM FolderProcessAttempt
     WHERE ProcessRSN = @ProcessRSN

     SELECT @TicketNumber = FolderProcessAttempt.AttemptComment
     FROM FolderProcessAttempt
     WHERE FolderProcessAttempt.AttemptRSN = @MaxAttemptRSN
END

IF @AttemptResult = 20160 /* Track Occupancy Status */
BEGIN

   /* Add Folder Info for Track Occupancy Start Date (20075) */
   IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 20075)
   BEGIN
      UPDATE FolderInfo SET InfoValue = getdate(), InfoValueDateTime = getdate()
      WHERE infocode = 20075 AND FolderRSN = @FolderRSN
   END
   ELSE
   BEGIN
      INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, InfoValueDateTime, StampDate, StampUser)
      VALUES(@FolderRSN, 20075, getdate(), getdate(), getdate(), @UserID)
   END

   /* Add empty info fields for 
	20034 = VB Most Recent Use of Building
	20035 = VB Proposed Use of Building
	20038 = VB Date of Vacancy
	20039 = VB Expected Occupancy Date
	20040 = VB Plan for Building
   */
   INSERT INTO FolderInfo (FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired)
   SELECT @FolderRSN, InfoCode, DisplayOrder, PrintFlag, getdate(), @UserID, Mandatory, RequiredForInitialSetup 
   FROM DefaultInfo WHERE FolderType = 'VB' and InfoCode IN (20034,20035,20038,20039,2040)

   /* Set Process Status to Tracking Occupancy (20010) */
   UPDATE FolderProcess  
   SET StatusCode = 20010, StartDate = NULL, EndDate = NULL
   WHERE FolderProcess.ProcessRSN = @ProcessRSN

   /* Set Folder Status to Occupancy Tracking (20025) */
   UPDATE Folder SET StatusCode = 20025
   WHERE Folder.FolderRSN = @FolderRSN

   /* Set Q1 Folder Status to Occupancy Tracking (20025) */
   SELECT @ParentRSN = ParentRSN FROM Folder WHERE FolderRSN = @FolderRSN
   UPDATE Folder SET StatusCode = 20025
   WHERE Folder.FolderRSN = @ParentRSN
 
END

IF @AttemptResult = 20170 /* Vacant Building Declared */
BEGIN

   /* Add Folder Info for Vacant Building Declared Date (25040):  */
   IF EXISTS (SELECT FolderRSN FROM FolderInfo WHERE FolderInfo.FolderRSN = @FolderRSN AND InfoCode = 25040)
   BEGIN
      UPDATE FolderInfo SET InfoValue = getdate(), InfoValueDateTime = getdate()
      WHERE infocode = 25040 AND FolderRSN = @FolderRSN
   END
   ELSE
   BEGIN
      INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, InfoValueDateTime, StampDate, StampUser)
      VALUES(@FolderRSN, 25040, dbo.FormatDateTime(getdate(), 'LongDate'), getdate(), getdate(), @UserID)
   END

   /* Set Process Status to Vacant Building Declared (20020) */
   UPDATE FolderProcess  
   SET StatusCode = 20020, StartDate = NULL, EndDate = NULL
   WHERE FolderProcess.ProcessRSN = @ProcessRSN

/* Create the new VB Folder */
	DECLARE @TodayQuarter INT
	DECLARE @TodayYear INT

	DECLARE @CurrSubCode INT
	DECLARE @CurrQuarter INT
	DECLARE @CurrYear INT
	DECLARE @CurrFolderQuarter INT
	DECLARE @CurrFolderYear CHAR(2)

	DECLARE @NewSubCode INT
	DECLARE @NewQuarter INT
	DECLARE @NewYear INT
	DECLARE @NewFolderQuarter INT
	DECLARE @NewFolderYear CHAR(2)

	/* Figure out FolderQuarter and FolderYear. Since we're converting calendar year to fiscal year, this
	   is a little complicated. But it works. */
	SET @TodayQuarter = DATEPART(q, getdate())				/* Calendar Quarter for date procedure runs */
	SET @TodayYear = RIGHT(STR(DATEPART(yyyy,getdate())),2)	/* Calendar Year for date procedure runs */
	IF @TodayQuarter = 1
	BEGIN
		SET @CurrFolderQuarter = 3
		SET @CurrFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @CurrSubCode = 25003
		SET @NewFolderQuarter = 3
		SET @NewFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @NewSubCode = 25003
	END
	IF @TodayQuarter = 2
	BEGIN
		SET @CurrFolderQuarter = 4
		SET @CurrFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @CurrSubCode = 25004
		SET @NewFolderQuarter = 4
		SET @NewFolderYear = CAST(@TodayYear AS CHAR(2))
		SET @NewSubCode = 25004
	END
	IF @TodayQuarter = 3
	BEGIN
		SET @CurrFolderQuarter = 1
		SET @CurrFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @CurrSubCode = 25001
		SET @NewFolderQuarter = 1
		SET @NewFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @NewSubCode = 25001
	END
	IF @TodayQuarter = 4
	BEGIN
		SET @CurrFolderQuarter = 2
		SET @CurrFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @CurrSubCode = 25002
		SET @NewFolderQuarter = 2
		SET @NewFolderYear = CAST(@TodayYear + 1 AS CHAR(2))
		SET @NewSubCode = 25002
	END

	SELECT @PropertyRSN = PropertyRSN FROM Folder WHERE FolderRSN = @FolderRSN

	/* Call the procedure to create the VB folder */
	EXEC usp_CreateVBFolder @PropertyRSN, @FolderRSN, @NewFolderYear, @NewFolderQuarter, @NewSubCode	

   /* Set Folder Status to Closed (2) */
   UPDATE Folder SET StatusCode = 2
   WHERE Folder.FolderRSN = @FolderRSN

   /* Set Q1 Folder Status to Closed (2) */
	SELECT @ParentRSN = ParentRSN FROM Folder WHERE FolderRSN = @FolderRSN
    UPDATE Folder
	SET StatusCode = 2, FinalDate = getdate()
	WHERE Folder.FolderRSN = @ParentRSN
 
END


GO
