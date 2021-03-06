USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QF_00020001]    Script Date: 9/9/2013 9:56:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QF_00020001]
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
DECLARE @Inspectiondate datetime
DECLARE @Complybydate datetime
DECLARE @DEsc varchar(2000)

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @InspectionDate = AttemptDate
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @ComplyByDate = InfoValue
FROM FolderInfo
WHERE FolderInfo.InfoCode = 20001 
AND FolderInfo.FolderRSN = @FolderRSN


IF @AttemptResult = 20047 /*Deficiencies Found*/
  BEGIN

  IF @ComplyByDate is null

   BEGIN
   UPDATE FolderProcess
   SET StatusCode = 1, Signoffuser = Null, EndDate= Null
   WHERE ProcessRSN = @ProcessRSN

   DELETE FROM FolderProcessAttempt
   WHERE ProcessRSN = @ProcessRSN
   AND AttemptRSN = (Select max(AttemptRSN)
                    FROM FolderProcessAttempt
                    WHERE ProcessRSN = @ProcessRSN)

   COMMIT Transaction
   BEGIN Transaction
   RAISERROR ('YOU MUST SUPPLY A COMPLY BY DATE IN THE INFO FIELD', 16, -1)

   END

ELSE
  BEGIN

  UPDATE Folder
  SET Folder.StatusCode = 20014 /*Violation*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET FolderProcess.ScheduleDate = @complybydate, EndDate = NULL, StatusCode = 1, assigneduser = 'GAllen',
  ProcessComment = 'Schedule a Reinspection'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN

  DECLARE @ViolationType varchar(2)
  SELECT @ViolationType = FolderType
  FROM Folder
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderInfo
  SET FolderInfo.InfoValue = Convert(Char(11),@InspectionDate)
  WHERE FolderInfo.InfoCode = 20030
  AND FolderInfo.FolderRSN = @FolderRSN

  END
END

IF @AttemptResult = 20008 /*Refer to Zoning*/
BEGIN

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'REVIEW PROGRESS OF ZONING EVALUATION', 'KBUTLER',
  @FolderRSN, 'Y', getdate()+10, getdate(), @userID)

  UPDATE FolderProcess
  SET ScheduleDate = NULL, StatusCode = 1, EndDate = NULL
  WHERE FolderProcess.ProcessRSN = @ProcessRSN

  SELECT @Desc = Folder.FolderDescription
  FROM Folder
  WHERE Folder.FolderRSN = @FolderRSN

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
               FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate, FolderDescription,
               ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
SELECT @NextFolderRSN, @TheCentury, @TheYear, @Seq, '000', '00',
                'Q2', '150', SubCode, WorkCode, PropertyRSN, getdate(), @Desc,
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

IF @AttemptResult = 20046 /*Found In Compliance*/
BEGIN
  
     UPDATE Folder
     SET StatusCode = 2, FinalDate = getdate()
     WHERE Folder.FolderRSN = @FolderRSN

     UPDATE FolderInfo
     SET FolderInfo.InfoValue = Convert(Char(11),@InspectionDate)
     WHERE FolderInfo.InfoCode = 20030
     AND FolderInfo.FolderRSN = @FolderRSN

     UPDATE FolderProcess  /*close any open processes*/
     SET FolderProcess.EndDate = getdate(), FolderProcess.StatusCode = 2
     WHERE FolderProcess.FolderRSN = @FolderRSN
     AND FolderProcess.EndDate IS NULL

     INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
     FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
     VALUES(getdate(), 'REVIEW COMPLIANCE', 'KBUTLER',
     @FolderRSN, 'Y', getdate(), getdate(), @userID)
END


IF @AttemptResult = 20011 /*Legal Action Required*/
BEGIN

   INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
   FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
   VALUES(getdate(), 'REVIEW PROGRESS OF LEGAL ACTION', 'KBUTLER',
   @FolderRSN, 'Y', getdate()+30, getdate(), @userID)

   UPDATE Folder
   SET StatusCode = 110 /*Legal Action*/
   WHERE Folder.FolderRSN = @FolderRSN

END


/*Note: All programming above is identical to QB Folder 20000 */


IF @AttemptResult = 20031 /*Refer to Fire Marshall*/
BEGIN

   INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
   FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
   VALUES(getdate(), 'REVIEW PROGRESS OF FIRE MARSHALL EVALUATION', 'KBUTLER',
   @FolderRSN, 'Y', getdate()+20, getdate(), @userID)

   UPDATE Folder
   SET StatusCode = 20018 /*Referred to Fire Marshall*/
   WHERE Folder.FolderRSN = @FolderRSN

END



GO
