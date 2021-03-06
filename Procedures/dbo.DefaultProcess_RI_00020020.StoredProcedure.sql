USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_RI_00020020]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_RI_00020020]
@ProcessRSN int, @FolderRSN int, @UserId char(8)
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
DECLARE @reinspect datetime
DECLARE @NonComplyCount int
DECLARE @InspectionCycle int
DECLARE @LastInspect DateTime
DECLARE @NoofUnits int
DECLARE @Extensiondays int
DECLARE @ExtendedDate Datetime 
DECLARE @PropertyRSN int
DECLARE @COCYears Int 

SELECT @AttemptResult = ResultCode, @ExtensionDays = MileageAmount
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

Select @Propertyrsn = PropertyRSN
From Folder
Where FolderRSn = @FolderRSN

SELECT @InspectionCycle = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20029

SELECT @LastInspect = Max(AttemptDate)
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.FolderRSN = @FolderRSN
AND FolderProcessAttempt.ProcessRSN = @ProcessRSN

SELECT @NonComplyCount = Count(LocationDesc)
FROM FolderProcessDeficiency
WHERE FolderPRocessDeficiency.StatusCode = 1
and FolderProcessDeficiency.FolderRSN = @FolderRSN
Group By LocationDesc

SELECT @NoofUnits = @@RowCount

IF @attemptresult in (20046, 20059) --Found in Compliance or Self Certification

   IF @InspectionCycle is Null
   BEGIN
   UPDATE FolderProcess
   SET StatusCode = 1, SignOffUser = Null, EndDate=Null
   WHERE ProcessRSN = @ProcessRSN

   DELETE FROM FolderProcessAttempt
   WHERE ProcessRSN = @ProcessRSN
   AND AttemptRSN = (SELECT max(AttemptRSN)
                     FROM FolderProcessAttempt
                     WHERE ProcessRSN = @ProcessRSN)
   COMMIT Transaction
   BEGIN Transaction
   RAISERROR( 'PLEASE BE SURE TO ENTER A REINSPECTION YEAR CYCLE  IN THE INFO VALUE FIELD', 16, -1)
   END

   ELSE

   IF @NonComplyCount is not null
   
   BEGIN
   UPDATE FolderProcess
   SET StatusCode = 1, SignOffUser = Null, EndDate=Null
   WHERE ProcessRSN = @ProcessRSN

   DELETE FROM FolderProcessAttempt
   WHERE ProcessRSN = @ProcessRSN
   AND AttemptRSN = (SELECT max(AttemptRSN)
                     FROM FolderProcessAttempt
   WHERE ProcessRSN = @ProcessRSN)
   COMMIT Transaction
   BEGIN Transaction
   RAISERROR( 'ALL DEFICIENCIES ARE NOT MARKED AS COMPLIED', 16, -1)
   END

ELSE
   BEGIN
   UPDATE Folder
   SET Folder.StatusCode = 2 /*Closed*/, Folder.FinalDate = @lastinspect
   WHERE Folder.FolderRSN = @FolderRSN

   UPDATE FolderInfo
   SET FolderInfo.InfoValue = Convert(Char(11),@lastinspect), 
       FolderInfo.InfoValueUpper = Upper(Convert(Char(11),@lastinspect)),
       FolderInfo.InfoValueDatetime = @lastinspect 
   WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 20030

   UPDATE FolderInfo
   SET FolderInfo.InfoValue = @NoofUnits, FolderInfo.InfoValueNumeric= @NoofUnits, 
       FolderInfo.InfoValueUpper = Upper(@NoofUnits) 
   WHERE FolderInfo.FolderRSN = @FolderRSN
   AND FolderInfo.InfoCode = 20032

   INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
   FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
   VALUES(getdate(), 'REVIEW COMPLIANCE', 'KBUTLER',
   @FolderRSN, 'Y', getdate(), getdate(), @userID)

   Update PropertyInfo
   Set PropInfoValue = Convert(Char(11),@lastinspect), 
       InfoValueUpper = Upper(Convert(Char(11),@lastinspect)),
       PropertyInfoValueDatetime = @lastinspect 
   Where PropertyRSn = @PropertyRSN
   And PropertyInfoCode = 30

   Select @COCYears = InfoValueNumeric
   From FolderInfo
   Where FolderRSN = @FolderRSN
   And InfoCode = 20029 

   Update PropertyInfo
   Set PropInfoValue = Convert(Char(11), dateadd(yy, @COCYears, @lastinspect)), 
       InfoValueUpper = Upper(Convert(Char(11),dateadd(yy, @COCYears, @lastinspect))),
       PropertyInfoValueDatetime = dateadd(yy, @COCYears, @lastinspect)
   Where PropertyRSn = @PropertyRSN
   And PropertyInfoCode = 35


   Update PropertyInfo
   Set PropInfoValue = @COCYears, 
       InfoValueUpper = Upper(@COCYears),
       PropertyInfoValueNumeric = @COCYears
   Where PropertyRSn = @PropertyRSN
   And PropertyInfoCode = 40

   END





