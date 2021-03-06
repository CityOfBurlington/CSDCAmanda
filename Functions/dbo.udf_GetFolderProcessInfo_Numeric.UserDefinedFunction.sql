USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetFolderProcessInfo_Numeric]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetFolderProcessInfo_Numeric](@intProcessRSN INT, @intInfoCode INT) 
RETURNS REAL 
AS 
BEGIN
   DECLARE @realNumber real 

   SELECT @realNumber = FolderProcessInfo.InfoValueNumeric 
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN 
      AND FolderProcessInfo.InfoCode = @intInfoCode 

   RETURN @realNumber
END
GO
