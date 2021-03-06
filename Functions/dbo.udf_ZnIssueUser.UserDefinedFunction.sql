USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZnIssueUser]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_ZnIssueUser](@intFolderRSN INT) RETURNS varchar(20)
AS
BEGIN

   DECLARE @FolderIssueUser varchar(20)
   DECLARE @ProjectManager varchar(20)
   DECLARE @IssueUser varchar(20)

   SELECT @FolderIssueUser = Folder.IssueUser,
                 @ProjectManager = dbo.f_info_alpha(Folder.FolderRSN, 10068)
     FROM Folder
   WHERE Folder.FolderRSN = @intFolderRSN

   IF @FolderIssueUser IS NULL SELECT @IssueUser = @ProjectManager
   ELSE 
   BEGIN
     SELECT @IssueUser = ValidUser.UserName
        FROM Folder, ValidUser
    WHERE  Folder.IssueUser = ValidUser.UserID
          AND Folder.FolderRSN = @intFolderRSN
   END

   RETURN @IssueUser
END

GO
