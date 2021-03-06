USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ExportFee]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ExportFee](
@AccountBillFeeRSN INT,
@FolderRSN INT,
@FeeCode INT, 
@FeeAmount numeric(18,2),
@FeeComment VARCHAR(256), 
@BillNumber INT,
@BillDate DATETIME)
AS
BEGIN	

	DECLARE @NextFeeExportRSN INT
	DECLARE @FolderName VARCHAR(80)
	DECLARE @FolderType VARCHAR(4)
	DECLARE @PropertyRSN INT
	DECLARE @ParcelID VARCHAR(30)
	DECLARE @PeopleRSN INT
	DECLARE @PeopleType INT
	
	/* DATE: 10/11/2010  Dana Baron  */
	/* This Stored Procedure exports fee data to Accounts Receivable. This works like this:             */
	/*    - When fees are created, the procedure PC_FEE_INSERT calls this procdure.                     */
	/*	  - This procedure creates an entry in the table tblFeeExport.                                  */
	/*	  - A SSIS package runs periodically to find rows in the table with ExportToARDate = NULL.      */
	/*    - The SSIS package sends these rows to a text file then updates ExportToARDate with the date. */

	SELECT @NextFeeExportRSN = MAX( tblFeeExport.tblFeeExportRSN ) + 1 FROM tblFeeExport
	SELECT @FolderName = FolderName, @FolderType = FolderType FROM Folder WHERE Folder.FolderRSN = @FolderRSN
	SELECT @PropertyRSN = PropertyRSN FROM FolderProperty WHERE FolderProperty.FolderRSN = @FolderRSN
	SELECT @ParcelID = PropertyRoll FROM Property WHERE Property.PropertyRSN = @PropertyRSN
	SELECT @PeopleType = PeopleCode FROM ValidFolder WHERE ValidFolder.FolderType = @FolderType
	SELECT @PeopleRSN = PeopleRSN FROM FolderPeople WHERE FolderPeople.FolderRSN = @FolderRSN AND FolderPeople.PeopleCode = @PeopleType

	INSERT INTO tblFeeExport
	(tblFeeExportRSN, AccountBillFeeRSN, FolderRSN, FolderName, PropertyRSN, ParcelID, PeopleRSN, PeopleType,
	FeeCode, FeeAmount, FeeComment, BillNumber, BillDate, ExportToARDate)
	VALUES
	(@NextFeeExportRSN, @AccountBillFeeRSN, @FolderRSN, @FolderName, @PropertyRSN, @ParcelID, @PeopleRSN, @PeopleType,
	@FeeCode, @FeeAmount, @FeeComment, @BillNumber, @BillDate, NULL)

END

GO
