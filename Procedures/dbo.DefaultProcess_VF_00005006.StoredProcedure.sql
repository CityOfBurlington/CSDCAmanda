USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VF_00005006]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VF_00005006]
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
DECLARE @NextFolderRSN int 
DECLARE @TheYear char(2) 
DECLARE @TheCentury int 
DECLARE @SeqNo int
DECLARE @Seq char(6)
DECLARE @SeqLength int 


SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


IF @attemptresult = 5026 /*Denied*/
  BEGIN
 UPDATE Folder
  SET Folder.StatusCode = 5007, expirydate = getdate() + 15 /*Appeal*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+16, ScheduleEndDate = getdate() +21, EndDate = NULL, StatusCode = 1,assigneduser = 'ROconnor'
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
  END


IF @attemptresult = 5028 /*Appeal Received */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5021 /*Pending DRB Decision*/
  WHERE Folder.FolderRSN = @FolderRSN
END


IF @attemptresult = 5025 /*Approve*/
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5020,
  Folder.FolderDescription ='FUNCTIONAL FAMILY STATUS APPROVED - REVIEW DUE ' + Convert(char(11),getdate()+730),
  expirydate = getdate()+730 /*Review Period*/
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+730, EndDate = NULL, StatusCode = 1,assigneduser = 'JFrancis'
  WHERE FolderProcess.FolderRSN = @FolderRSN
  AND FolderProcess.ProcessCode = 5005

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate(), 'FUNCTIONAL FAMILY STATUS APPROVED', 'KBUTLER',
  @FolderRSN, 'Y',getdate(), getdate(), @userID)

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate()+.01,'FUNCTIONAL FAMILY STATUS APPROVED', 'LChicoin',
  @FolderRSN, 'Y',getdate()+.01, getdate()+.01, @userID)

  INSERT INTO FolderComment (CommentDate, Comments, CommentUser, 
  FolderRSN, IncludeOnToDo, ReminderDate, StampDate, StampUser)
  VALUES(getdate()+ .02, 'FUNCTIONAL FAMILY STATUS APPROVED', 'NHolt',
  @FolderRSN, 'Y',getdate()+.02, getdate()+.02, @userID)
END


IF @attemptresult = 5027 /*No Appeal*/
BEGIN
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

  UPDATE Folder
  SET Folder.StatusCode = 2 /*Closed*/
  WHERE Folder.FolderRSN = @FolderRSN

  /* Insert Violation Folder*/ 
  INSERT INTO FOLDER
  (FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
   FolderType, StatusCode, SubCode, WorkCode, FolderDescription,PropertyRSN, Indate,
   ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
   SELECT @NextFolderRSN, @TheCentury, @TheYear, @Seq, '000', '00',
   'VL', 150,'5002' ,'5025' ,'From AT 5025', PropertyRSN, getdate(),
   @FolderRSN, 'DDDDD', FolderName, getdate(), User
   FROM Folder
   WHERE FolderRSN = @FolderRSN

 END



GO
