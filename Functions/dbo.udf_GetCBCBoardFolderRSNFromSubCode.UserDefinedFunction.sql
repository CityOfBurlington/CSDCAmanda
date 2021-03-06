USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCBCBoardFolderRSNFromSubCode]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetCBCBoardFolderRSNFromSubCode](@intSubCode int)
RETURNS INT
AS 
BEGIN
	/* For the CBC FolderType, returns the FolderRSN for a commission/board based upon Folder.SubCode. 
	   This function must be updated when new commission, board, or committee Folder records are added. JA 8/2013 */
	
	DECLARE @intBoardFolderRSN int
	
	SELECT @intBoardFolderRSN = 
	CASE @intSubCode				
		WHEN 40000 THEN 0			/* Advisory Committee on Accessibility */
		WHEN 40001 THEN 253662		/* Airport Commission */
		WHEN 40002 THEN	253684		/* Board of Assessors */
		WHEN 40003 THEN	0			/* BHA Board */
		WHEN 40004 THEN	0			/* Cemetery Commission */
		WHEN 40005 THEN	0			/* Chittenden County Regional Planning Commission */
		WHEN 40006 THEN	0			/* Chittenden Transportation Authority */
		WHEN 40007 THEN	0			/* Chittenden Solid Waste District Board of Commissioners */
		WHEN 40008 THEN 0			/* City Council */
		WHEN 40009 THEN 0			/* Church Street Marketplace District Commission */
		WHEN 40010 THEN 0			/* Conservation Board */
		WHEN 40011 THEN 0			/* Design Advisory Board */
		WHEN 40012 THEN 252532		/* Development Review Board */
		WHEN 40013 THEN 0			/* Electric Light Commission */
		WHEN 40014 THEN 0			/* Fence Viewers */
		WHEN 40015 THEN 0			/* Fire Commission */
		WHEN 40016 THEN 0			/* Fire Wardens */
		WHEN 40017 THEN 0			/* Board of Health */
		WHEN 40018 THEN 0			/* Housing Board of Review */
		WHEN 40019 THEN 0			/* Library Board of Commissioners */
		WHEN 40020 THEN 0			/* Board of Medical Examiners */
		WHEN 40021 THEN 0			/* Parks and Recreation Commission */
		WHEN 40022 THEN 0			/* Planning Commission */
		WHEN 40023 THEN 0			/* Police Commission */
		WHEN 40024 THEN 0			/* Public Works Commission */
		WHEN 40025 THEN 0			/* Retirement Board */
		WHEN 40026 THEN 0			/* Board of Tax Appeals */
		WHEN 40027 THEN 0			/* Board for Registration of Voters */
		WHEN 40028 THEN 0			/* Winooski Valley Park District */
		ELSE 0
	END
	
	RETURN @intBoardFolderRSN
END

GO
