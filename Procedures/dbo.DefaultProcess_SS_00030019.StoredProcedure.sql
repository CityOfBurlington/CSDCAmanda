USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_SS_00030019]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_SS_00030019]  @ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128) as  exec RsnSetLock DECLARE @NextRSN numeric(10) SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0)
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
DECLARE @CountInspections int 
DECLARE @Rough VarChar(3) 
DECLARE @UnpaidFeeCount int 
DECLARE @LimitedApproval int 
DECLARE @ValidClause VARCHAR(300) 
DECLARE @BalDue Money 
DECLARE @StatusCode INT 
 
SELECT @Rough = InfoValue 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30053 
 
SELECT @AttemptResult = Resultcode 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN 
AND FolderProcessAttempt.AttemptRSN =  
(SELECT MAX(FolderProcessAttempt.AttemptRSN) 
FROM FolderProcessAttempt 
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN) 
 
SELECT @CountInspections = count(*) 
FROM FolderProcess 
WHERE FolderProcess.FolderRSN = @FolderRSN 
AND FolderProcess.EndDate IS NULL 
 
SELECT @UnpaidFeeCount = count(*) 
FROM AccountBill 
WHERE AccountBill.FolderRSN = @FolderRSN 
AND AccountBill.PaidinFullFlag = 'N' 
 
SELECT @LimitedApproval = count(*) FROM FolderProcessAttempt 
WHERE FolderRSN = @FolderRSN AND (ResultCode = 30108) AND  
(AttemptRSN = (SELECT MAX(AttemptRSN) AS Expr1 FROM FolderProcessAttempt AS FPA2 
WHERE (dbo.FolderProcessAttempt.ProcessRSN = ProcessRSN))) 
 
IF @AttemptResult = 40 /*approved*/ 
BEGIN 
    IF @CountInspections <>0 OR @UnpaidFeeCount <>0 
        BEGIN 
        ROLLBACK TRANSACTION 
        RAISERROR('FEES MUST BE PAID OR YOU MUST COMPLETE ALL OTHER INSPECTIONS PRIOR TO DOING A FINAL INSPECTION',16,-1) 
        RETURN 
        END 
 
    ELSE 
 
    IF @LimitedApproval <> 0 
    BEGIN 
    ROLLBACK TRANSACTION 
    RAISERROR('THERE IS AT LEAST ONE PROCESS WITH LIMITED APPROVAL.',16,-1) 
    RETURN 
    END 
 
    ELSE  
 
    UPDATE Folder 
        SET StatusCode = 2, FinalDate = getdate() 
        WHERE Folder.FolderRSN = @FolderRSN 
 
    SELECT @ValidClause = ValidClause.ClauseText 
    FROM ValidClause 
    WHERE ClauseRSN = 440 
 
    UPDATE FolderProcess /*add a comment*/ 
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = @ValidClause 
    WHERE FolderProcess.processRSN = @processRSN 
 
END 
 
IF @AttemptResult = 60 /*canceled*/ 
BEGIN 
    UPDATE Folder 
 SET Folder.StatusCode = 30005, FinalDate = GetDate() 
    WHERE Folder.FolderRSN = @FolderRSN 
 
    UPDATE FolderProcess /*add a comment*/ 
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = 'Process canceled' 
    WHERE FolderProcess.processRSN = @processRSN 
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
     RAISERROR('You must issue an Order to Comply prior to issuing a Stop Work Order',16,-1) 
     RETURN 
     END 
 
     ELSE 
 
     BEGIN 
     UPDATE Folder 
     SET Folder.StatusCode = 30007 /*Stop Work Order*/ 
     WHERE Folder.FolderRSN = @FolderRSN 
 
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
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30018 
     END 
  
END 
 
IF @AttemptResult = 35 /*Legal Action*/ 
BEGIN 
 
     UPDATE Folder 
     SET Folder.StatusCode = 30008 /*Legal Action*/ 
     WHERE Folder.FolderRSN = @FolderRSN 
 
 
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
     WHERE Folder.FolderRSN = @FolderRSN 
 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
     FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30018 
     END 
END 
 
IF @AttemptResult = 20 /*Not Required*/ 
BEGIN 
    UPDATE FolderProcess 
    SET ProcessComment = 'Not Required' 
    WHERE FolderProcess.processRSN = @processRSN 
 
END 
 
IF @AttemptResult = 30150 /*closed administratively*/ 
BEGIN 
 
    /*RAISERROR('Testing Administrative Close',16,-1)*/ 
 
    UPDATE Folder 
    SET Folder.StatusCode = 2, FinalDate = GetDate() 
    WHERE Folder.FolderRSN = @FolderRSN 
 
    SELECT @ValidClause = ValidClause.ClauseText 
    FROM ValidClause 
    WHERE ClauseRSN = 439 
 
    UPDATE FolderProcess /*add a comment*/ 
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = @ValidClause 
    WHERE FolderProcess.processRSN = @processRSN 
 
END 
 
IF @AttemptResult = 30108  /*limited approval*/ 
BEGIN 
 
  /*RAISERROR('Testing Pending Approval',16,-1)*/ 
 
/* This logic removed per Ned Holt - 12/15/2010  
  UPDATE Folder /*change folder status to Pending Approval */ 
  SET Folder.StatusCode = 30019, Folder.Finaldate = getdate() 
  WHERE Folder.FolderRSN = @FolderRSN 
*/ 
  UPDATE FolderProcess /*reopen this process*/ 
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
  WHERE FolderProcess.processRSN = @processRSN 
 
END  
END
GO
