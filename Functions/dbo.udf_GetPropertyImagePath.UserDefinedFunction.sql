USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetPropertyImagePath]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetPropertyImagePath](@pFolderRSN AS INT) RETURNS VARCHAR(400)
AS
BEGIN
	DECLARE @strRetVal VARCHAR(400)

	SELECT TOP 1 @strRetVal = ISNULL(Attachment.DosPath, '\\Patriot\C$\ActiveX\Amanda\Images\Workorder.jpg')
	FROM Attachment 
	INNER JOIN Folder ON Attachment.TableRSN = Folder.PropertyRSN 
	WHERE Attachment.TableName = 'Property' 
	AND Folder.FolderRSN = @pFolderRSN 

	RETURN @strRetVal
END
GO
