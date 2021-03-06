USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_BP]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_BP]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Rough VarChar(3)
DECLARE @Foundation VarChar(3)

SELECT @Rough = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30053

SELECT @Foundation = InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30071


DECLARE @i_SubCode int 
DECLARE @i_WorkCode int 
SELECT @i_SubCode = Folder.SubCode, 
       @i_WorkCode = Folder.WorkCode 
  FROM Folder 
 WHERE ( Folder.FolderRSN = @FolderRSN ) 


IF @Rough = 'No' OR @i_WorkCode = 30019
BEGIN
DELETE
FROM FolderProcess
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode =30002
END
 

IF @Foundation = 'No' OR @i_WorkCode = 30019
BEGIN
DELETE
FROM FolderProcess
WHERE FolderProcess.FolderRSN = @FolderRSN
AND FolderProcess.ProcessCode = 30001
END

GO
