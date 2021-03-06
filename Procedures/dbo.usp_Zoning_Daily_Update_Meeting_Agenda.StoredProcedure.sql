USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Daily_Update_Meeting_Agenda]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Daily_Update_Meeting_Agenda]
AS 
BEGIN
/* Set Zoning Meeting Agenda folder statuses when the regular 
   item submission date (Folder.ExpiryDate) has passed. 
   Folder.StatusCode is set to Agenda Closed, or for when the Public 
   Hearing deadline has passed, to the intermediary status of 
   Agenda PH Closed. Deletes null FolderRSN Info fields when submission 
   date (Folder.ExpiryDate) has passed. Closes the Agenda Management 
   process when the meeting date (Folder.IssueDate) has passed. Sets 
   Folder.StatusCode to Meeting Held when the meeting date has passed.*/ 

   UPDATE Folder
      SET Folder.StatusCode = 10051   /* Agenda PH Closed */
    WHERE Folder.FolderType = 'ZM' 
      AND Folder.SubCode = 10049      /* Development Review Board */
      AND Folder.StatusCode = 10050   /* Agenda Active */ 
      AND Folder.FinalDate  < getdate() 
      AND Folder.ExpiryDate > getdate() 

   DELETE FolderInfo 
     FROM FolderInfo
   INNER JOIN Folder ON FolderInfo.FolderRSN = Folder.FolderRSN
        WHERE Folder.FolderType = 'ZM' 
          AND Folder.StatusCode IN (10050, 10051) 
          AND Folder.ExpiryDate < getdate() 
          AND FolderInfo.InfoCode BETWEEN 10082 AND 10119 
          AND FolderInfo.InfoValue IS NULL 

   UPDATE Folder
      SET Folder.StatusCode = 10052   /* Agenda Closed */
    WHERE Folder.FolderType = 'ZM' 
      AND Folder.StatusCode IN (10050, 10051) 
      AND Folder.ExpiryDate < getdate() 

   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2 
    WHERE FolderProcess.ProcessCode = 10031
      AND FolderProcess.StatusCode = 1 
      AND FolderProcess.FolderRSN IN 
        ( SELECT Folder.FolderRSN
            FROM Folder 
           WHERE Folder.FolderType = 'ZM' 
             AND Folder.StatusCode IN (10049, 10050, 10051, 10052) 
             AND Folder.IssueDate < getdate() ) 

   UPDATE Folder
      SET Folder.StatusCode = 10053   /* Meeting Held */
    WHERE Folder.FolderType = 'ZM' 
      AND Folder.StatusCode IN (10049, 10050, 10051, 10052) 
      AND Folder.IssueDate < getdate() 
END
GO
