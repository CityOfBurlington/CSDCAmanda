USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_QI_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_QI_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @RentalUnits int

SELECT @RentalUnits = PropertyInfo.PropertyInfoValueNumeric
FROM PropertyInfo, Folder
WHERE PropertyInfo.PropertyInfoCode = 20
AND PropertyInfo.PropertyRSN = Folder.PropertyRSN
AND Folder.FolderRSN = @FolderRSN

UPDATE FolderInfo
SET FolderInfo.InfoValue = @RentalUnits
WHERE FolderInfo.InfoCode = 20031
AND FolderInfo.FolderRSN = @FolderRSN


GO
