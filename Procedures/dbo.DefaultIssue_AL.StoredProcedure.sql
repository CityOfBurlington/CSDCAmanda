USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_AL]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultIssue_AL] @FolderRSN numeric(10), @UserId varchar(128) as DECLARE @NextRSN numeric(10) exec RsnSetLock SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) FROM AccountBillFee 
BEGIN 
DECLARE @Rough VarChar(3) 
DECLARE @StatusCode INT 
DECLARE @strFolderType VARCHAR(4) 
DECLARE @intCOMReturnValue INT 
 
SELECT @Rough = InfoValue 
FROM FolderInfo 
WHERE FolderInfo.FolderRSN = @FolderRSN 
AND FolderInfo.InfoCode = 30053 
 
 
IF @Rough = 'No' BEGIN 
    DELETE 
    FROM FolderProcess 
    WHERE FolderProcess.FolderRSN = @FolderRSN 
    AND FolderProcess.ProcessCode = 30018 
END 
 
 
  
END
GO
