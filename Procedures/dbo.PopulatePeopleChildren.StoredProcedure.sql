USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[PopulatePeopleChildren]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Parameter @module_name added to retrieve data for people related view for Amandai depending upon modules */

CREATE PROCEDURE  [dbo].[PopulatePeopleChildren] (@p_parentRSN INT, @p_lvl INT out,@module_name varchar(100) =  null)
AS
	DECLARE @v_PeopleRSN INT
	DECLARE @v_path VARCHAR(2000)    
    IF @module_name = 'PeopleGroup'
      BEGIN
			/*
			Name of Person: ESS
			Date : March 28 2006
			Version: 4.4.6

			Procedure PopulatePeopleChildren is used in AMANDAi for generating the related Children for People Parent RSN
			ESS modified 12th Feb 2009: Used separate logic for People Member Tree. Code has been made conditional against the parameter @module_name (default value null) to avoid any imapct on the related view.          
            ESS (Manjit) :MOdified 2009.05.15 - 'PeopleCode' is used instead of 'PeopleRSN' as key value for caching the TabMask
			*/		        
				DECLARE c_crs CURSOR LOCAL FOR                  
					SELECT PeopleRSN,dbo.f_getRelatedPath(GroupRSN, 'PeopleGroup') path 
					FROM PeopleGroup
					WHERE GroupRSN  = @p_parentRSN AND PeopleRSN != @p_parentRSN
					AND Not Exists (Select PeopleRSN From #temp_People Where PeopleRSN = PeopleGroup.PeopleRSN)
				OPEN c_crs
				FETCH NEXT FROM c_crs INTO @v_PeopleRSN,@v_path
				WHILE @@FETCH_STATUS = 0
				BEGIN
						SET @p_lvl = @p_lvl+1;
						INSERT INTO #temp_People
						SELECT GroupRSN,People.PeopleRSN,@v_path,@p_lvl,NameTitle, NameFirst, NameLast, OrganizationName, People.PeopleCode
						FROM People,PeopleGroup WHERE People.PeopleRSN = @v_PeopleRSN
						and GroupRSN = @p_parentRSN and PeopleGroup.PeopleRSN = People.PeopleRSN
						EXEC PopulatePeopleChildren @v_PeopleRSN, @p_lvl OUT ,'PeopleGroup'
					FETCH NEXT FROM c_crs INTO @v_PeopleRSN,@v_path
				END
				CLOSE c_crs
				DEALLOCATE c_crs
		END
		
    ELSE
		 BEGIN
			/*
			Name of Person: ESS
			Date : March 28 2006
			Version: 4.4.6

			Procedure PopulatePeopleChildren is used in AMANDAi for generating the related Children for People Parent RSN
			*/
		        
				DECLARE c_crs CURSOR LOCAL FOR                  
					SELECT PeopleRSN,dbo.f_getRelatedPath(PeopleRSN, 'People') path FROM People
				WHERE ParentRSN  = @p_parentRSN AND PeopleRSN != @p_parentRSN
				AND Not Exists (Select PeopleRSN From #temp_People Where PeopleRSN = People.PeopleRSN)
				OPEN c_crs
				FETCH NEXT FROM c_crs INTO @v_PeopleRSN,@v_path
				WHILE @@FETCH_STATUS = 0
				BEGIN
						SET @p_lvl = @p_lvl+1;
						INSERT INTO #temp_People
						SELECT ParentRSN,PeopleRSN,@v_path,@p_lvl,NameTitle, NameFirst, NameLast, OrganizationName, PeopleCode
						FROM People WHERE PeopleRSN = @v_PeopleRSN

						EXEC PopulatePeopleChildren @v_PeopleRSN, @p_lvl OUT
					FETCH NEXT FROM c_crs INTO @v_PeopleRSN,@v_path
				END
				CLOSE c_crs
				DEALLOCATE c_crs
		END


GO
