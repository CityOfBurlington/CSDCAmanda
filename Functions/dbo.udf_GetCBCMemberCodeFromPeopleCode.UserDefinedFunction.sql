USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCBCMemberCodeFromPeopleCode]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetCBCMemberCodeFromPeopleCode](@intPeopleCode int)
RETURNS INT
AS 
BEGIN
	/* For the CBC FolderType, maps FolderPeople.PeopleCode to PeopleGroup.MemberCode   
	   returning PeopleGroup.MemberCode.  JA 8/2013 */
	
	DECLARE @intMemberCode int
	
	SELECT @intMemberCode = 
	CASE @intPeopleCode
		WHEN 40001 THEN 40001		/* Chair */
		WHEN 40002 THEN 40002		/* Vice Chair */
		WHEN 40003 THEN 40003		/* Secretary */
		WHEN 40004 THEN 40004		/* Alternate */
		WHEN 40005 THEN 40005		/* Youth */
		WHEN 40006 THEN 40006		/* Member */
		WHEN 40007 THEN 40006		/* New Member becomes Member */
		WHEN 40008 THEN 40006		/* Reappointed becomes Member */
		WHEN 40009 THEN 99999		/* Retired becomes Error */
		WHEN 40010 THEN 99999		/* Resigned becomes Error */
		WHEN 40011 THEN 40006		/* Pending becomes Member */
		ELSE 99999					/* Unknown Error */
	END
	
	RETURN @intMemberCode
END
GO
