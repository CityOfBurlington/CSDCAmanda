USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_MH_00020032]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_MH_00020032]
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
MH Admin Routine ProcessCode 20032
DefaultProcess_MH_00020032
*/

DECLARE @AttemptResult int
DECLARE @Inspector varchar(10) 
DECLARE @NextFolderRSN int
DECLARE @SeqNo int
DECLARE @Seq char(6)
DECLARE @SeqLength int
DECLARE @TheYear char(2)
DECLARE @TheCentury char(2)
DECLARE @intDeficiencies INT
DECLARE @WorkCode INT
DECLARE @MHAppealUser VARCHAR(30)
DECLARE @MHAppealUserEmail VARCHAR(200)
DECLARE @UserEmail VARCHAR(200)
DECLARE @FolderName VARCHAR(400)
DECLARE @EmailBody VARCHAR(1000)
DECLARE @ScheduleDate DATETIME


SELECT @FolderName = FolderName FROM Folder WHERE FolderRSN = @FolderRSN
SET @FolderName = ISNULL(@FolderName, ' ')

SELECT @UserEmail = EmailAddress
FROM ValidUser 
WHERE UserId = @UserId

SELECT TOP 1 @MHAppealUser = dbo.f_info_alpha(FolderRSN, 30140 /*MH Appeal User*/),
@MHAppealUserEmail = dbo.f_info_alpha(FolderRSN, 30142 /*MH Appeal User Email*/)
FROM Folder
WHERE FolderType = 'AA'
ORDER BY FolderRSN DESC

SELECT @WorkCode = WorkCode
FROM Folder 
WHERE FolderRSN = @FolderRSN

SELECT @intDeficiencies = SUM(1)
FROM FolderProcessDeficiency
WHERE FolderRSN = @FolderRSN
AND StatusCode = 1 /*Non-Complied*/

SET @intDeficiencies = ISNULL(@intDeficiencies, 0)

SELECT @AttemptResult = ResultCode, @ScheduleDate = AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


IF @AttemptResult = 20074 /*Compliance Docs Issued*/
    BEGIN
    
    IF @intDeficiencies > 0
        BEGIN
            RAISERROR('Error!   Deficiencies Exist, Compliance Docs Cannot be Issued', 16, -1)
        END
    ELSE

    BEGIN
        Update Folder
        Set SubCode = 21000, --Compliance Docs Issued
        StatusCode = 2 --Closed
        Where FolderRSN = @FolderRSN 

        EXEC usp_UpdateFolderCondition @FolderRSN, 'Compliance Docs Issued'

        Update PropertyInfo
        Set PropInfoValue = dbo.formatdatetime (@ScheduleDate, 'shortdate'), 
        PropertyInfoValueDatetime = @ScheduleDate
        Where PropertyRSN = (Select PropertyRSN From Folder Where FolderRSN = @FolderRSN) 
        And PropertyInfoCode = 30 --COC Issue Date

        Update PropertyInfo
        Set PropInfoValue = dbo.formatdatetime (Dateadd ( year, 3, @ScheduleDate), 'shortdate'), 
        PropertyInfoValueDatetime = Dateadd ( year, 3, @ScheduleDate)
        Where PropertyRSN = (Select PropertyRSN From Folder Where FolderRSN = @FolderRSN) 
        And PropertyInfoCode = 35 --COC Expiration Date

        SELECT @NextFolderRSN =  max(FolderRSN + 1) FROM  Folder
        SELECT @TheYear = substring(convert( char(4),DATEPART(year, getdate())),3,2)
        SELECT @TheCentury = substring(convert( char(4),DATEPART(year, getdate())),1,2)

        SELECT @SeqNo = convert(int,max(FolderSequence)) + 1
        FROM Folder
        WHERE FolderYear = @TheYear

        IF @SeqNo IS NULL
        BEGIN
            SELECT @SeqNo = 100000
        END

        SELECT @SeqLength = datalength(convert(char(6),@SeqNo))

        IF @SeqLength < 6
        BEGIN
            SELECT @Seq = substring('000000',1,(6 - @SeqLength)) + convert(char(6), @SeqNo)
        END

        IF @SeqLength = 6
        BEGIN
            SELECT @Seq = convert(char(6),@SeqNo)
        END
/* The logic below inserts a new MH folder with an InDate one year in the future.
   A decision was made in September, 2010 to remove this logic.

        INSERT INTO FOLDER
        (FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision, 
        FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, InDate,
        CopyFlag, FolderName, StampDate, StampUser, IssueUser, ExpiryDate)
        SELECT @NextFolderRSN, @TheCentury, @TheYear, @Seq, '000', '00',
        'MH', 20022, SubCode, 20064, PropertyRSN, DateAdd(Month, 12, @ScheduleDate),
        'DDDDD', FolderName, getdate(), User, IssueUser, DateAdd(Month, 12, @ScheduleDate)
        FROM Folder
      WHERE FolderRSN = @FolderRSN 
*/
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
        Update Folder
        SET StatusCode = 20030 --COC Pending Fees
        Where FolderRSN = @FolderRSN 

        EXEC usp_UpdateFolderCondition @FolderRSN, 'COC Pending Overdue Fees'

        /*Reopen process*/
        UPDATE FolderProcess
        SET StatusCode = 1, 
        SignOffUser = Null, 
        EndDate = Null
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
        Update Folder
        SET StatusCode = 20035 --COC Pending EMP
        Where FolderRSN = @FolderRSN 

        EXEC usp_UpdateFolderCondition @FolderRSN, 'COC Pending EMP'

        /*Reopen process*/
        UPDATE FolderProcess
        SET StatusCode = 1, 
        SignOffUser = Null, 
        EndDate = Null
        WHERE ProcessRSN = @ProcessRSN

    END
