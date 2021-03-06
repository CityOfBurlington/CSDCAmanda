USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_FolderInfo_DRB_Setup]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_FolderInfo_DRB_Setup] (@intFolderRSN int, @varDRBReview varchar(3), @varUserID varchar(20))
AS
BEGIN 
	/* Sets up FolderInfo fields for DRB review for Primary decisions. 
	   @varDRBReview must be either Y (insert), or N (delete). 
	   Existing FolderInfo fields are nulled out if not null to insure 
	   an updated info is subsequently entered.  
	   Called by Review Path (10000) and Initate Appeal (10008). */

	DECLARE @varFolderType varchar(4)
	DECLARE @intFolderStatus int
	DECLARE @varPublicHearingRequired varchar(3)

	SELECT @varFolderType = Folder.FolderType, @intFolderStatus = Folder.StatusCode  
	FROM Folder
	WHERE Folder.FolderRSN = @intFolderRSN

	SELECT @varPublicHearingRequired = dbo.udf_ZoningPublicHearingFlag(@intFolderRSN)

	IF @varDRBReview = 'Y'
	BEGIN

		/* DRB Meeting Date */ 

		EXECUTE dbo.usp_Zoning_Insert_FolderInfo @intFolderRSN, 10001, @varUserID 

		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10001 
		AND FolderInfo.InfoValue IS NOT NULL

		/* 	DRB Public Hearing Closed Date */
	
		IF @varPublicHearingRequired = 'Y'
			EXECUTE dbo.usp_Zoning_Insert_FolderInfo @intFolderRSN, 10009, @varUserID

		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10009 
		AND FolderInfo.InfoValue IS NOT NULL

		/* 	DRB Deliberative Meeting Date */

		EXECUTE dbo.usp_Zoning_Insert_FolderInfo @intFolderRSN, 10017, @varUserID

		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10017 
		AND FolderInfo.InfoValue IS NOT NULL

		/* 	DRB Deliberative Decision  - not added for DRB appeals. */

		IF ( @varPublicHearingRequired = 'Y' AND @intFolderStatus <> 10009 ) 
			EXECUTE dbo.usp_Zoning_Insert_FolderInfo @intFolderRSN, 10036, @varUserID

		UPDATE FolderInfo
		SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10036 
		AND FolderInfo.InfoValue IS NOT NULL

		/* DRB Decision Date */

		IF ( @varFolderType <> 'ZL' AND @intFolderStatus <> 10009 )
		BEGIN
			EXECUTE dbo.usp_Zoning_Insert_FolderInfo @intFolderRSN, 10049, @varUserID

			UPDATE FolderInfo
			SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
			WHERE FolderInfo.FolderRSN = @intFolderRSN
			AND FolderInfo.InfoCode = 10049 
			AND FolderInfo.InfoValue IS NOT NULL 
		END

		/* 	DRB Appeal Decision Date */

		IF ( @varFolderType = 'ZL' OR @intFolderStatus = 10009 ) 
		BEGIN
			EXECUTE dbo.usp_Zoning_Insert_FolderInfo @intFolderRSN, 10056, @varUserID

			UPDATE FolderInfo
			SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
			WHERE FolderInfo.FolderRSN = @intFolderRSN
			AND FolderInfo.InfoCode = 10056 
			AND FolderInfo.InfoValue IS NOT NULL 
		END

	END  /* End of @varDRBReview = 'Y' */

	IF @varDRBReview = 'N'
	BEGIN

		DELETE FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10001
		AND FolderInfo.InfoValue IS NULL

		DELETE FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10009
		AND FolderInfo.InfoValue IS NULL

		DELETE FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10017
		AND FolderInfo.InfoValue IS NULL

		DELETE FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10036
		AND FolderInfo.InfoValue IS NULL

		DELETE FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10049
		AND FolderInfo.InfoValue IS NULL

		DELETE FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intFolderRSN
		AND FolderInfo.InfoCode = 10056
		AND FolderInfo.InfoValue IS NULL

	END  /* End of @varDRBReview = 'N' */

