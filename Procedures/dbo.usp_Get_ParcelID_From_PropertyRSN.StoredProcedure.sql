USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_ParcelID_From_PropertyRSN]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Get_ParcelID_From_PropertyRSN](@PropertyRSN INT, @ParcelID VARCHAR(13) OUTPUT)
AS
BEGIN
	SELECT @ParcelID = PropertyRoll
	FROM Property
	WHERE (PropertyRSN = @PropertyRSN)
END
GO
