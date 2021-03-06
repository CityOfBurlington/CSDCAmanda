USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_VZ_00005001]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_VZ_00005001]
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
DECLARE @ComplyBy datetime


SELECT @AttemptResult = ResultCode
FROM FolderProcessAttempt
WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
AND FolderProcessAttempt.AttemptRSN = 
                    (SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcessAttempt
                     WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN)

IF @attemptresult = 5013 /*Stipulation Agreement */
SELECT @ComplyBy = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 3005

BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5015 /*Stipulation Agreement*/, Folder.expirydate = @ComplyBy
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = @complyby+1,EndDate = NULL, StatusCode = 1, assigneduser = 'jfrancis'
  WHERE FolderProcess.ProcessCode = 5000
  AND FolderProcess.FolderRSN = @FolderRSN
END


IF @attemptresult = 5011 /*Legal Action */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 5011
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET  EndDate = NULL, StatusCode = 1
  WHERE FolderProcess.ProcessRSN = @ProcessRSN
END

 
IF @attemptresult = 5015 /*Legal Action Resolved */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 150 
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+1,EndDate = NULL, StatusCode = 1, assigneduser = 'jfrancis'
  WHERE FolderProcess.ProcessCode = 5000
  AND FolderProcess.FolderRSN = @FolderRSN

END

IF @attemptresult = 5014 /*Response Received */
BEGIN
  UPDATE Folder
  SET Folder.StatusCode = 150 /*Investigation */
  WHERE Folder.FolderRSN = @FolderRSN

  UPDATE FolderProcess
  SET ScheduleDate = getdate()+1,EndDate = NULL, StatusCode = 1, assigneduser = 'jfrancis'
  WHERE FolderProcess.ProcessCode = 5000
  AND FolderProcess.FolderRSN = @FolderRSN

END


GO
