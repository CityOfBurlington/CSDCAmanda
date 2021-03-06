USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetFolderTabRowCounts]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Function f_getFolderTabRowCounts modified to add the join for ValidProcess table for process count */

CREATE PROCEDURE [dbo].[GetFolderTabRowCounts](@FolderRSN INT, @TabMask VARCHAR(64), @UserId VARCHAR (128), @enableRLS VARCHAR (1)) 
AS 
BEGIN 
	
	-- 544.31:  Ess: Function f_getFolderTabRowCounts modified to add the join for ValidProcess table for process count 
	-- 5.4.4.30a_jems: ESS:Tapas 2011/08/19 - FolderAttachment tab rowcount should add FolderAttachment and ProcessAttachment rowcount for Jems. 
	-- 5.4.4.30a_jems: ESS:Sailendu 2011/05/31 - PeopleRowcount should add Folderuser and FolderContact rowcoubt for Jems. 
	-- 5.4.4.30: ESS:Tapas 2011/04/21 start - TabMask added for JEMS judgment Tab 
	-- 5.4.4.30: ESS:Sudhir 2011/05/13 start - Updated For Vehicle as per new implementation 
	-- 5.4.4.31: ESS:Jeevan 2012/01/11 - Modified for tab rowcount in the Folder Tab
	/*  
		Name of Person: ESS 
		Date : Jun 29,2010 
		Version: 44.28b 
		Comments :19327 - To fix ValidUser.MaxRows limiting Tab records instead of Return Records 
	*/ 
	/*  5.4.4.29a: Subhash 2010/12/15 argument @TabMask size changed from 32 to 64 as it has been increased in the database 
		5.4.4.29a: Mandy 2010/09/30 Certification fix 
		5.4.4.28b: April 14, 2010 Mandy modified to include new Certification tabMask 29  
		5.4.4.28b: Hongli - Add row count for Map tab   
	*/ 
	/* Version 4.4.26a: YUMING August 24, 2009: Changed data type to Integer from Numeric for @FolderRSN */ 
 
	/*  
		Amanda 44.25:   
		Name of Person: ESS   
		Date : March 28 2006   
		Version: 4.4.6   
 
	This procedure is ussed in AMANDAi for make the number of rows mask for Folder tab row counts.   
	*/ 
   
	DECLARE @rowCountMask		VARCHAR(2000) 
	DECLARE @no_of_rows			INT 
	DECLARE @processSQL			VARCHAR(1000) 
	DECLARE @sqlQry				NVARCHAR(4000) 
	DECLARE @no_of_max_rows		INT 
	DECLARE @n_groupTypeCode	INT 
	DECLARE @no_FolderUser_rows	INT 
	DECLARE @no_ContactUser_rows	INT 
   
	SET @rowCountMask		= '|' 
	SET @no_of_rows			= 0 
	SET @no_of_max_rows		= 0 
	SET	@n_groupTypeCode	= 0 
	SET @no_FolderUser_rows		= 0 
	SET @no_ContactUser_rows	= 0 
  
	SELECT	@no_of_max_rows = ISNULL(ValidUser.MaxRow,0) 
	FROM	ValidUser 
	WHERE	UserId = @UserId 
 
	SELECT	@n_groupTypeCode = MAX(ISNULL(ValidFolderGroup.GroupTypeCode,0)) 
    FROM	Folder, ValidFolderGroup, ValidFolder 
	WHERE	Folder.FolderRSN = @FolderRSN 
	AND		Folder.FolderType = ValidFolder.FolderType 
    AND		ValidFolderGroup.FolderGroupCode = ValidFolder.FolderGroupCode 
     
     IF(@n_groupTypeCode = 38 OR @n_groupTypeCode = 39 OR @n_groupTypeCode = 40 OR @n_groupTypeCode = 41) 
         BEGIN 
             SELECT @no_FolderUser_rows = COUNT(FolderUser.FolderRSN) 
             FROM FolderUser WHERE FolderUser.FolderRSN = @FolderRSN; 
         
             SELECT @no_ContactUser_rows = COUNT(FolderContact.FolderRSN) 
             FROM FolderContact WHERE FolderContact.FolderRSN = @FolderRSN; 
         
         END 
   
	IF(SUBSTRING(@TabMask,1,1) = 'Y') 
		BEGIN 
			-- Aspire 2008/09/22   
			IF(@enableRLS='Y') 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderProperty.FolderRSN) 
					FROM	FolderProperty 
					WHERE	FolderProperty.FolderRSN = @FolderRSN 
					AND		( 
								ISNULL(FolderProperty.SecurityCode, 0) = 0 
							OR	FolderProperty.SecurityCode IN ( 
																	SELECT	SecurityCode 
																	FROM	ValidProgramSecurityUser 
																	WHERE	UserId = @UserId 
																	AND		SelectFlag = 'Y' 
																) 
							) 
				END 
			ELSE 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderProperty.FolderRSN) 
					FROM	FolderProperty 
					WHERE	FolderProperty.FolderRSN = @FolderRSN 
				END 
 
		IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
			BEGIN 
				SET @no_of_rows = @no_of_max_rows 
			END 
   
		SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
	END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
 
   
	IF(SUBSTRING(@TabMask,2,1) = 'Y') 
		BEGIN 
			-- Aspire 2008/09/22   
			IF(@enableRLS='Y') 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderPeople.PeopleRSN) 
					FROM	FolderPeople 
					WHERE	FolderPeople.FolderRSN=@FolderRSN 
					AND		( 
								ISNULL(FolderPeople.SecurityCode, 0) = 0 
							OR	FolderPeople.SecurityCode IN ( 
																SELECT	SecurityCode 
																FROM	ValidProgramSecurityUser 
																WHERE	UserId = @UserId 
																AND		SelectFlag = 'Y' 
															 ) 
							) 
				END 
		ELSE 
			BEGIN 
				SELECT	@no_of_rows = COUNT(FolderPeople.PeopleRSN) 
				FROM	FolderPeople 
				WHERE	FolderPeople.FolderRSN = @FolderRSN 
			END 
  
		IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
			BEGIN 
				SET @no_of_rows = @no_of_max_rows 
			END 
		IF(@n_groupTypeCode = 38 OR @n_groupTypeCode = 39 OR @n_groupTypeCode = 40 OR @n_groupTypeCode = 41) 
		    BEGIN 
		        SET @no_of_rows = @no_of_rows + @no_FolderUser_rows + @no_ContactUser_rows 
 		    END 
   
		SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
	END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
 
   
	IF( SUBSTRING(@TabMask,3,1) = 'Y' ) 
		BEGIN 
			-- Aspire 2008/09/22   
			IF(@enableRLS = 'Y') 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderInfo.InfoCode) 
					FROM	FolderInfo 
					WHERE	FolderInfo.FolderRSN = @FolderRSN 
					AND		( 
								ISNULL(FolderInfo.SecurityCode, 0) = 0 
							OR	FolderInfo.SecurityCode IN	( 
																SELECT	SecurityCode 
																FROM	ValidProgramSecurityUser 
																WHERE	UserId = @UserId 
																AND		SelectFlag = 'Y' 
															) 
							) 
				END 
			ELSE 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderInfo.InfoCode) 
					FROM	FolderInfo 
					WHERE	FolderInfo.FolderRSN = @FolderRSN 
				END 
   
			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
				BEGIN 
					SET @no_of_rows = @no_of_max_rows 
				END 
  
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
   
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
   
	IF( SUBSTRING(@TabMask,4,1)='Y' ) 
		BEGIN 
			-- Aspire 2008/09/22   
			IF(@enableRLS = 'Y') 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderFixture.FixtureCode) 
					FROM	FolderFixture 
					WHERE	FolderFixture.FolderRSN = @FolderRSN 
					AND		( 
								ISNULL(FolderFixture.SecurityCode, 0) = 0 
							OR	FolderFixture.SecurityCode IN ( 
																SELECT	SecurityCode 
																FROM	ValidProgramSecurityUser 
																WHERE	UserId = @UserId 
																AND		SelectFlag = 'Y' 
															  ) 
							) 
				END 
			ELSE 
				BEGIN 
					SELECT	@no_of_rows = COUNT(FolderFixture.FixtureCode) 
					FROM	FolderFixture 
					WHERE	FolderFixture.FolderRSN = @FolderRSN 
				END 
   
			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
				BEGIN 
					SET @no_of_rows = @no_of_max_rows 
				END 
  
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
   
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
 
