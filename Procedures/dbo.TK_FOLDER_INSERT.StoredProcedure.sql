USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_FOLDER_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[TK_FOLDER_INSERT]
@argFolderType varchar(4), 
@argStatusCode int,
@argPropertyRSN int,
@argFolderName varchar(40),
@argUserID varchar(20)

AS


BEGIN
	
	DECLARE @FolderRSN int
	DECLARE @FolderCentury char(2)
	DECLARE @FolderYear char(2)


	/* FOLDER: Create new Folder. */
	SET @FolderRSN  = dbo.udf_GetNextFolderRSN()
	SET @FolderCentury = SUBSTRING(CAST(YEAR(getdate()) AS CHAR), 1, 2)
	SET @FolderYear = SUBSTRING(CAST(YEAR(getdate()) AS CHAR), 3, 2)
	
	INSERT INTO Folder
	(FolderRSN, FolderType, IssueUser, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision,
		StatusCode, PropertyRSN, Indate, CopyFlag, StampDate, StampUser, FolderName)
	SELECT @FolderRSN, @argFolderType, @argUserID, @FolderCentury, @FolderYear, 
         dbo.udf_GetNextFolderSeq(), '000', '00', @argStatusCode, @argPropertyRSN, 
         GETDATE(), 'DDDD',  GETDATE(), @argUserID, @argFolderName
 
	RETURN @FolderRSN

END;

GO
