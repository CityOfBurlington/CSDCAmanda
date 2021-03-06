USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_EC_00030007]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultProcess_EC_00030007]  @ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128) as  exec RsnSetLock DECLARE @NextRSN numeric(10) SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0)
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
DECLARE @CountChildInspections int 
DECLARE @Rough VarChar(3) 
DECLARE @UnpaidFeeCount int 
DECLARE @OpenChildCount int 
DECLARE @intDocumentRSN INT 
DECLARE @dtm15DaysForward DATETIME 
DECLARE @InfoCount INT 
DECLARE @LimitedApproval int 
DECLARE @ValidClause VARCHAR(300) 
DECLARE @BalDue Money 
DECLARE @StatusCode INT 
 
SELECT @intDocumentRSN  = dbo.udf_GetNextDocumentRSN(), 
@dtm15DaysForward = DateAdd(Day, 15, GetDate()), 
@Rough = InfoValue 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30053 
 
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
 
SELECT @CountChildInspections = count(*) 
FROM FolderProcess, Folder 
WHERE FolderProcess.DisciplineCode = 75 
AND FolderProcess.FolderRSN = Folder.FolderRSN 
AND Folder.ParentRSN = @FolderRSN 
AND FolderProcess.EndDate IS NULL 
AND FolderProcess.ProcessCode <> 30030 
 
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
 
IF @AttemptResult = 20200 /*Reinspection Required*/ 
    BEGIN 
    INSERT INTO FolderDocument (DocumentRSN, FolderRSN, DocumentCode, DocumentStatus) 
    VALUES (@intDocumentRSN, @FolderRSN, 30008, 1) 
 
    INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, InfoValueDateTime, StampDate, StampUser, Mandatory, ValueRequired) 
    VALUES(@FolderRSN, 1000, CAST(@dtm15DaysForward AS VARCHAR(30)), @dtm15DaysForward, GetDate(), @UserId, 'Y', 'Y') 
 
 
    UPDATE FolderProcess /*reopen this process*/ 
    SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
    WHERE FolderProcess.processRSN = @processRSN 
END 
 
IF @AttemptResult = 20201 /*Send Back Completion Form*/ 
    BEGIN 
    INSERT INTO FolderDocument (DocumentRSN, FolderRSN, DocumentCode, DocumentStatus) 
    VALUES (@intDocumentRSN, @FolderRSN, 30009, 1) 
 
    SELECT @InfoCount = count(InfoValue) FROM FolderInfo WHERE FolderRSN = @FolderRSN AND InfoCode = 1000 
    If @InfoCount = 0 
	BEGIN 
		INSERT INTO FolderInfo (FolderRSN, InfoCode, InfoValue, InfoValueDateTime, StampDate, StampUser, Mandatory, ValueRequired) 
		VALUES(@FolderRSN, 1000, CAST(@dtm15DaysForward AS VARCHAR(30)), @dtm15DaysForward, GetDate(), @UserId, 'Y', 'Y') 
	END 
 
	ELSE 
 
	BEGIN 
		UPDATE FolderInfo SET InfoValue = CAST(@dtm15DaysForward AS VARCHAR(30)), InfoValueDateTime = @dtm15DaysForward,  
		   StampDate = GetDate(), StampUser = @UserID, Mandatory = 'Y', ValueRequired = 'Y' 
		WHERE FolderRSN = @FolderRSN AND InfoCode = 100 
	END 
 
 
    UPDATE FolderProcess /*reopen this process*/ 
    SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
    WHERE FolderProcess.processRSN = @processRSN 
END 
 
IF @AttemptResult = 40 /*approved*/ 
BEGIN 
    IF @CountInspections <> 0 OR @UnpaidFeeCount <> 0 OR @CountChildInspections <> 0 
    BEGIN 
    ROLLBACK TRANSACTION 
    RAISERROR('FEES MUST BE PAID AND/OR YOU MUST COMPLETE ALL OTHER INSPECTIONS PRIOR TO DOING A FINAL INSPECTION',16,-1) 
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
 
IF @AttemptResult = 65 /*closed with Conditions*/ 
BEGIN 
    IF @CountInspections <> 0 OR @UnpaidFeeCount <> 0 
    BEGIN 
    ROLLBACK TRANSACTION 
    RAISERROR('YOU MUST COMPLETE ALL OTHER INSPECTIONS PRIOR TO DOING FINAL ELECTRICAL INSPECTION',16,-1) 
    RETURN 
    END 
 
    ELSE 
 
    UPDATE Folder 
    SET StatusCode = 2, FinalDate = getdate() 
    WHERE Folder.FolderRSN = @FolderRSN 
 
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
     AND FolderProcess.ProcessCode =30006 
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
     WHERE (Folder.FolderRSN = @FolderRSN) 
 
     UPDATE FolderProcess /*reopen this process*/ 
     SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
     WHERE FolderProcess.processRSN = @processRSN 
 
     IF @Rough = 'No' 
     BEGIN 
     DELETE 
    FROM FolderProcess 
     WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode =30006 
     END 
END 
 
IF @AttemptResult = 20 /*Not Required*/ 
BEGIN 
     UPDATE FolderProcess 
     SET ProcessComment = 'Not Required' 
     WHERE FolderProcess.ProcessRSN = @ProcessRSN 
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
  SET Folder.StatusCode = 30019 
*/ 
  UPDATE FolderProcess /*reopen this process*/ 
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1 
  WHERE FolderProcess.processRSN = @processRSN 
 
END  
END
GO
