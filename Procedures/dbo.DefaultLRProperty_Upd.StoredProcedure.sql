USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[DefaultLRProperty_Upd]    Script Date: 9/9/2013 9:56:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[DefaultLRProperty_Upd] (@argLRPropertyRSN INT, @DUserId VARCHAR(128)) AS
BEGIN

DELETE FROM LRPropertyInfo
WHERE LRPropertyRSN = @argLRPropertyRSN
AND LRPropertyInfoValue IS NULL
AND LRPropertyInfoCode NOT IN
    ( SELECT LRPropertyInfoCode
      FROM DefaultLRPropertyInfo, LRProperty
      WHERE DefaultLRPropertyInfo.LRPropertyCode = LRProperty.LRPropertyCode
      AND LRProperty.LRPropertyRSN = @argLRPropertyRSN )

INSERT INTO LRPropertyInfo ( LRPropertyRSN, LRPropertyInfoCode )
SELECT @argLRPropertyRSN, DefaultLRPropertyInfo.LRPropertyInfoCode
FROM DefaultLRPropertyInfo, LRProperty
WHERE LRProperty.LRPropertyRSN = @argLRPropertyRSN
AND DefaultLRPropertyInfo.LRPropertyCode = LRProperty.LRPropertyCode
AND DefaultLRPropertyInfo.LRPropertyInfoCode NOT IN
    ( SELECT LRPropertyInfo.LRPropertyInfoCode
      FROM LRPropertyInfo
      WHERE LRPropertyInfo.LRPropertyRSN = @argLRPropertyRSN )

END

GO
