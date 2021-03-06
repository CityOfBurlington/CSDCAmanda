USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[GetPeopleRelatedView]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure GetPeopleRelatedView modified to add alias name in the label for people related view */

CREATE PROCEDURE [dbo].[GetPeopleRelatedView] @PeopleRSN INT, @UserId VARCHAR(128), @module_name varchar(100) =  null
AS
	DECLARE @v_startRSN INT
	DECLARE @v_currentRSN INT
	DECLARE @v_lvl INT
	DECLARE @noDataFound CHAR(1)
    DECLARE @v_ExistRSN INT
BEGIN
	/*
	Name of Person: ESS
	Date : March 28 2006
	Version: 4.4.6
	Procedure GetPeopleRelatedView is used in AMANDAi to get Related view structure for a specific PeopleRSN
	ESS Modified Nov 05 2008:Related view node click fixing in MS Sql Server DataBase.
	
	ESS Modified 2008.11.05 - Server hang problem during deleting a child folder in Related view
	ESS Modified 2008.12.05 - Used F_RelatedView_Label_People function
    ESS(Manjit):MOdified 2009.05.15 - 'PeopleCode' is used instead of 'PeopleRSN' as key value for caching the TabMask
	5.4.4.30: ESS Modified 2011.03.08 - Issue id :21255 (Alias name added for F_RelatedView_Label_People)
	*/
    
	CREATE TABLE #temp_People
		(
		ParentRSN       INT           ,
		PeopleRSN       INT           ,
		Path            VARCHAR(2000) ,
		Rowndx          INT           ,
		NameTitle     VARCHAR(4)      ,
		NameFirst     VARCHAR(25)     ,
		NameLast      VARCHAR(25)     ,
		OrganizationName VARCHAR(125) ,
        PeopleCode      INT              
		)

	SET @v_currentRSN = @PeopleRSN;
	SET @noDataFound = 'N'

    

	IF @module_name != 'PeopleGroup'
    BEGIN 
		WHILE (@v_currentRSN IS NOT NULL)
		BEGIN
        		SET @v_startRSN = @v_currentRSN
        		SELECT @v_currentRSN = CASE ParentRSN
						WHEN PeopleRSN THEN
							NULL
						WHEN @PeopleRSN THEN
							NULL
						ELSE
							ParentRSN
						END
			FROM People WHERE PeopleRSN = @v_currentRSN
			if @@rowcount = 0 		
				begin
					if @v_currentRSN = @PeopleRSN				
						begin
							set @noDataFound = 'Y'
						end
					else
						begin
							SET @v_startRSN = @v_ExistRSN				
						end
					set @v_currentRSN = null
	                
				end
			else
				begin
					SET @v_ExistRSN = @v_startRSN	
				end
		END
    END
	ELSE
	BEGIN
		SET @v_startRSN = @PeopleRSN 
	END
	if @noDataFound = 'N'
	   IF @module_name='PeopleGroup'
	       begin
				SET @v_lvl = 1			
				INSERT INTO #temp_People
				SELECT NUll,PeopleRSN,PeopleRSN,@v_lvl,NameTitle, NameFirst, NameLast, OrganizationName, PeopleCode
				FROM People WHERE PeopleRSN = @v_startRSN
				
				EXEC PopulatePeopleChildren @v_startRSN, @v_lvl OUT,'PeopleGroup'
				
		   end
       ELSE
		   begin
				SET @v_lvl = 1			
				INSERT INTO #temp_People
				SELECT ParentRSN,PeopleRSN,PeopleRSN,@v_lvl,NameTitle, NameFirst, NameLast, OrganizationName, PeopleCode
				FROM People WHERE PeopleRSN = @v_startRSN
				
				EXEC PopulatePeopleChildren @v_startRSN, @v_lvl OUT 
               
		    end
	SELECT Path, NameTitle, NameFirst, NameLast, OrganizationName, PeopleRSN, dbo.F_RelatedView_Label_People(PeopleRSN) LabelPeople,PeopleCode FROM #temp_People
	ORDER BY Rowndx
END

GO