IF( SUBSTRING(@TabMask,5,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT @no_of_rows =COUNT(AccountBillFee.FeeCode) 
    FROM AccountBillFee 
   WHERE AccountBillFee.FolderRSN=@FolderRSN 
           AND (ISNULL(AccountBillFee.SecurityCode, 0) = 0 OR 
             AccountBillFee.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT @no_of_rows =COUNT(AccountBillFee.FeeCode) 
    FROM AccountBillFee 
   WHERE AccountBillFee.FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
 SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
IF( SUBSTRING(@TabMask,6,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT @no_of_rows  =COUNT(FolderProcess.FolderRSN) 
    FROM FolderProcess, ValidProcess 
   WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode = ValidProcess.ProcessCode 
           AND (ISNULL(FolderProcess.SecurityCode, 0) = 0 OR 
             FolderProcess.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
   
 END 
 ELSE 
 BEGIN 
  SELECT @no_of_rows  =COUNT(FolderProcess.FolderRSN) 
    FROM FolderProcess, ValidProcess 
   WHERE FolderProcess.FolderRSN = @FolderRSN 
     AND FolderProcess.ProcessCode = ValidProcess.ProcessCode 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
   SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF( SUBSTRING(@TabMask,7,1)='Y' ) 
BEGIN 
    /*SELECT @processSQL=REPLACE(ProcessSQL,char(13)+char(10) ,'') 
      FROM ValidProcessSQL, ValidUser 
     WHERE ValidUser.UserId=@UserId 
       AND ValidProcessSQL.ProcessSQLType = ValidUser.ProcessSQLType 
   
    SET @sqlQry = 'SELECT COUNT(FolderProcess.FolderRSN)' 
     + '  FROM FolderProcess,ValidProcess,ValidProcessGroup' 
     + '  WHERE ValidProcess.ProcessCode = FolderProcess.ProcessCode' 
     + '  AND ValidProcess.ProcessCode = FolderProcess.ProcessCode ' 
     + '  AND ValidProcessGroup.ProcessGroupCode = ValidProcess.ProcessGroupCode ' 
     + '  AND '+@processSQL 
     + '  AND FolderProcess.FolderRSN='+CAST(@FolderRSN AS VARCHAR(10)) 
 -- Aspire 2008/09/22 - start   
 IF(@enableRLS='Y') 
 BEGIN 
  SET @sqlQry = @sqlQry + '  AND (ISNULL(FolderProcess.SecurityCode, 0) = 0 OR   
      FolderProcess.SecurityCode in   
      (SELECT SecurityCode   
     FROM ValidProgramSecurityUser   
     WHERE UserId = '''+@UserId+'''   
     AND SelectFlag = ''Y''))' 
 END 
 -- Aspire 2008/09/22 - end   
    
  CREATE TABLE #t(x INT ) 
  INSERT INTO #t EXEC (@sqlQry) 
  SELECT @no_of_rows =  x FROM #t 
   
   	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR(2000))+'|' */
	SET @rowCountMask=@rowCountMask +'0'+'|' 
   
END 
ELSE 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
   
IF ( SUBSTRING(@TabMask,8,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT @no_of_rows =COUNT(FolderDocument.DocumentCode) 
    FROM FolderDocument 
   WHERE FolderDocument.FolderRSN=@FolderRSN 
           AND (ISNULL(FolderDocument.SecurityCode, 0) = 0 OR 
             FolderDocument.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT @no_of_rows =COUNT(FolderDocument.DocumentCode) 
    FROM FolderDocument 
   WHERE FolderDocument.FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF( SUBSTRING(@TabMask,9,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT  @no_of_rows = COUNT(FolderFile.FolderRSN) 
    FROM FolderFile 
   WHERE FolderFile.FolderRSN=@FolderRSN 
           AND (ISNULL(FolderFile.SecurityCode, 0) = 0 OR 
             FolderFile.SecurityCode in 
   (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT  @no_of_rows = COUNT(FolderFile.FolderRSN) 
    FROM FolderFile 
   WHERE FolderFile.FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF( SUBSTRING(@TabMask,10,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT @no_of_rows = COUNT(FolderInspectionRequest.ProcessCode) 
    FROM FolderInspectionRequest 
   WHERE FolderInspectionRequest.FolderRSN=@FolderRSN 
           AND (ISNULL(FolderInspectionRequest.SecurityCode, 0) = 0 OR 
             FolderInspectionRequest.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT @no_of_rows = COUNT(FolderInspectionRequest.ProcessCode) 
    FROM FolderInspectionRequest 
   WHERE FolderInspectionRequest.FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
IF( SUBSTRING(@TabMask,11,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT  @no_of_rows =COUNT(FolderComment.FolderRSN) 
    FROM  FolderComment 
   WHERE FolderRSN=@FolderRSN 
           AND (ISNULL(FolderComment.SecurityCode, 0) = 0 OR 
             FolderComment.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT  @no_of_rows =COUNT(FolderComment.FolderRSN) 
    FROM  FolderComment 
   WHERE FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF( SUBSTRING(@TabMask,12,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT @no_of_rows =COUNT(FolderClock.FolderRSN) 
    FROM FolderClock 
   WHERE FolderClock.FolderRSN=@FolderRSN 
           AND (ISNULL(FolderClock.SecurityCode, 0) = 0 OR 
             FolderClock.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT @no_of_rows =COUNT(FolderClock.FolderRSN) 
    FROM FolderClock 
   WHERE FolderClock.FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
IF( SUBSTRING(@TabMask,13,1)='Y' ) 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
  SELECT @no_of_rows =COUNT(FolderUsage.FolderRSN) 
    FROM FolderUsage 
   WHERE  FolderUsage.FolderRSN=@FolderRSN 
           AND (ISNULL(FolderUsage.SecurityCode, 0) = 0 OR 
             FolderUsage.SecurityCode in 
             (SELECT SecurityCode 
                 FROM ValidProgramSecurityUser 
                WHERE UserId = @UserId 
                  AND SelectFlag = 'Y')); 
 END 
 ELSE 
 BEGIN 
  SELECT @no_of_rows =COUNT(FolderUsage.FolderRSN) 
    FROM FolderUsage 
   WHERE  FolderUsage.FolderRSN=@FolderRSN 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
 
IF(SUBSTRING(@TabMask,14,1)='Y') 
BEGIN 
 -- Aspire 2008/09/22   
 IF(@enableRLS='Y') 
 BEGIN 
	IF(@n_groupTypeCode = 38 OR @n_groupTypeCode = 39 OR @n_groupTypeCode = 40 OR @n_groupTypeCode = 41) 
		BEGIN 
			SELECT @no_of_rows = COUNT(Attachment.TableRSN) 
			FROM Attachment 
		    WHERE ISNULL(CurrentVersionFlag, 'Y') = 'Y' 
			AND  Attachment.TableName IN ('Folder', 'FolderProcess') 
			AND (ATTACHMENT.TableRSN IN (SELECT ProcessRSN FROM FolderProcess WHERE FolderRSN = @FolderRSN) OR ATTACHMENT.TableRSN = @FolderRSN) 
			AND (ISNULL(Attachment.SecurityCode, 0) = 0 OR 
			Attachment.SecurityCode in (SELECT SecurityCode 
			FROM ValidProgramSecurityUser 
			WHERE UserId = @UserId 
			AND SelectFlag = 'Y')) 
		END 
	ELSE 
		BEGIN 
			SELECT @no_of_rows = COUNT(Attachment.TableRSN) 
			FROM Attachment 
		    WHERE ISNULL(CurrentVersionFlag, 'Y') = 'Y' 
			AND  Attachment.TableName='Folder' 
			AND  Attachment.TableRSN=@FolderRSN 
			AND (ISNULL(Attachment.SecurityCode, 0) = 0 OR 
			Attachment.SecurityCode in (SELECT SecurityCode 
			FROM ValidProgramSecurityUser 
			WHERE UserId = @UserId 
			AND SelectFlag = 'Y')) 
		END 
 END 
 ELSE 
 BEGIN 
	IF(@n_groupTypeCode = 38 OR @n_groupTypeCode = 39 OR @n_groupTypeCode = 40 OR @n_groupTypeCode = 41) 
		BEGIN 
			SELECT @no_of_rows = COUNT(Attachment.TableRSN) 
			FROM Attachment 
			WHERE ISNULL(CurrentVersionFlag, 'Y') = 'Y' 
			AND  Attachment.TableName IN ('Folder', 'FolderProcess') 
			AND (ATTACHMENT.TableRSN IN (SELECT ProcessRSN FROM FolderProcess WHERE FolderRSN = @FolderRSN) OR ATTACHMENT.TableRSN = @FolderRSN) 
		END 
	ELSE 
		BEGIN 
			SELECT @no_of_rows = COUNT(Attachment.TableRSN) 
			FROM Attachment 
			WHERE ISNULL(CurrentVersionFlag, 'Y') = 'Y' 
			AND  Attachment.TableName='Folder' 
			AND  Attachment.TableRSN=@FolderRSN 
		END 
 END 
 	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF(SUBSTRING(@TabMask,15,1)='Y') 
BEGIN 
   
  SELECT  @no_of_rows =COUNT(FolderEvent.FolderRSN) 
    FROM FolderEvent 
   WHERE FolderEvent.FolderRSN=@FolderRSN 
    
	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF(SUBSTRING(@TabMask,16,1)='Y') 
BEGIN 
  SELECT  @no_of_rows =COUNT(FolderDonation.FolderRSN) 
    FROM FolderDonation 
   WHERE FolderDonation.FolderRSN=@FolderRSN 
    
   	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF(SUBSTRING(@TabMask,17,1)='Y') 
BEGIN 
  SELECT  @no_of_rows =COUNT(FolderDraw.FolderRSN) 
    FROM FolderDraw 
   WHERE FolderDraw.FolderRSN=@FolderRSN 
   
  	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF(SUBSTRING(@TabMask,18,1)='Y') 
BEGIN 
  SELECT  @no_of_rows =COUNT(FolderWheel.FolderRSN) 
    FROM FolderWheel 
   WHERE FolderWheel.FolderRSN=@FolderRSN 
   
  	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
    SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
    SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
IF(SUBSTRING(@TabMask,19,1)='Y') 
BEGIN 
  SELECT @no_of_rows = COUNT(PeopleCourse.FolderRSN) 
    From PeopleCourse, People, Course, Folder 
 WHERE People.PeopleRSN = PeopleCourse.PeopleRSN 
 AND PeopleCourse.CourseRSN = Course.CourseRSN 
 AND PeopleCourse.FolderRSN = Folder.FolderRSN 
    AND Folder.FolderRSN=@FolderRSN 
     
    IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
   SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
   SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
IF(SUBSTRING(@TabMask,20,1)='Y' or SUBSTRING(@TabMask,20,1)='X')   /* Mandy 2010/09/30 */ 
BEGIN 
	/* Mandy 2010/04/14 new Certification */ 
 
	IF(SUBSTRING(@TabMask,20,1)='X') 
  		SELECT @no_of_rows = COUNT(*) 
    		From Certification 
 		WHERE Certification.FolderRSN = @FolderRSN 
    	ELSE 
  		SELECT @no_of_rows = COUNT(PeopleCourse.FolderRSN) 
    		From PeopleCourse, People, Course, Folder 
 		WHERE People.PeopleRSN = PeopleCourse.PeopleRSN 
 		AND PeopleCourse.CourseRSN = Course.CourseRSN 
 		AND PeopleCourse.FolderRSN = Folder.FolderRSN 
    		AND Folder.FolderRSN=@FolderRSN 
   
  	IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
	BEGIN 
		SET @no_of_rows = @no_of_max_rows 
	END 
   	SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
END 
ELSE 
BEGIN 
   SET @rowCountMask=@rowCountMask +'N'+'|' 
END 
   
	IF(SUBSTRING(@TabMask,21,1)='Y') 
		 --ESS when user calling this function from other than Vehicle Lic then join should be with FolderVehicle  
		BEGIN 
			IF @n_groupTypeCode <> 8		 -- If Folder is not belongs to FolderVehicle (Vehicle License - groupTypeCode 8) 
				BEGIN 
					SELECT @no_of_rows = COUNT(Folder.FolderRSN) 
					FROM Folder, FolderVehicle , Vehicle 
					WHERE Folder.FolderRSN =@FolderRSN 
					AND FolderVehicle.FolderRSN = Folder.FolderRSN AND FolderVehicle.VehicleRSN  = Vehicle.VehicleRSN 
 
					IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
						BEGIN 
							SET @no_of_rows = @no_of_max_rows 
						END 
				END 
			ELSE 
				BEGIN 
					 --ESS when user calling this function from Vehicle Lic then join should be with Vehicle 
 
						SELECT @no_of_rows = COUNT(Folder.FolderRSN) 
						FROM Folder, Vehicle 
						WHERE Folder.FolderRSN = @FolderRSN 
						AND Vehicle.VehicleRSN = Folder.VehicleRSN 
 
				END 
				SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
		   
	IF(SUBSTRING(@TabMask,22,1) = 'Y') 
		BEGIN 
			SELECT @no_of_rows = COUNT(FolderInsurance.FolderRSN) 
			  FROM FolderInsurance 
			 WHERE FolderInsurance.FolderRSN = @FolderRSN 
		      
  			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
				BEGIN 
					SET @no_of_rows = @no_of_max_rows 
				END 
  
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask =  @rowCountMask + 'N' + '|' 
		END 
   
	IF(SUBSTRING(@TabMask,23,1) = 'Y') 
		BEGIN 
			SELECT @no_of_rows = COUNT(FolderCondition.FolderRSN) 
			  FROM FolderCondition 
			 WHERE FolderCondition.FolderRSN = @FolderRSN 
		   
  			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
			BEGIN 
				SET @no_of_rows = @no_of_max_rows 
			END 
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
	IF(SUBSTRING(@TabMask,24,1) = 'Y') 
		BEGIN 
			SELECT @no_of_rows = COUNT(FolderCustomize.FolderRSN) 
			  FROM FolderCustomize 
			 WHERE FolderCustomize.FolderRSN=@FolderRSN 
		   
  			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
				BEGIN 
					SET @no_of_rows = @no_of_max_rows 
				END 
  
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
	IF(SUBSTRING(@TabMask,25,1) = 'Y') 
	BEGIN 
		SELECT @no_of_rows = COUNT(FolderCorrespondence.FolderRSN) 
		  FROM FolderCorrespondence 
		 WHERE FolderCorrespondence.FolderRSN = @FolderRSN 
	   
  		IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
			BEGIN 
				SET @no_of_rows = @no_of_max_rows 
			END 
  
		SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
	END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
	IF(SUBSTRING(@TabMask,26,1) = 'Y') 
		BEGIN 
			 -- Aspire 2008/09/22   
			 IF(@enableRLS = 'Y') 
				 BEGIN 
					  SELECT @no_of_rows = COUNT(FolderLRProperty.FolderRSN) 
						FROM FolderLRProperty 
					   WHERE FolderLRProperty.FolderRSN=@FolderRSN 
							   AND (ISNULL(FolderLRProperty.SecurityCode, 0) = 0 OR 
								 FolderLRProperty.SecurityCode in 
								 (SELECT SecurityCode 
									 FROM ValidProgramSecurityUser 
									WHERE UserId = @UserId 
									  AND SelectFlag = 'Y')); 
				 END 
			 ELSE 
				 BEGIN 
					  SELECT @no_of_rows = COUNT(FolderLRProperty.FolderRSN) 
						FROM FolderLRProperty 
					   WHERE FolderLRProperty.FolderRSN = @FolderRSN 
				 END 
			   
			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
				BEGIN 
					SET @no_of_rows = @no_of_max_rows 
				END 
  
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
	IF(SUBSTRING(@TabMask,27,1)='Y') 
		BEGIN 
			SELECT @no_of_rows = COUNT(FolderMap.FolderRSN) 
			  FROM FolderMap 
			 WHERE FolderMap.FolderRSN = @FolderRSN 
		   
  			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
				BEGIN 
					SET @no_of_rows = @no_of_max_rows 
				END 
			SET @rowCountMask = @rowCountMask + CAST(@no_of_rows AS VARCHAR) + '|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask = @rowCountMask + 'N' + '|' 
		END 
   
	IF(SUBSTRING(@TabMask,28,1)='Y') 
		BEGIN 
			SELECT @no_of_rows = COUNT(FolderMilestone.FolderRSN) 
			  FROM FolderMilestone 
			 WHERE FolderMilestone.FolderRSN=@FolderRSN 
		   
  			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
			BEGIN 
				SET @no_of_rows = @no_of_max_rows 
			END 
			SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask=@rowCountMask +'N'+'|' 
		END 
		 
	-- ESS:Tapas 2011/04/21 start - TabMask added for JEMS judgment Tab 
	IF(SUBSTRING(@TabMask,37,1)='Y') 
		BEGIN 
			SELECT @no_of_rows = COUNT(FolderJudgment.FolderRSN) 
			FROM FolderJudgment 
			WHERE FolderJudgment.FolderRSN=@FolderRSN 
		   
  			IF(@no_of_max_rows <> 0 AND @no_of_rows > @no_of_max_rows) 
			BEGIN 
				SET @no_of_rows = @no_of_max_rows 
			END 
			SET @rowCountMask=@rowCountMask +CAST(@no_of_rows AS VARCHAR)+'|' 
		END 
	ELSE 
		BEGIN 
			SET @rowCountMask=@rowCountMask +'N'+'|' 
		END 
	-- ESS:Tapas 2011/04/21 end 
	SELECT @rowCountMask RowCountMask 
 
END

GO
