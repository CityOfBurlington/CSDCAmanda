USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[TK_FOLDERDOCUMENT_INSERT]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TK_FOLDERDOCUMENT_INSERT]
(@argFolderRSN int, @argDocumentCode int, @DUserID varchar(1000), @n_documentRSN int OUTPUT, @argAssignedUser varchar(1000)=NULL, @argDocumentComment varchar(1000)=NULL)
--WITH 
--EXECUTE AS CALLER
AS
--DECLARE @n_documentRSN int
DECLARE @n_displayOrder int


BEGIN
     Set @n_displayOrder=0

	 SELECT @n_documentRSN = max(ISNULL(documentRSN,0))+1--ISNULL(max(documentRSN),0)+1
	 FROM folderDocument


     SELECT @n_displayOrder=max(ISNULL(displayOrder,0))+5
	 FROM folderDocument
	 WHERE folderRSN = @argFolderRSN



     INSERT INTO folderDocument(folderRSN, documentRSN, documentCode, documentStatus, displayOrder, stampDate, stampUser, assignedUser, documentComment)
	 VALUES(@argFolderRSN, @n_documentRSN, @argDocumentCode, 1, @n_displayOrder, getDate(), @DUserID, @argAssignedUser, @argDocumentComment);

	 --KW 04/29/2009:  added a return for documentRSN in case further processing is needed
	 --RETURN @n_documentRSN
END;



GO
