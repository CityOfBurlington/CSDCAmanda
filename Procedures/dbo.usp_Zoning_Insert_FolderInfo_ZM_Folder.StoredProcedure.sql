USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_FolderInfo_ZM_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_FolderInfo_ZM_Folder] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
   /* Adds Zoning Meeting Agenda (ZM) folder Info fields for FolderRSNs. */

   DECLARE @intSubCodeBoard int
   DECLARE @intLoopCounter int
   DECLARE @intMinInfoCode int 
   DECLARE @intMaxInfoCode int 
   DECLARE @intFolderInfoCount int
   DECLARE @intFolderInfoValue int
   DECLARE @varNullFolderRSNFlag varchar(2)
   DECLARE @intNextInfoCode int
   DECLARE @intNextDisplayOrder int 

   SELECT @intSubCodeBoard = Folder.SubCode 
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN

   SET @intLoopCounter = 1        /* Consent items */
   SET @intMinInfoCode = 10082 
   SET @intMaxInfoCode = 10091

   WHILE @intLoopCounter < 6      /* There are 5 InfoGroups */
   BEGIN 
      SELECT @intFolderInfoCount = COUNT(*) 
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 

      IF @intFolderInfoCount = 0 
      BEGIN
         SELECT @intNextInfoCode = @intMinInfoCode 
         SELECT @intNextDisplayOrder = 1 
         SELECT @varNullFolderRSNFlag = 'N' 
      END
      ELSE
      BEGIN 
         SELECT @intFolderInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0)
           FROM FolderInfo 
          WHERE FolderInfo.FolderRSN = @intFolderRSN 
            AND FolderInfo.InfoCode = 
              ( SELECT MAX(FolderInfo.InfoCode) 
                  FROM FolderInfo 
                 WHERE FolderInfo.FolderRSN = @intFolderRSN 
                   AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode  ) 

         IF @intFolderInfoValue > 0 SELECT @varNullFolderRSNFlag = 'N' 
         ELSE SELECT @varNullFolderRSNFlag = 'Y' 

         SELECT @intNextInfoCode = ( MAX(FolderInfo.InfoCode) + 1 ), 
                @intNextDisplayOrder = ( MAX(FolderInfo.DisplayOrder) + 1 ) 
           FROM FolderInfo 
          WHERE FolderInfo.FolderRSN = @intFolderRSN 
            AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 
      END

      IF @intLoopCounter IN (1, 2) AND @intSubCodeBoard = 10049    /* Consent, PH - DRB */
      BEGIN 
         IF ( @varNullFolderRSNFlag = 'N' AND @intNextInfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode  )
         BEGIN
            INSERT INTO FolderInfo
                    ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                      StampDate, StampUser, Mandatory, ValueRequired )
             VALUES ( @intFolderRSN, @intNextInfoCode,  @intNextDisplayOrder, 'Y', 
                      getdate(), @varUserID, 'N', 'N' ) 
         END
      END 

      IF @intLoopCounter IN (3, 4, 5)          /* COA, Sketch, Other Biz - all boards */
      BEGIN 
         IF ( @varNullFolderRSNFlag = 'N' AND @intNextInfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode  )
         BEGIN
            INSERT INTO FolderInfo
                    ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                      StampDate, StampUser, Mandatory, ValueRequired )
             VALUES ( @intFolderRSN, @intNextInfoCode,  @intNextDisplayOrder, 'Y', 
                      getdate(), @varUserID, 'N', 'N' ) 
         END
      END 

      SELECT @intLoopCounter = @intLoopCounter + 1 

      IF @intLoopCounter = 2             /* Public Hearing */
      BEGIN
         SELECT @intMinInfoCode = 10092 
         SELECT @intMaxInfoCode = 10101
      END
      IF @intLoopCounter = 3             /* Certificate of Appropriateness */
      BEGIN
         SELECT @intMinInfoCode = 10102 
         SELECT @intMaxInfoCode = 10111
      END
      IF @intLoopCounter = 4             /* Sketch Plan */
      BEGIN
         SELECT @intMinInfoCode = 10112 
         SELECT @intMaxInfoCode = 10114
      END
      IF @intLoopCounter = 5             /* Other Business */
      BEGIN
         SELECT @intMinInfoCode = 10115 
         SELECT @intMaxInfoCode = 10119
      END
   END
END

GO