END


 /* Old code... 

	DECLARE @intDRBMeetingOrder int
	DECLARE @intDRBMeetingInfoFieldCount int
	DECLARE @dtDRBMeetingInfoValue datetime 

	DECLARE @intDRBPHClosedOrder int
	DECLARE @intDRBPHClosedInfoFieldCount int
	DECLARE @dtDRBPHClosedInfoValue datetime

	DECLARE @intDRBDelibMeetingOrder int
	DECLARE @intDRBDelibMeetingInfoFieldCount int
	DECLARE @dtDRBDelibMeetingInfoValue datetime

	DECLARE @intDRBDelibDecOrder int
	DECLARE @intDRBDelibDecInfoFieldCount int
	DECLARE @varDRBDelibDecInfoValue varchar(30)

	DECLARE @intDRBDecDateOrder int
	DECLARE @intDRBDecDateInfoFieldCount int
	DECLARE @dtDRBDecDateInfoValue datetime

	DECLARE @intDRBAppealDecDateOrder int
	DECLARE @intDRBAppealDecDateInfoFieldCount int
	DECLARE @dtDRBAppealDecDateInfoValue datetime 

	SELECT @intDRBMeetingOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10001)
	SELECT @intDRBMeetingInfoFieldCount = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10001) 
	SELECT @dtDRBMeetingInfoValue = dbo.f_info_date(@intFolderRSN, 10001) 

	SELECT @intDRBPHClosedOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10009)
	SELECT @intDRBPHClosedInfoFieldCount = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10009) 
	SELECT @dtDRBPHClosedInfoValue = dbo.f_info_date(@intFolderRSN, 10009)

	SELECT @intDRBDelibMeetingOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10017)
	SELECT @intDRBDelibMeetingInfoFieldCount = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10017)
	SELECT @dtDRBDelibMeetingInfoValue = dbo.f_info_date(@intFolderRSN, 10017)

	SELECT @intDRBDelibDecOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10036)
	SELECT @intDRBDelibDecInfoFieldCount = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10036)
	SELECT @varDRBDelibDecInfoValue = dbo.f_info_alpha_null(@intFolderRSN, 10036)

	SELECT @intDRBDecDateOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10049) 
	SELECT @intDRBDecDateInfoFieldCount = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10049)
	SELECT @dtDRBDecDateInfoValue = dbo.f_info_date(@intFolderRSN, 10049)

	SELECT @intDRBAppealDecDateOrder = dbo.udf_GetZoningFolderInfoDisplayOrder(@intFolderRSN, 10056)
	SELECT @intDRBAppealDecDateInfoFieldCount = dbo.udf_FolderInfoFieldExists(@intFolderRSN, 10056)
	SELECT @dtDRBAppealDecDateInfoValue = dbo.f_info_date(@intFolderRSN, 10056)

	IF @varDRBReview = 'Y'
	BEGIN
		IF @intDRBMeetingInfoFieldCount = 0
		BEGIN
			INSERT INTO FolderInfo
				( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
			VALUES ( @intFolderRSN, 10001,  @intDRBMeetingOrder, 'Y', getdate(), @varUserID, 'N', 'N' )
		END 
		ELSE 
		IF @dtDRBMeetingInfoValue IS NOT NULL
		BEGIN
			UPDATE FolderInfo
			SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
			WHERE FolderInfo.FolderRSN = @intFolderRSN
			AND FolderInfo.InfoCode = 10001 
		END 

		IF @varPublicHearingRequired = 'Y'
		BEGIN
			IF @intDRBPHClosedInfoFieldCount = 0 
			BEGIN
				INSERT INTO FolderInfo
					( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
				VALUES ( @intFolderRSN, 10009,  @intDRBPHClosedOrder, 'Y', getdate(), @varUserID, 'N', 'N' )
			END
			ELSE
			IF @dtDRBPHClosedInfoValue IS NOT NULL
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
				WHERE FolderInfo.FolderRSN = @intFolderRSN
				AND FolderInfo.InfoCode = 10009 
			END
		END 

		IF @intDRBDelibMeetingInfoFieldCount = 0
		BEGIN
			INSERT INTO FolderInfo
				( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
			VALUES ( @intFolderRSN, 10017,  @intDRBDelibMeetingOrder, 'Y', getdate(), @varUserID, 'N', 'N' )
		END
		ELSE
		IF @dtDRBDelibMeetingInfoValue IS NOT NULL
		BEGIN
			UPDATE FolderInfo
			SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
			WHERE FolderInfo.FolderRSN = @intFolderRSN
			AND FolderInfo.InfoCode = 10017 
		END 

		IF @varPublicHearingRequired = 'Y'
		BEGIN
			IF @intDRBDelibDecInfoFieldCount = 0 
			BEGIN
				INSERT INTO FolderInfo
					( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
				VALUES ( @intFolderRSN, 10036,  @intDRBDelibDecOrder, 'Y', getdate(), @varUserID, 'N', 'N' )
			END
			ELSE
			IF @varDRBDelibDecInfoValue IS NOT NULL
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
				WHERE FolderInfo.FolderRSN = @intFolderRSN
				AND FolderInfo.InfoCode = 10036 
			END
		END 

		IF @varFolderType <> 'ZL' 
		BEGIN
			IF @intDRBDecDateInfoFieldCount = 0 
			BEGIN
				INSERT INTO FolderInfo
				( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
				VALUES ( @intFolderRSN, 10049,  @intDRBDecDateOrder, 'Y', getdate(), @varUserID, 'N', 'N' )
			END
			ELSE
			IF @dtDRBDecDateInfoValue IS NOT NULL
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
				WHERE FolderInfo.FolderRSN = @intFolderRSN
				AND FolderInfo.InfoCode = 10049 
			END
		END 

		IF @varFolderType = 'ZL' 
		BEGIN
			IF @intDRBAppealDecDateInfoFieldCount = 0 
			BEGIN  
				INSERT INTO FolderInfo
					( FolderRSN, InfoCode, DisplayOrder, PrintFlag, StampDate, StampUser, Mandatory, ValueRequired )
				VALUES ( @intFolderRSN, 10056,  @intDRBAppealDecDateOrder, 'Y', getdate(), @varUserID, 'N', 'N' )
			END
			ELSE
			IF @dtDRBAppealDecDateInfoValue IS NOT NULL
			BEGIN
				UPDATE FolderInfo
				SET FolderInfo.InfoValue = NULL, FolderInfo.InfoValueDateTime = NULL
				WHERE FolderInfo.FolderRSN = @intFolderRSN
				AND FolderInfo.InfoCode = 10056 
			END
		END 
*/

GO
