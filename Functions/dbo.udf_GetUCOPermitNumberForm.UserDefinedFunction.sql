USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetUCOPermitNumberForm]    Script Date: 9/9/2013 9:43:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetUCOPermitNumberForm](@intFolderRSN INT) 
RETURNS VARCHAR(10)
AS
BEGIN
   /* Returns Folder.ReferenceFile for a permit in the UCO folder. The permit's 
      FolderRSN is entered into FolderProcessInfo for the process that adds the 
      mailmerge document. Used by Word mailmerge documents. */

   DECLARE @varPermitNumber varchar(10)
   DECLARE @intPermitFolderRSN int 

   SET @varPermitNumber = ' '

   SELECT @intPermitFolderRSN = FolderProcessInfo.InfoValueNumeric
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.FolderRSN = @intFolderRSN
      AND FolderProcessInfo.InfoCode = 23005   /* Permit FolderRSN */
      AND FolderProcessInfo.ProcessRSN = 
          ( SELECT MAX(FolderProcess.ProcessRSN)  
              FROM FolderProcess 
             WHERE FolderProcess.FolderRSN = @intFolderRSN 
               AND FolderProcess.ProcessCode = 23005 )

   SELECT @varPermitNumber = Folder.ReferenceFile 
     FROM Folder 
    WHERE Folder.FolderRSN = @intPermitFolderRSN 

   RETURN @varPermitNumber
END

GO
