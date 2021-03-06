USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_FolderProcessInfo_Add_Time]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_FolderProcessInfo_Add_Time] (@intProcessRSN int, @intInfoCode int)
AS
BEGIN 
   DECLARE @intHour int

   /* Meeting Date FolderProcessInfo fields - add regular meeting time */
   IF @intInfoCode IN (10004, 10005, 10006)
   BEGIN 
      SELECT @intHour = 
      CASE @intInfoCode
         WHEN 10004 THEN 17   /* DRB Board Meeting Date */
         WHEN 10005 THEN 20   /* DRB Public Hearing Closed Date */
         WHEN 10006 THEN 16   /* DRB Deliberative Meeting Date */
         ELSE 0  
      END

      UPDATE FolderProcessInfo
         SET FolderProcessInfo.InfoValueDateTime = DATEADD(hour, @intHour, FolderProcessInfo.InfoValueDateTime)
       WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN
         AND FolderProcessInfo.InfoCode = @intInfoCode
   END

   ELSE   /* Other FolderProcessInfo date fields - add current time */

   BEGIN
      UPDATE FolderProcessInfo
         SET FolderProcessInfo.InfoValueDateTime = DATEADD(hour, datepart(hour, getdate()), FolderProcessInfo.InfoValueDateTime)
       WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN
         AND FolderProcessInfo.InfoCode = @intInfoCode

      UPDATE FolderProcessInfo
         SET FolderProcessInfo.InfoValueDateTime = DATEADD(minute, datepart(minute, getdate()), FolderProcessInfo.InfoValueDateTime)
       WHERE FolderProcessInfo.ProcessRSN = @intProcessRSN
         AND FolderProcessInfo.InfoCode = @intInfoCode
   END
END


GO
