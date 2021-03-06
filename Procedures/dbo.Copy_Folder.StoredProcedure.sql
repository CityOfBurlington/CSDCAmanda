USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[Copy_Folder]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure Copy_Folder modified to copy the data for FolderFreeForm table from old folder to new folder */

CREATE PROCEDURE [dbo].[Copy_Folder] @ArgOldFolderRSN INT, @ArgNewFolderRSN INT, @ArgUserId VARCHAR(128)
AS
/* Version 5.4.4.301 2011.03.18 Satyajit Issue id : 21078 : Renewal functionality added for FreeForm*/
/* Version 44V29b: YUMING Jan. 17, 2011: Modified to fix the issue when the primary people is copied in the Public Portal */
/* Version 44V22: Subhash November 23, 2007: Modified to fix the issue of primary people not copied properly when renewing professional licence  */
/* Version 44V21: Subhash June 11, 2006: Not to copy primary people for people licence as it is done inside Amanda */
/* Version 4.4V12: Subhash September 18, 2006: Code changed to copy multiple folder usage rows from old folderrsn to new folderrsn, before this change this procedure was giving unique key error for folder usage table */
/* version 4.4: YUMING 2005.08.08 Make functionality same with oracle*/
/* Version 4.3V16.1: Subhash March 16, 2004: Make functionality same as oracle
                     For renewal, FolderProperty rows are copied from old folder to new folder as suggested by Chris Grant
		     Copy FolderComments only when folders are renewed as suggested by Marco, so previous code to copy folder comment commented
*/
/* Version 4.3V13:
   Subhash October 7, 2004: Andrew's change about removing ',' from infovalue while converting to numeric added
   Subhash October 7, 2004: FolderComment rows to be copied from old to new folderrsn
   Subhash October 7, 2004: Some extra conditon added in Insert for FolderPeople/FolderInfo/FolderFixture
*/

/* 2003.11.12 Subhash InfoValueUpper, InfoValueCrypt added in FolderInfo insert and PeopleRSNCrypt added in FolderPeople insert */

/* 2004.03.26 AP as per CG Synertech. Add logic to insert default info and default fixtures for the new foldertype. */

/* 2000.02.03 Robb Based on mandy.c.sql.amanda34.oracle.scr342.p_fold.sql dated 2000.1.1 */
/* 2000.02.03 Robb Reformatted, renamed and removed variables */
/* 2000.02.03 Robb Used FolderProcessSeq, FolderUsageSeq */
/* 2011.03.18 Satyajit Issue id : 21078 : Renewal functionality added for FreeForm*/

DECLARE @c_CopyFlag char(6)
DECLARE @c_DefaultFixture char(1)
DECLARE @c_DefaultInfo char(1)
DECLARE @c_DefaultPeople char(1)
DECLARE @c_DefaultProcess char(1)
DECLARE @c_DefaultUsage char(1)
DECLARE @c_DefaultFreeForm char(1)
DECLARE @n_Count integer


DECLARE @MaxRSN 		int,
	@ProcessCode 		int,
	@BaseLineStartDate	datetime,
	@BaseLineEndDate	datetime,
	@ScheduleDate		datetime,
	@ScheduleEndDate	datetime,
	@StartDate		datetime,
	@EndDate		datetime,
	@StatusCode	        int,
	@DisciplineCode	        int,
	@AssignedUser           varchar(128),
	@ReviewerUser           varchar(128),
	@SignOffUser          	varchar(128),
	@MandatoryFlag        	char(1),
	@ProcessComment		varchar(4000),
	@AssignFlag        	char(1),
	@PassedFlag        	char(1),
	@ConditionalOccupancy	char(1),
	@SignOff		char(1),
	@OrderIssued		char(1),
	@OrderComplied		char(1),
	@PrintFlag        	char(1),
	@DisplayOrder		int,
	@n_oldFolderRSN		int,
        @SecurityCode           Int

   /* YUMING 2005.08.08 added  @SecurityCode */
