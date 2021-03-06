USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesFCOATFPaidInFullFlag]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesFCOATFPaidInFullFlag](@intFolderRSN INT)
RETURNS VARCHAR(4)
AS
BEGIN
   /* Used by Infomaker forms */
   /* All FCO-related fees must be billed. */
   /* The dbo.udf_GetZoningFeeCalcFinalCOAfterTheFact function does the logic 
      of whether an After The Fact fee is applicable, and returns zero (0) 
      if it is not. */

   DECLARE @dtCurrentDate datetime 
   DECLARE @moneyATFCalc money 
   DECLARE @varATFPaidFlag varchar(4)
   DECLARE @varFeePaidFlag varchar(4)

   SELECT @dtCurrentDate = CurrentDate 
     FROM dbo.uvw_Current_DateTime

   SELECT @moneyATFCalc = dbo.udf_GetZoningFeeCalcFinalCOAfterTheFact(@intFolderRSN)

   SELECT @varATFPaidFlag = ISNULL(MIN(AccountBill.PaidInFullFlag), 'X') 
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBill.PaidInFullFlag <> 'C'
      AND AccountBillFee.FeeCode = 166
      AND Folder.FolderRSN = @intFolderRSN; 

   IF @moneyATFCalc = 0 SELECT @varFeePaidFlag = 'NA' 
   ELSE 
   BEGIN 
      IF @varATFPaidFlag = 'Y' SELECT @varFeePaidFlag = 'Yes' 
      ELSE SELECT @varFeePaidFlag = 'No' 
   END 

   RETURN @varFeePaidFlag
END
GO
