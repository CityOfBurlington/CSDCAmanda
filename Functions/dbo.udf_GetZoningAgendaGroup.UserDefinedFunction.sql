USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaGroup]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaGroup](@intAgendaFolderRSN INT, @intApplicationFolderRSN INT) 
RETURNS varchar(30)
AS 
BEGIN
   /* Returns the agenda item group (ValidInfo.InfoGroup) for grouping Infomaker meeting_agenda */

   DECLARE @varAgendaSection varchar(50)

   SELECT @varAgendaSection = ValidInfo.InfoGroup 
     FROM ValidInfo, FolderInfo 
    WHERE FolderInfo.FolderRSN = @intAgendaFolderRSN 
      AND FolderInfo.InfoCode = ValidInfo.InfoCode 
      AND FolderInfo.InfoValueNumeric = @intApplicationFolderRSN 

   RETURN ISNULL(@varAgendaSection, ' ')
END

GO
