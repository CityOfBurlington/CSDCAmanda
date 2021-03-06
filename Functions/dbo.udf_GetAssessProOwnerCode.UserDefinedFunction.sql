USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetAssessProOwnerCode]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_GetAssessProOwnerCode](@PeopleRSN int) 
	RETURNS INT
AS
BEGIN
	DECLARE @intRetVal INT

	SET @intRetVal = NULL
	IF EXISTS (SELECT InfoValueNumeric FROM PeopleInfo WHERE PeopleRSN = @PeopleRSN AND InfoCode = 10)
	BEGIN 
		SELECT @intRetVal = InfoValueNumeric FROM PeopleInfo WHERE PeopleRSN = @PeopleRSN AND InfoCode = 10
	END

	RETURN @intRetVal

END



GO
