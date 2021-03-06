USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateRBFolder]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_CreateRBFolder](@intPropertyRSN INT, @intFolderYear INT, @strUserID VARCHAR(8))
AS
BEGIN	

	/* DATE: 2/24/2009	Dana Baron  */
	/* This Stored Procedure processes annual Rental Billing (RB) folders */
	/* Other stored procedures that work with this are:                   */
	/*	usp_CreateAnnualRBFolders                                         */
	/*	usp_CreateRBFolder   (this sp)                                    */
	
	DECLARE @intOldFolderRSN INT
	DECLARE @intNextFolderRSN INT
	DECLARE @strFolderYear VARCHAR(4)
	DECLARE @intPriorYear INT
	DECLARE @strPriorYear VARCHAR(4)
	DECLARE @strPropertyAddress VARCHAR(200)
	DECLARE @strFolderDesc VARCHAR(100)
	DECLARE @OutstandingFee MONEY
	DECLARE @strFeeWarning VARCHAR(25)
	DECLARE @intNumBilledUnits INT
	DECLARE @intNumRentalUnits INT
	DECLARE @strExemptStatus VARCHAR(8)
	DECLARE @intNumExemptUnits INT
	DECLARE @strUseCode VARCHAR(4)
	
	DECLARE @RentalFEE float
	DECLARE @FeeAmount float
	DECLARE @FeeComment varchar(100)
	DECLARE @CreateBill varchar(3)
	DECLARE @ExportFee varchar(3)
	DECLARE @PeopleType INT
	DECLARE @PeopleRSN INT
	DECLARE @strReferenceFile AS VARCHAR(20)
	DECLARE @PrimaryCodeOwnerRSN VARCHAR(20)


	SELECT @strFolderYear = RIGHT(CAST(@intFolderYear AS VARCHAR(4)), 2),
	@intPriorYear = @intFolderYear - 1,
	@strPriorYear = RIGHT(CAST(@intFolderYear - 1 AS VARCHAR(4)), 2)

	SET @strFolderYear = RIGHT('0' + @strFolderYear, 2)
	SET @strPriorYear = RIGHT('0' + @strPriorYear, 2)

	SET @strFolderDesc = '20' + @strFolderYear + ' Rental Billing'

	SELECT @strPropertyAddress = dbo.udf_GetPropertyAddress(@intPropertyRSN),
	@intNextFolderRSN  = dbo.udf_GetNextFolderRSN()

	/* Create new RB Folder. */
	INSERT INTO Folder
	(FolderRSN, IssueUser, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
	FolderType, StatusCode, PropertyRSN, Indate, FolderDescription,
	CopyFlag,  StampDate, FolderName)
	SELECT @intNextFolderRSN, @strUserID, 20, @strFolderYear, dbo.udf_GetNextFolderSeq(), '000', '00',
	'RB', 1, @intPropertyRSN, GETDATE(), @strFolderDesc, 'DDDDD',  GETDATE(), @strPropertyAddress

	/* Add FolderComment for outstanding fee from last year if there is one. */
	SELECT @intOldFolderRSN = FolderRSN FROM Folder
		WHERE FolderType = 'RB' AND StatusCode = 1 AND FolderYear = @strPriorYear

	SELECT @OutstandingFee = dbo.udf_GetFolderFeesDue(@intOldFolderRSN)
	IF @OutstandingFee > 0 
	BEGIN
		SET @strFeeWarning = @strPriorYear + ' Fee Outstanding'
		UPDATE Folder SET FolderCondition = @strFeeWarning WHERE FolderRSN = @intNextFolderRSN
		INSERT INTO FolderComment
		(FolderRSN, CommentDate, CommentUser, StampDate, StampUser, Comments)
		SELECT @intNextFolderRSN, GETDATE(), @strUserID, GETDATE(), @strUserID, @strFeeWarning
	END

	/*Copy People From PropertyPeople into FolderPeople for People Types Property Manager (75), */
	/* Emergency Contact (80), Service of Process (85) and Primary Code Owner (322) */
	INSERT INTO FolderPeople
	(FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampDate, StampUser, PeopleRSNCrypt, SecurityCode)
	SELECT @intNextFolderRSN, PeopleCode, PeopleRSN, PrintFlag, GetDate(), @strUserID, PeopleRSNCrypt, SecurityCode
	FROM PropertyPeople
	WHERE PropertyRSN = @intPropertyRSN
	AND PropertyPeople.PeopleCode IN (75, 80, 85, 322)

	/*Create or Update FolderInfo fields. 
	  Info fields defined as default are inserted automatically so we only have to update these. 
	  Currently therse are:
		5000  - Print Bill Date = getdate()
		20020 - No of Billed Rental Units = Number of Rental Units - Number of Exempt Units
		20031 - Number of Rental Units = PropertyInfo(20)
		20046 - Exemption Status = PropertyInfo(22)
		20047 - No of Exempt Units = PropertyInfo(23)
	  To be on the safe side, the logic checks that the field exists and UPDATEs if it does, INSERTs it if it doesn't.
	*/
	SELECT @strExemptStatus = ISNULL(dbo.f_info_alpha_property(@intPropertyRSN,22),'No'),
	       @intNumRentalUnits = ISNULL(dbo.f_info_numeric_property(@intPropertyRSN,20),0),
	       @intNumExemptUnits = ISNULL(dbo.f_info_numeric_property(@intPropertyRSN,23),0)
	SET @intNumBilledUnits = @intNumRentalUnits - @intNumExemptUnits

	/* Bill Print Date */
    IF EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 5000)
    BEGIN
		UPDATE FolderInfo SET InfoValue = dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY'), 
		InfoValueDateTime = getdate(), DisplayOrder = 50,StampDate = getdate(), StampUser = @strUserID
		WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 5000
    END
	ELSE
	BEGIN
        INSERT INTO FolderInfo (FolderRSN,InfoCode,InfoValue,InfoValueDateTime,DisplayOrder,StampDate,StampUser)
        VALUES(@intNextFolderRSN, 5000, dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY'), getdate(), 50, 
        getdate(), @strUserID)
	END

	/* No of Billed Rental Units */
    IF EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20020)
    BEGIN
		UPDATE FolderInfo SET InfoValue = @intNumBilledUnits, InfoValueNumeric = @intNumBilledUnits, 
		DisplayOrder = 20,StampDate = getdate(), StampUser = @strUserID
		WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20020
    END
	ELSE
	BEGIN
        INSERT INTO FolderInfo (FolderRSN,InfoCode,InfoValue,InfoValueNumeric,DisplayOrder,StampDate,StampUser)
        VALUES(@intNextFolderRSN, 20020, @intNumBilledUnits, @intNumBilledUnits, 20, getdate(), @strUserID)
	END

	/* No of Rental Units */
    IF EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20031)
    BEGIN
		UPDATE FolderInfo SET InfoValue = @intNumRentalUnits, InfoValueNumeric = @intNumRentalUnits, 
		DisplayOrder = 10,StampDate = getdate(), StampUser = @strUserID
		WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20031
    END
	ELSE
	BEGIN
        INSERT INTO FolderInfo (FolderRSN,InfoCode,InfoValue,InfoValueNumeric,DisplayOrder,StampDate,StampUser)
        VALUES(@intNextFolderRSN, 20031, @intNumRentalUnits, @intNumRentalUnits, 10, getdate(), @strUserID)
	END

	/* Exemption Status */
    IF EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20046)
    BEGIN
		UPDATE FolderInfo SET InfoValue = @strExemptStatus,  
		DisplayOrder = 30,StampDate = getdate(), StampUser = @strUserID
		WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20046
    END
	ELSE
	BEGIN
        INSERT INTO FolderInfo (FolderRSN,InfoCode,InfoValue,DisplayOrder,StampDate,StampUser)
        VALUES(@intNextFolderRSN, 20046, @strExemptStatus, 30, getdate(), @strUserID)
	END

	/* No of Exempt Units */
    IF EXISTS(SELECT InfoValue FROM FolderInfo WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20047)
    BEGIN
		UPDATE FolderInfo SET InfoValue = @intNumExemptUnits, InfoValueNumeric = @intNumExemptUnits, 
		DisplayOrder = 40,StampDate = getdate(), StampUser = @strUserID
		WHERE FolderRSN = @intNextFolderRSN AND InfoCode = 20047
    END
	ELSE
	BEGIN
        INSERT INTO FolderInfo (FolderRSN,InfoCode,InfoValue,InfoValueNumeric,DisplayOrder,StampDate,StampUser)
        VALUES(@intNextFolderRSN, 20047, @intNumExemptUnits, @intNumExemptUnits, 40, getdate(), @strUserID)
	END

	SELECT @strUseCode = PropertyInfo.PropInfoValue
	FROM PropertyInfo
	WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
	AND PropertyInfo.PropertyInfoCode = 10

	IF @strUseCode = 'R2' AND @intNumBilledUnits = 1
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
	SET @Feeamount = @intNumBilledUnits * @RentalFee

	/* Rental Registration Fee */
	IF @FeeAmount = 0
		SET @FeeComment = 'Exempt'
	ELSE
		SET @FeeComment = 'Rental Registration Fee'

	EXEC TK_FEE_INSERT @intNextFolderRSN, 907, @FeeAmount, @strUserID, @FeeComment, 1, 1

	SELECT @strReferenceFile = CAST(FolderPeople.PeopleRSN AS VARCHAR(20))
	FROM Folder
	INNER JOIN FolderPeople ON Folder.FolderRSN = FolderPeople.FolderRSN
	WHERE Folder.FolderRSN = @intNextFolderRSN
	AND FolderPeople.PeopleCode = 322

	SET @strReferenceFile = ISNULL(@strReferenceFile, 'XXXXXXXX')

	UPDATE Folder 
	SET ReferenceFile = @strReferenceFile 
	WHERE FolderRSN = @intNextFolderRSN

END




GO
