USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNextProcessRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetNextProcessRSN]() 
RETURNS INT
AS
BEGIN
   DECLARE @intNextProcessRSN INT

   SELECT @intNextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
     FROM FolderProcess

   RETURN @intNextProcessRSN
END
GO
