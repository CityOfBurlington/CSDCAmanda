USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultPayment_EM]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultPayment_EM] @FolderRSN numeric(10), @UserId varchar(128), @PaymentRSN numeric(10), @argType varchar(20)= NULL as DECLARE @NextRSN numeric(10) exec RsnSetLock  SELECT @NextRSN = isnull(max( AccountBillFee.AccountBillFeeRSN ), 0) FROM AccountBillFee 
BEGIN 
DECLARE @BalDue MONEY 
DECLARE @IsPayment INT 
 
SELECT @IsPayment = SUM(1) 
FROM AccountPayment  
WHERE FolderRSN = @FolderRSN 
AND PaymentNumber = @PaymentRSN 
 
SET @IsPayment = ISNULL(@IsPayment, 0) 
 
SELECT @BalDue = dbo.udf_GetFolderFeesDue(@FolderRSN) 
 
IF @IsPayment > 0  
BEGIN 
  IF ISNULL(@BalDue, 0.0) = 0.0  
    BEGIN 
        UPDATE Folder 
        SET StatusCode = 30002 /* Issued */ 
        WHERE FolderRSN = @FolderRSN 
    END 
END  
END
GO
