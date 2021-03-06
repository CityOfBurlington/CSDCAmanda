USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_ExportFeeByBillNumber]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ExportFeeByBillNumber](
@BillNumber INT,
@BillToPeopleCode INT)
AS
BEGIN	

	DECLARE @AccountBillFeeRSN INT
	DECLARE @FeeCode INT
	DECLARE @FeeAmount numeric(18,2)
	DECLARE @FeeComment VARCHAR(256)
	DECLARE @FolderRSN INT
	DECLARE @BillDate DATETIME
	DECLARE @DateGenerated DATETIME

	DECLARE @NextFeeExportRSN INT
	DECLARE @FolderName VARCHAR(80)
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

	/* Select all fee information for a given Bill Number to be exported */
	DECLARE curFees CURSOR FOR
		SELECT AccountBillFeeRSN, FeeCode, FeeComment, FeeAmount, 
		DateGenerated, AccountBill.DateGenerated, Folder.FolderRSN, 
		FolderName, Folder.PropertyRSN, PropertyRoll, FolderPeople.PeopleRSN
		FROM AccountBillFee 
		JOIN Folder ON AccountBillFee.FolderRSN = Folder.FolderRSN
		JOIN AccountBill on AccountBill.BillNumber = AccountBillFee.BillNumber
		JOIN Property ON Property.PropertyRSN = Folder.PropertyRSN
		JOIN FolderPeople ON FolderPeople.FolderRSN = Folder.FolderRSN
		JOIN People ON People.PeopleRSN = FolderPeople.PeopleRSN  AND FolderPeople.PeopleCode = @BillToPeopleCode
		WHERE AccountBill.BillNumber = @BillNumber
		
	OPEN curFees
	FETCH NEXT FROM curFees INTO @AccountBillFeeRSN, @FeeCode, @FeeComment, @FeeAmount, 
		@DateGenerated, @BillDate, @FolderRSN, @FolderName, @PropertyRSN, @ParcelID, @PeopleRSN

	WHILE @@FETCH_STATUS = 0
		BEGIN

		IF NOT EXISTS(SELECT BillNumber FROM tblFeeExport WHERE BillNumber = @BillNumber)
		BEGIN
			EXEC usp_ExportFee @AccountBillFeeRSN, @FolderRSN, @FeeCode,@FeeAmount,@FeeComment,@BillNumber,@BillDate
		END

		FETCH NEXT FROM curFees INTO @AccountBillFeeRSN, @FeeCode, @FeeComment, @FeeAmount, 
		@DateGenerated, @BillDate, @FolderRSN, @FolderName, @PropertyRSN, @ParcelID, @PeopleRSN
		
	END

	CLOSE curFees
	DEALLOCATE curFees

END

GO
