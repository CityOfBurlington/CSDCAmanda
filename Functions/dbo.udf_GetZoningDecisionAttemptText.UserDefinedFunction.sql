USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionAttemptText]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionAttemptText](@intFolderRSN INT, @intAttemptResult INT)
RETURNS VARCHAR(50)
AS
BEGIN
DECLARE @varFolderType varchar(4)
DECLARE @intWorkCode int
DECLARE @varDecisionAttemptText varchar(100)

SELECT @varFolderType = Folder.FolderType, 
       @intWorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @intFolderRSN

IF @varFolderType = 'ZL'
BEGIN
   SELECT @varDecisionAttemptText = 
   CASE @intWorkCode
      WHEN 10004 THEN 'Notice of Violation'
      WHEN 10005 THEN 'Misc Zoning Administrative Decision'
      ELSE 'Unknown Decision' 
   END
END
ELSE
BEGIN 
   SELECT @varDecisionAttemptText = 
   CASE @intAttemptResult
      WHEN 10002 THEN 'Denial'
      WHEN 10003 THEN 'Approval'
      WHEN 10011 THEN 'Approval w/ Pre-Release Conditions'
      WHEN 10020 THEN 'Denial w/o Prejudice'
      WHEN 10017 THEN 'Determination that Permit Not Required'
      WHEN 10018 THEN 'Determination that Permit Is Required'
      WHEN 10046 THEN 'Affirmative Determination Finding'
      WHEN 10047 THEN 'Adverse Determination Finding'
      ELSE 'Unknown Decision' 
   END
END
RETURN @varDecisionAttemptText
END

GO
