USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeUnpaidFees]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CodeUnpaidFees]
AS
BEGIN

--VB (202), RB (179,180,181,187,188,189,196,198,901,902,903,904,905), 
--Reinspection (200,231,232,233,234), liens fees (204), late charge (209)
SELECT DISTINCT AccountBill.BillNumber, DateGenerated, AccountBill.FolderRSN, BillAmount, TotalPaid, PaidInFullFlag,
'VB' AS FeeType, dbo.udf_GetFolderParcelID(AccountBill.FolderRSN) AS ParcelID, 
dbo.udf_GetFolderType(AccountBill.FolderRSN) AS FolderType
FROM AccountBill
JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
WHERE FeeCode = 202
AND PaidInFullFlag = 'N'
AND DateGenerated >= '1/1/2006'
AND BillAmount <> 0
--ORDER BY AccountBill.BillNumber
UNION
SELECT DISTINCT AccountBill.BillNumber, DateGenerated, AccountBill.FolderRSN, BillAmount, TotalPaid, PaidInFullFlag,
'RB' AS FeeType, dbo.udf_GetFolderParcelID(AccountBill.FolderRSN) AS ParcelID,
dbo.udf_GetFolderType(AccountBill.FolderRSN) AS FolderType
FROM AccountBill
JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
WHERE FeeCode IN (179,180,181,187,188,189,196,198,901,902,903,904,905)
AND PaidInFullFlag = 'N'
AND DateGenerated >= '1/1/2006'
AND BillAmount <> 0
UNION
SELECT DISTINCT AccountBill.BillNumber, DateGenerated, AccountBill.FolderRSN, BillAmount, TotalPaid, PaidInFullFlag,
'RF' AS FeeType, dbo.udf_GetFolderParcelID(AccountBill.FolderRSN) AS ParcelID,
dbo.udf_GetFolderType(AccountBill.FolderRSN) AS FolderType
FROM AccountBill
JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
WHERE FeeCode IN (200,231,232,233,234)
AND PaidInFullFlag = 'N'
AND DateGenerated >= '1/1/2006'
AND BillAmount <> 0
UNION
SELECT DISTINCT AccountBill.BillNumber, DateGenerated, AccountBill.FolderRSN, BillAmount, TotalPaid, PaidInFullFlag,
'LF' AS FeeType, dbo.udf_GetFolderParcelID(AccountBill.FolderRSN) AS ParcelID,
dbo.udf_GetFolderType(AccountBill.FolderRSN) AS FolderType
FROM AccountBill
JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
WHERE FeeCode = 204
AND PaidInFullFlag = 'N'
AND DateGenerated >= '1/1/2006'
AND BillAmount <> 0
UNION
SELECT DISTINCT AccountBill.BillNumber, DateGenerated, AccountBill.FolderRSN, BillAmount, TotalPaid, PaidInFullFlag,
'LC' AS FeeType, dbo.udf_GetFolderParcelID(AccountBill.FolderRSN) AS ParcelID,
dbo.udf_GetFolderType(AccountBill.FolderRSN) AS FolderType
FROM AccountBill
JOIN AccountBillFee ON AccountBill.BillNumber = AccountBillFee.BillNumber
WHERE FeeCode = 209
AND PaidInFullFlag = 'N'
AND DateGenerated >= '1/1/2006'
AND BillAmount <> 0
ORDER BY FeeType, dbo.udf_GetFolderParcelID(AccountBill.FolderRSN)--,AccountBill.BillNumber

END
GO
