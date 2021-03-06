USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_ZM]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_ZM]
@FolderRSN numeric(10), @UserId char(128), @InfoCode int
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* ZM Info Validation - Checks linked folders for validity, and adds Info fields */

IF @InfoCode BETWEEN 10082 AND 10119     /* FolderRSN fields for InfoGroups */
BEGIN
   DECLARE @intMeetingFolderStatus int
   DECLARE @varFolderDescription varchar(10)
   DECLARE @intAppFolderRSN int
   DECLARE @varAppFolderType varchar(4)
   DECLARE @intAppFolderStatus int
   DECLARE @intDuplicateRSNFlag int 
   DECLARE @varPublicHearingFlag varchar(2)
   DECLARE @intDisplayOrder int
   DECLARE @intDisplayOrderCount int
   DECLARE @intMinInfoCode int
   DECLARE @intMaxInfoCode int
   DECLARE @intFolderInfoTextCount int
   DECLARE @intNextInfoCode int
   DECLARE @intNextDisplayOrder int
   DECLARE @varLogEntry varchar(500)
   DECLARE @varOtherBizEntry varchar(500)
   DECLARE @varFolderCondition varchar(500)

   SELECT @intMeetingFolderStatus = Folder.StatusCode, 
          @varFolderDescription = Folder.FolderDescription 
     FROM Folder 
    WHERE Folder.FolderRSN = @FolderRSN 

   IF @intMeetingFolderStatus = 10053     /* Meeting Held */
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('The agenda is closed: Item updates are not allowed.', 16, -1)
      RETURN
   END

   SELECT @intAppFolderRSN = ISNULL(FolderInfo.InfoValueNumeric, 0) 
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

