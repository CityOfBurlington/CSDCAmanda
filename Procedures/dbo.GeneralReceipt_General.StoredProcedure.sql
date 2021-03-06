USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GeneralReceipt_General]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Parameter UserId added to the procedure so that StampUser can be updated with the actual userid taking the payment */

CREATE PROCEDURE [dbo].[GeneralReceipt_General] @ArgBatchRSN int, @ArgReceiptLineRSN int, @UserID VarChar(128)
AS
/* Amanda 44.26: ESS. Dec 19, 2008: added new parameter UserId for StampUser */
/* Modified Feb 15, 2008:  TransactionDate condition is commented out as getting ControlBatchRSN for Windsor Users */
/* 44V22 Subhash October 12, 2007: Modified to properly insert trust account transaction in AccountBillFee if refund ( negative amount) is withdrawn */
/* 44.21 Modified July 10, 2007: Subhash - use 'Gen_Pay' instead of 'Payment' to get Payment Tran Code only for Windsor, for the rest use 'Payment' */
/* Modified June 5, 2007: Sam - Insert batch user from OneStopBatch into ControlBatch table */
/* Modified Mar 18, 2007: Steve - use 'Gen_Pay' instead of 'Payment' to get Payment Tran Code */
/* Modified Nov 22, 2006: Hong revised */
/* Modified Nov 08, 2006: F_Payment_Get_Gl_Account is used as function */
/* Modified Mar 29, 2006: Hong -  get Payment Transaction Code */
/* Jan 06, 2006: update sequence ControlBatch, Payment and Transaction for Windsor */
/* V 4311: Subhash August 5, 2004 - Made same as Oracle to handle TA/OSP */

DECLARE @n_TransactionCode			int
DECLARE @n_TransactionCode_Payment		int
DECLARE @n_PaymentAmount			numeric(18,2)
DECLARE @s_PaymentDesc				Varchar(255)
DECLARE @n_PaymentRSN				int
DECLARE @n_PeopleRSN				int
DECLARE @n_ControlBatchRSN			int
DECLARE @n_BatchSubCode				int
DECLARE @n_Year					int
DECLARE @n_NextTransactionRSN			int
DECLARE @s_CreditGLNumber			Varchar(32)
DECLARE @s_DebitGLNumber			Varchar(32)
DECLARE @s_TransactionDesc			Varchar(64)
DECLARE @s_PaymentComment			Varchar(255)
DECLARE @ArgUser				varchar(128)
DECLARE @ret					int
DECLARE @d_ReceiptDate				datetime
DECLARE @n_ReceiptRSN				int
DECLARE @d_TransactionDate			datetime

-- Subhash August 5, 2004
DECLARE
	@n_NextRSN				int,
	@n_NextFeeRSN			int,
	@s_Description			Varchar(255),
	@n_Trust_FolderRSN		int,
	@n_TAFeeCode			int,
	@n_PaymentNumber		int,
	@s_PaymentType			Varchar(255),
	@n_Rate					FLOAT,
	@s_FolderType			Varchar(4),
	@n_TrustAccountAmount	numeric(18,2),
	@n_DrawnByFolderRSN		int,
	@SurTax1Flag			char(1),
	@SurTax2Flag			char(1),
	@SurTax1_Rate			float,
	@SurTax2_Rate			float
-- End Subhash August 5, 2004

