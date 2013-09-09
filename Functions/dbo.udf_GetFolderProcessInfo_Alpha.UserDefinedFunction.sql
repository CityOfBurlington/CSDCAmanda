USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderProcessInfo_Alpha]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderProcessInfo_Alpha](@intProcessRSN INT, @intInfoCode INT) 
RETURNS varchar(2000) 
AS 
BEGIN
   DECLARE @varString varchar(2000)

   SELECT @varString = FolderProcessInfo.InfoValue 
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN 
      AND FolderProcessInfo.InfoCode = @intInfoCode 

   RETURN @varString
END

GO
