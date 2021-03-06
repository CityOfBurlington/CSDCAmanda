USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020052]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020052]
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
/* Review Requests (20052) version 1 */

DECLARE @AttemptResult int
DECLARE @FolderType varchar(2)
DECLARE @FolderStatus int
DECLARE @InDate datetime
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @FolderConditions varchar(2000)

DECLARE @InvestigationInfoOrder int
DECLARE @InvestigationProcessOrder int
DECLARE @SCMemoProcessStatus int

DECLARE @GrandfatherRequestInfoOrder int
DECLARE @GrandfatherRequestInfoField int
DECLARE @GrandfatherDecisionInfoOrder int
DECLARE @GrandfatherDecisionInfoField int
DECLARE @GrandfatherDecisionInfoValue datetime
DECLARE @GrandfatherProcess int
DECLARE @GrandfatherProcessOrder int
DECLARE @GrandfatherProcessAttempt int

DECLARE @FuncFamilyRequestInfoOrder int
DECLARE @FuncFamilyRequestInfoField int
DECLARE @FuncFamilyDecisionInfoOrder int
DECLARE @FuncFamilyDecisionInfoField int
DECLARE @FuncFamilyDecisionInfoValue datetime
DECLARE @FuncFamilyProcess int
DECLARE @FuncFamilyProcessOrder int
DECLARE @FuncFamilyProcessAttempt int

DECLARE @ZoningRevRequestInfoOrder int
DECLARE @ZoningRevRequestInfoField int
DECLARE @ZoningRevDecisionInfoOrder int
DECLARE @ZoningRevDecisionInfoField int
DECLARE @ZoningRevDecisionInfoValue datetime
DECLARE @ZoningPermitNoInfoOrder int
DECLARE @ZoningPermitNoInfoField int
DECLARE @ZoningRevProcess int
DECLARE @ZoningRevProcessOrder int
DECLARE @ZoningRevProcessAttempt int

DECLARE @ShowCauseProcessOrder int
DECLARE @ReviewRequestsProcessOrder int
DECLARE @InitiateAppealProcessOrder int
DECLARE @AppealProcessOrder int
DECLARE @MuniTicketProcessOrder int
DECLARE @ViolationProcessOrder int
DECLARE @RemedyVerifyProcessOrder int

/* Get Attempt Result */

