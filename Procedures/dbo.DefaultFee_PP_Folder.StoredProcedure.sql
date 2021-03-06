USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_PP_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_PP_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @strFolderClauseText Varchar(2000)
DECLARE @intWorkCode int

SELECT @intWorkCode = Folder.WorkCode
FROM Folder 
WHERE Folder.FolderRSN = @FolderRSN

SELECT @strFolderClauseText = ValidClause.ClauseText
FROM ValidClause
WHERE ValidClause.ClauseGroup = 'PP'
AND ValidClause.DisplayOrder = @intWorkCode

UPDATE Folder
SET Folder.FolderDescription = @strFolderClauseText
WHERE Folder.FolderRSN = @FolderRSN
GO
