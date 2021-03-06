USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_SAS_00003CAA]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[P_SAS_00003CAA] AS
/* Procedure Altered Dated : 2001.05.01 */
BEGIN
         Insert into Property_SAS_AA(
	 AARSN  ,
	 AssessmentDate ,
	 PropertyRSN ,
	 RollNumber ,
	 RecordType ,
	 Ward   ,
	 Poll  ,
	 PollSuffix ,
	 HighSchoolCode,
	 PublicSchoolCode  ,
	 SeparateSchoolCode ,
	 SpecialRateArea,
	 NeighbourhoodNumber,
	 PreviousRollNumber,
	 AssessmentClass ,
	 FrenchSchoolCode,
	 UpdateSource,
	 StampDate   ,
	 StampUser ,
	 ControlAssessmentRSN,
	 FolderRSN ,
	 FrenchPublicSchoolCode,
	 FrenchCatholicSchoolCode,
	 SystemSortNumber,
	 OmitSuppIndicator,
	 OmitSuppSequence ,
	 EffectiveDate   
	 )
	 SELECT AARSN ,
	 	 AssessmentDate  ,
	 	 PropertyRSN   ,
	 	 RollNumber  ,
	 	 RecordType ,
	 	 Ward,
	 	 Poll ,
	 	 PollSuffix,
	 	 HighSchoolCode,
	 	 PublicSchoolCode ,
	 	 SeparateSchoolCode ,
	 	 SpecialRateArea,
	 	 NeighbourhoodNumber,
	 	 PreviousRollNumber,
	 	 AssessmentClass   ,
	 	 FrenchSchoolCode ,
	 	 UpdateSource,
	 	 StampDate,
	 	 StampUser,
		 ControlAssessmentRSN ,
	 	 FolderRSN,
		 FrenchPublicSchoolCode,
		 FrenchCatholicSchoolCode,
	 	 SystemSortNumber,
	 	 OmitSuppIndicator ,
	 	 OmitSuppSequence ,
	 	 EffectiveDate
		 FROM X_AA
END

GO
