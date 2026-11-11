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
	
	Record.FileOwner = Parameters.FileOwner;
	Record.FileOwnerType = Parameters.FileOwnerType;
	Record.IsFile = Parameters.IsFile;
	
	If ValueIsFilled(Record.Account) Then
		Items.Account.ReadOnly = True;
	EndIf;
	
	OwnerPresentation = Common.SubjectString(Record.FileOwner);
	
	Title = NStr("vi = 'Tùy chỉnh đồng bộ hóa tệp:';
				|ru = 'Настройка синхронизации файлов:';
				|en = 'File synchronization setting:'; fa = 'File synchronization setting:';
				|it = 'Impostazioni di sincronizzazione dei file';
				|pl = 'Dostosowanie synchronizacji plików:';
				|tr = 'Dosya eşleşmesinin ayarı:'")
		+ " " + OwnerPresentation;
	
EndProcedure

#EndRegion