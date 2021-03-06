USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QB_00020002]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QB_00020002]
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
DECLARE @AttemptResult int

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @AttemptResult = 20018 /*Violation Resolved*/
BEGIN

  UPDATE Folder
  SET StatusCode = 2, FinalDate = getdate()
  WHERE Folder.FolderRSN = @FolderRSN

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'REVIEW RESOLUTION OF LEGAL ACTION', 'KBUTLER',
  @FolderRSN, 'Y', getdate(), getdate(), @userID)

  UPDATE FolderProcess  /*close any open processes*/
  SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
  WHERE FolderProcess.FolderRSN = @FolderRSN
  AND FolderProcess.EndDate IS NULL

END
GO
