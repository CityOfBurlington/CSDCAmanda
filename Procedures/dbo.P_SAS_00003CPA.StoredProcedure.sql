USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_SAS_00003CPA]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Modified to update OmitSuppCVA column in x_PA and Property_SAS_PA tables */ 
 
 CREATE Procedure [dbo].[P_SAS_00003CPA] AS  
/* Procedure Altered Dated : 2001.05.01 */  
/* Modified Jan 20, 2009: in the table Property_SAS_PA: change PhaseInValue for PropertyTotal
    and adding the CurrentValueAssessmentTotal and CurrentValueAssessmentPortion */
/* Amanda 44v27: HOng: Modified July 2, 2009: adding the OmitSuppCVA into x_PA and Property_SAS_PA */

BEGIN  
INSERT INTO Property_SAS_PA  
 (PARSN,  
 AssessmentDate,  
 PropertyRSN,  
 RollNumber,  
 RecordType,  
 SEQUENCENumber,  
-- PropertyTOTAL,
 PhaseInValue, 
 UnitClass,  
 REALTYTaxClass,  
 BUSINESSTaxClass,  
 BUSINESSPERCENTAGE,  
 AUTHORITYFORChange,  
 REALTYREASON,  
 BUSINESSREASON,  
 EffectiveDate,  
 TENANTTaxLIABILITY,  
 NOTICEISSUED,  
 PREVYearAssessment,  
 PublicLYTRAdEDUnit,  
 PARTNERSHIPCode,  
 UpdateSource,  
 StampDate,  
 StampUser,  
 ControlAssessmentRSN,  
 PropertyClassCode,  
 FolderRSN,  
 REALTYTaxQUALIFIER,  
 REALTYTaxClassPrevious,  
 REALTYTaxQUALIFIERPrevious,  
 EffectiveDateOFOS,  
 POOLEDTaxESUnit,  
 SYSTEMSORTNumber,  
 OMITSUPPINDICATOR,  
 OMITSUPPSEQUENCE,  
 EffectiveDateOFLASTChange,  
 UnitSUPPORT,
 CurrentValueAssessmentTotal ,
 CurrentValueAssessmentPortion,
 OmitSuppCVA)  
  SELECT  
  X_PA.PARSN,  
  X_PA.AssessmentDate,  
  X_PA.PropertyRSN,  
  X_PA.RollNumber,  
  X_PA.RecordType,  
  X_PA.SEQUENCENumber,  
  --X_PA.PropertyTOTAL, 
  X_PA.PhaseInValue,  
  X_PA.UnitClass,  
  X_PA.REALTYTaxClass,  
  X_PA.BUSINESSTaxClass,  
  X_PA.BUSINESSPERCENTAGE,  
  X_PA.AUTHORITYFORChange,  
  X_PA.REALTYREASON,  
  X_PA.BUSINESSREASON,  
  X_PA.EffectiveDate,  
  X_PA.TENANTTaxLIABILITY,  
  X_PA.NOTICEISSUED,  
  X_PA.PREVYearAssessment,  
  X_PA.PublicLYTRAdEDUnit,  
  X_PA.PARTNERSHIPCode,  
  X_PA.UpdateSource,  
  X_PA.StampDate,  
  X_PA.StampUser,  
  X_PA.ControlAssessmentRSN,  
  X_PA.PropertyClassCode,  
  X_PA.FolderRSN,  
  X_PA.REALTYTaxQUALIFIER,  
  X_PA.REALTYTaxClassPrevious,  
  X_PA.REALTYTaxQUALIFIERPrevious,  
  X_PA.EffectiveDateOFOS,  
  X_PA.POOLEDTaxESUnit,  
  X_PA.SYSTEMSORTNumber,  
  X_PA.OMITSUPPINDICATOR,  
  X_PA.OMITSUPPSEQUENCE,  
  X_PA.EffectiveDateOFLASTChange,  
  X_PA.UnitSUPPORT ,
  X_PA.CurrentValueAssessmentTotal,
  X_PA.CurrentValueAssessmentPortion,
  X_PA.OmitSuppCVA 
 FROM  X_PA  
END  


GO
