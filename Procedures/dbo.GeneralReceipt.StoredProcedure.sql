USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GeneralReceipt]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Parameter ArgFolderRSN added to the procedure so that FolderRSN can be passed as required by new cashier module */

CREATE PROCEDURE [dbo].[GeneralReceipt] @ArgBatchRSN int, @UserID VarChar(128)=NULL, @ArgFolderRSN int = 0
as 
-- 5.4.4.31a: ESS - Parameter ArgFolderRSN added to the procedure so that FolderRSN can be passed as required by new cashier module
-- Amanda 44.28a: ESS Feb,17, 2010: Modified for bilingual implementation. The 'f_GetAmandaMessage' function has been implemented.    
/* Version 4.4.26a: YUMING August 24, 2009: Changed data type to Integer from Numeric for @n_count */ 
/* Amanda 44.26: Prem (ESS) Feb 24, 2009: if UserID is null, then get the logon user id.*/
/* ESS. Dec 19, 2008: added new parameter UserId for StampUser */
/* 44v 18 Subhash March 28, 2007: Script modified to call procedure OneStop_UserPost, which client can customized for data validation */
/* Hong V4.3.13 Oct 15, 2004: modified multi-payment with one receipt */
/* Hong V4.4.13 Nov 02, 2006: adding the Raise error message */
/* Hong V4.4.13 Nov 21, 2006: fixing the bug */
/* Hong Dec 05, 2006: applied AMANDA payment immediately */
/* H. Jan 12, 2007: adjustment the OSP batch total amount as having the void transactions */
/* H. Mar 01, 2007: the status of Batch is changed as using the Post Batch button */
/* Anthony Mar 16, 2009: use IF SUBSTRING(@s_SystemType,1,1) = 'A' instead of IF @s_SystemType = 'A' for working with non-Permit FolderType */

DECLARE @n_ReceiptLineRSN   int
DECLARE @n_ReceiptRSN      int
DECLARE @n_Receipt_Prev      int
DECLARE @n_PaymentNumber   int
DECLARE @n_PaymentReceipt   int
DECLARE @n_AmandaCount      int
DECLARE @f_AmandaTotal      numeric(14,2)
DECLARE @n_OpenTaxCount      int
DECLARE @f_OpenTaxTotal      numeric(14,2)
DECLARE @n_GeneralCount      int
DECLARE @f_GeneralTotal      numeric(14,2)
DECLARE @n_PaymentAmount   numeric(14,2)
DECLARE @n_SessionRSN      int
DECLARE @n_ControlBatchRSN   int
DECLARE @s_SystemType      varchar(2)
DECLARE @s_AccountSession   varchar(1)
DECLARE @s_Amanda         varchar(1)
DECLARE @s_OpenTax         varchar(1)
DECLARE @s_General         varchar(1)
DECLARE @f_AmountPaid      numeric(14,2)
DECLARE @f_total           numeric(14,2)
DECLARE @s_AMANDA_Option   varchar(32)
DECLARE @n_count            INT
DECLARE @ErrorMessage 		varchar(4000)  

/* Cusor for Storing One Stop Posting Records for Posting each Receipt Line */

DECLARE  Cur_OneStopPost CURSOR FOR
    SELECT  OneStopPost.LineRSN,
            OneStopPost.ReceiptRSN,
            OneStopPost.SystemType,
            OneStopPost.PaymentAmount
    FROM    OneStopPost
    WHERE   OneStopPost.BatchRSN = @ArgBatchRSN
    ORDER BY OneStopPost.LineRSN

