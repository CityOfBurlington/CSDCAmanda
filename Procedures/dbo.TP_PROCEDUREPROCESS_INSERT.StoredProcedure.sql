USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TP_PROCEDUREPROCESS_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE    PROCEDURE [dbo].[TP_PROCEDUREPROCESS_INSERT] @argFolderType varchar(10), 
@argProcessCode int
AS

DECLARE @v_defaultDesc varchar(2000)
DECLARE @v_procedureName varchar(2000)
DECLARE @v_defaultProc varchar(8000);
DECLARE @v_defaultproc1 varchar(2000);
DECLARE @v_defaultproc2 varchar(2000);
DECLARE @n_procCount int;
DECLARE @n_rowCount int;
DECLARE @n_globalFolderRSN int;
DECLARE @v_globalFolderType varchar(2000)
DECLARE @n_globalProcCode float
DECLARE @v_GlobalFolder varchar(10)
DECLARE @n_commonCodeRSN int;
DECLARE @v_commonCodeType varchar(10)
DECLARE @n_commonProcCount int;
DECLARE @n_attemptCount int;
DECLARE @v_resultDesc varchar(100)
DECLARE @n_resultCode int



BEGIN

	SELECT @n_attemptCount = count(*)
	FROM  DefaultAttemptResult
	WHERE ProcessCode = @argProcessCode
	AND resultCode NOT IN (1)

	SELECT @n_procCount = count(*)
	FROM defaultProcessProcedure
	WHERE folderType = @argfolderType
	AND processCode = @argprocessCode
	AND ProcedureName NOT LIKE 'DefaultProcessInfo%'


	IF @n_procCount = 0 AND @n_attemptCount > 0 --create default procedure only if there isn't already one and there are default attempt results
	BEGIN

		--check mapping lookup table for common procedure

		SET @v_procedureName = 'DefaultAttempt_'+@argfolderType+'_'+cast(replace(str(@argprocessCode,8,0),' ','0') as char(8))

		SELECT @v_defaultDesc = processDesc
		FROM validProcess
		WHERE processCode = @argprocessCode

		SELECT @v_globalFolderType = max(lookupString), @n_globalProcCode = max(lookup2)
		FROM validLookup
		WHERE lookupCode = 50
		AND lookup1 = @argProcessCode
		
		--check to see if the common code folder has an entry
		
		SELECT @n_commonCodeRSN = max(folderRSN)
		FROM folder 
		WHERE folderType = 'CONF'
		AND LTRIM(RTRIM(folderName)) = @argFolderType;
		
		IF  @n_commonCodeRSN IS NOT NULL
		BEGIN
			SET @v_commonCodeType = dbo.tk_folderInfo_alpha(@n_commonCodeRSN, 200)
			
			IF @v_commonCodeType IS NOT NULL --check to see if there is an attemptProcedure
			BEGIN
			
				SELECT @n_commonProcCount = count(*)
				FROM defaultProcessProcedure
				WHERE folderType = @v_commonCodeType
				AND processCode = @argprocessCode
				AND ProcedureName NOT LIKE 'DefaultProcessInfo%'
			
			END
		END

		IF @v_globalFolderType IS NOT NULL AND @n_globalProcCode IS NOT NULL
		BEGIN
			
			SET @v_defaultProc= '/******************************************************************************'+char(13)+char(10)+
			'Call Common Procedure '+@v_globalFolderType+' '+@n_globalProcCode+char(13)+char(10)+char(13)+char(10)+
			'******************************************************************************/'+char(13)+char(10)+char(13)+char(10)+
			'DefaultAttempt_'+@v_globalFolderType+'_'+cast(replace(str(@n_globalProcCode,8,0),' ','0') as char(8))+'(@ProcessRSN, @FolderRSN, @UserID, @AttemptRSN);'
		;
		END
		ELSE IF @v_commonCodeType IS NOT NULL AND @n_commonProcCount > 0
		BEGIN
			SET @v_globalFolderType = @v_commonCodeType;
			SET @n_globalProcCode = @argprocessCode;

			SET @v_defaultProc = '/******************************************************************************'+char(13)+char(10)+
			'Call Common Procedure '+@v_globalFolderType+' '+@n_globalProcCode+char(13)+char(10)+char(13)+char(10)+
			'******************************************************************************/'+char(13)+char(10)+char(13)+char(10)+
			'DefaultAttempt_'+@v_globalFolderType+'_'+cast(replace(str(@n_globalProcCode,8,0),' ','0') as char(8))+'(@ProcessRSN, @FolderRSN, @UserID, @AttemptRSN);'
		;
		
		END
		ELSE
		BEGIN
			SET @v_defaultProc ='/******************************************************************************'+char(13)+char(10)+
			'NAME: '+@argFolderType+' - '+@v_defaultDesc+char(13)+char(10)+
			'PURPOSE:    '+char(13)+char(10)+
			'REVISIONS:'+char(13)+char(10)+char(13)+char(10)+
   			'Ver        Date        Author           Description'+char(13)+char(10)+
			'---------  ----------  ---------------  ------------------------------------'+char(13)+char(10)+
			'1.0        '+convert(varchar(100),getDate(),101)+'                   1. Created procedure'+char(13)+char(10)+char(13)+char(10)+

			'NOTES: '+char(13)+char(10)+char(13)+char(10)+
			'******************************************************************************/'+char(13)+char(10)+char(13)+char(10)
			;

			SET @v_defaultProc = @v_defaultProc+'--AMANDA Standard Variables'+char(13)+char(10)+
			'DECLARE @n_ResultCode int'+char(13)+char(10)+
			'DECLARE @v_attemptComment varchar(2000)'+char(13)+char(10)+
			'DECLARE @v_processComment varchar(2000)'+char(13)+char(10)+
			'DECLARE @n_HourSpent float'+char(13)+char(10)+
			'DECLARE @n_OverTime float'+char(13)+char(10)+
			'DECLARE @v_timeUnit varchar(10)'+char(13)+char(10)+
			'DECLARE @n_MileageAmount float'+char(13)+char(10)+
			'DECLARE @n_ExpenseAmount float'+char(13)+char(10)+char(13)+char(10)+
			'--AMANDA Standard Exception Handling'+char(13)+char(10)+
			'DECLARE @v_errorDesc varchar(2000);'+char(13)+char(10)+char(13)+char(10)+
			'--Additional Variables'+char(13)+char(10)+char(13)+char(10)+
			--'exec tp_attemptResult_Validate @ProcessRSN, @UserID'+char(13)+char(10)+char(13)+char(10)+
			'exec TK_ATTEMPTDETAILS_SELECT @ProcessRSN, @AttemptRSN, @n_ResultCode OUTPUT, @v_attemptComment OUTPUT,'+char(13)+char(10)+
			'@v_processComment OUTPUT, @n_HourSpent OUTPUT, @n_OverTime OUTPUT, @v_timeUnit OUTPUT, @n_MileageAmount OUTPUT, @n_ExpenseAmount OUTPUT'+char(13)+char(10)+char(13)+char(10)
			SET @n_rowCount = 1
			
			DECLARE AttemptList CURSOR FOR
			SELECT v.resultDesc, v.resultCode
			FROM DefaultAttemptResult d, ValidProcessAttemptResult v
			WHERE d.ProcessCode = @argProcessCode
			AND d.resultCode = v.resultCode
			AND v.resultCode NOT IN (1) --we aren't going to code rules for reopen

			OPEN AttemptList
            		FETCH NEXT FROM AttemptList INTO @v_resultDesc, @n_resultCode
			WHILE @@FETCH_STATUS = 0
			BEGIN
	
				IF @n_rowCount = 1 
				BEGIN
					SET @v_defaultProc = @v_defaultProc + 'IF @n_resultCode = '+cast(@n_resultCode as varchar(10))+' --'+@v_resultDesc+char(13)+char(10)+
					'BEGIN'+char(13)+char(10)
				END
				ELSE
				BEGIN
					SET @v_defaultProc = @v_defaultProc + 'ELSE IF @n_resultCode = '+cast(@n_resultCode as varchar(10))+' --'+@v_resultDesc+char(13)+char(10)+
					'BEGIN'+char(13)+char(10)
				END

				SET @v_defaultProc = @v_defaultProc+char(9)+'exec pc_Process_Update @ProcessRSN, 0, @UserID, @n_resultCode'+char(13)+char(10)+char(13)+char(10)+
				'END'+char(13)+char(10)+char(13)+char(10)				
				
				SET @n_rowCount = @n_rowCount +1;
				FETCH NEXT FROM AttemptList INTO @v_resultDesc, @n_resultCode
			END
			DEALLOCATE AttemptList

			SET @v_defaultProc = @v_defaultProc+'ELSE --attempt Result is not a default for this process'+char(13)+char(10)+
			'BEGIN'+char(13)+char(10)+char(13)+char(10)+
			char(9)+'exec pc_attemptResult_Invalid @ProcessRSN, @n_resultCode'+char(13)+char(10)+char(13)+char(10)+
			'END';
		END

		IF len(@v_defaultProc) > 2000
		BEGIN
		   SET @v_defaultproc1 = ltrim(left(@v_defaultProc,2000));
		   SET @v_defaultproc2 = ltrim(substring(@v_defaultProc,2001,len(@v_defaultproc)))
		END
		ELSE
		BEGIN
		   SET @v_defaultproc1 = @v_defaultProc;
		END

		INSERT INTO defaultProcessProcedure(ProcedureName, folderType, processCode, defaultDesc, defaultProc, defaultproc01, stampDate, stampUser)
		VALUES(@v_procedureName, @argfolderType, @argprocessCode, @v_defaultDesc, @v_defaultProc1, @v_defaultproc2, getDate(), USER);


	END

END









GO
