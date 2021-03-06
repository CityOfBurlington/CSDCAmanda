USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetAssessProPropertyValue]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetAssessProPropertyValue](@PropertyRSN int) 
	RETURNS INT
AS
BEGIN

	DECLARE @ParcelID VARCHAR(13)
	DECLARE @APAcctNum INT
	DECLARE @PropValue INT
	DECLARE @intRetVal INT

	SELECT @ParcelID = PropertyRoll FROM Property WHERE PropertyRSN = @PropertyRSN
	SELECT @APAcctNum = AccountNumber FROM Cobdb.AssessPro.dbo.DataProperty WHERE ParcelID = @ParcelID
	SELECT @PropValue = Total FROM Cobdb.AssessPro.dbo.DataPreasses WHERE AccountNumber = @APAcctNum
	
	SET @intRetVal = @PropValue

	RETURN @intRetVal
	
END



GO
