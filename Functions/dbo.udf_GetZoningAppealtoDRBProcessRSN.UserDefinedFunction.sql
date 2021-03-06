USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAppealtoDRBProcessRSN]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAppealtoDRBProcessRSN](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
   DECLARE @intAppealProcessCode int 
   DECLARE @intAppealProcessRSN int 

   SELECT @intAppealProcessCode = 10002   /* Appeal to DRB */

   SELECT @intAppealProcessRSN = FolderProcess.ProcessRSN
     FROM FolderProcess 
    WHERE FolderProcess.FolderRSN = @intFolderRSN  
      AND FolderProcess.ProcessCode = @intAppealProcessCode 

   RETURN ISNULL(@intAppealProcessRSN, 0)
END

GO
