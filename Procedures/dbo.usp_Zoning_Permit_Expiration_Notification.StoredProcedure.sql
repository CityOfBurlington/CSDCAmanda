USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Permit_Expiration_Notification]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Permit_Expiration_Notification] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
	/* Inserts and codes Expiration Notification Generated Info field (10128). 
	   Used to document when letter is generated for tracking, and is called 
	   by the automated procedure that Selects permit folders that will expire 
	   in the next 29-62 days, and creates mailing letters as a pdf.*/

	DECLARE @intInfoCode int 
	DECLARE @intDisplayOrder int 
	DECLARE @int10128Count int
	DECLARE @intDecisionAttemptCode int
	
	SELECT @intInfoCode = 10128 
	SELECT @intDisplayOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, @intInfoCode) 
	SELECT @int10128Count = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10128)
	SELECT @intDecisionAttemptCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)  /* MAX(AttemptRSN) */

	IF dbo.udf_ZoningPermitExpirationDateFlag(@intFolderRSN) = 'Y' 
	BEGIN 
		IF @intDecisionAttemptCode IN (10003, 10011)   /* Approved */
		BEGIN
			IF @int10128Count > 0
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
				WHERE FolderInfo.FolderRSN = @intFolderRSN 
				AND FolderInfo.InfoCode = @intInfoCode
			END
			ELSE
			BEGIN
				INSERT INTO FolderInfo
				  ( FolderRSN, InfoCode, DisplayOrder, 
					PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
			VALUES (@intFolderRSN, @intInfoCode, @intDisplayOrder, 
					'Y', getdate(), @varUserID, 'N', 'N')
			END
		END
	END
END

GO
