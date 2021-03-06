USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDRBReviewTypeOrder]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_GetZoningDRBReviewTypeOrder](@intFolderRSN INT)
RETURNS VARCHAR(60)
AS
BEGIN
   DECLARE @varReviewTypeOrder varchar(1)
   DECLARE @varReviewType varchar(60)

   SELECT @varReviewType = dbo.udf_GetZoningDRBReviewType(@intFolderRSN)

   SELECT @varReviewTypeOrder = 
   CASE @varReviewType
      WHEN 'Site Plan COA' THEN 'A'
      WHEN 'Site Plan Basic' THEN 'B'
      WHEN 'Site Plan COA and Conditional Use' THEN 'C'
      WHEN 'Site Plan COA and Home Occupation' THEN 'D' 
      WHEN 'Site Plan COA and Major Impact Review' THEN 'E'
      WHEN 'Site Plan COA and Variance' THEN  'F'
      WHEN 'Conditional Use' THEN 'G'
      WHEN 'Major Impact Review with Site Plan' THEN 'H'
      WHEN 'Home Occupation' THEN 'I'
      WHEN 'Variance' THEN 'J'
      WHEN 'Preliminary Plat' THEN 'K'  
      WHEN 'Preliminary and Final Plat' THEN 'L' 
      WHEN 'Final Plat' THEN 'M'
      WHEN 'Sketch Plan' THEN 'N'
      WHEN 'Signs and Awnings' THEN 'O'
      WHEN 'Fence' THEN 'P'
      WHEN 'Determination' THEN 'Q'
      WHEN 'Master Plan' THEN 'R'
      WHEN 'Appeal of Zoning Permit Administrative Decision' THEN 'S'
      WHEN 'Appeal of Code Enforcement Decision' THEN 'T'
      WHEN 'Appeal of Misc Zoning Decision' THEN 'U'
      WHEN 'Not Reviewed by DRB' THEN 'V' 
      ELSE 'Z'
   END

   RETURN @varReviewTypeOrder
END

GO
