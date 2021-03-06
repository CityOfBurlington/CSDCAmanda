USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_BP_00030003]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_BP_00030003]
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
DECLARE @attemptCk int
DECLARE @CountParentInspections int
DECLARE @CountChildInspections int
DECLARE @CORequired varchar(3)
DECLARE @Rough VarChar(3)
DECLARE @Foundation VarChar(3)
DECLARE @UnpaidFeeCount int
DECLARE @LimitedApproval int
DECLARE @ValidClause VARCHAR(300)
DECLARE @StatusCode INT
DECLARE @BalDue Money

SELECT @AttemptResult = Resultcode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
(SELECT MAX(FolderProcessAttempt.AttemptRSN)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @CountParentInspections = count(*)
FROM FolderProcess
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.DisciplineCode = 75 /*inspections*/
AND FolderProcess.ProcessCode<>36000
AND FolderProcess.EndDate IS NULL

SELECT @CountChildInspections = count(*)
FROM FolderProcess, Folder
WHERE FolderProcess.DisciplineCode = 75
AND FolderProcess.FolderRSN = Folder.FolderRSN
AND Folder.ParentRSN = @FolderRSN
AND FolderProcess.EndDate IS NULL
AND FolderProcess.ProcessCode <> 30030

SELECT @CORequired = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30059

IF @CORequired IS NULL BEGIN
SET @CORequired= 'No'
END

SELECT @Rough = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30053

SELECT @Foundation = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30071

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
    IF @UnpaidFeeCount <> 0
  BEGIN
    ROLLBACK TRANSACTION
RAISERROR('THERE ARE UNPAID FEES FOR THIS BUILDING PERMIT.',16,-1)
    RETURN
    END

    IF @CountChildInspections <> 0
    BEGIN
    ROLLBACK TRANSACTION
    RAISERROR('THERE ARE INCOMPLETE INSPECTIONS FOR CHILD FOLDERS ON THIS BUILDING PERMIT',16,-1)
    RETURN
    END

    IF @CountParentInspections <> 0
    BEGIN
    ROLLBACK TRANSACTION
    RAISERROR('THERE ARE INCOMPLETE INSPECTIONS FOR PARENT FOLDERS ON THIS BUILDING PERMIT',16,-1)
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

    IF @CORequired = 'No'
    UPDATE Folder
    SET Folder.StatusCode = 2, FinalDate = GetDate()
    WHERE Folder.FolderRSN = @FolderRSN

    ELSE
    
    UPDATE Folder
    SET StatusCode = 30003, FinalDate = getdate()
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

  UPDATE Folder /*change folder status to Pending Approval */
  SET Folder.StatusCode = 30019
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess /*reopen this process*/
  SET ScheduleDate = getdate(), Enddate=Null, StatusCode = 1
  WHERE FolderProcess.processRSN = @processRSN

END

IF @AttemptResult = 30155  /*Close Limited Approval */
BEGIN

    /*RAISERROR('Testing Close Limited Approval',16,-1)*/

    UPDATE Folder
    SET Folder.StatusCode = 2, FinalDate = GetDate()
    WHERE Folder.FolderRSN = @FolderRSN

    SELECT @ValidClause = ValidClause.ClauseText
 FROM ValidClause
    WHERE ClauseRSN = 466

    UPDATE FolderProcess /*add a comment*/
    SET Enddate=getdate(), StatusCode = 2, ProcessComment = @ValidClause
    WHERE FolderProcess.processRSN = @processRSN

END

GO
