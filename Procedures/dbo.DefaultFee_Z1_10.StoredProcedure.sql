USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_Z1_10]    Script Date: 9/9/2013 9:56:46 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_Z1_10]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
EXECUTE DefaultFee_ZB_10 @FolderRSN, @UserID
GO
