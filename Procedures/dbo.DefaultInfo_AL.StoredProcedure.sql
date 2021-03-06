USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_AL]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_AL]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @ErrorMsg VARCHAR(100)
DECLARE @ATFO VARCHAR(3)
DECLARE @ATFC VARCHAR(3)

SELECT @ATFO = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30078

SELECT @ATFC = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30095

IF @ATFO = 'Yes' AND @ATFC = 'Yes'
BEGIN
    ROLLBACK TRANSACTION
    SET @ErrorMsg = 'Sorry. Both ATFO and ATFC are set to Yes. You will have to choose one or the other.'
    RAISERROR (@ErrorMsg, 16, -1)
    RETURN
END
GO
