USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Upd_Ownerpeople_rsn]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[Upd_Ownerpeople_rsn] 
AS
begin

DECLARE @Lookupcode int,
	@AccountNumber   varchar(100),
	@Owner1LastName   varchar(100),
	@Owner1FirstName   varchar(100),
	@MailStreet1	varchar(100),
	@MailStreet2	varchar(100),
	@City	varchar(100),
	@StateProv	varchar(100),
	@Country	varchar(100),
	@Postal	varchar(100),	
        @MaxRSN int

DECLARE cu_updpeoplersn CURSOR FOR
select TOS.Code, DP.AccountNumber, CO.Owner1LastName,CO.Owner1FirstName, CO.MailStreet1, CO.MailStreet2, 
CO.City, CO.StateProv, CO.Country, CO.Postal
from assesspro.dbo.DC_CSDCOwnerChanges CO,assesspro.dbo.Dataproperty DP, assesspro.dbo.TableOwnerShip TOS
where cardnumber = 1
and CO.AccountNumber = DP.AccountNumber
and DP.OwnerLookup = TOS.Code
and CONVERT(varchar(100),TOS.Code) not in(select InfoValue from peopleinfo where infocode = 10 and infovalue is not null)

OPEN cu_updpeoplersn
FETCH cu_updpeoplersn INTO
	@Lookupcode,
	@AccountNumber,
	@Owner1LastName,
	@Owner1FirstName,
	@MailStreet1,
	@MailStreet2,
	@City,
	@StateProv,
	@Country,
	@Postal
WHILE @@FETCH_STATUS = 0

BEGIN
	SELECT @MaxRSN = max(peoplersn)+1 FROM People
	
	INSERT INTO People(PeopleRSN,NameFirst,NameLast,NameFirstUpper,NameLastUpper,AddressLine1,AddressLine2,AddrCity,
	AddrProvince,AddrCountry,AddrPostal,Licencenumber,AddressLine3)
	VALUES(@MaxRSN,substring(@Owner1FirstName,1,25),substring(@Owner1LastName,1,25),substring(UPPER(@Owner1FirstName),1,25),
	substring(UPPER(@Owner1LastName),1,25), substring(@MailStreet1,1,60), substring(@MailStreet2,1,60), 
	substring(@City,1,20),substring(@StateProv,1,2),substring(@Country,1,20),substring(@Postal,1,12),@Lookupcode,ltrim(substring(@City,1,20)+' '+substring(@StateProv,1,2)+' '+substring(@Postal,1,12)))
	
	INSERT INTO PeopleInfo(PeopleRSN,Infovalue,infocode) VALUES(@MaxRSN,@Lookupcode,10) 
		
FETCH cu_updpeoplersn INTO
	@Lookupcode,
	@AccountNumber,
	@Owner1LastName,
	@Owner1FirstName,
	@MailStreet1,
	@MailStreet2,
	@City,
	@StateProv,
	@Country,
	@Postal
END

CLOSE   cu_updpeoplersn
DEALLOCATE   cu_updpeoplersn
END

GO
