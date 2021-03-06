USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetPropertyRelatedView]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure GetPropertyRelatedView modified to add alias name in the label for property related view */

CREATE PROCEDURE [dbo].[GetPropertyRelatedView] @PropertyRSN INT, @UserId VARCHAR(128)         
AS         
DECLARE @v_startRSN INT         
 DECLARE @v_currentRSN INT         
 DECLARE @v_lvl INT         
 DECLARE @noDataFound CHAR(1)         
    DECLARE @v_ExistRSN INT         
BEGIN         
  /*         
  Name of Person: ESS         
  Date : March 28 2006         
  Version: 4.4.6         
         
  Procedure GetPropertyRelatedView is used in AMANDAi to get Related view structure for a specific PropertyRSN         
     ESS Modified Nov 05 2008:Related view node click fixing in MS Sql Server DataBase.          
  ESS Modified 2008.11.05 - Server hang problem during deleting a child folder in Related view         
  ESS Modified 2008.12.05 - Used F_RelatedView_Label_Property function         
  5.4.4.31: ESS Modified 2011.03.08 - Issue id :21255 (Alias name added for F_RelatedView_Label_Property)         
  */         
          
  CREATE TABLE #temp_Property         
   (         
   ParentPropertyRSN       INT           ,         
   PropertyRSN             INT           ,         
   PATH                    VARCHAR(2000) ,         
   ROWNDX                  INT           ,         
   PropHouseNumeric        INT           ,         
   PropHouse               VARCHAR(20 )  ,         
   PropStreetPrefix        VARCHAR(2)    ,         
   PropStreet              VARCHAR(40)   ,         
   PropStreetType          VARCHAR(10)   ,         
   PropStreetDirection     CHAR(2)       ,         
   PropUnitType            CHAR(6)       ,         
   PropUnit                VARCHAR(6)    ,         
   PropCity                VARCHAR(40)   ,         
   PropProvince            CHAR(2)       ,         
   PropPostal              VARCHAR(12)   ,         
   PropCode                INT           ,         
   PropertyName            VARCHAR(64)   ,         
   StatusCode              INT     ,         
   FamilyRSN    INT         
   )         
         
  SET @v_currentRSN = @PropertyRSN;         
  SET @noDataFound = 'N'         
  WHILE (@v_currentRSN IS NOT NULL)         
  BEGIN         
  SET @v_startRSN = @v_currentRSN         
  SELECT @v_currentRSN = CASE ParentPropertyRSN         
     WHEN PropertyRSN THEN         
      NULL         
     WHEN @PropertyRSN THEN         
      NULL         
     ELSE         
      ParentPropertyRSN         
     END         
  FROM Property WHERE PropertyRSN = @v_currentRSN         
  if @@rowcount = 0         
    begin         
     if @v_currentRSN = @PropertyRSN         
      begin         
       set @noDataFound = 'Y'         
      end         
     else         
      begin         
       SET @v_startRSN = @v_ExistRSN         
      end         
     set @v_currentRSN = null         
                         
    end         
   else         
    begin         
     SET @v_ExistRSN = @v_startRSN         
    end         
         
         
  END         
          
  if @noDataFound = 'N'         
   begin         
    SET @v_lvl = 1         
    INSERT INTO #temp_Property         
    SELECT ParentPropertyRSN,PropertyRSN,PropertyRSN,@v_lvl,PropHouseNumeric,PropHouse,PropStreetPrefix,PropStreet,PropStreetType,         
           PropStreetDirection,PropUnitType,PropUnit,PropCity, PropProvince, PropPostal, PropCode, PropertyName,StatusCode,         
      FamilyRSN         
    FROM Property WHERE PropertyRSN = @v_startRSN         
               
    EXEC PopulatePropertyChildren @v_startRSN,@v_lvl OUT         
   end         
         
  SELECT Path,PropHouseNumeric,PropHouse,PropStreetPrefix,PropStreet,PropStreetType,         
         PropStreetDirection,PropUnitType,PropUnit,PropCity, PropProvince, PropPostal, PropertyRSN,         
         PropCode, StatusDesc,PropertyName,FamilyRSN, dbo.F_RelatedView_Label_Property(PropertyRSN) LabelProperty         
  FROM #temp_Property Property         
  LEFT OUTER JOIN ValidPropertyStatus         
  ON ValidPropertyStatus.StatusCode = Property.StatusCode         
  ORDER BY PropHouse,ROWNDX     
END      

GO
