USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_QN_Folder]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_QN_Folder]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee

--to insert people records from RR
EXECUTE DefaultProcess_RR_11111111 0, @FolderRSN, @UserID

UPDATE Folder
SET folder.folderdescription = 'Notes to File--See Comments', 
folder.statuscode = 160 --Change status to Notes to File
where folder.folderrsn = @folderrsn
GO
