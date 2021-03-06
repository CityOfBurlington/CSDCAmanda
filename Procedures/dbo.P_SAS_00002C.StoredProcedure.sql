USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_SAS_00002C]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[P_SAS_00002C] (@ArgControlAssessmentRSN int, @ArgRollNumber Char(19),@ArgNumber int , @ArgUnit char(5),  @ArgStreet Char(17), @ArgFound int OUTPUT) 
AS

/* Procedure Altered Dated : 2001.05.01 */
DECLARE @n_Street 	int
DECLARE @c_StreetName 	Char(17)
DECLARE @c_StreetType 	Char(17)
DECLARE @c_StreetDirect Char(17)
DECLARE @c_StreetUnit 	Char(17)
DECLARE @c_Street		Char(17)
DECLARE @c_Block1		Char(17)
DECLARE @c_Block2		Char(17)
DECLARE @c_Block3		Char(17)
DECLARE @c_Block4		Char(17)
DECLARE @n_StartAt		int
DECLARE @n_Length		int
DECLARE @n_FullLength		int
DECLARE @n_PropCount    	int
DECLARE @c_Number 		Char(10)
DECLARE @n_Block3 		int

DECLARE @n_Filter 		int

/* BB Variables */
	DECLARE @f_Frontage Float
	DECLARE @f_Area Float
	DECLARE @f_DepthOrFFEAcreage  
Float
	DECLARE @c_Zoning Char(12)
	DECLARE @c_UFFI    Char(1)
	DECLARE @n_MinBBCount Int
	DECLARE @n_PropCode int

/* LL Variables */
	DECLARE @c_LegalDesc Char(28)
	DECLARE @c_LegalFull Char(255)
	DECLARE @n_MaxLL Int
	DECLARE @n_MinLL  Int
	DECLARE @n_LLCount int


/* X_SAS_Property Variables */

DECLARE @n_SASStatus int 

SELECT @c_Street = LTRIM(RTRIM(@ArgStreet))

SELECT @c_Block1 = ''
SELECT @c_Block2 = ''
SELECT @c_Block3 = ''
SELECT @c_Block4 = ''

/* Max Blanks in StreetName is 3 */
/* Parse the Street */

SELECT @n_FullLength = DATALENGTH(LTRIM(RTRIM(@c_Street)))

SELECT @n_StartAT    = CHARINDEX(' ',LTRIM(RTRIM(@c_Street)))

IF @n_StartAT > 0 
  BEGIN
   SELECT @c_Block1 = LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(@c_Street)),1,@n_StartAt - 1)))
   SELECT @c_Block2 = LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(@c_Street)),@n_StartAT + 1,@n_FullLength - @n_StartAt)))
   SELECT @n_FullLength = DATALENGTH(LTRIM(RTRIM(@c_Block2)))
  END
ELSE
  BEGIN
   SELECT @c_Block1 = LTRIM(RTRIM(@c_Street))
  END

SELECT @n_Length = DATALENGTH(LTRIM(RTRIM(@c_Block2)))
IF @n_Length > 0 
 BEGIN
  SELECT @n_StartAT    = CHARINDEX(' ',LTRIM(RTRIM(@c_Block2)))
  IF @n_StartAT > 0 
   BEGIN
    SELECT @c_Block3 = LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(@c_Block2)),@n_StartAt + 1,@n_FullLength - @n_StartAt)))
    SELECT @c_Block2 = LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(@c_Block2)),1,@n_StartAt - 1)))
    SELECT @n_FullLength = DATALENGTH(LTRIM(RTRIM(@c_Block3)))
   END
 END

SELECT @n_Length = DATALENGTH(LTRIM(RTRIM(@c_Block3)))
IF @n_Length > 0 
 BEGIN
  SELECT @n_StartAT    = CHARINDEX(' ',LTRIM(RTRIM(@c_Block3)))
  IF @n_StartAT > 0 
   BEGIN
    SELECT @c_Block4 = LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(@c_Block3)),@n_StartAt + 1,@n_FullLength - @n_StartAt)))
    SELECT @c_Block3 = LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(@c_Block3)),1,@n_StartAt - 1)))
  END
 END


DECLARE	@n_TypeCount int
SELECT 	@n_TypeCount = Count(*)
FROM 		X_SAS_StreetType 
WHERE 	UPPER(LTRIM(RTRIM(PropStreetType))) = UPPER(LTRIM(RTRIM(@c_block2)))

