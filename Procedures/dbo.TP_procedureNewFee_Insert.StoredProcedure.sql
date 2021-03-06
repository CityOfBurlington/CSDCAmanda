USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TP_procedureNewFee_Insert]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE   PROCEDURE [dbo].[TP_procedureNewFee_Insert] @argSourceFolder varchar(1000), 
@argDestinationFolder varchar(1000),
@DUserID varchar(1000)


AS

DECLARE @v_defaultproc varchar(2000)
DECLARE @n_procCount int

BEGIN

	SELECT @n_procCount = count(*)
	FROM defaultAccountBillFee
	WHERE folderType = @argSourceFolder
	AND defaultOrder = 1

	IF @n_procCount > 0
	BEGIN
		SET @v_defaultProc = '/******************************************************************************'+char(13)+char(10)+
					 'Call Common New Fee Procedure from '+@argSourceFolder+char(13)+char(10)+char(13)+char(10)+
					 '******************************************************************************/'+char(13)+char(10)+
					 'exec DefaultFee_'+@argSourceFolder+'_New @FolderRSN, @UserID'+char(13)+char(10)+char(13)+char(10)
	END
    ELSE
	BEGIN

	 	 SET @v_defaultProc ='/******************************************************************************'+char(13)+char(10)+
			'NAME: '+@argDestinationFolder+' - New Fee Procedure'+char(13)+char(10)+
			'PURPOSE:    '+char(13)+char(10)+
			'REVISIONS:'+char(13)+char(10)+char(13)+char(10)+
   			'Ver        Date        Author           Description'+char(13)+char(10)+
			'---------  ----------  ---------------  ------------------------------------'+char(13)+char(10)+
			'1.0        '+convert(varchar(100),getDate(),101)+'                   1. Created procedure'+char(13)+char(10)+char(13)+char(10)+

			'NOTES: '+char(13)+char(10)+char(13)+char(10)+
			'USE exec @n_feeAmount = TP_FEE_SELECT @infoCode to select the fee amount from FEES folder'+char(13)+char(10)+
			'******************************************************************************/'+char(13)+char(10)+char(13)+char(10)
			

	END
	SET @v_defaultProc = @v_defaultProc+'DECLARE @v_errorDesc varchar(2000)'+char(13)+char(10)
	+'DECLARE @n_feeAmount float'
	+char(13)+char(10)+

	+'--add '+@argDestinationFolder+' specific code here'+char(13)+char(10)+char(13)+char(10)
	+'exec TP_FEE_INSERT @FolderRSN, @argFeeCode, @n_feeAmount'; 

	INSERT INTO defaultAccountBillFee(procedureName, folderType, defaultOrder, defaultDesc, defaultProc, stampDate, stampUser)
	VALUES('DefaultFee_'+@argDestinationFolder+'_New',@argDestinationFolder,1,'New Fee Procedure',@v_defaultProc,getDate(), @DUserID);

END 









GO
