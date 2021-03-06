USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetCBCBoardPeopleRSNFromSubCode]    Script Date: 9/9/2013 9:43:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetCBCBoardPeopleRSNFromSubCode](@intSubCode int)
RETURNS INT
AS 
BEGIN
	/* For the CBC FolderType, returns the PeopleRSN for a commission/board based upon Folder.SubCode. 
	   This function must be updated when new commission, board, or committee People records are added. JA 7/2013 */
	   
	/* Jay does not think this is needed - can cover thorugh where clauses   JA 8/2013 */
	
	DECLARE @intBoardPeopleRSN int
	
	SELECT @intBoardPeopleRSN = 
	CASE @intSubCode				
		WHEN 40000 THEN 184519			/* Advisory Committee on Accessibility */
		WHEN 40001 THEN 184520			/* Airport Commission */
		WHEN 40002 THEN	184521			/* Board of Assessors */
		WHEN 40003 THEN	184522			/* BHA Board */
		WHEN 40004 THEN	184523			/* Cemetery Commission */
		WHEN 40005 THEN	184524			/* Chittenden County Regional Planning Commission */
		WHEN 40006 THEN	184525			/* Chittenden Transportation Authority */
		WHEN 40007 THEN	184526			/* Chittenden Solid Waste District Board of Commissioners */
		WHEN 40008 THEN 184527			/* City Council */
		WHEN 40009 THEN 184528			/* Church Street Marketplace District Commission */
		WHEN 40010 THEN 184529			/* Conservation Board */
		WHEN 40011 THEN 184530			/* Design Advisory Board */
		WHEN 40012 THEN 184512			/* Development Review Board */
		WHEN 40013 THEN 184531			/* Electric Light Commission */
		WHEN 40014 THEN 184532			/* Fence Viewers */
		WHEN 40015 THEN 184533			/* Fire Commission */
		WHEN 40016 THEN 184534			/* Fire Wardens */
		WHEN 40017 THEN 184535			/* Board of Health */
		WHEN 40018 THEN 184536			/* Housing Board of Review */
		WHEN 40019 THEN 184537			/* Library Board of Commissioners */
		WHEN 40020 THEN 184538			/* Board of Medical Examiners */
		WHEN 40021 THEN 184539			/* Parks and Recreation Commission */
		WHEN 40022 THEN 184540			/* Planning Commission */
		WHEN 40023 THEN 184541			/* Police Commission */
		WHEN 40024 THEN 184542			/* Public Works Commission */
		WHEN 40025 THEN 184543			/* Retirement Board */
		WHEN 40026 THEN 184544			/* Board of Tax Appeals */
		WHEN 40027 THEN 184545			/* Board for Registration of Voters */
		WHEN 40028 THEN 184546			/* Winooski Valley Park District */
		ELSE 0
	END
	
	RETURN @intBoardPeopleRSN
END
GO
