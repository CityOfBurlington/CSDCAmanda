USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Permit_Expiration_Dates]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Permit_Expiration_Dates] (@intFolderRSN int, @dtDecisionDate datetime)
AS
BEGIN 
	/* Updates FolderInfo fields Permit Expiration Date (10024), and Construction Start Deadline (10127). */

	DECLARE @dtPermitExpiryDate datetime
	DECLARE @dtConstructionDeadline datetime
	DECLARE @intDecisionAttemptCode int
	DECLARE @int10024Count int
	DECLARE @int10127Count int

	SELECT @dtPermitExpiryDate = dbo.udf_ZoningPermitExpirationDate(@intFolderRSN, @dtDecisionDate)
	SELECT @dtConstructionDeadline = DATEADD(year, 1, @dtDecisionDate)     /* One year to start construction */
	SELECT @intDecisionAttemptCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)  /* MAX(AttemptRSN) */
	SELECT @int10024Count = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10024)
	SELECT @int10127Count = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10127)

	IF dbo.udf_ZoningPermitExpirationDateFlag(@intFolderRSN) = 'Y' 
	BEGIN
		IF @intDecisionAttemptCode IN (10003, 10011)   /* Approved */
		BEGIN
			IF @int10024Count > 0
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = CONVERT(CHAR(11), @dtPermitExpiryDate),
					FolderInfo.InfoValueDateTime = @dtPermitExpiryDate 
				WHERE FolderInfo.FolderRSN = @intFolderRSN 
				AND FolderInfo.InfoCode = 10024
			END
			IF @int10127Count > 0
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = CONVERT(CHAR(11), @dtConstructionDeadline), 
					FolderInfo.InfoValueDateTime = @dtConstructionDeadline 
				WHERE FolderInfo.FolderRSN = @intFolderRSN 
				AND FolderInfo.InfoCode = 10127
			END
		END
		IF @intDecisionAttemptCode IN (10002, 10020)   /* Denied */
		BEGIN
			IF @int10024Count > 0
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL,FolderInfo.InfoValueDateTime = NULL
				WHERE FolderInfo.FolderRSN = @intFolderRSN 
				AND FolderInfo.InfoCode = 10024
			END
			IF @int10127Count > 0
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL 
				WHERE FolderInfo.FolderRSN = @intFolderRSN 
				AND FolderInfo.InfoCode = 10127
			END
		END
	END
END


GO
