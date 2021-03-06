USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetImagePath]    Script Date: 9/9/2013 9:43:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetImagePath](@PropertyRSN INT) RETURNS VARCHAR(200)
AS

BEGIN

	DECLARE @ParcelID VARCHAR(30)
	DECLARE @ImagePath VARCHAR(200)

	SELECT DISTINCT @ParcelID = RTRIM(LTRIM(PropertyRoll))
	FROM Property
	WHERE PropertyRSN = @PropertyRSN

	SELECT DISTINCT @ImagePath = Image
	FROM AssessPro.dbo.DataProperty
	WHERE ParcelID = @ParcelID

	RETURN ISNULL('E:\AssessPro\Image' + @ImagePath, 'E:\AssessPro\Image\0\0.jpg')
END



GO
