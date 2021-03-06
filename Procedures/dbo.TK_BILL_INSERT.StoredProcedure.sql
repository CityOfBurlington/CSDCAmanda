USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_BILL_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/******************************************************************************
NAME: TOOLKIT.BILL_INSERT
PURPOSE: Will bill unbilled fees on a folder.  The argFeeList parameter can be used if you want to only bill fees in a 
certain list
REVISIONS:

Ver        Date        Author           Description
---------  ----------  ---------------  ------------------------------------
1.0                           Shraddha    1. convert oracle procedure to mssql

NOTES: argInList can be used to indicate if you want all fees in argFeeList or all fees that are not in argFeeList

******************************************************************************/

CREATE PROCEDURE [dbo].[TK_BILL_INSERT]
(@argFolderRSN int, @DUserID varchar(4000), @argFeeList varchar(4000)='ALL', @argInList int=1, @n_BillNumber int OUTPUT)
--WITH 
--EXECUTE AS CALLER
AS
BEGIN
	exec RsnSetLock

	--DECLARE @n_BillNumber int
	DECLARE @n_billAmount numeric(18,2)
	DECLARE @n_feeCount int
		
		    /* -- revised Fobidos -- 06112009 -- since bill Number is returned even if it was not created
        SELECT @n_BillNumber = max(billNumber) + 1 --changes for oracle to MSSQL
        FROM accountBillFee --changes for oracle to MSSQL
		    */
		
	IF @argFeeList = 'ALL' 
	BEGIN 
		SELECT @n_feeCount = COUNT(*)
		FROM accountBillFee 
		WHERE folderRSN  = @argFolderRSN
		AND billNumber = 0
			
		IF @n_feeCount > 0 
		BEGIN 
		
			SELECT @n_billAmount  =  ISNULL(SUM(feeAmount),0)
			FROM accountBillFee 
			WHERE folderRSN = @argFolderRSN
			AND billNumber = 0
			
			SELECT @n_BillNumber = max(billNumber) + 1 --changes for oracle to MSSQL
			FROM accountBillFee --changes for oracle to MSSQL
				
			INSERT INTO  accountBill(billnumber, folderRSN, dateGenerated, billAmount , 
						totalPaid, paidInFullFlag, billDesc, stampDate, stampUser)  
			VALUES (@n_BillNumber, @argFolderRSN, GETDATE(), @n_billAmount, 
				0, 'N', DBO.f_FolderNumber(@argFolderRSN), GETDATE(), @DUserID)  
				
			UPDATE accountBillFee   
			SET billNumber = @n_BillNumber, stampDate = GETDATE() 
			WHERE folderRSN = @argFolderRSN
			AND billNumber = 0 
				
		END
   	END
	ELSE
	BEGIN 
		RAISERROR ( 'Code needed for fee List'  , 16  , -1   ) 
	END
  
		
END

GO
