USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProcessRSN](@intFolderRSN INT, @intProcessCode INT)
RETURNS INT
AS
BEGIN
   DECLARE @intProcessRSN int 

   SELECT @intProcessRSN = ISNULL(FolderProcess.ProcessRSN, 0)
     FROM FolderProcess
    WHERE FolderProcess.FolderRSN = @intFolderRSN 
      AND FolderProcess.ProcessCode = @intProcessCode

   RETURN @intProcessRSN
END
GO
