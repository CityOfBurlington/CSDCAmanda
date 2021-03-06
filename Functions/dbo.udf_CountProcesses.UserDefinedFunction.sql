USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CountProcesses]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_CountProcesses](@intFolderRSN INT, @intProcessCode INT)
RETURNS INT
AS
BEGIN
   DECLARE @AttemptCount int
   SET @AttemptCount = 0
   SELECT @AttemptCount = count(*)
     FROM FolderProcess
    WHERE FolderProcess.ProcessCode = @intProcessCode
      AND FolderProcess.FolderRSN = @intFolderRSN
RETURN @AttemptCount
END


GO
