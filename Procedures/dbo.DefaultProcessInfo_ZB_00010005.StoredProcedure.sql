USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcessInfo_ZB_00010005]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcessInfo_ZB_00010005]
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
DECLARE @varFolderType varchar(4)
DECLARE @intStatusCode int
DECLARE @intSubCode int
DECLARE @intWorkCode int

SELECT @varFolderType = Folder.FolderType, 
       @intStatusCode = Folder.StatusCode, 
       @intSubCode = Folder.SubCode,
       @intWorkCode = Folder.WorkCode
  FROM Folder
 WHERE Folder.FolderRSN = @FolderRSN

/* Waive Right to Appeal Option - adds process Waive Right to Appeal (10028) */

IF @ProcessInfoCode = 10002       
BEGIN
   DECLARE @intWaiveProcessCount int
   DECLARE @varWaiveFlag varchar(4) 

   SELECT @intWaiveProcessCount = COUNT(*)
     FROM FolderProcess
    WHERE FolderProcess.FolderRSN = @FolderRSN
      AND FolderProcess.ProcessCode = 10028

   SELECT @varWaiveFlag = FolderProcessInfo.InfoValueUpper
     FROM FolderProcessInfo
    WHERE FolderProcessInfo.ProcessRSN = @ProcessRSN
      AND FolderProcessInfo.InfoCode = @ProcessInfoCode

   IF @varWaiveFlag = 'YES' AND @intWaiveProcessCount = 0
   BEGIN
      SELECT @NextProcessRSN = MAX(FolderProcess.ProcessRSN) + 1
        FROM FolderProcess

      INSERT INTO FolderProcess
                ( ProcessRSN, FolderRSN, ProcessCode, DisciplineCode, StatusCode,
                  ScheduleDate, DisplayOrder, PrintFlag, MandatoryFlag, StampDate, StampUser )
         VALUES ( @NextProcessRSN, @FolderRSN, 10028, 45, 1,
                  getdate(), 450, 'Y', 'Y', getdate(), @UserID )
   END 

   IF @varWaiveFlag = 'YES' AND @intWaiveProcessCount > 0
   BEGIN
         UPDATE FolderProcess
            SET FolderProcess.StatusCode = 1, FolderProcess.ScheduleDate = getdate(),
                FolderProcess.EndDate = NULL, FolderProcess.SignOffUser = NULL
          WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 10028
   END

   IF @varWaiveFlag = 'NO' AND @intWaiveProcessCount > 0 
   BEGIN 
         UPDATE FolderProcess
            SET FolderProcess.StatusCode = 2, FolderProcess.EndDate = getdate(), 
       FolderProcess.SignOffUser = @UserID 
          WHERE FolderProcess.FolderRSN = @FolderRSN
            AND FolderProcess.ProcessCode = 10028
   END
END
GO
