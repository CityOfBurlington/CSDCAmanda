USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PC_FolderStatus_Update]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PC_FolderStatus_Update]
(@argFolderRSN int, @argStatusCode int, @DUserid varchar(1000)=NULL, @argStatusFlag varchar(1000)=NULL)
--WITH 
--EXECUTE AS CALLER
AS
DECLARE @v_statusFlag varchar(10)
DECLARE @n_statusCount int
DECLARE @v_errorDesc varchar(2000)

BEGIN

	SELECT @n_statusCount = count(*)
	FROM validStatus
	WHERE statusCode = @argStatusCode;
  
	IF @n_statusCount <> 1
	BEGIN
		SET @v_errorDesc = cast(@argStatusCode as varchar)+' is an invalid Folder Status, please contact your AMANDA Administrator'
	 	RAISERROR(@v_errorDesc,16,-1)
	END

	IF @argStatusFlag IN ('X','C') --cancelled, Complete
	BEGIN
 
 
		UPDATE folder
		SET statusCode = @argStatusCode,
		finalDate = getDate()
		WHERE folderRSN = @argFolderRSN
	END
    ELSE IF @argStatusFlag = 'I' --Issued
	  BEGIN

	 	UPDATE folder
	 	SET statusCode = @argStatusCode,
	 	issueDate = getDate(),
		issueUser = @DUserid
	 	WHERE folderRSN = @argFolderRSN

	  END
	ELSE --all others
	BEGIN

		UPDATE folder
	 	SET statusCode = @argStatusCode
	 	WHERE folderRSN = @argFolderRSN
	--RAISERROR('here2',16,-1) 
	END

END

GO
