USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastAttemptResult]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetLastAttemptResult](@FolderRSN INT) RETURNS DATETIME
AS
BEGIN

DECLARE @RetVal DATETIME


SELECT @RetVal = MAX(AttemptDate)
FROM  FolderProcessAttempt 
WHERE FolderRSN = @FolderRSN


RETURN @RetVal

END
GO
