USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_String_Today]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[p_String_Today] @Today VARCHAR(8)

AS

BEGIN
	SET @Today = CONVERT(VARCHAR(8), GETDATE(), 112)
END


GO
