USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_BP_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultFee_BP_Folder]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
DECLARE @intPropertyStatus int

exec RsnSetLock

SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
FROM AccountBillFee

UPDATE Folder 
SET Folder.FolderDescription = ValidClause.ClauseText
FROM Folder 
INNER JOIN ValidClause ON Folder.WorkCode = ValidClause.DisplayOrder 
AND Folder.FolderType = ValidClause.ClauseGroup
WHERE Folder.FolderRSN = @FolderRSN

UPDATE Folder 
SET Folder.FolderName = UPPER(Folder.FolderName)
WHERE Folder.FolderRSN = @FolderRSN 

IF @intPropertyStatus = 2
BEGIN
	RAISERROR ('A permit may not be issued for an Inactive status Property. Please choose an Active or Pending Property.', 16,-1)
	RETURN
END

IF @intPropertyStatus > 3
BEGIN
	RAISERROR ('Invalid Property status. Please choose an Active or Pending status Property.', 16,-1)
	RETURN
END

GO
