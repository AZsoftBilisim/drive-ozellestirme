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
	If Not PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		Items.ImportFile3.ChoiceButton = False;
		SSLAvailable = False;
	Else
		SSLAvailable = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectFileToImportSuggested(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	If FileSystemExtensionAttached1 Then
		
		SelectingFile = New FileDialog(FileDialogMode.Open);
		SelectingFile.Multiselect = False;
		SelectingFile.Title = NStr("vi = 'Hãy chọn tệp kết nhập mức đo';
									|ru = 'Выберите файл импорта замеров';
									|en = 'Choose a sample file'; fa = 'Choose a sample file';
									|it = 'Seleziona il file di impostazione dei rilevamenti';
									|pl = 'Wybierz plik importu pomiarów';
									|tr = 'Ölçüm içe aktarım dosyasını seçin'");
		SelectingFile.Filter = "Files import2 measurings (*.zip)|*.zip";
		
		CallbackDescription = New CallbackDescription("FileDialogCompletion", ThisObject, Undefined);
		If SSLAvailable Then
			ModuleFileSystemClient = Eval("FileSystemClient");
			If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
				ModuleFileSystemClient.ShowSelectionDialog(CallbackDescription, SelectingFile);
			EndIf;
		Else
			SelectingFile.Show(CallbackDescription);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFile3StartChoice(Item, ChoiceData, StandardProcessing)
	
	If SSLAvailable Then
		CallbackDescription = New CallbackDescription("SelectFileToImportSuggested", ThisObject, Undefined);
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			ModuleFileSystemClient.Attach1CEnterpriseExtension(CallbackDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Import(Command)
	File = New File(ImportFile3);
	File.BeginCheckingExistence(New CallbackDescription("ImportAfterExistenceCheck", ThisObject));
EndProcedure

&AtClient
Procedure ImportAfterExistenceCheck(Exists, AdditionalParameters) Export
	If Not Exists Then 
		Message = New UserMessage();
    	Message.Text = NStr("vi = 'Hãy chọn tệp để kết nhập.';
							|ru = 'Выберите файл для импорта.';
							|en = 'Choose a sample file'; fa = 'Choose a sample file';
							|it = 'Seleziona il file per l''importazione.';
							|pl = 'Wybierz plik dla importu.';
							|tr = 'İçe aktarılacak dosyayı seçin.'");
    	Message.Field = "ImportFile3";
    	Message.Message();
		Return;
	EndIf;
	BinaryData = New BinaryData(ImportFile3);
    StorageAddress = PutToTempStorage(BinaryData, UUID);
    ExecuteImportAtServer1(ImportFile3, StorageAddress);	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure ExecuteImportAtServer1(FileName, StorageAddress)
	PerformanceMonitor.LoadPerformanceMonitorFile(FileName, StorageAddress);
EndProcedure                                                                     

&AtClient
Procedure FileDialogCompletion(SelectedFiles, AdditionalParameters) Export
    
    If SelectedFiles <> Undefined Then
		ImportFile3 = SelectedFiles[0];
	EndIf;
		
EndProcedure

#EndRegion