IF @AttemptResult = 20047 /*Deficiencies Found*/
BEGIN
/*Populate Comply by Dates */

  RAISERROR('USE MH FOLDER FOR THIS ATTEMPT RESULT', 16, -1)

  BEGIN
  DECLARE @new_count1 int
  DECLARE @severity_code int

  DECLARE Upd_comply_by_date CURSOR FOR
  SELECT ISNULL(FolderProcessDeficiency.SeverityCode,-1)
  FROM FolderProcessDeficiency
  WHERE FolderProcessDeficiency.ProcessRSN = @ProcessRSN 
  AND FolderProcessDeficiency.StatusCode = 1

  OPEN Upd_comply_by_date

  FETCH NEXT FROM Upd_comply_by_date INTO @severity_code
  WHILE @@FETCH_STATUS = 0 
  BEGIN
    SELECT @new_count1 = DefaultDaysToComply 
    FROM ValidProcessSeverity 
    WHERE SeverityCode = @severity_code

    UPDATE FolderProcessDeficiency
    SET ComplyByDate = dateadd(day,@new_count1,getdate())
    WHERE ProcessRSN = @ProcessRSN
    AND SeverityCode = @severity_code
    AND Statuscode = 1

    FETCH NEXT FROM Upd_comply_by_date INTO @severity_code
  END

 CLOSE Upd_comply_by_date
  DEALLOCATE Upd_comply_by_date
END

COMMIT Transaction
BEGIN Transaction

BEGIN
SELECT @reinspect = Max(Complybydate)
FROM FolderProcessdeficiency
WHERE FolderProcessdeficiency.ProcessRSN = @ProcessRSN
AND FolderProcessDeficiency.FolderRSN = @FolderRSN


UPDATE Folder
  SET Folder.StatusCode = 20014 /*Violation*/, Folder.ExpiryDate = @reinspect
 WHERE Folder.FolderRSN = @FolderRSN

INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
VALUES(getdate(), 'DEFICIENCIES CONFIRMED ON PROPERTY', 'KBUTLER',
@FolderRSN, 'Y', getdate()+20, getdate(), @userID)


UPDATE FolderInfo
SET FolderInfo.InfoValue = Convert(Char(11),@lastinspect)
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20030

UPDATE FolderInfo
SET FolderInfo.InfoValue = Convert(Char(11),@reinspect)
WHERE FolderInfo.FolderRSN =@FolderRSN
AND FolderInfo.InfoCode = 20001

UPDATE FolderInfo
SET FolderInfo.InfoValue = @NoofUnits, FolderInfo.InfoValueNumeric= @NoofUnits
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20032


UPDATE FolderProcess
SET ScheduleDate = @reinspect, StatusCode = 1, EndDate = Null,ProcessComment = 'Schedule Re-Inspection'
WHERE FolderProcess.ProcessCode = 20019
AND FolderProcess.FolderRSN = @FolderRSN

UPDATE FolderProcess
SET ScheduleDate = Null, StatusCode = 1, EndDate = Null
WHERE FolderProcess.ProcessRSN = @ProcessRSN

 END 
END

IF @AttemptResult = 20008 /*Refer to Zoning*/
BEGIN
RAISERROR('USE MH FOLDER FOR THIS ATTEMPT RESULT', 16, -1)

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'REVIEW PROGRESS OF ZONING EVALUATION', 'KBUTLER',
  @FolderRSN, 'Y', getdate()+10, getdate(), @userID)

  UPDATE FolderProcess
  SET ScheduleDate = NULL, StatusCode = 1, EndDate = NULL
  WHERE FolderProcess.ProcessRSN = @ProcessRSN


