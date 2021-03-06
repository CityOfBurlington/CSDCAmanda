USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_EM_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_EM_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @EMLang varchar(2000)

SELECT @EMLang = ValidClause.ClauseText
from ValidClause
WHERE ValidClause.ClauseGroup = 'Electrical Maintenance'

UPDATE Folder
SET Folder.FolderDescription = @EMLang
WHERE folder.FolderRSN = @FolderRSN

GO
