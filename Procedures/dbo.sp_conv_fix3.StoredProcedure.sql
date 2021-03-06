USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[sp_conv_fix3]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.sp_conv_fix3    Script Date: 11/10/00 10:24:19 AM ******/
/****** Object:  Stored Procedure dbo.sp_conv_fix3    Script Date: 11/18/1997 3:06:38 PM ******/
create procedure [dbo].[sp_conv_fix3] as
begin

   DECLARE @DefaultCountry		varchar(20) 
   DECLARE @NameTitle			varchar(50)
   DECLARE @House					varchar(7)
   DECLARE @Street				varchar(35) 
   DECLARE @StreetType			varchar(10) 
   DECLARE @StreetDir			varchar(2) 
   DECLARE @UnitType				varchar(5) 
   DECLARE @Unit					varchar(6) 
   DECLARE @City					varchar(20)
   DECLARE @Province				varchar(2)
   DECLARE @Country				varchar(20)
   DECLARE @Postal				varchar(12)
   DECLARE @AddressLine1		varchar(60)
   DECLARE @AddressLine2		varchar(60)
   DECLARE @AddressLine3		varchar(60)
   DECLARE @AddressLine4		varchar(60)
   DECLARE @AddrPrefix			varchar(64)
   DECLARE @AddrHouseNumeric	int
   DECLARE @PeopleRSN			int
   DECLARE @PeopleRSN_min		int
   DECLARE @PeopleRSN_max		int
    
   SELECT @DefaultCountry = DefaultCountry FROM ValidSite  

   SELECT @PeopleRSN_Min = min(PeopleRSN) from People 
   SELECT @PeopleRSN_Max = max(PeopleRSN) from People 
   SELECT @PeopleRSN = @PeopleRSN_Min

   SELECT @PeopleRSN     = 301000
   SELECT @PeopleRSN_max = 305000

   WHILE @PeopleRSN <= @PeopleRSN_Max
   begin

    SELECT @House = ' ' 
    SELECT @House = AddrHouse
      FROM People
     WHERE AddressLine1 = '' and AddrPrefix = '' and AddrHouse > ' ' 
       and People.PeopleRSN = @PeopleRSN

     if (@House > ' ' ) 
     begin


    SELECT @Street = AddrStreet
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @StreetType =  AddrStreetType
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @StreetDir =  AddrStreetDirection
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @UnitType =  AddrUnitType
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @Unit =  AddrUnit
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @City =  AddrCity
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @Province =  AddrProvince
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @Postal =  AddrPostal
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

    SELECT @Country =  AddrCountry
      FROM People
     WHERE People.PeopleRSN = @PeopleRSN

      SELECT @AddressLine1 = ''
      if @House > ' ' SELECT @AddressLine1 = @AddressLine1 + @House + ' ' + @Street + ' '
      if @StreetType > ' ' SELECT @AddressLine1 = @AddressLine1 + @StreetType + ' '
      if @StreetDir > ' ' SELECT @AddressLine1 = @AddressLine1 + @StreetDir + ' '
      if @UnitType > ' ' SELECT @AddressLine1 = @AddressLine1 + @UnitType + ' '
      if @Unit > ' ' SELECT @AddressLine1 = @AddressLine1 + @Unit + ' '
      SELECT @AddressLine1 = upper(@AddressLine1)

      SELECT @Addressline2 = ''
      if @City > ' ' SELECT @Addressline2 = @Addressline2 + @City + ' ' 
      if @Province > ' ' SELECT @Addressline2 = @Addressline2 + @Province + ' '
      if datalength(@Postal) = 6 SELECT @Addressline2 = @Addressline2 + substring(@Postal,1,3) + ' ' + right(@Postal,3) + ' '
      if datalength(@Postal) > 6 SELECT @Addressline2 = @Addressline2 + @Postal + ' '
      SELECT @Addressline2 = upper(@Addressline2)

      SELECT @Addressline3 = ''
      if upper(@Country) <> upper(@DefaultCountry) and @Country <> 'CAN' SELECT @Addressline3 = upper(@Country) 
      begin 


	begin transaction 

	Update People 
         set AddressLine1 = @AddressLine1,
             AddressLine2 = @AddressLine2,
             AddressLine3 = @AddressLine3,
             StampUser = 'fix3',
             StampDate = GetDate() 
       where PeopleRSN = @PeopleRSN 
                commit 
      end 
      end

      SELECT @PeopleRSN = @PeopleRSN + 1
   end 
end 




GO
