USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB_UnitCompare_To_Property2]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_RB_UnitCompare_To_Property2](@FolderYear INT)
AS
BEGIN
	SELECT Property.PropertyRSN, uvw_RB.FolderRSN,
	dbo.udf_GetPropertyAddress(Property.PropertyRSN) AS PropertyAddress,
	ISNULL(dbo.udf_GetFolderPeopleName(uvw_RB.FolderRSN, 322), '') AS RBPrimaryCodeOwner,
	ISNULL(dbo.f_info_alpha_property(Property.PropertyRSN, 600), '') AS CodeInspector,
	ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) AS PropRentalUnits,

	uvw_RB.RentalUnits AS RBRentalUnits,
	uvw_RB.BilledRentalUnits AS RBBilledUnits,

	CASE WHEN ISNULL(dbo.f_info_alpha_property(Property.PropertyRSN, 22), '') <> 'Yes' THEN '' ELSE 'Yes' END AS ExemptFee,
	ISNULL(dbo.udf_GetFolderFeesDue(uvw_RB.FolderRSN), 0) AS RB_Fees_Due,
	CASE WHEN dbo.udf_GetLastLRFolderDeedTransfer(Property.PropertyRSN) > DATEADD(YEAR, -1, GETDATE()) THEN dbo.FormatDateTime(dbo.udf_GetLastLRFolderDeedTransfer(Property.PropertyRSN), 'MM/DD/YYYY') ELSE '' END AS LR_Trans_Date/*,
	ISNULL(dbo.FormatDateTime(dbo.udf_GetLastPropertyFolderAttemptResult(Property.PropertyRSN, 'MH'), 'MM/DD/YYYY'), '') AS Last_MH_Attempt*/

	/*These fields aren't on the report, just needed for sorting data*/

	FROM uvw_RB
	INNER JOIN Property ON uvw_RB.PropertyRSN = Property.PropertyRSN
	WHERE /*ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) <> 0
	AND*/ uvw_RB.FolderYear = @FolderYear
	ORDER BY Property.PropStreet, Property.PropStreetType, Property.PropHouseNumeric, Property.PropUnit

END



GO
