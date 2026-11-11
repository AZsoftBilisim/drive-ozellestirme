///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.SharedUser.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể xem thông tin về người dùng ""%1"" vì đây là 
		           |tài khoản dịch vụ được cung cấp cho quản trị viên dịch vụ.';
		           |ru = 'Просмотр сведений о пользователе ""%1"" недоступен, т.к. это 
		           |служебная учетная запись, предусмотренная для администраторов сервиса.';
		           |en = 'Cannot display information on user %1.
		           |This is a service account reserved for SaaS administrators.'; fa = 'Cannot display information on user %1.
		           |This is a service account reserved for SaaS administrators.';
		           |it = 'Просмотр сведений о пользователе ""%1"" недоступен, т.к. это 
		           |служебная учетная запись, предусмотренная для администраторов сервиса.';
		           |pl = 'Cannot display information on user %1.
		           |This is a service account reserved for SaaS administrators.';
		           |tr = '""%1"" kullanıcısı hakkındaki bilgiler görüntülenemiyor çünkü... 
		           |Bu, hizmet yöneticilerine yönelik bir hizmet hesabıdır.'"),
		String(Parameters.Key));
	
EndProcedure

#EndRegion