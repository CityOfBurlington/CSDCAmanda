USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Zoning_Insert_Fee_Filing]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Zoning_Insert_Fee_Filing] (@intFolderRSN int, @varUserID varchar(20))
AS
BEGIN 
	/* Inserts Clerk's Filing Fee for one page. JA 7/2012 */

	DECLARE @fltFilingFee float
	DECLARE @intNextRSN int
	
	SELECT @fltFilingFee = ValidLookup.LookupFee 
	FROM ValidLookup 
	WHERE ValidLookup.LookupCode = 3 
	AND ValidLookup.Lookup1 = 2 

	SELECT @intNextRSN = ISNULL(MAX(AccountBillFee.AccountBillFeeRSN), 0) + 1 
	FROM AccountBillFee

	INSERT INTO AccountBillFee 
		( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
		FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser ) 
	VALUES ( @intNextRSN, @intFolderRSN, 80, 'Y', 
			@fltFilingFee, 0, 0, getdate(), @varUserId )
END

GO
