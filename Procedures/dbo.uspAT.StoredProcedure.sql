USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[uspAT]    Script Date: 9/9/2013 9:56:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAT] 
AS
INSERT INTO ValidCity (City) VALUES('Austin')

GO
