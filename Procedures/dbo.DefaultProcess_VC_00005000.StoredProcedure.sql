USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VC_00005000]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VC_00005000]
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
DECLARE @AttemptCk int


SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @attemptresult = 5001 /*First Offense */
BEGIN
SELECT @attemptCk = Count(*)
     FROM FolderProcessattempt
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN
     AND FolderProcessattempt.Resultcode = 5000

     IF @attemptCk <1
     BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('YOU MUST ISSUE A WARNING PRIOR TO ISSUING A FIRST TICKET',16,-1)
     RETURN
     
     END
ELSE

  BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5001 /*Ticket 1 Issued*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+3, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
  END
END


IF @attemptresult = 5002 /*Second Offense */
BEGIN
SELECT @attemptCk = Count(*)
     FROM FolderProcessattempt
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN
     AND FolderProcessattempt.Resultcode = 5001

     IF @attemptCk <1
     BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('YOU MUST ISSUE A FIRST TICKET PRIOR TO ISSUING A SECOND TICKET',16,-1)
     RETURN
     
     END
ELSE

  BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5002 /*Ticket 2 Issued*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+3, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
  END
END

IF @attemptresult = 5003 /*Third Offense */
BEGIN
SELECT @attemptCk = Count(*)
     FROM FolderProcessattempt
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN
     AND FolderProcessattempt.Resultcode = 5002

     IF @attemptCk <1
     BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('YOU MUST ISSUE A SECOND TICKET PRIOR TO ISSUING A THIRD TICKET',16,-1)
     RETURN
     
     END
ELSE

  BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5003 /*Ticket 3 Issued*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+3, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
  END
END



IF @attemptresult = 5000  
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5000 /*Warning Issued*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+3, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
END



IF @attemptresult = 5005 /*Appealed */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5007 /*Appeal*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+3, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

IF @attemptresult = 5004 /*Zoning Permit Obtained*/
BEGIN
   UPDATE Folder
   SET Folder.StatusCode = 5016
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderProcess
   SET ScheduleDate = getdate() +15, EndDate = null, StatusCode=1,assigneduser = 'JFrancis'
   WHERE FolderProcess.ProcessRSN = @ProcessRSN
END     


IF @attemptresult = 5010 /*Notice of Violation*/
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5004
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+3, EndDate = NULL, StatusCode = 1
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

IF @attemptresult = 5008 /*Temp CofO */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5012, Folder.Expirydate = getdate()+ 90
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+90, EndDate = NULL, StatusCode = 1, AssignedUser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
END


IF @attemptresult = 5007 /*Resolved */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 2, finaldate = getdate()
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET EndDate = GetDate(), StatusCode = 2, ProcessComment = 'Violation Resolved' 
  WHERE FolderProcess.ProcessRSN = 5001
 AND FolderProcess.FolderRSN = @FolderRSN

END


IF @attemptresult = 5009 /*Final CofO */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 2, Finaldate = getdate()
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET  EndDate = Getdate(), StatusCode = 2, ProcessComment = 'Violation Resolved' 
  WHERE FolderProcess.ProcessRSN = 5001
  AND FolderProcess.FolderRSN = @FolderRSN

END



IF @attemptresult = 5006 /*Litigation*/
BEGIN
   UPDATE Folder
   SET Folder.StatusCode = 5008
   WHERE Folder.FolderRSN = @FolderRSN
END




GO
