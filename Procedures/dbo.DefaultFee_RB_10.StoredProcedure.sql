USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_10]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_10]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @RentalUnits int
DECLARE @ExemptRentalUnits int
DECLARE @BilledRentalUnits int
DECLARE @UseCode varchar(2)
DECLARE @RentalFEE float
DECLARE @FeeAmount float
DECLARE @FeeComment varchar(100)
DECLARE @CreateBill varchar(3)
DECLARE @ExportFee varchar(3)
DECLARE @PeopleType INT
DECLARE @PeopleRSN INT

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure is part of the processing for annual Rental Billing (RB) folders   */
	/* To create RB folders for a new year, change the following:                               */
	/*		FeeCode (set to new value for the new year)                                         */
	/*		FeeComment (set to new text for new year)                                           */
	/*		Be sure the Rental Billing fee is updated as necessary                              */
	/*                                                                                          */
	/* Other stored procedures that work with this are:                                         */
	/*	usp_CreateAnnualRBFolders                                                               */
	/*	usp_CreateRBFolder                                                                      */
	/*	DefaultFee_RB_10  (this sp)                                                             */

	/* January 24, 2011 - changed logic to get information about billed units from PropertyInfo */
	/*						rather than FolderInfo.                                             */

/* Make sure we have someone to bill to */
SELECT @PeopleType = PeopleCode FROM ValidFolder WHERE ValidFolder.FolderType = 'RB'
SELECT @PeopleRSN = PeopleRSN FROM FolderPeople WHERE FolderPeople.FolderRSN = @FolderRSN AND FolderPeople.PeopleCode = @PeopleType
IF @PeopleRSN IS NULL 
BEGIN
    RAISERROR ('You will need to identify the Primary Code Owner for this property before you send the bill.', 16, -1)
    RETURN
END

SELECT @UseCode = PropertyInfo.PropInfoValue
FROM PropertyInfo, Folder
WHERE PropertyInfo.PropertyRSN = Folder.PropertyRSN
AND Folder.FolderRSN = @FolderRSN
AND PropertyInfo.PropertyInfoCode = 10

SET @RentalUnits = 0
IF EXISTS (SELECT PropertyInfo.PropInfoValue FROM PropertyInfo, Folder
	WHERE PropertyInfo.PropertyRSN = Folder.PropertyRSN
	AND Folder.FolderRSN = @FolderRSN AND PropertyInfo.PropertyInfoCode = 20)
BEGIN
	SELECT @RentalUnits = PropertyInfo.PropInfoValue
	FROM PropertyInfo, Folder
	WHERE PropertyInfo.PropertyRSN = Folder.PropertyRSN
	AND Folder.FolderRSN = @FolderRSN
	AND PropertyInfo.PropertyInfoCode = 20
END

SET @ExemptRentalUnits = 0
IF EXISTS (SELECT PropertyInfo.PropInfoValue FROM PropertyInfo, Folder
	WHERE PropertyInfo.PropertyRSN = Folder.PropertyRSN
	AND Folder.FolderRSN = @FolderRSN AND PropertyInfo.PropertyInfoCode = 23)
BEGIN
	SELECT @ExemptRentalUnits = ISNULL(PropertyInfo.PropInfoValue,0)
	FROM PropertyInfo, Folder
	WHERE PropertyInfo.PropertyRSN = Folder.PropertyRSN
	AND Folder.FolderRSN = @FolderRSN
	AND PropertyInfo.PropertyInfoCode = 23
END

SET @BilledRentalUnits = @RentalUnits - @ExemptRentalUnits

IF @UseCode = 'R2' AND @BilledRentalUnits = 1
BEGIN
SELECT @RentalFee = ValidLookup.LookupFee,
	   @CreateBill = ValidLookup.LookupString3,
	   @ExportFee = ValidLookup.LookupString4
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 8 ) 
   AND ( ValidLookup.Lookup1 = 1 )
END
ELSE
BEGIN
SELECT @RentalFee = ValidLookup.LookupFee,
	   @CreateBill = ValidLookup.LookupString3,
	   @ExportFee = ValidLookup.LookupString4
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 8 ) 
   AND ( ValidLookup.Lookup1 = 2 )
END
SET @Feeamount = @BilledRentalUnits * @RentalFee

/* Rental Registration Fee */

SET @NextRSN = @NextRSN + 1 

IF @FeeAmount = 0
	SET @FeeComment = 'Exempt'
ELSE
	SET @FeeComment = 'Rental Registration Fee'

EXEC TK_FEE_INSERT @FolderRSN, 907, @FeeAmount, @UserID, @FeeComment, 1, 1

DECLARE @strReferenceFile AS VARCHAR(20)

SELECT @strReferenceFile = CAST(FolderPeople.PeopleRSN AS VARCHAR(20))
FROM Folder
INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
WHERE Folder.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = 322

SET @strReferenceFile = ISNULL(@strReferenceFile, 'XXXXXXXX')

UPDATE Folder 
SET ReferenceFile = @strReferenceFile 
WHERE FolderRSN = @FolderRSN

GO
