USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_BP_00030002]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_BP_00030002]  @ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128) as  exec RsnSetLock DECLARE @NextRSN numeric(10) SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0)
 FROM AccountBillFee
 DECLARE @NextProcessRSN numeric(10)
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0)
 FROM FolderProcess
 DECLARE @NextDocumentRSN numeric(10)
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0)
 FROM FolderDocument
BEGIN 
DECLARE @AttemptResult int 
DECLARE @attemptCk int 
DECLARE @Rough VarChar(3) 
DECLARE @Foundation VarChar(3) 
DECLARE @BalDue Money 
DECLARE @StatusCode INT 
 
 
SELECT @AttemptResult = Resultcode 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN 
AND FolderProcessAttempt.AttemptRSN =  
(SELECT MAX(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN) 
 
SELECT @Rough = InfoValue 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30053 
 
SELECT @Foundation = InfoValue 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30071 
 
 
IF @AttemptResult = 70 /*Stop Work Order*/ 
BEGIN 
 
     SELECT @attemptCk = Count(*) 
     FROM FolderProcessattempt 
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN 
     AND FolderProcessattempt.Resultcode = 125 
 
     IF @attemptCk <1 
 
     BEGIN 
     ROLLBACK TRANSACTION 
     RAISERROR('You must issue an Order to Comply prior to issuing a Stop Work Order',16,-1) 
     RETURN 
     END 
 
     ELSE 
 
     BEGIN 
     UPDATE Folder 
     SET Folder.StatusCode = 30007 /*Stop Work Order*/ 
     WHERE Folder.FolderRSN = @FolderRSN 
     OR Folder.ParentRSN = @FolderRSN 
     AND Folder.StatusCode NOT IN (2, 30005, 30003, 30004, 30006) 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
      
     END 
END 
 
IF @AttemptResult = 130 /*Stop Work Order Lifted*/ 
BEGIN 
 
	SET @StatusCode = 30002 /* Default Status to Issued */ 
	SELECT @BalDue = dbo.udf_GetFolderFeesDue(@FolderRSN) 
	IF ISNULL(@BalDue, 0.0) = 0.0 SET @StatusCode = 30022 /* If not paid in full, Status is "Awaiting Payment" */ 
 
     UPDATE Folder 
     SET Folder.StatusCode = @StatusCode 
     WHERE Folder.FolderRSN = @FolderRSN 
     --OR Folder.ParentRSN = @FolderRSN 
     --AND Folder.StatusCode = 30002 
 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE  FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30002 
     END 
  
     IF @Foundation = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode = 30001 
     END 
END 
 
IF @AttemptResult = 35 /*Legal Action*/ 
BEGIN 
 
     UPDATE Folder 
     SET Folder.StatusCode = 30008 /*Legal Action*/ 
     WHERE Folder.FolderRSN = @FolderRSN 
     OR Folder.ParentRSN = @FolderRSN 
     AND Folder.StatusCode NOT IN (2, 30005, 30003, 30004, 30006) 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
END 
 
IF @AttemptResult = 135 /*Legal Action Resolved*/ 
BEGIN 
 
	SET @StatusCode = 30002 /* Default Status to Issued */ 
	SELECT @BalDue = dbo.udf_GetFolderFeesDue(@FolderRSN) 
	IF ISNULL(@BalDue, 0.0) = 0.0 SET @StatusCode = 30022 /* If not paid in full, Status is "Awaiting Payment" */ 
 
     UPDATE Folder 
     SET Folder.StatusCode = @StatusCode 
     WHERE (Folder.FolderRSN = @FolderRSN OR Folder.ParentRSN = @FolderRSN) 
     AND Folder.StatusCode = 30008 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30002 
     END 
  
     IF @Foundation = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode = 30001 
     END 
 
END 
 
IF @AttemptResult = 20 /*Not Required*/ 
BEGIN 
    UPDATE FolderProcess 
    SET ProcessComment = 'Not Required' 
    WHERE FolderProcess.processRSN = @processRSN 
 
END  
END
GO
