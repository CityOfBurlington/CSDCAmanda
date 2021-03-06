USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZB_00010006]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZB_00010006]
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
  
/* Pre-Release Conditions (10006) 
   Used when application approved, but applicant must provide materials or info 
   before the permit can be released. */

/* This procedure works in concert with dbo.uspZoningFolderCleanup, which changes 
   Folder.StatusCode when the zoning appeal period ends (Folder.ExpiryDate).  
   The next status is set by 
   dbo.udf_ZoningPreReleaseConditionsFolderStatus (@FolderRSN, getdate()) .
   If pre-release conditions are met and the appeal period is not over, then the 
   status is changed to Appeal Period - APP (10002). 
   If pre-release conditions have been met when the appeal period is over, 
   then folder status is set to to Ready to Release (10005).
   If pre-release conditions have not been met (indicated by folder status 
   Appeal Period - PRC) when the appeal period is over, dbo.uspZoningFolderCleanup 
   changes the folder status to Pre-Release Conditions (10018). */
   
/* Add the Abandon Permit process when a permit with unmet pre-release conditions 
   is to be relinquished. */

DECLARE @intAttemptResult int
DECLARE @dtAttemptDate datetime
DECLARE @intAbandonProcessDisplayOrder int
DECLARE @intNextProcessRSN int

/* Get attempt result */

SELECT @intAttemptResult = FolderProcessAttempt.ResultCode,
	   @dtAttemptDate = FolderProcessAttempt.AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
	( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
	  FROM FolderProcessAttempt
	  WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

IF @intAttemptResult = 10028                    /* Pre-Release Conditions Met */
BEGIN
	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = 'Pre-Release Conditions Met'
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessRSN = @ProcessRSN

	UPDATE Folder
	SET Folder.StatusCode = dbo.udf_ZoningPreReleaseConditionsFolderStatus (@FolderRSN, getdate()), 
		Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Pre-Release Conditions Met (' + CONVERT(CHAR(11), @dtAttemptDate) + ')' ))
	WHERE Folder.FolderRSN = @FolderRSN
END

IF @intAttemptResult = 10071                    /* Request to Relinquish Permit */
BEGIN
	UPDATE FolderProcess
	SET FolderProcess.ProcessComment = 'Request to Relinqiush Permit'
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessRSN = @ProcessRSN

	UPDATE Folder
	SET Folder.FolderCondition = CONVERT(text,(rtrim(CONVERT(varchar(2000),foldercondition)) + ' -> Request to Relinquish Permit (' + CONVERT(CHAR(11), @dtAttemptDate) + ')' ))
	WHERE Folder.FolderRSN = @FolderRSN

	/* Insert Abandon Permit process */ 

	SELECT @intAbandonProcessDisplayOrder = FolderProcess.DisplayOrder + 70 
	FROM FolderProcess
	WHERE FolderProcess.FolderRSN = @FolderRSN 
	AND FolderProcess.ProcessCode = 10006 
	AND FolderProcess.ProcessRSN = @ProcessRSN 

	SELECT @intNextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
	FROM FolderProcess

	INSERT INTO FolderProcess 
		( ProcessRSN, FolderRSN, ProcessCode, ScheduleDate, StatusCode, DisciplineCode, 
		   PassedFlag, PrintFlag, StampDate, StampUser, DisplayOrder )
	VALUES ( @intNextProcessRSN, @FolderRSN, 10019, getdate(), 1, 45, 
			 'N', 'Y', getdate(), @UserID, @intAbandonProcessDisplayOrder )
END
GO
