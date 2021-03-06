USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_Extend_Permit_Expiration_Process]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_Extend_Permit_Expiration_Process] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
   /* Called by InfoValidation for Folder.InfoCode = 10078 */
   /* Extend Permit Expiration is Yes/No. At initialization field is set to No. 
      Do some checks, add the Extend Permit Expiration (10020) process, and insert 
      Public Hearing fees when required. */

   DECLARE @varFolderType varchar(4)
   DECLARE @intWorkCode int
   DECLARE @varExtendFlag varchar(2)
   DECLARE @dtPermitExpirationDate datetime
   DECLARE @dtAppealExpirationDate datetime
   DECLARE @intExtendPermitExpProcess int
   DECLARE @intExtendPermitExpProcessRSN int
   DECLARE @intDisplayOrder int
   DECLARE @intPermitDecision int
   DECLARE @intNextProcessRSN int
   DECLARE @varViolationFlag varchar(4)
   DECLARE @fltCUVarianceFee float 
   DECLARE @intAccountBillFeeRSN int

   SELECT @varFolderType = Folder.FolderType,
          @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @varExtendFlag = FolderInfo.InfoValue 
     FROM FolderInfo 
    WHERE FolderInfo.FolderRSN = @intFolderRSN
      AND FolderInfo.InfoCode = 10078

   SELECT @intExtendPermitExpProcess = COUNT(*)
     FROM FolderProcess
    WHERE FolderProcess.ProcessCode = 10020
      AND FolderProcess.FolderRSN = @intFolderRSN 

 SELECT @intExtendPermitExpProcessRSN = ISNULL(FolderProcess.ProcessRSN, 0)
     FROM FolderProcess
    WHERE FolderProcess.ProcessCode = 10020
      AND FolderProcess.FolderRSN = @intFolderRSN 

   SELECT @intDisplayOrder = ( DefaultProcess.DisplayOrder + 5 ) * 10
     FROM DefaultProcess
    WHERE DefaultProcess.FolderType = @varFolderType
      AND DefaultProcess.ProcessCode = 10003       /* Appeal to VSCED */ 

   IF @varExtendFlag <> 'No' 
   BEGIN
      SELECT @dtPermitExpirationDate = FolderInfo.InfoValueDateTime 
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intFolderRSN
         AND FolderInfo.InfoCode = 10024

      SELECT @intPermitDecision = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)

      IF @intPermitDecision = 0
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('This application has not been acted upon. Please set back to No.',16,-1)
         RETURN
      END

      IF @dtPermitExpirationDate < getdate() 
         BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('This permit has already expired: This cow has left the barn. Please set back to No or exit Info.',16,-1)
         RETURN
      END 

     IF dbo.udf_ZoningPermitExpirationDateFlag(@intFolderRSN) = 'N'
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('This permit type does not expire - nothing to extend. So sorry. Please set back to No or exit Info.',16,-1)
         RETURN
      END

      IF @intPermitDecision IN (10002, 10020)  /* Other decision processes are covered by udf_ZoningPermitExpirationDateFlag */
      BEGIN
         ROLLBACK TRANSACTION
         RAISERROR ('Denied applications can not be extended. So sorry. Please set back to No or exit Info.',16,-1)
      RETURN
      END

      SELECT @intNextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      IF @intExtendPermitExpProcess = 0
      BEGIN 
         INSERT INTO FolderProcess 
            (ProcessRSN, FolderRSN, ProcessCode, StartDate, StatusCode, DisciplineCode, 
             PrintFlag, StampDate, StampUser, DisplayOrder)
         VALUES 
            (@intNextProcessRSN, @intFolderRSN, 10020, getdate(), 1, 45, 
             'Y', getdate(), @varUserID, @intDisplayOrder)
      END
      ELSE
      BEGIN
         SELECT @dtAppealExpirationDate = FolderProcessInfo.InfoValueDateTime
           FROM FolderProcessInfo 
          WHERE FolderProcessInfo.ProcessRSN = @intExtendPermitExpProcessRSN 
            AND FolderProcessInfo.InfoCode = 10009 

         IF @dtAppealExpirationDate > getdate()
         BEGIN
            ROLLBACK TRANSACTION
            RAISERROR ('Previous permit extension is in its appeal period. So sorry. Please set back to No or exit Info.',16,-1)
            RETURN
         END

         UPDATE FolderProcess
            SET FolderProcess.StatusCode = 1, FolderProcess.ScheduleDate = getdate(),
                FolderProcess.EndDate = NULL, FolderProcess.SignOffUser = NULL
          WHERE FolderProcess.FolderRSN = @intFolderRSN
            AND FolderProcess.ProcessCode = 10020
      END 

      /* Insert fee where applicable: Conditional Use, Major Impact, Variance (3.2.9(d)); 
         and permits arising from violations (3.2.9(e)). */

      SELECT @varViolationFlag = ISNULL(FolderInfo.InfoValueUpper, 'NO')
        FROM FolderInfo 
       WHERE FolderInfo.FolderRSN = @intFolderRSN 
         AND FolderInfo.InfoCode = 10043

      IF ( @intWorkCode IN (10000, 10002, 10003) ) OR ( @varViolationFlag = 'YES' ) 
      BEGIN
         SELECT @fltCUVarianceFee = ValidLookup.LookupFee
           FROM ValidLookup
          WHERE ValidLookup.LookupCode = 3 
            AND ValidLookup.Lookup1 = 19

         SELECT @intAccountBillFeeRSN = MAX(AccountBillFee.AccountBillFeeRSN) + 1
           FROM AccountBillFee

         INSERT INTO AccountBillFee 
                   ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
                     FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
            VALUES ( @intAccountBillFeeRSN, @intFolderRSN, 135, 'Y', 
                     @fltCUVarianceFee, 0, 0, getdate(), @varUserId )
       END
   END    /* End of varExtendFlag <> 'No' */

   IF @varExtendFlag = 'No' 
   BEGIN
      IF @intExtendPermitExpProcess > 0
      BEGIN 
         UPDATE FolderProcess
            SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate() 
          WHERE FolderProcess.FolderRSN = @intFolderRSN
            AND FolderProcess.ProcessCode = 10020
      END
   END    /* End of varExtendFlag = 'No' */
END


GO
