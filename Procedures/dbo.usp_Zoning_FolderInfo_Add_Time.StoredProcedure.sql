USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_FolderInfo_Add_Time]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_FolderInfo_Add_Time] (@intFolderRSN int, @intInfoCode int)
AS
BEGIN 
   DECLARE @intHour int

   /* Meeting Date Info fields - add regular meeting time */
   IF @intInfoCode IN (10001, 10003, 10007, 10009, 10017)  
   BEGIN 
      SELECT @intHour = 
      CASE @intInfoCode
         WHEN 10001 THEN 17   /* DRB Board Meeting Date */
         WHEN 10003 THEN 15   /* DAB Board Meeting Date */
         WHEN 10007 THEN 17   /* CB Board Meeting Date */
         WHEN 10009 THEN 20   /* DRB Public Hearing Closed Date */
         WHEN 10017 THEN 16   /* DRB Deliberative Meeting Date */
         ELSE 0  
      END

      UPDATE FolderInfo
         SET FolderInfo.InfoValueDateTime = DATEADD(hour, @intHour, FolderInfo.InfoValueDateTime)
        FROM FolderInfo
       WHERE FolderInfo.FolderRSN = @intFolderRSN
         AND FolderInfo.InfoCode = @intInfoCode

      IF @intInfoCode = 10007
      BEGIN
         UPDATE FolderInfo
            SET FolderInfo.InfoValueDateTime = DATEADD(minute, 30, FolderInfo.InfoValueDateTime)
           FROM FolderInfo
          WHERE FolderInfo.FolderRSN = @intFolderRSN
            AND FolderInfo.InfoCode = @intInfoCode
      END
   END
   ELSE   /* Other FolderInfo date fields - add current time */
   BEGIN
      UPDATE FolderInfo
         SET FolderInfo.InfoValueDateTime = DATEADD(hour, datepart(hour, getdate()), FolderInfo.InfoValueDateTime)
       WHERE FolderInfo.FolderRSN = @intFolderRSN
         AND FolderInfo.InfoCode = @intInfoCode

      UPDATE FolderInfo
         SET FolderInfo.InfoValueDateTime = DATEADD(minute, datepart(minute, getdate()), FolderInfo.InfoValueDateTime)
       WHERE FolderInfo.FolderRSN = @intFolderRSN
         AND FolderInfo.InfoCode = @intInfoCode
   END
END


GO
