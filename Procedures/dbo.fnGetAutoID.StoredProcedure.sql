USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[fnGetAutoID]    Script Date: 9/9/2013 9:56:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* For better performance, data type for @TheRSN changed to Int */ 

CREATE PROCEDURE [dbo].[fnGetAutoID] @sTableName VARCHAR(40), @sColumnName VARCHAR(40)
/* Version 4.4.26a: YUMING August 24, 2009: Changed data type to Integer from Numeric for @TheRSN */ 
/* Script Date: 3/28/2005 */
/* Modified: Aug 11, 2005 */
AS
BEGIN
    DECLARE @TheRSN  INT
    SET @sTableName = @sTableName+'SEQ'

    BEGIN TRANSACTION

    UPDATE Sequence_Tab
    SET    Seq_Value = ISNULL(Seq_Value,0) + ISNULL(INCREMENTBY,0)
    WHERE  Seq_Name = @sTableName

    SELECT @TheRSN = Seq_Value
    FROM   Sequence_Tab
    WHERE  Seq_Name = @sTableName

    COMMIT TRANSACTION

    RETURN @TheRSN
END

GO
