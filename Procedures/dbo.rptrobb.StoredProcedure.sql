USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[rptrobb]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.rptrobb    Script Date: 11/10/00 10:24:19 AM ******/
CREATE  PROCEDURE [dbo].[rptrobb] @to_date datetime, @FROM_date datetime

AS 

SELECT ValidFolder.FolderDesc, count (FolderRSN) foldercount
FROM Folder, ValidFolder
Where (ValidFolder.FolderType = Folder.FolderType) AND
(Folder.InDate between @FROM_date AND @to_date)
group by ValidFolder.FolderDesc


GO
