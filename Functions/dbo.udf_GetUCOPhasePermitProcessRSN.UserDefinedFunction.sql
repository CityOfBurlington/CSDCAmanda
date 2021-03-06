USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOPhasePermitProcessRSN]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOPhasePermitProcessRSN](@intPermitFolderRSN INT, @intUCOPhaseNumberValue INT) 
RETURNS INT
AS
BEGIN
	/* Returns the phasing zoning permit ProcessRSN of the Phased Certificate of Occupancy process 
	   for the phase the UCO applies to. Used in Permit STatus CHeck (23002) and Infomaker UCO forms. */

	DECLARE @intPCOProcessCount int
	DECLARE @intPCOProcessRSN int
	
	SET @intPCOProcessRSN = 0
	
	SELECT @intPCOProcessCount = COUNT(*)
	FROM FolderProcessInfo
	WHERE FolderProcessInfo.FolderRSN = @intPermitFolderRSN
	AND FolderProcessInfo.InfoCode = 10010 
	AND FolderProcessInfo.InfoValueNumeric = @intUCOPhaseNumberValue 

	IF @intPCOProcessCount > 0
	BEGIN
		SELECT @intPCOProcessRSN = ISNULL(FolderProcessInfo.ProcessRSN, 0)
		FROM FolderProcessInfo
		WHERE FolderProcessInfo.FolderRSN = @intPermitFolderRSN
		AND FolderProcessInfo.InfoCode = 10010 
		AND FolderProcessInfo.InfoValueNumeric = @intUCOPhaseNumberValue 
	END
	ELSE SELECT @intPCOProcessRSN = 0 

	RETURN @intPCOProcessRSN
END

GO