BEGIN
  /* copy Process, People, Info, Fixture, Usage according to the copy flag */

	SELECT @c_CopyFlag = Folder.CopyFlag
	FROM Folder
	WHERE Folder.FolderRSN = @ArgNewFolderRSN

	Set @c_DefaultPeople  = substring(@c_CopyFlag,1,1)
	Set @c_DefaultInfo    = substring(@c_CopyFlag,2,1)
	Set @c_DefaultFixture = substring(@c_CopyFlag,3,1)
	Set @c_DefaultProcess = substring(@c_CopyFlag,4,1)
	Set @c_DefaultUsage   = substring(@c_CopyFlag,5,1)

    IF LEN(@c_CopyFlag) > 5 
		Set @c_DefaultFreeForm = substring(@c_CopyFlag,6,1)

        SELECT  @MaxRSN = max(ProcessRSN) FROM FolderProcess
	SELECT  @MaxRSN = isnull(@MaxRSN,0)

  /*  Copy_FolderLink(ArgOldFolderRSN, ArgNewFolderRSN, c_CopyFlag); */

	IF @c_DefaultPeople = 'C'
	BEGIN
            -- Subhash November 23, 2007: Reverse back the changes made on June 11, 2007
     		INSERT INTO FolderPeople
			( FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampUser, StampDate, PeopleRSNCrypt, SecurityCode)
		-- YUMING Jan. 17, 2011 Comment out and Modified for Guelph's Problem with web portal
        --SELECT @ArgNewFolderRSN, PeopleCode, PeopleRSN, PrintFlag, @ArgUserId, GETDATE(), PeopleRSNCrypt, SecurityCode
		--FROM FolderPeople
		--WHERE FolderRSN = @ArgOldFolderRSN
		--and PeopleCode <> 2
        SELECT @ArgNewFolderRSN, A.PeopleCode, A.PeopleRSN, A.PrintFlag, @ArgUserId, GETDATE(), A.PeopleRSNCrypt, A.SecurityCode
		FROM FolderPeople A
		WHERE FolderRSN = @ArgOldFolderRSN
		and PeopleCode <> 2
        AND NOT EXISTS ( SELECT * FROM FolderPeople B WHERE 
        B.FolderRSN = @ArgNewFolderRSN
        AND A.PeopleCode = B.PeopleCode
        AND A.PeopleRSN = B.PeopleRSN
        AND ISNULL(A.PeopleRSNCrypt, 0) = ISNULL(B.PeopleRSNCrypt, 0))
		-- YUMING Jan. 17, 2011 Comment out and Modified for Guelph's Problem with web portal --- end

       -- Subhash October 7, 2004:
		-- if owner is inserted from RFS window before this is call, it gives unique constraint error,
		--  so checking wheterh owner is already inserted

		SELECT @n_Count = count(*)
      		FROM FolderPeople
     		WHERE FolderRSN = @ArgNewFolderRSN
       		and PeopleCode = 2

    		IF @n_Count = 0
		BEGIN
		   INSERT INTO FolderPeople
			( FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampUser, StampDate, PeopleRSNCrypt, SecurityCode)
		   SELECT @ArgNewFolderRSN, P.PeopleCode, P.PeopleRSN, 'Y', @ArgUserId, GETDATE(), P.PeopleRSNCrypt, P.SecurityCode
		   FROM Folder, PropertyPeople P
     		   WHERE Folder.FolderRSN = @ArgNewFolderRSN
       		   and P.PropertyRSN = Folder.PropertyRSN
       		   and P.PeopleCode  = 2
		-- End Subhash October 7, 2004
                --YUMING 2005.08.08 added a SecurityCode column

		   SELECT @n_Count = count(*)
      		   FROM FolderPeople
     		   WHERE FolderRSN = @ArgNewFolderRSN
       		   and PeopleCode = 2
		END

    		IF @n_Count = 0
                    --YUMING 2005.08.08 added a SecurityCode column
		begin
      			INSERT INTO FolderPeople
        			( FolderRSN, PeopleCode, PeopleRSN, PrintFlag, StampUser,StampDate, PeopleRSNCrypt, SecurityCode)
      			SELECT @ArgNewFolderRSN, PeopleCode, PeopleRSN, PrintFlag, @ArgUserId, GETDATE(), PeopleRSNCrypt, SecurityCode
        		FROM FolderPeople
       			WHERE FolderRSN = @ArgOldFolderRSN
         		and PeopleCode = 2
    		END
	END

	IF @c_DefaultFixture = 'C'
	BEGIN
    		INSERT INTO FolderFixture
      			( FolderRSN, FixtureCode, FixtureClass, Quantity,
        		Remark, DisplayOrder, StampUser, StampDate,FixtureSize, FixtureUnit,SecurityCode)
    		SELECT @ArgNewFolderRSN, FixtureCode, FixtureClass, Quantity,
           		Remark, DisplayOrder, @ArgUserId, GETDATE(), FixtureSize, FixtureUnit, SecurityCode
      		FROM FolderFixture
     		WHERE FolderRSN = @ArgOldFolderRSN
-- YUMING 2005.08.08 added a SecurityCode column
-- 2004/03/26 AP as per CG Synertech.
-- Only copy existing fixtures that are null, as the redefault that
-- follows will insert any missing default fixture records.
		 AND ISNULL( Quantity, 0) > 0
-- Added by Subhash October 7, 2004
		AND (FixtureCode NOT IN (
			SELECT FixtureCode
			FROM FolderFixture ff
			WHERE ff.folderrsn = @ArgNewFolderRSN))

