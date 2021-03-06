USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_QZ_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_QZ_Folder]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* QZ Folder Initialization */

/* Set Subcode to Complaint Received. */

UPDATE Folder
   SET Folder.StatusCode = 1, Folder.SubCode = 20059
 WHERE Folder.FolderRSN = @folderRSN

/* Retrieve Zoning District, and code to Info. */

DECLARE @ZnDistrict varchar(3)

SELECT @ZnDistrict = Property.ZoneType1
  FROM Property, Folder
 WHERE Property.PropertyRSN = Folder.PropertyRSN
   AND Folder.FolderRSN = @folderRSN

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @ZnDistrict,
       FolderInfo.InfoValueUpper = @ZnDistrict
 WHERE FolderInfo.InfoCode = 20050
   AND FolderInfo.FolderRSN = @folderRSN

/* Retrieve Ward from Property, and code to Info. */

DECLARE @Ward int

SELECT @Ward = Property.PropPlan
  FROM Property, Folder
 WHERE Property.PropertyRSN = Folder.PropertyRSN
   AND Folder.FolderRSN = @folderRSN

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @Ward,
       FolderInfo.InfoValueNumeric =@Ward
 WHERE FolderInfo.InfoCode = 20051
   AND FolderInfo.FolderRSN =@folderRSN

/* Retrieve Assessor Use Code, and code to Info. */

DECLARE @AssessorUse varchar(3)

SELECT @AssessorUse = PropertyInfo.PropInfoValue
  FROM PropertyInfo, Property, Folder
 WHERE PropertyInfo.PropertyInfoCode = 10
   AND PropertyInfo.PropertyRSN = Property.PropertyRSN
   AND Property.PropertyRSN = Folder.PropertyRSN
   AND Folder.FolderRSN = @folderRSN

UPDATE FolderInfo
   SET FolderInfo.InfoValue = @AssessorUse,
       FolderInfo.InfoValueUpper = @AssessorUse
 WHERE FolderInfo.InfoCode = 20049
   AND FolderInfo.FolderRSN = @folderRSN

GO
