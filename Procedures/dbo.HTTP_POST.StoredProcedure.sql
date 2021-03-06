USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[HTTP_POST]    Script Date: 9/9/2013 9:56:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[HTTP_POST]( @sUrl varchar(8000), @response varchar(8000) out, @error varchar(100) out)
As


Declare
@obj int
,@hr int
,@status int
,@msg varchar(255)


exec @hr = sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT
-- exec @hr = sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT
if @hr <> 0 begin Raiserror('sp_OACreate MSXML2.ServerXMLHttp.3.0
failed', 16,1) return end


exec @hr = sp_OAMethod @obj, 'open', NULL, 'GET', @sUrl, false
if @hr <>0 begin set @msg = 'sp_OAMethod Open failed' goto eh end


exec @hr = sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type',
'application/x-www-form-urlencoded'
if @hr <>0 begin set @msg = 'sp_OAMethod setRequestHeader failed' goto
eh end


exec @hr = sp_OAMethod @obj, send, NULL, ''
if @hr <>0 begin set @msg = 'sp_OAMethod Send failed' goto eh end


exec @hr = sp_OAGetProperty @obj, 'status', @status OUT
if @hr <>0 begin set @msg = 'sp_OAMethod read status failed' goto
eh
end


if @status <> 200 begin set @msg = 'sp_OAMethod http status ' +
str(@status) goto eh end


exec @hr = sp_OAGetProperty @obj, 'responseText', @response OUT
if @hr <>0 begin set @msg = 'sp_OAMethod read response failed' goto
eh end

exec @hr = sp_OADestroy @obj
return
eh:
exec @hr = sp_OADestroy @obj
set @error = @msg
return


GO
