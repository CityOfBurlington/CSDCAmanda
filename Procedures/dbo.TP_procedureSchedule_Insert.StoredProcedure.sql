USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TP_procedureSchedule_Insert]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE  PROCEDURE [dbo].[TP_procedureSchedule_Insert] @argSourceFolder varchar(1000), 
@argDestinationFolder varchar(1000),
@DUserID varchar(1000)


AS

DECLARE @v_defaultproc varchar(2000)
DECLARE @n_procCount int

BEGIN

	SELECT @n_procCount = count(*)
	FROM defaultAccountBillFee
	WHERE folderType = @argSourceFolder
	AND defaultOrder = 900000001

	IF @n_procCount > 0
	BEGIN
		SET @v_defaultProc = '/******************************************************************************'+char(13)+char(10)+
					 'Call Common Schedule Procedure from '+@argSourceFolder+char(13)+char(10)+char(13)+char(10)+
					 '******************************************************************************/'+char(13)+char(10)+
					 'exec DefaultSchedule_'+@argSourceFolder+' @FolderRSN,@UserID, @ProcessRSN'+char(13)+char(10)+char(13)+char(10)
	END
    ELSE
	BEGIN

	 	 SET @v_defaultProc ='/******************************************************************************'+char(13)+char(10)+
			'NAME: '+@argDestinationFolder+' - Schedule Procedure'+char(13)+char(10)+
			'PURPOSE:    '+char(13)+char(10)+
			'REVISIONS:'+char(13)+char(10)+char(13)+char(10)+
   			'Ver        Date        Author           Description'+char(13)+char(10)+
			'---------  ----------  ---------------  ------------------------------------'+char(13)+char(10)+
			'1.0        '+convert(varchar(100),getDate(),101)+'                   1. Created procedure'+char(13)+char(10)+char(13)+char(10)+

			'NOTES: '+char(13)+char(10)+char(13)+char(10)+
			'******************************************************************************/'+char(13)+char(10)+char(13)+char(10)
			

	END
	SET @v_defaultProc = @v_defaultProc+'DECLARE @v_errorDesc varchar(2000)'+char(13)+char(10)+char(13)+char(10)+

	'--add '+@argDestinationFolder+' specific code here'+char(13)+char(10)+char(13)+char(10);

	INSERT INTO defaultAccountBillFee(procedureName, folderType, defaultOrder, defaultDesc, defaultProc, stampDate, stampUser)
	VALUES('DefaultSchedule_'+@argDestinationFolder,@argDestinationFolder,900000001,'Schedule Procedure',@v_defaultProc,getDate(), @DUserID);

END 







GO
