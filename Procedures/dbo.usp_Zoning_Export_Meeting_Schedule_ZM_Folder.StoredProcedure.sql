USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Export_Meeting_Schedule_ZM_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Export_Meeting_Schedule_ZM_Folder] (@intYear int)
AS
BEGIN 
SELECT dbo.udf_GetZoningAgendaBoardExport(Folder.FolderRSN) AS Board, 
       Folder.IssueDate AS MeetingDate, 
       Folder.ExpiryDate AS DeadlineRegDate, 
       Folder.FinalDate AS DeadlinePHDate, 
       dbo.udf_GetZoningAgendaLocationRoomExport(Folder.FolderRSN) AS Location, 
       dbo.udf_GetZoningAgendaLocationStreetExport(Folder.FolderRSN) AS Street, 
       getdate() AS StampDate, 
       'jappleton' AS StampUser
  FROM Folder 
 WHERE Folder.FolderType = 'ZM' 
   AND DATEPART(year, Folder.IssueDate) = @intYear 
ORDER BY Board, MeetingDate
END

GO
