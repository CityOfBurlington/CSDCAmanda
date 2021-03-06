USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VF_00005005]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VF_00005005]
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
DECLARE @attemptresult int
DECLARE @AttemptCk int
DECLARE @AppealDate datetime

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


IF @attemptresult = 5010 /*Notice of Violation */
BEGIN
SELECT @attemptCk = Count(*)
     FROM FolderProcessattempt
     WHERE FolderProcessattempt.ProcessRSN = @ProcessRSN
     AND FolderProcessattempt.Resultcode = 5021

     IF @attemptCk <1
     BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('YOU MUST ISSUE A WARNING LETTER TO ISSUING A NOTICE OF VIOLATION',16,-1)
     RETURN
     
     END
ELSE

Declare @AttemptDate Datetime 
Declare @NextFolderRSN int 
Declare @TheYear char(2) 
Declare @TheCentury int 
Declare @SeqNo int
Declare @Seq char(6)
Declare @SeqLength int 


BEGIN

  UPDATE Folder
  SET Folder.StatusCode = 5004 /*Notice of Violation*/
  WHERE Folder.FolderRSN = @FolderRSN

  SELECT @NextFolderRSN =  max(FolderRSN + 1)
  FROM  Folder

   SELECT @TheYear = substring(convert( char(4),DATEPART(year, getdate())),3,2)
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

  /* Insert Violation Folder*/ 
  INSERT INTO FOLDER
  (FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
   FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
   ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
   SELECT @NextFolderRSN, @TheCentury, @TheYear, @Seq, '000', '00',
   'VL', 150,'5002' ,'5025' , PropertyRSN, getdate(),
   @FolderRSN, 'DDDDD', FolderName, getdate(), User
   FROM Folder
   WHERE FolderRSN = @FolderRSN

  END
END





IF @attemptresult = 5021
  BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5017 /*Warning Letter*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+10, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
  END


IF @attemptresult = 5022 /*Refer to CCEO */
BEGIN

  UPDATE Folder
  SET Folder.StatusCode = 5018 /*Referred to CCEO*/
  WHERE Folder.FolderRSN = @FolderRSN
 
END



IF @attemptresult = 5005 /*Appealed */
BEGIN

SELECT @appealdate = EndDate
     FROM FolderProcess
     WHERE FolderProcess.FolderRSN = @FolderRSN
     AND FolderProcess.ProcessCode = 5006


  UPDATE Folder
  SET Folder.StatusCode = 5007 /*Appeal*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = @appealdate+30, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
  END


IF @attemptresult =5024 /*Closed*/
BEGIN

  UPDATE Folder
  SET Folder.StatusCode = 2 /*Closed*/
  WHERE Folder.FolderRSN = @FolderRSN
END



IF @attemptresult = 5023 /*Status Removed*/

BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 2, Folder.FolderDescription ='FUNCTIONAL FAMILY STATUS REMOVED' /*Closed*/
  WHERE Folder.FolderRSN = @FolderRSN

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'FUNCTIONAL FAMILY STATUS REMOVED', 'KBUTLER',
  @FolderRSN, 'Y',getdate(), getdate(), @userID)

 INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate()+.01,'FUNCTIONAL FAMILY STATUS REMOVED', 'LChicoin',
  @FolderRSN, 'Y',getdate()+.01, getdate()+.01, @userID)

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate()+ .02, 'FUNCTIONAL FAMILY STATUS REMOVED', 'NHolt',
  @FolderRSN, 'Y',getdate()+.02, getdate()+.02, @userID)

END


GO
