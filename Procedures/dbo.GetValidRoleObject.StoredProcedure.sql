USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetValidRoleObject]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[GetValidRoleObject] (@RoleType VARCHAR(200))
AS
BEGIN
	/*
	Name of Person: ESS
	Date : March 28 2006
	Version: 4.4.6

 	Procedure GetValidRoleObject is used in AMANDAi for Getting the Level of Permission for different user object 
			(User table, Function and Stored Procedure).	
			This SP will get a parameter Role Type which should be a valid role in the ValidRole table.
			For that role SP will return the different Level of Permission.

			In MSSQL 	Action  = 193 -> Select
							 	Execute = 224 -> Execute or Select permission in Oracle
							  Insert  = 195 -> Insert
								Update  = 197 -> Update
								Delete  = 196 -> Delete
	*/
	CREATE TABLE #temp1(RoleType VARCHAR(200),ObjectName VARCHAR(255),ObjectType CHAR(1), action INT)
	INSERT INTO #temp1
	SELECT user_name(p.uid), SYSOBJECTS.name,
	CASE SYSOBJECTS.xtype 
		WHEN 'U' THEN	'T' ---As in SQL Server User Table display as 'U'
		WHEN 'F' THEN 'F'
		WHEN 'P' THEN 'P'
	END ,action 
	FROM SYSPROTECTS p, SYSOBJECTS
	WHERE SYSOBJECTS.id = p.id
	AND p.uid IN (SELECT DISTINCT user_id(@RoleType) FROM ValidUser)
	AND p.action IN (193, 195, 196, 197, 224)
	AND SYSOBJECTS.xtype IN('U','F','P')

	SELECT ObjectName,ObjectType ,
	(SELECT 'Y' FROM #temp1 t193 WHERE (t193.action = 193 OR  t193.action = 224)AND t193.ObjectName = t.ObjectName 
	  AND t193.ObjectType = t.ObjectType)																SelectAccess,
	(SELECT 'Y' FROM #temp1 t195 WHERE t195.action = 195 AND t195.ObjectName = t.ObjectName 
		AND t195.ObjectType = t.ObjectType) 														InsertAccess,
	(SELECT 'Y' FROM #temp1 t197 WHERE t197.action = 197 AND t197.ObjectName = t.ObjectName 
		AND t197.ObjectType = t.ObjectType) 														UpdateAccess,
	(SELECT 'Y' FROM #temp1 t196 WHERE t196.action = 196 AND t196.ObjectName = t.ObjectName 
		AND t196.ObjectType = t.ObjectType) 														DeleteAccess


	FROM #temp1 t
	GROUP BY ObjectName,ObjectType

END



GO
