USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultVehicle_Upd]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
--DROP PROCEDURE DefaultVehicle_Upd ;
--go
--Commented for VT for Sangeet

CREATE PROCEDURE [dbo].[DefaultVehicle_Upd] @argVehicleRSN NUMERIC, @DUserId VARCHAR
AS

BEGIN  
  
DELETE FROM VehicleInfo
WHERE VehicleRSN = @argVehicleRSN  
AND VehicleInfoValue is null  
AND VehicleInfoCode not in  
    ( SELECT VehicleInfoCode  
      FROM ValidVehicleInfo
      WHERE ValidVehicleInfo.VehicleInfoDefault = 'Y') ;  

INSERT INTO VehicleInfo (VehicleRSN, VehicleInfoCode )  
SELECT @argVehicleRSN, ValidVehicleInfo.VehicleInfoCode  
FROM ValidVehicleInfo
WHERE ValidVehicleInfo.VehicleInfoDefault = 'Y'
AND ValidVehicleInfo.VehicleInfoCode not in  
    ( SELECT VehicleInfo.VehicleInfoCode  
      FROM VehicleInfo  
      WHERE VehicleInfo.VehicleRSN = @argVehicleRSN ) ; 
END;


GO
