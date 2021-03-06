USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultInfo_UC]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultInfo_UC]
@FolderRSN int, @UserId char(128), @InfoCode int
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

/* Info Validation for Permit FolderRSNs, TCO fields */

/* September 2012 - Types of checks for zoning folders reduced in anticipation of
   the UCO becoming used as a Certificate of Compliance for a project. Thus the 
   types of folders allowed should not be limited to those that receive CO, such 
   as Non-Applicabilities and Preliminary Plats. */

IF @InfoCode IN (23032, 23033, 23034)    /* TCO Decision Date, TCO Expiration Date, TCO Conditions Date */
BEGIN
   UPDATE FolderInfo
      SET FolderInfo.InfoValueDateTime = DATEADD(hour, datepart(hour, getdate()), FolderInfo.InfoValueDateTime)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   UPDATE FolderInfo
      SET FolderInfo.InfoValueDateTime = DATEADD(minute, datepart(minute, getdate()), FolderInfo.InfoValueDateTime)
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode
END

IF @InfoCode BETWEEN 23001 AND 23020     /* FolderRSN fields */
BEGIN
   DECLARE @PermitFolderRSNValue int
   DECLARE @FolderType varchar(2)
   DECLARE @FolderStatus int
   DECLARE @ZPNumber varchar(15)
   DECLARE @SubCode int
   DECLARE @WorkCode int
   DECLARE @IssueDate datetime
   DECLARE @PermitDescription varchar(500)
   DECLARE @FolderTypeDesc varchar(30)
   DECLARE @ZoningDecision varchar(30)
   DECLARE @ZPPhaseNumberInfoValue int
   DECLARE @BPCOProcessCount int
   DECLARE @BPCOProcessAttemptResult int
   DECLARE @UCPhaseNumberDefault int
   DECLARE @UCOccupancyLoadInfoCount int 
   DECLARE @UCOccupancyLoadInfoCode int
   DECLARE @BPOccupancyLoadInfoCount int 
   DECLARE @BPOccupancyLoadInfoValue int
   DECLARE @NullPermitRSNFlag int
   DECLARE @ValidPermitFlag varchar(1)
   DECLARE @DuplicateRSNFlag int
   DECLARE @varUserMessage varchar(200)

   SELECT @ValidPermitFlag = 'Y'

   SELECT @PermitFolderRSNValue = FolderInfo.InfoValueNumeric, 
          @NullPermitRSNFlag = FolderInfo.InfoValue
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode = @InfoCode

   SELECT @UCOccupancyLoadInfoCode = COUNT(*)
  FROM FolderInfo
    WHERE FolderInfo.InfoCode = 23030
      AND FolderInfo.FolderRSN = @FolderRSN

   SELECT @DuplicateRSNFlag = COUNT(*)
     FROM FolderInfo
    WHERE FolderInfo.InfoValueNumeric = @PermitFolderRSNValue
      AND FolderInfo.InfoValue IS NOT NULL 
      AND FolderInfo.FolderRSN = @FolderRSN
      AND FolderInfo.InfoCode BETWEEN 23001 AND 23020 

   SELECT @FolderType = ISNULL(Folder.FolderType, 'X'),  
          @FolderStatus = ISNULL(Folder.StatusCode, 0), 
          @ZPNumber = Folder.ReferenceFile, 
          @SubCode = ISNULL(Folder.SubCode, 0), 
          @WorkCode = ISNULL(Folder.WorkCode, 0), 
          @IssueDate = Folder.IssueDate, 
          @PermitDescription = Folder.FolderDescription
     FROM Folder
    WHERE Folder.FolderRSN = @PermitFolderRSNValue

   IF @DuplicateRSNFlag > 1
   BEGIN
      ROLLBACK TRANSACTION
      RAISERROR ('Duplicate FolderRSN entered. Please enter a unique FolderRSN.', 16, -1)
      RETURN
   END

   IF @NullPermitRSNFlag IS NOT NULL 
   BEGIN
      IF @FolderType = 'X' 
      BEGIN
         SELECT @ValidPermitFlag = 'N'
         ROLLBACK TRANSACTION
         RAISERROR ('Invalid FolderRSN - No folder found. Please re-enter FolderRSN.', 16, -1)
         RETURN
      END
      ELSE 
      BEGIN
         SELECT @FolderTypeDesc = ValidFolder.FolderDesc
           FROM ValidFolder
          WHERE ValidFolder.FolderType = @FolderType
      END

      IF @FolderType NOT IN ('BP','EP','MP','Z1','Z2','Z3','ZA','ZB','ZC','ZF','ZH','ZN','ZZ')
      BEGIN
         SELECT @ValidPermitFlag = 'N'
  ROLLBACK TRANSACTION
         RAISERROR ('Folder type is ineligible for Unified Certificate of Occupancy. Please re-enter FolderRSN.', 16, -1)
         RETURN
      END

      IF @FolderType IN ('Z1', 'Z2', 'Z3', 'ZA', 'ZB', 'ZC', 'ZF', 'ZH', 'ZN', 'ZZ') 
      BEGIN
         SELECT @ZoningDecision = dbo.udf_GetZoningPermitDecisionCode(@PermitFolderRSNValue)
         IF @ZoningDecision IN (10002, 10020) AND @FolderType <> 'ZN'  /* Denials */
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('Denied Zoning Permit applications are ineligible for Certificates of Occupancy. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END

      /* IF @FolderType = 'Z3' AND @WorkCode = 10009
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('Preliminary Plats are ineligible for Certificates of Occupancy. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END  */

         IF @FolderStatus IN (10010, 10023, 10024, 10028, 10031, 10037)
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('Zoning permits that are Withdrawn, Revoked, Relinquished, Superceded, or Expired are ineligible for Unified Certificates of Occupancy. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END

         IF @IssueDate IS NULL
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('The Folder Issue Date is blank, but is required for UCO processing. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END

         IF @FolderStatus = 10018
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('Permit has unmet Pre-Release Conditions and is ineligible for Certificate of Occupancy at this time. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END

         IF @FolderStatus IN (10002, 10003, 10004, 10016, 10022)
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('Permit application decision is in its appeal period, and remains ineligible for Certificate of Occupancy. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END
         
         EXECUTE dbo.usp_UC_Insert_FolderInfo_Phase_Number @PermitFolderRSNValue, @FolderRSN, @UserID

         /* The above procedure does the below:  
         
         DECLARE @UCPhaseNumberInfoCount int
         
         SELECT @UCPhaseNumberInfoCount = COUNT(*)
         FROM FolderInfo
         WHERE FolderInfo.InfoCode = 23035
         AND FolderInfo.FolderRSN = @FolderRSN

         SELECT @ZPPhaseNumberInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0) 
           FROM FolderInfo
          WHERE FolderInfo.FolderRSN = @PermitFolderRSNValue
            AND FolderInfo.InfoCode = 10081    /* Number of Phases */

         IF @UCPhaseNumberInfoCount = 0 AND @ZPPhaseNumberInfoValue > 1
         BEGIN
           SELECT @UCPhaseNumberDefault = dbo.udf_GetUCOPhaseNumberActive(@PermitFolderRSNValue)
 
           INSERT INTO FolderInfo
                      ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                        InfoValue, InfoValueNumeric, 
                        StampDate, StampUser, Mandatory, ValueRequired )
               VALUES ( @FolderRSN, 23035,  305, 'Y', 
                        @UCPhaseNumberDefault, @UCPhaseNumberDefault, 
                        getdate(), @UserID, 'N', 'N' )
         END */

      END   /* End of zoning folders */

      IF @FolderType = 'BP'
      BEGIN
         IF @FolderStatus IN (30005, 30006)
         BEGIN
            SELECT @ValidPermitFlag = 'N'
            ROLLBACK TRANSACTION
            RAISERROR ('Building permits that are Cancelled or Revoked are ineligible for Certificates of Occupancy. Please re-enter FolderRSN.', 16, -1)
            RETURN
         END

         SELECT @BPCOProcessCount = COUNT(*)
          FROM FolderProcess
          WHERE FolderProcess.FolderRSN = @PermitFolderRSNValue
            AND FolderProcess.ProcessCode = 30004

         IF @BPCOProcessCount > 0 
         BEGIN
            SELECT @BPCOProcessAttemptResult = ISNULL(FolderProcessAttempt.ResultCode, 0)
              FROM Folder, FolderProcess, FolderProcessAttempt
             WHERE Folder.FolderRSN = FolderProcess.FolderRSN
               AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
               AND FolderProcess.ProcessCode = 30004
               AND Folder.FolderRSN = @PermitFolderRSNValue
           AND FolderProcessAttempt.AttemptRSN = 
                 ( SELECT max(FolderProcessAttempt.AttemptRSN) 
                     FROM FolderProcess, FolderProcessAttempt
                    WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
                      AND FolderProcess.ProcessCode = 30004
                      AND FolderProcessAttempt.FolderRSN = @PermitFolderRSNValue ) 
         END
         ELSE SELECT @BPCOProcessAttemptResult = 0 

         SELECT @UCOccupancyLoadInfoCount = COUNT(*)
           FROM FolderInfo
          WHERE FolderInfo.FolderRSN = @FolderRSN
            AND FolderInfo.InfoCode = 23030 

         SELECT @BPOccupancyLoadInfoCount = COUNT(*)
           FROM FolderInfo
          WHERE FolderInfo.FolderRSN = @PermitFolderRSNValue 
            AND FolderInfo.InfoCode = 30058 

         IF @BPOccupancyLoadInfoCount > 0 
         BEGIN 
            SELECT @BPOccupancyLoadInfoValue = ISNULL(FolderInfo.InfoValueNumeric, 0) 
              FROM FolderInfo
             WHERE FolderInfo.FolderRSN = @PermitFolderRSNValue
               AND FolderInfo.InfoCode = 30058 
         END
         ELSE SELECT @BPOccupancyLoadInfoValue = 0 

         IF @UCOccupancyLoadInfoCount = 0 AND @BPOccupancyLoadInfoValue > 0 
         BEGIN
            INSERT INTO FolderInfo
                      ( FolderRSN, InfoCode, DisplayOrder, PrintFlag, 
                        InfoValue, InfoValueNumeric, 
                        StampDate, StampUser, Mandatory, ValueRequired )
               VALUES ( @FolderRSN, 23030,  310, 'Y', 
                        @BPOccupancyLoadInfoValue, @BPOccupancyLoadInfoValue, 
        getdate(), @UserID, 'N', 'N' )
         END
         ELSE
         BEGIN
            IF @BPOccupancyLoadInfoValue > 0 
            BEGIN 
               UPDATE FolderInfo
                  SET FolderInfo.InfoValue = @BPOccupancyLoadInfoValue, 
                      FolderInfo.InfoValueNumeric = @BPOccupancyLoadInfoValue 
                 FROM FolderInfo
                WHERE FolderInfo.FolderRSN = @FolderRSN
                  AND FolderInfo.InfoCode = 23030 
            END
         END
      END       /* End of building folders */

   /* If code gets to here, @ValidPermitFlag = 'Y' */

   /* Issue confirmation to user */

   IF @ZPPhaseNumberInfoValue > 1
      SELECT @varUserMessage = 'CSDCWARNING: Please contact the Zoning Project Manager so she may assist with Phased Projects. Permit FolderRSN accepted.' 
   ELSE 
      SELECT @varUserMessage = 'CSDCWARNING: Permit FolderRSN accepted. Please continue.'

   COMMIT
   RAISERROR(@varUserMessage, 16, -1)

   END
END

GO
