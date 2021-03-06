USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetApplicantName]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetApplicantName] (@FolderRSN INT) RETURNS VARCHAR(100)
AS 
BEGIN
	DECLARE @Applicant VARCHAR(100)

	SELECT TOP 1 @Applicant = People.OrganizationName
	FROM FolderPeople
	INNER JOIN People ON FolderPeople.PeopleRSN = People.PeopleRSN
	WHERE FolderRSN = @FolderRSN
	AND FolderPeople.PeopleCode = 1

	RETURN @Applicant
END 


GO
