USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningTimeExtensionAppealExpiryDate]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningTimeExtensionAppealExpiryDate](@intFolderRSN int) 
RETURNS DATETIME 
AS 
BEGIN
   DECLARE @intProcessRSN int
   DECLARE @dtDate datetime 

   SELECT @intProcessRSN = MAX(FolderProcess.ProcessRSN) 
     FROM FolderProcess 
    WHERE FolderProcess.FolderRSN = @intFolderRSN 
      AND FolderProcess.ProcessCode = 10020     /* Extend Permit Expiration */

   SELECT @dtDate = FolderProcessInfo.InfoValueDateTime 
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN 
      AND FolderProcessInfo.InfoCode = 10009    /* Appeal Period Expiration Date */

   RETURN @dtDate
END

GO
