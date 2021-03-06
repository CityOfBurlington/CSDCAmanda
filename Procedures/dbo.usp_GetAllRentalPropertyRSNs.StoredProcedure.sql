USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAllRentalPropertyRSNs]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetAllRentalPropertyRSNs]
AS
SELECT DISTINCT Property.PropertyRSN
FROM Property 
WHERE dbo.f_info_numeric_property(Property.PropertyRSN, 20) > 0 /*No of Res Rental Units*/
AND (dbo.f_info_alpha_property(Property.PropertyRSN, 22) <> 'Yes' /*Not Exempt From Rental Reg Fee*/ OR dbo.f_info_alpha_property(Property.PropertyRSN, 22) IS NULL /*Exemption Not Stated*/)





GO
