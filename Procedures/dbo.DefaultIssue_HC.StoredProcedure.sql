USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_HC]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_HC]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
UPDATE Folder
SET StatusCode = 2
WHERE FolderRSN = @FolderRSN
GO
