USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultProcess_PP_00030030]    Script Date: 9/9/2013 9:56:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultProcess_PP_00030030]
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
DECLARE @ValidUser INT
DECLARE @ValidUserID1 varchar(128)
DECLARE @ValidUserID2 varchar(128)
DECLARE @ValidUserID3 varchar(128)

/* Get the User Id for those authorized to process refunds. Currenlt allow up to 3 */
SELECT @ValidUserID1 = LookupString FROM ValidLookup WHERE LookupCode = 30020
SELECT @ValidUserID2 = LookupString2 FROM ValidLookup WHERE LookupCode = 30020
SELECT @ValidUserID3 = LookupString3 FROM ValidLookup WHERE LookupCode = 30020


SET @ValidUser = 0

IF @UserId IN (@ValidUserID1, @ValidUserID1, @ValidUserID1) 
   BEGIN
     SET @ValidUser = 1
   END

IF @ValidUser = 1
  BEGIN
      UPDATE Folder 
      SET StatusCode = 2 
      WHERE FolderRSN = @FolderRSN
  END
ELSE
  BEGIN
     UPDATE FolderProcess
     SET StatusCode = 1, 
     SignOffUser = Null, 
     EndDate = Null
     WHERE ProcessRSN = @ProcessRSN

     RAISERROR('You are not authorized to run this process', 16, -1)
  END

GO
