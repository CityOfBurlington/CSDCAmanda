USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[csdc_SetRolePermissions]    Script Date: 9/9/2013 9:56:45 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE  PROCEDURE [dbo].[csdc_SetRolePermissions] AS
DECLARE @string varchar(2000),
	@name varchar(2000)
BEGIN
	SET NOCOUNT ON
	DECLARE cur_tables CURSOR FOR SELECT name FROM sysobjects WHERE xtype in ( 'U', '','V')
	OPEN cur_tables
	FETCH cur_tables INTO @name
	WHILE @@FETCH_status = 0
	BEGIN
		SET @string = 'REVOKE ALL ON ' + RTRIM(@name) + ' FROM reado, staff, senior, admin'
		EXECUTE ( @string )
		IF  @name NOT LIKE 'sys%'
		BEGIN
			SET @string = 'GRANT SELECT ON ' + RTRIM(@name) + ' TO reado'
			EXECUTE ( @string )
			SET @string = 'GRANT ALL ON ' + RTRIM(@name) + ' TO admin'
			EXECUTE ( @string )
			IF @name NOT LIKE 'Valid%' AND @name NOT LIKE 'Default%'
			BEGIN
				SET @string = 'GRANT ALL ON ' + RTRIM(@name) + ' TO staff, senior'
				EXECUTE ( @string )
			END
			ELSE
			BEGIN
				IF @name in ('ValidClause','ValidAdHoc','ValidLog')
				BEGIN
					SET @string = 'GRANT SELECT ON ' + RTRIM(@name) + ' TO staff'
					EXECUTE ( @string )

					SET @string = 'GRANT ALL ON ' + RTRIM(@name) + ' TO senior'
					EXECUTE ( @string )

				END
				ELSE
				BEGIN
					SET @string = 'GRANT SELECT ON ' + RTRIM(@name) + ' TO staff, senior'
					EXECUTE ( @string )
				END
			END
		END
		FETCH cur_tables INTO @name
	END
	CLOSE cur_tables
	DEALLOCATE cur_tables

	DECLARE cur_procs CURSOR FOR SELECT name FROM sysobjects WHERE xtype in ('P', 'FN') and name not like 'sys%'
	OPEN cur_procs
	FETCH cur_procs INTO @name
	WHILE @@FETCH_status = 0
	BEGIN
		SET @string = 'REVOKE ALL ON ' + RTRIM(@name) + ' FROM reado, staff, senior'
		EXECUTE ( @string )
		IF  @name NOT LIKE 'sys%'
		BEGIN
			SET @string = 'GRANT ALL ON ' + RTRIM(@name) + ' TO reado, staff, senior, admin'
			EXECUTE ( @string )
		END
		FETCH cur_procs INTO @name
	END
	CLOSE cur_procs
	DEALLOCATE cur_procs
-- user defined role permissions
--
--	REVOKE DELETE ON FolderProcessAttempt TO staff--, senior,admin
--	REVOKE UPDATE (ProcessRSN, FolderRSN, AttemptRSN, AttemptDate, AttemptBy, ResultCode) ON FolderProcessAttempt TO staff--admin, staff, senior
--	REVOKE DELETE ON Folder TO staff, senior, admin
--  REVOKE UPDATE, INSERT, DELETE ON PropertyPeople TO staff, senior, admin

END


GO
