USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_BP_00030004]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_BP_00030004]
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
DECLARE @CurrentStatus int
DECLARE @ChildStatus int

DECLARE @ParentFolderRSN int
DECLARE @AttemptDate Datetime

SELECT @AttemptResult = Resultcode, 
       @AttemptDate = AttemptDate 
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @CurrentStatus = Folder.StatusCode
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

SELECT @ChildStatus = count(*)
FROM Folder
WHERE Folder.FolderRSN IN (SELECT Folder.FolderRSN FROM Folder
                          WHERE Folder.ParentRSN = @FolderRSN)
AND Folder.StatusCode NOT IN (2, 30005) /*closed or cancelled*/

IF @ChildStatus <> 0
BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('ALL FINAL INSPECTIONS MUST BE COMPLETED ON CHILD FOLDERS PRIOR TO ISSUE OF C OF O',16,-1)
     RETURN
END


IF @AttemptResult = 110 /*Issued*/
BEGIN
  /*
  IF @CurrentStatus NOT IN (30003, 30004) finalled or temp c of o
  BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('ALL FINAL INSPECTIONS MUST BE COMPLETED PRIOR TO ISSUE OF C OF O',16,-1)
     RETURN
  END
  */

  BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 2, Folder.FinalDate = getdate()
  WHERE Folder.FolderRSN = @FolderRSN

  /*Start - Sangeet Mar 03, 2002*/
  Select @ParentFolderRSN = ParentRSN 
  From Folder
  Where FolderRSN = @FolderRSN

  Update FolderProcess
  Set ScheduleDate = @AttemptDate
  Where FolderRSN = @ParentFolderRSN
  And ProcessCode = 10001
  /*End - Sangeet Mar 03, 2002*/
  END
END

IF @AttemptResult = 30109 /*Temp C of O*/
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 30004 /*temp C of O*/,folder.expirydate = getdate()+90
  WHERE Folder.FolderRSN = @FolderRSN
 
  UPDATE FolderProcess  /*reopen this process and schedule for 90 days*/
  SET StatusCode = 1, EndDate = NULL, ScheduleDate = getdate()+90
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

IF @AttemptResult = 20 /*Not Required*/

  IF @CurrentStatus NOT IN (30003, 30004) /*finalled or temp c of o*/
  BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('ALL FINAL INSPECTIONS MUST BE COMPLETED PRIOR TO ISSUE OF C OF O',16,-1)
     RETURN
  END

  BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 2, Folder.FinalDate = getdate()
  WHERE Folder.FolderRSN = @FolderRSN

  /*Start - Sangeet Mar 03, 2002*/
  Select @ParentFolderRSN = ParentRSN 
  From Folder
  Where FolderRSN = @FolderRSN

  Update FolderProcess
  Set ScheduleDate = @AttemptDate
  Where FolderRSN = @ParentFolderRSN
  And ProcessCode = 10001
  /*End - Sangeet Mar 03, 2002*/
END

GO
