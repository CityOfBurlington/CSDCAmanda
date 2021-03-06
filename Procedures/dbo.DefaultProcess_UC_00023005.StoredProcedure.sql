USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_UC_00023005]    Script Date: 9/9/2013 9:56:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_UC_00023005]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
   
/* UC Requester Letters (23005) */

/* Adds various Word Mailmerge letters to FolderDocument */ 

DECLARE @intAttemptResult int 
DECLARE @intPermitRSN int 
DECLARE @varPermitFolderType varchar(4)
DECLARE @intPermitRSNExists int
DECLARE @intDocumentCode int
DECLARE @varLogText varchar(100)
DECLARE @intLetterCount int
DECLARE @intLetterDisplayOrder int
DECLARE @intLetterNotGenerated int

/* Get attempt result. */

SELECT @intAttemptResult = FolderProcessAttempt.ResultCode 
  FROM FolderProcessAttempt
 WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN
   AND FolderProcessAttempt.AttemptRSN = 
       ( SELECT MAX(FolderProcessAttempt.AttemptRSN) 
           FROM FolderProcessAttempt
          WHERE FolderProcessAttempt.ProcessRSN = @ProcessRSN ) 

/* Error checks of FolderProcessInfo FolderRSN entry */

SELECT @intPermitRSN = FolderProcessInfo.InfoValueNumeric
  FROM FolderProcessInfo
 WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
   AND FolderProcessInfo.InfoCode = 23005 

IF @intPermitRSN IS NULL
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter the FolderRSN for the subject permit letter in ProcessInfo.', 16, -1)
   RETURN
END

SELECT @intPermitRSNExists = COUNT(*)
  FROM FolderInfo  
 WHERE FolderInfo.FolderRSN = @FolderRSN 
   AND FolderInfo.InfoCode BETWEEN 23001 AND 23020
   AND FolderInfo.InfoValueNumeric = @intPermitRSN 

IF @intPermitRSNExists = 0
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('Please enter a FolderRSN in ProcessInfo that matches one in FolderInfo.', 16, -1)
   RETURN
END

SELECT @varPermitFolderType = Folder.FolderType 
FROM Folder
WHERE Folder.FolderRSN = @intPermitRSN

IF @intAttemptResult IN (23010, 23011) AND @varPermitFolderType LIKE 'Z%'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('FolderRSN in ProcessInfo is for a Zoning Permit. Please enter one for a Building Permit.', 16, -1)
   RETURN
END

IF @intAttemptResult IN (23008, 23012) AND @varPermitFolderType NOT LIKE 'Z%'
BEGIN
   ROLLBACK TRANSACTION
   RAISERROR ('FolderRSN in ProcessInfo is for a Building Permit. Please enter one for a Zoning Permit.', 16, -1)
   RETURN
END

/* Set document parameters */ 

SELECT @intDocumentCode = 
CASE @intAttemptResult
   WHEN 23008 THEN 23000 
   WHEN 23009 THEN 23001
   WHEN 23010 THEN 23002
   WHEN 23011 THEN 23003
   WHEN 23012 THEN 23004
   ELSE 0
END

SELECT @varLogText = 
CASE @intAttemptResult
   WHEN 23008 THEN 'Send Project Noncompliant Letter'
   WHEN 23009 THEN 'Send Incomplete Documentation Letter'
   WHEN 23010 THEN 'Send Building Permit Required Letter'
   WHEN 23011 THEN 'Send Building Permit Not Closed Letter'
   WHEN 23012 THEN 'Send Development Review Fee Due Letter'
   ELSE ' '
END

SELECT @intLetterCount = COUNT(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode BETWEEN 23000 AND 23004

SELECT @intLetterDisplayOrder = 1000 + ( @intLetterCount * 10 )

SELECT @intLetterNotGenerated = COUNT(*)
  FROM FolderDocument
 WHERE FolderDocument.FolderRSN = @FolderRSN
   AND FolderDocument.DocumentCode = @intDocumentCode
   AND FolderDocument.DateGenerated IS NULL

IF @intAttemptResult IN (23008, 23009, 23010, 23011, 23012) AND @intLetterNotGenerated = 0 
BEGIN
   SELECT @NextDocumentRSN = @NextDocumentRSN + 1
   INSERT INTO FolderDocument
             ( FolderRSN, DocumentCode, DocumentStatus, DocumentRSN, 
               DisplayOrder, StampDate, StampUser, LinkCode )
      VALUES ( @FolderRSN, @intDocumentCode, 1, @NextDocumentRSN, 
               @intLetterDisplayOrder, getdate(), @UserID, 1 )
END

/* Record log in Folder.FolderCondition. */

UPDATE Folder
SET Folder.FolderCondition = 
	CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000),FolderCondition)) + 
	' -> ' + RTRIM(@varLogText) + ' (' +
	CONVERT(CHAR(11), getdate()) + ')' ))
FROM Folder 
WHERE Folder.FolderRSN = @FolderRSN

/* Set UC folder status to UCO Noncompliant when a noncompliant letter is added */

IF @intAttemptResult = 23008			/* Add Project Noncompliant Letter */
BEGIN
	UPDATE Folder
	SET Folder.StatusCode = 23010		/* UCO Noncompliant */
	WHERE Folder.FolderRSN = @FolderRSN
END

/* Process stays open until UCO is issued, at which time the UCO 
   process (23003) closes it. */

UPDATE FolderProcess
   SET FolderProcess.StatusCode = 1, 
       FolderProcess.ScheduleDate = getdate(),
       FolderProcess.StartDate = NULL, FolderProcess.EndDate = NULL, 
       FolderProcess.AssignedUser = NULL, FolderProcess.SignOffUser = NULL 
 WHERE FolderProcess.ProcessRSN = @ProcessRSN
   AND FolderProcess.FolderRSN = @FolderRSN

GO
