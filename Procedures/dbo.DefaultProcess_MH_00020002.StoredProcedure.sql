USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_MH_00020002]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_MH_00020002]
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
/*
MH Legal Action ProcessCode 20002
DefaultProcess_MH_00020002
*/

DECLARE @AttemptResult int
DECLARE @MHAppealUser Varchar(30)

SELECT TOP 1 @MHAppealUser = dbo.f_info_alpha(FolderRSN, 30140 /*MH Extension/Appeal Process User*/)
FROM Folder
WHERE FolderType = 'AA'
ORDER BY FolderRSN DESC

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

  EXEC usp_UpdateFolderCondition @FolderRSN, 'Review Resolution of Legal Action'

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'Review Resolution of Legal Action', @MHAppealUser,
  @FolderRSN, 'Y', getdate(), getdate(), @userID)

  UPDATE FolderProcess  /*close any open processes*/
  SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
  WHERE FolderProcess.FolderRSN = @FolderRSN
  AND FolderProcess.EndDate IS NULL

END
GO
