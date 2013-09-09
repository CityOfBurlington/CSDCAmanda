USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_ZC_00010029]    Script Date: 9/9/2013 9:56:53 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_ZC_00010029]
@ProcessRSN numeric(10), @FolderRSN numeric(10), @UserId char(128)
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
EXECUTE DefaultProcess_ZB_00010029 @ProcessRSN, @FolderRSN, @UserID
GO
