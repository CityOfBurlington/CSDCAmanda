USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_Q2_00005004]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_Q2_00005004]
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
DECLARE @CountCheckList float
DECLARE @Inspector char(8)

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

SELECT @CountChecklist = Count(*)
FROM FolderProcessChecklist
WHERE FolderProcessChecklist.FolderRSN = @FolderRSN
AND FolderProcessChecklist.ProcessRSN = @ProcessRSN
AND FolderProcessChecklist.Passed = 'Y'

  
IF @AttemptResult = 5020  /*Refer to Enforcement */
BEGIN 
  IF @CountChecklist = 0
  BEGIN
  ROLLBACK TRANSACTION
  RAISERROR('YOU MUST CHOOSE AT LEAST ONE VIOLATION TYPE FROM THE CHECKLIST', 16, -1)
  RETURN
  END

ELSE

DECLARE @NextFolderRSN int
DECLARE @SeqNo int
DECLARE @Seq char(6)
DECLARE @SeqLength int
DECLARE @TheYear char(2)
DECLARE @FolderType char(2)
DECLARE @SubCode int
DECLARE @WorkCode int
DECLARE @ChecklistCode int

SELECT @Inspector = FolderProcess.AssignedUser
FROM FolderProcess
WHERE FolderProcess.ProcessRSN = @ProcessRSN

UPDATE Folder
SET Folder.StatusCode = 2, Folder.FinalDate = getdate()
WHERE Folder.FolderRSN = @FolderRSN
 
DECLARE Checklist_check CURSOR FOR
SELECT CheckListCode FROM FolderProcessChecklist
WHERE FolderRSN = @FolderRSN
AND ProcessRSN = @ProcessRSN
AND PASSED = 'Y'
 
OPEN Checklist_check
FETCH Checklist_check INTO @ChecklistCode
WHILE @@fetch_status = 0
 
BEGIN
 
SELECT @FolderType = ValidLookup.LookupString FROM ValidLookup
WHERE ValidLookup.LookupCode = 7 and ValidLookup.Lookup1 = @ChecklistCode
 
SELECT @SubCode = ValidLookup.LookUp2 FROM ValidLookup
WHERE ValidLookup.LookupCode = 7 and ValidLookup.Lookup1 = @ChecklistCode
 
SELECT @WorkCode = ValidLookup.LookUpFee FROM ValidLookup
WHERE ValidLookup.LookupCode = 7 and ValidLookup.Lookup1 = @ChecklistCode


SELECT @NextFolderRSN =  max(FolderRSN + 1)
FROM  Folder
 
SELECT @TheYear = substring(convert( char(4),DATEPART(year, getdate())),3,2)
 
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
SELECT @NextFolderRSN, 20, @TheYear, @Seq, '000', '00',
   @FolderType, 150, @SubCode, @WorkCode, PropertyRSN, getdate(),
   @FolderRSN, 'DDDDD', FolderName, getdate(), User
FROM Folder
WHERE FolderRSN = @FolderRSN 
 
FETCH Checklist_check INTO @ChecklistCode
 
END
 
CLOSE Checklist_check
DEALLOCATE Checklist_check

UPDATE FolderProcess
SET FolderProcess.AssignedUser = @Inspector
WHERE FolderProcess.FolderRSN IN (SELECT Folder.FolderRSN FROM Folder
                                 WHERE Folder.ParentRSN = @FolderRSN)
AND FolderProcess.ProcessCode = 5000
END



GO
