USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_AssessPro_LUC_Changes_Updates]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_AssessPro_LUC_Changes_Updates] 
AS
BEGIN

	DECLARE @strSQL NVARCHAR(2000)
	DECLARE @LUC VARCHAR(5)
	DECLARE @PropertyRSN INT

	DECLARE curAP CURSOR FOR
		SELECT DISTINCT P.PropertyRSN, DL.LUC 
		FROM dbo.Property AS P INNER JOIN
		dbo.PropertyInfo AS PrI ON P.PropertyRSN = PrI.PropertyRSN INNER JOIN
		AssessPro.dbo.DataProperty AS DP ON P.PropertyRoll = DP.ParcelID INNER JOIN
		assesspro.dbo.DataLand AS DL ON DL.AccountNumber = DP.AccountNumber AND PrI.PropInfoValue <> DL.LUC INNER JOIN
		assesspro.dbo.TableLandUse AS TLU ON DL.LUC = TLU.Code LEFT OUTER JOIN
		dbo.Folder AS F ON P.PropertyRSN = F.PropertyRSN --AND F.FolderType = 'RB'
		WHERE(PrI.PropertyInfoCode = 10) AND (P.StatusCode = 1) AND (DP.CardNumber = 1) 
		AND (DL.CardNumber = 1) AND (DL.SeqNumber = 1) AND (ISNULL(DP.Closed, 0) <> 1)


	/* Create a cursor to process selected properties */
	OPEN curAP
	FETCH NEXT FROM curAP INTO @PropertyRSN, @LUC
	WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE PropertyInfo
			SET PropertyInfo.PropInfoValue = @LUC
			WHERE PropertyInfo.PropertyRSN = @PropertyRSN AND PropertyInfo.PropertyInfoCode = 10
		FETCH NEXT FROM curAP INTO @PropertyRSN, @LUC
	END

	CLOSE curAP
	DEALLOCATE curAP

END
GO
