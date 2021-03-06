USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteBill]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DeleteBill](@intBillNumber INT)
AS
BEGIN


	DELETE FROM AccountPayment WHERE PaymentNumber IN(SELECT PaymentNumber FROM AccountPaymentDetail WHERE BillNumber = @intBillNumber)

	DELETE FROM AccountGL WHERE PaymentNumber IN(SELECT PaymentNumber FROM AccountPaymentDetail WHERE BillNumber = @intBillNumber)

	DELETE FROM AccountPaymentDetail WHERE BillNumber = @intBillNumber

	DELETE FROM AccountBill WHERE BillNumber = @intBillNumber

	DELETE FROM AccountBillFee WHERE BillNumber = @intBillNumber
 END





GO
