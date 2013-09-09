USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNextDocumentRSN]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetNextDocumentRSN]() RETURNS INT
AS
BEGIN
DECLARE @intRetVal INT

SELECT @intRetVal = MAX(DocumentRSN) FROM FolderDocument

SET @intRetVal = @intRetVal + 1

RETURN @intRetVal
END
GO
