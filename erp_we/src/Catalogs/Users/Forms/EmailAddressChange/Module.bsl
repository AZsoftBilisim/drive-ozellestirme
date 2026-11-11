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
	
	OldEmail = Parameters.OldEmail;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeEmailAddress(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(OldEmail) Then
		QueryText =
			NStr("vi = 'Địa chỉ email của người dùng dịch vụ sẽ được đặt.
			           |Chủ sở hữu và quản trị viên sẽ không thể thay đổi cài đặt người dùng nữa.
			           |
			           |Bạn có muốn đặt địa chỉ email không?';
			           |ru = 'Адрес электронной почты пользователя сервиса будет установлен.
			           |Владельцы и администраторы абонента больше не смогут изменять параметры пользователя.
			           |
			           |Выполнить установку адреса электронной почты?';
			           |en = 'The service user''s email address will be set.
			           |Subscriber owners and administrators will no longer be able to change the user parameters.
			           |
			           |Do you want to set the email address?'; fa = 'The service user''s email address will be set.
			           |Subscriber owners and administrators will no longer be able to change the user parameters.
			           |
			           |Do you want to set the email address?';
			           |it = 'Адрес электронной почты пользователя сервиса будет установлен.
			           |Владельцы и администраторы абонента больше не смогут изменять параметры пользователя.
			           |
			           |Выполнить установку адреса электронной почты?';
			           |pl = 'The service user''s email address will be set.
			           |Subscriber owners and administrators will no longer be able to change the user parameters.
			           |
			           |Do you want to set the email address?';
			           |tr = 'Hizmet kullanıcısının e-posta adresi ayarlanacak.
			           |Abone sahipleri ve yöneticiler artık kullanıcı ayarlarını değiştiremeyecek.
			           |
			           |E-posta adresini ayarlamak istiyor musunuz?'");
	Else
		QueryText = NStr("vi = 'Thực hiện thay đổi địa chỉ E-mail?';
						|ru = 'Выполнить изменение адреса электронной почты?';
						|en = 'Do you want to change the email address?'; fa = 'Do you want to change the email address?';
						|it = 'Effettuare la modifica dell''indirizzo di posta elettronica?';
						|pl = 'Wykonać zmianę adresu poczty elektronicznej?';
						|tr = 'E-posta adresini değiştirmek istiyor musunuz?'");
	EndIf;
	
	ShowQueryBox(
		New CallbackDescription("ChangeEmailAddressContinued", ThisObject),
		QueryText,
		QuestionDialogMode.YesNoCancel);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeEmailAddressContinued(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		Close(NewEmailAddress);
	ElsIf Response = DialogReturnCode.No Then
		Close(Undefined);
	EndIf;
	
EndProcedure

#EndRegion
