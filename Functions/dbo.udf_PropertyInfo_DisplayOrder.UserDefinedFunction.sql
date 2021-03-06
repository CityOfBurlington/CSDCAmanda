USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_PropertyInfo_DisplayOrder]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_PropertyInfo_DisplayOrder](@intPropertyInfoCode int)
RETURNS INT
AS
BEGIN

   /* Sets PropertyInfo DisplayOrders. As new PropertyInfo fields are 
      added, this must also be updated. 
      Function is called from PropertyInfo procedures for Insert, Update, 
      and Redefault button. */

   DECLARE @intDisplayOrder int

   SELECT @intDisplayOrder = 
     CASE @intPropertyInfoCode 
     WHEN 10 THEN 602     /* Land Use Code */
     WHEN 15 THEN 402     /* No of Res Units */
     WHEN 20 THEN 404     /* No of Res Rental Units */
     WHEN 22 THEN 406     /* Exmpt Rent Reg Fee */
     WHEN 23 THEN 407     /* No of Exempt Units */
     WHEN 25 THEN 408     /* Last MH Inspection */
     WHEN 30 THEN 410     /* COC Issue Date */
     WHEN 35 THEN 412     /* COC Expiration Date */
     WHEN 40 THEN 414     /* COC Years */
     WHEN 50 THEN 604     /* Ownership */
     WHEN 55 THEN 605     /* Institutional Use */
     WHEN 60 THEN 606     /* Year Built */
     WHEN 65 THEN 810     /* Parking Spaces (Number) */
     WHEN 70 THEN 608     /* Easements */
     WHEN 80 THEN 302     /* 2011 Structure FMV in Lake SFHA */
     WHEN 85 THEN 844     /* NRP: Special Flood Hazard Area */
     WHEN 87 THEN 304     /* Land <= 104 Ft Lake Elevation */
     WHEN 88 THEN 306     /* Number of Structures in Lake SFHA */
     WHEN 89 THEN 308     /* Number of Structures <= 104 Ft Lake Elevation */
     WHEN 90 THEN 840     /* NRP: Wetland */
     WHEN 95 THEN 848     /* NRP: Natural Area */
     WHEN 100 THEN 820     /* Historic Structure */
     WHEN 121 THEN 830     /* Design Review by Geography */
     WHEN 122 THEN 834     /* Institutional Core Campus */
     WHEN 123 THEN 836     /* RH Density Bonus */
     WHEN 124 THEN 846     /* NRP: Riparian and Littoral Zone */
     WHEN 125 THEN 838     /* RL Larger Lot */
     WHEN 126 THEN 850     /* Mouth of River */
     WHEN 127 THEN 852     /* Centennial Woods */
     WHEN 128 THEN 832     /* Parking District */
     WHEN 129 THEN 842     /* NRP: Vernal Pool */
     WHEN 130 THEN 860     /* 1990 Zoning District */
     WHEN 140 THEN 102     /* Pesticide Application Permit */
     WHEN 150 THEN 202     /* Downtown Plan Study Area */
     WHEN 200 THEN 702     /* Vacant Building On Site? */
     WHEN 500 THEN 610     /* Assess Pro AcctNo */
     WHEN 600 THEN 416     /* Code Inspector Assigned */
     WHEN 610 THEN 502     /* Lidar Impervious Surface */
     ELSE 0
     END

   RETURN @intDisplayOrder

END
GO
