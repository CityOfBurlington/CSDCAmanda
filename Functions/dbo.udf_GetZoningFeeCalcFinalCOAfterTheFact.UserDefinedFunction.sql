USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeeCalcFinalCOAfterTheFact]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeeCalcFinalCOAfterTheFact](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
	/* Calculates a Zoning Final CO After The Fact (ATF) fee if it does not exist, or 
	returns the existing ATF fee. Fees must be billed to execute correctly. */ 
	
	/* Version: ATF fee schedule effective July 1, 2012 (FY13). */

	/* When the rollover is within one day, in order for the calculation of the 
	number of 180 day intervals (@intATFMultiplier) to be correct, minutes 
	are used instead of days. (180 days = 4320 hours = 259200 minutes) 
	1 is added to @intATFMultiplier because the first interval starts at zero (0). */

	/* NOTE: Programming does not reflect one fee structure parameter: 
	Tier multipliers are driven off of the number of 180 day intervals from 
	the permit expiration date OR the date of occupancy if that occurred 
	first, to the current date. Dates of occupancy are not tracked in the DB, 
	so that calculation must be done by hand. This procedure uses only 
	the permit expiration date to calculate the multiplier. */

	DECLARE @varFolderType varchar(4)
	DECLARE @intSubCode int 
	DECLARE @dtDecisionDate datetime 
	DECLARE @varLevel3Review varchar(4)
	DECLARE @intAppealtoDRB int
	DECLARE @varReviewType varchar(10)
	DECLARE @moneyApplicationFee money
	DECLARE @fltATFNominalFee float
	DECLARE @fltAtfTierFee float
	DECLARE @varCOFlag varchar(2) 
	DECLARE @intATFFeeExists int
	DECLARE @dtPermitExpirationDate datetime
	DECLARE @dtCurrentDate datetime
	DECLARE @varATFFlag varchar(1) 
	DECLARE @intATFMultiplier int
	DECLARE @moneyATFFee money 

	SELECT @varFolderType = Folder.FolderType, 
		@intSubCode = Folder.SubCode, 
		@dtDecisionDate = Folder.IssueDate 
	FROM Folder 
	WHERE Folder.FolderRSN = @intFolderRSN 

	SELECT @intAppealtoDRB = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10002)

	SELECT @varReviewType = 
	CASE @intSubCode 
		WHEN 10041 THEN 'ADMIN'
		WHEN 10042 THEN 'DRB' 
		ELSE 'NA'
	END
	
	IF @intAppealtoDRB > 0 SELECT @varReviewType = 'DRB'

	SELECT @moneyApplicationFee = dbo.udf_GetZoningFeesPermitApplicationNoFF(@intFolderRSN)

	SELECT @fltATFNominalFee = ValidLookup.LookupFee
	FROM ValidLookup 
	WHERE ValidLookup.LookupCode = 15
	AND ValidLookup.Lookup1 = 5

	SELECT @fltAtfTierFee = ValidLookup.LookupFee
	FROM ValidLookup 
	WHERE ValidLookup.LookupCode = 15
	AND ValidLookup.Lookup1 = 6 

	SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intFolderRSN)

	SELECT @intATFFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 166 
	AND Folder.FolderRSN = @intFolderRSN

	SELECT @dtPermitExpirationDate = FolderInfo.InfoValueDateTime 
	FROM FolderInfo 
	WHERE FolderInfo.FolderRSN = @intFolderRSN 
	AND FolderInfo.InfoCode = 10024 

	SELECT @varLevel3Review = dbo.udf_GetZoningLevel3ReviewType(@intFolderRSN)

	SELECT @dtCurrentDate = CurrentDate 
	FROM dbo.uvw_Current_DateTime

	IF ( @dtPermitExpirationDate IS NOT NULL AND @dtPermitExpirationDate < @dtCurrentDate ) 
	BEGIN 
		IF ( @varFolderType IN ('ZA', 'ZF') OR @varLevel3Review = 'LLA' ) SELECT @varATFFlag = 'N' 
		ELSE SELECT @varATFFlag = 'Y' 
	END
	ELSE SELECT @varATFFlag = 'N' 

	/* ATF Fee does not exist */

	IF ( @intATFFeeExists = 0 AND @varATFFlag = 'Y' AND @varCOFlag = 'Y' ) 
	BEGIN   
		SELECT @intATFMultiplier = (DATEDIFF(minute, @dtPermitExpirationDate, @dtCurrentDate) / 259200) + 1 

		/* Nominal ATF */
		IF ( @dtDecisionDate > '7/13/1989 00:00:00' AND @dtPermitExpirationDate < '2/1/2009 00:00:00' ) 
			SELECT @moneyATFFee = @fltATFNominalFee 

		/* Tiers 1 (Admin) and 2 (DRB) */
		IF @dtPermitExpirationDate >= '2/1/2009 00:00:00' AND @dtPermitExpirationDate < '7/1/2012 00:00:00'
		BEGIN
			SELECT @moneyATFFee = ( @fltAtfTierFee * @intATFMultiplier )
			
			IF @varReviewType = 'ADMIN' AND @moneyATFFee > 450 SELECT @moneyATFFee = 450 
			
			IF @varReviewType = 'DRB' AND  @moneyATFFee > 1500 SELECT @moneyATFFee = 1500 
				
			IF @moneyApplicationFee < @moneyATFFee SELECT @moneyATFFee = @moneyApplicationFee
		END

		/* Tiers 3 (Admin) and 4 (DRB) */
		IF @dtPermitExpirationDate >= '7/1/2012 00:00:00'
		BEGIN
			SELECT @moneyATFFee = ( @fltAtfTierFee * @intATFMultiplier )
			
			IF @varReviewType = 'ADMIN' AND @moneyATFFee > 450 SELECT @moneyATFFee = 450 
			
			IF @varReviewType = 'DRB' AND  @moneyATFFee > 1500 SELECT @moneyATFFee = 1500 
		END
	END

	/* ATF fee already exists */

	IF ( @intATFFeeExists > 0 AND @varATFFlag = 'Y' AND @varCOFlag = 'Y' ) 
	BEGIN   
		SELECT @moneyATFFee = ISNULL(SUM(AccountBillFee.FeeAmount), 0) 
		FROM Folder, AccountBill, AccountBillFee
		WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
		AND Folder.FolderRSN = AccountBill.FolderRSN
		AND AccountBillFee.BillNumber = AccountBill.BillNumber
		AND AccountBill.PaidInFullFlag <> 'C'
		AND AccountBillFee.FeeCode = 166 
		AND Folder.FolderRSN = @intFolderRSN
	END 
	
	RETURN ISNULL(@moneyATFFee, 0) 
END

GO
