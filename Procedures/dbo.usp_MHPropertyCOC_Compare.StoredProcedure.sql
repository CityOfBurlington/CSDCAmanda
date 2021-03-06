USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_MHPropertyCOC_Compare]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_MHPropertyCOC_Compare](@Year1 VARCHAR(2), @Year2 VARCHAR(2)) 
AS
BEGIN
/*

*/
SELECT COC.*,
dbo.udf_GetMHPropertyFolderStatus(PropertyRSN, @Year1) AS FolderStatus1,
dbo.udf_GetMHPropertyFolderWorkDesc(PropertyRSN, @Year1) AS FolderWork1,
dbo.udf_GetMHPropertyFolderSubDesc(PropertyRSN, @Year1) AS FolderSub1,
dbo.udf_GetMHPropertyFolderStatus(PropertyRSN, @Year2) AS FolderStatus2,
dbo.udf_GetMHPropertyFolderWorkDesc(PropertyRSN, @Year2) AS FolderWork2,
dbo.udf_GetMHPropertyFolderSubDesc(PropertyRSN, @Year2) AS FolderSub2
FROM uvw_PropertyByCOCExpiration COC 

END
GO
