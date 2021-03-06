USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_SB]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_SB]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @NoofMonths int
DECLARE @CountAttemptResult int

SELECT @CountAttemptResult = Count(ResultCode)
FROM FolderProcess, FolderProcessAttempt
WHERE FolderProcess.ProcessCode = 30100 /*Application Review*/
and FolderProcessAttempt.FolderRSN = FolderProcess.FolderRSN
and FolderProcessAttempt.ResultCode = 40
AND FOLDERPROCESS.FOLDERRSN = @FOLDERRSN


IF @CountAttemptResult <> 1
BEGIN
     ROLLBACK TRANSACTION
     RAISERROR('YOU DID NOT APPROVED THE APPLICATION REVIEW',16,-1)
     RETURN
END

ELSE
BEGIN
SELECT @NoofMonths = FolderInfo.InfoValueNumeric
FROM FolderInfo
WHERE FolderInfo.InfoCode = 30119
AND FolderInfo.FolderRSN = @FolderRSN


UPDATE 
FOLDER
SET Folder.ExpiryDate = DateAdd(m, @NoofMonths,getdate()), Folder.statuscode = 30002
WHERE
Folder.FolderRSN = @FolderRSN

END



GO
