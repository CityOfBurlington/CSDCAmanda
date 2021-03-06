USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaTitleShort]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaTitleShort](@intFolderRSN INT) 
RETURNS varchar(400)
AS 
BEGIN
   /* Creates short version of meeting board and date for Infomaker whiteboard */

   DECLARE @intSubCode int
   DECLARE @varChecklistCode int 
   DECLARE @varMeetingDate varchar(30)
   DECLARE @varMeetingTitle varchar(100)

   SELECT @intSubCode = Folder.SubCode 
     FROM Folder 
    WHERE FOlder.FolderRSN = @intFolderRSN 

   SELECT @varChecklistCode = FolderProcessChecklist.ChecklistCode
     FROM FolderProcessChecklist, FolderProcess
    WHERE FolderProcessChecklist.Passed = 'Y'
      AND FolderProcessChecklist.FolderRSN = @intFolderRSN
      AND FolderProcessChecklist.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.ProcessCode = 10031

   SELECT @varMeetingDate = dbo.udf_GetFolderIssueDateLong(@intFolderRSN)

   IF @intSubCode = 10049 AND @varChecklistCode = 10024 
      SELECT @varMeetingTitle = 'DRB Deliberative - ' + @varMeetingDate 
   ELSE 
   BEGIN 
      SELECT @varMeetingTitle = 
      CASE @intSubCode 
         WHEN 10049 THEN 'DRB - ' + @varMeetingDate 
         WHEN 10050 THEN 'DAB - ' + @varMeetingDate 
         WHEN 10051 THEN 'CB - '  + @varMeetingDate 
         ELSE ' '
      END
   END

   RETURN @varMeetingTitle
END



GO
