USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_LL]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_LL](@Year CHAR(2))
AS
BEGIN

	CREATE TABLE #temp(
		FolderRSN INT, 
		DBAName VARCHAR(100), 
		BusinessName VARCHAR(100), 
		ParcelID VARCHAR(13), 
		PropertyTaxesDue MONEY DEFAULT(0),
		GrossReceiptID VARCHAR(20), 
		GrossReceiptDue MONEY DEFAULT(0),		
		PersonalPropID VARCHAR(20), 
		PersonalPropDue MONEY DEFAULT(0),
		CommonAreaID VARCHAR(20),
		CommonAreaDue MONEY DEFAULT(0),
	)

	INSERT INTO #temp
	SELECT Folder.FolderRSN,
	dbo.f_info_alpha(Folder.FolderRSN, 7004) AS DBAName,
	dbo.f_info_alpha(Folder.FolderRSN, 7005) AS BusinessName,
	dbo.udf_GetFolderParcelID(Folder.FolderRSN) AS ParcelID,
	0 AS PropertyTaxesDue,
	dbo.f_info_alpha(Folder.FolderRSN, 7001) AS GrossReceiptID,
	0 AS GrossReceiptsDue,
	dbo.f_info_alpha(Folder.FolderRSN, 7002) AS PersonalPropID,
	0 AS PersonalPropDue,
	dbo.f_info_alpha(Folder.FolderRSN, 7003) AS CommonAreaID,
	0 AS CommonAreaDue
	FROM Folder
	WHERE Folder.FolderType = 'LL'
	AND Folder.FolderYear = @Year
	ORDER BY 2, 3

	CREATE TABLE #tempBalDue(
		DBAName				VARCHAR(100),
		BillType			VARCHAR(1), /*R=Real Estate, P=Personal, G=Gross*/
		AmountDue			MONEY
	)

	DECLARE @DBAName		VARCHAR(100)
	DECLARE @ParcelID		VARCHAR(20)
	DECLARE @GrossReceiptID	VARCHAR(20) 
	DECLARE @PersonalPropID	VARCHAR(20)
	DECLARE @CommonAreaID	VARCHAR(20)

	DECLARE @TaxYear		INT
	DECLARE @BalDue			MONEY

	SET @TaxYear = CAST('20' + @Year AS INT)

	DECLARE curParcels CURSOR FOR SELECT DBAName, ParcelID, GrossReceiptID, PersonalPropID, CommonAreaID FROM #temp
	OPEN curParcels
	
	FETCH NEXT FROM curParcels INTO @DBAName, @ParcelID, @GrossReceiptID, @PersonalPropID, @CommonAreaID

	WHILE @@FETCH_STATUS = 0
		BEGIN

		/*REAL ESTATE TAX*/
		INSERT INTO #tempBalDue EXEC cob005.pstax.dbo.usp_PastDue_RealEstateTaxes @DBAName, @ParcelID, 2007

		/*PERSONAL PROPERTY TAXES*/
		INSERT INTO #tempBalDue EXEC cob005.pstax.dbo.usp_PastDue_PersonalPropertyTaxes @DBAName, @PersonalPropID, @TaxYear 

		/*GROSS RECEIPTS TAX*/
		INSERT INTO #tempBalDue EXEC cob005.finplus.dbo.usp_PastDue_GrossReceiptTaxes @DBAName, @GrossReceiptID

		SET @BalDue = 0

		FETCH NEXT FROM curParcels INTO @DBAName, @ParcelID, @GrossReceiptID, @PersonalPropID, @CommonAreaID
	END

	CLOSE curParcels
	DEALLOCATE curParcels
	
	UPDATE #temp
	SET PropertyTaxesDue = #tempBalDue.AmountDue
	FROM #temp
	INNER JOIN #tempBalDue ON #temp.DBAName = #tempBalDue.DBAName
	WHERE #tempBalDue.BillType = 'R'

	UPDATE #temp
	SET PersonalPropDue = #tempBalDue.AmountDue
	FROM #temp
	INNER JOIN #tempBalDue ON #temp.DBAName = #tempBalDue.DBAName
	WHERE #tempBalDue.BillType = 'P'

	UPDATE #temp
	SET GrossReceiptDue = #tempBalDue.AmountDue
	FROM #temp
	INNER JOIN #tempBalDue ON #temp.DBAName = #tempBalDue.DBAName
	WHERE #tempBalDue.BillType = 'G'

	DROP TABLE #tempBalDue

	SELECT FolderRSN, DBAName, BusinessName, 
		ParcelID, ISNULL(PropertyTaxesDue, 0) AS PropertyTaxesDue,
		GrossReceiptID, ISNULL(GrossReceiptDue, 0) AS GrossReceiptDue, 
		PersonalPropID, ISNULL(PersonalPropDue, 0) AS PersonalPropDue, 
		CommonAreaID, ISNULL(CommonAreaDue, 0) AS CommonAreaDue
	FROM #temp

	DROP TABLE #temp
END

GO
