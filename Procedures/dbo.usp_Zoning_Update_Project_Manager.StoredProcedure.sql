USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Update_Project_Manager]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Update_Project_Manager] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
   DECLARE @varUserFullName varchar(20)

   SELECT @varUserFullName = ValidUser.UserName 
     FROM ValidUser 
    WHERE ValidUser.UserID = @varUserID 

   UPDATE FolderInfo
      SET FolderInfo.InfoValue = @varUserFullName, 
          FolderInfo.InfoValueUpper = UPPER(@varUserFullName), 
          FolderInfo.StampDate = getdate(), 
          FolderInfo.StampUser = @varUserID  
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 10068            /* Project Manager */
END

GO
