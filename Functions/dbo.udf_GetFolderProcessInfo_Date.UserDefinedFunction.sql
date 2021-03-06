USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderProcessInfo_Date]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderProcessInfo_Date](@intProcessRSN INT, @intInfoCode INT) 
RETURNS DATETIME 
AS 
BEGIN
   DECLARE @dtDate datetime

   SELECT @dtDate = FolderProcessInfo.InfoValueDateTime 
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN 
      AND FolderProcessInfo.InfoCode = @intInfoCode 

   RETURN @dtDate
END

GO
