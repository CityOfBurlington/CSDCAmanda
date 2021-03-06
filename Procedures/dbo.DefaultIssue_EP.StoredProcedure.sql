USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_EP]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_EP]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Rough VarChar(3)
DECLARE @Underground VarChar(3)


SELECT @Rough = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30053

SELECT @Underground = InfoValue
From FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30072

IF @Rough = 'No'
BEGIN
DELETE
FROM FolderProcess
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode =30006
END

IF @Underground = 'No'
BEGIN
DELETE
FROM FolderProcess
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode = 30020
END

 


GO
