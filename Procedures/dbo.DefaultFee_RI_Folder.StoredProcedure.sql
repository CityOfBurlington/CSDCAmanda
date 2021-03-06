USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RI_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RI_Folder]
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
SET FolderInfo.InfoValue = @RentalUnits,
FolderInfo.InfoValueNumeric = @RentalUnits
WHERE FolderInfo.InfoCode = 20031
AND FolderInfo.FolderRSN = @FolderRSN

--to insert people records from RR
EXECUTE DefaultProcess_RR_11111111 0, @FolderRSN, @UserID

GO
