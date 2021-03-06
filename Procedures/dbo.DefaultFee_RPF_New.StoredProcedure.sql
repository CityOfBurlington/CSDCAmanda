USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RPF_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RPF_New]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
UPDATE Folder SET StatusCode=30022 WHERE FolderRSN=@FolderRSN

DECLARE @ClauseText VARCHAR(800)
SELECT @ClauseText=ClauseText
FROM ValidClause 
WHERE ClauseRSN=470

UPDATE Folder
SET FolderDescription=@ClauseText
WHERE FolderRSN=@FolderRSN

/*
IF PAID IN FULL THEN 
UPDATE Folder 
SET StatusCode=2
WHERE FolderRSN=@FolderRSN
*/
GO
