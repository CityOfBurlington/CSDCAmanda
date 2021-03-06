USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_MH_00020041]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_MH_00020041]
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
MH Admin Additional F/U Inspection ProcessCode 20041
DefaultProcess_MH_00020041
*/

DECLARE @AttemptResult INT
DECLARE @intDeficiencies INT
DECLARE @AttemptDate DATETIME
DECLARE @MHAppealUser VARCHAR(30)
DECLARE @MHAppealUserEmail VARCHAR(200)
DECLARE @UserEmail VARCHAR(200)
DECLARE @FolderName VARCHAR(400)
DECLARE @EmailBody VARCHAR(1000)

SELECT @FolderName = FolderName 
FROM Folder 
WHERE FolderRSN = @FolderRSN

SET @FolderName = ISNULL(@FolderName, ' ')

SELECT @UserEmail = EmailAddress
FROM ValidUser 
WHERE UserId = @UserId

SELECT TOP 1 @MHAppealUser = dbo.f_info_alpha(FolderRSN, 30140 /*MH Appeal User*/),
@MHAppealUserEmail = dbo.f_info_alpha(FolderRSN, 30142 /*MH Appeal User Email*/)
FROM Folder
WHERE FolderType = 'AA'
ORDER BY FolderRSN DESC

SELECT @AttemptResult = ResultCode, @AttemptDate = AttemptDate
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
      (SELECT MAX(FolderProcessAttempt.AttemptRSN) 
         FROM FolderProcessAttempt
        WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


SELECT @intDeficiencies = SUM(1)
  FROM FolderProcess
 INNER JOIN FolderProcessDeficiency ON FolderProcess.ProcessRSN = FolderProcessDeficiency.ProcessRSN
 WHERE FolderProcess.FolderRSN = @FolderRSN
   AND FolderProcess.ProcessCode = 20040 /*Additional FU*/
   AND FolderProcessDeficiency.StatusCode = 1 /*Non-Complied*/

SET @intDeficiencies = ISNULL(@intDeficiencies, 0)

IF @AttemptResult = 20074 /*Compliance PW Issued*/
BEGIN
    IF @intDeficiencies = 0
    BEGIN
        EXEC usp_UpdateFolderCondition @FolderRSN, 'Admin Additional F/U Process Complete, Found in Compliance'
        UPDATE Folder
           SET StatusCode = 2
         WHERE FolderRSN = @FolderRSN
     END
     ELSE
     BEGIN
         RAISERROR('Error!   Deficiencies Exist', 16, -1)
     END
END

IF @AttemptResult = 20079 /*COC Pending Overdue Fees*/
BEGIN
    
    IF @intDeficiencies > 0
    BEGIN
        RAISERROR('Error!   Deficiencies Exist, COC Not Ready to be Issued', 16, -1)
    END
    ELSE
    BEGIN
        UPDATE Folder
           SET StatusCode = 20030 --COC Pending Fees
         WHERE FolderRSN = @FolderRSN 

        EXEC usp_UpdateFolderCondition @FolderRSN, 'COC Pending Overdue Fees'

        /*Reopen process*/
        UPDATE FolderProcess
           SET StatusCode = 1, SignOffUser = Null, EndDate = Null
         WHERE ProcessRSN = @ProcessRSN
    END
END

IF @AttemptResult = 20080 /*COC Pending EMP*/
BEGIN
    IF @intDeficiencies > 0
    BEGIN
        RAISERROR('Error!   Deficiencies Exist, COC Not Ready to be Issued', 16, -1)
    END
    ELSE
    BEGIN
        UPDATE Folder
           SET StatusCode = 20035 --COC Pending EMP
         WHERE FolderRSN = @FolderRSN 

        EXEC usp_UpdateFolderCondition @FolderRSN, 'COC Pending EMP'

        /*Reopen process*/
        UPDATE FolderProcess
           SET StatusCode = 1, SignOffUser = Null, EndDate = Null
         WHERE ProcessRSN = @ProcessRSN
    END
END

IF @AttemptResult = 20077 /*First Order Issued*/
BEGIN
    IF @intDeficiencies = 0
    BEGIN
        RAISERROR('Error!   No Deficiencies Exist for Order', 16, -1)
    END
    ELSE
    BEGIN
        EXEC usp_UpdateFolderCondition @FolderRSN, 'Additional F/U Order Issued'

        UPDATE Folder 
           SET SubCode = 21013 /*Additional FU Order Issued*/
         WHERE FolderRSN = @FolderRSN
    END
END

IF @AttemptResult = 20071 /*Extension Requested*/
BEGIN
    IF @intDeficiencies = 0
    BEGIN
        RAISERROR('Error!   No Deficiencies Exist for Extension Request', 16, -1)
    END
    ELSE
    BEGIN
        EXEC usp_UpdateFolderCondition @FolderRSN, 'Extension Requested'

        UPDATE Folder 
           SET SubCode = 20092 /*Extension Requested*/
         WHERE FolderRSN = @FolderRSN

        UPDATE FolderProcess 
           SET StatusCode = 20001 /*Admin Review*/
         WHERE ProcessRSN = @ProcessRSN /*Closed*/

        COMMIT TRANSACTION

        BEGIN TRANSACTION
        SET @FolderName = 'Extension Requested ' + @FolderName
        SET @EmailBody = 'Extension Requested on ' + dbo.FormatDateTime(GetDate(), 'LONGDATEANDTIME') + ', FolderRSN ' + CAST(@FolderRSN AS VARCHAR(30))

        EXEC webservices_SendEmail @FolderName, @EmailBody, 'AMANDA@ci.burlington.vt.us', 'Amanda', @MHAppealUserEmail, ''

        /* Administrative Review */ 
        SELECT @NextProcessRSN = @NextProcessRSN + 1 
        INSERT INTO FolderProcess 
               ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
                ScheduleDate, ScheduleEndDate ) 
        VALUES ( @NextProcessRSN, @FolderRSN, 20038, 90, 'Y', 1, getdate(), @UserId, @MHAppealUser, 
                @AttemptDate, @AttemptDate) 
    END
