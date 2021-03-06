USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetNewPeople]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_GetNewPeople](@dtmStartDate DateTime, @dtmEndDate DateTime)
AS 
SELECT 'New' AS Status, IsNull(P.NameFirst, ' ') AS NameFirst, IsNull(P.NameLast, ' ') AS NameLast, 
	IsNull(P.OrganizationName, ' ') AS OrganizationName, P.PeopleRSN, P.StampDate, P.StampUser, U.UserName, D.DepartmentDesc
FROM People P
LEFT OUTER JOIN ValidUser U ON P.StampUser = U.UserID
LEFT OUTER JOIN ValidDepartment D ON U.DepartmentCode = D.DepartmentCode
WHERE P.StampDate BETWEEN @dtmStartDate AND @dtmEndDate
UNION
SELECT 'Existing' AS Status, IsNull(P.NameFirst, ' ') AS NameFirst, IsNull(P.NameLast, ' ') AS NameLast, 
	IsNull(P.OrganizationName, ' ') AS OrganizationName, P.PeopleRSN, P.StampDate, P.StampUser, U.UserName, D.DepartmentDesc
FROM People P
LEFT OUTER JOIN ValidUser U ON P.StampUser = U.UserID
LEFT OUTER JOIN ValidDepartment D ON U.DepartmentCode = D.DepartmentCode
WHERE stampdate < @dtmStartDate
AND (NameFirst + NameLast IN(SELECT NameFirst + NameLast FROM PEOPLE WHERE StampDate BETWEEN @dtmStartDate AND @dtmEndDate))
ORDER BY NameLast ASC, 
	NameFirst ASC, 
	Status Desc


GO
