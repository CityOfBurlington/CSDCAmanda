USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_BP_New]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_BP_New]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/************************************************************/
/*calculations for Building Permit Fee and Clerks Filing Fee*/
/************************************************************/
DECLARE @CalculatedBuildingFee FLOAT
DECLARE @CalculatedFilingFee FLOAT
DECLARE @CofORequired CHAR(3)
DECLARE @Estimated_Cost_of_Construction FLOAT 
DECLARE @SubCode INT
DECLARE @Building_Fee_Rate FLOAT 
DECLARE @FilingFeeRate FLOAT
DECLARE @MinimumFee FLOAT
DECLARE @IsMunicipal INT
DECLARE @WorkCode INT

SET @IsMunicipal = 1
SET @CalculatedBuildingFee = 0
SET @CalculatedFilingFee = 0

SELECT @Estimated_Cost_of_Construction = FolderInfo.InfoValueNumeric
FROM FolderInfo 
WHERE (FolderInfo.FolderRSN = @FolderRSN) 
AND (FolderInfo.InfoCode = 30006)

SELECT @SubCode = SubCode
FROM Folder 
WHERE FolderRSN = @FolderRSN

IF @SubCode = 30011 
BEGIN
     SET @IsMunicipal = 0
END

SELECT @WorkCode = WorkCode
FROM Folder
WHERE FolderRSN = @FolderRSN


SELECT @CofORequired = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30059

SELECT @Building_Fee_Rate = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE (ValidLookup.LookupCode = 1) 
AND (ValidLookUp.LookUp1 = 1)

SELECT @FilingFeeRate = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE (ValidLookup.LookupCode = 1) 
AND (ValidLookup.Lookup1 = 2)

SELECT @MinimumFee = ValidLookup.LookupFee 
FROM ValidLookup 
WHERE (ValidLookup.LookupCode = 1) 
AND (ValidLookup.Lookup1 = 3)

SET @CalculatedBuildingFee = @Building_Fee_Rate * @Estimated_Cost_of_Construction * @IsMunicipal

IF @CalculatedBuildingFee < @MinimumFee
	BEGIN
	SET @CalculatedBuildingFee = @MinimumFee * @IsMunicipal
END


IF @CofORequired = 'Yes'
	BEGIN
	SET @CalculatedFilingFee = @FilingFeeRate * 2 * @IsMunicipal
	END
ELSE
        BEGIN
	SET @CalculatedFilingFee = @FilingFeeRate * @IsMunicipal
        END

/* BP Not required. Set Building Fee and Filing Fee to 0. */
IF @WorkCode = 30110
	BEGIN
	SET @CalculatedBuildingFee = 0
	SET @CalculatedFilingFee = 0
	END

/* Clerks Filing Fee */
SELECT @NextRSN = @NextRSN + 1

INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser) 
VALUES(@NextRSN, @FolderRSN, 80, 'Y', @CalculatedFilingFee, 0, 0, getdate(), @UserId)

/* Building Permit Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee (AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser)
VALUES (@NextRSN, @FolderRSN, 25, 'Y', @CalculatedBuildingFee, 0, 0, getdate(), @UserId)

BEGIN TRAN
	EXECUTE DEFAULTFee_BP_10 @FolderRSN, @UserID
COMMIT TRAN

/*************************************************************/
/*adding child folders based on what is checked in infofields*/
/*************************************************************/
DECLARE @ElectricalReq   char(3)
DECLARE @PlumbingReq     char(3)
DECLARE @MechanicalReq   char(3)
DECLARE @AlarmReq        char(3)
DECLARE @SprinklerReq    char(3)
DECLARE @SuppressionReq  char(3)
DECLARE @ElecControlReq  char(3)
DECLARE @ObstructionReq  char(3)

SELECT @ElectricalReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30000

SELECT @ElecControlReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30127

SELECT @PlumbingReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30001

SELECT @MechanicalReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30002

SELECT @AlarmReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30003

SELECT @SprinklerReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30004

SELECT @SuppressionReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30005

SELECT @ObstructionReq = FolderInfo.InfoValue
FROM FolderInfo
WHERE FolderInfo.FolderRSN = @FolderRSN
AND FolderInfo.InfoCode = 30096

DECLARE @NextFolderRSN INT
DECLARE @strCurrentYear CHAR(4)

SELECT @strCurrentYear = SUBSTRING(CONVERT(CHAR(4), DATEPART(YEAR, GetDate())), 3, 2)

/********************************************/
/*Insert Child Electrical Permit if required*/
/********************************************/
IF @ElectricalReq ='Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear,  dbo.udf_GetNextFolderSeq(), '000', '00',
		'EP', '30000', PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
	COMMIT TRAN
END


/****************************************************/
/*Insert Child Electrical Control Permit if required*/
/****************************************************/

IF @ElecControlReq ='Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		'EC', '30000', SubCode, 30023, PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
	COMMIT TRAN
END


/********************************************/
/*Insert Child Plumbing Permit if required  */
/********************************************/

IF @PlumbingReq = 'Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType,StatusCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName,StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		'PP', '30000', PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN
	COMMIT TRAN
END


/********************************************/
/*Insert Child Mechanical Permit if required*/
/********************************************/

IF @MechanicalReq = 'Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		 'MP', '30000', PropertyRSN, getdate(),
		 @FolderRSN, 'DDDDD', FolderName, getdate(), User
		 FROM Folder
		 WHERE FolderRSN = @FolderRSN 
	 COMMIT TRAN
END


/*************************************************/
/*Insert Child Obstruction/ROW Permit if required*/
/*************************************************/

IF @ObstructionReq = 'Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		 'OB', '30000', PropertyRSN, getdate(),
		 @FolderRSN, 'DDDDD', FolderName, getdate(), User
		 FROM Folder
		 WHERE FolderRSN = @FolderRSN 
	 COMMIT TRAN
END
/********************************************/
/*Insert Child Fire Alarm Permit if required*/
/********************************************/

IF @AlarmReq = 'Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		'AL', '30000', SubCode, 30014, PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
	COMMIT TRAN
END


/********************************************/
/*Insert Child Sprinkler Permit if required */
/********************************************/

IF @SprinklerReq = 'Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		'SS', '30000', SubCode, 30015, PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
	COMMIT TRAN
END


/****************************************************/
/*Insert Child Suppression System Permit if required*/
/****************************************************/


IF @SuppressionReq = 'Yes'
	BEGIN
	SELECT @NextFolderRSN = MAX(FolderRSN) + 1 FROM Folder
	BEGIN TRAN
		INSERT INTO FOLDER
		(FolderRSN, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		FolderType, StatusCode, SubCode, WorkCode, PropertyRSN, Indate,
		ParentRSN, CopyFlag, FolderName, StampDate, StampUser)
		SELECT @NextFolderRSN, 20, @strCurrentYear, dbo.udf_GetNextFolderSeq(), '000', '00',
		'SU', '30000', SubCode, 30016, PropertyRSN, getdate(),
		@FolderRSN, 'DDDDD', FolderName, getdate(), User
		FROM Folder
		WHERE FolderRSN = @FolderRSN 
	COMMIT TRAN
END

GO
