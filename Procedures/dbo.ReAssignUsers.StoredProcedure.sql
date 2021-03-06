USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[ReAssignUsers]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.ReAssignUsers    Script Date: 11/10/00 10:24:19 AM ******/
CREATE PROCEDURE [dbo].[ReAssignUsers] @argProcessCode int
AS
	DECLARE @RecCount	int 
	DECLARE @DefaultUser char(128)

	UPDATE FolderProcess
	SET AssignedUser =
		(SELECT DAA.AssignUser
		FROM DefaultAreaAssignment DAA, ValidProcess VP, Folder, PropertyInfo
		WHERE DAA.ProcessCode = @argProcessCode
		AND DAA.AreaCode = PropertyInfo.PropInfoValue
		AND VP.ProcessCode = @argProcessCode
		AND Folder.FolderRSN = FolderProcess.FolderRSN
	  	AND PropertyInfo.PropertyRSN = Folder.PropertyRSN
	  	AND PropertyInfo.PropertyInfoCode = VP.PropertyInfoCode )
	WHERE FolderProcess.ProcessCode = @argProcessCode
  	AND FolderProcess.EndDate is null



GO
