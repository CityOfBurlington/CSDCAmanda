USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProjectNumberNext]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetProjectNumberNext](@intFolderRSN int, @dtCurrentDate datetime) 
RETURNS varchar(20)
AS
BEGIN
   /* Returns the next Project Number for initializing zoning folders. 
      Assumes Project Number format of xx-yyyyzzzzz where: 
            xx is the fiscal year as a 2-digit integer
          yyyy is the sequence number with leading zeros
         zzzzz is a 2-5 letter character string */

   DECLARE @intCurrentDateYear int
   DECLARE @intCurrentDateMonth int
   DECLARE @intYrDiff int
   DECLARE @intCenturyDiff int
   DECLARE @intFiscalYearCurrent int
   DECLARE @intMaxSequenceNumber int
   DECLARE @intNextSequenceNumber int
   DECLARE @varNextSequenceNumber varchar(4)
   DECLARE @varFolderType varchar(4)
   DECLARE @intWorkCode int
   DECLARE @varZ3ProjectType varchar(50)
   DECLARE @varPermitTypeAbbrev varchar(10)
   DECLARE @varProjectNumber varchar(20)

   SELECT @intCurrentDateYear  = ISNULL(DATEPART(yy, @dtCurrentDate), 0), 
          @intCurrentDateMonth = ISNULL(DATEPART(mm, @dtCurrentDate), 0)

   IF @intCurrentDateMonth > 6 SELECT @intYrDiff = 1
   ELSE SELECT @intYrDiff = 0

   IF @intcurrentDateYear < 2000 SELECT @intCenturyDiff = 1900
   ELSE SELECT @intCenturyDiff = 2000

   SELECT @intFiscalYearCurrent = ((@intCurrentDateYear - @intCenturyDiff) + @intYrDiff)

   SELECT @intMaxSequenceNumber = ISNULL(MAX(CAST(SUBSTRING(Folder.ReferenceFile, 4, 4) AS INT)), 0)
     FROM Folder
    WHERE CAST(SUBSTRING(Folder.ReferenceFile, 1, 2) AS INT) = @intFiscalYearCurrent 
      AND Folder.FolderType LIKE 'Z%' 
      AND SUBSTRING(Folder.ReferenceFile, 3, 1) = '-' 

   SELECT @intNextSequenceNumber = @intMaxSequenceNumber + 1 

   IF @intNextSequenceNumber < 10 
      SELECT @varNextSequenceNumber = '000' + CAST(@intNextSequenceNumber as VARCHAR)

   IF @intNextSequenceNumber > 9 AND @intNextSequenceNumber < 100 
      SELECT @varNextSequenceNumber = '00' + CAST(@intNextSequenceNumber as VARCHAR)

   IF @intNextSequenceNumber > 99 AND @intNextSequenceNumber < 1000 
      SELECT @varNextSequenceNumber = '0' + CAST(@intNextSequenceNumber as VARCHAR)

   IF @intNextSequenceNumber > 999 
      SELECT @varNextSequenceNumber = CAST(@intNextSequenceNumber as VARCHAR)

   SELECT @varFolderType = Folder.FolderType, 
          @intWorkCode = Folder.WorkCode
     FROM Folder 
    WHERE Folder.FolderRSN = @intFolderRSN

   SELECT @varPermitTypeAbbrev = 
   CASE @varFolderType 
      WHEN 'BP' THEN 'BP' 
      WHEN 'Z1' THEN 'CA'
      WHEN 'Z2' THEN 'CA'
      WHEN 'ZB' THEN 'BA'
      WHEN 'ZD' THEN 'DT'
      WHEN 'ZF' THEN 'FC'
      WHEN 'ZL' THEN 'AP'
      WHEN 'ZN' THEN 'NA'
      WHEN 'ZP' THEN 'MP' 
      WHEN 'ZS' THEN 'SP'
   END

   IF @varFolderType IN ('ZA', 'ZH') 
   BEGIN
      SELECT @varPermitTypeAbbrev = 
      CASE @intWorkCode 
         WHEN 10000 THEN 'CU'
         WHEN 10001 THEN 'HO'
         WHEN 10002 THEN 'MA'
         WHEN 10003 THEN 'VR'
         WHEN 10035 THEN 'SN'
         WHEN 10036 THEN 'AW'
         WHEN 10037 THEN 'AW'
      END
   END

   IF @varFolderType = 'ZC' 
   BEGIN
      SELECT @varPermitTypeAbbrev = 
      CASE @intWorkCode 
         WHEN 10000 THEN 'CA/CU'
         WHEN 10001 THEN 'CA/HO'
         WHEN 10002 THEN 'CA/MA'
         WHEN 10003 THEN 'CA/VR'
      END
   END

   /* The permit type abbreviation is completed by InfoValidation 
      for FolderInfo.InfoCode = 10015 

   IF @varFolderType = 'Z3' SELECT @varPermitTypeAbbrev = NULL 
   SELECT @varProjectNumber = CAST(@intFiscalYearCurrent AS VARCHAR) + '-' + @varNextSequenceNumber + @varPermitTypeAbbrev 
*/

   /* The code above was not working for Z3 folders (at least not in AMANDA5) because adding a NULL value to a good value
      always produced a NULL result. Thus the @varProjectNumber variable was being passed back as NUll. */
   IF @varFolderType = 'Z3' 
      SELECT @varProjectNumber = CAST(@intFiscalYearCurrent AS VARCHAR) + '-' + @varNextSequenceNumber
   ELSE
      SELECT @varProjectNumber = CAST(@intFiscalYearCurrent AS VARCHAR) + '-' + @varNextSequenceNumber + @varPermitTypeAbbrev 


   RETURN @varProjectNumber 

END
GO
