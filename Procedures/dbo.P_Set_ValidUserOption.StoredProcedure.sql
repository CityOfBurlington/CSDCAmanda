USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[P_Set_ValidUserOption]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Procedure created to update existing or insert new row in the ValidUserOption table for the given user and option key */

CREATE PROCEDURE [dbo].[P_Set_ValidUserOption] @argUserId varchar(128), @argOptionKey varchar(2000), @argOptionValue varchar(2000), @DUserId varchar(128) as

-- Amanda 44.28: Subhash January 14, 2010: Updates/Inserts the data in ValidUserOption table */  

BEGIN 
if exists ( SELECT * FROM ValidUserOption WHERE OptionKey = @argOptionKey and UserID = @argUserId)
   UPDATE ValidUserOption 
      SET OptionValue = @argOptionValue,
	      StampDate = GETDATE(),
	   	  StampUser = @DUserId
  	WHERE OptionKey = @argOptionKey and UserID = @argUserId		 
 else
    INSERT INTO ValidUserOption 
	          (UserID, OptionKey, OptionValue, StampDate, StampUser)
		VALUES (@argUserId, @argOptionKey, @argOptionValue, GETDATE(), @DUserId)
-- Commit is done in Java Code     
END

GO
