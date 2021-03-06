USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_QC_00020032]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_QC_00020032]
@ProcessRSN int, @FolderRSN int, @UserId char(128)
as
exec RsnSetLock
DECLARE @NextRSN int 
 SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) 
   FROM AccountBillFee
DECLARE @NextProcessRSN int 
 SELECT @NextProcessRSN = isnull(max( FolderProcess.ProcessRSN ), 0) 
   FROM FolderProcess 
DECLARE @NextDocumentRSN int 
 SELECT @NextDocumentRSN = isnull(max( FolderDocument.DocumentRSN ), 0) 
   FROM FolderDocument 
DECLARE @ParentRSN INT
DECLARE @OldStatus INT
DECLARE @NewStatus INT

/* Get the current status of the QC folder */
SELECT @ParentRSN = ParentRSN, @OldStatus = StatusCode 
FROM Folder WHERE FolderRSN = @FolderRSN

/* Call the MH routine to handle the bulk of the logic */
EXEC DefaultProcess_MH_00020032 @ProcessRSN, @FolderRSN, @UserId


/* If QC Folder Status is now Closed, close the associated Q1 folder as well */
COMMIT
BEGIN TRANSACTION
SELECT @NewStatus = StatusCode FROM Folder WHERE FolderRSN = @FolderRSN
IF @OldStatus <> 2 AND @NewStatus = 2
BEGIN
    UPDATE Folder SET StatusCode = 2 WHERE FolderRSN = @ParentRSN
END

GO
