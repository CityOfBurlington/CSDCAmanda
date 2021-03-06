USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionProcessRSN]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionProcessRSN](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
DECLARE @intDecisionProcessCode int
DECLARE @intDecisionProcessRSN int 

SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intDecisionProcessRSN = FolderProcess.ProcessRSN 
     FROM FolderProcess
    WHERE FolderProcess.FolderRSN = @intFolderRSN 
      AND FolderProcess.ProcessCode = @intDecisionProcessCode

RETURN ISNULL(@intDecisionProcessRSN, 0)
END
GO
