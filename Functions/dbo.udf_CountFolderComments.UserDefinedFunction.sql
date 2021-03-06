USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CountFolderComments]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_CountFolderComments](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
   DECLARE @CommentCount int
   SET @CommentCount = 0
   SELECT @CommentCount = count(*)
     FROM Folder, FolderComment
    WHERE FolderComment.FolderRSN = Folder.FolderRSN
      AND Folder.FolderRSN = @intFolderRSN
RETURN @CommentCount
END


GO
