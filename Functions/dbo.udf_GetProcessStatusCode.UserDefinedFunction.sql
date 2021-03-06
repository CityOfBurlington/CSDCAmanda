USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessStatusCode]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProcessStatusCode](@intFolderRSN INT, @intProcessCode INT) 
RETURNS int
AS
BEGIN 
   /* Returns the StatusCode for the last ProcessCode when multiple processes exist */

   DECLARE @intStatusCode int

   SELECT @intStatusCode = FolderProcess.StatusCode 
     FROM FolderProcess
    WHERE FolderProcess.ProcessRSN = 
          ( SELECT MAX(FolderProcess.ProcessRSN)
              FROM FolderProcess
             WHERE FolderProcess.FolderRSN = @intFolderRSN
               AND FolderProcess.ProcessCode = @intProcessCode )

	RETURN @intStatusCode
END
GO
