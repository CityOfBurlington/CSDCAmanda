USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_SearchViews]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SearchViews](@strSearchString VARCHAR(255))
AS
BEGIN

SELECT DISTINCT sysobjects.name AS [Object Name] 
FROM sysobjects,syscomments
WHERE sysobjects.id = syscomments.id
AND sysobjects.type = 'V'
AND sysobjects.category = 0
AND CHARINDEX(@strSearchString, syscomments.text) > 0
/*AND ((CHARINDEX(@notcontain, syscomments.text)= 0 OR CHARINDEX(@notcontain,syscomments.text) <> 0)) */


END
GO
