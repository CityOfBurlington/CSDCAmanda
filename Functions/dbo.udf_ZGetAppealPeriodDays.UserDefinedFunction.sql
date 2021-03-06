USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZGetAppealPeriodDays]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_ZGetAppealPeriodDays](@intFolderRSN INT) 
RETURNS INT
AS
BEGIN
   /* Used by Permit Conditions Mailmerge document */
   DECLARE @intSubCode int
   DECLARE @intAppealtoDRB int
   DECLARE @intAppealtoVEC int
   DECLARE @intAppealtoVSC int
   DECLARE @intAppealPeriodDays int

   SELECT @intSubCode = Folder.SubCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @intAppealtoDRB = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10002)
   SELECT @intAppealtoVEC = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10003)
   SELECT @intAppealtoVSC = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10029)

   IF @intSubCode = 10041 AND @intAppealtoDRB = 0 AND @intAppealtoVEC = 0 AND @intAppealtoVSC = 0
      SELECT @intAppealPeriodDays = 15
   ELSE SELECT @intAppealPeriodDays = 30

   RETURN ISNULL(@intAppealPeriodDays, 0)
END

GO
