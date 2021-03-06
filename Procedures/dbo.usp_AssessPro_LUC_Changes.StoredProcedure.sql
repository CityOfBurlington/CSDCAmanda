USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AssessPro_LUC_Changes]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_AssessPro_LUC_Changes] 
AS
BEGIN
SELECT DISTINCT P.PropertyRSN, DP.ParcelID, P.PropStreet AS StreetName, P.PropHouse AS StreetNo, P.PropStreetType AS StreetType, PrI.PropInfoValue AS AmandaLUC, 
DL.LUC AS AssessorLUC, TLU.Description AS AssessorLUCDescription, CASE WHEN F.FolderType = 'RB' THEN 'Y' ELSE 'N' END AS HasRBFolder
FROM dbo.Property AS P INNER JOIN
dbo.PropertyInfo AS PrI ON P.PropertyRSN = PrI.PropertyRSN INNER JOIN
COBDB.AssessPro.dbo.DataProperty AS DP ON P.PropertyRoll = DP.ParcelID INNER JOIN
COBDB.assesspro.dbo.DataLand AS DL ON DL.AccountNumber = DP.AccountNumber AND PrI.PropInfoValue <> DL.LUC INNER JOIN
COBDB.assesspro.dbo.TableLandUse AS TLU ON DL.LUC = TLU.Code LEFT OUTER JOIN
dbo.Folder AS F ON P.PropertyRSN = F.PropertyRSN --AND F.FolderType = 'RB'
WHERE(PrI.PropertyInfoCode = 10) AND (P.StatusCode = 1) AND (DP.CardNumber = 1) 
AND (DL.CardNumber = 1) AND (DL.SeqNumber = 1) AND (ISNULL(DP.Closed, 0) <> 1)
END


GO