SELECT @AttemptResult = FolderProcessAttempt.ResultCode
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @processRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT max(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

/* Get Folder Type, Folder Status, Initialization Date, SubCode, WorkCode, and
   Conditions values. */

SELECT @FolderType = Folder.FolderType, 
       @FolderStatus = Folder.StatusCode,
       @InDate = Folder.InDate,
       @SubCode = Folder.SubCode,
       @WorkCode = Folder.WorkCode,
       @FolderConditions = Folder.FolderCondition
  FROM Folder
 WHERE Folder.FolderRSN = @folderRSN

/* Set display orders for adding Info fields based upon the Investigation Decision 
   Date order. */

SELECT @InvestigationInfoOrder = ISNULL(FolderInfo.DisplayOrder, 70)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20059

SELECT @GrandfatherRequestInfoOrder  = @InvestigationInfoOrder + 10
SELECT @GrandfatherDecisionInfoOrder = @InvestigationInfoOrder + 20
SELECT @FuncFamilyRequestInfoOrder   = @InvestigationInfoOrder + 30
SELECT @FuncFamilyDecisionInfoOrder  = @InvestigationInfoOrder + 40
SELECT @ZoningRevRequestInfoOrder    = @InvestigationInfoOrder + 50
SELECT @ZoningPermitNoInfoOrder      = @InvestigationInfoOrder + 60
SELECT @ZoningRevDecisionInfoOrder   = @InvestigationInfoOrder + 70

/* Set display orders for adding processes based upon Investigation. */

SELECT @InvestigationProcessOrder = ISNULL(FolderProcess.DisplayOrder, 100)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20046

SELECT @ShowCauseProcessOrder      = @InvestigationProcessOrder + 10
SELECT @ReviewRequestsProcessOrder = @InvestigationProcessOrder + 20
SELECT @GrandfatherProcessOrder    = @InvestigationProcessOrder + 30
SELECT @FuncFamilyProcessOrder     = @InvestigationProcessOrder + 40
SELECT @ZoningRevProcessOrder      = @InvestigationProcessOrder + 50
SELECT @InitiateAppealProcessOrder = @InvestigationProcessOrder + 60
SELECT @AppealProcessOrder         = @InvestigationProcessOrder + 70
SELECT @MuniTicketProcessOrder     = @InvestigationProcessOrder + 80
SELECT @ViolationProcessOrder      = @InvestigationProcessOrder + 90
SELECT @RemedyVerifyProcessOrder   = @InvestigationProcessOrder + 100

/* Check for various date Info field existence, and values. */

SELECT @GrandfatherRequestInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20053

SELECT @GrandfatherDecisionInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20054

SELECT @GrandfatherDecisionInfoValue = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20054

SELECT @FuncFamilyRequestInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20055

SELECT @FuncFamilyDecisionInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20056

SELECT @FuncFamilyDecisionInfoValue = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20056

SELECT @ZoningRevRequestInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20057

SELECT @ZoningRevDecisionInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20058

SELECT @ZoningPermitNoInfoField = count(*)
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20072

SELECT @ZoningRevDecisionInfoValue = FolderInfo.InfoValueDateTime
  FROM FolderInfo
 WHERE FolderInfo.FolderRSN = @folderRSN
   AND FolderInfo.InfoCode = 20058

/* Check for various Process existence, and attempt results. */

SELECT @GrandfatherProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20043

SELECT @FuncFamilyProcess = count(*)
 FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20044

SELECT @ZoningRevProcess = count(*)
  FROM FolderProcess
 WHERE FolderProcess.FolderRSN = @folderRSN
   AND FolderProcess.ProcessCode = 20045

SELECT @GrandfatherProcessAttempt = count(*)
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = 
      (SELECT FolderProcess.ProcessRSN
         FROM FolderProcess
        WHERE FolderProcess.FolderRSN = @folderRSN
          AND FolderProcess.ProcessCode = 20043)

SELECT @FuncFamilyProcessAttempt = count(*)
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = 
      (SELECT FolderProcess.ProcessRSN
         FROM FolderProcess
        WHERE FolderProcess.FolderRSN = @folderRSN
          AND FolderProcess.ProcessCode = 20044)

SELECT @ZoningRevProcessAttempt = count(*)
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = 
      (SELECT FolderProcess.ProcessRSN
         FROM FolderProcess
        WHERE FolderProcess.FolderRSN = @folderRSN
          AND FolderProcess.ProcessCode = 20045)

/* Grandfathering Request attempt result */

IF @AttemptResult = 20108
BEGIN

   UPDATE Folder
      SET Folder.SubCode = 20061, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Grandfathering Request (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Grandfathering Request',
          FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = @UserID
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = 'Grandfathering Request (' + CONVERT(char(11), getdate()) + ')', 
          FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @processRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @GrandfatherRequestInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, 
                    InfoValue, InfoValueDateTime, InfoValueUpper, InfoValueNumeric, 
                    PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20053, @GrandfatherRequestInfoOrder, 
                    CONVERT(CHAR(11), getdate()), getdate(), UPPER(CONVERT(CHAR(11), getdate())), 0, 
                    'Y', getdate(), @UserID, 'N', 'N' )
   END

   IF @GrandfatherDecisionInfoField = 0
   BEGIN
    INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20054, @GrandfatherDecisionInfoOrder, 'Y', 
                    getdate(), @UserID, 'N', 'N' )
   END

   IF @GrandfatherProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
             ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
               ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
               AssignedUser, DisplayOrder,
               PrintFlag, MandatoryFlag, StampDate, StampUser )
      VALUES ( @NextProcessRSN, @folderRSN, 20043, 80, 1,
                getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
                @UserID, @GrandfatherProcessOrder, 
                'Y', 'Y', getdate(), @UserID )
   END

   IF @GrandfatherProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, FolderProcess.EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20043
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @FuncFamilyProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
       WHERE FolderProcess.ProcessCode = 20044
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @ZoningRevProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
       WHERE FolderProcess.ProcessCode = 20045
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @FuncFamilyDecisionInfoField > 0 AND @FuncFamilyDecisionInfoValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20055
 
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20056
   END

   IF @ZoningRevDecisionInfoField > 0 AND @ZoningRevDecisionInfoValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20057
 
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20058

      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20072
   END

END   /* End of Grandfather Request attempt result */

/* Functional Family Request attempt result */

IF @AttemptResult = 20109
BEGIN

   UPDATE Folder
      SET Folder.SubCode = 20062, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Functional Family Request (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Functional Family Request',
          FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = @UserID
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = 'Functional Family Request (' + CONVERT(char(11), getdate()) + ')', 
          FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @processRSN
    AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcessAttempt
  WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @FuncFamilyRequestInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, 
                    InfoValue, InfoValueDateTime, InfoValueUpper, InfoValueNumeric, 
                    PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20055,  @FuncFamilyRequestInfoOrder, 
                    CONVERT(CHAR(11), getdate()), getdate(), UPPER(CONVERT(CHAR(11), getdate())), 0, 
                       'Y', getdate(), @UserID, 'N', 'N' )
   END

   IF @FuncFamilyDecisionInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                  ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                    StampDate, StampUser, Mandatory, ValueRequired )
           VALUES ( @FolderRSN, 20056, @FuncFamilyDecisionInfoOrder, 'Y', 
                    getdate(), @UserID, 'N', 'N' )
   END

   IF @FuncFamilyProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
                ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                  ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
                  AssignedUser, DisplayOrder,
                  PrintFlag, MandatoryFlag, StampDate, StampUser )
         VALUES ( @NextProcessRSN, @folderRSN, 20044, 80, 1,
                  getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
                  @UserID, @FuncFamilyProcessOrder, 
                  'Y', 'Y', getdate(), @UserID )
   END

   IF @FuncFamilyProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20044
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @GrandfatherProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
       WHERE FolderProcess.ProcessCode = 20043
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @ZoningRevProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
       WHERE FolderProcess.ProcessCode = 20045
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @GrandfatherDecisionInfoField > 0 AND @GrandfatherDecisionInfoValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20053
 
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20054
   END

   IF @ZoningRevDecisionInfoField > 0 AND @ZoningRevDecisionInfoValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20057
 
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20058

      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20072
   END

