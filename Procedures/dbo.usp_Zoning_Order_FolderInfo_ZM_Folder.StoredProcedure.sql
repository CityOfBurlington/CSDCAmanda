USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Order_FolderInfo_ZM_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Order_FolderInfo_ZM_Folder] (@intFolderRSN int)
AS
BEGIN 
   /* Makes FolderInfo.DisplayOrder sequential Zoning Meeting Agenda (ZM) folder FolderRSN fields. */

   DECLARE @intBoard int
   DECLARE @intMeetingType int
   DECLARE @intGroupLoopCounter int
   DECLARE @intMinInfoCode int
   DECLARE @intMaxInfoCode int
   DECLARE @intFolderInfoCount int 
   DECLARE @intFolderInfoLoopCounter int
   DECLARE @intExpectedDisplayOrderCount int
   DECLARE @intInfoCode int 
   DECLARE @intDisplayOrderDelta int
   DECLARE @intMaxDisplayOrder int

   SELECT @intBoard = Folder.SubCode 
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN 

   SET @intGroupLoopCounter = 1        /* Consent items */
   SET @intMinInfoCode = 10082 
   SET @intMaxInfoCode = 10091

   WHILE @intGroupLoopCounter < 6      /* There are 5 InfoGroups */
   BEGIN 
      SELECT @intFolderInfoCount = COUNT(*) 
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 

      IF @intFolderInfoCount > 0 
      BEGIN 
         SELECT @intFolderInfoLoopCounter = 1 
         SELECT @intDisplayOrderDelta = 0 

         SELECT @intMaxDisplayOrder = MAX(FolderInfo.DisplayOrder)
           FROM FolderInfo 
          WHERE FolderInfo.FolderRSN = @intFolderRSN 
            AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 

         WHILE @intFolderInfoLoopCounter < ( @intMaxDisplayOrder + 1 )
         BEGIN 
            SELECT @intExpectedDisplayOrderCount = COUNT(*)
              FROM FolderInfo 
             WHERE FolderInfo.FolderRSN = @intFolderRSN 
               AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 
               AND FolderInfo.DisplayOrder = @intFolderInfoLoopCounter 

            IF @intExpectedDisplayOrderCount > 0 
            BEGIN
               SELECT @intInfoCode = FolderInfo.InfoCode
                 FROM FolderInfo 
                WHERE FolderInfo.FolderRSN = @intFolderRSN 
                  AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 
                  AND FolderInfo.DisplayOrder = @intFolderInfoLoopCounter 

               UPDATE FolderInfo
                  SET FolderInfo.DisplayOrder = ( @intFolderInfoLoopCounter - @intDisplayOrderDelta ), 
                      FolderInfo.StampDate = getdate() 
                WHERE FolderInfo.FolderRSN = @intFolderRSN 
                  AND FolderInfo.InfoCode = @intInfoCode 
            END

            IF @intExpectedDisplayOrderCount = 0 
               SELECT @intDisplayOrderDelta = @intDisplayOrderDelta + 1 

            SELECT @intFolderInfoLoopCounter = @intFolderInfoLoopCounter + 1 

         END /* End of WHILE Loop for @intFolderInfoLoopCounter */
      END    /* End of @intFolderInfoCount > 0 */

      SELECT @intGroupLoopCounter = @intGroupLoopCounter + 1 

      IF @intGroupLoopCounter = 2             /* Public Hearing */
      BEGIN
         SELECT @intMinInfoCode = 10092 
         SELECT @intMaxInfoCode = 10101
      END
      IF @intGroupLoopCounter = 3             /* Certificate of Appropriateness */
      BEGIN
         SELECT @intMinInfoCode = 10102 
         SELECT @intMaxInfoCode = 10111
      END
      IF @intGroupLoopCounter = 4             /* Sketch Plan */
      BEGIN
         SELECT @intMinInfoCode = 10112 
         SELECT @intMaxInfoCode = 10114
      END
      IF @intGroupLoopCounter = 5             /* Other Business */
      BEGIN
         SELECT @intMinInfoCode = 10115 
         SELECT @intMaxInfoCode = 10119
      END

   END  /* End of WHILE @intGroupLoopCounter loop */
END

GO
