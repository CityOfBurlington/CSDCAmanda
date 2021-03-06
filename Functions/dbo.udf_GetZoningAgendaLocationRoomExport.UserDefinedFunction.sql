USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaLocationRoomExport]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaLocationRoomExport](@intFolderRSN INT) 
RETURNS VARCHAR(30)
AS 
BEGIN
   /* Returns meeting room from ZM folders for exporting to the web site database. 
      Called by dbo.usp_Zoning_Export_Meeting_Schedule_ZM_Folder. */

   DECLARE @varLocation varchar(30)
   DECLARE @intWorkCode int

   SELECT @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varLocation = 
   CASE @intWorkCode 
      WHEN 10038 THEN 'City Hall Contois Auditorium'
      WHEN 10039 THEN 'City Hall Conference Rm 12'
      WHEN 10040 THEN 'Planning and Zoning Office' 
      WHEN 10041 THEN 'Firehouse Center for the Arts' 
      WHEN 10042 THEN 'Public Works Conference Rm' 
      WHEN 10043 THEN 'Fletcher Free Library' 
      WHEN 10044 THEN 'Police Station Community Rm'
      ELSE ' '
   END

   RETURN @varLocation
END
GO
