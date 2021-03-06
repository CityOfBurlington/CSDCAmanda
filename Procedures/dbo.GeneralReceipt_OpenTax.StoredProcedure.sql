USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GeneralReceipt_OpenTax]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure modified to copy OneStopPost.PaymentMemo to TaxPayment.PaymentComment */

CREATE PROCEDURE [dbo].[GeneralReceipt_OpenTax] @ArgBatchRSN int, @ArgReceiptLineRSN int
as
DECLARE @n_FolderRSN          int
DECLARE @n_PaymentAmount      numeric(14,2)
DECLARE @n_PaymentRSN         int
DECLARE @n_PeopleRSN          int
DECLARE @n_ControlBatchRSN    int
DECLARE @n_BatchSubCode       int
DECLARE @n_Year               int
DECLARE @s_CreditGLNumber     Varchar(32)
DECLARE @s_DebitGLNumber      Varchar(32)
DECLARE @s_TransactionDesc    Varchar(64)
DECLARE @n_Hog1TransCode      int
DECLARE @n_Hog2TransCode      int
DECLARE @n_ActualCount        int
DECLARE @n_ActualAmount       numeric(14,2)
DECLARE @n_ActualAmount1      numeric(14,2)
DECLARE @n_ActualAmount2      numeric(14,2)
DECLARE @s_PaymentComment     Varchar(255)
DECLARE @n_TransactionCode    int
DECLARE @s_PaymentDesc	      Varchar(64)
DECLARE @ArgUser	      char(8) 
DECLARE @d_PaymentDate        DATETIME
DECLARE @d_TransactionDate    DATETIME
DECLARE @n_ReceiptRSN          int

/* 44.28b: Hong June 17, 2010: Put the OneStopPost.PaymentMemo to TaxPayment.PaymentComment */
/* 4.4.3V1 Kannan/Murg Jan. 10, 2006 TaxPayment.PaymentDate is updated with BatchDate instead of ReceiptDate*/
/* 4.4.3V1 Kannan/Murg  Jan. 10 2006 Selecting BatchDate Porttion has been moved up*/
/* 4.4.3V1 Hong Jan 06, 2006: ControlBatch Date in Opentax is kept the same date of Onestop Batch */
/* 4.4.3V1 Hong Dec 20, 2005: The sequence of PaymentRSN is taken from Sequence_Tab table for Windsor */
/* 4.4.3V1 Hong Dec 2, 2005: take the payment date from OneStop while inserting in TaxPayment table */
/* 4.4.2 -- Kannan 2005.11.15 Propagated changes in 4.3.21 to 4.4.2  */
/* 4.4.13 Hong Nov 2, 2006: adding the error message as inserting data */
/* Modified Aug 24, 2009: storing the OneStopReceipt.ReceiptRSN into TaxPayment.ReceiptRSN */

