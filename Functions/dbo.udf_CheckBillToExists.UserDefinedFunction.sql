USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_CheckBillToExists]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[udf_CheckBillToExists] (@FolderRSN INT)  
RETURNS INT
AS
BEGIN

DECLARE @FolderType VARCHAR(4)
DECLARE @PrimaryPeople INT
DECLARE @RetVal INT

--SET @FolderRSN = 194767

SELECT @FolderType = FolderType FROM Folder WHERE FolderRSN = @FolderRSN

SELECT @PrimaryPeople = PeopleCode FROM ValidFolder WHERE FolderType = @FolderType

SET @RetVal = 0
IF EXISTS
	(SELECT FolderRSN FROM FolderPeople WHERE FolderRSN = @FolderRSN AND PeopleCode = @PrimaryPeople)
	BEGIN
		SET @RetVal = 1
	END

RETURN @RetVal

END

GO
