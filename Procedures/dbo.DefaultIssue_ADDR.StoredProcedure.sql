USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultIssue_ADDR]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultIssue_ADDR]
@FolderRSN int, @UserId char(128)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
/* Call procedure to do the work */
EXEC usp_AddressChange @FolderRSN, @UserID
GO
