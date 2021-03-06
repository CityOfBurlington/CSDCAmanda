USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Daily_Update_Temporary_CO]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Daily_Update_Temporary_CO]
AS 
BEGIN
	/* Expired Temporary Certificates of Occupancy for Zoning and UCO folders:
	   For projects without phases, set Folder.StatusCode to TCO Expired. 
	   For multi-phase projects, set the Phased CO process FolderProcess.StatusCode 
	   to TCO Expired. */

	UPDATE Folder
	   SET Folder.StatusCode = 10013,           /* TCO Expired - Single Phase Projects */
		   Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + '-> TCO Expired (' + CONVERT(CHAR(11), getdate()) + ')')) 
	  FROM Folder, FolderInfo
	 WHERE Folder.FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZF' ,'ZH', 'ZZ')
	   AND Folder.StatusCode = 10007
	   AND Folder.FolderRSN = FolderInfo.FolderRSN
	   AND FolderInfo.InfoCode = 10072
	   AND FolderInfo.InfoValueDateTime < getdate() 

	UPDATE Folder
	   SET Folder.StatusCode = 23008,           /* TCO Expired - UCO folders */
		   Folder.Foldercondition = convert(text,(rtrim(convert(varchar(2000),foldercondition)) + '-> TCO Expired (' + CONVERT(CHAR(11), getdate()) + ')')) 
	  FROM Folder, FolderInfo
	 WHERE Folder.FolderType = 'UC' 
	   AND Folder.StatusCode = 23007
	   AND Folder.FolderRSN = FolderInfo.FolderRSN
	   AND FolderInfo.InfoCode = 23033
	   AND FolderInfo.InfoValueDateTime < getdate() 

	UPDATE FolderProcess 
	   SET FolderProcess.StatusCode = 10005     /* TCO Expired - Phased Projects */
	 WHERE FolderProcess.ProcessCode = 10030 
	   AND FolderProcess.StatusCode = 10004 
	   AND FolderProcess.ProcessRSN IN 
		   ( SELECT FolderProcessInfo.ProcessRSN 
			   FROM FolderProcessInfo
			  WHERE FolderProcessInfo.InfoValueDateTime < getdate() 
			    AND FolderProcessInfo.InfoCode = 10015 )
END
GO
