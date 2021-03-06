USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCBCPeopleCodeFromMemberCode]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetCBCPeopleCodeFromMemberCode](@intMemberCode INT)
RETURNS INT
AS 
BEGIN
	/* For the CBC FolderType, maps PeopleGroup.MemberCode to FolderPeople.PeopleCode 
	   returning FolderPeople.PeopleCode.  JA 8/2013 */

	DECLARE @intPeopleCode int
		
	SELECT @intPeopleCode = 
	CASE @intMemberCode				/* ValidPeopleMember.MemberDesc */
		WHEN 40001 THEN 40001		/* Chair */
		WHEN 40002 THEN 40002		/* Vice Chair */
		WHEN 40003 THEN 40003		/* Secretary */
		WHEN 40004 THEN 40004		/* Alternate */
		WHEN 40005 THEN 40005		/* Youth */
		WHEN 40006 THEN 40006		/* Member */
		WHEN 40007 THEN 40006		/* Trustee becomes Member*/
		WHEN 40008 THEN 40006		/* Employee Libary becomes Member */
		WHEN 40009 THEN 40006		/* Employee Class A becomes Member */
		WHEN 40010 THEN 40006		/* Employee Class B becomes Member */
		WHEN 40011 THEN 40006		/* Pending becomes Member */
		WHEN 40012 THEN 40006		/* South Burlington City Council becomes Member */
		ELSE 999					/* Unknown Error */
	END
	
	RETURN @intPeopleCode
END
GO
