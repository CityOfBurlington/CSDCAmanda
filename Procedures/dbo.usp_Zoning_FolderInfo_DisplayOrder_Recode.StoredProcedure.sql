USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_FolderInfo_DisplayOrder_Recode]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_FolderInfo_DisplayOrder_Recode] 
AS
BEGIN 
	UPDATE FolderInfo SET DisplayOrder = 248 WHERE InfoCode = 10024
	UPDATE FolderInfo SET DisplayOrder = 250 WHERE InfoCode = 10023
	UPDATE FolderInfo SET DisplayOrder = 252 WHERE InfoCode = 10027
	UPDATE FolderInfo SET DisplayOrder = 254 WHERE InfoCode = 10028
END

GO
