USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetInspectionRequestedForDate]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetInspectionRequestedForDate](@FolderRSN INT) RETURNS DATETIME 
AS
BEGIN
	DECLARE @dtmRetVal AS DATETIME

	SELECT @dtmRetVal = MAX(RequestedForDate) 
	FROM FolderInspectionRequest
	WHERE FolderRSN = @FolderRSN

	RETURN @dtmRetVal
END

GO
