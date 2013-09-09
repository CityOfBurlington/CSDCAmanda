USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_ZL_Folder]    Script Date: 9/9/2013 9:56:47 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_ZL_Folder]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
EXECUTE DefaultFee_ZB_Folder @FolderRSN, @UserID
GO
