USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QZ_00020056]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QZ_00020056]
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
/* QZ Retarter (20056). Sets folder back to initial state of Complaint Received. */

DECLARE @intAttemptResult int
DECLARE @varFolderType varchar(2)
DECLARE @intFolderStatus int
DECLARE @intSubCode int
DECLARE @intWorkCode int

/* Get attempt result and folder info */

SELECT @intAttemptResult = FolderProcessAttempt.ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = ( 
	SELECT MAX(FolderProcessAttempt.AttemptRSN) 
	FROM FolderProcessAttempt
	WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN )

SELECT @varFolderType = Folder.FolderType, 
	@intFolderStatus = Folder.StatusCode,
	@intSubCode = Folder.SubCode,
	@intWorkCode = Folder.WorkCode 
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

IF @intAttemptResult = 20136	/* Back to Complaint Received */
BEGIN
	UPDATE Folder
	SET Folder.StatusCode = 1, Folder.SubCode = 20059, 
		Folder.WorkCode = NULL, Folder.IssueDate = NULL, 
		Folder.ExpiryDate = NULL, Folder.FinalDate = NULL, 
		Folder.IssueUser = NULL, Folder.FolderCondition = NULL
	WHERE Folder.FolderRSN = @FolderRSN

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = 'No', FolderInfo.InfoValueUpper = 'NO' 
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = 20071		/* Violation Finality */
	
	UPDATE FolderInfo
	SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL  
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = 20059		/* Investigation Decision Date */

	UPDATE FolderInfo
	SET FolderInfo.InfoValue = 'None', FolderInfo.InfoValueUpper = 'NONE' 
	WHERE FolderInfo.FolderRSN = @FolderRSN 
	AND FolderInfo.InfoCode = 20068		/* Appealable Decision */

	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate()
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.StatusCode = 1 
	AND FolderProcess.ProcessCode IN ( 20042, 20043, 20044, 20045, 20047, 
		20050, 20051, 20052, 20053 )

	UPDATE FolderProcess
	SET FolderProcess.StatusCode = 1, 
		FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
		FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL, 
		FolderProcess.ProcessComment = NULL
	WHERE FolderProcess.FolderRSN = @FolderRSN
	AND FolderProcess.ProcessCode = 20046	/* Investigation */
END

/* Reopen QZ Restarter */

UPDATE FolderProcess
SET FolderProcess.StatusCode = 1, 
	FolderProcess.EndDate = NULL, FolderProcess.DisplayOrder = 999
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessRSN = @ProcessRSN 


GO
