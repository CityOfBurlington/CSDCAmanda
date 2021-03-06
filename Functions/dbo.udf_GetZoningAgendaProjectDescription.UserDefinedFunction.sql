USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaProjectDescription]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaProjectDescription](@intAgendaFolderRSN INT, @intApplicationFolderRSN INT) 
RETURNS varchar(1000)
AS 
BEGIN
   /* Creates second line of a zoning agenda item for Infomaker meeting_agenda */
   /* Probable Bug in Amanda:  When the Folder.FolderDescription is long (>200 
      charcacters), the last few letters are truncated when pulled by 
      dbo.udf_GetZoningAgendaProjectDescription. The function works correctly in 
      SQL Server Management Express, but not in Amanda&#039;s Quick and Simple, 
      and Infomaker forms. The variables in the function are of adequate size. */

   DECLARE @intApplicationFolderStatus int
   DECLARE @intApplicationReviewType int 
   DECLARE @varProjectDesc varchar(800)
   DECLARE @intProjectDescLength int
   DECLARE @intApplicationDecision int 
   DECLARE @varAppealText varchar(100) 
   DECLARE @varProjectManager varchar(20)
   DECLARE @varProjectFullDesc varchar(1000)

   IF @intAgendaFolderRSN = @intApplicationFolderRSN
   BEGIN
      SELECT @varProjectDesc = Folder.FolderCondition
        FROM Folder
       WHERE Folder.FolderRSN = @intAgendaFolderRSN 

      SELECT @varProjectFullDesc = RTRIM(@varProjectDesc)
   END
   ELSE 
   BEGIN
      SELECT @intApplicationFolderStatus = Folder.StatusCode, 
             @intApplicationReviewType = Folder.SubCode, 
             @varProjectDesc = Folder.FolderDescription 
        FROM Folder 
       WHERE Folder.FolderRSN = @intApplicationFolderRSN 

      IF @intApplicationFolderStatus IN (10009, 10020, 20021) AND @intApplicationReviewType = 10041 
      BEGIN
         SELECT @intApplicationDecision = dbo.udf_GetZoningDecisionAttemptCode(@intApplicationFolderRSN) 

         SELECT @varAppealText = 
         CASE @intApplicationDecision 
            WHEN 10002 THEN 'Appeal of administrative permit denial to'
            WHEN 10003 THEN 'Appeal of administrative permit approval to'
            WHEN 10011 THEN 'Appeal of administrative permit approval to'
            WHEN 10017 THEN 'Appeal of administrative permit applicability determination to'
            WHEN 10018 THEN 'Appeal of administrative permit applicability determination to'
            WHEN 10020 THEN 'Appeal of administrative permit denial to'
            WHEN 10046 THEN 'Appeal of administrative affirmative determination to'
            WHEN 10047 THEN 'Appeal of administrative adverse determination to' 
            ELSE ''
         END

         SELECT @intProjectDescLength = LEN(@varProjectDesc) 
         SELECT @varProjectDesc = LOWER(SUBSTRING(@varProjectDesc, 1, 1)) + SUBSTRING(@varProjectDesc, 2, (@intProjectDescLength - 1))

         SELECT @varProjectDesc = @varAppealText + ' ' + @varProjectDesc 
      END 

      SELECT @varProjectManager = ISNULL(dbo.f_info_alpha_null(@intApplicationFolderRSN, 10068), 'TBD')

      SELECT @varProjectFullDesc = RTRIM(@varProjectDesc) + ' (Project Manager: ' +
                                   RTRIM(@varProjectManager) + ')' 
   END 

   RETURN ISNULL(@varProjectFullDesc, ' ')
END

GO
