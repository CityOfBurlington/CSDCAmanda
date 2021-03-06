USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_SAS_00001C]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[P_SAS_00001C](@ArgControlAssessmentRSN int)
AS

/* Procedure Altered Dated : 2001.05.01 */
/* Status  9 Not in Amanda or  Not in KK also */
/* Status  8  in Amanda  */
/* Status  3 Updatable but match has more than one propertyrsn in Amanda  */
/* Status  2 Purely Updatable has only one match */
/* Status  1 Purely New Property */
/* Search for Matching Properties */
	DECLARE @c_RollNumber Char(19)
	DECLARE @n_RollCount  Int
	DECLARE @n_RollMatch  int
	DECLARE @n_RollMatchUpdate int
	DECLARE @n_RollNotMatch int
	DECLARE @c_TimeStart  Char(30)
	DECLARE @c_TimeFinish Char(30)
/* KK Variables */
	DECLARE @n_KKCount 	int	
	DECLARE @n_MinKKRSN 	int
	DECLARE @n_Number    	int
	DECLARE @c_Unit     	Char(5)
	DECLARE  @c_Street    	Char(17)
/* BB Variables */
	DECLARE @f_Frontage Float
	DECLARE @f_Area Float
	DECLARE @f_DepthOrFFEAcreage Float
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

/* Temp Tables */
	DECLARE C_X_AA CURSOR FOR  
	SELECT 	RollNumber  /* RollNumber */
	FROM 	X_AA   
	WHERE   RIGHT(RollNumber,4) = '0000'


/* Start X AA RollMatch */
	SELECT @n_RollMatch 		= 0
	SELECT @n_RollNotMatch 		= 0
	SELECT @n_RollMatchUpdate  	= 0

	OPEN C_X_AA
	FETCH NEXT FROM C_X_AA INTO @c_RollNumber
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		SELECT 	@n_RollCount  = Count(PropertyRSN)
		FROM  	X_Property 
		WHERE 	PropertyRoll = @c_RollNumber

		IF 	@n_RollCount = 0 
		BEGIN
			/* Roll Not Found - Start Check Record in KK Tables */
			SELECT @n_KKCount = Count(*) 
			FROM X_KK 
			WHERE RollNumber = @c_RollNumber

			IF @n_KKCount > 0
			/* Roll Found - Start Check Record in KK Tables for Street */
			BEGIN		
				SELECT @n_MinKKRSN = Min(KKRSN) 
				FROM X_KK
				WHERE RollNumber = @c_RollNumber
				SELECT	@n_Number = ISNULL(StreetNumber,0),					 
					@c_Unit   = ISNULL(LTRIM(RTRIM(UnitNumber)),'NULL'),
					@c_Street = ISNULL(StreetName,'NULL')
				FROM 	X_KK
				WHERE	KKRSN = @n_MinKKRSN
				
				IF @n_Number = 0  								
				BEGIN
					GOTO KKLEAVE
				END

				IF  @c_Street  = 'NULL'
			 
				BEGIN
					GOTO KKLEAVE
				END
				SELECT @n_KKCount = 0

			EXEC 	P_SAS_00002C @ArgControlAssessmentRSN,@c_RollNumber,@n_Number, @c_Unit, @c_Street, @n_KKCount

			GOTO GETROLL

			END
			ELSE
			BEGIN
			KKLEAVE:			

			/* 9 refers No KK Record and PropCode is Pending */	
				SELECT 	@n_MinBBCount = Min(BBRSN) 
				FROM 		X_BB
				WHERE 	Rollnumber = @c_RollNumber
				IF @n_MinBBCount > 0 
				BEGIN
					SELECT @f_Frontage	=  ROUND(Frontage,2),
					@f_Area		 	=  ROUND(SiteArea,2),
					@n_PropCode		= PropertyCode,
					@f_DepthORFFEAcreage	=  ROUND(DepthOrFFEAcreage,2),
					@c_Zoning 		= Zoning,
					@c_UFFI			= UFFI
					FROM X_BB
					WHERE BBRSN = @n_MinBBCount	
				END
					SELECT @n_LLCount = Count(*)			 
					FROM  X_LL
					WHERE RollNumber = @c_RollNumber
					IF @n_LLCount > 0 
				BEGIN
					SELECT @n_MinLL = MIN(LLRSN), @n_MaxLL = MAX(LLRSN) 
					FROM X_LL
					WHERE RollNumber = @c_RollNumber
					WHILE @n_MinLL <= @n_MaxLL
					BEGIN
						SELECT @c_LegalDesc = LegalDesc
						FROM X_LL
						WHERE RollNumber = @c_RollNumber
						SELECT @c_LegalFull = @c_LegalFull + 							@c_LegalDesc
						SELECT @n_MinLL = @n_MinLL + 1
					END	
				END

				INSERT INTO X_SAS_Property(SasStatus,
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
				(9,
				 0,
				 @c_RollNumber,
				 @n_PropCode,
				 'sa',
				 GetDate(),
				@f_Frontage,
				@f_Area,
				@f_DepthORFFEAcreage,
				@c_Zoning,
				@c_UFFI,
				@c_LegalFull,
				CONVERT(CHAR(7),@n_Number),
				@c_Street,
				null,
				null,
				@c_Unit,
				@ArgControlAssessmentRSN)

			/* Roll Not Found - End Check Record in KK Tables */
			END	
		END
		GETROLL:
		FETCH NEXT FROM C_X_AA INTO @c_RollNumber 
	END
	CLOSE C_X_AA
	DEALLOCATE C_X_AA


/* END  X AA RollMatch */                                                                                                                                                                                           

GO
