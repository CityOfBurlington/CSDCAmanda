USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaLocationStreetExport]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaLocationStreetExport](@intFolderRSN INT) 
RETURNS VARCHAR(30)
AS 
BEGIN
   /* Returns meeting street address from ZM folders for exporting to the web site database. 
      Called by dbo.usp_Zoning_Export_Meeting_Schedule_ZM_Folder. */

   DECLARE @varStreet varchar(30)
   DECLARE @intWorkCode int

   SELECT @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varStreet = 
   CASE @intWorkCode 
      WHEN 10038 THEN '149 Church Street'
      WHEN 10039 THEN '149 Church Street'
      WHEN 10040 THEN '149 Church Street' 
      WHEN 10041 THEN '135 Church Street' 
      WHEN 10042 THEN '645 Pine Street' 
      WHEN 10043 THEN '235 College Street' 
      WHEN 10044 THEN '1 North Avenue'
      ELSE ' '
   END

   RETURN @varStreet
END

GO
