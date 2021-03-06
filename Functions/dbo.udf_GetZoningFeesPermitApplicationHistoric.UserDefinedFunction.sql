USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningFeesPermitApplicationHistoric]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningFeesPermitApplicationHistoric](@intFolderRSN INT)
   RETURNS MONEY
AS
BEGIN
	/* Returns only the zoning permit application fee amount, for permits 
       which exist on paper only (ZZ folder). Filing fees were not charged 
       back then. Upon entry, fees are not billed. */

   DECLARE @moneyPermitAppFee MONEY

   SELECT @moneyPermitAppFee = ISNULL(SUM(AccountBillFee.FeeAmount), 0)
     FROM AccountBillFee
    WHERE AccountBillFee.FolderRSN = @intFolderRSN
      AND AccountBillFee.FeeCode = 155

	RETURN @moneyPermitAppFee
END


GO