BEGIN
    IF dbo.F_Validsite_City()  = 'WINDSOR'
        SELECT @ArgUser=StampUser              /* From Windsor - Sam Jun 5, 2007: to get user from stampuser in OS Batch */
        FROM    OneStopBatch 
        WHERE BatchRSN=@ArgBatchRSN
    ELSE
        SELECT @ArgUser=user

    IF @ArgUser = 'dbo'
        SELECT @ArgUser='sa'

    /* Get the BatchRSN,FolderRSN,PaymentAmount,PaymentType,PepopleRSN,PaymentComment from the OneStopPost */
     -- Subhash August 5, 2004: DrawnByFolderRSN added
    SELECT @n_TransactionCode = OneStopPost.FolderRSN,
                  @n_PaymentAmount = OneStopPost.PaymentAmount,
                  @s_PaymentDesc     = OneStopPost.PaymentType,
                  @n_PeopleRSN         = OneStopPost.PeopleRSN,
                  @s_PaymentComment  = OneStopPost.PaymentMemo,
                  @n_ReceiptRSN        = OneStopPost.ReceiptRSN,
                  @n_Trust_FolderRSN = OneStopPost.DrawnByFolderRSN
    FROM    OneStopPost
    WHERE OneStopPost.LineRSN  = @ArgReceiptLineRSN
    and        OneStopPost.BatchRSN = @ArgBatchRSN

    /* Get the receipt date */

    -- Subhash August 5, 2004: In following SELECT Distinct ReceiptDate replaced by Min(ReceiptDate)
    --SELECT distinct @d_ReceiptDate = OneStopLine.ReceiptDate
    --  FROM OneStopLine
    -- WHERE OneStopLine.ReceiptRSN = @n_ReceiptRSN

    SELECT @d_ReceiptDate = Min(OneStopLine.ReceiptDate)
    FROM    OneStopLine
    WHERE OneStopLine.ReceiptRSN = @n_ReceiptRSN

    SELECT @s_TransactionDesc = ISNULL(TransactionDesc, ' ')
    FROM    ValidTransaction
    WHERE TransactionCode = @n_TransactionCode
    -- End Subhash August 5, 2004

    /* Get a Batch in the Control Batch */

    IF dbo.F_Validsite_City()  = 'WINDSOR'
        SELECT @n_ControlBatchRSN = ISNULL(min(ControlBatchRSN), 0)
        FROM    ControlBatch
        WHERE BatchStatus = 1
        and        BatchType = 'G'
        and        InsertedUser = @UserID
        and        OspBatchRSN = @ArgBatchRSN
    ELSE
        SELECT @n_ControlBatchRSN = ISNULL(min(ControlBatchRSN), 0)
        FROM    ControlBatch
        WHERE BatchStatus = 1
        and        CONVERT(char(8), TransactionDate, 1) = CONVERT(char(8), getdate(), 1)
        and        BatchType = 'G'
        and        InsertedUser = @UserID
        and        OspBatchRSN = @ArgBatchRSN

    IF @n_ControlBatchRSN < 1
    BEGIN
        IF dbo.F_Validsite_City()  = 'WINDSOR'
           EXEC @n_ControlBatchRSN = fnGetAutoID 'ControlBatch' ,  'ControlBatchRSN'
        ELSE
           SELECT @n_ControlBatchRSN = ISNULL(max(ControlBatchRSN),0) + 1
           FROM    ControlBatch

       SELECT  @d_TransactionDate = BatchDate
       FROM     OnestopBatch
       WHERE  BatchRSN = @ArgBatchRSN

       /* Get BatchSubCode for inserting in Control Batch */

       SELECT @n_BatchSubCode = ISNULL(MIN(BatchSubCode), 0)
       FROM    ValidBatchSub
       WHERE BatchType = 'G'

       /* Insert the Control Batch Transaction */

       INSERT INTO ControlBatch
                 (ControlBatchRSN,BatchType,BatchSubCode,BatchStatus,TransactionDate,
                  InsertedUser,InsertedDate,StampUser,StampDate,ActualCount,
                  ActualTotal,OspBatchRSN, BatchComment)
          VALUES (@n_ControlBatchRSN,'G',@n_BatchSubCode,1,@d_TransactionDate,
                  @UserID,getdate(),@UserID,getdate(),0,
                  0.00,@ArgBatchRSN, 'One Stop Payment')
    END

    /* Get the PaymentRSN for this Transaction */
    IF dbo.F_Validsite_City()  = 'WINDSOR'
        EXEC @n_PaymentRSN = fnGetAutoID 'TaxPayment' ,  'PaymentRSN'
    ELSE
        SELECT @n_PaymentRSN = ISNULL(MAX(PaymentRSN), 0) + 1
        FROM   TaxPayment

    /* Get the Current Processing Year */
    SELECT @n_Year = datepart(year,getdate())

    /* Get the Credit GL AccountNumber */
    EXEC @s_CreditGLNumber = f_Payment_Get_GL_Account @n_TransactionCode, @n_Year, 0, 'C'

    /* Get the Debit GL AccountNumber */
    EXEC @s_DebitGLNumber = f_Payment_Get_GL_Account @n_TransactionCode,@n_Year,0,'D'

    /* Insert the TaxTransaction for the payment amount - Credit Entry */
    /* Get Next Transaction RSN */

    IF dbo.F_Validsite_City()  = 'WINDSOR'
        EXEC @n_NextTransactionRSN = fnGetAutoID 'TaxTransaction' ,  'TransactionRSN'
    ELSE
        SELECT @n_NextTransactionRSN = ISNULL(MAX(TransactionRSN), 0) + 1
        FROM TaxTransaction

    INSERT INTO TaxTransaction
              (TransactionRSN, ControlBatchRSN, FolderRSN, BillRSN, YearForBilling,
               ParentTransactionRSN, PaymentRSN, InstallmentRSN, AdjustmentRSN,
               BatchSubCode, BillSumFlag, PaymentSumFlag, TransactionCode,
               TransactionDesc,TransactionDate,TransactionAmount,GlAccountNumber,
               DebitCreditFlag,ChargeRSN)
        VALUES(@n_NextTransactionRSN, @n_ControlBatchRSN, 0, 0, @n_Year,
               0, @n_PaymentRSN, 0, 0,
               0, '  ', '  ', @n_TransactionCode,
               @s_PaymentComment, getdate(), 0.0 - @n_PaymentAmount, @s_CreditGLNumber,
               'C', 0)

    /* Insert the TaxTransaction for the payment amount - Debit Entry */

    IF dbo.F_Validsite_City()  = 'WINDSOR'
        EXEC @n_NextTransactionRSN = fnGetAutoID 'TaxTransaction' ,  'TransactionRSN'
    ELSE
        SELECT @n_NextTransactionRSN = @n_NextTransactionRSN + 1


    INSERT INTO TaxTransaction
              (TransactionRSN,ControlBatchRSN,FolderRSN,BillRSN,YearForBilling,
               ParentTransactionRSN,PaymentRSN,InstallmentRSN,AdjustmentRSN,
               BatchSubCode,BillSumFlag,PaymentSumFlag,TransactionCode,
               TransactionDesc,TransactionDate,TransactionAmount,GlAccountNumber,
               DebitCreditFlag,ChargeRSN)
       VALUES (@n_NextTransactionRSN, @n_ControlBatchRSN, 0, 0, @n_Year,
               0, @n_PaymentRSN, 0, 0,
               0,'  ','  ', @n_TransactionCode,
               @s_PaymentComment, getdate(), @n_PaymentAmount, @s_DebitGLNumber,
               'D', 0)

    /* Creating PaymentType Transactions in Tax Transactions Added Feb 3, 2000 */
    /* Subhash July 10, 2007: Else part added */
    IF dbo.F_Validsite_City()  = 'WINDSOR'
       SELECT @n_TransactionCode_Payment = isnull(ValidTransaction.TransactionCode,0)
         FROM ValidTransaction
        WHERE ValidTransaction.TransactionType = 'Gen_Pay'
          and UPPER(ValidTransaction.TransactionDesc) = UPPER(@s_PaymentDesc)
    ELSE
       SELECT @n_TransactionCode_Payment = isnull(ValidTransaction.TransactionCode,0)
         FROM ValidTransaction
        WHERE ValidTransaction.TransactionType = 'Payment'
          and UPPER(ValidTransaction.TransactionDesc) = UPPER(@s_PaymentDesc)

    /* Get the Credit GL AccountNumber */
    EXEC @s_CreditGLNumber = f_Payment_Get_GL_Account @n_TransactionCode_Payment, @n_Year, 0, 'C'

    /* Get the Debit GL AccountNumber */
    EXEC @s_DebitGLNumber = f_Payment_Get_GL_Account @n_TransactionCode_Payment,@n_Year,0,'D'

    if @n_TransactionCode_Payment = 0
        select top 1 @s_CreditGLNumber = GLACCOUNTNUMBERUNDEFINEDCREDIT,
                     @s_DebitGLNumber = GLACCOUNTNUMBERUNDEFINEDDEBIT
        From ValidSiteTax

    /* Insert the TaxTransaction for the PaymentType amount - Credit Entry */

    IF dbo.F_Validsite_City()  = 'WINDSOR'
        EXEC @n_NextTransactionRSN = fnGetAutoID 'TaxTransaction' ,  'TransactionRSN'
    ELSE
        SELECT @n_NextTransactionRSN = @n_NextTransactionRSN + 1

    INSERT INTO TaxTransaction
              (TransactionRSN, ControlBatchRSN, FolderRSN, BillRSN, YearForBilling,
               ParentTransactionRSN, PaymentRSN, InstallmentRSN, AdjustmentRSN,
               BatchSubCode, BillSumFlag, PaymentSumFlag, TransactionCode,
               TransactionDesc,TransactionDate,TransactionAmount,GlAccountNumber,
               DebitCreditFlag,ChargeRSN)
        VALUES(@n_NextTransactionRSN, @n_ControlBatchRSN, 0, 0, @n_Year,
               0, @n_PaymentRSN, 0, 0,
               0, '  ', '  ', @n_TransactionCode_Payment,
               @s_PaymentComment, getdate(), @n_PaymentAmount, @s_CreditGLNumber,
               'C', 0)

    /* Insert the TaxTransaction for the payment amount - Debit Entry */

    IF dbo.F_Validsite_City()  = 'WINDSOR'
        EXEC @n_NextTransactionRSN = fnGetAutoID 'TaxTransaction' ,  'TransactionRSN'
    ELSE
        SELECT @n_NextTransactionRSN = @n_NextTransactionRSN + 1

    INSERT INTO TaxTransaction
              (TransactionRSN,ControlBatchRSN,FolderRSN,BillRSN,YearForBilling,
               ParentTransactionRSN,PaymentRSN,InstallmentRSN,AdjustmentRSN,
               BatchSubCode,BillSumFlag,PaymentSumFlag,TransactionCode,
               TransactionDesc,TransactionDate,TransactionAmount,GlAccountNumber,
               DebitCreditFlag,ChargeRSN)
       VALUES(@n_NextTransactionRSN, @n_ControlBatchRSN, 0, 0, @n_Year,
               0, @n_PaymentRSN, 0, 0,
               0,'  ','  ', @n_TransactionCode_Payment,
               @s_PaymentComment, getdate(), 0.00 - @n_PaymentAmount, @s_DebitGLNumber,
               'D', 0)

    /* Insert the TaxTransaction for the Taxes (like GST,PST) */
    /* Insert the TaxTransaction for the Total (PaymentAmount + Taxes) */
    /* Insert the TaxPayment Transaction */

    INSERT INTO TaxPayment
               (PaymentRSN,ControlBatchRSN,PeopleRSN,TransactionCode,PaymentDate,
                PaymentAmount,AppliedAmount,OnAccountAmount,PaymentComment)
         VALUES(@n_PaymentRSN,@n_ControlBatchRSN,@n_PeopleRSN,@n_TransactionCode_Payment,@d_ReceiptDate,
                0.00 - @n_PaymentAmount,0.00 - @n_PaymentAmount,0,'General')

   -- Subhash August 5, 2004
    SELECT @n_PaymentAmount = (-1) * @n_PaymentAmount
    SELECT @s_Description = 'Payment ' + ltrim(rtrim(convert(char(10),@n_PaymentRSN)))

    IF @n_Trust_FolderRSN > 0
    BEGIN
        SELECT @n_TAFeeCode = ValidFolder.TAFeeCode
        FROM   ValidFolder, Folder
        WHERE  Folder.FolderRSN = @n_Trust_FolderRSN
        AND    ValidFolder.FolderType = Folder.FolderType

        SELECT @SurTax1Flag = isnull(VT.SurTax1Flag, 'N'),
               @SurTax2Flag = isnull(VT.SurTax2Flag, 'N'),
               @SurTax1_Rate = isnull(VS.SurTax1_Rate, 0),
               @SurTax2_Rate = isnull(VS.SurTax2_Rate, 0)
        FROM   ValidTransaction VT, ValidSiteTax VS
        WHERE  VT.TransactionCode = @n_TransactionCode

        SELECT @n_TrustAccountAmount = @n_PaymentAmount
        IF @SurTax1Flag = 'Y'
            SELECT @n_TrustAccountAmount = @n_TrustAccountAmount + (@n_PaymentAmount * @SurTax1_Rate)
        IF @SurTax2Flag = 'Y'
            SELECT @n_TrustAccountAmount = @n_TrustAccountAmount + (@n_PaymentAmount * @SurTax2_Rate)
	-- Subhash October 12, 2007: Following if else end if commented and replaced by new line 
	--IF @n_TrustAccountAmount > 0
        --    SELECT @n_DrawnByFolderRSN = 0
        --ELSE
        --    SELECT @n_DrawnByFolderRSN = 1
        SELECT @n_DrawnByFolderRSN = 1
        -- upto here

        SELECT @n_NextFeeRSN = ISNULL(Max(AccountBillFeeRSN), 0) + 1
        FROM AccountBillFee

        INSERT INTO AccountBillFee
                (AccountBillFeeRSN, FolderRSN, FeeCode, FeeAmount, MandatoryFlag,
                 BillNumber, DrawnByFolderRSN, DrawnByPaymentNumber, StampDate,StampUser)
        VALUES (@n_NextFeeRsn, @n_Trust_FolderRSN, @n_TAFeeCode, @n_TrustAccountAmount, 'Y',
                 0, @n_DrawnByFolderRSN, -1, GetDate(), @UserID)
    END
    -- End Subhash August 5, 2004
END


GO
