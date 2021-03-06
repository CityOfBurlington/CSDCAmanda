USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaItemOrder]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaItemOrder](@intAgendaFolderRSN INT, @intApplicationFolderRSN INT) 
RETURNS int
AS 
BEGIN
   /* Returns the agenda item order (FolderInfo.DisplayOrder) for ordering Infomaker meeting_agenda */

   DECLARE @intApplicationItemOrder int

   SELECT @intApplicationItemOrder = ISNULL(FolderInfo.DisplayOrder, 0)
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intAgendaFolderRSN 
      AND FolderInfo.InfoValueNumeric = @intApplicationFolderRSN 

   RETURN @intApplicationItemOrder 
END

GO
