USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_TestPeople]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_TestPeople] AS
BEGIN
SELECT * FROM People
END
GO