IF @n_TypeCount = 0 
BEGIN 
	SELECT @c_Block1  = @c_Block1 +  Space(1) + @c_Block2
	SELECT @c_Block2  = @c_Block3
	SELECT @c_Block3  = @c_Block4
END




SELECT @c_Number = Convert(Char(10),@ArgNumber)
SELECT @n_Filter = 4
DECLARE @n_checkLen int
DECLARE @c_B3 char(3)


SELECT @n_CheckLen = DATALENGTH(LTRIM(RTRIM(@c_Block3))) 
IF @n_CheckLEN > 0 
BEGIN
Select @c_B3 = 'YES'
END 
ELSE
BEGIN
Select @c_B3 = 'NOT'
END 


/* Unit is Null and Direction is Null */
IF LTRIM(RTRIM(@ArgUnit)) = 'NULL' and   @c_B3 = 'NOT'
BEGIN
      
	SELECT @n_PropCount = Count(PropertyRSN) 
	FROM X_property
	Where  LTRIM(RTRIM(PropStreet))		= LTRIM(RTRIM(@c_Block1))
	and    LTRIM(RTRIM(PropStreetType))		= LTRIM(RTRIM(@c_Block2))
	and    LTRIM(RTRIM(PropHouse))		= LTRIM(RTRIM(@c_Number))
	and    PropStreetDirection 			is Null
	and    PropUnit					is Null
	and 	PropertyRoll				is Null
	DECLARE @mycount int
	SELECT  @myCount = @n_PropCount	

	IF @n_PropCount = 1
	/* SAS Status = 2 */
	BEGIN
		SELECT @n_SASStatus = 2
	END
	ELSE
	BEGIN
		IF @n_PropCount > 1
		BEGIN
		SELECT @n_SASStatus = 3
		END
		ELSE
		BEGIN
		SELECT @n_SASStatus  = 1
		END
	END	

SELECT @n_Filter = 1
END 

IF  LTRIM(RTRIM(@ArgUnit)) = 'NULL' and   @c_B3 = 'YES'
BEGIN
	SELECT @n_PropCount = Count(PropertyRSN) 
	FROM X_Property
	Where   LTRIM(RTRIM(PropStreet))	= LTRIM(RTRIM(@c_Block1))
	and   LTRIM(RTRIM(PropStreetType))	= LTRIM(RTRIM(@c_Block2))
	and    LTRIM(RTRIM(PropHouse))	= LTRIM(RTRIM(@c_Number))
	and   LTRIM(RTRIM(PropStreetDirection)) 	= LTRIM(RTRIM(@c_Block3))
	and   PropUnit			is Null
	and 	PropertyRoll		is Null
 

	IF @n_PropCount = 1

	/* SAS Status = 2 */
	BEGIN
		SELECT @n_SASStatus = 2
	END
	ELSE
	BEGIN
		IF @n_PropCount > 1
		BEGIN
		SELECT @n_SASStatus = 3
		END
		ELSE
		BEGIN
		SELECT @n_SASStatus = 1
		END
		
	END	
SELECT @n_Filter = 2
 
END

IF  LTRIM(RTRIM(@ArgUnit)) <> 'NULL' and   @c_B3 = 'NOT'
BEGIN
	SELECT @n_PropCount = Count(PropertyRSN) 
	FROM X_Property
	Where LTRIM(RTRIM(PropStreet))		= LTRIM(RTRIM(@c_Block1))
	and  LTRIM(RTRIM( PropStreetType))		= LTRIM(RTRIM(@c_Block2))
	and  LTRIM(RTRIM( PropHouse))		= LTRIM(RTRIM(@c_Number))
	and   PropStreetDirection 	is Null
	and   LTRIM(RTRIM(PropUnit))			= LTRIM(RTRIM(@ArgUnit))
	and 	PropertyRoll		is Null

	IF @n_PropCount = 1
	/* SAS Status = 2  */
	BEGIN
		SELECT @n_SASStatus = 2
	END
	ELSE
	BEGIN
		IF @n_PropCount > 1
		BEGIN
		SELECT @n_SASStatus = 3
		END
		ELSE
		BEGIN
		SELECT @n_SASStatus = 1
		END
		
	END	
SELECT @n_Filter = 3
END

