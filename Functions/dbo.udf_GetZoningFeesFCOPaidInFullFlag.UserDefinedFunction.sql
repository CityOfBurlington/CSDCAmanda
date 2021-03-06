USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesFCOPaidInFullFlag]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesFCOPaidInFullFlag](@intFolderRSN INT)
RETURNS VARCHAR(4)
AS
BEGIN
   /* Used by Infomaker forms */
   /* All FCO-related fees must be billed. */
   /* Filing Fee:  Starting or after 7/1/1998 (FY99), the CO filing fee was 
      charged at permit application ($7). Therefore the CO filing fee needs 
      to paid for permits applied for prior to 7/1/1998.  
      Then starting July 1, 2009 (FY10), the filing fee is no longer charged at 
      zoning permit application, but at CO request. */

   DECLARE @dtInDate datetime
   DECLARE @varFCOPaidFlag varchar(4)
   DECLARE @varFCOFilingPaidFlag varchar(4)
   DECLARE @varCOFlag varchar(2) 
   DECLARE @varFeePaidFlag varchar(4)

   SELECT @dtInDate = Folder.InDate
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @varCOFlag = dbo.udf_ZoningCertificateofOccupancyFlag(@intFolderRSN)

   SELECT @varFCOPaidFlag = ISNULL(MIN(AccountBill.PaidInFullFlag), 'X') 
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBill.PaidInFullFlag <> 'C'
      AND AccountBillFee.FeeCode = 160
      AND Folder.FolderRSN = @intFolderRSN; 

   SELECT @varFCOFilingPaidFlag = ISNULL(MIN(AccountBill.PaidInFullFlag), 'X') 
     FROM Folder, AccountBill, AccountBillFee
    WHERE Folder.FolderRSN = AccountBillFee.FolderRSN
      AND Folder.FolderRSN = AccountBill.FolderRSN
      AND AccountBillFee.BillNumber = AccountBill.BillNumber
      AND AccountBill.PaidInFullFlag <> 'C'
      AND AccountBillFee.FeeCode = 304
      AND Folder.FolderRSN = @intFolderRSN; 

   IF @varFCOPaidFlag = 'X' OR @varFCOFilingPaidFlag = 'X'
   BEGIN
      IF @varCOFlag = 'Y' 
      BEGIN 
         IF ( @dtInDate < '7/1/1998 00:00:00' OR @dtInDate > '7/1/2009 00:00:00' )
           SELECT @varFeePaidFlag = 'No'
         ELSE 
         BEGIN 
            IF @varFCOPaidFlag <> 'X' AND @varFCOFilingPaidFlag = 'X'
               SELECT @varFeePaidFlag = 'Yes' 
            ELSE SELECT @varFeePaidFlag = 'No' 
         END
      END
      ELSE SELECT @varFeePaidFlag = 'NA'
   END
   ELSE
   BEGIN 
      IF @varFCOPaidFlag = 'N' OR @varFCOFilingPaidFlag = 'N'
         SELECT @varFeePaidFlag = 'No' 
      IF @varFCOPaidFlag = 'Y' AND @varFCOFilingPaidFlag = 'Y' 
         SELECT @varFeePaidFlag = 'Yes' 
   END

   RETURN @varFeePaidFlag
END
GO
