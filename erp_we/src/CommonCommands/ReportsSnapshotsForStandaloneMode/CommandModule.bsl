///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

#If MobileClient Then
	OpenForm("InformationRegister.ReportsSnapshots.Form.ReportViewForm");
#Else
	CommonClient.MessageToUser(NStr(
			"vi = 'Lệnh này được dùng khi làm việc từ mobile client.';
			|ru = 'Данная команда используется при работе с мобильного клиента.';
			|en = 'This command is used in the mobile client.'; fa = 'This command is used in the mobile client.';
			|it = 'Данная команда используется при работе с мобильного клиента.';
			|pl = 'This command is used in the mobile client.';
			|tr = 'Bu komut mobil istemciden çalışırken kullanılmaktadır.'"));
#EndIf

EndProcedure

#EndRegion