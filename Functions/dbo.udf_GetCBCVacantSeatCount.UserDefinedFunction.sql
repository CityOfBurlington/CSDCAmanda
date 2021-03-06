USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCBCVacantSeatCount]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetCBCVacantSeatCount](@intSubCode INT)
RETURNS INT
AS 
BEGIN
	/* For the CBC FolderType, counts number of vacant seats. This simple function is used to insure that 
	   the definition of a vacant seat is consistent, i.e. PeopleBoardSeat.PeopleRSN = 0.   JA 8/2013 */
	
	DECLARE @intBoardSeatVacantCount int

	SET @intBoardSeatVacantCount = 0	/* no vacant seats */

	SELECT @intBoardSeatVacantCount = COUNT(*)
	FROM PeopleBoardSeat 
	WHERE PeopleBoardSeat.SubCode = @intSubCode 
	AND PeopleBoardSeat.PeopleRSN = 0 

	RETURN @intBoardSeatVacantCount
END
GO