-- 2004/03/26 AP as per CG Synertech.
-- Redefault missing fixtures (if old foldertype and new foldertype
-- differ, this redefaults the new folder
		INSERT INTO FOLDERFIXTURE
		      ( FolderRSN, FixtureCode, Quantity, DisplayOrder,
		        StampUser, StampDate, FixtureUnit, SecurityCode)
		SELECT @ArgNewFolderRSN, DF.FixtureCode, DF.Quantity, DF.DisplayOrder,
    			@ArgUserId, f.StampDate, DF.FixtureUnit, null
		FROM DEFAULTFIXTURE DF, Folder f
		WHERE f.folderrsn = @ArgNewFolderRSN
		AND (DF.FolderType = f.FolderType)
		AND (DF.FixtureCode NOT IN (
			SELECT DFE.FixtureCode
			FROM folder f, defaultfixtureexclusion dfe
			WHERE f.folderrsn = @ArgNewFolderRSN
			AND ( DFE.FolderType = f.FolderType )
			AND ( DFE.WorkCode   = f.WorkCode OR DFE.WorkCode = -999 OR
					( DFE.WorkCode IS NULL AND f.WorkCode IS NULL ))
			AND ( DFE.SubCode    = f.SubCode OR  DFE.SubCode = -999 OR
					( DFE.SubCode IS NULL AND f.SubCode IS NULL))
			))
		AND (DF.FixtureCode NOT IN (
			SELECT FixtureCode
			FROM FolderFixture ff
			WHERE ff.folderrsn = @ArgNewFolderRSN))

  	END
    -- YUMING 2005.08.08 added a SecurityCode column and stampdate is changed from GETDATE() to F.StampDate


  	IF @c_DefaultInfo = 'C'
	BEGIN
    		INSERT INTO FolderInfo
      			( FolderRSN, InfoCode, InfoValue, InfoValueNumeric, DisplayOrder, PrintFlag,
        		InfoValueDateTime, StampUser, StampDate, ValueRequired, Mandatory, InfoValueUpper, InfoValueCrypt, SecurityCode)
    		SELECT @ArgNewFolderRSN, InfoCode, InfoValue, InfoValueNumeric, DisplayOrder, PrintFlag,
           		InfoValueDateTime, @ArgUserId, GETDATE(), ValueRequired, Mandatory, InfoValueUpper, InfoValueCrypt, SecurityCode
      		FROM FolderInfo
     		WHERE FolderRSN = @ArgOldFolderRSN
--YUMING 2005.08.08 added a SecurityCode column
-- 2004/03/26 AP as per CG Synertech.
-- Only copy existing folderinfo that are null, as the redefault that
-- follows will insert any missing default info records.
		 AND ISNULL( InfoValue, '') <> ' '
-- Added by Subhash October 7, 2004
       		AND (InfoCode NOT IN (
			SELECT fi.InfoCode
			FROM FolderInfo fi
			WHERE fi.folderrsn = @ArgNewFolderRSN))


-- 2004/03/26 AP as per CG Synertech.
-- Redefault missing folderinfo (if old foldertype and new foldertype
-- differ, this redefaults the new folder
		INSERT INTO FOLDERINFO
      			( FolderRSN, InfoCode , InfoValue, DisplayOrder, PrintFlag,
        		Mandatory, InfoValueNumeric, StampUser, StampDate, ValueRequired, SecurityCode)
    		SELECT @ArgNewFolderRSN, DI.InfoCode, DI.InfoValue, DI.DisplayOrder, DI.PrintFlag,
           		Mandatory, 0 , @ArgUserId, GETDATE(), DI.RequiredForInitialSetup, null
      		FROM DEFAULTINFO DI, FOLDER f
		WHERE f.folderrsn = @ArgNewFolderRSN
       		AND (DI.FolderType = f.FolderType)
                AND (DI.FolderStage = f.StatusCode OR DI.FolderStage IS NULL)
       		AND (DI.InfoCode NOT IN
             		( SELECT DIE.InfoCode
                 	FROM FOLDER f, DEFAULTINFOEXCLUSION DIE
                	WHERE f.folderrsn = @ArgNewFolderRSN
                	AND ( DIE.FolderType = f.FolderType )
                  	AND ( DIE.WorkCode   = f.WorkCode OR  DIE.WorkCode   = -999 OR
                        	( DIE.WorkCode IS NULL AND f.WorkCode IS NULL ))
                  	AND ( DIE.SubCode    = f.SubCode OR  DIE.SubCode    = -999 OR
                        	( DIE.SubCode IS NULL AND f.SubCode IS NULL))
                        AND ( DIE.FolderStage = f.StatusCode OR  DIE.FolderStage = -999 OR
	                	        ( DIE.FolderStage IS NULL))))
       		AND (DI.InfoCode NOT IN (
			SELECT InfoCode
			FROM FolderInfo fi
			WHERE fi.folderrsn = @ArgNewFolderRSN))
--YUMING 2005.08.08 added a SecurityCode column and added the '(DI.FolderStage = f.StatusCode OR DI.FolderStage IS NULL)'
--and '( DIE.FolderStage = f.StatusCode OR  DIE.FolderStage = -999 OR ( DIE.FolderStage IS NULL)) 'in where clause

-- 2004/03/26 AP as per CG Synertech.
-- 2004/10/07 Subhash: Replace added for casting as sent by AP
    		UPDATE FOLDERINFO
       		SET InfoValueNumeric = CAST( REPLACE( InfoValue,',','') AS FLOAT), StampDate = GETDATE()
     		WHERE FOLDERINFO.FolderRSN = @ArgNewFolderRSN
       		AND FOLDERINFO.InfoCode IN
             		( SELECT InfoCode
                 	FROM VALIDINFO
                	WHERE InfoType = 'N')
       		--AND ISNUMERIC( RTRIM( LTRIM( REPLACE(FOLDERINFO.InfoValue,',','')))) = 1
                 AND dbo.f_amanda_IsNumeric(RTRIM(LTRIM(REPLACE(FOLDERINFO.InfoValue, ',', '')))) = 'Y';
/*2005.08.08 YUMING
changed 'AND ISNUMERIC( RTRIM( LTRIM( REPLACE(FOLDERINFO.InfoValue,',','')))) = 1' to
'AND dbo.f_amanda_IsNumeric(RTRIM(LTRIM(REPLACE(FOLDERINFO.InfoValue, ',', '')))) = 'Y';'
*/


-- 2004/03/26 AP as per CG Synertech.
		UPDATE FOLDERINFO
       		SET InfoValueDateTime = CONVERT( DATETIME, InfoValue), StampDate = GETDATE()
		WHERE FOLDERINFO.FolderRSN = @ArgNewFolderRSN
       		AND FOLDERINFO.InfoCode IN
             		( SELECT InfoCode
                 	FROM VALIDINFO
                	WHERE InfoType = 'D')
		AND ISDATE( InfoValue) = 1

-- 2004/03/26 AP as per CG Synertech.
    		UPDATE FOLDERINFO
       		SET InfoValueUpper = UPPER( InfoValue), StampDate = GETDATE()
     		WHERE FOLDERINFO.FolderRSN = @ArgNewFolderRSN

  	END

  	IF @c_DefaultUsage = 'C'
	BEGIN
		-- Subhash September 18, 2006: Following insert commented and replaced by cursor as it is failing while coping multipl folder usage rows
		
    		--	INSERT INTO FolderUsage
      		--		( FolderRSN, FolderUsageRSN, GenUse, Unit, SqFt,
       		--		OccClass, OccLoad, NoOfExits, StampUser, StampDate, SecurityCode)
     		--	SELECT @ArgNewFolderRSN, (SELECT MAX(FolderUsageRSN) + 1 FROM FolderUsage), GenUse, Unit, SqFt,
       		--    		OccClass, OccLoad, NoOfExits, @ArgUserId, GETDATE(), SecurityCode
       		--	FROM FolderUsage
      		--	WHERE FolderRSN = @ArgOldFolderRSN
      	
      
      		DECLARE @OldFolderUsageRSN int,
        	      @NewFolderUsageRSN int
      		SELECT  @NewFolderUsageRSN = max(FolderUsageRSN) FROM FolderUsage 
	  	SELECT  @NewFolderUsageRSN = isnull(@NewFolderUsageRSN, 0)
      		DECLARE COPY_FolderUsage_CURSOR CURSOR FOR
      		   SELECT FolderUsageRSN FROM FolderUsage WHERE FolderRSN = @ArgOldFolderRSN
      		OPEN COPY_FolderUsage_CURSOR 
         	FETCH COPY_FolderUsage_CURSOR INTO @OldFolderUsageRSN
         	WHILE @@FETCH_STATUS = 0
         	BEGIN
         	   SELECT  @NewFolderUsageRSN = @NewFolderUsageRSN + 1
    		   INSERT INTO FolderUsage 
      			( FolderRSN, FolderUsageRSN, GenUse, Unit, SqFt, 
        		OccClass, OccLoad, NoOfExits, StampUser, StampDate, SecurityCode)
     		   SELECT @ArgNewFolderRSN, @NewFolderUsageRSN, GenUse, Unit, SqFt,
            	  	  OccClass, OccLoad, NoOfExits, @ArgUserId, GETDATE(), SecurityCode
       		    FROM FolderUsage
      		   WHERE FolderRSN = @ArgOldFolderRSN and FolderUsageRSN = @OldFolderUsageRSN
            	   FETCH COPY_FolderUsage_CURSOR INTO @OldFolderUsageRSN
         	END
      		CLOSE COPY_FolderUsage_CURSOR
      		DEALLOCATE COPY_FolderUsage_CURSOR
		-- upto here      	
  	END
  --YUMING 2005.08.08  added a SecurityCode column




  /* copy all historical processes , i.e. processes
     which have been started */
  	IF @c_DefaultProcess = 'H'
	BEGIN
		/*RAISERROR('Historical reached.', 16, -1)*/

		DECLARE COPY_HISTORIC_PROCESS_CURSOR CURSOR FOR
     		SELECT  ProcessCode, BaseLineStartDate, BaseLineEndDate,
            		ScheduleDate, ScheduleEndDate, StartDate, EndDate, StatusCode,
            		DisciplineCode, AssignedUser, ReviewerUser, SignOffUser, MandatoryFlag,
            		ProcessComment, AssignFlag, PassedFlag, ConditionalOccupancy, SignOff,
            		OrderIssued, OrderComplied, PrintFlag, DisplayOrder, SecurityCode
       		FROM FolderProcess
      		WHERE FolderRSN = @ArgOldFolderRSN
        	and StartDate is not null

		OPEN COPY_HISTORIC_PROCESS_CURSOR
		FETCH COPY_HISTORIC_PROCESS_CURSOR INTO
			@ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
			@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
			@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
			@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
			@OrderIssued, @OrderComplied, @PrintFlag, @DisplayOrder , @SecurityCode


		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT  @MaxRSN = @MaxRSN + 1

			INSERT INTO FolderProcess
	      			( ProcessRSN, FolderRSN, ProcessCode, BaseLineStartDate, BaseLineEndDate,
        			ScheduleDate, ScheduleEndDate, StartDate, EndDate, StatusCode,
        			DisciplineCode, AssignedUser, ReviewerUser, SignOffUser, MandatoryFlag,
        			ProcessComment, AssignFlag, PassedFlag, ConditionalOccupancy, SignOff,
	        		OrderIssued, OrderComplied, PrintFlag, StampDate, StampUser, DisplayOrder , SecurityCode)
			VALUES ( @MaxRSN, @ArgNewFolderRSN, @ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
	            		@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
            			@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
	            		@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
            			@OrderIssued, @OrderComplied, @PrintFlag, GETDATE(), @ArgUserId, @DisplayOrder, @SecurityCode )

			FETCH COPY_HISTORIC_PROCESS_CURSOR INTO
				@ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
				@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
				@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
				@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
				@OrderIssued, @OrderComplied, @PrintFlag, @DisplayOrder, @SecurityCode

		END /* inner WHILE */
		CLOSE COPY_HISTORIC_PROCESS_CURSOR
		DEALLOCATE COPY_HISTORIC_PROCESS_CURSOR
  	END
--YUMING 2005.08.08 added a SecurityCode column
  /* copy all Issue stage processes which have been started */
  	IF @c_DefaultProcess = 'S'
	BEGIN
		/*RAISERROR('Issue stage reached.', 16, -1)*/

		DECLARE COPY_ISSUESTAGE_PROCESS_CURSOR CURSOR FOR
     		SELECT  FP.ProcessCode, FP.BaseLineStartDate, FP.BaseLineEndDate,
            		FP.ScheduleDate, FP.ScheduleEndDate, FP.StartDate, FP.EndDate, FP.StatusCode,
			FP.DisciplineCode, FP.AssignedUser, FP.ReviewerUser, FP.SignOffUser, FP.MandatoryFlag,
			FP.ProcessComment, FP.AssignFlag, FP.PassedFlag, FP.ConditionalOccupancy, FP.SignOff,
			FP.OrderIssued, FP.OrderComplied, FP.PrintFlag, FP.DisplayOrder, FP.SecurityCode
       		FROM FolderProcess FP, Folder, DefaultProcess, ValidFolder, ValidFolderGroup
       		WHERE FP.FolderRSN = @ArgOldFolderRSN
         	and FP.StartDate is not null
         	and Folder.FolderRSN = @ArgOldFolderRSN
         	and ValidFolder.FolderType = Folder.FolderType
         	and ValidFolderGroup.FolderGroupCode = ValidFolder.FolderGroupCode
         	and ValidFolderGroup.IssueStatusCode = DefaultProcess.FolderStage
         	and DefaultProcess.FolderType = Folder.FolderType
         	and FP.ProcessCode = DefaultProcess.ProcessCode;

		OPEN COPY_ISSUESTAGE_PROCESS_CURSOR
		FETCH COPY_ISSUESTAGE_PROCESS_CURSOR INTO
			@ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
			@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
			@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
			@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
			@OrderIssued, @OrderComplied, @PrintFlag, @DisplayOrder, @SecurityCode

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT  @MaxRSN = @MaxRSN + 1

			INSERT INTO FolderProcess
	      			( ProcessRSN, FolderRSN, ProcessCode, BaseLineStartDate, BaseLineEndDate,
        			ScheduleDate, ScheduleEndDate, StartDate, EndDate, StatusCode,
        			DisciplineCode, AssignedUser, ReviewerUser, SignOffUser, MandatoryFlag,
        			ProcessComment, AssignFlag, PassedFlag, ConditionalOccupancy, SignOff,
	        		OrderIssued, OrderComplied, PrintFlag, StampDate, StampUser, DisplayOrder, SecurityCode )
			VALUES ( @MaxRSN, @ArgNewFolderRSN, @ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
	            		@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
            			@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
	            		@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
            			@OrderIssued, @OrderComplied, @PrintFlag, GETDATE(), @ArgUserId, @DisplayOrder, @SecurityCode )

			FETCH COPY_ISSUESTAGE_PROCESS_CURSOR INTO
				@ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
				@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
				@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
				@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
				@OrderIssued, @OrderComplied, @PrintFlag, @DisplayOrder, @SecurityCode

		END /* inner WHILE */
		CLOSE COPY_ISSUESTAGE_PROCESS_CURSOR
		DEALLOCATE COPY_ISSUESTAGE_PROCESS_CURSOR
  	END
--YUMING 2005.08.08 added a SecurityCode column


  /* copy only the incomplete processes */
  --YUMING 2005.08.08 added a SecurityCode column
  	IF @c_DefaultProcess = 'I'
	BEGIN
		/*RAISERROR('Incomplete reached.', 16, -1)*/

		DECLARE COPY_INCOMPLETE_PROCESS_CURSOR CURSOR FOR

     		SELECT  ProcessCode, BaseLineStartDate, BaseLineEndDate,
            		ScheduleDate, ScheduleEndDate, StartDate, EndDate, StatusCode,
            		DisciplineCode, AssignedUser, ReviewerUser, SignOffUser, MandatoryFlag,
            		ProcessComment, AssignFlag, PassedFlag, ConditionalOccupancy, SignOff,
            		OrderIssued, OrderComplied, PrintFlag, DisplayOrder, SecurityCode
       		FROM FolderProcess
      		WHERE FolderRSN = @ArgOldFolderRSN
        	and StartDate is not null
        	and EndDate is null

		OPEN COPY_INCOMPLETE_PROCESS_CURSOR
		FETCH COPY_INCOMPLETE_PROCESS_CURSOR INTO
			@ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
			@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
			@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
			@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
			@OrderIssued, @OrderComplied, @PrintFlag, @DisplayOrder ,@SecurityCode

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT  @MaxRSN = @MaxRSN + 1

			INSERT INTO FolderProcess
	      			( ProcessRSN, FolderRSN, ProcessCode, BaseLineStartDate, BaseLineEndDate,
        			ScheduleDate, ScheduleEndDate, StartDate, EndDate, StatusCode,
        			DisciplineCode, AssignedUser, ReviewerUser, SignOffUser, MandatoryFlag,
        			ProcessComment, AssignFlag, PassedFlag, ConditionalOccupancy, SignOff,
	        		OrderIssued, OrderComplied, PrintFlag, StampDate, StampUser, DisplayOrder, SecurityCode )
			VALUES ( @MaxRSN, @ArgNewFolderRSN, @ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
	            		@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
            			@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
	            		@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
            			@OrderIssued, @OrderComplied, @PrintFlag, GETDATE(), @ArgUserId, @DisplayOrder, @SecurityCode )

			FETCH COPY_INCOMPLETE_PROCESS_CURSOR INTO
				@ProcessCode, @BaseLineStartDate, @BaseLineEndDate,
				@ScheduleDate, @ScheduleEndDate, @StartDate, @EndDate, @StatusCode,
				@DisciplineCode, @AssignedUser, @ReviewerUser, @SignOffUser, @MandatoryFlag,
				@ProcessComment, @AssignFlag, @PassedFlag, @ConditionalOccupancy, @SignOff,
				@OrderIssued, @OrderComplied, @PrintFlag, @DisplayOrder, @SecurityCode

		END /* inner WHILE */
		CLOSE COPY_INCOMPLETE_PROCESS_CURSOR
		DEALLOCATE COPY_INCOMPLETE_PROCESS_CURSOR
  	END  	
	--Abhisek: 21-Oct-2011: To Copy FolderFreeform data.
	IF @c_DefaultFreeForm = 'C'
	BEGIN
		DECLARE 
	    @FREEFORMCODE int, @PROCESSRSN int, @FORMROW int, @COMMENTS varchar(255),		
		@B01 char(1), @B02 char(1), @B03 char(1), @B04 char(1), @B05 char(1), @B06 char(1), @B07 char(1),
		@B08 char(1), @B09 char(1), @B10 char(1), @B11 char(1), @B12 char(1), @B13 char(1), @B14 char(1),
		@B15 char(1), @B16 char(1), @B17 char(1), @B18 char(1), @B19 char(1), @B20 char(1),
		@C01 varchar(80), @C02 varchar(80), @C03 varchar(80), @C04 varchar(80), @C05 varchar(80),
		@C06 varchar(80), @C07 varchar(80), @C08 varchar(80), @C09 varchar(80), @C10 varchar(80), 
		@C11 varchar(80), @C12 varchar(80), @C13 varchar(80), @C14 varchar(80), @C15 varchar(80), 
		@C16 varchar(80), @C17 varchar(80), @C18 varchar(80), @C19 varchar(80), @C20 varchar(80), 
		@C21 varchar(80), @C22 varchar(80), @C23 varchar(80), @C24 varchar(80), @C25 varchar(80), 
		@N01 numeric(10, 2), @N02 numeric(10, 2), @N03 numeric(10, 2), @N04 numeric(10, 2), @N05 numeric(10, 2), 
		@N06 numeric(10, 2), @N07 numeric(10, 2), @N08 numeric(10, 2), @N09 numeric(10, 2), @N10 numeric(10, 2), 
		@N11 numeric(10, 2), @N12 numeric(10, 2), @N13 numeric(10, 2), @N14 numeric(10, 2), @N15 numeric(10, 2), 
		@N16 numeric(10, 2), @N17 numeric(10, 2), @N18 numeric(10, 2), @N19 numeric(10, 2), @N20 numeric(10, 2), 
		@D01 datetime, @D02 datetime, @D03 datetime, @D04 datetime, @D05 datetime, @D06 datetime, @D07 datetime, 
		@D08 datetime, @D09 datetime, @D10 datetime, @D11 datetime, @D12 datetime, @D13 datetime, @D14 datetime, 
		@D15 datetime, @D16 datetime, @D17 datetime, @D18 datetime, @D19 datetime, @D20 datetime,
		@F01 numeric(18, 0), @F02 numeric(18, 0), @F03 numeric(18, 0), @F04 numeric(18, 0), @F05 numeric(18, 0), 
		@F06 numeric(18, 0), @F07 numeric(18, 0), @F08 numeric(18, 0), @F09 numeric(18, 0), @F10 numeric(18, 0), 
		@F11 numeric(18, 0), @F12 numeric(18, 0), @F13 numeric(18, 0), @F14 numeric(18, 0), @F15 numeric(18, 0), 
		@F16 numeric(18, 0), @F17 numeric(18, 0), @F18 numeric(18, 0), @F19 numeric(18, 0), @F20 numeric(18, 0),
		@NewFolderFreeFormRSN int
		
		SELECT  @NewFolderFreeFormRSN = isnull(max(FREEFORMRSN),0) FROM FOLDERFREEFORM
	      
		DECLARE COPY_FolderFreeForm_CURSOR CURSOR FOR
     		SELECT    FREEFORMCODE, PROCESSRSN, FORMROW, COMMENTS,
			  B01, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11, B12, B13, B14, B15, B16, B17, B18, B19, B20,
			  C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20,
			  C21, C22, C23, C24, C25,
			  D01, D02, D03, D04, D05, D06, D07, D08, D09, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19, D20,
			  F01, F02, F03, F04, F05, F06, F07, F08, F09, F10, F11, F12, F13, F14, F15, F16, F17, F18, F19, F20,
			  N01, N02, N03, N04, N05, N06, N07, N08, N09, N10, N11, N12, N13, N14, N15, N16, N17, N18, N19, N20
       		FROM FOLDERFREEFORM
      		WHERE FolderRSN = @ArgOldFolderRSN
        	AND ProcessRSN IS NULL        	

		OPEN COPY_FolderFreeForm_CURSOR
		FETCH COPY_FolderFreeForm_CURSOR INTO
			  @FREEFORMCODE, @PROCESSRSN, @FORMROW, @COMMENTS,
			  @B01, @B02, @B03, @B04, @B05, @B06, @B07, @B08, @B09, @B10, @B11, @B12, @B13, @B14, @B15, 
			  @B16, @B17, @B18, @B19, @B20,
			  @C01, @C02, @C03, @C04, @C05, @C06, @C07, @C08, @C09, @C10, @C11, @C12, @C13, @C14, @C15, 
			  @C16, @C17, @C18, @C19, @C20, @C21, @C22, @C23, @C24, @C25,
			  @D01, @D02, @D03, @D04, @D05, @D06, @D07, @D08, @D09, @D10, @D11, @D12, @D13, @D14, @D15, 
			  @D16, @D17, @D18, @D19, @D20,
			  @F01, @F02, @F03, @F04, @F05, @F06, @F07, @F08, @F09, @F10, @F11, @F12, @F13, @F14, @F15, 
			  @F16, @F17, @F18, @F19, @F20,
			  @N01, @N02, @N03, @N04, @N05, @N06, @N07, @N08, @N09, @N10, @N11, @N12, @N13, @N14, @N15, 
			  @N16, @N17, @N18, @N19, @N20

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT  @NewFolderFreeFormRSN = @NewFolderFreeFormRSN + 1

			INSERT INTO FOLDERFREEFORM
	      			( FREEFORMRSN, FREEFORMCODE, FOLDERRSN, PROCESSRSN, FORMROW, COMMENTS,
				  B01, B02, B03, B04, B05, B06, B07, B08, B09, B10, B11, B12, B13, B14, B15, B16, B17, B18, B19, B20,
				  C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20,
				  C21, C22, C23, C24, C25,
				  D01, D02, D03, D04, D05, D06, D07, D08, D09, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19, D20,
				  F01, F02, F03, F04, F05, F06, F07, F08, F09, F10, F11, F12, F13, F14, F15, F16, F17, F18, F19, F20,
				  N01, N02, N03, N04, N05, N06, N07, N08, N09, N10, N11, N12, N13, N14, N15, N16, N17, N18, N19, N20,
				  STAMPDATE, STAMPUSER )
			VALUES ( @NewFolderFreeFormRSN, @FREEFORMCODE, @ArgNewFolderRSN, @PROCESSRSN, @FORMROW, @COMMENTS,
				  @B01, @B02, @B03, @B04, @B05, @B06, @B07, @B08, @B09, @B10, @B11, @B12, @B13, @B14, @B15, 
				  @B16, @B17, @B18, @B19, @B20,
				  @C01, @C02, @C03, @C04, @C05, @C06, @C07, @C08, @C09, @C10, @C11, @C12, @C13, @C14, @C15, 
				  @C16, @C17, @C18, @C19, @C20, @C21, @C22, @C23, @C24, @C25,
				  @D01, @D02, @D03, @D04, @D05, @D06, @D07, @D08, @D09, @D10, @D11, @D12, @D13, @D14, @D15, 
				  @D16, @D17, @D18, @D19, @D20,
				  @F01, @F02, @F03, @F04, @F05, @F06, @F07, @F08, @F09, @F10, @F11, @F12, @F13, @F14, @F15, 
				  @F16, @F17, @F18, @F19, @F20,
				  @N01, @N02, @N03, @N04, @N05, @N06, @N07, @N08, @N09, @N10, @N11, @N12, @N13, @N14, @N15, 
				  @N16, @N17, @N18, @N19, @N20,
				  GETDATE(), @ArgUserId)

		FETCH COPY_FolderFreeForm_CURSOR INTO
					  @FREEFORMCODE, @PROCESSRSN, @FORMROW, @COMMENTS,
					  @B01, @B02, @B03, @B04, @B05, @B06, @B07, @B08, @B09, @B10, @B11, @B12, @B13, @B14, @B15, 
					  @B16, @B17, @B18, @B19, @B20,
					  @C01, @C02, @C03, @C04, @C05, @C06, @C07, @C08, @C09, @C10, @C11, @C12, @C13, @C14, @C15, 
					  @C16, @C17, @C18, @C19, @C20, @C21, @C22, @C23, @C24, @C25,
					  @D01, @D02, @D03, @D04, @D05, @D06, @D07, @D08, @D09, @D10, @D11, @D12, @D13, @D14, @D15, 
					  @D16, @D17, @D18, @D19, @D20,
					  @F01, @F02, @F03, @F04, @F05, @F06, @F07, @F08, @F09, @F10, @F11, @F12, @F13, @F14, @F15, 
					  @F16, @F17, @F18, @F19, @F20,
					  @N01, @N02, @N03, @N04, @N05, @N06, @N07, @N08, @N09, @N10, @N11, @N12, @N13, @N14, @N15, 
					  @N16, @N17, @N18, @N19, @N20

		END
		CLOSE COPY_FolderFreeForm_CURSOR
		DEALLOCATE COPY_FolderFreeForm_CURSOR
  	END

 	-- Subhash December 22, 2004: StampDate, StampUser copied from existing folder as suggested by Marco
  	SELECT @n_oldFolderRSN = ISNULL(OldFolderRSN,0) FROM Folder WHERE FolderRSN = @ArgNewFolderRSN;
  	IF @n_oldFolderRSN = @ArgOldFolderRSN
  	BEGIN
  	   --this is a renewal so copy folderproperty and the comments.
  	   -- 2005/03/14 CSDC CG: Copy folderproperty records
  	   INSERT INTO FolderProperty
  	         (FolderRSN, PropertyRSN, StampDate, StampUser, FolderPropertyUnit, RelationType, SecurityCode, Comments,
  	          F01, F02, F03, F04, F05, F06, F07, F08, C01, C02, C03, C04)
  	   SELECT @ArgNewFolderRSN, PropertyRSN, StampDate, StampUser, FolderPropertyUnit, RelationType, SecurityCode, Comments,
  	          F01, F02, F03, F04, F05, F06, F07, F08, C01, C02, C03, C04
  	     FROM FolderProperty
  	    WHERE FolderRSN = @ArgOldFolderRSN
  	      AND PropertyRSN NOT IN (SELECT PropertyRSN From FolderProperty WHERE FolderRSN = @ArgNewFolderRSN);
  	   -- End CG

	   -- Subhash October 7, 2004: to copy comments as well
	   INSERT INTO FolderComment
	       ( FolderRSN, CommentDate, CommentUser, ReminderDate, Comments, StampDate, StampUser, IncludeOnToDo)
	   SELECT @ArgNewFolderRSN, CommentDate, CommentUser, ReminderDate, Comments, StampDate, StampUser, IncludeOnToDo
	     FROM FolderComment
	    WHERE FolderRSN = @ArgOldFolderRSN

  	END
  	
  	--Abhisek: 26-Oct-2011: To Copy FolderCustomize data.
	IF @c_DefaultFreeForm = 'C'
	BEGIN
		DECLARE 
			@CustomizeCode int, @FC_DisplayOrder numeric(5, 0),
			@FC_C01 varchar(255), @FC_C02 varchar(255), @FC_C03 varchar(255), @FC_C04 varchar(255), @FC_C05 varchar(255),
			@FC_C06 varchar(255), @FC_C07 varchar(255), @FC_C08 varchar(255), @FC_C09 varchar(255), @FC_C10 varchar(255),
			@FC_COMMENTS varchar(2000), 
			@FC_N01 numeric(10, 2), @FC_N02 numeric(10, 2), @FC_N03 numeric(10, 2), @FC_N04 numeric(10, 2), @FC_N05 numeric(10, 2), 
			@FC_N06 numeric(10, 2), @FC_N07 numeric(10, 2), @FC_N08 numeric(10, 2), @FC_N09 numeric(10, 2), @FC_N10 numeric(10, 2),
			@FC_N11 numeric(10, 2), @FC_N12 numeric(10, 2),
			@FC_D01 datetime, @FC_D02 datetime, @FC_D03 datetime, @FC_D04 datetime, @FC_D05 datetime,
			@NewCustomizeRSN int

		SELECT  @NewCustomizeRSN = isnull(max(CustomizeRSN),0) FROM FOLDERCUSTOMIZE

		DECLARE COPY_FolderCustomize_CURSOR CURSOR FOR
		SELECT    
		CustomizeCode, DisplayOrder,
			C01, C02, C03, C04, C05,
			C06, C07, C08, C09, C10,
			COMMENTS, 
			N01, N02, N03, N04, N05, 
			N06, N07, N08, N09, N10,
			N11, N12,
			D01, D02, D03, D04, D05
		FROM FOLDERCUSTOMIZE
		WHERE FolderRSN = @ArgOldFolderRSN

		OPEN COPY_FolderCustomize_CURSOR
		FETCH COPY_FolderCustomize_CURSOR INTO
			@CustomizeCode, @FC_DisplayOrder,
			@FC_C01, @FC_C02, @FC_C03, @FC_C04, @FC_C05,
			@FC_C06, @FC_C07, @FC_C08, @FC_C09, @FC_C10,
			@FC_COMMENTS, 
			@FC_N01, @FC_N02, @FC_N03, @FC_N04, @FC_N05, 
			@FC_N06, @FC_N07, @FC_N08, @FC_N09, @FC_N10,
			@FC_N11, @FC_N12,
			@FC_D01, @FC_D02, @FC_D03, @FC_D04, @FC_D05

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT  @NewCustomizeRSN = @NewCustomizeRSN + 1

			INSERT INTO FOLDERCUSTOMIZE
				( 	CustomizeRSN, FolderRSN,
					CustomizeCode, DisplayOrder,
						C01, C02, C03, C04, C05,
						C06, C07, C08, C09, C10,
						COMMENTS, 
						N01, N02, N03, N04, N05, 
						N06, N07, N08, N09, N10,
						N11, N12,
						D01, D02, D03, D04, D05,
						STAMPDATE, STAMPUSER)
			VALUES ( 	
					@NewCustomizeRSN, @ArgNewFolderRSN, 
					@CustomizeCode, @FC_DisplayOrder,
					@FC_C01, @FC_C02, @FC_C03, @FC_C04, @FC_C05,
					@FC_C06, @FC_C07, @FC_C08, @FC_C09, @FC_C10,
					@FC_COMMENTS, 
					@FC_N01, @FC_N02, @FC_N03, @FC_N04, @FC_N05, 
					@FC_N06, @FC_N07, @FC_N08, @FC_N09, @FC_N10,
					@FC_N11, @FC_N12,
					@FC_D01, @FC_D02, @FC_D03, @FC_D04, @FC_D05,
					GETDATE(), @ArgUserId)

		FETCH COPY_FolderCustomize_CURSOR INTO
					@CustomizeCode, @FC_DisplayOrder,
					@FC_C01, @FC_C02, @FC_C03, @FC_C04, @FC_C05,
					@FC_C06, @FC_C07, @FC_C08, @FC_C09, @FC_C10,
					@FC_COMMENTS, 
					@FC_N01, @FC_N02, @FC_N03, @FC_N04, @FC_N05, 
					@FC_N06, @FC_N07, @FC_N08, @FC_N09, @FC_N10,
					@FC_N11, @FC_N12,
					@FC_D01, @FC_D02, @FC_D03, @FC_D04, @FC_D05

		END
		CLOSE COPY_FolderCustomize_CURSOR
		DEALLOCATE COPY_FolderCustomize_CURSOR
  	END
END


GO
