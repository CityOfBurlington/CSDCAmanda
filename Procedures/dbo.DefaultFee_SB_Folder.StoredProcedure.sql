USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_SB_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_SB_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @strLocationSubType VARCHAR(100)
DECLARE @strZoningDistrict VARCHAR(200)

SELECT @strLocationSubType = ValidSub.SubDesc
FROM Folder
INNER JOIN ValidSub ON Folder.SubCode = ValidSub.SubCode
INNER JOIN FolderProperty ON Folder.FolderRSN = FolderProperty.FolderRSN
INNER JOIN Property ON FolderProperty.PropertyRSN = Property.PropertyRSN
WHERE Folder.FolderRSN = @FolderRSN

SELECT @strZoningDistrict = ISNULL(ValidZone.ZoneDesc + ' (', ' (Property Zoning District) ') + ISNULL(Property.ZoneType1 + ')', ' ')
FROM Folder
INNER JOIN ValidSub ON Folder.SubCode = ValidSub.SubCode
INNER JOIN FolderProperty ON Folder.FolderRSN = FolderProperty.FolderRSN
INNER JOIN Property ON FolderProperty.PropertyRSN = Property.PropertyRSN
LEFT OUTER JOIN ValidZone ON Property.ZoneType1 = ZoneType
WHERE Folder.FolderRSN = @FolderRSN

IF @strLocationSubType = 'Existing Business'
BEGIN
    UPDATE Folder
    SET FolderDescription = (SELECT CONVERT(VARCHAR(2000), ClauseText) FROM ValidClause WHERE ClauseRSN = 374)
    WHERE FolderRSN = @FolderRSN
END
ELSE
    UPDATE Folder
    SET FolderDescription = (SELECT REPLACE(CONVERT(VARCHAR(2000), ClauseText), '___(#)____', @strZoningDistrict) FROM ValidClause WHERE ClauseRSN = 375)
    WHERE FolderRSN = @FolderRSN
GO
