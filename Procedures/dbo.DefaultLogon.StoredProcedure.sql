USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultLogon]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultLogon] @argReleaseNumber AS VARCHAR(10), @UserID AS Varchar(128) = NULL

as 


select * from ValidSite

GO
