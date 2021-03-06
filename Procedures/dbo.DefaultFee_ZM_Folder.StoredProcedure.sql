USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZM_Folder]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZM_Folder]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Folder Initialize for ZM (Zoning Meeting Agenda) folders */

DECLARE @intSubCode int          /* Board */
DECLARE @dtIssueDate datetime    /* Meeting Date */
DECLARE @dtExpiryDate datetime   /* Regular Item Submission Deadline Date */
DECLARE @dtFinalDate datetime    /* Public Hearing Item Submission Deadline Date */
DECLARE @intMeetingHour int
DECLARE @intMeetingMinute int 
DECLARE @intSubmissionHour int
DECLARE @varMeetingDate varchar(30)
DECLARE @varFolderName varchar(150)
DECLARE @varFolderLog varchar(150)
DECLARE @intAMProcessRSN int

SELECT @intSubCode =   Folder.SubCode,  
       @dtIssueDate =  Folder.IssueDate, 
       @dtExpiryDate = Folder.ExpiryDate, 
       @dtFinalDate =  Folder.FinalDate 
  FROM Folder 
 WHERE Folder.FolderRSN = @FolderRSN  

/* Check for meeting date and submission deadline date entry */

IF @dtIssueDate IS NULL 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the meeting date in Issue/Approval.', 16, -1)
   RETURN
END

IF @dtExpiryDate IS NULL 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the Regular Item Deadline date in Expires.', 16, -1)
   RETURN
END

IF @intSubCode = 10049   /* DRB */
BEGIN 
   IF @dtFinalDate IS NULL 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Please enter the Public Hearing Item Deadline date in Final Date.', 16, -1)
      RETURN
   END

   IF @dtExpiryDate < @dtFinalDate 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('The Regular Item Deadline date is prior to Public Hearing Item Deadline date. Please reverse.', 16, -1)
      RETURN
   END
END 

IF ( @intSubCode <> 10049 AND @dtFinalDate IS NOT NULL ) 
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Public Hearing Deadline date (Final Date) is valid only for the DRB. Please correct.', 16, -1)
   RETURN
END


/* Add initialization time to Folder.InDate */

UPDATE Folder
   SET Folder.InDate = DATEADD(hour, datepart(hour, getdate()), Folder.InDate)
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

UPDATE Folder
   SET Folder.InDate = DATEADD(minute, datepart(minute, getdate()), Folder.InDate)
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

/* Add times to meeting date and submission deadline dates. */

SELECT @intMeetingHour = 
CASE @intSubCode
   WHEN 10049 THEN 17   /* DRB */
   WHEN 10050 THEN 15   /* DAB */
   WHEN 10051 THEN 17   /* CB  */
END

SELECT @intMeetingMinute = 
CASE @intSubCode
   WHEN 10049 THEN  0   /* DRB */
   WHEN 10050 THEN  0   /* DAB */
   WHEN 10051 THEN 30   /* CB  */
END

SELECT @intSubmissionHour = 
CASE @intSubCode
   WHEN 10049 THEN 16   /* DRB */
   WHEN 10050 THEN 16   /* DAB */
   WHEN 10051 THEN 16   /* CB  */
END

UPDATE Folder
   SET Folder.IssueDate  = DATEADD(hour, @intMeetingHour,    Folder.IssueDate), 
       Folder.ExpiryDate = DATEADD(hour, @intSubmissionHour, Folder.ExpiryDate) 
 WHERE Folder.FolderRSN = @FolderRSN

UPDATE Folder
   SET Folder.IssueDate  = DATEADD(minute, @intMeetingMinute, Folder.IssueDate)
 WHERE Folder.FolderRSN = @FolderRSN

IF @intSubCode = 10049 
BEGIN
   UPDATE Folder
      SET Folder.FinalDate = DATEADD(hour, @intSubmissionHour, Folder.FinalDate) 
    WHERE Folder.FolderRSN = @FolderRSN
END

/* Write out agenda title to Folder.FolderName and UserID to Folder.IssueBy. */

SELECT @varFolderName  = 'Agenda for ' + dbo.udf_GetZoningAgendaMeetingDateTime(@FolderRSN)

UPDATE Folder
   SET Folder.FolderName = @varFolderName, 
       Folder.IssueUser = @UserID
 WHERE Folder.FolderRSN = @FolderRSN

/* Insert FolderInfo fields */

EXECUTE dbo.usp_Zoning_Insert_FolderInfo_ZM_Folder @FolderRSN , @UserID 

/* Insert FolderProcessChecklists into Agenda Management */

SELECT @intAMProcessRSN = FolderProcess.ProcessRSN 
  FROM FolderProcess 
 WHERE FolderProcess.FolderRSN = @FolderRSN 
   AND FolderProcess.ProcessCode = 10031 

INSERT INTO FolderProcessChecklist               /* Regular Meeting Agenda */
          ( FolderRSN, ProcessRSN, ChecklistCode, Passed, 
            StampDate, StampUser, ChecklistDisplayOrder )
   VALUES ( @FolderRSN, @intAMProcessRSN, 10022, 'Y', getdate(), @UserID, 10 )


INSERT INTO FolderProcessChecklist                  /* Amended Agenda */
          ( FolderRSN, ProcessRSN, ChecklistCode, 
            StampDate, StampUser, CheckListDisplayOrder )
   VALUES ( @FolderRSN, @intAMProcessRSN, 10023, getdate(), @UserID, 20 )

INSERT INTO FolderProcessChecklist                  /* Special Meeting Agenda */
          ( FolderRSN, ProcessRSN, ChecklistCode, 
            StampDate, StampUser, ChecklistDisplayOrder )
   VALUES ( @FolderRSN, @intAMProcessRSN, 10024, getdate(), @UserID, 30 )

GO
