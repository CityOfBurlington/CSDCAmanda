USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_UCOPhasingFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_UCOPhasingFlag](@intFolderRSN INT) 
RETURNS VARCHAR(2)
AS
BEGIN
   /* Returns 'Y' if any zoning permit in the UCO is for a phased project. 
      Separate building permits are issued for each phase, and so do not 
      need to be accounted for. */

	DECLARE @intCountInfoCodes int
	DECLARE @intCounter int
	DECLARE @intPermitFolderRSN int 
	DECLARE @intZPPhaseNumberInfoValue int
	DECLARE @varPhasingFlag varchar(2)
   
	SET @varPhasingFlag = 'N'

	SELECT @intCountInfoCodes = COUNT(*)
	FROM FolderInfo
	WHERE FolderInfo.InfoCode BETWEEN 23001 AND 23020
	AND FolderInfo.FolderRSN = @intFolderRSN

	SELECT @intCounter = 1

	WHILE @intCounter < ( @intCountInfoCodes + 1 ) 
	BEGIN
		SELECT @intPermitFolderRSN = FolderInfo.InfoValueNumeric
		FROM FolderInfo
		WHERE FolderInfo.InfoCode = ( 23000 + @intCounter )
		AND FolderInfo.FolderRSN = @intFolderRSN
       
		SELECT @intZPPhaseNumberInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0) 
		FROM FolderInfo
		WHERE FolderInfo.FolderRSN = @intPermitFolderRSN
		AND FolderInfo.InfoCode = 10081    /* Number of Phases */
		
		IF @intZPPhaseNumberInfoValue > 1 SELECT @varPhasingFlag = 'Y'

		SELECT @intCounter = @intCounter + 1

	END  /* End of InfoCode loop */

   RETURN @varPhasingFlag 
END

GO
