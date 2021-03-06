USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetProcessCheckListPassed]    Script Date: 9/9/2013 9:43:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_GetProcessCheckListPassed](@intFolderRSN INT, @intProcessCode INT)
RETURNS VARCHAR(50)
AS
BEGIN
   DECLARE @CheckListDesc varchar(50)

   SELECT @CheckListDesc = ValidCheckList.CheckListDesc
     FROM FolderProcessCheckList, FolderProcess, ValidCheckList
    WHERE FolderProcessCheckList.Passed = 'Y'
      AND FolderProcessCheckList.FolderRSN = @intFolderRSN
      AND FolderProcessCheckList.ProcessRSN = FolderProcess.ProcessRSN
      AND FolderProcess.ProcessCode = @intProcessCode
      AND FolderProcessCheckList.CheckListCode = ValidCheckList.CheckListCode

   RETURN ISNULL(@CheckListDesc, 'Not Assigned')
END


GO
