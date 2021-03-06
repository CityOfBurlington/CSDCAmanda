USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Update_Agenda_Log_ZM_Folder]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Update_Agenda_Log_ZM_Folder] (@intFolderRSN int)
AS
BEGIN 
   /* Updates Zoning Meeting Agenda (ZM) log to Folder.FolderDescription 
      based upon FolderInfo FolderRSN values. */
   /* Since InfoCodes may be nonsequential owing to deletes, looping 
      to select FolderRSN values is based upon FolderInfo.DisplayOrder. 
      Therefore dbo.Zoning_Order_FolderInfo_ZM_Folder MUST be run 
      prior to this procedure. */

   DECLARE @intGroupLoopCounter int 
   DECLARE @varInfoGroup varchar(40)
   DECLARE @intMinInfoCode int
   DECLARE @intMaxInfoCode int
   DECLARE @varFirstEntryFlag varchar(2)
   DECLARE @varOtherBizTextEntryFlag varchar(2)
   DECLARE @intFolderInfoCount int 
   DECLARE @intFolderInfoLoopCounter int
   DECLARE @intMaxDisplayOrder int 
   DECLARE @intExpectedDisplayOrderCount int 
   DECLARE @intInfoCode int 
   DECLARE @intAppFolderRSN int
   DECLARE @varZPNumber varchar(20)
   DECLARE @varPropertyAddress varchar(100) 
   DECLARE @varLogEntry varchar(500) 

   /* Loop through FolderRSNs and write rows for the applications */

   SET @intGroupLoopCounter = 1        /* Consent items */
   SET @intMinInfoCode = 10082 
   SET @intMaxInfoCode = 10091
   SET @varFirstEntryFlag = 'Y'        /* First line written */
   SET @varOtherBizTextEntryFlag = 'N' /* Other Business text items */

   WHILE @intGroupLoopCounter < 6      /* There are 5 InfoGroups */
   BEGIN 
      SELECT @varInfoGroup = 
      CASE @intGroupLoopCounter 
         WHEN 1 THEN 'Consent:'
         WHEN 2 THEN 'Public Hearing:'
         WHEN 3 THEN 'Certificate of Appropriateness:'
         WHEN 4 THEN 'Sketch Plan Review:'
         WHEN 5 THEN 'Other Business:' 
      END

      SELECT @intFolderInfoCount = COUNT(*) 
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode BETWEEN @intMinInfoCode AND @intMaxInfoCode 

      IF @intFolderInfoCount > 0 
      BEGIN 
         IF @varFirstEntryFlag = 'Y' 
         BEGIN
            UPDATE Folder 
               SET Folder.FolderDescription = @varInfoGroup 
             WHERE Folder.FolderRSN = @intFolderRSN 

            SELECT @varFirstEntryFlag = 'N'
         END
         ELSE 
         BEGIN
            UPDATE Folder 
               SET Folder.FolderDescription = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000), Folder.FolderDescription)) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + @varInfoGroup))
             WHERE Folder.FolderRSN = @intFolderRSN 
         END

         SELECT @intFolderInfoLoopCounter = 1 

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

               SELECT @intAppFolderRSN = FolderInfo.InfoValueNumeric
                 FROM FolderInfo 
                WHERE FolderInfo.FolderRSN = @intFolderRSN 
                  AND FolderInfo.InfoCode = @intInfoCode 

               /* Only Other Business text items allow @intAppFolderRSN = @intFolderRSN.
                  Pull from FolderCondition occurs once. */

               IF ( @intAppFolderRSN = @intFolderRSN AND @varOtherBizTextEntryFlag = 'N' ) 
               BEGIN
                  SELECT @varLogEntry = Folder.FolderCondition 
                    FROM Folder 
                   WHERE Folder.FolderRSN = @intFolderRSN 

                  UPDATE Folder 
                     SET Folder.FolderDescription = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000), Folder.FolderDescription)) + CHAR(13) + CHAR(10) + @varLogEntry))
                   WHERE Folder.FolderRSN = @intFolderRSN 
 
                  SELECT @varOtherBizTextEntryFlag = 'Y'
               END

               IF @intAppFolderRSN <> @intFolderRSN 
               BEGIN 
                  SELECT @varZPNumber = Folder.ReferenceFile,  
                         @varPropertyAddress = Folder.FolderName 
                    FROM Folder 
                   WHERE Folder.FolderRSN = @intAppFolderRSN 

                  SELECT @varLogEntry = CAST(@intFolderInfoLoopCounter AS VARCHAR) + '. ' + @varPropertyAddress + ' (' + @varZPNumber + ')' 

                  UPDATE Folder 
                     SET Folder.FolderDescription = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000), Folder.FolderDescription)) + CHAR(13) + CHAR(10) + @varLogEntry))
                   WHERE Folder.FolderRSN = @intFolderRSN 
               END
            END

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
