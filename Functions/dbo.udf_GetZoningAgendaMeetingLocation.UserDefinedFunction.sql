USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaMeetingLocation]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaMeetingLocation](@intFolderRSN INT) 
RETURNS varchar(400)
AS 
BEGIN
   /* Creates meeting location for Infomaker meeting_agenda */

   DECLARE @intWorkCode int
   DECLARE @varMeetingLocation varchar(100)

   SELECT @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @varMeetingLocation = 
   CASE @intWorkCode 
      WHEN 10038 THEN 'Contois Auditorium, City Hall, 149 Church Street, Burlington, VT' 
      WHEN 10039 THEN 'Conference Room 12, City Hall, 149 Church Street, Burlington, VT' 
      WHEN 10040 THEN 'Planning and Zoning Conference Room, 149 Church Street, Burlington, VT' 
      WHEN 10041 THEN 'Firehouse Center for the Visual Arts, 135 Church Street, Burlington, VT'
      WHEN 10042 THEN 'Public Works Conference Room, 645 Pine Street, Burlington, VT'
      WHEN 10043 THEN 'Fletcher Free Library, 235 College Street, Burlington, VT'
      when 10044 THEN 'Police Station Community Room, 1 North Avenue, Burlington, VT'
      ELSE 'To Be Determined'
   END

   RETURN @varMeetingLocation
END

GO
