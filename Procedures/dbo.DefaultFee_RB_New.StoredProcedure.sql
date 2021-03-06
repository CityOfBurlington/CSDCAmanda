USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_RB_New]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_RB_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @RentalUnits int
DECLARE @UseCode varchar(2)
DECLARE @RentalFEE float
DECLARE @FeeAmount float
DECLARE @FeeComment varchar(100)
DECLARE @CreateBill varchar(3)
DECLARE @ExportFee varchar(3)

	/* DATE: 11/10/2010	Dana Baron  */
	/* This Stored Procedure run when a new Rental Billing (RB) folder is created */
	/*                                                                                        */

SELECT @UseCode = PropertyInfo.PropInfoValue
FROM PropertyInfo, Folder
WHERE PropertyInfo.PropertyRSN = Folder.PropertyRSN
AND Folder.FolderRSN = @FolderRSN
AND PropertyInfo.PropertyInfoCode = 10

SELECT @RentalUnits = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 20020 

IF @UseCode = 'R2' AND @RentalUnits = 1
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
SET @FeeAmount = @RentalUnits * @RentalFee

/* Rental Registration Fee */

SET @NextRSN = @NextRSN + 1 

IF @FeeAmount = 0
	SET @FeeComment = 'Exempt'
ELSE
	SET @FeeComment = 'Rental Registration Fee'

--EXEC PC_FEE_INSERT @FolderRSN, 905, @FeeAmount, @UserID, 1, @FeeComment, 1, 1

DECLARE @strReferenceFile AS VARCHAR(20)

SELECT @strReferenceFile = CAST(FolderPeople.PeopleRSN AS VARCHAR(20))
FROM Folder
INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
WHERE Folder.FolderRSN = @FolderRSN
AND FolderPeople.PeopleCode = 322

SET @strReferenceFile = ISNULL(@strReferenceFile, 'XXXXXXXX')

--UPDATE Folder 
--SET ReferenceFile = @strReferenceFile 
--WHERE FolderRSN = @FolderRSN

GO
