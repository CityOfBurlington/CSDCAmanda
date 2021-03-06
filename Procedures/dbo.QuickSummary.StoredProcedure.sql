USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[QuickSummary]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[QuickSummary] (@intFolderRSN int)
AS
BEGIN 
	/* Provides a quick summary view of a Folder. Intended for interactive use. JA 4/2013 */

	SELECT Folder.FolderRSN AS FolderRSN, 
		Folder.FolderType AS FolderType, 
		Folder.ReferenceFile AS ZPNumber, 
		ValidStatus.StatusDesc AS Status,
		dbo.udf_GetPropertyAddressLongMixed(@intFolderRSN) AS Address,
		Folder.FolderName AS Address, 
		ValidSub.SubDesc AS Sub, 
		ValidWork.WorkDesc AS Work,  
		CONVERT(CHAR(11), Folder.InDate) AS InDate,
		CONVERT(CHAR(11), Folder.IssueDate) AS IssueDate, 
		CONVERT(CHAR(11), Folder.ExpiryDate) AS ExpiryDate, 
		dbo.f_info_alpha_null(@intFolderRSN, 10068) AS ProjectManager, 
		Folder.FolderDescription AS Description
	FROM Folder
	LEFT JOIN ValidStatus ON Folder.StatusCode = ValidStatus.StatusCode 
	LEFT JOIN ValidSub ON Folder.SubCode = ValidSub.SubCode
	LEFT JOIN ValidWork ON Folder.WorkCode = ValidWork.WorkCode 
	WHERE Folder.FolderRSN = @intFolderRSN
END

GO
