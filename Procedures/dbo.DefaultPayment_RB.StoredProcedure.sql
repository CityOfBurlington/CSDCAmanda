USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultPayment_RB]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultPayment_RB]
@FolderRSN int, @UserId char(10), @PaymentRSN int, @argType varchar(20) = NULL
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @Message VARCHAR(200)
DECLARE @BalDue MONEY
DECLARE @IsPayment INT

SELECT @IsPayment = SUM(1)
FROM AccountPayment 
WHERE FolderRSN = @FolderRSN
AND PaymentNumber = @PaymentRSN


SET @IsPayment = ISNULL(@IsPayment, 0)

SELECT @BalDue = dbo.udf_GetFolderFeesDue(@FolderRSN), 
@Message = 'Payment entered by ' + @UserId + ' on ' + dbo.FormatDateTime(GetDate(), 'MM/DD/YYYY HH:MM 12')

IF @IsPayment > 0 
BEGIN
  IF ISNULL(@BalDue, 0.0) > 0.0 
    BEGIN
        SET @Message = 'Partial ' + @Message
        EXEC usp_UpdateFolderCondition @FolderRSN, @Message

        UPDATE Folder
        SET SubCode = 20202
        WHERE FolderRSN = @FolderRSN
    END
  ELSE
    BEGIN

     EXEC usp_UpdateFolderCondition @FolderRSN, @Message

     UPDATE Folder
     SET SubCode = 20201
     WHERE FolderRSN = @FolderRSN
  END

END
GO
