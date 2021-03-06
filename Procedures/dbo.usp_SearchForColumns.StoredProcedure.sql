USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_SearchForColumns]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SearchForColumns](@ColumnName AS VARCHAR(30))
AS
BEGIN

SELECT sysobjects.name AS TableName
FROM syscolumns 
INNER JOIN sysobjects ON syscolumns.id = sysobjects.id
WHERE syscolumns.name LIKE '%' + @ColumnName +'%'
AND sysobjects.type IN('U')
ORDER BY sysobjects.name
END

GO
