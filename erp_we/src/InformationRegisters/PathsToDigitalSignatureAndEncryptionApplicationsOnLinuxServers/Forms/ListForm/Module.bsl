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
	
	If Parameters.Filter.Property("Application") 
	   And ValueIsFilled(Parameters.Filter.Application) Then
		
		Application = Parameters.Filter.Application;
		
		AutoTitle = False;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đường dẫn đến ứng dụng %1 trên server Linux';
				|ru = 'Пути к приложению %1 на серверах Linux';
				|en = 'Paths to %1 on Linux servers'; fa = 'Paths to %1 on Linux servers';
				|it = 'Paths to %1 on Linux servers';
				|pl = 'Paths to %1 on Linux servers';
				|tr = 'Linux sunucularında %1 uygulamasına giden yol'"), Application);
		
		Items.ListApplication.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	If Not ValueIsFilled(Application) Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", Items.List.CurrentRow);
	FormParameters.Insert("FillingValues", New Structure("Application", Application));
	
	OpenForm("InformationRegister.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers.RecordForm",
		FormParameters, Items.List, ,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	RowToDelete          = Items.List.CurrentRow;
	RowToDeleteApplication = Items.List.CurrentData.Application;
	
EndProcedure

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	Notify("Write_PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers",
		New Structure("Application", RowToDeleteApplication), RowToDelete);
	
EndProcedure

#EndRegion
