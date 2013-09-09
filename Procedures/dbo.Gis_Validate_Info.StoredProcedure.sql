USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Gis_Validate_Info]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure Gis_Validate_Info created for users to write custom code to validate info from GIS in Amandai */

CREATE PROCEDURE [dbo].[Gis_Validate_Info] @argFolderRSN INT, @argQueryRSN INT
as 

-- Amanda 44.27: Hongli July 10, 2009: Procedure Gis_Validate_Property created for users to write custom code to validate property from GIS in Amandai

begin	

        RAISERROR('CSDCWARNING:Procedure Gis_Validate_Info was called.', 16, -1)        

end


GO
