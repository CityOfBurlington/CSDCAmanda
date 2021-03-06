USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Business_License_Folders]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Business_License_Folders](@FolderType CHAR(2), @Year CHAR(2)) 
AS

DECLARE @PropertyRSN	 INT
DECLARE @ParcelID		 VARCHAR(15)
DECLARE @PropertyAddress VARCHAR(100)
DECLARE @BusinessName	 VARCHAR(100)
DECLARE @DBAName		 VARCHAR(100)
DECLARE @BusinessPPId	 VARCHAR(20)

CREATE TABLE #tempProperty(
	PropertyRSN INT,
	BusinessName VARCHAR(100),
	DBAName VARCHAR(100)
)

INSERT INTO #tempProperty
SELECT Folder.PropertyRSN, dbo.f_info_alpha(Folder.FolderRSN, 7005)/*Business*/,
dbo.f_info_alpha(Folder.FolderRSN, 7004)/*DBA Name*/
FROM Folder 
WHERE FolderType = @FolderType
AND FolderYear = @Year

INSERT INTO #tempProperty
SELECT Property.ParentPropertyRSN, dbo.f_info_alpha(Folder.FolderRSN, 7005)/*Business*/,
dbo.f_info_alpha(Folder.FolderRSN, 7004)/*DBA Name*/
FROM Folder
INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
WHERE FolderType = @FolderType
AND FolderYear = @Year

CREATE TABLE #tempFolders(
	FolderRSN		INT,
	ParcelID		VARCHAR(15),
	BusinessName	VARCHAR(100),
	DBAName			VARCHAR(100),
	Address			VARCHAR(100),
	FolderType		VARCHAR(50),
	FolderGroup		VARCHAR(50),
	FolderDate		DATETIME,
	FolderStatus	VARCHAR(50),
	FeesDue			MONEY
)

DECLARE curProperty CURSOR FOR
SELECT DISTINCT PropertyRSN, BusinessName, DBAName
FROM #tempProperty
WHERE PropertyRSN IS NOT NULL

OPEN curProperty

FETCH NEXT FROM curProperty INTO @PropertyRSN, @BusinessName, @DBAName

WHILE @@FETCH_STATUS = 0
	BEGIN
	PRINT @PropertyRSN
	
	INSERT INTO #tempFolders
	SELECT Folder.FolderRSN, Property.PropertyRoll, @BusinessName, @DBAName,
	dbo.udf_GetPropertyAddress(Folder.PropertyRSN),
	ValidFolder.FolderDesc, ValidFolderGroup.FolderGroupDesc,
	Folder.InDate, ValidStatus.StatusDesc, 
	dbo.udf_GetFolderFeesDue(Folder.FolderRSN)
	FROM Folder
	INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
	INNER JOIN ValidFolder ON Folder.FolderType = ValidFolder.FolderType
	INNER JOIN ValidFolderGroup ON ValidFolder.FolderGroupCode = ValidFolderGroup.FolderGroupCode
	INNER JOIN ValidStatus ON Folder.StatusCode = ValidStatus.StatusCode
	WHERE Property.PropertyRSN = @PropertyRSN
	AND ValidFolderGroup.FolderGroupDesc <> 'Clerk/Treasurer'

	SELECT @ParcelID = Property.PropertyRoll,
	@PropertyAddress = dbo.udf_GetPropertyAddress(Folder.PropertyRSN),
	@BusinessPPId = dbo.f_info_alpha(Folder.FolderRSN, 7002)
	FROM Folder
	INNER JOIN Property ON Folder.PropertyRSN = Property.PropertyRSN
	WHERE Property.PropertyRSN = @PropertyRSN

	/*BUSINESS PERSONAL PROPERTY TAX*/
	IF EXISTS(SELECT *
			FROM cob005.pstax.dbo.r_detail 
			WHERE property_id = @BusinessPPId
			AND district = 'PERSONAL'
		)
		BEGIN

		INSERT INTO #tempFolders
		SELECT DISTINCT NULL, @BusinessPPId, @BusinessName, @DBAName, @PropertyAddress,
		'Business Personal Proprty Tax', 'Taxes',
		CAST(dbo.udf_Trunc(GetDate()) AS DATETIME), ' ', (SUM(amt_due) - SUM(amt_paid))
		+ (SUM(penalty) - SUM(pen_paid)) 
		+ (SUM(interest) - SUM(int_paid)) 
		FROM cob005.pstax.dbo.r_detail 
		WHERE property_id = @BusinessPPId
		AND district = 'PERSONAL'
		AND tax_yr < 2007
	END

	/*DID PROPERTY TAX*/
	IF EXISTS(SELECT *
			FROM cob005.pstax.dbo.r_detail 
			WHERE property_id = @ParcelID
			AND district = 'DID'
		)
		BEGIN

		INSERT INTO #tempFolders
		SELECT DISTINCT NULL, @ParcelID, @BusinessName, @DBAName, @PropertyAddress,
		'DID Property Tax', 'Taxes',
		CAST(dbo.udf_Trunc(GetDate()) AS DATETIME), ' ', (SUM(amt_due) - SUM(amt_paid))
		+ (SUM(penalty) - SUM(pen_paid)) 
		+ (SUM(interest) - SUM(int_paid)) 
		FROM cob005.pstax.dbo.r_detail 
		WHERE property_id = @ParcelID
		AND district = 'DID'
		AND tax_yr < 2007
	END

	/*REAL ESTATE TAX*/
	IF EXISTS(SELECT *
			FROM cob005.pstax.dbo.r_detail 
			WHERE property_id = @ParcelID
			AND district = 'CITY'
		)
		BEGIN

		INSERT INTO #tempFolders
		SELECT DISTINCT NULL, @ParcelID, @BusinessName, @DBAName, @PropertyAddress,
		'Real Estate Tax', 'Taxes',
		CAST(dbo.udf_Trunc(GetDate()) AS DATETIME), ' ', (SUM(amt_due) - SUM(amt_paid))
		+ (SUM(penalty) - SUM(pen_paid)) 
		+ (SUM(interest) - SUM(int_paid)) 
		FROM cob005.pstax.dbo.r_detail 
		WHERE property_id = @ParcelID
		AND district = 'CITY'
		AND tax_yr < 2007
	END

	FETCH NEXT FROM curProperty INTO @PropertyRSN, @BusinessName, @DBAName
END

CLOSE curProperty
DEALLOCATE curProperty 

DECLARE @CleanupFees MONEY

DECLARE curCleanup CURSOR FOR 
SELECT BusinessName, SUM(ISNULL(FeesDue, 0))
FROM #tempFolders
GROUP BY BusinessName
HAVING SUM(FeesDue) = 0

OPEN curCleanUp

FETCH NEXT FROM curCleanup INTO @BusinessName, @CleanupFees

WHILE @@FETCH_STATUS = 0
	BEGIN

	DELETE FROM #tempFolders 
	WHERE BusinessName = @BusinessName

	FETCH NEXT FROM curCleanup INTO @BusinessName, @CleanupFees
END

CLOSE curCleanup
DEALLOCATE curCleanup

SELECT DISTINCT * 
FROM #tempFolders
ORDER BY DBAName

DROP TABLE #tempFolders
DROP TABLE #tempProperty

GO
