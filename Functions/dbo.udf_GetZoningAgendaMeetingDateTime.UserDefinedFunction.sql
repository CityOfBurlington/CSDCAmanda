USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaMeetingDateTime]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaMeetingDateTime](@intFolderRSN INT) 
RETURNS varchar(400)
AS 
BEGIN
   /* Creates meeting location day, date, time for Infomaker meeting_agenda */

   DECLARE @dtMeetingDateTime datetime 
   DECLARE @varDayName varchar(10)
   DECLARE @varMonth varchar(10)
   DECLARE @varDayNumber varchar(3)
   DECLARE @varYear varchar(5)
   DECLARE @varHour varchar(3)
   DECLARE @varMinute varchar(3)
   DECLARE @varAMPM varchar(3)
   DECLARE @varMeetingDayDateTime varchar(100)

   SELECT @dtMeetingDateTime = Folder.IssueDate
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @varDayName = DATENAME(weekday, Folder.IssueDate), 
          @varMonth = DATENAME(month, Folder.IssueDate), 
          @varDayNumber = CAST(DATENAME(day, Folder.IssueDate) AS VARCHAR), 
          @varYear = CAST(DATENAME(year, Folder.IssueDate) AS VARCHAR), 
          @varHour = LTRIM(LEFT(RIGHT(CONVERT(CHAR(19), Folder.IssueDate, 100), 7), 2)), 
          @varMinute = RIGHT('00' + CAST(DATEPART(minute, Folder.IssueDate) AS VARCHAR), 2), 
          @varAMPM = RIGHT(CONVERT(CHAR(19), Folder.IssueDate, 100), 2) 
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @varMeetingDayDateTime = @varDayName + ' ' + 
          @varMonth + ' ' + 
          @varDayNumber + ', ' + 
          @varYear + ' at ' + 
          @varHour + ':' + 
          @varMinute + ' ' + 
          @varAMPM 

   RETURN @varMeetingDayDateTime 
END

GO
