USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionOverturnAttemptText]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionOverturnAttemptText](@intFolderRSN INT)
RETURNS VARCHAR(50)
AS
BEGIN
DECLARE @intDecisionProcessCode int
DECLARE @intDecisionAttemptResult int
DECLARE @varDecisionOverturnAttemptText varchar(50)

SELECT @intDecisionProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intDecisionAttemptResult = dbo.udf_GetProcessAttemptCode(@intFolderRSN, @intDecisionProcessCode)

SELECT @varDecisionOverturnAttemptText = 
CASE @intDecisionAttemptResult
   WHEN 10002 THEN 'Approved upon Appeal'
   WHEN 10003 THEN 'Denied upon Appeal'
   WHEN 10011 THEN 'Denied upon Appeal'
   WHEN 10020 THEN 'Approved upon Appeal'
   WHEN 10017 THEN 'Permit Required upon Appeal'
   WHEN 10018 THEN 'Permit Not Required upon Appeal'
   WHEN 10046 THEN 'Determination Adverse upon Appeal'
   WHEN 10047 THEN 'Determination Affirmative upon Appeal'
   ELSE 'Unknown Attempt Result'
END

RETURN @varDecisionOverturnAttemptText
END

GO
