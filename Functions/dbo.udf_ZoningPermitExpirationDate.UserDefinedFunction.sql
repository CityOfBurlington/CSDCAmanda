USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZoningPermitExpirationDate]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZoningPermitExpirationDate] (@intFolderRSN int, @dtDecisionDate datetime) 
RETURNS datetime
AS
BEGIN
	DECLARE @intParentRSN int
	DECLARE @varFolderType varchar(4)
	DECLARE @intSubCode int
	DECLARE @intWorkCode int 
	DECLARE @varLevel3Project varchar(30)
	DECLARE @varViolationFlag varchar(3)
	DECLARE @intYearIncrement int
	DECLARE @dtExpiryDate datetime

	SELECT @varFolderType = Folder.FolderType,
		   @intSubCode = Folder.SubCode, @intWorkCode = Folder.WorkCode
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SET @varViolationFlag = 'NO'
	SELECT @varViolationFlag = ISNULL(FolderInfo.InfoValueUpper, 'NO')
	FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
	AND FolderInfo.InfoCode = 10043

	SELECT @varLevel3Project = ISNULL(FolderInfo.InfoValueUpper, '?')
	FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN 
	AND FolderInfo.InfoCode = 10015

/* Set permit expiration date to: 
	5 years - Parking and Tree Maintenance Master Plans (ZP folder)
	2 years - Basic, COA 1 and 2,  Conditional Use, Home Occupation, Major Impact Review
	1 year  - COA Level 3 - Preliminary Plat
	180 days - COA Level 3 - Final and Prelim/Final Combo Plat (Plat must be filed 
		in the Land Records within 180 days of the decision)
	0 years - Code Enforcement Appeals, Determinations, Variances, Nonapplicabilities, 
		misc Zoning Appeals, Sign Master Plans. 

	Sec. 3.2.9(d) specifies 2 years to complete the project (and get a CO) for all permits, 
	except Prelim and Final Plats (see sec. 10.1.8(g) and 10.1.11(b). Major Impact and 
	some Home Occupations are a form of conditional use review.  A time limit on a variance 
	may or may not be imposed (sec. 12.1.3) - implemented as imposed.  
	Appeals and Determinations are not defined as permits.  

	Sec. 3.2.9(e) stipulates that permits which arise from a zoning violation shall 
	be completed in one (1) year. Master Plans do not arise from violations so not 
	applicable to ZP folders. 

	Whether or not this function is called is controlled by 
	dbo.udf_ZoningPermitExpirationFlag, which returns Y/N. */

	IF @intSubCode IN(10041, 10042)
	BEGIN
		IF @varViolationFlag = 'YES' SELECT @intYearIncrement = 1
		ELSE SELECT @intYearIncrement = 2

		IF @varFolderType IN('ZA', 'ZB', 'ZC', 'ZF', 'ZH', 'Z1', 'Z2') 
			SELECT @dtExpiryDate = DATEADD(year, @intYearIncrement, @dtDecisionDate)

		IF @varFolderType = 'Z3'
		BEGIN
			IF @varLevel3Project = 'PLANNED UNIT DEVELOPMENT'
				SELECT @dtExpiryDate = DATEADD(year, @intYearIncrement, @dtDecisionDate)
			ELSE
			BEGIN
				IF @intWorkCode = 10009      /* Preliminary Plat */
					SELECT @dtExpiryDate = DATEADD(year, 1, @dtDecisionDate)
				IF @intWorkCode IN(10010, 10011)    /* Final, and Preliminary and Final Combo Plat */
					SELECT @dtExpiryDate = DATEADD(day, 180, @dtDecisionDate)
			END
		END

		IF @varFolderType = 'ZP' AND @intWorkCode IN (10006, 10008)
			SELECT @dtExpiryDate = DATEADD(year, 5, @dtDecisionDate)
	END

	RETURN @dtExpiryDate
END


GO
