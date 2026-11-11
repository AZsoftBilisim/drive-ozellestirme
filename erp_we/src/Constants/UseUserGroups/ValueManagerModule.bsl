///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = Constants.UseUserGroups.Get();
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi sử dụng nhóm người sử dụng trong ứng dụng trong dịch vụ.';
				|ru = 'Изменение использования групп пользователей следует выполнить в приложении в сервисе.';
				|en = 'User groups can only be customized in the SaaS version.'; fa = 'User groups can only be customized in the SaaS version.';
				|it = 'Изменение использования групп пользователей следует выполнить в приложении в сервисе.';
				|pl = 'User groups can only be customized in the SaaS version.';
				|tr = 'Kullanıcı gruplarının kullanımının değiştirilmesi servisteki uygulamada yapılmalıdır.'");
		Raise ErrorText;
		
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi sử dụng nhóm người sử dụng trong nút chính của cơ sở thông tin.';
				|ru = 'Изменение использования групп пользователей следует выполнить в главном узле информационной базы.';
				|en = 'User groups can only be customized in the master node.'; fa = 'User groups can only be customized in the master node.';
				|it = 'Изменение использования групп пользователей следует выполнить в главном узле информационной базы.';
				|pl = 'User groups can only be customized in the master node.';
				|tr = 'Kullanıcı gruplarının kullanımının değiştirilmesi infobase''in ana düğümünde yapılmalıdır.'");
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Constants.UseExternalUserGroups.Refresh();
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf