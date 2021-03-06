USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GeneralReceipt_Amanda]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Parameter ArgFolderRSN added to the procedure so that FolderRSN can be passed as required by new cashier module */

CREATE PROCEDURE [dbo].[GeneralReceipt_Amanda] @ArgBatchRSN int, @ArgReceiptLineRSN int, @ArgAccountSession VarChar,
 @ArgPaymentNumber int, @ArgPaymentReceipt int, @UserID VarChar(128), @ArgFolderRSN int
AS

-- 5.4.4.31a: ESS - Parameter ArgFolderRSN added to the procedure so that FolderRSN can be passed as required by new cashier module
/* Version 44.28b: Anthony 07/09/2010: Roll back the script to 44.26 version as the 44.28 version cause problem which broken Cashier.  Bilingual implementation is not require for this procedure*/  
/* Amanda 44.26: Prem (ESS) Feb 24, 2009: Specified the size of @UserID.*/
/* ESS. Dec 19, 2008: added new parameter UserId for StampUser */
/* Version 44V21: Kannan Aug 23, 2007: Modified to allow -ve amount */
/* 44v19, Subhash April 3, 2007: Modified to execute Payment procedure */
/* 44v17, Subhash March 2, 2007: When the payemnt is inserted into Amanda, 
          AccountPayment.ReceiptLineRSN is updated with OneStopPost.ReceiptRSN  */
/* Version 4.4V9: Subhash January 31, 2006: AccountPayment.DateGenerated is populated from ReceiptDate, rather than GetDate() to match with AccountPayment.PaymentDate */
/* Version 4.4V9: Subhash January 31, 2006: Modified to handle single bill number when entered in OSP - CASE entry */
/* Version 4.3V22: Subhash December 15, 2005: 'Account Receivable' changed to 'Accounts Receivable' for making AccountGL.AccountName same as in triggers */
/* V 4313: Hong : Oct 15, 2004: modified multi-payment with one receipt and LocationCode from OSPost to AccountPayment */
/* V 4311: Subhash August 5, 2004 - Made same as Oracle to handle TA/OSP */
/* V 4318: Subhash July 19, 2005 - Kannan's changes integrated to create Accountgl correctly for TA/OSP */

DECLARE @n_FolderRSN          int
DECLARE @n_TotalPaidAmount    numeric(14,2)
DECLARE @n_BillNumber         int
DECLARE @n_BillNumberOSP      int	-- Subhash January 31, 2006
DECLARE @n_BillBalanceAmount  numeric(14,2)
DECLARE @dt_BillDate          DateTime
DECLARE @n_PaymentAmount      numeric(14,2)
DECLARE @n_AppliedAmount      numeric(14,2)
DECLARE @f_AppliedAmount_Sum  numeric(14,2)
DECLARE @n_Osp_PaymentAmount  numeric(14,2)
DECLARE @n_Osp_ChangeDue      numeric(14,2)
DECLARE @s_PaymentType        Varchar(6)
DECLARE @n_PaymentNumber      int
DECLARE @n_PeopleRSN          int
DECLARE @n_NextSessionRSN     int
DECLARE @s_PaymentComment     VarChar(255)
DECLARE @s_PaymentDesc        Varchar(64)
DECLARE @n_Rate        numeric(14,3)
DECLARE @n_AmountTendered     numeric(14,2)
DECLARE @ArgUser       Varchar(128)
DECLARE @d_ReceiptDate       datetime
DECLARE @n_ReceiptRSN       int

-- Subhash August 5, 2004
DECLARE
	@n_NextRSN	         int,
	@n_NextFeeRSN 	      int,
	@s_Description	      varchar(64),
	@n_Trust_FolderRSN   int,
	@n_TAFeeCode         int,
	@s_FolderType        varchar(4),
	@s_AccRecGL          varchar(32),
	@s_TAFeeGLCode       varchar(32),
	@s_TAFeeName         varchar(40),
	@n_TAFeeCode1        int,
	@n_TransactionRSN    int,
	@n_TransactionAmount numeric(14,2),
	@s_NormalCredit      varchar(1),
	@s_NormalDebit       varchar(1),
	@s_TADescription     varchar(60),
	@n_DrawnByFolderRSN  int