IF @n_Filter = 4 
BEGIN
/* All Vari 
ables have Values */
	SELECT @n_PropCount = Count(PropertyRSN) 
	FROM X_Property
	Where  LTRIM(RTRIM(PropStreet))		= LTRIM(RTRIM(@c_Block1))
	and   LTRIM(RTRIM(PropStreetType))		= LTRIM(RTRIM(@c_Block2))
	and   LTRIM(RTRIM(PropHouse))			= LTRIM(RTRIM(@c_Number))
	and   LTRIM(RTRIM(PropStreetDirection ))	= LTRIM(RTRIM(@c_Block3))
	and  LTRIM(RTRIM( PropUnit))			= LTRIM(RTRIM(@ArgUnit))
	and 	PropertyRoll		is Null

	IF @n_PropCount = 1
	/* SAS Status = 2 */
	BEGIN
		SELECT @n_SASStatus = 2
	END

	ELSE
	BEGIN
		IF @n_PropCount > 1
		BEGIN
		SELECT @n_SASStatus = 3
		END
		ELSE
		BEGIN
		SELECT @n_SASStatus = 1
		END
		
	END	
END

IF @n_Filter = 1
BEGIN
	IF @n_SASStatus = 2 OR @n_SASStatus = 3
	BEGIN

		INSERT INTO X_SAS_Property(
		SASStatus,
		PropertyRoll,
		PropertyRSN,
		PropCode,
		PropHouse,
		PropStreet,
		PropStreetType,
		PropStreetDirection,
		PropUnit,
		LegalDesc,
		StampUser,
		StampDate,
		ControlAssessmentRSN)
		SELECT 
		@n_SASStatus,
		@ArgRollNumber,
		X_Property.PropertyRSN,
		X_Property.PropCode,
		X_Property.PropHouse,
		X_Property.PropStreet,
		X_Property.PropStreetType,
		X_Property.PropStreetDirection,
		X_Property.PropUnit,
		X_Property.LegalDesc,
		X_Property.StampUser,
		X_Property.StampDate,
		@ArgControlAssessmentRSN
		FROM X_Property
		Where  LTRIM(RTRIM(PropStreet))			= LTRIM(RTRIM(@c_Block1))
		and    LTRIM(RTRIM(PropStreetType))		= LTRIM(RTRIM(@c_Block2))
		and    LTRIM(RTRIM(PropHouse))			= LTRIM(RTRIM(@c_Number))
		and    PropStreetDirection 			is Null
		and    PropUnit					is Null
		and 	PropertyRoll				is Null

                           
		RETURN @n_PropCount
                      
		END
END

IF @n_Filter = 2
BEGIN
	IF @n_SASStatus = 2 OR @n_SASStatus = 3
	BEGIN

		INSERT INTO  X_SAS_Property(
		SASStatus,
		PropertyRoll,
		PropertyRSN,
		PropCode,
		PropHouse,
		PropStreet,
		PropStreetType,
		PropStreetDirection,
		PropUnit,
		LegalDesc,
		StampUser,
		StampDate,
		ControlAssessmentRSN)
		SELECT 
		@n_SASStatus,
		@ArgRollNumber,
		X_Property.PropertyRSN,
		X_Property.PropCode,
		X_Property.PropHouse,
		X_Property.PropStreet,
		X_Property.PropStreetType,
		X_Property.PropStreetDirection,
		X_Property.PropUnit,
		X_Property.LegalDesc,
		X_Property.StampUser,
		X_Property.StampDate,
		@ArgControlAssessmentRSN
		FROM X_Property
		Where LTRIM(RTRIM(PropStreet))		= LTRIM(RTRIM(@c_Block1))
		and   LTRIM(RTRIM(PropStreetType))		= LTRIM(RTRIM(@c_Block2))
		and   LTRIM(RTRIM(PropHouse))			= LTRIM(RTRIM(@c_Number))
		and   LTRIM(RTRIM(PropStreetDirection)) 	= LTRIM(RTRIM(@c_Block3))
		and   PropUnit			is Null
		and 	PropertyRoll		is Null
		RETURN @n_PropCount
		END
              

	END


