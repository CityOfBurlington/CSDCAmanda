USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[ControlError_Warning]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* For better performance, data type of @ArgDisplayOrder, @ArgTableRSN changed to int from numeric */ 

CREATE Procedure [dbo].[ControlError_Warning] @ArgErrorText Varchar(2000),
      @ArgErrorWindow Varchar(64),
      @ArgDisplayOrder INT,
      @ArgProcedureName Varchar(64),
      @ArgWindowName Varchar(64),
      @ArgTableName Varchar(64),
      @ArgTableRSN INT
as
/* Version 4.4.26a: YUMING August 21, 2009: Changed data type to Integer from Numeric for @ArgDisplayOrder,@ArgTableRSN */ 
      INSERT INTO ControlError (ErrorRSN, ErrorSessionID,
             ErrorWindow, ErrorText, DisplayOrder,
        WarningFlag, AutoDeleteFlag,
             ProcedureName, WindowName,
        TableName, TableRSN,
        StampUser, StampDate)
      SELECT (Select Max(ErrorRSN)+ 1 From ControlError), USER_ID(user),
             upper(@ArgErrorWindow), @ArgErrorText, @ArgDisplayOrder,
             'W', 'Y',
             upper(@ArgProcedureName), upper(@ArgWindowName),
        upper(@ArgTableName), @ArgTableRSN,
        USER, getdate()


       commit

GO
