USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_RB1Percent]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_RB1Percent] (@intFolderRSN INT, @strFeeComment VARCHAR(256), @dtmDueDate DATETIME)
AS


DECLARE @intNextAccountBillFeeRSN INT
DECLARE @intNextBillNumber INT
DECLARE @dblRentalLateFee FLOAT

SELECT @intNextAccountBillFeeRSN = MAX(AccountBillFee.AccountBillFeeRSN) + 1 FROM AccountBillFee

SELECT @intNextBillNumber = MAX(AccountBill.BillNumber) + 1 FROM AccountBill

SELECT @dblRentalLateFee = dbo.udf_Get1PercentOfRB(Folder.FolderRSN) FROM Folder WHERE FolderRSN = @intFolderRSN

INSERT INTO AccountBill
SELECT 
@intNextBillNumber, /*BillNumber*/
GETDATE(), /*DateGenerated*/
@intFolderRSN, /*RB Folder*/
@dblRentalLateFee, /*Late Fee Amount*/
0,/*Amount Paid*/
'N',/*Paid In Full Flag*/
@strFeeComment, /*Bill Comment*/
@dtmDueDate, /*Due Date*/
GETDATE(), /*Stamp Date*/
'sa' /*Stamp User*/

INSERT INTO AccountBillFee 
(AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
FeeAmount, BillNumber, BillItemSequence, StampDate, StampUser, FeeComment)
VALUES
(@intNextAccountBillFeeRSN, @intFolderRSN, 210, 'Y', 
@dblRentalLateFee, 0, 0, GETDATE(), 'sa', @strFeeComment) 






GO