IF @n_Filter = 3
BEGIN
	IF @n_SASStatus = 2 OR @n_SASStatus  = 3                                                                                                                                                                                                                                                            

	BEGIN

		INSERT INTO X_SAS_Property(
		SASStatus,
		PropertyRoll,
		PropertyRSN,
		PropCode,
		PropHouse,
		PropStreet,
		PropStreetType,
		PropStreetDirection,
		PropUnit,
		LegalDesc,
		StampUser,
		StampDate,
		ControlAssessmentRSN)
		SELECT 
		@n_SASStatus,
		@ArgRollNumber,
		X_Property.PropertyRSN,
		X_Property.PropCode,
		X_Property.PropHouse,
		X_Property.PropStreet,
		X_Property.PropStreetType,
		X_Property.PropStreetDirection,
		X_Property.PropUnit,
		X_Property.LegalDesc,
		X_Property.StampUser,
		X_Property.StampDate,
		@ArgControlAssessmentRSN
		FROM X_Property
		Where LTRIM(RTRIM(PropStreet))		= LTRIM(RTRIM(@c_Block1))
		and   LTRIM(RTRIM(PropStreetType))		= LTRIM(RTRIM(@c_Block2))
		and   LTRIM(RTRIM(PropHouse))			= LTRIM(RTRIM(@c_Number))
		and  PropStreetDirection 	is Null
		and   LTRIM(RTRIM(PropUnit))			= LTRIM(RTRIM(@ArgUnit))
		and 	PropertyRoll		is Null

		RETURN @n_PropCount
	END
END

IF @n_Filter = 4
BEGIN
	IF @n_SASStatus = 2 OR @n_SASStatus = 3
	BEGIN

			INSERT INTO X_SAS_Property(
			SASStatus,
			PropertyRoll,
			PropertyRSN,
			PropCode,
			PropHouse,
			PropStreet,
			PropStreetType,
			PropStreetDirection,
			PropUnit,
			LegalDesc,
			StampUser,
			StampDate,
			ControlAssessmentRSN)
			SELECT 
			@n_SASStatus,
			@ArgRollNumber,
			X_Property.PropertyRSN,
			X_Property.PropCode,
			X_Property.PropHouse,
			X_Property.PropStreet,
			X_Property.PropStreetType,
			X_Property.PropStreetDirection,
			X_Property.PropUnit,
			X_Property.LegalDesc,
			X_Property.StampUser,
			X_Property.StampDate,
			@ArgControlAssessmentRSN
			FROM X_Property
			Where LTRIM(RTRIM(PropStreet))		= LTRIM(RTRIM(@c_Block1))
			and   LTRIM(RTRIM(PropStreetType))		= LTRIM(RTRIM(@c_Block2))
			and   LTRIM(RTRIM(PropHouse))			= LTRIM(RTRIM(@c_Number))
			and   LTRIM(RTRIM(PropStreetDirection)) 	= LTRIM(RTRIM(@c_Block3))
			and   LTRIM(RTRIM(PropUnit))			= LTRIM(RTRIM(@ArgUnit))
			and 	PropertyRoll		is Null

		RETURN @n_PropCount

	END

END


IF @n_SASStatus = 1
BEGIN
	SELECT @n_MinBBCount = Min(BBRSN) 
	FROM  X_BB
	WHERE RollNumber = @ArgRollNumber
	IF @n_MinBBCount > 0
	BEGIN
		SELECT @f_Frontage		= ROUND(Frontage,2), 
			@f_Area		 	=  ROUND(SiteArea,2),
			@n_PropCode		= PropertyCode,
			@f_DepthORFFEAcreage	=  ROUND(DepthOrFFEAcreage,2),
			@n_PropCode 		= PropertyCode,
			@c_Zoning 		= Zoning,
			@c_UFFI			= UFFI
			FROM X_BB
			WHERE BBRSN = @n_MinBBCount	
	 END
	 ELSE
	 BEGIN	
 

		SELECT 	@f_Frontage		= 0.0
		SELECT	@f_Area		 	= 0.0
		SELECT	@n_PropCode		= 70
		SELECT	@f_DepthORFFEAcreage	= 0.0
		SELECT	@c_Zoning 		= ''
		SELECT	@c_UFFI			= ''
	  END
	
	  SELECT @n_LLCount = Count(*) 
	  FROM  X_LL
	  WHERE RollNumber =  @ArgRollNumber
	  IF @n_LLCount > 0 
 	  BEGIN
		SELECT @n_MinLL = MIN(LLRSN), @n_MaxLL = MAX(LLRSN) 
		FROM X_LL
		WHERE RollNumber = @ArgRollNumber
		WHILE @n_MinLL <= @n_MaxLL
		BEGIN
			SELECT @c_LegalDesc = LegalDesc
			FROM X_LL
			WHERE  RollNumber = @ArgRollNumber
			SELECT @c_LegalFull = @c_LegalFull + @c_LegalDesc
			SELECT @n_MinLL = @n_MinLL + 1
		END	
	   END
	   ELSE
	   BEGIN
	   SELECT @c_LegalFull = ''
	   END


