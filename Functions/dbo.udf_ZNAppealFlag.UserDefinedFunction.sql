USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZNAppealFlag]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_ZNAppealFlag](@intFolderRSN INT) 
        RETURNS VARCHAR(30) 
AS
BEGIN
	DECLARE @intRetVal VARCHAR(30)
        DECLARE @DRBAppeal INT
        DECLARE @VECAppeal INT

        SELECT @DRBAppeal = COUNT(*)
          FROM Folder, FolderProcess
         WHERE FolderProcess.FolderRSN = @intFolderRSN
           AND FolderProcess.ProcessCode = 10002
       
        SELECT @VECAppeal = COUNT(*)
          FROM Folder, FolderProcess
         WHERE FolderProcess.FolderRSN = @intFolderRSN
           AND FolderProcess.ProcessCode = 10003

        SELECT @intRetVal = 'Error'

        IF ( @DRBAppeal = 0 AND @VECAppeal = 0 )
           SELECT @intRetVal = 'Not_Appealed'
        ELSE 
        BEGIN
           IF @DRBAppeal > 0 AND @VECAppeal = 0 
              SELECT @intRetVal = 'Administrative_Decision'
           ELSE 
              SELECT @intRetVal = 'DRB_Decision'
        END

	RETURN @intRetVal
END



GO
