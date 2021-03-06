USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Daily_Update_Folder_Clock]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Daily_Update_Folder_Clock]
AS 
BEGIN
	/* Increment the Folder Clock forward for zoning folders. 
	   FolderClock.Counter is in Days.  Start Folder Clocks that are set to start. 
	   ZN folders do not have FolderClock. */

	UPDATE FolderClock
	   SET FolderClock.Counter =  ( FolderClock.Counter + DATEDIFF(day, FolderClock.StartDate, getdate()) ), 
		   FolderClock.StartDate = getdate()
	  FROM Folder, FolderClock
	 WHERE Folder.FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZD', 'ZF', 'ZH', 'ZL', 'ZP') 
	   AND FolderClock.Status = 'Running'
	   AND FolderClock.StartDate < getdate()
	   AND Folder.FolderRSN = FolderClock.FolderRSN
	
	UPDATE FolderClock
	   SET FolderClock.Status = 'Running'
	  FROM Folder, FolderClock
	 WHERE Folder.FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZD', 'ZF', 'ZH', 'ZL', 'ZP') 
	   AND FolderClock.Status = 'Set to Start'
	   AND FolderClock.StartDate < getdate()
       AND Folder.FolderRSN = FolderClock.FolderRSN
END
GO
