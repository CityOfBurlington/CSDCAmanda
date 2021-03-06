USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitType]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitType](@intFolderRSN int) 
RETURNS varchar(50)
AS
BEGIN
   /* Used by Word Mailmerge Documents */
   DECLARE @strFolderPermitType varchar(50)
   DECLARE @AppealText varchar(20)
   DECLARE @AppealDRBProcessAttempt int
   DECLARE @strFolderType varchar(4)
   DECLARE @strOtherText varchar(30)

   SET @strFolderPermitType = 'Unknown FolderType'
   SET @strOtherText = ''
   SET @AppealText = ''

   SELECT @strFolderType = Folder.FolderType
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @AppealDRBProcessAttempt = count(*)
     FROM FolderProcessAttempt
    WHERE FolderProcessAttempt.ProcessRSN = 
         (SELECT FolderProcess.ProcessRSN
            FROM FolderProcess
            WHERE FolderProcess.FolderRSN = @intFolderRSN
             AND FolderProcess.ProcessCode = 10002)

   IF @AppealDRBProcessAttempt > 0 SELECT @AppealText = 'Appeal of ' 
   IF @strFolderType = 'ZC' SELECT @strOtherText = 'Zoning Permit - COA and '
   IF @strFolderType = 'ZL' SELECT @strOtherText = 'Miscellaneous ' 

   IF @strFolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZF', 'ZP', 'ZZ')
   BEGIN
      SELECT @strFolderPermitType = @AppealText + ValidFolder.FolderDesc
        FROM Folder, ValidFolder
       WHERE ValidFolder.FolderType = Folder.FolderType
         AND Folder.FolderRSN = @intFolderRSN
   END

   IF @strFolderType IN ('ZC', 'ZH')
   BEGIN
      SELECT @strFolderPermitType = @AppealText + @strOtherText + ValidWork.WorkDesc
        FROM Folder, ValidWork
       WHERE Folder.WorkCode = ValidWork.WorkCode
         AND Folder.FolderRSN = @intFolderRSN
   END

   IF @strFolderType = 'ZL'
   BEGIN
      SELECT @strFolderPermitType = @strOtherText + ValidWork.WorkDesc
        FROM Folder, ValidWork
       WHERE Folder.WorkCode = ValidWork.WorkCode
         AND Folder.FolderRSN = @intFolderRSN
   END

   RETURN @strFolderPermitType
END

GO
