USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultFee_CC_New]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultFee_CC_New]
@FolderRSN int, @UserId char(10)
as
DECLARE @NextRSN int
exec RsnSetLock
SELECT @NextRSN = IsNull(max( AccountBillFee.AccountBillFeeRSN ), 0)
  FROM AccountBillFee
DECLARE @SubCode int
DECLARE @m_Right_of_Way_Fees float 

SELECT @Subcode =Folder.SubCode
FROM Folder
WHERE Folder.FolderRSN = @FolderRSN

IF @SubCode = 30014

SELECT @m_Right_of_Way_Fees = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1= 4 )

IF @SubCode = 30015

SELECT @m_Right_of_Way_Fees = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1= 5 )

IF @SubCode = 30016

SELECT @m_Right_of_Way_Fees = ValidLookup.LookupFee 
  FROM ValidLookup 
 WHERE ( ValidLookup.LookupCode = 6 ) 
   AND ( ValidLookup.Lookup1= 6 )


/* Excavation Fee */
SELECT @NextRSN = @NextRSN + 1 
INSERT INTO AccountBillFee 
       ( AccountBillFeeRSN, FolderRSN, FeeCode, MandatoryFlag, 
         FeeAmount, 
         BillNumber, BillItemSequence, StampDate, StampUser ) 
VALUES ( @NextRSN, @FolderRSN, 170, 'Y', 
         @M_right_of_way_fees, 
         0, 0, getdate(), @UserId )

GO
