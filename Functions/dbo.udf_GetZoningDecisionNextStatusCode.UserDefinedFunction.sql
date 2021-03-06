USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionNextStatusCode]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionNextStatusCode](@intFolderRSN INT, @intAttemptResultCode INT)
RETURNS INT
AS
BEGIN
/* Passes next Folder.StatusCode for various zoning decision attempt results. 
   Appeal to DRB attempt result statuses are based upon the decision that 
   was appealed, and so are not accounted for here. */

	DECLARE @intNextStatusCode int
	DECLARE @intPreReleaseConditions int

	SELECT @intPreReleaseConditions = ISNULL(dbo.udf_GetProcessAttemptCode(@intFolderRSN, 10006), 0)

	SELECT @intNextStatusCode = 
	CASE @intAttemptResultCode
		WHEN 10002 THEN 10003   /* Project Decision (10005) - Denied */
		WHEN 10003 THEN 10002   /* Project Decision (10005) - Approved */
		WHEN 10008 THEN 10003   /* Appeal to VEC (10003) - VSCED Denied Permit */
		WHEN 10009 THEN 10002   /* Appeal to VEC (10003) - VSCED Approved Permit */
		WHEN 10010 THEN 10002   /* Appeal to VEC (10003) - VSCED Modified Permit */
		WHEN 10020 THEN 10016   /* Project Decision (10005) - Denied w/out Prejudice */
		WHEN 10017 THEN 10002   /* Nonapplicability Request (10010) - Permit Not Required */
		WHEN 10018 THEN 10003   /* Nonapplicability Request (10010)  - Permit Required */
		WHEN 10030 THEN 10016   /* Appeal to VEC (10003) - VSCED Denied w/out Prejudice Permit */
		WHEN 10046 THEN 10027   /* Determination Decision (10016) - Affirmative */
		WHEN 10047 THEN 10027   /* Determination Decision (10016) - Adverse */
		WHEN 10048 THEN 10056   /* Appeal to VEC (10003) - VSCED Remanded Back to City */
		WHEN 10052 THEN 10003   /* Appeal to VEC (10003) - VSCED Dismisses the appeal */
		WHEN 10053 THEN 10002   /* Appeal to VEC (10003)  - Stipulation Agreement Reached */
		WHEN 10054 THEN 10003   /* Appeal to VEC (10003) - VSCED Upheld Misc Admin Decision */
		WHEN 10055 THEN 10002   /* Appeal to VEC (10003) - VSCED Overturned Misc Admin Decision */
		WHEN 10056 THEN 10002   /* Appeal to VEC (10003) - ZN Permit Not Required */
		WHEN 10057 THEN 10003   /* Appeal to VEC (10003) - 	ZN Permit Required */
		WHEN 10060 THEN 10044   /* Extend Permit Expiration (10020) - Grant Extension */
		WHEN 10061 THEN 10045   /* Extend Permit Expiration (10020) - Deny Extension */
		ELSE 10099
	END

	IF @intAttemptResultCode = 10011   /* Approved w/ Pre-Release Conditions */
	BEGIN
		IF @intPreReleaseConditions = 0 SELECT @intNextStatusCode = 10004
		ELSE SELECT @intNextStatusCode = 10002
	END

	RETURN @intNextStatusCode
END


GO
