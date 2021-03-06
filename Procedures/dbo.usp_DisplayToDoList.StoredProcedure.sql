USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_DisplayToDoList]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DisplayToDoList](@ToDoUser VARCHAR(128))
AS
BEGIN

/* Build list of open folder processes for this user */
SELECT Folder.FolderRSN, Folder.FolderCentury,  Folder.FolderYear, Folder.FolderSequence, 
Folder.FolderSection, Folder.FolderRevision, Folder.FolderType, 
Folder.FolderName, Folder.Priority, Folder.ReferenceFile, Folder.ParentRSN, 
ValidProcess.ProcessDesc, FolderProcess.ProcessRSN, FolderProcess.ProcessCode, FolderProcess.Priority,
FolderProcess.ScheduleDate, FolderProcess.TimeIndicator , FolderProcess.ScheduleEndDate, 
FolderProcess.EndDate, FolderProcess.StatusCode AS PStatusCode, FolderProcess.SignOffUser, 
FolderProcess.AssignedUser, FolderProcess.AssignFlag, FolderProcess.PassedFlag, 
FolderProcess.StartDate, FolderProcess.ProcessComment, 
FolderProcess.StampDate, FolderProcess.StampUser, ' ' PeopleName,' ' ShowFlag, ' ' IsPaused 
, ' ' ViolationFlag, Folder.PropertyRSN, ' ' InspectionRequestComment, 
Property.PropHouseNumeric PropHouse, Property.PropStreet PropStreet, 
Property.PropStreetType  PropStreetType  FROM Folder, FolderProcess, ValidProcess, ValidFolder, ValidFolderGroup, Property  
WHERE ( Folder.FolderRSN = FolderProcess.FolderRSN ) 
and ( Property.PropertyRSN = Folder.PropertyRSN )
and ( FolderProcess.ProcessCode = ValidProcess.ProcessCode )
and ( FolderProcess.EndDate is NULL ) 
AND ( FolderProcess.AssignedUser = @ToDoUser ) 
AND ((FolderProcess.ScheduleDate between '1-1-1800 0:0:0.000' and '7-8-2011 23:59:59.000') 
 OR ( FolderProcess.AssignFlag = '*')) 
AND ( Folder.FolderType = ValidFolder.FolderType )
AND ( ValidFolder.FolderGroupCode = ValidFolderGroup.FolderGroupCode )
AND ( ValidFolder.FolderType = Folder.FolderType ) 
AND ( ValidFolder.ConfidentialFolder is NULL OR ValidFolder.ConfidentialFolder = 'N' 
 OR ( ValidFolder.ConfidentialFolder = 'Y' 
AND EXISTS ( SELECT * FROM ValidUserButton WHERE ValidUserButton.UserId = @ToDoUser 
AND ValidUserButton.FolderType = ValidFolder.FolderType AND ValidUserButton.ButtonCode = 9 ))) 
ORDER BY Folder.FolderRSN, FolderProcess.ProcessRSN

/* Build list of included folder comments */
SELECT Folder.FolderRSN, Folder.FolderCentury, Folder.FolderYear, Folder.FolderSequence,
 Folder.FolderSection, Folder.FolderRevision, Folder.FolderType, Folder.FolderName,
 FolderComment.CommentDate, FolderComment.ReminderDate, FolderComment.Comments, FolderComment.CommentUser, 
 FolderComment.IncludeOnToDo, FolderComment.StampDate, FolderComment.StampUser
 FROM Folder, FolderComment  , ValidFolder 
 WHERE ( Folder.FolderRSN = FolderComment.FolderRSN ) 
 and ( FolderComment.CommentUser = @ToDoUser ) 
 AND ( FolderComment.ReminderDate between '1-1-1800 0:0:0.000' and '7-8-2011 23:59:59.000' ) 
 AND ( FolderComment.IncludeOnToDo = 'Y' ) AND ( ValidFolder.FolderType = Folder.FolderType ) 
 AND ( ValidFolder.ConfidentialFolder is NULL OR ValidFolder.ConfidentialFolder = 'N' 
  OR ( ValidFolder.ConfidentialFolder = 'Y' 
 AND EXISTS ( SELECT * FROM ValidUserButton WHERE ValidUserButton.UserId = @ToDoUser 
 AND ValidUserButton.FolderType = ValidFolder.FolderType AND ValidUserButton.ButtonCode = 9 )))
 ORDER BY Folder.FolderRSN, FolderComment.StampDate

END
GO