-- End Subhash August 5, 2004
DECLARE @n_LocationCode        int

DECLARE @s_PaymentProcedure varchar(60)
DECLARE @n_Count int

/* Cusor for storing the bills(not paid in full and not cancelled) for the folder */
/* Commented by Kannan  - Cursor has been moved down just before opening - July 19, 2005*/
--DECLARE AccountBill_Cur CURSOR FOR
--SELECT AccountBill.DateGenerated,
--            AccountBill.BillNumber,
--            ISNULL(AccountBill.TotalPaid, 0),
--            ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0)
--       FROM AccountBill
--      WHERE AccountBill.FolderRSN = @n_FolderRSN
--        AND AccountBill.PaidInFullFlag <> 'Y'
--        AND AccountBill.PaidInFullFlag <> 'C'
--        AND ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0) > 0.00
--    ORDER BY AccountBill.DateGenerated asc

BEGIN
	 -- ESS; Instead of @ArgUser, @UserID parameter is used
    --SELECT @ArgUser = user
    --IF @ArgUser = 'dbo'
    --    SELECT @ArgUser='sa'

    /* Added by Kannan - July 19, 2005 */
    Select @n_PaymentNumber = @ArgPaymentNumber

    /*Get the BatchRSN, FolderRSN,PaymentAmount,PaymentType,PepopleRSN from the OneStopPost */
    -- Subhash January 31, 2006: BillNumber added
    -- SubhashAugust 5, 2004: DrawnByFolderRSN added
    SELECT @n_FolderRSN      = OneStopPost.FolderRSN,
           @n_AmountTendered = OneStopPost.PaymentAmount,
           @s_PaymentDesc    = OneStopPost.PaymentType,
           @n_PeopleRSN      = OneStopPost.PeopleRSN,
           @s_PaymentComment = OneStopPost.PaymentMemo,
           @n_ReceiptRSN     = OneStopPost.ReceiptRSN,
           @n_Trust_FolderRSN = OneStopPost.DrawnByFolderRSN,
           @n_LocationCode = OneStopPost.LocationCode,
           @n_BillNumberOSP = ISNULL(OneStopPost.BillNumber, 0)
      FROM OneStopPost
     WHERE OneStopPost.LineRSN = @ArgReceiptLineRSN
       and OneStopPost.BatchRSN = @ArgBatchRSN

    /* Get the receipt date */

	 -- Subhash August 5, 2004: In following SELECT Distinct ReceiptDate replaced by Min(ReceiptDate)
    --SELECT distinct @d_ReceiptDate = OneStopLine.ReceiptDate
    --  FROM OneStopLine
    -- WHERE OneStopLine.ReceiptRSN = @n_ReceiptRSN

    SELECT @d_ReceiptDate = Min(OneStopLine.ReceiptDate)
      FROM OneStopLine
     WHERE OneStopLine.ReceiptRSN = @n_ReceiptRSN
	 -- End Subhash August 5, 2004

	/* H. added 2009.05.15 */
      if @d_ReceiptDate is null 
         SELECT @d_ReceiptDate = dbo.GETDATE()
      
      
    /* Get The Payment Type */
    SELECT @s_PaymentType = ISNULL(ValidAccountPayment.PaymentType, ' '),
           @n_Rate = ISNULL(ValidAccountPayment.CurrencyRate, 1.0)
      FROM ValidAccountPayment
     WHERE Upper(ValidAccountPayment.PaymentTypeDesc) = Upper(@s_PaymentDesc)

    SELECT @n_PaymentAmount = @n_AmountTendered * @n_Rate

    /* Locking for Account Payment Number */
    EXEC RsnSetLock

 /* Create Account Session */

    If @ArgAccountSession  = 'Y'
    BEGIN
        /* Get AccountSession.SessionRSN for this user */
        SELECT @n_NextSessionRSN = Max(SessionRSN)
          FROM AccountSession
         WHERE OspBatchRSN = @ArgBatchRSN
           and StampUser = @UserID
           and SessionStatus = 1

        IF ISNULL(@n_NextSessionRSN, 0) = 0
        BEGIN
           SELECT @n_NextSessionRSN = ISNULL(Max(SessionRSN), 0) + 1
             FROM AccountSession

           INSERT INTO AccountSession
                  (SessionRSN, SessionDesc, SessionStatus, SessionType,SessionCreateDate,StampUser,OspBatchRSN)
           VALUES (@n_NextSessionRSN, @UserID, 1, 1, getdate(), @UserID, @ArgBatchRSN)
        END
    END

    /* n_Osp_PaymentAmount is for Storing in AccountPayment, Account Session */

    SELECT @n_Osp_PaymentAmount = @n_PaymentAmount

    /* Insert AppliedAmount into AccountPayment */
    /* Till the PaymentAmount becomes zero apply it into the bills. */

    SELECT @f_AppliedAmount_Sum = 0

    -- Subhash January 11, 2006
    -- Kannan Aug 23, 2007: Modified to allow -ve amount
    
    /* H. added 2009.05.15 */
	    SELECT @n_count =  count(*) 
	      FROM   AccountBill
	     WHERE  FolderRSN = @n_FolderRSN 
        AND    BillNumber = @n_BillNumberOSP
        
    IF @n_BillNumberOSP > 0 and @n_count > 0 /* H. added 2009.05.15 */
	    DECLARE AccountBill_Cur CURSOR FOR
	    SELECT AccountBill.DateGenerated,
		    AccountBill.BillNumber,
		    ISNULL(AccountBill.TotalPaid, 0),
		    ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0)
	       FROM AccountBill
	      WHERE AccountBill.FolderRSN = @n_FolderRSN
		AND AccountBill.PaidInFullFlag <> 'Y'
		AND AccountBill.PaidInFullFlag <> 'C'
		AND ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0) <> 0.00
    		AND AccountBill.BillNumber = @n_BillNumberOSP
    ELSE
    -- End: Subhash January 11, 2006
	    /* Kannan - Declare Cursor moved from up - July 19, 2005*/
	    /* Kannan Aug 23, 2007: Modified to allow -ve amount */
	    DECLARE AccountBill_Cur CURSOR FOR
	    SELECT AccountBill.DateGenerated,
		    AccountBill.BillNumber,
		    ISNULL(AccountBill.TotalPaid, 0),
		    ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0)
	       FROM AccountBill
	      WHERE AccountBill.FolderRSN = @n_FolderRSN
		AND AccountBill.PaidInFullFlag <> 'Y'
		AND AccountBill.PaidInFullFlag <> 'C'
		AND ISNULL(AccountBill.BillAmount, 0) - ISNULL(AccountBill.TotalPaid, 0) <> 0.00
	    ORDER BY AccountBill.DateGenerated asc

    OPEN AccountBill_Cur
    FETCH AccountBill_Cur INTO
          @dt_BillDate,
          @n_BillNumber,
          @n_TotalPaidAmount,
          @n_BillBalanceAmount

    /* WHILE @@SQLSTATUS = 0 */
    WHILE @@FETCH_STATUS = 0
    BEGIN
          IF @n_PaymentAmount > @n_BillBalanceAmount
            /* if the paymentamount is greater then
            apply it into the bill and reduce the payment amount */
          BEGIN
              SELECT @n_AppliedAmount = @n_BillBalanceAmount
              SELECT @n_PaymentAmount = @n_PaymentAmount - @n_AppliedAmount
          END
          ELSE
          BEGIN
               SELECT @n_AppliedAmount = @n_PaymentAmount
               SELECT @n_PaymentAmount = 0
          END

          /* Insert AppliedAmount with bill details Into AccountPaymentDetail */
          -- Subhash January 20, 2006: DateGenerated is populated from @d_ReceiptDate, rather than GetDate() to match with AccountPayment.PaymentDate
          INSERT INTO AccountPaymentDetail
                   (BillNumber,
                   PaymentNumber,
                   DateGenerated,
                   PaymentAmount,
                   FolderRSN,
                   ReverseEntryFlag,
                   StampDate,
                   StampUser)
            VALUES (@n_BillNumber,
                   @ArgPaymentNumber,
                   @d_ReceiptDate,
                   @n_AppliedAmount,
                   @n_FolderRSN,
                   'N',
                   getdate(),
                   @UserID)

          /* For Storing Applied Amount in Account Payment */

          SELECT @f_AppliedAmount_Sum = @f_AppliedAmount_Sum + @n_AppliedAmount

          IF @n_PaymentAmount <= 0
          BEGIN
              BREAK
          END
          FETCH AccountBill_Cur INTO
                @dt_BillDate,
                @n_BillNumber,
                @n_TotalPaidAmount,
                @n_BillBalanceAmount
    END

    CLOSE AccountBill_Cur
    DEALLOCATE AccountBill_Cur
    /* Satyajit: 2012.02.14 :-- To add OverPayment functionality in cashier module. */
    IF @ArgFolderRSN != 0 
    BEGIN
    	SELECT @n_Osp_ChangeDue = OneStopReceipt.ChangeDue FROM OneStopReceipt WHERE OneStopReceipt.BatchRsn = @ArgBatchRSN and OneStopReceipt.ReceiptRsn = @n_ReceiptRSN
    END

    IF @ArgFolderRSN = @n_FolderRSN
    BEGIN
	SET @n_Osp_PaymentAmount = @n_Osp_PaymentAmount + @n_Osp_ChangeDue
    END

    INSERT INTO AccountPayment
                (PaymentNumber,
                 PaymentType,
                 PaymentDate,
                 PaymentAmount,
                 PaymentComment,
                 FolderRSN,
                 ReceiptNumber,
                 DateReceiptPrinted,
                 AmountApplied,
                 AmountRefunded,
                 StampDate,
                 StampUser,
                 BillToRSN,
                 NSFFlag,
                 NSFServiceChargeFlag,
                 VoidFlag,
                 CurrencyRate,
                 AmountTendered,
                 ReceiptLineRSN, 
                 LocationCode)
         VALUES (@ArgPaymentNumber,
                 @s_PaymentType,
                 @d_ReceiptDate,
                 @n_Osp_PaymentAmount,
                 @s_PaymentComment,
                 @n_FolderRSN,
                 @ArgPaymentReceipt,
                 NULL,
                 @f_AppliedAmount_Sum,
                 0.00,
                 getdate(),
                 @UserID,
                 @n_PeopleRSN,
                 'N',
                 'N',
                 'N',
                 @n_Rate,
                 @n_AmountTendered,
                 @n_ReceiptRSN, 
                 @n_LocationCode)

    -- Subhash August 5, 2004
    SELECT @f_AppliedAmount_Sum = (-1) * @f_AppliedAmount_Sum
	 SELECT @s_Description = 'Payment ' + ltrim(rtrim(convert(char(10),@n_PaymentNumber)))

    IF @n_Trust_FolderRSN > 0
    BEGIN
       SELECT @n_TAFeeCode = ValidFolder.TAFeeCode
         FROM ValidFolder, Folder
        WHERE Folder.FolderRSN = @n_Trust_FolderRSN
         AND  ValidFolder.FolderType = Folder.FolderType

       SELECT @n_NextFeeRSN = ISNULL(Max(AccountBillFeeRSN), 0) + 1
         FROM AccountBillFee
       -- Kannan August 23, 2007 if else commented and replaced by SELECT @n_DrawnByFolderRSN = 1
       SELECT @n_DrawnByFolderRSN = 1
       --IF @f_AppliedAmount_Sum > 0
       --   SELECT @n_DrawnByFolderRSN = 0
       --ELSE
       --   SELECT @n_DrawnByFolderRSN = 1
       -- End Kannan August 23, 2007
       INSERT INTO AccountBillFee
                (AccountBillFeeRSN, FolderRSN, FeeCode, FeeAmount, MandatoryFlag,
                 BillNumber, DrawnByFolderRSN, DrawnByPaymentNumber, StampDate,StampUser)
         VALUES (@n_NextFeeRsn, @n_Trust_FolderRSN, @n_TAFeeCode, @f_AppliedAmount_Sum, 'Y',
                 0, @n_DrawnByFolderRSN, @n_PaymentNumber, GetDate(), @UserID)
		 UPDATE AccountPayment
          SET FromFolderRSN = @n_Trust_FolderRSN
        WHERE PaymentNumber = @n_PaymentNumber

       /* Start: Insert AccountGL for Trust Account Transaction - Kannan */

       SELECT @n_TransactionAmount = @n_Osp_PaymentAmount
       SELECT @s_NormalDebit  = 'D'
       SELECT @s_NormalCredit  = 'C'
       SELECT @s_TADescription = 'Payment ' + ltrim(rtrim(convert(char(10),@n_PaymentNumber))) + ' Folder' +ltrim(rtrim(convert(char( 10),@n_FolderRSN)))

       SELECT @s_TAFeeGLCode = ValidAccountFee.GlAccountNumber,
              @s_TAFeeName = ValidAccountFee.FeeDesc,
              @n_TAFeeCode1 = ValidAccountFee.FeeCode
         FROM ValidAccountFee, ValidFolder
        WHERE ValidFolder.FolderType = @s_PaymentType
         AND  ValidAccountFee.FeeCode = ValidFolder.TAFeeCode

       SELECT @n_TransactionRSN = ISNULL(Max(TransactionRSN), 0) + 1
         FROM AccountGL

       SELECT @s_TAFeeName = substring(@s_TAFeeName, 1, 30)

       /* Debit to  TAFeeGL Account */
       INSERT INTO AccountGL
		       (TransactionRSN,
				  TransactionDate,
				  GlAccountNumber,
				  DebitCreditFlag,
				  AccountName,
				  TransactionDesc,
				  FolderRSN,
				  FeeCode,
				  PaymentNumber,
				  TransactionAmount,
				  StampDate,
				  StampUser,
				  SessionRSN)
       VALUES (@n_TransactionRSN,
				  GetDate(),
				  @s_TAFeeGLCode,
				  @s_NormalDebit,
				  @s_TAFeeName,
				  @s_TADescription,
				  @n_FolderRSN,
				  @n_TAFeeCode1 ,
				  @n_PaymentNumber,
				  @n_TransactionAmount,
				  GetDate(),
				  @UserID,
				  @n_NextSessionRSN)

       SELECT @s_AccRecGL = ValidSite.GlAccountNumberAccRecv
         FROM ValidSite

       SELECT @n_TransactionRSN = @n_TransactionRSN + 1

       /* Credit to  TAFeeGL Account */
       -- Subhash December 15, 2005: In following insert 'Account Receivable' changed to 'Accounts Receivable'
       INSERT INTO AccountGL
			     (TransactionRSN,
					TransactionDate,
				   GlAccountNumber,
					DebitCreditFlag,
					AccountName,
					TransactionDesc,
					FolderRSN,
					FeeCode,
					PaymentNumber,
					TransactionAmount,
					StampDate,
					StampUser,
					SessionRSN )
       VALUES (@n_TransactionRSN,
					GetDate(),
					@s_AccRecGL,
					@s_NormalCredit,
					'Accounts Receivable',
					@s_TADescription,
					@n_FolderRSN,
					NULL,
					@n_PaymentNumber,
					@n_TransactionAmount,
					GetDate(),
					@UserID,
					@n_NextSessionRSN)
    END
    -- End Subhash August 5, 2004

    UPDATE AccountSession
       SET SessionInputTotal = ISNULL(SessionInputTotal,0.00) + @n_Osp_PaymentAmount,
           SessionInputCount = ISNULL(SessionInputCount,0) + 1
     WHERE AccountSession.OspBatchRSN = @ArgBatchRSN
     
    
    SET @s_FolderType = ''
    SELECT @s_FolderType = FolderType FROM Folder WHERE FolderRSN = @n_FolderRSN
    SET @s_PaymentProcedure = 'DefaultPayment_' + @s_FolderType
    SELECT @n_Count = Count(*)
      FROM sysobjects
     WHERE Name = @s_PaymentProcedure
    if @n_Count > 0 
       EXECUTE @s_PaymentProcedure @n_FolderRSN, @UserID, @ArgPaymentNumber, 'PAYMENT' 
END



GO