END

IF @AttemptResult = 20078 /*Appeal Requested*/
BEGIN
    IF @intDeficiencies = 0
    BEGIN
        RAISERROR('Error!   No Deficiencies Exist for Appeal Request', 16, -1)
    END
    ELSE
    BEGIN
        EXEC usp_UpdateFolderCondition @FolderRSN, 'Appeal Requested'

        UPDATE Folder 
           SET SubCode = 20094 /*Appeal Requested*/
         WHERE FolderRSN = @FolderRSN

        UPDATE FolderProcess 
           SET StatusCode = 20001 /*Admin Review*/
         WHERE ProcessRSN = @ProcessRSN /*Closed*/

        COMMIT TRANSACTION

        BEGIN TRANSACTION
        SET @FolderName = 'Appeal Requested ' + @FolderName
        SET @EmailBody = 'Appeal Requested on ' + dbo.FormatDateTime(GetDate(), 'LONGDATEANDTIME') + ', FolderRSN ' + CAST(@FolderRSN AS VARCHAR(30))

        EXEC webservices_SendEmail @FolderName, @EmailBody, 'AMANDA@ci.burlington.vt.us', 'Amanda', @MHAppealUserEmail, ''

        /* Administrative Review */ 
        SELECT @NextProcessRSN = @NextProcessRSN + 1 
        INSERT INTO FolderProcess 
               ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
                ScheduleDate, ScheduleEndDate ) 
        VALUES ( @NextProcessRSN, @FolderRSN, 20048, 90, 'Y', 1, getdate(), @UserId, @MHAppealUser, 
                @AttemptDate, @AttemptDate) 
    END
END

GO
