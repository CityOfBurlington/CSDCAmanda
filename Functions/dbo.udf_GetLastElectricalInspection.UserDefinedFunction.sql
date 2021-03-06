USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetLastElectricalInspection]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetLastElectricalInspection](@FolderRSN INT) RETURNS DATETIME AS
BEGIN
DECLARE @RetVal DATETIME

SELECT @RetVal = MAX(FolderProcessAttempt.AttemptDate)
FROM FolderProcessAttempt 
INNER JOIN FolderProcess ON FolderProcessAttempt.ProcessRSN = FolderProcess.ProcessRSN
WHERE FolderProcess.DisciplineCode = 75 /*Inspections*/
AND FolderProcessAttempt.FolderRSN = @FolderRSN

RETURN @RetVal

END

GO
