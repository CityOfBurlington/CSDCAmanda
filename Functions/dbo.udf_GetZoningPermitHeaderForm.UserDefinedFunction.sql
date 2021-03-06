USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitHeaderForm]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitHeaderForm](@intFolderRSN int) RETURNS varchar(50)
AS
BEGIN
   /* Used by Infomaker zoning_all_permits form */
   DECLARE @strFolderPermitHeader varchar(50)
   DECLARE @intAttemptResCode INT

   SET @strFolderPermitHeader = 'x'
   SET @intAttemptResCode = 0

   SELECT @intAttemptResCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN)

   SELECT @strFolderPermitHeader =
   CASE @intAttemptResCode 
      WHEN 10002 THEN 'ZONING REQUEST DENIAL' 
      WHEN 10003 THEN 'ZONING PERMIT'
      WHEN 10011 THEN 'ZONING PERMIT'
      WHEN 10020 THEN 'ZONING REQUEST DENIAL' 
      ELSE 'UNOFFICIAL DOCUMENT' 
   END

RETURN @strFolderPermitHeader
END

GO
