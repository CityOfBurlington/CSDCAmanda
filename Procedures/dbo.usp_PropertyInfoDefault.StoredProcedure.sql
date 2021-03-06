USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_PropertyInfoDefault]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_PropertyInfoDefault](@intPropertyRSN int, @strUserID varchar(8))
AS
BEGIN 
   /* Sets up and manages PropertyInfo fields.  
      Requires updates when new PropertyInfo fields are added.  
      Default fields are identified by ValidPropertyInfo.PropCode = 100.    
      JA 1/09 */

	DECLARE @intPropertyType int

	SELECT @intPropertyType = Property.PropCode
	FROM Property
	WHERE Property.PropertyRSN = @intPropertyRSN

	IF @intPropertyType < 101
	BEGIN

   /* Set variables for default PropertyInfo fields */
   DECLARE @LandUseCodeInfoField int
   DECLARE @LandUseCodeInfoCode int 
   DECLARE @NoResUnitsInfoField int
   DECLARE @NoResUnitsInfoCode int
   DECLARE @NoResRentalInfoField int
   DECLARE @NoResRentalInfoCode int 
   DECLARE @YearBuiltInfoField int
   DECLARE @YearBuiltInfoCode int
   DECLARE @NoParkingSpacesInfoField int
   DECLARE @NoParkingSpacesInfoCode int
   DECLARE @EasementsInfoField int
   DECLARE @EasementsInfoCode int
   DECLARE @HistoricInfoField int
   DECLARE @HistoricInfoCode int
   DECLARE @1990ZoningInfoField int
   DECLARE @1990ZoningInfoCode int
   DECLARE @AssessProAcctInfoField int
   DECLARE @AssessProAcctInfoCode int

   /* Set variables for other PropertyInfo fields */
   DECLARE @ExemptRentRegInfoCode int
   DECLARE @ExemptUnitsInfoCode int
   DECLARE @LastMHInspecInfoCode int
   DECLARE @COCIssueDateInfoCode int
   DECLARE @COCExpiryDateInfoCode int
   DECLARE @COCYearsInfoCode int
   DECLARE @OwnershipInfoCode int
   DECLARE @2011EstFMV int
   DECLARE @FloodplainInfoCode int
   DECLARE @WetlandInfoCode int
   DECLARE @NaturalAreaInfoCode int
   DECLARE @OverlayDesignInfoCode int
   DECLARE @OverlayICCInfoCode int
   DECLARE @OverlayRHBonusInfoCode int
   DECLARE @OverlayNatResourceInfoCode int
   DECLARE @OverlayRLLargerInfoCode int
   DECLARE @OverlayRiverInfoCode int
   DECLARE @OverlayCentennialInfoCode int
   DECLARE @CodeInspectorInfoCode int
   DECLARE @LidarImperviousInfoField int
   DECLARE @LidarImperviousInfoCode int
   DECLARE @PesticideApplicationInfoField int
   DECLARE @PesticideApplicationInfoCode int
   DECLARE @DowntownPlanStudyAreaInfoCode int

   SELECT @LandUseCodeInfoCode  = 10
   SELECT @NoResUnitsInfoCode = 15
   SELECT @NoResRentalInfoCode = 20
   SELECT @YearBuiltInfoCode = 60
   SELECT @NoParkingSpacesInfoCode = 65
   SELECT @EasementsInfoCode = 70
   SELECT @HistoricInfoCode = 100
   SELECT @1990ZoningInfoCode = 130
   SELECT @AssessProAcctInfoCode  = 500

   SELECT @ExemptRentRegInfoCode = 22
   SELECT @ExemptUnitsInfoCode = 23
   SELECT @LastMHInspecInfoCode = 25
   SELECT @COCIssueDateInfoCode = 30
   SELECT @COCExpiryDateInfoCode = 35
   SELECT @COCYearsInfoCode = 40
   SELECT @OwnershipInfoCode = 50
   SELECT @2011EstFMV = 80
   SELECT @FloodplainInfoCode = 85
   SELECT @WetlandInfoCode = 90 
   SELECT @NaturalAreaInfoCode = 95 
   SELECT @OverlayDesignInfoCode = 121
   SELECT @OverlayICCInfoCode = 122
   SELECT @OverlayRHBonusInfoCode = 123
   SELECT @OverlayNatResourceInfoCode = 124
   SELECT @OverlayRLLargerInfoCode = 125
   SELECT @OverlayRiverInfoCode = 126
   SELECT @OverlayCentennialInfoCode = 127
   SELECT @CodeInspectorInfoCode = 600
   SELECT @LidarImperviousInfoCode = 610
   SELECT @PesticideApplicationInfoCode = 140
   SELECT @DowntownPlanStudyAreaInfoCode = 150

   /* Delete any null non-default PropertyInfo fields - works only if the field has never been 
       coded.  If it was coded and the value deleted, PropInfoValue has nothing in it, but 
       Query Analyzer shows the field as not null.  

   DELETE PropertyInfo FROM PropertyInfo 
   INNER JOIN ValidPropertyInfo ON ValidPropertyInfo.PropertyInfoCode = PropertyInfo.PropertyInfoCode 
   WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
        AND PropertyInfo.PropInfoValue is null
        AND ( ValidPropertyInfo.PropCode <> 100 OR ValidPropertyInfo.PropCode is null ) */

   /* Check default PropertyInfo fields - insert if missing or set display order if present */

   SELECT @LandUseCodeInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @LandUseCodeInfoCode

   SELECT @YearBuiltInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @YearBuiltInfoCode

   SELECT @NoResUnitsInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
      AND PropertyInfo.PropertyInfoCode = @NoResUnitsInfoCode

   SELECT @NoResRentalInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @NoResRentalInfoCode

   SELECT @NoParkingSpacesInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @NoParkingSpacesInfoCode

   SELECT @EasementsInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @EasementsInfoCode

   SELECT @HistoricInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @HistoricInfoCode

   SELECT @1990ZoningInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @1990ZoningInfoCode

   SELECT @AssessProAcctInfoField = count(*)
      FROM PropertyInfo
    WHERE PropertyInfo.PropertyRSN = @intPropertyRSN
         AND PropertyInfo.PropertyInfoCode = @AssessProAcctInfoCode

   IF @AssessProAcctInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @AssessProAcctInfoCode, 
                   dbo.udf_PropertyInfo_DisplayOrder (@AssessProAcctInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@AssessProAcctInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @AssessProAcctInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @LandUseCodeInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @LandUseCodeInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@LandUseCodeInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@LandUseCodeInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @LandUseCodeInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @YearBuiltInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
       VALUES ( @intPropertyRSN, @YearBuiltInfoCode, 
                       dbo.udf_PropertyInfo_DisplayOrder (@YearBuiltInfoCode), 
                       getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@YearBuiltInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @YearBuiltInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @NoResUnitsInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                       (PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @NoResUnitsInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@NoResUnitsInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@NoResUnitsInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @NoResUnitsInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @NoResRentalInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @NoResRentalInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@NoResRentalInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@NoResRentalInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @NoResRentalInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @NoParkingSpacesInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @NoParkingSpacesInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@NoParkingSpacesInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@NoParkingSpacesInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @NoParkingSpacesInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @EasementsInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @EasementsInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@EasementsInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@EasementsInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @EasementsInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @HistoricInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
      VALUES ( @intPropertyRSN, @HistoricInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@HistoricInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@HistoricInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @HistoricInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   IF @1990ZoningInfoField = 0
   BEGIN
      INSERT INTO PropertyInfo
                     ( PropertyRSN, PropertyInfoCode, DisplayOrder, StampDate, StampUser )
   VALUES ( @intPropertyRSN, @1990ZoningInfoCode, 
                      dbo.udf_PropertyInfo_DisplayOrder (@1990ZoningInfoCode), getdate(), @strUserID )
   END
   ELSE
   BEGIN
      UPDATE PropertyInfo
             SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@1990ZoningInfoCode)
       WHERE PropertyInfo.PropertyInfoCode = @1990ZoningInfoCode
             AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END

   /* Update non-default display orders */

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@ExemptRentRegInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @ExemptRentRegInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@ExemptUnitsInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @ExemptUnitsInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@LastMHInspecInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @LastMHInspecInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@COCIssueDateInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @COCIssueDateInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@COCExpiryDateInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @COCExpiryDateInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@COCYearsInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @COCYearsInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OwnershipInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OwnershipInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@FloodplainInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @FloodplainInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@2011EstFMV)
    WHERE PropertyInfo.PropertyInfoCode = @2011EstFMV
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@WetlandInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @WetlandInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@NaturalAreaInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @NaturalAreaInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayDesignInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayDesignInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayICCInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayICCInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayRHBonusInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayRHBonusInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayNatResourceInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayNatResourceInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayRLLargerInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayRLLargerInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayRiverInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayRiverInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@OverlayCentennialInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @OverlayCentennialInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@CodeInspectorInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @CodeInspectorInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@LidarImperviousInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @LidarImperviousInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@PesticideApplicationInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @PesticideApplicationInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN

   UPDATE PropertyInfo
          SET PropertyInfo.DisplayOrder = dbo.udf_PropertyInfo_DisplayOrder (@DowntownPlanStudyAreaInfoCode)
    WHERE PropertyInfo.PropertyInfoCode = @DowntownPlanStudyAreaInfoCode
          AND PropertyInfo.PropertyRSN = @intPropertyRSN
   END
END



GO
