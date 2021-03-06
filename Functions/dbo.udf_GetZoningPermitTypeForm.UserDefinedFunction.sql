USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitTypeForm]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitTypeForm](@intFolderRSN int) 
RETURNS varchar(60)
AS
BEGIN
   /* Used by Infomaker zoning_all_permits form */
   DECLARE @strFolderPermitType varchar(60)
   DECLARE @strFolderType varchar(3)
   DECLARE @intWorkCode int

   SET @strFolderPermitType = 'Unknown FolderType'

   SELECT @strFolderType = Folder.Foldertype, 
          @intWorkCode = Folder.WorkCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   IF @strFolderType IN ('ZH', 'ZL', 'ZP')
   BEGIN
      SELECT @strFolderPermitType = 
      CASE @intWorkCode
         WHEN 10000 THEN 'CONDITIONAL USE'
         WHEN 10001 THEN 'HOME OCCUPATION'
         WHEN 10002 THEN 'CONDITIONAL USE'
         WHEN 10003 THEN 'VARIANCE'
         WHEN 10004 THEN 'APPEAL OF ENFORCEMENT DECISION'
         WHEN 10005 THEN 'APPEAL OF MISC ZONING DECISION' 
         WHEN 10006 THEN 'MASTER PARKING PLAN REVIEW'
         WHEN 10007 THEN 'MASTER SIGN PLAN REVIEW' 
         WHEN 10008 THEN 'MASTER TREE MAINTENANCE PLAN REVIEW'
         ELSE 'UNKNOWN WORKCODE'
      END
   END
   ELSE
   BEGIN
      SELECT @strFolderPermitType = 
      CASE @strFolderType
         WHEN 'ZA' THEN 'SIGNS AND AWNINGS'
         WHEN 'ZB' THEN 'BASIC' 
         WHEN 'ZC' THEN 'CERTIFICATE OF APPROPRIATENESS'
         WHEN 'ZF' THEN 'FENCE'
         WHEN 'ZZ' THEN 'PAPER-BASED RECORD'
         WHEN 'Z1' THEN 'CERTIFICATE OF APPROPRIATENESS'
         WHEN 'Z2' THEN 'CERTIFICATE OF APPROPRIATENESS'
         WHEN 'Z3' THEN 'CERTIFICATE OF APPROPRIATENESS'
         ELSE 'UNKNOWN FOLDER TYPE'
      END
  END

RETURN @strFolderPermitType
END



GO
