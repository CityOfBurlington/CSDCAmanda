USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_VC_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_VC_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DELETE  FolderProcessChecklist
FROM FolderProcessChecklist

WHERE FolderProcessChecklist.ChecklistCode IN (5009,5010,5011,5012)
AND FolderProcessChecklist.FolderRSN = @FolderRSN


GO
