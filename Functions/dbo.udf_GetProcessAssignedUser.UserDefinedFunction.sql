USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessAssignedUser]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetProcessAssignedUser](@intProcessCode INT, @intFolderRSN INT)
RETURNS VARCHAR(100)
AS
BEGIN
   DECLARE @AssignedUser varchar(100)

   SELECT @AssignedUser = ValidUser.UserName
     FROM Folder, FolderProcess, ValidUser
    WHERE Folder.FolderRSN = FolderProcess.FolderRSN
      AND FolderProcess.ProcessCode = @intProcessCode
      AND FolderProcess.AssignedUser = ValidUser.UserID
      AND Folder.FolderRSN = @intFolderRSN

   RETURN @AssignedUser
END

GO