BEGIN
    SELECT @ArgUser = user
    IF @ArgUser = 'dbo'
        SELECT @ArgUser='sa'

    /* Get the FolderRSN,PaymentAmount,PaymentType,PepopleRSN,PaymentMemo from the OneStopPost */

    SELECT @n_FolderRSN      = OneStopPost.FolderRSN,
           @n_PaymentAmount  = OneStopPost.PaymentAmount,
           @s_PaymentDesc    = OneStopPost.PaymentType,
           @n_PeopleRSN      = OneStopPost.PeopleRSN,
           @s_PaymentComment = OneStopPost.PaymentMemo,
           @n_ReceiptRSN     = OneStopPost.ReceiptRSN
      FROM OneStopPost
     WHERE OneStopPost.LineRSN = @ArgReceiptLineRSN
       and OneStopPost.BatchRSN = @ArgBatchRSN

    /* Get the Transaction Code */

    SELECT @n_TransactionCode = ISNULL(ValidTransaction.TransactionCode,0)
      FROM ValidTransaction
     WHERE ValidTransaction.TransactionType = 'Payment' 
       and Upper(ValidTransaction.TransactionDesc) = Upper(@s_PaymentDesc)
   
        /* Check a Batch in the Control Batch */

    SELECT @n_ControlBatchRSN = ISNULL(min(ControlBatchRSN), 0)
      FROM ControlBatch
     WHERE BatchStatus = 1
       and BatchType = '$'
       and InsertedUser = @ArgUser
       and OspBatchRSN = @ArgBatchRSN

    SELECT @d_TransactionDate = BatchDate 
    FROM   OnestopBatch
    WHERE  BatchRSN = @ArgBatchRSN

    if @n_ControlBatchRSN < 1
    BEGIN 
        if exists (select count(*) from Sequence_tab where seq_name = 'CONTROLBATCHSEQ')
            EXEC @n_ControlBatchRSN = FNGETAUTOID 'ControlBatch' ,  'ControlBatchRSN'
        else
            SELECT @n_ControlBatchRSN = ISNULL(max(ControlBatchRSN),0) + 1
            FROM ControlBatch  

       /* Kannan - Murg Jan. 10, 2006  moved up - Since If there is more than 1 LineRSN, its not getting calucated
        SELECT @d_TransactionDate = BatchDate 
        FROM   OnestopBatch
        WHERE  BatchRSN = @ArgBatchRSN*/

         /* Get BatchSubCode for inserting in Control Batch */

        SELECT @n_BatchSubCode = ISNULL(min(BatchSubCode), 0)
        FROM   ValidBatchSub 
        WHERE  BatchType = '$' 
  
        /* Amanda 4.3 V 21:	
           Kannan November 15, 2005, 'BatchComment' column has been added as per Windsor's Need */

        INSERT INTO ControlBatch
	       (ControlBatchRSN, BatchType, BatchSubCode,BatchStatus,TransactionDate,
	        InsertedUser, InsertedDate, StampUser, StampDate, ActualCount,
	        ActualTotal, OspBatchRSN,BatchComment)
        VALUES (@n_ControlBatchRSN, '$', @n_BatchSubCode, 1, @d_TransactionDate,
	        @ArgUser , getdate(), @ArgUser, getdate(), 0,
	        0.00, @ArgBatchRSN,'#'+ rtrim(ltrim(CONVERT(CHAR,@ArgBatchRSN))) +'Cashier: '+@ArgUser)
        IF @@Error <> 0   
        BEGIN
            RAISERROR('Insert into Controlbatch fails.'  , 16 , 1)
            ROLLBACK TRANSACTION
            RETURN
        END
    END

    /* Get the PaymentRSN for this Transaction */
       
    EXEC @n_PaymentRSN = FNGETAUTOID 'TaxPayment' ,  'PaymentRSN'
    /*  SELECT @n_PaymentRSN = ISNULL(MAX(PaymentRSN), 0) + 1
        FROM TaxPayment  */

    /* Get PaymentDate  - Kannan, Murg -  Commented as Payment Date is taken from BatchDate 
    SELECT @d_PaymentDate = ReceiptDate
    FROM   OneStopLine
    WHERE  LineRSN = @ArgReceiptLineRSN */
      
    /* Insert the TaxTransaction for the Taxes (like GST,PST) */
    /* Insert the TaxTransaction for the Total (PaymentAmount + Taxes) */
    /* Insert the TaxPayment Transaction */

   SET @s_PaymentComment = 'OSP: '  + @s_PaymentComment

    INSERT INTO TaxPayment
           ( PaymentRSN, ControlBatchRSN, PeopleRSN, TransactionCode, PaymentDate,
             PaymentAmount, AppliedAmount, OnAccountAmount, PaymentComment, ReceiptRSN)
    VALUES ( @n_PaymentRSN, @n_ControlBatchRSN, @n_PeopleRSN, @n_TransactionCode, @d_TransactionDate, 
             0.00 - @n_PaymentAmount, 0.00, 0.00, @s_PaymentComment, @n_ReceiptRSN)

    IF @@Error <> 0   
    BEGIN
        RAISERROR('Insert into TaxPayment fails.'  , 16 , 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    /* Insert the Payment Transaction into TaxPaymentFolder */

    INSERT INTO TaxPaymentFolder
          ( PaymentRSN, FolderRSN, ControlBatchRSN )
    VALUES( @n_PaymentRSN, @n_FolderRSN, @n_ControlBatchRSN )

    IF @@Error <> 0   
    BEGIN
        RAISERROR('Insert into TaxPayment fails.'  , 16 , 1)
        ROLLBACK TRANSACTION
        RETURN
    END

END

GO
