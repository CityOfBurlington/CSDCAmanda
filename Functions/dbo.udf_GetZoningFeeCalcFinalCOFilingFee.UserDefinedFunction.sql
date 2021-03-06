USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeeCalcFinalCOFilingFee]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeeCalcFinalCOFilingFee](@intFolderRSN INT)
RETURNS MONEY
AS
BEGIN
   /* Calculates a Zoning Final CO Filing fee for single and multi phase projects. */
   /* All FCO-related fees must be billed. */

	DECLARE @intStatusCode int
	DECLARE @dtInDate datetime
	DECLARE @varCOFlag varchar(2) 
	DECLARE @intNumberofPhases int
	DECLARE @intPhaseAbandoned int
	DECLARE @intNetPhases int
	DECLARE @intFCOFilingFeeExists int 
	DECLARE @mnFCOFilingFee float 
	DECLARE @mnFilingFee money

	SELECT @intStatusCode = Folder.StatusCode, @dtInDate = Folder.Indate 
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intFolderRSN)

	SELECT @intFCOFilingFeeExists = COUNT(*)  
	FROM Folder, AccountBill, AccountBillFee
	WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
	AND Folder.FolderRSN = AccountBill.FolderRSN
	AND AccountBillFee.BillNumber = AccountBill.BillNumber
	AND AccountBill.PaidInFullFlag <> 'C'
	AND AccountBillFee.FeeCode = 304 
	AND Folder.FolderRSN = @intFolderRSN

	IF @intStatusCode <> 10047   /* Project Phasing */
	BEGIN
		IF @intFCOFilingFeeExists > 0
		BEGIN
			SELECT @mnFCOFilingFee = SUM(AccountBillFee.FeeAmount) 
			FROM Folder, AccountBill, AccountBillFee
			WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
			AND Folder.FolderRSN = AccountBill.FolderRSN
			AND AccountBillFee.BillNumber = AccountBill.BillNumber
			AND AccountBill.PaidInFullFlag <> 'C'
			AND AccountBillFee.FeeCode = 304 
			AND Folder.FolderRSN = @intFolderRSN
		END
		ELSE
		BEGIN
			SELECT @mnFCOFilingFee = ValidLookup.LookupFee   /* One page */
			FROM ValidLookup 
			WHERE ValidLookup.LookupCode = 15
			AND ValidLookup.Lookup1 = 4
		END
	END
	ELSE   /* Project Phasing */
	BEGIN
		SELECT @intNumberofPhases = CAST(ROUND(ISNULL(FolderInfo.InfoValueNumeric, 0), 0) AS INT)
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10081

		SELECT @intPhaseAbandoned = dbo.udf_CountProcessAttemptResultSpecific(@intFolderRSN, 10030, 10067)
	
		SELECT @intNetPhases = @intNumberofPhases - @intPhaseAbandoned 
		IF @intNetPhases < 1 SELECT @intNetPhases = 1

		IF @intFCOFilingFeeExists < @intNetPhases 
		BEGIN
			SELECT @mnFCOFilingFee = ValidLookup.LookupFee   /* One page */
			FROM ValidLookup 
			WHERE ValidLookup.LookupCode = 15
			AND ValidLookup.Lookup1 = 4
		END
		ELSE 
		BEGIN
			SELECT @mnFCOFilingFee = SUM(AccountBillFee.FeeAmount) 
			FROM Folder, AccountBill, AccountBillFee
			WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
			AND Folder.FolderRSN = AccountBill.FolderRSN
			AND AccountBillFee.BillNumber = AccountBill.BillNumber
			AND AccountBill.PaidInFullFlag <> 'C'
			AND AccountBillFee.FeeCode = 304 
			AND Folder.FolderRSN = @intFolderRSN
		END
	END
	
	/* Filing Fee History:  Starting or after 7/1/1998 (FY99), the CO filing 
	   fee was charged at permit application ($7). Therefore the CO filing fee 
	   needs to paid for permits applied for prior to 7/1/1998.  
	   Then starting July 1, 2009 (FY10), the filing fee is no longer charged at 
	   zoning permit application, but at CO request. 
	   Project Phasing: If the permit applciation falls within the time when  
	   the filing fee was paid at application, there is no filing fee charge 
	   for the first phase CO only. */

	IF @varCOFlag = 'N' SELECT @mnFilingFee = 0
	ELSE
	BEGIN
		IF ( @dtInDate < '7/1/1998 00:00:00' OR @dtInDate > '7/1/2009 00:00:00' )
			SELECT  @mnFilingFee = @mnFCOFilingFee
		ELSE 
		BEGIN 
			IF @intStatusCode <> 10047 SELECT @mnFilingFee = 0 
			ELSE 
			BEGIN
				IF @intFCOFilingFeeExists = 0 SELECT @mnFilingFee = 0 
				ELSE SELECT @mnFilingFee = @mnFCOFilingFee
			END
		END
	END
	
	RETURN @mnFilingFee 
END
GO
