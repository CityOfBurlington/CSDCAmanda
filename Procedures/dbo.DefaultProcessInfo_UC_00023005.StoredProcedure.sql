USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcessInfo_UC_00023005]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcessInfo_UC_00023005]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128), @ProcessInfoCode int = NULL
as
exec RsnSetLock
DECLARE @NextRSN numeric(10) 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN numeric(10) 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN numeric(10) 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
/* Check Permit FolderRSN for its counterpart in FolderInfo */

IF @ProcessInfoCode = 23005 
BEGIN
   DECLARE @intFolderProcessInfoFolderRSN int
   DECLARE @intFolderInfoFolderRSNCount int

   SELECT @intFolderProcessInfoFolderRSN = ISNULL(FolderProcessInfo.InfoValueNumeric, 0)
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
      AND FolderProcessInfo.InfoCode = @ProcessInfoCode

   SELECT @intFolderInfoFolderRSNCount = COUNT(*) 
     FROM FolderInfo
    WHERE FolderInfo.FolderRSN = @FolderRSN 
      AND FolderInfo.InfoCode BETWEEN 23001 AND 23020 
      AND FolderInfo.InfoValueNumeric = @intFolderProcessInfoFolderRSN

   IF @intFolderInfoFolderRSNCount = 0 AND @intFolderProcessInfoFolderRSN > 0 
   BEGIN 
      ROLLBACK TRANSACTION
      RAISERROR ('The Permit FolderRSN entered does not match any of those in FolderInfo. Please enter a matching FolderRSN', 16, -1)
      RETURN
   END
END
GO
