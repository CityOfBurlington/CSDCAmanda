USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ZGetDecisionBody]    Script Date: 9/9/2013 9:43:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[udf_ZGetDecisionBody](@intFolderRSN INT) 
RETURNS VARCHAR(30)
AS
BEGIN
   /* Used by Reasons for Denial Mailmerge document */
   DECLARE @intSubCode int
   DECLARE @intAppealtoDRB int
   DECLARE @intAppealtoVEC int
   DECLARE @intAppealtoVSC int
   DECLARE @varReviewBody varchar(30)

   SELECT @intSubCode = Folder.SubCode
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @intAppealtoDRB = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10002)
   SELECT @intAppealtoVEC = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10003)
   SELECT @intAppealtoVSC = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10029)

   IF @intSubCode = 10042 OR @intAppealtoDRB > 0
        SELECT @varReviewBody = 'Development Review Board'
   ELSE SELECT @varReviewBody = 'Zoning Administrator'

   RETURN ISNULL(@varReviewBody, 'x')
END



GO
