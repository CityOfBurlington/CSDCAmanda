USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020053]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020053]
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
/* Remedy Verification (20053) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @NextWorkCode int
DECLARE @AppealableDecisionInfoValue varchar(50)
DECLARE @ViolationFinalityInfoValue Varchar(3)
DECLARE @ResultText varchar(100)
DECLARE @InvestigationProcessOrder int
DECLARE @ViolationProcess int
DECLARE @ViolationProcessOrder int

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode, WorkCode values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Get Appealable Decision Info value and set next work codes. */

SELECT @AppealableDecisionInfoValue = FolderInfo.InfoValue
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20068

IF @SubCode = 20065 SELECT @NextWorkCode = 20109
ELSE 
BEGIN
   SELECT @NextWorkCode =
   CASE @AppealableDecisionInfoValue
      WHEN 'Grandfathering - Approved' THEN 20102
      WHEN 'Functional Family - Approved' THEN 20102
      WHEN 'Zoning Review - Approved' THEN 20102
      ELSE 0
   END
END

SELECT @ViolationFinalityInfoValue = FolderInfo.InfoValueUpper
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20071

SELECT @ResultText =
CASE @ViolationFinalityInfoValue
   WHEN 'YES' THEN 'Remedy Verified -> Violation Resolved'
   WHEN 'NO'  THEN 'Remedy Verified -> Complaint Resolved'
   ELSE ' '
END

/* Check for Violation process existence and set display order. */

SELECT @InvestigationProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20046

SELECT @ViolationProcessOrder      = @InvestigationProcessOrder + 90

SELECT @ViolationProcess = count(*)
 FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20047

/* Remedy Verified attempt result */

IF @AttemptResult = 20094
BEGIN

   UPDATE Folder
      SET Folder.StatusCode = 2, Folder.WorkCode = @NextWorkCode, 
          Folder.FinalDate = getdate(),
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> ' + @ResultText + ' (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Remedy Verified',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Remedy Verified (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of Remedy Verified attempt result */

/* Remedy Not Implemented attempt result */

IF @AttemptResult = 20101
BEGIN

   UPDATE Folder
      SET Folder.SubCode = 20065, Folder.WorkCode = 20130, Folder.IssueUser = @UserId,
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Remedy Not Implemented (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

    UPDATE FolderProcess
       SET FolderProcess.ProcessComment = 'Remedy Not Implemented',
           FolderProcess.EndDate = getdate(), 
           FolderProcess.AssignedUser = @UserID
     WHERE FolderProcess.FolderRSN = @folderRSN
       AND FolderProcess.ProcessRSN = @processRSN

    UPDATE FolderProcessAttempt
       SET FolderProcessAttempt.AttemptComment = 'Remedy Not Implemented (' + CONVERT(char(11), getdate()) + ')', 
           FolderProcessAttempt.AttemptBy = @UserID
     WHERE FolderProcessAttempt.ProcessRSN = @processRSN
       AND FolderProcessAttempt.AttemptRSN = 
           ( SELECT max(FolderProcessAttempt.AttemptRSN) 
               FROM FolderProcessAttempt
              WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

END    /* end of Remedy Not Implemented attempt result */

/* Close processes. */

IF @AttemptResult = 20094
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), 
          FolderProcess.BaseLineEndDate = getdate(), 
          FolderProcess.SignOffUser = @UserID
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.FolderRSN = @folderRSN
END

IF @AttemptResult = 20101
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), 
          FolderProcess.BaseLineEndDate = getdate(), 
          FolderProcess.SignOffUser = @UserID
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.ProcessCode IN(20042, 20043, 20044, 20045, 20046, 20049, 
                                       20050, 20051, 20052, 20053)
      AND FolderProcess.FolderRSN = @folderRSN

   IF @ViolationProcess = 0
   BEGIN 
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
       FROM FolderProcess

      INSERT INTO FolderProcess
                  ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                    ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
                    DisplayOrder, PrintFlag, MandatoryFlag, StampDate )
           VALUES ( @NextProcessRSN, @folderRSN, 20047, 80, 1,
                    getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
                    @ViolationProcessOrder, 'Y', 'Y', getdate() )
   END

   IF @ViolationProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20047
         AND FolderProcess.FolderRSN = @folderRSN
   END
END

GO
