USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_Code_Rental_Units]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Code_Rental_Units]
AS
BEGIN

SELECT SUM(dbo.f_info_numeric_property(Property.PropertyRSN, 20)) AS TotalResRentalUnits
FROM Property
WHERE ISNULL(dbo.f_info_numeric_property(Property.PropertyRSN, 20), 0) > 0

END


GO
