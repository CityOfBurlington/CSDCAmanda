USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_SB]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_SB]
@FolderRSN int, @UserId char(10), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
IF @InfoCode IN (30113,30114)
BEGIN
DECLARE @ClauseOne Varchar(2000)
DECLARE @ClauseTwo Varchar(2000)
DECLARE @InfoValue Varchar(5)

SELECT @ClauseOne = ValidClause.ClauseText
FROM ValidClause
WHERE ValidClause.ClauseRSN = 341

SELECT @ClauseTwo = ValidClause.ClauseText
FROM ValidClause
WHERE ValidClause.ClauseRSN = 342

SELECT @InfoValue = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30113

IF @InfoValue = 'Yes'

UPDATE 
Folder
SET Folder.FolderCondition = @ClauseOne
WHERE Folder.FolderRSN = @FolderRSN

ELSE

UPDATE 
Folder
SET Folder.FolderCondition = @ClauseTwo
WHERE Folder.FolderRSN = @FolderRSN

END


IF @InfoCode = 30112
BEGIN
SELECT @InfoValue = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30112

  IF @InfoValue = 'Yes'
    BEGIN
    ROLLBACK TRANSACTION
    RAISERROR('YOU CAN NOT ISSUE A PERMIT WITHIN 12 FEET OF EACH OTHER',16,-1)
    RETURN
    END

END



GO
