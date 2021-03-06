USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_QH]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_QH]
@FolderRSN int, @UserId char(10), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Complyby datetime

SELECT @ComplyBy = FolderInfo.InfoValue
FROM FolderInFo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20001

BEGIN
UPDATE Folder
SET Folder.ExpiryDate = @ComplyBy
WHERE Folder.FolderRSN = @FolderRSN
END
GO
