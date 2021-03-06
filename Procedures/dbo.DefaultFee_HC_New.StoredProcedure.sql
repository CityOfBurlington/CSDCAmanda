USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_HC_New]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_HC_New]
@FolderRSN numeric(10), @UserId char(128)
as
DECLARE @NextRSN numeric(10)
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @dblISDFeeAmount MONEY
DECLARE @dblCodeFeeAmount MONEY
DECLARE @intNoOfTags INT
DECLARE @intStartingTag INT
DECLARE @intEndingTag INT
DECLARE @FeeComment VARCHAR(80)
DECLARE @BillNumber INT


UPDATE Folder 
SET WorkCode = 10050
WHERE FolderRSN = @FolderRSN

SELECT @intStartingTag = dbo.f_info_numeric(@FolderRSN, 30200),
@intEndingTag = dbo.f_info_numeric(@FolderRSN, 30201)
SET @intNoOfTags = @intEndingTag - @intStartingTag + 1

SET @FeeComment = 'Fees for Heating Tags ' + CAST(@intStartingTag AS VARCHAR(10)) + ' thru ' + CAST(@intEndingTag AS VARCHAR(10))

SET @dblISDFeeAmount = (2 * @intNoOfTags)
SET @dblCodeFeeAmount = (3 * @intNoOfTags)

EXEC PC_FEE_INSERT @FolderRSN, 30, @dblISDFeeAmount, @UserID, 1, @FeeComment, 0, 0

EXEC PC_FEE_INSERT @FolderRSN, 31, @dblCodeFeeAmount, @UserID, 1, @FeeComment, 0, 0

EXEC TK_BILL_INSERT @FolderRSN, @UserID, 'ALL', 1, @BillNumber

GO
