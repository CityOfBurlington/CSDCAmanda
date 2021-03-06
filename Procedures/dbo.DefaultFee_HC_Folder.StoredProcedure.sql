USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_HC_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_HC_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DELETE FROM FolderPeople 
WHERE FolderRSN = @FolderRSN

DECLARE @strClause VARCHAR(4000)

SELECT @strClause = ClauseText
FROM ValidClause
WHERE ClauseGroup = 'HC'

UPDATE Folder 
SET FolderDescription = @strClause
WHERE FolderRSN = @FolderRSN
GO
