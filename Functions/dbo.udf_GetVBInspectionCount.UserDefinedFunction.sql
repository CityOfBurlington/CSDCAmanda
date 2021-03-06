USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetVBInspectionCount]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetVBInspectionCount](@FolderRSN INT) RETURNS INT
AS
BEGIN

/* Count the inspection attempts for the VB folder. Attempt ResultCode for VB inspections is 25070 (Inspection Scheduled)
*/
DECLARE @intRetVal INT

	SELECT @intRetVal = Count(*) FROM FolderProcessAttempt 
		WHERE FolderRSN = @FolderRSN
		AND ResultCode = 25070

RETURN @intRetVal

END


GO
