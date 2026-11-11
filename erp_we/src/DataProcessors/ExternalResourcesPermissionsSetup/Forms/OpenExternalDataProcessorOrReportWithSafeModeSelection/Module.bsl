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
	
	SafeMode = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportDataProcessorFile();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(NameOfDataProcessorFile) Or Not ValueIsFilled(DataProcessorFileAddress) Then
		Common.MessageToUser(NStr("vi = 'Hãy chỉ ra tệp báo cáo hoặc bộ xử lý ngoài.';
									|ru = 'Укажите файл внешнего отчета или обработки.';
									|en = 'Specify an external report file or a data processor file.'; fa = 'Specify an external report file or a data processor file.';
									|it = 'Indicare il file del report esterno o dell''elaborazione.';
									|pl = 'Wprowadź plik zewnętrznego raportu lub przetwarzania.';
									|tr = 'Harici rapor veya işlenecek dosyayı belirtin.'"),, 
			"NameOfDataProcessorFile");
		Cancel = True;
	Else
		FileProperties = CommonClientServer.ParseFullFileName(NameOfDataProcessorFile);
		If Lower(FileProperties.Extension) <> Lower(".epf") And Lower(FileProperties.Extension) <> Lower(".erf") Then
			Common.MessageToUser(NStr("vi = 'Tệp đã chọn không phải là báo cáo hoặc bộ xử lý ngoài.';
										|ru = 'Выбранный файл не является внешним отчетом или обработкой.';
										|en = 'The selected file is not an external report or data processor.'; fa = 'The selected file is not an external report or data processor.';
										|it = 'Il file selezione non è un report esterno o un''elaborazione.';
										|pl = 'Wybrany plik nie jest zewnętrznym raportem lub traktowaniem.';
										|tr = 'Seçilen dosya harici rapor veya işleme değildir.'"),,
				"NameOfDataProcessorFile");
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(SafeMode) Then
		Common.MessageToUser(NStr("vi = 'Hãy chỉ ra chế độ bảo mật để kết nối mô-đun ngoài.';
									|ru = 'Укажите безопасный режим для подключения внешнего модуля.';
									|en = 'Specify the safe mode for the external module connection.'; fa = 'Specify the safe mode for the external module connection.';
									|it = 'Indicare la modalità di sicurezza per la connessione al modulo esterno.';
									|pl = 'Wprowadź tryb awaryjny do podłączenia zewnętrznego modułu.';
									|tr = 'Harici modülün bağlanması için güvenli modu belirtin. '"),, 
			"SafeMode");
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameOfDataProcessorFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	ImportDataProcessorFile();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AttachAndOpen(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;	
	
	FileProperties = CommonClientServer.ParseFullFileName(NameOfDataProcessorFile);
	IsExternalDataProcessor = (Lower(FileProperties.Extension) = Lower(".epf"));
	
	ExternalObjectName = AttachOnServer(IsExternalDataProcessor);
	If IsExternalDataProcessor Then
		ExternalFormName = "ExternalDataProcessor." + ExternalObjectName + ".Form";
	Else
		ExternalFormName = "ExternalReport." + ExternalObjectName + ".Form";
	EndIf;
	
	OpenForm(ExternalFormName, , FormOwner);
	Close();
		
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportDataProcessorFile()
	
	Notification = New CallbackDescription("ImportDataProcessorFileCompletion", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	FileSystemClient.ImportFile_(Notification);

EndProcedure

&AtClient
Procedure ImportDataProcessorFileCompletion(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	NameOfDataProcessorFile = FileThatWasPut.Name;
	DataProcessorFileAddress = FileThatWasPut.Location;
	
	FileProperties = CommonClientServer.ParseFullFileName(NameOfDataProcessorFile);
	If Lower(FileProperties.Extension) <> Lower(".epf") And Lower(FileProperties.Extension) <> Lower(".erf") Then
		ShowMessageBox(, NStr("vi = 'Tệp đã chọn không phải là báo cáo hoặc bộ xử lý ngoài.';
								|ru = 'Выбранный файл не является внешним отчетом или обработкой.';
								|en = 'The selected file is not an external report or data processor.'; fa = 'The selected file is not an external report or data processor.';
								|it = 'Il file selezione non è un report esterno o un''elaborazione.';
								|pl = 'Wybrany plik nie jest zewnętrznym raportem lub traktowaniem.';
								|tr = 'Seçilen dosya harici rapor veya işleme değildir.'"));
	EndIf;
	
EndProcedure

&AtServer
Function AttachOnServer(IsExternalDataProcessor)
	
	VerifyAccessRights("Administration", Metadata);
	
	If IsExternalDataProcessor Then
		Manager = ExternalDataProcessors;
	Else
		Manager = ExternalReports;
	EndIf;
	
	Return Manager.Connect(DataProcessorFileAddress,, SafeMode); // ACC:552; ACC:553 Secure connection.
	
EndFunction

#EndRegion
