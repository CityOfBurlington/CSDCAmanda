USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_AL_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_AL_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Condition VARCHAR(2000)

SELECT @Condition = ValidClause.ClauseText
FROM ValidClause
WHERE ClauseRSN = 339

UPDATE Folder
SET Folder.FolderCondition = @Condition
WHERE Folder.FolderRSN = @FolderRSN
GO
