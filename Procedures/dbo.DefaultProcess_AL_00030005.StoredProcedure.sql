USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_AL_00030005]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_AL_00030005]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
DECLARE @AttemptResult int
DECLARE @attemptCk int
DECLARE @Parent int
DECLARE @ValidClause VARCHAR(130)

SELECT @AttemptResult = Resultcode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @Parent = Folder.ParentRSN
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN


IF @AttemptResult = 40 /*approved*/
BEGIN

   UPDATE Folder  /*close folder*/
   SET Folder.StatusCode = 2, Folder.Finaldate = getdate()
   WHERE Folder.FolderRSN = @FolderRSN

    SELECT @ValidClause = ValidClause.ClauseText
    FROM ValidClause
    WHERE ClauseRSN = 440

    UPDATE FolderProcess /*add a comment*/
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = @ValidClause
    WHERE FolderProcess.processRSN = @processRSN

END


IF @AttemptResult = 130 /*Stop Work Order Lifted*/
BEGIN

  UPDATE Folder
  SET Folder.StatusCode = 30002 /* Issued*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
  WHERE FolderProcess.processRSN = @processRSN

  IF @Parent IS NOT NULL
  BEGIN
  UPDATE Folder
  SET StatusCode = 30002 /*issued*/
  WHERE Folder.FolderRSN = @Parent
  OR Folder.ParentRSN = @Parent
  END
END


IF @AttemptResult = 35 /*Legal Action*/
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 30008 /* Legal Action*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
  WHERE FolderProcess.processRSN = @processRSN

  IF @Parent IS NOT NULL
  BEGIN
  UPDATE Folder
  SET StatusCode = 30008 /*Legal Action*/
  WHERE Folder.FolderRSN = @Parent
  OR Folder.ParentRSN = @Parent
  END
END


IF @AttemptResult = 135 /*Legal Action Resolved*/
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 30002 /* Issued*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
  WHERE FolderProcess.processRSN = @processRSN

  IF @Parent IS NOT NULL
  BEGIN
  UPDATE Folder
  SET StatusCode = 30002 /*issued*/
  WHERE Folder.FolderRSN = @Parent
  OR Folder.ParentRSN = @Parent
  END
END

IF @AttemptResult = 70 /*Stop Work Order*/
BEGIN
     SELECT @attemptCk = Count(*)
     FROM FolderProcessattempt
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN
     AND FolderProcessattempt.Resultcode = 125

     IF @attemptCk <1

     BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('You must issue an Order to Comply prior to issuing a Stop Work  Order',16,-1)
     RETURN
     END

     ELSE IF @attemptCk >=1

     BEGIN
     UPDATE Folder
     SET Folder.StatusCode = 30007 /*Stop Work Order*/
     WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderProcess
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
     WHERE FolderProcess.processRSN = @processRSN
     

         IF @Parent IS NOT NULL
         BEGIN
         UPDATE Folder
         SET StatusCode = 30007 /*Stop Work Order*/
         WHERE Folder.FolderRSN = @Parent
         OR Folder.ParentRSN = @Parent
         END

     END
END
GO
