USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Test_Stored_Procedure]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Test_Stored_Procedure] @FolderRSN INT
AS
BEGIN

	SELECT FolderName, FolderType
	FROM Folder
	WHERE FolderRSN = @FolderRSN

END


GO
