USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNextFolderProcessRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[udf_GetNextFolderProcessRSN]() RETURNS INT
AS
BEGIN
DECLARE @intRetVal INT
SELECT @intRetVal = MAX(ProcessRSN + 1)
FROM FolderProcess
RETURN @intRetVal
END



GO
