USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_Q2_00005002]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_Q2_00005002]
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
DECLARE @CheckInfo float

SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)


SELECT @CheckInfo = count(*)
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20011
AND FolderInfo.InfoValue IS NULL
  
IF @AttemptResult = 5017
BEGIN

  IF @CheckInfo <> 0 
  BEGIN
  ROLLBACK TRANSACTION
  RAISERROR('YOU MUST ASSIGN AN INSPECTOR IN THE INFOFIELD', 16, -1)
  END

ELSE 

/* Zoning Compliant Investigation, Enforcement Action */ 
DECLARE @InspectorID char(8)
DECLARE @Inspector char(27)

SELECT @Inspector = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20011

SELECT @InspectorID = ValidUser.UserID
FROM ValidUser
WHERE ValidUser.UserName = @Inspector

SELECT @NextProcessRSN = @NextProcessRSN + 1 

INSERT INTO FolderProcess 
       ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, 
         PrintFlag, StampDate, StampUser,ScheduleDate, AssignedUser,statuscode ) 
VALUES ( @NextProcessRSN, @FolderRSN, 5003, 90, 
         'Y', getdate(), @UserId, getdate()+1, @inspectorID,1 ) 

UPDATE Folder
SET Folder.StatusCode = 150 /*Investigation*/
WHERE Folder.FolderRSN = @FolderRSN


END

ELSE

IF @AttemptResult = 5016 /*Cancelled*/

UPDATE Folder
SET Folder.StatusCode = 2, Folder.FinalDate = getdate(),
Folder.FolderCondition = 'COMPLAINT CANCELLED' + ' ' + Convert(Char(11),getdate()) + ' ' + @UserId
WHERE Folder.FolderRSN = @FolderRSN

GO
