USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningPermitPickedUp]    Script Date: 9/9/2013 9:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningPermitPickedUp](@intFolderRSN INT)
RETURNS VARCHAR(10)
AS
BEGIN 
   /* Returns the appropriate FolderInfo (10023) Permit Picked Up value 
      when a decision is entered. Denials are mailed. Approvals must 
      be picked up in person. */

   DECLARE @varFolderType varchar(4)
   DECLARE @intWorkCode int
   DECLARE @varPermitPickedUp varchar(10)
   DECLARE @intDecisionAttemptCode int
   DECLARE @intAppealtoDRB int
   DECLARE @varDecisionText varchar(60) 
   DECLARE @varLogText varchar(400)

   SET @varPermitPickedUp = 'No'

   SELECT @varFolderType = Folder.FolderType,
          @intWorkCode = Folder.WorkCode 
     FROM Folder
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @intDecisionAttemptCode = dbo.udf_GetZoningDecisionAttemptCode(@intFolderRSN) 

   /* Misc Appeals - Updates are done here because staff mails Findings upon decision to 
      allow maximum time to appeal. Write log to FolderConditions. */
   
   IF @varFolderType = 'ZL' 
   BEGIN 
		SELECT @varPermitPickedUp = 'Mailed ('
		SELECT @varDecisionText = dbo.udf_GetZoningPermitPickedUpText(@intFolderRSN, @intDecisionAttemptCode)
		SELECT @varLogText = @varDecisionText + @varPermitPickedUp + CONVERT(CHAR(11), getdate()) + ')'

		EXECUTE dbo.usp_Zoning_Update_FolderCondition_Log @intFolderRSN, @varLogText
   END
   
   /* Nonapplicabilities */

   IF @varFolderType = 'ZN' 
   BEGIN
      SELECT @intAppealtoDRB = dbo.udf_CountProcessAttemptResults(@intFolderRSN, 10002)
      IF @intAppealtoDRB > 0 SELECT @varPermitPickedUp = 'No'
      ELSE SELECT @varPermitPickedUp = 'Yes' 
   END 
   
   /* For everything else, permit must be signed and picked up, or mailed. */

   RETURN @varPermitPickedUp 
END
GO
