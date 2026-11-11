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
	CatalogAttributes = Metadata.Catalogs.ReportMailings.Attributes;
	Items.ServerAndDirectory.ToolTip      = CatalogAttributes.FTPDirectory.Tooltip;
	Items.Port.ToolTip                = CatalogAttributes.FTPPort.Tooltip;
	Items.Login.ToolTip               = CatalogAttributes.FTPUsername.Tooltip;
	Items.PassiveConnection.ToolTip = CatalogAttributes.FTPPassiveConnection.Tooltip;
	FillPropertyValues(ThisObject, Parameters, "Server, Directory, Port, Login, Password, PassiveConnection");
	If Server = "" Then
		Server = "server";
	EndIf;
	If Directory = "" Then
		Directory = "/directory/";
	EndIf;
	VisibleEnabled(ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ServerAndDirectoryOnChange(Item)
	FillPropertyValues(ThisObject, ReportMailingClient.ParseFTPAddress(ServerAndDirectory), "Server, Directory");
	VisibleEnabled(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Fill(Command)
	If Server = "" Then
		FullAddress = NStr("vi = 'ftp://tên đăng nhập:mật khẩu@server:cổng/thư mục/';
							|ru = 'ftp://логин:пароль@сервер:порт/каталог/';
							|en = 'ftp://username:password@server:port/directory'; fa = 'ftp://username:password@server:port/directory';
							|it = 'ftb://login:password@server:port/directory/';
							|pl = 'ftp://login:hasło@serwer:port/katalog/';
							|tr = 'ftp://kullanıcıadı:parola@sunucu:port/dizin'");
	Else
		If Login = "" Then
			FullAddress = "ftp://"+ Server +":"+ Format(Port, "NZ=21; NG=0") + Directory;
		Else
			FullAddress = "ftp://"+ Login +":"+ ?(ValueIsFilled(Password), PasswordHidden(), "") +"@"+ Server +":"+ Format(Port, "NZ=0; NG=0") + Directory;
		EndIf;
	EndIf;
	
	Handler = New CallbackDescription("FillCompletion", ThisObject);
	ShowInputString(Handler, FullAddress, NStr("vi = 'Hãy nhập địa chỉ đầy đủ ftp';
												|ru = 'Введите полный ftp адрес';
												|en = 'Enter full ftp address'; fa = 'Enter full ftp address';
												|it = 'Inserire indirizzo ftp completo';
												|pl = 'Wprowadź pełny adres ftp';
												|tr = 'Tam ftp adresi girin'"))
EndProcedure

&AtClient
Procedure OK(Command)
	SelectionValue = New Structure("Server, Directory, Port, Login, Password, PassiveConnection");
	FillPropertyValues(SelectionValue, ThisObject);
	NotifyChoice(SelectionValue);
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure VisibleEnabled(Form, Changes = "")
	If Not StrEndsWith(Form.Directory, "/") Then
		Form.Directory = Form.Directory + "/";
	EndIf;
	Form.ServerAndDirectory = "ftp://"+ Form.Server + Form.Directory;
EndProcedure

&AtClient
Procedure FillCompletion(InputResult, AdditionalParameters) Export
	If InputResult <> Undefined Then
		PasswordBeforeInput = Password;
		FillPropertyValues(ThisObject, ReportMailingClient.ParseFTPAddress(InputResult));
		If Password = PasswordHidden() Then
			Password = PasswordBeforeInput;
		EndIf;
		VisibleEnabled(ThisObject);
	EndIf;
EndProcedure

&AtClient
Function PasswordHidden()
	Return "********";
EndFunction

#EndRegion
