USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Code_Zoning_Complaint_Update]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Code_Zoning_Complaint_Update]
AS 
   /* Automated procedure for QZ folders - runs nightly.  
      Procedure updates WorkCodes for decisions whose appeal periods have expired. */

   /* SC Memo No Response or Inadequate Response */

   UPDATE Folder
      SET Folder.SubCode = 20064,       /* Investigation */
          Folder.WorkCode = 20101,      /* Show Cause Memo Expired */
          Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Show Cause Memo Deadline Passed -> Formal Investigation Initiated (' + CONVERT(CHAR(11), getdate()) + ')'))
    WHERE Folder.FolderType = 'QZ'
      AND Folder.StatusCode = 1
      AND Folder.ExpiryDate < getdate()
      AND Folder.SubCode IN (20059, 20060)      /* Complaint Received; Initial Assessment */
      AND Folder.WorkCode IN (20100, 20111)     /* Show Cause Memo Sent; Show Cause Memo Response Received */

   UPDATE Folder
      SET Folder.FolderCondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + ' -> Show Cause Memo Deadline Passed (' + CONVERT(CHAR(11), getdate()) + ')'))
    WHERE Folder.FolderType = 'QZ'
      AND Folder.StatusCode = 1
      AND Folder.ExpiryDate < getdate()
      AND Folder.SubCode NOT IN (20059, 20060)
      AND Folder.WorkCode IN (20100, 20111)     /* Show Cause Memo Sent; Show Cause Memo Response Received */

   UPDATE FolderProcess
      SET FolderProcess.StatusCode = 2, 
          FolderProcess.EndDate = getdate(), FolderProcess.BaseLineEndDate = getdate()
    WHERE FolderProcess.StatusCode = 1
      AND FolderProcess.ProcessCode = 20042     /* Show Cause Response */
      AND FolderProcess.FolderRSN IN  
          ( SELECT Folder.FolderRSN
              FROM Folder
             WHERE Folder.FolderType = 'QZ'
               AND Folder.StatusCode = 1
               AND Folder.ExpiryDate < getdate()
               AND Folder.WorkCode IN (20100, 20111) )     /* Show Cause Memo Sent; Show Cause Memo Response Received */

   /* Stipulation Agreement Deadline Passed (20114) */

   UPDATE Folder
      SET Folder.WorkCode = 20126,      /* Stipulation Agreement Expired */
          Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) +' -> Stipulation Agreement Deadline Passed (' + CONVERT(CHAR(11), getdate()) + ')'))
    WHERE Folder.FolderType = 'QZ'
      AND Folder.StatusCode = 1
      AND Folder.ExpiryDate < getdate()
      AND Folder.WorkCode  = 20114      /* Stipulation Agreement Reached */

   /* Appeal Period - GF, FF, ZR Approved and Denied (20115, 20116)
      Appeal Period - Complaint Unfounded (20119)
      Appeal Period - DRB and VEC Appeals (20121, 20122, 20123, 20124) 
      Appeal Period - Notice of Violation (20120) 
      Appeal Period - Litigation (20127) */

   UPDATE Folder
      SET Folder.WorkCode = 20131      /* Appeal Period Expired */
    WHERE Folder.FolderType = 'QZ'
      AND Folder.StatusCode = 1
      AND Folder.ExpiryDate < getdate()
      AND Folder.WorkCode IN (20115, 20116, 20119, 20120, 20121, 20122, 20123, 20124, 20127)

GO
