USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[OneStop_Validation]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[OneStop_Validation] @ArgReceiptRSN int 
as  

DECLARE @n_peopleRSN	int

BEGIN 

    --SELECT @n_peopleRSN = ISNULL(PeopleRSN, 0)
    --FROM   OneStopReceipt
    --WHERE  ReceiptRSN = @ArgReceiptRSN

--    if   @n_PeopleRSN = 0 
  --  BEGIN  
    --    RAISERROR('AMANDA payment is missing people records, please enter it.'  , 16 , 1) 
       RETURN 
   -- END
             
END

GO