END   /* End of Functional Family Request attempt result */

/* Zoning Review Request attempt result */

IF @AttemptResult = 20110
BEGIN
   UPDATE Folder
      SET Folder.SubCode = 20063, 
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Zoning Review Request (' + CONVERT(char(11), getdate()) + ')'))
    WHERE Folder.FolderRSN = @folderRSN

   UPDATE FolderProcess
      SET FolderProcess.ProcessComment = 'Zoning Review Request',
          FolderProcess.EndDate = NULL, 
          FolderProcess.AssignedUser = @UserID
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN

   UPDATE FolderProcessAttempt
      SET FolderProcessAttempt.AttemptComment = 'Zoning Review Request (' + CONVERT(char(11), getdate()) + ')', 
          FolderProcessAttempt.AttemptBy = @UserID
    WHERE FolderProcessAttempt.ProcessRSN = @processRSN
      AND FolderProcessAttempt.AttemptRSN = 
          ( SELECT max(FolderProcessAttempt.AttemptRSN) 
              FROM FolderProcessAttempt
             WHERE FolderProcessAttempt.ProcessRSN = @processRSN )

   IF @ZoningRevRequestInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, 
                  InfoValue, InfoValueDateTime, InfoValueUpper, InfoValueNumeric, 
                  PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 20057,  @ZoningRevRequestInfoOrder, 
                  CONVERT(CHAR(11), getdate()), getdate(), UPPER(CONVERT(CHAR(11), getdate())), 0, 
                  'Y', getdate(), @UserID, 'N', 'N' )
   END

   IF @ZoningRevDecisionInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 20058, @ZoningRevDecisionInfoOrder, 'Y', 
                  getdate(), @UserID, 'N', 'N' )
   END

   IF @ZoningPermitNoInfoField = 0
   BEGIN
      INSERT INTO FolderInfo
                ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                  StampDate, StampUser, Mandatory, ValueRequired )
         VALUES ( @FolderRSN, 20072, @ZoningPermitNoInfoOrder, 'Y', 
                  getdate(), @UserID, 'N', 'N' )
   END

   IF @ZoningRevProcess = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
                ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                  ScheduleDate, ScheduleEndDate, BaselineStartDate, BaselineEndDate,
                  AssignedUser, DisplayOrder,
                  PrintFlag, MandatoryFlag, StampDate, StampUser )
         VALUES ( @NextProcessRSN, @folderRSN, 20045, 80, 1,
                  getdate(), (getdate() + 180), getdate(), (getdate() + 180), 
                  @UserID, @ZoningRevProcessOrder, 
                  'Y', 'Y', getdate(), @UserID )
   END

   IF @ZoningRevProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 1, EndDate = NULL
       WHERE FolderProcess.ProcessCode = 20045
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @FuncFamilyProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
       WHERE FolderProcess.ProcessCode = 20044
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @GrandfatherProcess > 0
   BEGIN
      UPDATE FolderProcess
         SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
       WHERE FolderProcess.ProcessCode = 20043
         AND FolderProcess.FolderRSN = @folderRSN
   END

   IF @GrandfatherDecisionInfoField > 0 AND @GrandfatherDecisionInfoValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20053
 
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20054
   END

   IF @FuncFamilyDecisionInfoField > 0 AND @FuncFamilyDecisionInfoValue IS NULL
   BEGIN
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20055
 
      DELETE FROM FolderInfo
            WHERE FolderInfo.FolderRSN = @folderRSN
              AND FolderInfo.InfoCode = 20056
   END

END   /* End of Zoning Review Request attempt result*/

/* Set WorkCode if in the Show Cause Memo Response phase. */

SELECT @SCMemoProcessStatus = FolderProcess.StatusCode
  FROM FolderProcess
 WHERE FolderProcess.ProcessCode = 20042
   AND FolderProcess.FolderRSN = @folderRSN

IF @SCMemoProcessStatus = 1 
BEGIN
   UPDATE Folder
      SET Folder.WorkCode = 20111         /* SC Memo Response Received */
    WHERE Folder.FolderRSN = @folderRSN
END

/* Re-open process. Process closed by Zoning Investigation process. */

IF @AttemptResult IN(20108, 20109, 20110)
BEGIN
   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 1, 
          FolderProcess.ScheduleDate = getdate(),
          FolderProcess.EndDate = NULL, 
          FolderProcess.SignOffUser = NULL
    WHERE FolderProcess.ProcessRSN = @processRSN
      AND FolderProcess.FolderRSN = @folderRSN
END

GO
