USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[GETDATE]    Script Date: 9/9/2013 9:43:37 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[GETDATE]()
RETURNS DATETIME
AS
BEGIN

/*
  Name of Person: ESS
  Date : March 31 2006
  Version:
*/

  DECLARE @TheDate     DATETIME

  SELECT @TheDate = NewDate FROM GetdateView
  return(@TheDate)
END

GO
