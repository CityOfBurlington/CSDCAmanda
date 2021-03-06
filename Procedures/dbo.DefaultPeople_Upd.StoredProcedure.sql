USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultPeople_Upd]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DefaultPeople_Upd] @PeopleRSN int, @UserId char(128) as DECLARE @NextRSN int
DECLARE @n_peopleCode int
DECLARE @n_ownerCount int
DECLARE @AddrLine1 VARCHAR(60)
DECLARE @AddrLine2 VARCHAR(60)
DECLARE @AddrLine3 VARCHAR(60)
DECLARE @AddrLine4 VARCHAR(60)
DECLARE @FullAddrLine VARCHAR(60)
DECLARE @City VARCHAR(40)
DECLARE @State VARCHAR(2)
DECLARE @Zip VARCHAR(12)
DECLARE @Phone VARCHAR(32)
DECLARE @Email VARCHAR(128)
DECLARE @StampUser VARCHAR(128)

DECLARE @NoAddr INT
DECLARE @NoCity INT
DECLARE @NoState INT
DECLARE @NoZip INT
DECLARE @NoPhone INT
DECLARE @NoEmail INT

SELECT @n_peopleCode = peopleCode, @AddrLine1 = RTRIM(LTRIM(ISNULL(AddressLine1,''))), 
@AddrLine2 = RTRIM(LTRIM(ISNULL(AddressLine2, ''))), @AddrLine3 = RTRIM(LTRIM(ISNULL(AddressLine3,''))), 
@AddrLine4 = RTRIM(LTRIM(ISNULL(AddressLine4,''))), 
@FullAddrLine = RTRIM(LTRIM(ISNULL(AddrHouse,''))) + RTRIM(LTRIM(ISNULL(AddrStreet,''))) + 
RTRIM(LTRIM(ISNULL(AddrStreetType,''))) + RTRIM(LTRIM(ISNULL(AddrPrefix, ''))),
@City = RTRIM(LTRIM(ISNULL(AddrCity,''))), @State = RTRIM(LTRIM(ISNULL(AddrProvince,''))), 
@Zip = RTRIM(LTRIM(ISNULL(AddrPostal,''))), @Phone = RTRIM(LTRIM(ISNULL(Phone1, ''))),
@Email = RTRIM(LTRIM(ISNULL(EmailAddress,''))), @StampUser = StampUser
FROM people WHERE peopleRSN = @peopleRSN

SELECT @n_ownerCount = count(*) 
FROM propertyPeople
WHERE peopleRSN = @peopleRSN
AND peopleCode = 2

IF @n_peopleCode IS NULL 
BEGIN
	RAISERROR('You must choose a People Type (May I suggest Person or Organization?)',16,-1)
	Return
END

IF @UserID <> 'sschrader' AND @UserID <> 'sduck' AND @UserID <>'sa' AND @UserID <> 'abovee'
BEGIN

	IF LEN(@FullAddrLine) = 0 SET @NoAddr = 1 ELSE SET @NoAddr = 0
	IF LEN(@City) = 0 SET @NoCity = 1 ELSE SET @NoCity = 0
	IF LEN(@State) = 0 SET @NoState = 1 ELSE SET @NoState = 0
	IF LEN(@Zip) = 0 SET @NoZip = 1 ELSE SET @NoZip = 0
	IF LEN(@Email) = 0 SET @NoEmail = 1 ELSE SET @NoEmail = 0
	IF LEN(@Phone) = 0 OR CAST(SUBSTRING(@Phone,4,7) AS INT) = 0 SET @NoPhone = 1 ELSE SET @NoPhone = 0

	/* If you enter an adress, a phone number or an email address */
	IF @NoAddr = 0 OR @NoCity = 0 OR @NoState = 0 OR @NoZip = 0
	BEGIN
		IF @NoAddr = 1 
		BEGIN
			IF @NoPhone = 1 AND @NoEmail = 1
			BEGIN
				RAISERROR('You must enter an Address (or phone or email address).',16,-1)
				RETURN
			END
		END
		
		IF @NoCity = 1
		BEGIN
			IF @NoPhone = 1 AND @NoEmail = 1
			BEGIN
				RAISERROR('You must enter a City (or phone or email address).',16,-1)
				RETURN
			END
		END
		
		IF @NoState = 1
		BEGIN
			IF @NoPhone = 1 AND @NoEmail = 1
			BEGIN
				RAISERROR('You must enter a State (or phone or email address).',16,-1)
				RETURN
			END
		END
		
		IF @NoZip = 1
		BEGIN
			IF @NoPhone = 1 AND @NoEmail = 1
			BEGIN
				RAISERROR('You must enter a Zip Code.',16,-1)
				RETURN
			END
		END
	END
END
		
			
IF @n_PeopleCode = 40000 		/* Commissions, Boards, and Committees (CBC Folder) JA 7/2013 */
BEGIN	
	/* Check for duplicate board entry - code is inelegant but there are no options available with People. 
	   CBC Folder.SubCode is for board name. */
	
	DECLARE @varOrganizationName varchar (100)
	DECLARE @intOrganizationNameCount int
	DECLARE @varErrorMessage varchar(200)
	
	SELECT @varOrganizationName = People.OrganizationName
	FROM People 
	WHERE People.PeopleRSN = @PeopleRSN 
	
	SELECT @intOrganizationNameCount = COUNT(*)
	FROM People 
	WHERE People.OrganizationName = @varOrganizationName 
	
	IF @intOrganizationNameCount > 1
	BEGIN
		SELECT @varErrorMessage = 'A People record for ' + @varOrganizationName + ' has already been created. Please exit and use that one.'
		ROLLBACK TRANSACTION
		RAISERROR (@varErrorMessage, 16, -1)
		RETURN
	END
END

GO
