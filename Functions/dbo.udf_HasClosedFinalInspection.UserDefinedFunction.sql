USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_HasClosedFinalInspection]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_HasClosedFinalInspection](@FolderType VARCHAR(6), @ProcessCode INT, @FolderRSN INT) RETURNS BIT
AS
BEGIN
	DECLARE @RetVal BIT

	IF EXISTS(SELECT F.FolderRSN 
		FROM Folder F 
		INNER JOIN FolderProcess FP ON F.FolderRSN=FP.FolderRSN 
		WHERE F.FolderType=@FolderType
		AND FP.ProcessCode=@ProcessCode
		AND FP.FolderRSN=@FolderRSN)

		BEGIN

			IF EXISTS(SELECT F.FolderRSN 
				FROM Folder F 
				INNER JOIN FolderProcess FP ON F.FolderRSN=FP.FolderRSN 
				WHERE F.FolderType=@FolderType
				AND FP.ProcessCode=@ProcessCode /*Final Inspection*/ 
				AND FP.StatusCode=2 /*Closed*/ 
				AND FP.FolderRSN=@FolderRSN)
				BEGIN 
					SET @RetVal=1
				END
			ELSE
				BEGIN
					SET @RetVal=0
				END

		END

	ELSE
		
		/*NO FINAL INSPECTION PROCESS AT ALL*/
		SET @RetVal = NULL
	

	RETURN @RetVal
END


GO
