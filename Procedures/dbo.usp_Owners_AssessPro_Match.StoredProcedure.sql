USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Owners_AssessPro_Match]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Owners_AssessPro_Match]
AS
BEGIN
	DECLARE @ParcelID VARCHAR(20)
	DECLARE @AssessOwner VARCHAR(200)
	DECLARE @AmandaOwner VARCHAR(200)
	DECLARE @i INT
	SET @i = 0

	DECLARE curAssessPro CURSOR FOR
	SELECT P.ParcelID, RTRIM(LTRIM(ISNULL(O.Description, '')))
	FROM AssessPro.dbo.DataProperty P 
	INNER JOIN AssessPro.dbo.TableOwnership O ON P.OwnerLookUp = O.Code
	WHERE P.CardNumber = 1
	AND ISNULL(P.Closed, 0) = 0
	AND P.AccountNumber IN(SELECT DISTINCT AccountNumber FROM AssessPro.dbo.DataSales WHERE SaleDate < '2007-02-01')

	OPEN curAssessPro

	FETCH NEXT FROM curAssessPro INTO @ParcelID, @AssessOwner

	WHILE @@FETCH_STATUS = 0 BEGIN

		IF NOT EXISTS( SELECT People.PeopleRSN
				FROM People
				INNER JOIN PropertyPeople ON People.PeopleRSN = PropertyPeople.PeopleRSN
				INNER JOIN Property ON PropertyPeople.PropertyRSN = Property.PropertyRSN
				WHERE Property.PropertyRoll = @ParcelID
				AND PropertyPeople.PeopleCode = 2 /*Owner*/
				AND ( RTRIM(LTRIM(ISNULL(People.NameLast, ''))) = @AssessOwner
				OR RTRIM(LTRIM(ISNULL(People.OrganizationName, ''))) = @AssessOwner)) BEGIN

			BEGIN TRANSACTION
				EXEC usp_Owners_Copy_From_AssessPro @ParcelID
			COMMIT TRANSACTION 
		END

		FETCH NEXT FROM curAssessPro INTO @ParcelID, @AssessOwner
	END

	CLOSE curAssessPro
	DEALLOCATE curAssessPro
END


GO
