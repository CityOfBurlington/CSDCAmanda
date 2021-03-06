USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[p_UpdParentChild]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[p_UpdParentChild] 
AS

DECLARE 	@n_FolderRSN	INT,
		@n_new		INT,
		@n_parent		INT,
		@n_parentNew    	INT,
		@n_parentCount 	INT,
		@n_ChildCount  	INT,
		@n_FolderChild	INT,
		@n_ChildParent	INT,
		@n_ChildRenew  	INT,
		@ParmChild  	INT
BEGIN

DECLARE  Curs_fol CURSOR FOR
SELECT FolderRSN, ISNULL(NewFolderRSN,0),ISNULL(ParentRSN,0) FROM FOLDER

/* Cursor to hold the Children */

DECLARE Curs_child CURSOR FOR
   SELECT FolderRSN, ISNULL(ParentRSn,0), ISNULL(NewFOlderRSN,0) FROM FOLDER
   WHERE ISNULL(ParentRSN,0) > 0
   AND   ParentRSN = @ParmChild

  OPEN Curs_fol
  FETCH Curs_fol 
  INTO @n_FolderRSN,@n_new, @n_parent
  WHILE @@FETCH_STATUS = 0
  IF @n_parent > 0 
   /* Check the parent of this */
    SELECT @n_ParentCount = COUNT(*)
    FROM  FOLDER
    WHERE FolderRSN = @n_parent
 IF @n_parentCount > 0 
    SELECT @n_ParentNew = ISNULL(NewFolderRSN,0)
    FROM FOLDER
    WHERE FOlderRSN = @n_Parent
/* Check Parent Renewed */
    IF @n_ParentNew > 0 AND @n_parentNew <> @n_Parent 
	UPDATE FOLDER
	SET    ParentRSN = @n_parentNew
	WHERE  FolderRSn = @n_FolderRSn
	COMMIT
     
IF @n_New > 0 
      /* Check Child */
	SELECT @n_ChildCount = COUNT(*)
	FROM   FOLDER
	WHERE  ISNULL(ParentRSN,0) > 0
	AND    ParentRSN = @n_FolderRSN

        IF @n_childCount > 0 
           SET @ParmChild = @n_FolderRSN
           OPEN Curs_child
           FETCH Curs_Child 
           INTO @n_FolderChild, @n_ChildParent, @n_ChildRenew 
           WHILE @@FETCH_STATUS = 0
	     IF @n_ChildParent > 0 AND @n_childRenew >  0 
                UPDATE FOLDER
                SET ParentRSN = @n_new
                WHERE FolderRSN = @n_childRenew
		COMMIT
           CLOSE Curs_child
           DEALLOCATE Curs_child
CLOSE  Curs_fol
DEALLOCATE Curs_fol
END 


GO
