USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeeCalcFinalCOPhase]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeeCalcFinalCOPhase](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
	/* Calculates a Zoning Final CO application fee for a Phased Project, or returns 
		the existing and billed FCO fee amount.*/
	/* All FCO-related fees must be billed. */
	/* The Final CO Filing Fee is calculated by dbo.udf_GetZoningFeeCalcFinalCOFilingFee */

	DECLARE @varFolderType varchar(4)
	DECLARE @intNumberofPhases int
	DECLARE @intPhaseAbandoned int
	DECLARE @intNetPhases int
	DECLARE @dtInDate datetime
	DECLARE @fltPCOBaseFee float
	DECLARE @fltPCOFeeRate float
	DECLARE @varCOFlag varchar(2) 
	DECLARE @intPCOFeeExists int
	DECLARE @mnPermitApplicationFee money 
	DECLARE @mnPCOFee money 
   
	SET @mnPCOFee = 0

	SELECT @varFolderType = Folder.FolderType, @dtInDate = Folder.Indate 
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
	FROM FolderInfo
	WHERE FolderInfo.FolderRSN = @intFolderRSN
	AND FolderInfo.InfoCode = 10081
	
	SELECT @intPhaseAbandoned = dbo.udf_CountProcessAttemptResultSpecific(@intFolderRSN, 10030, 10067)

	SELECT @intNetPhases = @intNumberofPhases - @intPhaseAbandoned 
	IF @intNetPhases < 1 SELECT @intNetPhases = 1

	SELECT @fltPCOBaseFee = ValidLookup.LookupFee
	FROM ValidLookup 
	WHERE ValidLookup.LookupCode = 15
	AND ValidLookup.Lookup1 = 2

	SELECT @fltPCOFeeRate = ValidLookup.LookupFee
	FROM ValidLookup 
	WHERE ValidLookup.LookupCode = 15
	AND ValidLookup.Lookup1 = 3

	SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intFolderRSN)

	SELECT @intPCOFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 160 
	AND Folder.FolderRSN = @intFolderRSN

	IF @intPCOFeeExists = @intNetPhases		/* All phases are done */
	BEGIN
		SELECT @mnPCOFee = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
		FROM Folder, AccountBill, AccountBillFee
		WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
		AND Folder.FolderRSN = AccountBill.FolderRSN
		AND AccountBillFee.BillNumber = AccountBill.BillNumber
		AND AccountBill.PaidInFullFlag <> 'C'
		AND AccountBillFee.FeeCode = 160 
		AND Folder.FolderRSN = @intFolderRSN
	END
	ELSE
	BEGIN
		SELECT @mnPermitApplicationFee = ( ISNULL(SUM(AccountBillFee.FeeAmount), 0) ) / @intNetPhases
		FROM Folder, AccountBill, AccountBillFee
		WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
		AND Folder.FolderRSN = AccountBill.FolderRSN
		AND AccountBillFee.BillNumber = AccountBill.BillNumber
		AND AccountBill.PaidInFullFlag <> 'C'
		AND AccountBillFee.FeeCode IN(85, 86, 90, 95, 100, 105, 130, 135, 136, 147)
		AND Folder.FolderRSN = @intFolderRSN
	END
	
	IF @varCOFlag = 'N' SELECT @mnPCOFee = 0
	ELSE SELECT @mnPCOFee = @fltPCOBaseFee + ( @mnPermitApplicationFee * @fltPCOFeeRate )

	RETURN @mnPCOFee
END


GO
