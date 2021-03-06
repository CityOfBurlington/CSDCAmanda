USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_SearchStoredProcs]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SearchStoredProcs](@strSearchString VARCHAR(255))
AS
BEGIN


SELECT DISTINCT sysobjects.name AS [Object Name] ,
case when sysobjects.xtype = 'P' then 'Stored Proc'
when sysobjects.xtype = 'TF' then 'Function'
when sysobjects.xtype = 'FN' then 'Function'
when sysobjects.xtype = 'TR' then 'Trigger'
end as [Object Type]
FROM sysobjects,syscomments
WHERE sysobjects.id = syscomments.id
AND sysobjects.type IN('P','FN','TF','TR')
AND sysobjects.category = 0
AND CHARINDEX(@strSearchString, syscomments.text) > 0
/*AND ((CHARINDEX(@notcontain, syscomments.text)= 0 OR CHARINDEX(@notcontain,syscomments.text) <> 0)) */


END
GO
