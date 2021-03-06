USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaGroupOrder]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaGroupOrder](@intAgendaFolderRSN INT, @intApplicationFolderRSN INT) 
RETURNS int
AS 
BEGIN
   /* Returns the agenda item group order (ValidInfo.InfoGroupDisplayOrder) 
      for ordering InfoGroups for Infomaker meeting_agenda */

   DECLARE @intAgendaSectionOrder int

   SELECT @intAgendaSectionOrder = ISNULL(ValidInfo.InfoGroupDisplayOrder, 0)
     FROM ValidInfo, FolderInfo 
    WHERE FolderInfo.FolderRSN = @intAgendaFolderRSN 
      AND FolderInfo.InfoCode = ValidInfo.InfoCode 
      AND FolderInfo.InfoValueNumeric = @intApplicationFolderRSN 

   RETURN @intAgendaSectionOrder 
END

GO