/*Insert Child Folder*/

DECLARE @NextFolderRSN int
DECLARE @SeqNo int
DECLARE @Seq char(6)
DECLARE @SeqLength int
DECLARE @TheYear char(2)
DECLARE @TheCentury char(2)

SELECT @NextFolderRSN =  max(FolderRSN + 1)
FROM  Folder

SELECT @TheYear = substring(convert(char(4),DATEPART(year, getdate())),3,2)

SELECT @TheCentury = substring(convert( char(4),DATEPART(year, getdate())),1,2)

SELECT @SeqNo = convert(int,max(FolderSequence)) + 1
FROM Folder
WHERE FolderYear = @TheYear

IF @SeqNo IS NULL
 BEGIN
   SELECT @SeqNo = 100000
 END

SELECT @SeqLength = datalength(convert(varchar(6),@SeqNo))

IF @SeqLength < 6
 BEGIN
  SELECT @Seq = substring('000000',1,(6 - @SeqLength)) + convert(varchar(6), @SeqNo)
 END

IF @SeqLength = 6
 BEGIN
  SELECT @Seq = convert(varchar(6),@SeqNo)
 END

INSERT INTO FOLDER
              (FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
               FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
               ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
SELECT @NextFolderRSN, @TheCentury, @TheYear, @Seq, '000', '00',
                'Q2', '150', SubCode, WorkCode, PropertyRSN, getdate(),
                @FolderRSN, 'DDDDD', FolderName, getdate(), User
FROM Folder
WHERE FolderRSN = @FolderRSN 

UPDATE FolderProcess
SET AssignedUser = 'JFrancis', ScheduleDate = getdate()
WHERE FolderProcess.FolderRSN = @NextFolderRSN
and FolderProcess.ProcessCode = 5003

UPDATE FolderInfo
SET InfoValue = 'Departmental Referral'
WHERE FolderInfo.FolderRSN = @NextFolderRSN
AND FolderInfo.InfoCode = 20008


END


IF @AttemptResult = 20011 /*Legal Action Required*/
BEGIN
RAISERROR('USE MH FOLDER FOR THIS ATTEMPT RESULT', 16, -1)

   INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
   FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
   VALUES(getdate(), 'REVIEW PROGRESS OF LEGAL ACTION', 'KBUTLER',
   @FolderRSN, 'Y', getdate()+30, getdate(), @userID)

   UPDATE Folder
   SET StatusCode = 110 /*Legal Action*/
   WHERE Folder.FolderRSN = @FolderRSN

END


IF @AttemptResult = 20058 --Extension Granted
BEGIN
RAISERROR('USE MH FOLDER FOR THIS ATTEMPT RESULT', 16, -1)

   If @ExtensionDays is null 
      RAISERROR( 'PLEASE ENTER THE NUMBER OF DAYS IN MILEAGE COLUMN', 16, -1)

   Set @ExtendedDate = dateadd(dd, @Extensiondays, getdate()) 

   Update FolderProcessDeficiency
   Set ComplyByDate = @ExtendedDate 
   Where ProcessRSN = @ProcessRSN 
   And StatusCode = 1 

   UPDATE FolderProcess
   SET StatusCode = 1, SignOffUser = Null, EndDate=Null
   WHERE ProcessRSN = @ProcessRSN
END

IF @attemptresult = 20005 /*Ticket Issued*/

BEGIN
RAISERROR('USE MH FOLDER FOR THIS ATTEMPT RESULT', 16, -1)

UPDATE FolderProcess
   SET StatusCode = 1, SignOffUser = Null, EndDate=Null
   WHERE ProcessRSN = @ProcessRSN
END

If @AttemptResult = 20061 /*Hold Folder Open*/
BEGIN
RAISERROR('USE MH FOLDER FOR THIS ATTEMPT RESULT', 16, -1)


UPDATE Folder
SET Folder.StatusCode = 1 /*Open*/
WHERE Folder.FolderRSN = @FolderRSN

UPDATE FolderProcess
   SET StatusCode = 1, SignOffUser = Null, EndDate=Null
   WHERE ProcessRSN = @ProcessRSN
END

GO
