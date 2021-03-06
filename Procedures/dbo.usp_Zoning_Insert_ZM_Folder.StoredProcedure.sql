USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_ZM_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_ZM_Folder] 
		( @varBoard varchar(4), @dtMeetingDate datetime, @dtPHDate datetime, @dtRegDate datetime )
AS
BEGIN 
	/* Inserts a Zoning Meeting Agenda (ZM) folder. 
	
	   @varBoard valid values are 'DRB', 'DAB', or 'CB' 
	   @dtMeetingDate is the meeting date
	   @dtPHDate is the Public Hearing item submission deadline date 
	   @dtRegDate is the Regular item submission deadline date 
	   
	   dbo.DefaultFee_ZM_Folder adds the proper times to the above dates. */

	DECLARE @intNextFolderRSN int
	DECLARE @varFolderSequence varchar(10)
	DECLARE @varUserID varchar(20)
	DECLARE @intBoard int
	DECLARE @intRoom int
   
	SELECT @intNextFolderRSN = ( MAX(Folder.FolderRSN) + 1 ), 
		   @varFolderSequence = dbo.udf_GetNextFolderSeq() 
	FROM Folder 
	
	SELECT @varUserID = SYSTEM_USER
	
	SELECT @intBoard = 
	CASE @varBoard
		WHEN 'DRB' THEN 10049
		WHEN 'DAB' THEN 10050
		WHEN 'CB'  THEN 10051
		ELSE 0
	END

	/* Default meeting locations */

	SELECT @intRoom = 
	CASE @varBoard
		WHEN 'DRB' THEN 10038		/* Contois Auditorium */
		WHEN 'DAB' THEN 10039		/* Conference Room 12 */
		WHEN 'CB'  THEN 10040		/* P+Z Conference Room */
		ELSE 0
	END

	/* Indate = Initialization Date
	   IssueDate = Meeting Date
	   ExpiryDate = Regular Item Submission Deadline
	   FinalDate = Public Hearing Item Submission Deadline */

	INSERT INTO Folder 
		  ( FolderRSN, FolderType, FolderCentury, FolderYear, FolderSequence, FolderSection, FolderRevision, 
			StatusCode, SubCode, WorkCode, 
			InDate, IssueDate, ExpiryDate, FinalDate, 
			PropertyRSN, IssueUser, CopyFlag, StampDate, StampUser )
		VALUES ( @intNextFolderRSN, 'ZM', SUBSTRING(CAST(YEAR(getdate()) AS VARCHAR), 1, 2), 
				 SUBSTRING(CAST(YEAR(getdate()) AS VARCHAR), 3, 2), @varFolderSequence, '000', '00', 
				 10049, @intBoard, @intRoom, 
				 getdate(), @dtMeetingDate, @dtRegDate, @dtPHDate, 
				 0, NULL, 'DDDDD', getdate(), @varUserID ) 

	EXECUTE dbo.DefaultFee_ZM_Folder @intNextFolderRSN, @varUserID
	
	UPDATE Folder
	SET Folder.IssueUser = NULL
	WHERE Folder.FolderRSN = @intNextFolderRSN

END

GO
