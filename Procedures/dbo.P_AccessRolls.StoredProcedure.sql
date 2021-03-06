USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_AccessRolls]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.P_AccessRolls    Script Date: 11/10/00 10:24:19 AM ******/
Create Procedure [dbo].[P_AccessRolls] as
/* Created for City of Barrie */
/* a Customized procedure to load the Access Data into the Property Table. */

Declare Curs_0004 Cursor For
	Select PropNum from Dc_AccessProperty Group by PropNum

DECLARE @c_PropertyRoll Char(19)
DECLARE @c_LegalDesc Char(255)
Declare @n_MinRSN INT
DECLARE @n_RSN INT
DECLARE @n_MaxRSN INT

SELECT @n_MaxRSN = MAX(PropertyRSN) 
From Property

OPEN Curs_0004
FETCH Curs_0004 INTO @c_PropertyRoll
While @@FETCH_Status = 0
BEGIN
	SELECT @n_MINRSN = Min(RSN) 
	From  Dc_AccessProperty
	where PropNum = @c_PropertyRoll

	SELECT  @c_LegalDesc = Location 
	From Dc_AccessProperty
	where RSN = @n_MINRSN

	SELECT @n_MAXRSN = @n_MaxRSN + 1

	BEGIN TRAN
	INSERT INTO PROPERTY(PropertyRSN,PropertyRoll, LegalDesc ,PropHistoric, StampUser, 	Stampdate)
	VALUES  (@n_MaxRSN, @c_PropertyRoll, @c_LegalDesc, 'P', 'sa',GETDATE())
	COMMIT

	FETCH Curs_0004 INTO @c_PropertyRoll
END
Close Curs_0004
Deallocate Curs_0004



GO
