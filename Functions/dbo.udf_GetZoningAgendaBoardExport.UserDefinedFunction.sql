USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaBoardExport]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaBoardExport](@intFolderRSN INT) 
RETURNS VARCHAR(4)
AS 
BEGIN
   /* Returns Board abbreviation from ZM folders for exporting to the web site database. 
      Called by dbo.usp_Zoning_Export_Meeting_Schedule_ZM_Folder. */

   DECLARE @varBoard varchar(4)
   DECLARE @intSubCode int

   SELECT @intSubCode = Folder.SubCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varBoard = 
   CASE @intSubCode 
      WHEN 10049 THEN 'DRB'
      WHEN 10050 THEN 'DAB'
      WHEN 10051 THEN 'CB' 
      ELSE ' '
   END

   RETURN @varBoard
END

GO