BEGIN
    /* Parameters For Inserting the Records in AccountSession */
    SELECT @s_AccountSession = 'Y'
    SELECT @f_AmandaTotal = 0.00
    SELECT @f_OpenTaxTotal = 0.00
    SELECT @f_GeneralTotal = 0.00

    --Get logon user id if it is null (i.e. from .exe):
    if @UserID IS NULL
       set @UserID = SYSTEM_USER

    SELECT @n_count = count(*)
    FROM   ValidSiteOption
    WHERE  upper(OptionKey) = 'AMANDA_PAY_IMMEDIATELY'

    If @n_count > 0
        SELECT @s_AMANDA_Option = upper(isnull(OptionValue, 'NO'))
        FROM   ValidSiteOption
        WHERE  upper(OptionKey) = 'AMANDA_PAY_IMMEDIATELY'
    ELSE
        Select @s_AMANDA_Option = 'NO'


    BEGIN TRAN

    OPEN  Cur_OneStopPost
    FETCH Cur_OneStopPost
    INTO  @n_ReceiptLineRSN, @n_ReceiptRSN,
          @s_SystemType, @n_PaymentAmount

    Select  @n_Receipt_Prev = 0

    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF SUBSTRING(@s_SystemType,1,1) = 'A'
        BEGIN
            SELECT @n_PaymentNumber = ISNULL(Max(PaymentNumber), 0) + 1
            FROM AccountPayment

            IF @n_Receipt_Prev <> @n_ReceiptRSN
                select @n_PaymentReceipt = @n_PaymentNumber

            EXEC GeneralReceipt_Amanda @ArgBatchRSN , @n_ReceiptLineRSN, @s_AccountSession, @n_PaymentNumber, @n_PaymentReceipt, @UserID, @ArgFolderRSN /* Satyajit: 2012.02.14 :-- To add OverPayment functionality in cashier module. */

            SELECT @s_AccountSession = 'N'
            SELECT @s_Amanda = 'Y'
            Select @n_Receipt_Prev = @n_ReceiptRSN
        END

        IF @s_SystemType = 'O'
        BEGIN
           EXEC GeneralReceipt_OpenTax @ArgBatchRSN , @n_ReceiptLineRSN
                SELECT @s_OpenTax = 'Y'
        END
        IF @s_SystemType = 'G'
        BEGIN
                EXEC GeneralReceipt_General @ArgBatchRSN , @n_ReceiptLineRSN, @UserID
                SELECT @s_General = 'Y'
        END

        FETCH Cur_OneStopPost
        INTO  @n_ReceiptLineRSN, @n_ReceiptRSN,
              @s_SystemType, @n_PaymentAmount
    END

    CLOSE Cur_OneStopPost
    DEALLOCATE Cur_OneStopPost

    /* Updating Controls in OneStopBatch,ControlBatch */

    IF @s_Amanda = 'Y' or @s_AMANDA_Option = 'YES'
    BEGIN

        SELECT @n_count = count(*)
        FROM   AccountSession
        WHERE  OspBatchRSN = @ArgBatchRSN

        if @n_count > 0
        BEGIN
            SELECT @n_SessionRSN = Max(ISNULL(SessionRSN,0))
            FROM   AccountSession
            WHERE  OspBatchRSN = @ArgBatchRSN

            SELECT @f_AmandaTotal  = sum(PaymentAmount),
                   @n_AmandaCount = Count(*)
            FROM   AccountPayment
            WHERE  PaymentNumber IN (SELECT DISTINCT PaymentNumber
                  FROM AccountGL
                         WHERE SessionRSN = @n_SessionRSN)
         AND Isnull(VoidFlag, 'N') <> 'Y'
        END
    END

    IF @s_OpenTax = 'Y'
    BEGIN

        SELECT @f_OpenTaxTotal = Sum(PaymentAmount),
               @n_OpenTaxCount = Count(*)
        FROM   TaxPayment
        WHERE  ControlBatchRSN in (SELECT ControlBatchRSN
                                   FROM   ControlBatch
                                   WHERE  OspBatchRSN = @ArgBatchRSN
                                   AND    BatchType = '$' )

        UPDATE ControlBatch
        SET    ActualTotal = 0 - @f_OpenTaxTotal,
               ActualCount = @n_OpenTaxCount
        WHERE  OspBatchRSN = @ArgBatchRSN
        AND    BatchType = '$'
        IF @@ERROR <> 0
        BEGIN
            --RAISERROR('Update ControlBatch fails.'  , 16 , 1)
			   SET @ErrorMessage = (SELECT dbo.f_GetAmandaMessage('GENERAL_RECEIPT_UPDATE_CONTROLBATCH_FAILS',NULL,NULL))    
            RAISERROR(@ErrorMessage , 16 , 1)   
            ROLLBACK TRANSACTION
            RETURN
        END

    END

    IF @s_General = 'Y'
    BEGIN

        SELECT @f_GeneralTotal = Sum(PaymentAmount),
               @n_GeneralCount = Count(*)
        FROM   TaxPayment
        WHERE  ControlBatchRSN in (SELECT ControlBatchRSN
                                   FROM   ControlBatch
                                   WHERE  OspBatchRSN = @ArgBatchRSN
                                   AND    BatchType = 'G')
        UPDATE ControlBatch
        SET    ActualTotal = 0 - @f_GeneralTotal,
               ActualCount = @n_GeneralCount,
               BatchStatus  = 3
        WHERE  OspBatchRSN = @ArgBatchRSN
        AND    BatchType = 'G'
        IF @@ERROR <> 0
        BEGIN
            --RAISERROR('Update ControlBatch fails.'  , 16 , 1)
			   SET @ErrorMessage = (SELECT dbo.f_GetAmandaMessage('GENERAL_RECEIPT_UPDATE_CONTROLBATCH_FAILS',NULL,NULL))    
            RAISERROR(@ErrorMessage , 16 , 1)   
            ROLLBACK TRANSACTION
            RETURN
        END

    END

    SELECT @f_Total = @f_AmandaTotal - ( @f_OpenTaxTotal  +  @f_GeneralTotal )
    FROM   OneStopBatch
    WHERE  BatchRSN = @ArgBatchRSN

    SELECT @f_AmountPaid = sum(PaymentAmount - ChangeDue)
    FROM   OneStopReceipt
    WHERE  BatchRSN = @ArgBatchRSN
    AND    VoidFlag <> 'Y'

    IF @f_Total = @f_AmountPaid
    BEGIN
        Update OneStopLine
        SET     PaidFlag = 'Y'
        where   BatchRSN =  @ArgBatchRSN
        and     VoidFlag <> 'Y'

        IF @@ERROR <> 0
        BEGIN
            --RAISERROR('Update OneStopLine fails.'  , 16 , 1)
            SET @ErrorMessage = (SELECT dbo.f_GetAmandaMessage('GENERAL_RECEIPT_UPDATE_ONESTOPLINE_FAILS',NULL,NULL))    
				RAISERROR(@ErrorMessage , 16 , 1)      
            ROLLBACK TRANSACTION
            RETURN
        END

    END

    UPDATE OneStopBatch
    SET    OneStopBatch.StampDate   = getdate(),
           OneStopBatch.AmandaCount = @n_AmandaCount,
           OneStopBatch.AmandaTotal = @f_AmandaTotal,
           OneStopBatch.OpenTaxCount  = @n_OpenTaxCount,
           OneStopBatch.OpenTaxTotal  = 0.00 - @f_OpenTaxTotal,
           OneStopBatch.GeneralCount  = @n_GeneralCount,
           OneStopBatch.GeneralTotal  = 0.00 - @f_GeneralTotal,
           OneStopBatch.ExternalCount = 0,
           OneStopBatch.ExternalTotal =0.00
    WHERE  OneStopBatch.BatchRSN = @ArgBatchRSN

    IF @@ERROR <> 0
    BEGIN
        --RAISERROR('Update OneStopBatch fails.'  , 16 , 1)
        SET @ErrorMessage = (SELECT dbo.f_GetAmandaMessage('GENERAL_RECEIPT_UPDATE_ONESTOPBATCH_FAILS',NULL,NULL))    
		  RAISERROR(@ErrorMessage , 16 , 1)   
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Subhash March 28, 2007
    exec OneStop_UserPost @ArgBatchRSN

    COMMIT TRAN

END


GO
