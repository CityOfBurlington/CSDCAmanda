USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB_Unmatched_UnitNumbers]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RB_Unmatched_UnitNumbers](@FolderYear INT)
AS
BEGIN

SELECT Property.PropertyRSN, uvw_RB.FolderRSN, 
dbo.udf_GetPropertyAddress(Property.PropertyRSN) AS PropertyAddress,
ISNULL(dbo.udf_GetFolderPeopleName(uvw_RB.FolderRSN, 322), '') AS RBPrimaryCodeOwner,
ISNULL(dbo.f_info_alpha_property(Property.PropertyRSN, 600), '') AS CodeInspector,
ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) AS PropRentalUnits,
uvw_RB.RentalUnits AS RBRentalUnits,
uvw_RB.BilledRentalUnits AS RBBilledRentalUnits,
CASE WHEN ISNULL(dbo.f_info_alpha_property(Property.PropertyRSN, 22), '') <> 'Yes' THEN '' ELSE 'Yes' END AS ExemptFee,
ISNULL(dbo.udf_GetFolderFeesDue(uvw_RB.FolderRSN), 0) AS RB_Fees_Due,
uvw_RB.FolderStatus
FROM Property
LEFT OUTER JOIN uvw_RB ON Property.PropertyRSN = uvw_RB.PropertyRSN AND uvw_RB.FolderYear = @FolderYear
WHERE ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) + uvw_RB.BilledRentalUnits + uvw_RB.RentalUnits > 0 AND
( ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) <> uvw_RB.RentalUnits OR ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) <> uvw_RB.BilledRentalUnits OR uvw_RB.RentalUnits <> uvw_RB.BilledRentalUnits )
ORDER BY Property.PropStreet, Property.PropStreetType, Property.PropHouseNumeric, Property.PropUnit

END



GO
