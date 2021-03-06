USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionOverturnAttemptResult]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionOverturnAttemptResult](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
DECLARE @intDecisionProcessCode int
DECLARE @intDecisionAttemptResult int
DECLARE @intDecisionOverturnAttemptResult int 

SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intDecisionAttemptResult = dbo.udf_GetProcessAttemptCode(@intFolderRSN, @intDecisionProcessCode)

SELECT @intDecisionOverturnAttemptResult = 
CASE @intDecisionAttemptResult
   WHEN 10002 THEN 10003
   WHEN 10003 THEN 10002
   WHEN 10011 THEN 10002
   WHEN 10020 THEN 10003
   WHEN 10017 THEN 10018
   WHEN 10018 THEN 10017
   WHEN 10046 THEN 10047
   WHEN 10047 THEN 10046
   ELSE 0
END

RETURN @intDecisionOverturnAttemptResult
END
GO
