USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProjectNumberYearSequence]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProjectNumberYearSequence](@intFolderRSN int) 
RETURNS varchar(15)
AS
BEGIN
   /* Extracts the year and sequence number portion of the Project Number, 
      Folder.ReferenceFile. */

   DECLARE @varPermitNumber varchar(15)
   DECLARE @intLength int
   DECLARE @intPositionCounter int
   DECLARE @varCharacter varchar(1)
   DECLARE @varLetterAbbrevFlag varchar(2)
   DECLARE @intLetterAbbrevStart int
   DECLARE @varProjectNumber varchar(15)

   SELECT @varPermitNumber = Folder.ReferenceFile
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN 

   SELECT @intLength = LEN(@varPermitNumber)
   SELECT @intPositionCounter = 1
   SELECT @varLetterAbbrevFlag = 'N'

   WHILE @intPositionCounter < ( @intLength + 1 )
   BEGIN
      SELECT @varCharacter = SUBSTRING(@varPermitNumber, @intPositionCounter, 1)

      IF ( @varCharacter NOT IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-') AND @varLetterAbbrevFlag = 'N' ) 
      BEGIN
         SELECT @varLetterAbbrevFlag = 'Y' 
         SELECT @intLetterAbbrevStart = @intPositionCounter 
      END
      
      SELECT @intPositionCounter = @intPositionCounter  + 1 
   END

   IF @varLetterAbbrevFlag = 'N' SELECT @varProjectNumber = @varPermitNumber 
   ELSE
      SELECT @varProjectNumber = ISNULL(SUBSTRING(@varPermitNumber, 1, ( @intLetterAbbrevStart - 1 )), '?') 

   RETURN @varProjectNumber 
END
GO
