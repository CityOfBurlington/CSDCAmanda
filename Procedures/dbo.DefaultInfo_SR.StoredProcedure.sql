USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_SR]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_SR]
@FolderRSN numeric(10), @UserId char(128), @InfoCode int
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Testing use of Info Validation to add a process */


DECLARE @BoolInfoValue char(3)

SELECT @BoolInfoValue = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = @InfoCode

DECLARE @NextProcessRSN INT

IF @BoolInfoValue = 'Yes'
	BEGIN
	SELECT @NextProcessRSN = MAX(ProcessRSN) + 1 FROM FolderProcess
	BEGIN TRAN
		INSERT INTO FolderProcess
		(ProcessRSN, FolderRSN, ProcessCode, StartDate, StatusCode, AssignedUser, StampDate, StampUser)
		VALUES (@NextProcessRSN, @FolderRSN, 65, getdate(), 1, @UserID, getdate(), getdate())
	COMMIT TRAN
END


GO