IF @n_Filter = 1
	BEGIN

	INSERT INTO X_SAS_Property( 
			SasStatus,
			PropertyRSN,
			PropertyRoll,
			PropCode,
			StampUser,
			StampDate,
			PropFrontage,
			PropArea,
			PropDepth,
			ZoneType1,
			ZoneType5,
			LegalDesc,
			PropHouse,
			PropStreet,
			PropStreetType,
			PropStreetDirection,
			PropUnit,
			ControlAssessmentRSN)
			Values
			(@n_SASStatus,
			 @n_Filter,
			 @ArgRollNumber,
			 @n_PropCode,
			 'sa',
			 GetDate(),
			@f_Frontage,
			@f_Area,
			@f_DepthORFFEAcreage,
			@c_Zoning,
			@c_UFFI,
			@c_LegalFull,
			LTRIM(RTRIM(@c_Number)),
			LTRIM(RTRIM(@c_Block1)),
			LTRIM(RTRIM(@c_Block2)),
			null,
			null,
			@ArgControlAssessmentRSN)

              
	RETURN @n_PropCount
	END


IF @n_Filter = 2
	BEGIN

	INSERT INTO X_SAS_Property(
			SasStatus,
			PropertyRSN,
			PropertyRoll,
			PropCode,
			StampUser,
			StampDate,
			PropFrontage,
			PropArea,
			PropDepth,
			ZoneType1,
			ZoneType5,
			LegalDesc,
			PropHouse,
			PropStreet,
			PropStreetType,
			PropStreetDirection,
			PropUnit,
			ControlAssessmentRSN)
			Values
			(@n_SASStatus,
			 @n_Filter,
			 @ArgRollNumber,
			 @n_PropCode,
			 'sa',
			 GetDate(),
			@f_Frontage,
			@f_Area,
			@f_DepthORFFEAcreage,
			@c_Zoning,
			@c_UFFI,
			@c_LegalFull,
			LTRIM(RTRIM(@c_Number)),
			LTRIM(RTRIM(@c_Block1)),
			LTRIM(RTRIM(@c_Block2)),
			LTRIM(RTRIM(@c_Block3)),
			null,
			@ArgControlAssessmentRSN)

	RETURN @n_PropCount
               
	END

IF @n_Filter = 3
	BEGIN

	INSERT INTO X_SAS_Property(
			SasStatus, 
			PropertyRSN,
			PropertyRoll,
			PropCode,
			StampUser,
			StampDate,
			PropFrontage,
			PropArea,
			PropDepth,
			ZoneType1,
			ZoneType5,
			LegalDesc,
			PropHouse,
			PropStreet,
			PropStreetType,
			PropStreetDirection,
			PropUnit,
			ControlAssessmentRSN)
			Values
			(@n_SASStatus,
			 @n_Filter,
			 @ArgRollNumber,
			 @n_PropCode,
			 'sa',
			 GetDate(),
			@f_Frontage,
			@f_Area,
			@f_DepthORFFEAcreage,
			@c_Zoning,
			@c_UFFI,
			@c_LegalFull,
			LTRIM(RTRIM(@c_Number)),
			LTRIM(RTRIM(@c_Block1)),
			LTRIM(RTRIM(@c_Block2)),
			null,
			@ArgUnit,
			@ArgControlAssessmentRSN)

	RETURN @n_PropCount
	END

IF @n_Filter = 4
	BEGIN

	INSERT INTO X_SAS_Property(
			SasStatus,
			PropertyRSN,
			PropertyRoll,
			PropCode,
			StampUser,
			StampDate,
			PropFrontage,
			PropArea,
			PropDepth,
			ZoneType1,
			ZoneType5,
			LegalDesc,
			PropHouse,
			PropStreet,
			PropStreetType,
			PropStreetDirection,
			PropUnit,
			ControlAssessmentRSN)
			Values
			(@n_SASStatus,
			 @n_Filter,
			 @ArgRollNumber,
			 @n_PropCode,
			 'sa',
			 GetDate(),
			@f_Frontage,
			@f_Area,
			@f_DepthORFFEAcreage,
			@c_Zoning,
			@c_UFFI,
			@c_LegalFull,
			LTRIM(RTRIM(@c_Number)),
			LTRIM(RTRIM(@c_Block1)),
			LTRIM(RTRIM(@c_Block2)),
			LTRIM(RTRIM(@c_Block3)),
			LTRIM(RTRIM(@ArgUnit)),
			@ArgControlAssessmentRSN)

		RETURN @n_PropCount
	END
END

GO