END

IF @AttemptResult = 20073 /*Routine Order Issued*/
   BEGIN
   DECLARE @FollowUpProcessStatus INT

   SELECT @FollowUpProcessStatus = StatusCode
   FROM FolderProcess 
   WHERE FolderRSN = @FolderRSN
   AND ProcessCode = 20034 /*First Follow-Up Inspection*/

   IF @FollowUpProcessStatus = 1
        BEGIN
             IF @WorkCode = 20072 /*ROUTINE ORDER TO ADMIN*/
                 BEGIN
                     UPDATE Folder SET SubCode = 20078 WHERE FolderRSN = @FolderRSN
                     /*ORDER ISSUED*/
                 END

             EXEC usp_UpdateFolderCondition @FolderRSN, 'Routine Order Issued'
        END
   ELSE
        BEGIN
             RAISERROR('Error in Admin Routine Process - Not a Valid Work Code', 16, -1)
        END
END


IF @AttemptResult = 20071 /*Extension Requested*/
	BEGIN
    
    IF @intDeficiencies = 0
        BEGIN
            RAISERROR('Error!  No Deficiencies Exist for Extension', 16, -1)
        END
    ELSE
	BEGIN

                EXEC usp_UpdateFolderCondition @FolderRSN, 'Extension Requested'

                UPDATE Folder 
                SET SubCode = 20092 /*Extension Requested*/
                WHERE FolderRSN = @FolderRSN

                UPDATE FolderProcess 
                SET StatusCode = 20003 /*Extension Review*/
                WHERE FolderRSN = @FolderRSN
		AND (StatusCode = 1 
                OR ProcessRSN = @ProcessRSN)

                COMMIT TRANSACTION

                BEGIN TRANSACTION
                SET @FolderName = 'Extension Requested ' + @FolderName
                SET @EmailBody = 'Extension Requested on ' + dbo.FormatDateTime(GetDate(), 'LONGDATEANDTIME') + ', FolderRSN ' + CAST(@FolderRSN AS VARCHAR(30))

                EXEC webservices_SendEmail @FolderName, @EmailBody, 'AMANDA@ci.burlington.vt.us', 'Amanda', @MHAppealUserEmail, ''

 /* Administrative Review */ 
                SELECT @NextProcessRSN = @NextProcessRSN + 1 
                INSERT INTO FolderProcess 
                ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
                PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
                ScheduleDate, ScheduleEndDate ) 
                VALUES ( @NextProcessRSN, @FolderRSN, 20038, 90, 
                'Y', 1, getdate(), @UserId, @MHAppealUser, 
                @ScheduleDate, @ScheduleDate) 

	END
END 


IF @AttemptResult = 20078 /*Appeal Requested*/
	BEGIN
    IF @intDeficiencies = 0
        BEGIN
            RAISERROR('Error!  No Deficiencies Exist for Appeal', 16, -1)
        END
    ELSE
	BEGIN

                EXEC usp_UpdateFolderCondition @FolderRSN, 'Appeal Requested'

                UPDATE Folder 
                SET SubCode = 20094 /*Appeal Requested*/
                WHERE FolderRSN = @FolderRSN

                UPDATE FolderProcess 
                SET StatusCode = 20002 /*Appeal Review*/
                WHERE FolderRSN = @FolderRSN
		AND (StatusCode = 1 
                OR ProcessRSN = @ProcessRSN)

                COMMIT TRANSACTION

                BEGIN TRANSACTION
                SET @FolderName = 'Appeal Requested ' + @FolderName
                SET @EmailBody = 'Appeal Requested on ' + dbo.FormatDateTime(GetDate(), 'LONGDATEANDTIME') + ', FolderRSN ' + CAST(@FolderRSN AS VARCHAR(30))

                EXEC webservices_SendEmail @FolderName, @EmailBody, 'AMANDA@ci.burlington.vt.us', 'Amanda', @MHAppealUserEmail, ''

                /* Administrative Review */ 
                SELECT @NextProcessRSN = @NextProcessRSN + 1 
                INSERT INTO FolderProcess 
                ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
                PrintFlag, StatusCode, StampDate, StampUser, AssignedUser, 
                ScheduleDate, ScheduleEndDate ) 
                VALUES ( @NextProcessRSN, @FolderRSN, 20048, 90, 
       'Y', 1, getdate(), @UserId, @MHAppealUser, 
                @ScheduleDate, @ScheduleDate) 


	END
END

GO
