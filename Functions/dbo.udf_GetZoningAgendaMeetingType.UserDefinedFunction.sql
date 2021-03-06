USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningAgendaMeetingType]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningAgendaMeetingType](@intFolderRSN INT)
RETURNS VARCHAR(30)
AS
BEGIN
   DECLARE @varChecklistDesc varchar(30)

   SELECT @varChecklistDesc = ISNULL(ValidChecklist.ChecklistDesc, 'TBD')
     FROM FolderProcessChecklist, FolderProcess, ValidChecklist
    WHERE FolderProcessChecklist.Passed = 'Y'
      AND FolderProcessChecklist.FolderRSN = @intFolderRSN
      AND FolderProcessChecklist.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.ProcessCode = 10031
      AND FolderProcessChecklist.ChecklistCode = ValidChecklist.ChecklistCode

   RETURN @varChecklistDesc 
END
GO