/* IF @intAppFolderRSN = 0
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Blank or zero FolderRSN value entered. Please enter a valid FolderRSN.', 16, -1)
      RETURN
   END   */

   IF @intAppFolderRSN > 0
   BEGIN 
      SELECT @intDuplicateRSNFlag = COUNT(*)
        FROM FolderInfo
       WHERE FolderInfo.InfoValueNumeric = @intAppFolderRSN
         AND FolderInfo.InfoValue IS NOT NULL 
         AND FolderInfo.FolderRSN = @FolderRSN
         AND FolderInfo.InfoCode BETWEEN 10082 AND 10119 

      IF ( @intDuplicateRSNFlag > 1 ) AND ( @intAppFolderRSN <> @FolderRSN ) 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Duplicate application FolderRSN entered. Please enter a unique FolderRSN.', 16, -1)
         RETURN
      END 

      IF ( @intAppFolderRSN = @FolderRSN ) AND ( @InfoCode NOT IN (10115, 10116, 10117, 10118, 10119) ) 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('The Agenda FolderRSN may be entered only under Other Business. Please correct.', 16, -1)
         RETURN
      END

      SELECT @varAppFolderType = ISNULL(Folder.FolderType, 'X'),  
             @intAppFolderStatus = ISNULL(Folder.StatusCode, 0) 
        FROM Folder
       WHERE Folder.FolderRSN = @intAppFolderRSN 

      IF @varAppFolderType = 'X' 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Invalid FolderRSN - No folder found. Please  re-enter FolderRSN.', 16, -1)
         RETURN
      END

      IF @varAppFolderType NOT LIKE 'Z%'
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('FolderRSN is not for a zoning folder. Please re-enter FolderRSN.', 16, -1)
         RETURN
      END

      SELECT @varPublicHearingFlag = dbo.udf_ZoningPublicHearingFlag(@intAppFolderRSN) 

      IF ( @varPublicHearingFlag <> 'Y' ) AND ( @InfoCode BETWEEN 10092 AND 10101 ) 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Only applications requiring Public Hearing notice are allowed under Public Hearing. Please re-enter FolderRSN.', 16, -1)
         RETURN
      END 

      IF ( @varAppFolderType <> 'ZS' ) AND ( @InfoCode BETWEEN 10112 AND 10114 ) 
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Only Sketch Plan reviews are allowed. Please re-enter FolderRSN.', 16, -1)
         RETURN
      END

      IF @intAppFolderStatus IN (10010, 10023, 10024, 10028, 10031, 10037)
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Zoning applications or permits that are Withdrawn, Revoked, Relinquished, Superceded, or Expired are ineligible. Please re-enter FolderRSN.', 16, -1)
         RETURN
      END
   END

   /* If program flow made it to here, the FolderRSN is valid, add the next Info 
      field where appropriate. */

   /* Check FolderInfo.DisplayOrders for uniqueness */

   SELECT @intDisplayOrder = FolderInfo.DisplayOrder
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode = @InfoCode 

   IF @intDisplayOrder = 0 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Info Display Order of zero (0) is not allowed. Please reset the Display Order or exit.', 16, -1)
      RETURN
   END

   SELECT @intMinInfoCode = 
     CASE @InfoCode 
        WHEN 10082 THEN 10082
        WHEN 10083 THEN 10082
        WHEN 10084 THEN 10082
        WHEN 10085 THEN 10082
        WHEN 10086 THEN 10082
        WHEN 10087 THEN 10082
        WHEN 10088 THEN 10082
        WHEN 10089 THEN 10082
        WHEN 10090 THEN 10082
        WHEN 10091 THEN 10082
        WHEN 10092 THEN 10092
        WHEN 10093 THEN 10092
        WHEN 10094 THEN 10092
        WHEN 10095 THEN 10092
        WHEN 10096 THEN 10092
        WHEN 10097 THEN 10092
        WHEN 10098 THEN 10092
        WHEN 10099 THEN 10092
        WHEN 10100 THEN 10092
        WHEN 10101 THEN 10092
        WHEN 10102 THEN 10102
        WHEN 10103 THEN 10102
        WHEN 10104 THEN 10102
        WHEN 10105 THEN 10102
        WHEN 10106 THEN 10102
        WHEN 10107 THEN 10102
        WHEN 10108 THEN 10102
        WHEN 10109 THEN 10102
        WHEN 10110 THEN 10102
        WHEN 10111 THEN 10102
        WHEN 10112 THEN 10112
        WHEN 10113 THEN 10112
        WHEN 10114 THEN 10112
        WHEN 10115 THEN 10115
        WHEN 10116 THEN 10115
        WHEN 10117 THEN 10115
        WHEN 10118 THEN 10115
        WHEN 10119 THEN 10115
        ELSE 0
     END 

   SELECT @intMaxInfoCode = 
     CASE @InfoCode 
        WHEN 10082 THEN 10091
        WHEN 10083 THEN 10091
        WHEN 10084 THEN 10091
        WHEN 10085 THEN 10091
        WHEN 10086 THEN 10091
        WHEN 10087 THEN 10091
        WHEN 10088 THEN 10091
        WHEN 10089 THEN 10091
        WHEN 10090 THEN 10091
        WHEN 10091 THEN 10091
        WHEN 10092 THEN 10101
        WHEN 10093 THEN 10101
        WHEN 10094 THEN 10101
        WHEN 10095 THEN 10101
        WHEN 10096 THEN 10101
        WHEN 10097 THEN 10101
        WHEN 10098 THEN 10101
        WHEN 10099 THEN 10101
        WHEN 10100 THEN 10101
        WHEN 10101 THEN 10101
        WHEN 10102 THEN 10111
        WHEN 10103 THEN 10111
        WHEN 10104 THEN 10111
        WHEN 10105 THEN 10111
        WHEN 10106 THEN 10111
        WHEN 10107 THEN 10111
        WHEN 10108 THEN 10111
        WHEN 10109 THEN 10111
        WHEN 10110 THEN 10111
        WHEN 10111 THEN 10111
        WHEN 10112 THEN 10114
        WHEN 10113 THEN 10114
        WHEN 10114 THEN 10114
        WHEN 10115 THEN 10119
        WHEN 10116 THEN 10119
        WHEN 10117 THEN 10119
        WHEN 10118 THEN 10119
        WHEN 10119 THEN 10119
        ELSE 0
     END 

   SELECT @intDisplayOrderCount = COUNT(*)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCOde BETWEEN @intMinInfoCode AND @intMaxInfoCode 
      AND FolderInfo.DisplayOrder = @intDisplayOrder 

   IF @intDisplayOrderCount > 1 
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Info Display Order is not unique. Please reset the Display Order or exit.', 16, -1)
      RETURN
   END

   IF @intMeetingFolderStatus IN (10049, 10050, 10051) 
   BEGIN
      IF @intAppFolderRSN = @FolderRSN 
      BEGIN 
         SELECT @intFolderInfoTextCount = COUNT(*) 
           FROM FolderInfo 
          WHERE FolderInfo.FolderRSN = @FolderRSN 
            AND FolderInfo.InfoCode BETWEEN 10120 AND 10122

         IF @intFolderInfoTextCount = 0 
         BEGIN
            SELECT @intNextInfoCode = 10120 
            SELECT @intNextDisplayOrder = 6 
         END 
         ELSE 
         BEGIN
            SELECT @intNextInfoCode = ( MAX(FolderInfo.InfoCode) + 1 ), 
                   @intNextDisplayOrder = ( MAX(FolderInfo.DisplayOrder) + 1 ) 
              FROM FolderInfo 
             WHERE FolderInfo.FolderRSN = @FolderRSN 
               AND FolderInfo.InfoCode BETWEEN 10120 AND 10122 
         END

         IF @intNextInfoCode IN (10120, 10121, 10122)
         BEGIN
            INSERT INTO FolderInfo
                    ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                      StampDate, StampUser, Mandatory, ValueRequired )
             VALUES ( @FolderRSN, @intNextInfoCode,  @intNextDisplayOrder, 'Y', 
                      getdate(), @UserID, 'N', 'N' ) 
         END 
      END 
      ELSE 
         EXECUTE dbo.usp_Zoning_Insert_FolderInfo_ZM_Folder @FolderRSN , @UserID 
   END

   /* Set ZM folder status to Agenda Active if needed. */

   UPDATE Folder 
      SET Folder.StatusCode = 10050
    WHERE Folder.FolderRSN = @FolderRSN 
      AND Folder.StatusCode = 10049 

   /* Add Application Address to the log in Folder.FolderDescription for the 
      White Board. */

   SELECT @varLogEntry = dbo.udf_GetPropertyAddressLong(@intAppFolderRSN) 

   IF @varFolderDescription = NULL 
   BEGIN
      UPDATE Folder 
         SET Folder.FolderDescription = @varLogEntry, 
             Folder.IssueUser = @UserID 
       WHERE Folder.FolderRSN = @FolderRSN 
   END
   ELSE
   BEGIN 
      UPDATE Folder 
         SET Folder.FolderDescription = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000), Folder.FolderDescription)) + CHAR(13) + CHAR(10) + @varLogEntry)), 
             Folder.IssueUser = @UserID 
       WHERE Folder.FolderRSN = @FolderRSN 
   END

   /* Issue confirmation to user - not used 

   COMMIT
   RAISERROR('CSDCWARNING: Application FolderRSN accepted: Continue.', 16, -1) */

END

IF @InfoCode BETWEEN 10120 AND 10122     /* Text item fields under Other Business */
BEGIN
   SELECT @varOtherBizEntry = FolderInfo.InfoValue 
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode = @InfoCode

   SELECT @varFolderCondition = Folder.FolderCondition 
     FROM Folder
    WHERE Folder.FolderRSN = @FolderRSN

   IF ( @varFolderCondition IS NULL OR @InfoCode = 10120 ) 
   BEGIN 
      UPDATE Folder 
         SET Folder.FolderCondition = @varOtherBizEntry
       WHERE Folder.FolderRSN = @FolderRSN 
   END 
   ELSE
   BEGIN
      UPDATE Folder 
         SET Folder.FolderCondition = CONVERT(TEXT,(RTRIM(CONVERT(VARCHAR(2000), Folder.FolderCondition)) + CHAR(13) + CHAR(10) + @varOtherBizEntry))
       WHERE Folder.FolderRSN = @FolderRSN 
   END
END

GO
