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
	
	// First of all, checking the access rights.
	If Not AccessRight("Administration", Metadata) Then
		Raise NStr("vi = 'Chỉ có người quản trị có thể sử dụng bộ xử lý trong chế độ trực tác.';
					|ru = 'Использование обработки в интерактивном режиме доступно только администратору.';
					|en = 'Only administrators can run the data processor manually.'; fa = 'Only administrators can run the data processor manually.';
					|it = 'L''utilizzo dell''elaborazione in modalità interattiva è disponibile solo per l''amministratore.';
					|pl = 'Używanie przetwarzania w trybie interaktywnym jest dostępne tylko dla administratora.';
					|tr = 'Etkileşimli modda veri işlemcisi kullanımı sadece yönetici için kullanılabilir.'");
	EndIf;
	
	CheckPlatformVersionAndCompatibilityMode();
	
	Object.IsInteractiveMode = True;
	Object.SafeMode = True;
	Object.ExchangeProtocolFileEncoding = "TextEncoding.UTF8";
	
	FormCaption = NStr("vi = 'Trao đổi dữ liệu đa năng theo định dạng XML (%1)';
						|ru = 'Универсальный обмен данными в формате XML (%1)';
						|en = 'Conversion Rule Data Exchange in XML format (%1)'; fa = 'Conversion Rule Data Exchange in XML format (%1)';
						|it = 'Универсальный обмен данными в формате XML (%1)';
						|pl = 'Conversion Rule Data Exchange in XML format (%1)';
						|tr = 'XML (%1 formatında kapsamlı veri alışverişi'");
	FormCaption = StrTemplate(FormCaption, VersionOfObjectAtServer());
	
	Title = FormCaption;
	
	FillTypeAvailableToDeleteList();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.RulesFileName.ChoiceList.LoadValues(ExchangeRules.UnloadValues());
	Items.ExchangeFileName.ChoiceList.LoadValues(DataImportFromFile.UnloadValues());
	Items.DataFileName.ChoiceList.LoadValues(DataExportToFile.UnloadValues());
	
	OnPeriodChange();
	
	OnChangeChangesRegistrationDeletionType();
	
	ClearDataImportFileData();
	
	DirectExport = ?(Object.DirectReadingInDestinationIB, 1, 0);
	
	SavedImportMode = (Object.ExchangeMode = "Load");
	
	If SavedImportMode Then
		
		// Set the right page.
		Items.FormMainPanel.CurrentPage = Items.FormMainPanel.ChildItems.Load;
		
	EndIf;
	
	ProcessTransactionManagementItemsEnabled();
	
	ExpandTreeRows(DataToDelete, Items.DataToDelete, "Check");
	
	ArchiveFileOnValueChange();
	DirectExportOnValueChange();
	
	#If WebClient Then
		Items.ExportDebugPages.CurrentPage = Items.ExportDebugPages.ChildItems.WebClientExportGroup;
		Items.ImportDebugPages.CurrentPage = Items.ImportDebugPages.ChildItems.WebClientImportGroup;
		Object.HandlersDebugModeFlag = False;
		
		IsClient = True;
		Items.ProcessingMode.Enabled = False;
	#EndIf
	
	ChangeProcessingMode(IsClient);
	
	SetDebugCommandsEnabled();
	
	If SavedImportMode
		And Object.AutomaticDataImportSetup <> 0 Then
		
		If Object.AutomaticDataImportSetup = 1 Then
			
			CallbackDescription = New CallbackDescription("OnOpenCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, NStr("vi = 'Thực hiện kết nhập dữ liệu từ tệp trao đổi?';
													|ru = 'Выполнить загрузку данных из файла обмена?';
													|en = 'Do you want to import data from the exchange file?'; fa = 'Do you want to import data from the exchange file?';
													|it = 'Effettuare il download dei dati dal file di scambio?';
													|pl = 'Wykonać pobieranie danych z pliku wymiany?';
													|tr = 'Veri alışveriş dosyasından içe aktarılsın mı?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			
		Else
			
			OnOpenCompletion(DialogReturnCode.Yes, Undefined);
			
		EndIf;
		
	EndIf;
	
	If Not IsWindowsClient() Then
		Items.OSGroup.CurrentPage = Items.OSGroup.ChildItems.LinuxGroup;
	EndIf;
	
	#If WebClient Then
		FileSystemExtensionAttachment(True);
	#EndIf	
	
EndProcedure

&AtClient
Procedure OnOpenCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ExecuteImportFromForm();
		ExportPeriodPresentation = PeriodPresentation(Object.StartDate, Object.EndDate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ArchiveFileOnChange(Item)
	
	ArchiveFileOnValueChange();
	
EndProcedure

&AtClient
Procedure ExchangeRulesFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, ThisObject, "RulesFileName", True, , False, True);
	
EndProcedure

&AtClient
Procedure ExchangeRulesFileNameOpen(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DirectExportOnChange(Item)
	
	DirectExportOnValueChange();
	
EndProcedure

&AtClient
Procedure FormMainPanelOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "Upload0" Then
		
		Object.ExchangeMode = "Upload0";
		
	ElsIf CurrentPage.Name = "Load" Then
		
		Object.ExchangeMode = "Load";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FlagDebugModeOnChange(Item)
	
	If Object.FlagDebugMode Then
		
		Object.UseTransactions = False;
				
	EndIf;
	
	ProcessTransactionManagementItemsEnabled();

EndProcedure

&AtClient
Procedure ProcessedObjectsCountToUpdateStatusOnChange(Item)
	
	If Object.ProcessedObjectsCountToUpdateStatus = 0 Then
		Object.ProcessedObjectsCountToUpdateStatus = 100;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, ThisObject, "ExchangeFileName", False, , Object.ArchiveFile);
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, Object, "ExchangeProtocolFileName", False, "txt", False);
	
EndProcedure

&AtClient
Procedure ImportExchangeLogFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, Object, "ImportExchangeLogFileName", False, "txt", False);
	
EndProcedure

&AtClient
Procedure DataFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, ThisObject, "DataFileName", False, , Object.ArchiveFile);
	
EndProcedure

&AtClient
Procedure InfobaseToConnectDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	
	FileDialog.Title = NStr("vi = 'Hãy chọn thư mục cơ sở thông tin';
							|ru = 'Выберите каталог информационной базы';
							|en = 'Select an infobase directory'; fa = 'Select an infobase directory';
							|it = 'Selezionare la directory del database informatico';
							|pl = 'Wybierz katalog bazy informacyjnej';
							|tr = 'Bir Infobase yedekleme dizini seçin'");
	FileDialog.Directory = Object.InfobaseToConnectDirectory;
	FileDialog.CheckFileExistence = True;
	
	Notification = New CallbackDescription("ProcessSelectionInfobaseDirectoryToAdd", ThisObject);
	FileDialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure ProcessSelectionInfobaseDirectoryToAdd(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.InfobaseToConnectDirectory = SelectedFiles[0];
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ImportExchangeLogFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseToConnectDirectoryOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseToConnectWindowsAuthenticationOnChange(Item)
	
	Items.InfobaseToConnectUser.Enabled = Not Object.InfobaseToConnectWindowsAuthentication;
	Items.InfobaseToConnectPassword.Enabled = Not Object.InfobaseToConnectWindowsAuthentication;
	
EndProcedure

&AtClient
Procedure RulesFileNameOnChange(Item)
	
	File = New File(RulesFileName);
	
	Notification = New CallbackDescription("AfterExistenceCheckRulesFileName", ThisObject);
	File.BeginCheckingExistence(Notification);
	
EndProcedure

&AtClient
Procedure AfterExistenceCheckRulesFileName(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		MessageToUser(NStr("vi = 'Không tìm thấy tệp quy tắc trao đổi';
							|ru = 'Не найден файл правил обмена';
							|en = 'Exchange rules file not found'; fa = 'Exchange rules file not found';
							|it = 'Nessun file delle regole di scambio specificato';
							|pl = 'Nie znaleziono pliku zasad wymiany';
							|tr = 'Değişim kuralları dosyası bulunamadı'"), "RulesFileName");
		SetImportRuleFlag(False);
		Return;
	EndIf;
	
	If RuleAndExchangeFileNamesMatch() Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("RulesFileNameOnChangeCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, NStr("vi = 'Kết nhập quy tắc trao đổi dữ liệu?';
											|ru = 'Загрузить правила обмена данными?';
											|en = 'Do you want to import data exchange rules?'; fa = 'Do you want to import data exchange rules?';
											|it = 'Effettuare il download delle regole di scambio dati?';
											|pl = 'Pobrać reguły wymiany danych?';
											|tr = 'Veri değişimi kuralları içe aktarılsın mı?'"), QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure RulesFileNameOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ExecuteImportExchangeRules();
		
	Else
		
		SetImportRuleFlag(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExchangeFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExchangeFileNameOnChange(Item)
	
	ClearDataImportFileData();
	
EndProcedure

&AtClient
Procedure UseTransactionsOnChange(Item)
	
	ProcessTransactionManagementItemsEnabled();
	
EndProcedure

&AtClient
Procedure ImportHandlersDebugModeFlagOnChange(Item)
	
	SetDebugCommandsEnabled();
	
EndProcedure

&AtClient
Procedure ExportHandlerDebugModeFlagOnChange(Item)
	
	SetDebugCommandsEnabled();
	
EndProcedure

&AtClient
Procedure DataFileNameOpening(Item, StandardProcessing)
	
	OpenInApplication(Item.EditText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DataFileNameOnChange(Item)
	
	If EmptyAttributeValue(DataFileName, "DataFileName", Items.DataFileName.Title)
		Or RuleAndExchangeFileNamesMatch() Then
		Return;
	EndIf;
	
	Object.ExchangeFileName = DataFileName;
	
	File = New File(Object.ExchangeFileName);
	Object.ArchiveFile = (Upper(File.Extension) = Upper(".zip"));
	
EndProcedure

&AtClient
Procedure InfobaseToConnectTypeOnChange(Item)
	
	InfobaseTypeForConnectionOnValueChange();
	
EndProcedure

&AtClient
Procedure InfobaseToConnectPlatformVersionOnChange(Item)
	
	If IsBlankString(Object.InfobaseToConnectPlatformVersion) Then
		
		Object.InfobaseToConnectPlatformVersion = "V8";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangesRegistrationDeletionTypeForExportedExchangeNodesOnChange(Item)
	
	OnChangeChangesRegistrationDeletionType();
	
EndProcedure

&AtClient
Procedure ExportPeriodOnChange(Item)
	
	OnPeriodChange();
	
EndProcedure

&AtClient
Procedure DeletionPeriodOnChange(Item)
	
	OnPeriodChange();
	
EndProcedure

&AtClient
Procedure SafeImportOnChange(Item)
	
	ChangeSafeImportMode();
	
EndProcedure

&AtClient
Procedure NameOfImportRulesFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, ThisObject, "NameOfImportRulesFile", True, , False, True);
	
EndProcedure

&AtClient
Procedure NameOfImportRulesFileOnChange(Item)
	
	PutImportRulesFileInStorage();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExportRulesTable

&AtClient
Procedure ExportRulesTableBeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem.Name = "ExchangeNodeRef" Then
		
		If Item.CurrentData.IsFolder Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportRulesTableOnChange(Item)
	
	If Item.CurrentItem.Name = "DER" Then
		
		CurRow = Item.CurrentData;
		
		If CurRow.Enable = 2 Then
			CurRow.Enable = 0;
		EndIf;
		
		SetSubordinateMarks(CurRow, "Enable");
		SetParentMarks(CurRow, "Enable");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDataToDelete

&AtClient
Procedure DataToDeleteOnChange(Item)
	
	CurRow = Item.CurrentData;
	
	SetSubordinateMarks(CurRow, "Check");
	SetParentMarks(CurRow, "Check");

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConnectionTest(Command)
	
	EstablishConnectionWithDestinationIBAtServer();
	
EndProcedure

&AtClient
Procedure GetExchangeFileInfo(Command)
	
	FileAddress = "";
	
	If IsClient Then
		
		CallbackDescription = New CallbackDescription("GetExchangeFileInfoCompletion", ThisObject);
 
		BeginPutFileToServer(CallbackDescription,,, FileAddress, 
			PreparedParametersOfFilePlacementDialog(), UUID);	
		
	Else
		
		AdditionalParameters = AdditionalNotificationProcessingParameters();
		
		AdditionalParameters.AddressOfFileOnServer = FileAddress;
		
		GetExchangeFileInfoCompletion(True, AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeletionSelectAll(Command)
	
	For Each String In DataToDelete.GetItems() Do
		
		String.Check = 1;
		SetSubordinateMarks(String, "Check");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeletionClearAll(Command)
	
	For Each String In DataToDelete.GetItems() Do
		String.Check = 0;
		SetSubordinateMarks(String, "Check");
	EndDo;
	
EndProcedure

&AtClient
Procedure DeletionDelete(Command)
	
	CallbackDescription = New CallbackDescription("DeletionDeleteCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, NStr("vi = 'Xóa dữ liệu đã chọn trong cơ sở thông tin?';
											|ru = 'Удалить выбранные данные в информационной базе?';
											|en = 'Do you want to delete the selected data from the infobase?'; fa = 'Do you want to delete the selected data from the infobase?';
											|it = 'Cancellare i dati selezionati nel database informatico?';
											|pl = 'Usunąć wybrane dane w bazie informacyjnej?';
											|tr = 'Infobase''de seçilen veriler silinsin mi?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure DeletionDeleteCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		DeleteAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportSelectAll(Command)
	
	For Each String In Object.ExportRulesTable.GetItems() Do
		String.Enable = 1;
		SetSubordinateMarks(String, "Enable");
	EndDo;
	
EndProcedure

&AtClient
Procedure ExportClearAll(Command)
	
	For Each String In Object.ExportRulesTable.GetItems() Do
		String.Enable = 0;
		SetSubordinateMarks(String, "Enable");
	EndDo;
	
EndProcedure

&AtClient
Procedure ExportClearExchangeNodes(Command)
	
	FillExchangeNodeInTreeRowsAtServer(Undefined);
	
EndProcedure

&AtClient
Procedure ExportMarkExchangeNode(Command)
	
	If Items.ExportRulesTable.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillExchangeNodeInTreeRowsAtServer(Items.ExportRulesTable.CurrentData.ExchangeNodeRef);
	
EndProcedure

&AtClient
Procedure SaveParameters(Command)
	
	SaveParametersAtServer();
	
EndProcedure

&AtClient
Procedure RestoreParameters(Command)
	
	RestoreParametersAtServer();
	
EndProcedure

&AtClient
Procedure ExportDebugSetup(Command)
	
	Object.ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName, RuleFileAddressInStorage);
	
	OpenHandlerDebugSetupForm(True);
	
EndProcedure

&AtClient
Procedure AtClient(Command)
	
	If Not IsClient Then
		
		IsClient = True;
		
		ChangeProcessingMode(IsClient);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AtServer(Command)
	
	If IsClient Then
		
		IsClient = False;
		
		ChangeProcessingMode(IsClient);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDebugSetup(Command)
	
	ExchangeFileAddressInStorage = "";
	
	If IsClient Then
		
		CallbackDescription = New CallbackDescription("ImportDebugSetupCompletion", ThisObject);

		BeginPutFileToServer(CallbackDescription,,, ExchangeFileAddressInStorage, 
			PreparedParametersOfFilePlacementDialog(), UUID);
		
	Else
		
		If EmptyAttributeValue(ExchangeFileName, "ExchangeFileName", Items.ExchangeFileName.Title) Then
			Return;
		EndIf;
		
		AdditionalParameters = AdditionalNotificationProcessingParameters();
		
		AdditionalParameters.AddressOfFileOnServer = RuleFileAddressInStorage;
		
		ImportDebugSetupCompletion(True, AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteExport(Command)
	
	ExecuteExportFromForm();
	
EndProcedure

&AtClient
Procedure ExecuteImport(Command)
	
	ExecuteImportFromForm();
	
EndProcedure

&AtClient
Procedure ReadExchangeRules(Command)
	
	If Not IsWindowsClient() And DirectExport = 1 Then
		ShowMessageBox(,NStr("vi = 'Chỉ hỗ trợ kết nối trực tiếp đến cơ sở thông tin trong Client chạy hệ điều hành Windows.';
							|ru = 'Прямое подключение к информационной базе поддерживается только в клиенте под управлением ОС Windows.';
							|en = 'Only Windows clients support direct infobase connections.'; fa = 'Only Windows clients support direct infobase connections.';
							|it = 'L''accesso diretto al database informatico è consentito solo nel client del sistema operativo Windows.';
							|pl = 'Bezpośrednie podłączenie do bazy informacyjnej jest obsługiwane tylko w kliencie w systemie operacyjnym Windows.';
							|tr = 'Infobase''e doğrudan bağlantı yalnızca Windows tabanlı bir istemcide desteklenir.'"));
		Return;
	EndIf;
	
	If IsClient Then
		
		If Not IsBlankString(RuleFileAddressInStorage)
			And IsTempStorageURL(RuleFileAddressInStorage) Then
			DeleteFromTempStorage(RuleFileAddressInStorage);
			RuleFileAddressInStorage = "";
		EndIf;
		
		CallbackDescription = New CallbackDescription("ReadExchangeRulesCompletion", ThisObject); 
				
		BeginPutFileToServer(CallbackDescription,,, RuleFileAddressInStorage, 
			PreparedParametersOfFilePlacementDialog(), UUID);
		
	Else
		
		RuleFileAddressInStorage = "";
		If EmptyAttributeValue(RulesFileName, "RulesFileName", Items.RulesFileName.Title) Then
			Return;
		EndIf;
		
		AdditionalParameters = AdditionalNotificationProcessingParameters();
		
		AdditionalParameters.AddressOfFileOnServer = RuleFileAddressInStorage;
		
		ReadExchangeRulesCompletion(True, AdditionalParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Opens an exchange file in an external application.
//
// Parameters:
//  
// 
&AtClient
Procedure OpenInApplication(FileName, StandardProcessing = False)
	
	StandardProcessing = False;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("FileName", FileName);
	AdditionalParameters.Insert("CallbackDescription", New CallbackDescription);
	
	File = New File(FileName);
	
	CallbackDescription = New CallbackDescription("AfterDetermineFileExistence", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure AfterDetermineFileExistence(Exists, AdditionalParameters) Export
	
	If Exists Then
		BeginRunningApplication(AdditionalParameters.CallbackDescription, AdditionalParameters.FileName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearDataImportFileData()
	
	Object.ExchangeRulesVersion = "";
	Object.DataExportDate = "";
	ExportPeriodPresentation = "";
	
EndProcedure

&AtClient
Procedure ProcessTransactionManagementItemsEnabled()
	
	Items.UseTransactions.Enabled = Not Object.FlagDebugMode;
	
	Items.ObjectCountPerTransaction.Enabled = Object.UseTransactions;
	
EndProcedure

&AtClient
Procedure ArchiveFileOnValueChange()
	
	If Object.ArchiveFile Then
		DataFileName = StrReplace(DataFileName, ".xml", ".zip");
	Else
		DataFileName = StrReplace(DataFileName, ".zip", ".xml");
	EndIf;
	
	Items.ExchangeFileCompressionPassword.Enabled = Object.ArchiveFile;
	
EndProcedure

&AtServer
Procedure FillExchangeNodeInTreeRows(Tree, ExchangeNode)
	
	For Each String In Tree Do
		
		If String.IsFolder Then
			
			FillExchangeNodeInTreeRows(String.GetItems(), ExchangeNode);
			
		Else
			
			String.ExchangeNodeRef = ExchangeNode;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function RuleAndExchangeFileNamesMatch()
	
	If Upper(TrimAll(RulesFileName)) = Upper(TrimAll(DataFileName)) Then
		
		MessageToUser(NStr("vi = 'Tệp quy tắc trao đổi không thể trùng với tệp dữ liệu.
		|Hãy chọn tệp khác để kết xuất dữ liệu.';
		|ru = 'Файл правил обмена не может совпадать с файлом данных.
		|Выберите другой файл для выгрузки данных.';
		|en = 'An exchange rules file cannot be the same as a data file.
		|Select another file.'; fa = 'An exchange rules file cannot be the same as a data file.
		|Select another file.';
		|it = 'Il file delle regole di scambio non può corrispondere al file di dati.
		|Selezionare un altro file per scaricare i dati.';
		|pl = 'Plik reguł wymiany nie może zbiegać s plikiem danych.
		|Wybierz inny plik do eksportowania danych.';
		|tr = 'Alışveriş kuralları dosyası veri dosyasıyla eşleşemez. 
		|Veri aktarımı için diğer dosyayı seçin.'"));
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Fills a value tree with metadata objects available for deletion.
&AtServer
Procedure FillTypeAvailableToDeleteList()
	
	DataTree = FormAttributeToValue("DataToDelete");
	
	DataTree.Rows.Clear();
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("vi = 'Danh mục';
								|ru = 'Справочники';
								|en = 'Catalogs'; fa = 'فهرست‌ها';
								|it = 'Directory';
								|pl = 'Catalogs';
								|tr = 'Kataloglar'");
	
	For Each MetadataObjectsList In Metadata.Catalogs Do
		
		If Not AccessRight("Delete", MetadataObjectsList) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObjectsList.Name;
		MDRow.Metadata = "CatalogRef." + MetadataObjectsList.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("vi = 'Hệ thống dạng đặc tính';
								|ru = 'Планы видов характеристик';
								|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
								|it = 'Piani dei tipi di caratteristiche';
								|pl = 'Plany rodzajów charakterystyk';
								|tr = 'Özellik türü listeleri'");
	
	For Each MetadataObjectsList In Metadata.ChartsOfCharacteristicTypes Do
		
		If Not AccessRight("Delete", MetadataObjectsList) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObjectsList.Name;
		MDRow.Metadata = "ChartOfCharacteristicTypesRef." + MetadataObjectsList.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = NStr("vi = 'Chứng từ';
								|ru = 'Документы';
								|en = 'Documents'; fa = 'اسناد';
								|it = 'Documenti';
								|pl = 'Documents';
								|tr = 'Belgeler'");
	
	For Each MetadataObjectsList In Metadata.Documents Do
		
		If Not AccessRight("Delete", MetadataObjectsList) Then
			Continue;
		EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObjectsList.Name;
		MDRow.Metadata = "DocumentRef." + MetadataObjectsList.Name;
		
	EndDo;
	
	TreeRow = DataTree.Rows.Add();
	TreeRow.Presentation = "InformationRegisters";
	
	For Each MetadataObjectsList In Metadata.InformationRegisters Do
		
		If Not AccessRight("Update", MetadataObjectsList) Then
			Continue;
		EndIf;
		
		Subordinate = (MetadataObjectsList.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		If Subordinate Then Continue EndIf;
		
		MDRow = TreeRow.Rows.Add();
		MDRow.Presentation = MetadataObjectsList.Name;
		MDRow.Metadata = "InformationRegisterRecord." + MetadataObjectsList.Name;
		
	EndDo;
	
	ValueToFormAttribute(DataTree, "DataToDelete");
	
EndProcedure

&AtClient
Procedure ExecuteImportExchangeRules(RuleFileAddressInStorage = "", FileNameForExtension = "")
	
	Object.ErrorFlag = False;
	
	ImportExchangeRulesAndParametersAtServer(RuleFileAddressInStorage, FileNameForExtension);
	
	If Object.ErrorFlag Then
		
		SetImportRuleFlag(False);
		
	Else
		
		SetImportRuleFlag(True);
		ExpandTreeRows(Object.ExportRulesTable, Items.ExportRulesTable, "Enable");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandTreeRows(DataTree, PresentationOnForm, CheckBoxName)
	
	TreeRows = DataTree.GetItems();
	
	For Each String In TreeRows Do
		
		RowID=String.GetID();
		PresentationOnForm.Expand(RowID, False);
		EnableParentIfSubordinateItemsEnabled(String, CheckBoxName);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure EnableParentIfSubordinateItemsEnabled(TreeRow, CheckBoxName)
	
	Enable = TreeRow[CheckBoxName];
	
	For Each SubordinateRow In TreeRow.GetItems() Do
		
		If SubordinateRow[CheckBoxName] = 1 Then
			
			Enable = 1;
			
		EndIf;
		
		If SubordinateRow.GetItems().Count() > 0 Then
			
			EnableParentIfSubordinateItemsEnabled(SubordinateRow, CheckBoxName);
			
		EndIf;
		
	EndDo;
	
	TreeRow[CheckBoxName] = Enable;
	
EndProcedure

&AtClient
Procedure OnPeriodChange()
	
	Object.StartDate = ExportPeriod.StartDate;
	Object.EndDate = ExportPeriod.EndDate;
	
EndProcedure

&AtServer
Procedure ImportExchangeRulesAndParametersAtServer(RuleFileAddressInStorage, FileNameForExtension)
	
	ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName ,RuleFileAddressInStorage, FileNameForExtension);
	
	If ExchangeRulesFileName = Undefined Then
		
		Return;
		
	Else
		
		Object.ExchangeRulesFileName = ExchangeRulesFileName;
		
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	ObjectForServer.ExportRulesTable = FormAttributeToValue("Object.ExportRulesTable");
	ObjectForServer.ParametersSetupTable = FormAttributeToValue("Object.ParametersSetupTable");
	
	ObjectForServer.ImportExchangeRules();
	ObjectForServer.InitializeInitialParameterValues();
	ObjectForServer.Parameters.Clear();
	Object.ErrorFlag = ObjectForServer.ErrorFlag;
	
	If IsClient Then
		
		DeleteFiles(Object.ExchangeRulesFileName);
		
	EndIf;
	
	ValueToFormAttribute(ObjectForServer.ExportRulesTable, "Object.ExportRulesTable");
	ValueToFormAttribute(ObjectForServer.ParametersSetupTable, "Object.ParametersSetupTable");
	
EndProcedure

&AtClient
Procedure ImportDebugSetupCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Address = "";
	
	If TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("AddressOfFileOnServer") Then
		
		Address = AdditionalParameters.AddressOfFileOnServer;
		
	Else
		
		Address = Result.Address;
		
	EndIf;
		
	Object.ExchangeFileName = FileNameAtServerOrClient(ExchangeFileName ,Address);
	
	OpenHandlerDebugSetupForm(False);
	
EndProcedure

&AtClient
Procedure ReadExchangeRulesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	NameOfSelectedFile = "";
	
	If TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("AddressOfFileOnServer") Then
		
		RuleFileAddressInStorage = AdditionalParameters.AddressOfFileOnServer;
		
	Else
		
		RuleFileAddressInStorage = Result.Address;
		NameOfSelectedFile = Result.FileRef.Name;
		
	EndIf;
	
			
	ExecuteImportExchangeRules(RuleFileAddressInStorage, NameOfSelectedFile);
	
	If Object.ErrorFlag Then
		
		SetImportRuleFlag(False);
		
	Else
		
		SetImportRuleFlag(True);
		
	EndIf;
			
EndProcedure

// Opens file selection dialog.
//
&AtClient
Procedure SelectingFile(Item, StorageObject, PropertyName, CheckForExistence, Val DefaultExtension = "xml",
	ArchiveDataFile = True, RuleFileSelection = False)
	
	FileDialog = New FileDialog(FileDialogMode.Open);

	If DefaultExtension = "txt" Then
		
		FileDialog.Filter = "File protocol_ exchange (*.txt)|*.txt";
		FileDialog.DefaultExt = "txt";
		
	ElsIf Object.ExchangeMode = "Upload0" Then
		
		If ArchiveDataFile Then
			
			FileDialog.Filter = "Archived file data_ (*.zip)|*.zip";
			FileDialog.DefaultExt = "zip";
			
		ElsIf RuleFileSelection Then
			
			FileDialog.Filter = "File data_ (*.xml)|*.xml|Archived file data_ (*.zip)|*.zip";
			FileDialog.DefaultExt = "xml";
			
		Else
			
			FileDialog.Filter = "File data_ (*.xml)|*.xml";
			FileDialog.DefaultExt = "xml";
			
		EndIf; 
		
	Else
		If RuleFileSelection Then
			FileDialog.Filter = "File data_ (*.xml)|*.xml";
			FileDialog.DefaultExt = "xml";
		Else
			FileDialog.Filter = "File data_ (*.xml)|*.xml|Archived file data_ (*.zip)|*.zip";
			FileDialog.DefaultExt = "xml";
		EndIf;
	EndIf;
	
	FileDialog.Title = NStr("vi = 'Hãy chọn tệp';
							|ru = 'Выберите файл';
							|en = 'Select file'; fa = 'انتخاب فایل';
							|it = 'Selezionare un file';
							|pl = 'Wybierz plik';
							|tr = 'Dosya seç'");
	FileDialog.Preview = False;
	FileDialog.FilterIndex = 0;
	FileDialog.FullFileName = Item.EditText;
	FileDialog.CheckFileExistence = CheckForExistence;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StorageObject", StorageObject);
	AdditionalParameters.Insert("PropertyName",    PropertyName);
	AdditionalParameters.Insert("Item",        Item);
	
	Notification = New CallbackDescription("FileSelectionDialogChoiceProcessing", ThisObject, AdditionalParameters);
	FileDialog.Show(Notification);
	
EndProcedure

// Parameters:
//   SelectedFiles - Array of String - a file choice result.
//   AdditionalParameters - Structure - arbitrary additional parameters:
//     * StorageObject - Structure
//                      - ClientApplicationForm - a destination for the property storage.
//     * PropertyName - String - a name of the storage object property.
//     * Item - FormField - a source of the file choice event.
//
&AtClient
Procedure FileSelectionDialogChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.StorageObject[AdditionalParameters.PropertyName] = SelectedFiles[0];
	
	Item = AdditionalParameters.Item;
	
	If Item = Items.RulesFileName Then
		RulesFileNameOnChange(Item);
	ElsIf Item = Items.ExchangeFileName Then
		ExchangeFileNameOnChange(Item);
	ElsIf Item = Items.DataFileName Then
		DataFileNameOnChange(Item);
	ElsIf Item = Items.NameOfImportRulesFile Then
		NameOfImportRulesFileOnChange(Item);
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishConnectionWithDestinationIBAtServer()
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ConnectionResult = ObjectForServer.EstablishConnectionWithDestinationIB();
	
	If ConnectionResult <> Undefined Then
		
		MessageToUser(NStr("vi = 'Đã kết nối thành công.';
							|ru = 'Подключение успешно установлено.';
							|en = 'Connection established.'; fa = 'Connection established.';
							|it = 'Connessione stabilita con successo.';
							|pl = 'Połączenie zostało pomyślnie nawiązane.';
							|tr = 'Bağlantı başarıyla kuruldu.'"));
		
	EndIf;
	
EndProcedure

// Sets mark value in subordinate tree rows
// according to the mark value in the current row.
//
// Parameters:
//  CurRow      - A value tree row.
// 
&AtClient
Procedure SetSubordinateMarks(CurRow, CheckBoxName)
	
	SubordinateItems = CurRow.GetItems();
	
	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		String[CheckBoxName] = CurRow[CheckBoxName];
		
		SetSubordinateMarks(String, CheckBoxName);
		
	EndDo;
		
EndProcedure

// Sets mark values in parent tree rows
// according to the mark value in the current row.
//
// Parameters:
//  CurRow      - A value tree row.
// 
&AtClient
Procedure SetParentMarks(CurRow, CheckBoxName)
	
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf; 
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	For Each String In Parent.GetItems() Do
		If String[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf String[CheckBoxName] = 1
			Or String[CheckBoxName] = 2 Then
			EnabledItemsFound  = True;
		EndIf; 
		If EnabledItemsFound And DisabledItemsFound Then
			Break;
		EndIf; 
	EndDo;
	
	If EnabledItemsFound And DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound And (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) And DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) And (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf; 
	
EndProcedure

&AtServer
Procedure OpenImportFileAtServer(FileAddress)
	
	If IsClient Then
		
		BinaryData = GetFromTempStorage(FileAddress); // BinaryData
		Object.ExchangeFileName = GetTempFileName(".xml"); // ACC:441 - Deletion within "ExecuteExportAtServer".
		BinaryData.Write(Object.ExchangeFileName);
		
	Else
		
		FileOnServer = New File(ExchangeFileName);
		
		If Not FileOnServer.Exists() Then
			
			MessageToUser(NStr("vi = 'Không tìm thấy tệp trao đổi trên máy chủ.';
								|ru = 'Не найден файл обмена на сервере.';
								|en = 'Exchange file not found on the server.'; fa = 'Exchange file not found on the server.';
								|it = 'Nessun file di scambio trovato sul server.';
								|pl = 'Nie znaleziono pliku wymiany na serwerze.';
								|tr = 'Alışveriş dosyası sunucuda bulunamadı.'"), "ExchangeFileName");
			Return;
			
		EndIf;
		
		Object.ExchangeFileName = ExchangeFileName;
		
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	
	ObjectForServer.OpenImportFile(True);
	
	Object.StartDate = ObjectForServer.StartDate;
	Object.EndDate = ObjectForServer.EndDate;
	Object.DataExportDate = ObjectForServer.DataExportDate;
	Object.ExchangeRulesVersion = ObjectForServer.ExchangeRulesVersion;
	Object.Comment = ObjectForServer.Comment;
	
EndProcedure

// Deletes marked metadata tree rows.
//
&AtServer
Procedure DeleteAtServer()
	
	ObjectForServer = FormAttributeToValue("Object");
	DataBeingDeletedTree = FormAttributeToValue("DataToDelete");
	
	ObjectForServer.InitManagersAndMessages();
	
	For Each TreeRow In DataBeingDeletedTree.Rows Do
		
		For Each MDRow In TreeRow.Rows Do
			
			If Not MDRow.Check Then
				Continue;
			EndIf;
			
			TypeAsString = MDRow.Metadata;
			ObjectForServer.DeleteObjectsOfType(TypeAsString);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Sets an exchange node at tree rows.
//
&AtServer
Procedure FillExchangeNodeInTreeRowsAtServer(ExchangeNode)
	
	FillExchangeNodeInTreeRows(Object.ExportRulesTable.GetItems(), ExchangeNode);
	
EndProcedure

// Saves parameter values.
//
&AtServer
Procedure SaveParametersAtServer()
	
	ParametersTable = FormAttributeToValue("Object.ParametersSetupTable");
	
	ParametersToSave1 = New Map;
	
	For Each TableRow In ParametersTable Do
		ParametersToSave1.Insert(TableRow.Description, TableRow.Value);
	EndDo;
	
	SystemSettingsStorage.Save("UniversalDataExchangeXML", "Parameters", ParametersToSave1);
	
EndProcedure

// Restores parameter values.
//
&AtServer
Procedure RestoreParametersAtServer()
	
	ParametersTable = FormAttributeToValue("Object.ParametersSetupTable");
	RestoredParameters = SystemSettingsStorage.Load("UniversalDataExchangeXML", "Parameters");
	
	If TypeOf(RestoredParameters) <> Type("Map") Then
		Return;
	EndIf;
	
	If RestoredParameters.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Couples In RestoredParameters Do
		
		ParameterName = Couples.Key;
		
		TableRow = ParametersTable.Find(Couples.Key, "Description");
		
		If TableRow <> Undefined Then
			
			TableRow.Value = Couples.Value;
			
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(ParametersTable, "Object.ParametersSetupTable");
	
EndProcedure

// Performs interactive data export.
//
&AtClient
Procedure ExecuteImportFromForm()
	
	FileAddress = "";
	
	AddRowToChoiceList(Items.ExchangeFileName.ChoiceList, ExchangeFileName, DataImportFromFile);
	
	If IsClient Then
		
		CallbackDescription = New CallbackDescription("ExecuteImportFromFormCompletion", ThisObject);

		BeginPutFileToServer(CallbackDescription,,, FileAddress, 
			PreparedParametersOfFilePlacementDialog(), UUID);
		
	Else
		
		If EmptyAttributeValue(ExchangeFileName, "ExchangeFileName", Items.ExchangeFileName.Title) Then
			Return;
		EndIf;
		
		AdditionalParameters = AdditionalNotificationProcessingParameters();
		
		AdditionalParameters.AddressOfFileOnServer = FileAddress;
		
		ExecuteImportFromFormCompletion(True, AdditionalParameters);
						
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteImportFromFormCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	NameOfSelectedFile= "";
	Address = "";
	
	If TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("AddressOfFileOnServer") Then
		
		Address = AdditionalParameters.AddressOfFileOnServer;
		
	Else
		
		Address = Result.Address;
		NameOfSelectedFile = Result.FileRef.Name;
		
	EndIf;
		
	ExecuteImportAtServer(Address, NameOfSelectedFile);
	
	OpenExchangeProtocolDataIfNecessary();
	
EndProcedure

&AtClient
Procedure GetExchangeFileInfoCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Address  = "";
	
	If TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("AddressOfFileOnServer") Then
		
		Address = AdditionalParameters.AddressOfFileOnServer;
		
	Else
		
		Address = Result.Address;
		
	EndIf;
	
	Try
		
		OpenImportFileAtServer(Address);
		ExportPeriodPresentation = PeriodPresentation(Object.StartDate, Object.EndDate);
		
	Except
		
		MessageToUser(NStr("vi = 'Không thể đọc tệp trao đổi.';
							|ru = 'Не удалось прочитать файл обмена.';
							|en = 'Cannot read the exchange file.'; fa = 'Cannot read the exchange file.';
							|it = 'Impossibile leggere il file di scambio.';
							|pl = 'Nie udało się odczytać plik wymiany.';
							|tr = 'Değişim dosyası okunamıyor.'"));
		ClearDataImportFileData();
		
	EndTry;
			
EndProcedure

&AtServer
Procedure ExecuteImportAtServer(FileAddress, FileNameForExtension)
	
	FileToImportName = FileNameAtServerOrClient(ExchangeFileName ,FileAddress, FileNameForExtension);
	
	If FileToImportName = Undefined Then
		
		Return;
		
	Else
		
		Object.ExchangeFileName = FileToImportName;
		
	EndIf;
	
	If Object.SafeImport Then
		If IsTempStorageURL(ImportRulesFileAddressInStorage) Then
			BinaryData = GetFromTempStorage(ImportRulesFileAddressInStorage); // BinaryData
			Object.ExchangeRulesFileName = GetTempFileName("xml"); // ACC:441 - Deletion within "ImportExchangeRulesAndParametersAtServer".
			BinaryData.Write(Object.ExchangeRulesFileName);
		Else
			MessageToUser(NStr("vi = 'Chưa chỉ ra tệp quy tắc để kết nhập dữ liệu.';
								|ru = 'Не указан файл правил для загрузки данных.';
								|en = 'Data import file is not specified.'; fa = 'Data import file is not specified.';
								|it = 'Nessun file di regole specificato per il download dei dati.';
								|pl = 'Nie wskazano pliku reguł do pobierania danych.';
								|tr = 'Verileri içe aktarma kuralları dosyası belirtilmedi.'"));
			Return;
		EndIf;
	EndIf;
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ObjectForServer.ExecuteImport();
	
	Try
		
		If Not IsBlankString(FileAddress) Then
			DeleteFiles(FileToImportName);
		EndIf;
		
	Except
		WriteLogEvent(NStr("vi = 'Trao đổi dữ liệu đa năng theo định dạng XML';
							|ru = 'Универсальный обмен данными в формате XML';
							|en = 'Conversion Rule Data Exchange in XML format'; fa = 'تبادل داده با قواعد تبدیل در قالب XML';
							|it = 'Scambio dati universale in formato XML';
							|pl = 'Uniwersalna wymiana danych w formacie XML';
							|tr = 'XML formatında kapsamlı veri alışverişi'", ObjectForServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	ObjectForServer.Parameters.Clear();
	ValueToFormAttribute(ObjectForServer, "Object");
	
	RulesAreImported = False;
	Items.FormExecuteExport.Enabled = False;
	Items.ExportNoteLabel.Visible = True;
	Items.ExportDebugAvailableGroup.Enabled = False;
	
EndProcedure

&AtServer
Function FileNameAtServerOrClient(Var_AttributeName ,Val FileAddress, Val FileNameForExtension = ".xml",
	CreateNew = False, CheckForExistence = True)
	
	FileName = Undefined;
	
	If IsClient Then
		
		If CreateNew Then
			
			Extension = ? (Object.ArchiveFile, ".zip", ".xml");
			
			FileName = GetTempFileName(Extension); // ACC:441 - Deletion within "ImportExchangeRulesAndParametersAtServer" or "ExecuteExportAtServer".
			
		Else
			
			Extension = FileExtention(FileNameForExtension);
			BinaryData = GetFromTempStorage(FileAddress); // BinaryData
			FileName = GetTempFileName(Extension); // ACC:441 - Deletion within "ImportExchangeRulesAndParametersAtServer" or "ExecuteExportAtServer".
			BinaryData.Write(FileName);
			
		EndIf;
		
	Else
		
		FileOnServer = New File(Var_AttributeName);
		
		If Not FileOnServer.Exists() And CheckForExistence Then
			
			MessageToUser(NStr("vi = 'Không tồn tại tệp đã chỉ ra.';
								|ru = 'Указанный файл не существует.';
								|en = 'The file does not exist.'; fa = 'The file does not exist.';
								|it = 'Il file specificato non esiste.';
								|pl = 'Wskazany plik nie istnieje.';
								|tr = 'Belirtilen dosya mevcut değil.'"));
			
		Else
			
			FileName = Var_AttributeName;
			
		EndIf;
		
	EndIf;
	
	Return FileName;
	
EndFunction

&AtServer
Function FileExtention(Val FileName)
	
	PointPosition = LastSeparator(FileName);
	
	Extension = Right(FileName,StrLen(FileName) - PointPosition + 1);
	
	Return Extension;
	
EndFunction

&AtServer
Function LastSeparator(StringWithSeparator, Separator = ".")
	
	StringLength = StrLen(StringWithSeparator);
	
	While StringLength > 0 Do
		
		If Mid(StringWithSeparator, StringLength, 1) = Separator Then
			
			Return StringLength; 
			
		EndIf;
		
		StringLength = StringLength - 1;
		
	EndDo;

EndFunction

&AtClient
Procedure ExecuteExportFromForm()
	
	// Adding rule file name and data file name to the selection list.
	AddRowToChoiceList(Items.RulesFileName.ChoiceList, RulesFileName, ExchangeRules);
	
	If Not Object.DirectReadingInDestinationIB And Not IsClient Then
		
		If RuleAndExchangeFileNamesMatch() Then
			Return;
		EndIf;
		
		AddRowToChoiceList(Items.DataFileName.ChoiceList, DataFileName, DataExportToFile);
		
	EndIf;
	
	DataFileAddressInStorage = ExecuteExportAtServer();
	
	If DataFileAddressInStorage = Undefined Then
		Return;
	EndIf;
	
	ExpandTreeRows(Object.ExportRulesTable, Items.ExportRulesTable, "Enable");
	
	If IsClient And Not DirectExport And Not Object.ErrorFlag Then
		
		GetUploadFileOnClient(DataFileAddressInStorage);
		
	EndIf;
	
	OpenExchangeProtocolDataIfNecessary();
	
EndProcedure

&AtClient
Procedure GetUploadFileOnClient(Address)
	
	FileToSaveName = NStr("vi = 'Tệp kết xuất';
							|ru = 'Файл выгрузки';
							|en = 'Export file'; fa = 'فایل خروج';
							|it = 'File di upload';
							|pl = 'Plik przesyłania';
							|tr = 'Dışa aktarma dosyası'");
	
	ChoiceDialog = New FileDialog(FileDialogMode.Save);
	
	ChoiceDialog.Title = NStr("vi = 'Hãy chọn đường dẫn để lưu tệp kết xuất';
								|ru = 'Выберите путь для сохранения файла выгрузки';
								|en = 'Select a path to save the export file'; fa = 'Select a path to save the export file';
								|it = 'Выберите путь для сохранения файла выгрузки';
								|pl = 'Select a path to save the export file';
								|tr = 'Yükleme dosyasının kaydedileceği yolu seçin'");
	ChoiceDialog.DefaultExt = ?(Object.ArchiveFile, "zip", "xml");
	ChoiceDialog.Filter = ?(Object.ArchiveFile, "(*.zip)|*.zip", "(*.xml)|*.xml");
	
    Notification = New CallbackDescription;
	
	FilesToObtain = New Array;
	
	FilesToObtain.Add(New TransferableFileDescription(FileToSaveName, Address));
	
	BeginGettingFiles(Notification, FilesToObtain, ChoiceDialog);
	
EndProcedure

&AtServer
Function ExecuteExportAtServer()
	
	Object.ExchangeRulesFileName = FileNameAtServerOrClient(RulesFileName, RuleFileAddressInStorage);
	
	If Not DirectExport Then
		
		TempDataFileName = FileNameAtServerOrClient(DataFileName, "",,True, False);
		
		If TempDataFileName = Undefined Then
			
			MessageToUser(NStr("vi = 'Chưa xác định tệp dữ liệu';
								|ru = 'Не определен файл данных';
								|en = 'Data file not specified'; fa = 'Data file not specified';
								|it = 'Nessun file di dati definito';
								|pl = 'Nie określono pliku danych';
								|tr = 'Veri dosyası belirtilmedi'"));
			Return Undefined;
			
		Else
			
			Object.ExchangeFileName = TempDataFileName;
			
		EndIf;
		
	EndIf;
	
	ExportRulesTable = FormAttributeToValue("Object.ExportRulesTable");
	ParametersSetupTable = FormAttributeToValue("Object.ParametersSetupTable");
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	
	If ObjectForServer.HandlersDebugModeFlag Then
		
		Cancel = False;
		
		File = New File(ObjectForServer.EventHandlerExternalDataProcessorFileName);
		
		If Not File.Exists() Then
			
			MessageToUser(NStr("vi = 'Không tồn tại tệp bộ xử lý ngoài gỡ rối sự kiện trên máy chủ';
								|ru = 'Файл внешней обработки отладчиков событий не существует на сервере';
								|en = 'The external event debugger file does not exist on the server'; fa = 'The external event debugger file does not exist on the server';
								|it = 'Il file di elaborazione esterna dei debugger eventi non esiste sul server';
								|pl = 'Plik zewnętrznego przetwarzania procedur debugowania wydarzeń nie istnieje na serwerze';
								|tr = 'Sunucuda olay hata ayıklayıcılarının dış veri işlemci dosyası yok'"));
			Return Undefined;
			
		EndIf;
		
		ObjectForServer.ExportEventHandlers(Cancel);
		
		If Cancel Then
			
			MessageToUser(NStr("vi = 'Không thể kết xuất hàm sự kiện';
								|ru = 'Не удалось выгрузить обработчики событий';
								|en = 'Cannot export event handlers'; fa = 'Cannot export event handlers';
								|it = 'Impossibile scaricare elaboratori degli eventi';
								|pl = 'Nie udało się eksportować procedur przetwarzania wydarzeń';
								|tr = 'Etkinlik işleyicileri dışa aktarılamıyor'"));
			Return "";
			
		EndIf;
		
	Else
		
		ObjectForServer.ImportExchangeRules();
		ObjectForServer.InitializeInitialParameterValues();
		
	EndIf;
	
	ChangeExportRuleTree(ObjectForServer.ExportRulesTable.Rows, ExportRulesTable.Rows);
	ChangeParameterTable(ObjectForServer.ParametersSetupTable, ParametersSetupTable);
	
	ObjectForServer.ExecuteExport();
	ObjectForServer.ExportRulesTable = FormAttributeToValue("Object.ExportRulesTable");
	
	If IsClient And Not DirectExport Then
		
		DataFileAddress = PutToTempStorage(New BinaryData(ObjectForServer.ExchangeFileName), 
			UUID);
			
		DeleteFiles(ObjectForServer.ExchangeFileName);
		
	Else
		
		DataFileAddress = "";
		
	EndIf;
	
	If IsClient Then
		
		DeleteFiles(ObjectForServer.ExchangeRulesFileName);
		
	EndIf;
	
	ObjectForServer.Parameters.Clear();
	ValueToFormAttribute(ObjectForServer, "Object");
	
	Return DataFileAddress;
	
EndFunction

&AtClient
Procedure SetDebugCommandsEnabled()
	
	Items.ImportDebugSetup.Enabled = Object.HandlersDebugModeFlag;
	Items.ExportDebugSetup.Enabled = Object.HandlersDebugModeFlag;
	
EndProcedure

// Modifies a DER tree according to the tree specified in the form.
//
&AtServer
Procedure ChangeExportRuleTree(SourceTreeRows, TreeToReplaceRows)
	
	EnableColumn = TreeToReplaceRows.UnloadColumn("Enable");
	SourceTreeRows.LoadColumn(EnableColumn, "Enable");
	NodeColumn = TreeToReplaceRows.UnloadColumn("ExchangeNodeRef");
	SourceTreeRows.LoadColumn(NodeColumn, "ExchangeNodeRef");
	
	For Each SourceTreeRow1 In SourceTreeRows Do
		
		RowIndex = SourceTreeRows.IndexOf(SourceTreeRow1);
		TreeToChangeRow = TreeToReplaceRows.Get(RowIndex);
		
		ChangeExportRuleTree(SourceTreeRow1.Rows, TreeToChangeRow.Rows);
		
	EndDo;
	
EndProcedure

// Changed parameter table according the table in the form.
//
&AtServer
Procedure ChangeParameterTable(BaseTable, FormTable)
	
	DescriptionColumn = FormTable.UnloadColumn("Description");
	BaseTable.LoadColumn(DescriptionColumn, "Description");
	ValueColumn = FormTable.UnloadColumn("Value");
	BaseTable.LoadColumn(ValueColumn, "Value");
	
EndProcedure

&AtClient
Procedure DirectExportOnValueChange()
	
	ExportingParameters = Items.ExportingParameters;
	
	ExportingParameters.CurrentPage = ?(DirectExport = 0,
										  ExportingParameters.ChildItems.ExportingToFile,
										  ExportingParameters.ChildItems.ExportToDestinationIB);
	
	Object.DirectReadingInDestinationIB = (DirectExport = 1);
	
	InfobaseTypeForConnectionOnValueChange();
	
EndProcedure

&AtClient
Procedure InfobaseTypeForConnectionOnValueChange()
	
	InfobaseType = Items.InfobaseType;
	InfobaseType.CurrentPage = ?(Object.InfobaseToConnectType,
								InfobaseType.ChildItems.FileInforbaseFind,
								InfobaseType.ChildItems.ServerInfobase);
	
EndProcedure

&AtClient
Procedure AddRowToChoiceList(ValueListToSave, SavingValue, ParameterNameToSave)
	
	If IsBlankString(SavingValue) Then
		Return;
	EndIf;
	
	FoundItem = ValueListToSave.FindByValue(SavingValue);
	If FoundItem <> Undefined Then
		ValueListToSave.Delete(FoundItem);
	EndIf;
	
	ValueListToSave.Insert(0, SavingValue);
	
	While ValueListToSave.Count() > 10 Do
		ValueListToSave.Delete(ValueListToSave.Count() - 1);
	EndDo;
	
	ParameterNameToSave = ValueListToSave;
	
EndProcedure

&AtClient
Procedure OpenHandlerDebugSetupForm(EventHandlersFromRuleFile)
	
	DataProcessorName = Left(FormName, LastSeparator(FormName));
	FormNameToCall = DataProcessorName + "HandlerDebugSetupManagedForm";
	
	FormParameters = New Structure;
	FormParameters.Insert("EventHandlerExternalDataProcessorFileName", Object.EventHandlerExternalDataProcessorFileName);
	FormParameters.Insert("AlgorithmsDebugMode", Object.AlgorithmsDebugMode);
	FormParameters.Insert("ExchangeRulesFileName", Object.ExchangeRulesFileName);
	FormParameters.Insert("ExchangeFileName", Object.ExchangeFileName);
	FormParameters.Insert("ReadEventHandlersFromExchangeRulesFile", EventHandlersFromRuleFile);
	FormParameters.Insert("DataProcessorName", DataProcessorName);
	
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	Handler = New CallbackDescription("OpenHandlerDebugSetupFormCompletion", ThisObject, EventHandlersFromRuleFile);
	
	OpenForm(FormNameToCall, FormParameters, ThisObject,,,,Handler, Mode);
	
EndProcedure

&AtClient
Procedure OpenHandlerDebugSetupFormCompletion(DebugParameters, EventHandlersFromRuleFile) Export
	
	If DebugParameters <> Undefined Then
		
		FillPropertyValues(Object, DebugParameters);
		
		If IsClient Then
			
			If EventHandlersFromRuleFile Then
				
				FileName = Object.ExchangeRulesFileName;
				
			Else
				
				FileName = Object.ExchangeFileName;
				
			EndIf;
			
			Notification = New CallbackDescription("OpenHandlersDebugSettingsFormCompletionFileDeletion", ThisObject);
			BeginDeletingFiles(Notification, FileName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenHandlersDebugSettingsFormCompletionFileDeletion(AdditionalParameters) Export
	
	Return;
	
EndProcedure

&AtClient
Procedure ChangeFileLocation()
	
	Items.RulesFileName.Visible = Not IsClient;
	Items.DataFileName.Visible = Not IsClient;
	Items.ExchangeFileName.Visible = Not IsClient;
	Items.SafeImportGroup.Visible = Not IsClient;
	
	SetImportRuleFlag(False);
	
EndProcedure

&AtClient
Procedure ChangeProcessingMode(WorkMode)
	
	ModeGroup1 = CommandBar.ChildItems.ProcessingMode.ChildItems;
	
	ModeGroup1.FormAtClient.Check = WorkMode;
	ModeGroup1.FormAtServer.Check = Not WorkMode;
	
	CommandBar.ChildItems.ProcessingMode.Title = 
	?(WorkMode, NStr("vi = 'Chế độ làm việc (trên Client)';
					|ru = 'Режим работы (на клиенте)';
					|en = 'Mode (client)'; fa = 'Mode (client)';
					|it = 'Orario di lavoro (dal cliente)';
					|pl = 'Tryb pracy (na kliencie)';
					|tr = 'Çalışma modu (istemcide)'"), NStr("vi = 'Chế độ làm việc (trên máy chủ)';
													|ru = 'Режим работы (на сервере)';
													|en = 'Mode (server)'; fa = 'Mode (server)';
													|it = 'Orario di lavoro (su server)';
													|pl = 'Tryb pracy (na serwerze)';
													|tr = 'Çalışma modu (sunucuda)'"));
	
	Object.ExportRulesTable.GetItems().Clear();
	Object.ParametersSetupTable.Clear();
	
	ChangeFileLocation();
	
EndProcedure

&AtClient
Procedure OpenExchangeProtocolDataIfNecessary()
	
	If Not Object.OpenExchangeProtocolsAfterExecutingOperations Then
		Return;
	EndIf;
	
	#If Not WebClient Then
		
		If Not IsBlankString(Object.ExchangeProtocolFileName) Then
			OpenInApplication(Object.ExchangeProtocolFileName);
		EndIf;
		
		If Object.DirectReadingInDestinationIB Then
			
			Object.ImportExchangeLogFileName = GetProtocolNameForSecondCOMConnectionInfobaseAtServer();
			
			If Not IsBlankString(Object.ImportExchangeLogFileName) Then
				OpenInApplication(Object.ImportExchangeLogFileName);
			EndIf;
			
		EndIf;
		
	#EndIf
	
EndProcedure

&AtServer
Function GetProtocolNameForSecondCOMConnectionInfobaseAtServer()
	
	Return FormAttributeToValue("Object").GetProtocolNameForCOMConnectionSecondInfobase();
	
EndFunction

&AtClient
Function EmptyAttributeValue(Attribute, DataPath, Var_Title)
	
	If IsBlankString(Attribute) Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""%1""';
							|ru = 'Поле ""%1"" не заполнено';
							|en = '""%1"" is required'; fa = '""%1"" is required';
							|it = 'Il campo ""%1"" non è compilato';
							|pl = 'Pole ""%1"" nie jest wypełnione';
							|tr = '""%1"" alanı doldurulmadı.'");
		MessageText = StrReplace(MessageText, "%1", Var_Title);
		
		MessageToUser(MessageText, DataPath);
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtClient
Procedure SetImportRuleFlag(Flag)
	
	RulesAreImported = Flag;
	Items.FormExecuteExport.Enabled = Flag;
	Items.ExportNoteLabel.Visible = Not Flag;
	Items.ExportDebugGroup.Enabled = Flag;
	
EndProcedure

&AtClient
Procedure OnChangeChangesRegistrationDeletionType()
	
	If IsBlankString(ChangesRegistrationDeletionTypeForExportedExchangeNodes) Then
		Object.ChangesRegistrationDeletionTypeForExportedExchangeNodes = 0;
	Else
		Object.ChangesRegistrationDeletionTypeForExportedExchangeNodes = Number(ChangesRegistrationDeletionTypeForExportedExchangeNodes);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

// Returns True if the client application is running on Windows.
//
// Returns:
//  Boolean -  Returns False if no client application is available.
//
&AtClient
Function IsWindowsClient()
	
	SystemInfo = New SystemInfo;
	
	IsWindowsClient = SystemInfo.PlatformType = PlatformType.Windows_x86
	             Or SystemInfo.PlatformType = PlatformType.Windows_x86_64;
	
	Return IsWindowsClient;
	
EndFunction

&AtServer
Procedure CheckPlatformVersionAndCompatibilityMode()
	
	Information = New SystemInfo;
	VersionParts = StrSplit(Information.AppVersion, ".");
	If Not (Not (VersionParts.Count() < 2 Or Number(VersionParts[0]) < 8 Or Number(VersionParts[1]) < 3)
		And (Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse
		Or (Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_1
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode.Version8_2_13
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_2_16"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_1"]
		And Metadata.CompatibilityMode <> Metadata.ObjectProperties.CompatibilityMode["Version8_3_2"]))) Then
		
		Raise NStr("vi = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3.3 с отключенным режимом совместимости или выше';
			|ru = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3.3 с отключенным режимом совместимости или выше';
			|en = 'The data processor supports 1C:Enterprise 8.3.3 or later,
			|with disabled compatibility mode.'; fa = 'The data processor supports 1C:Enterprise 8.3.3 or later,
			|with disabled compatibility mode.';
			|it = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3.3 с отключенным режимом совместимости или выше';
			|pl = 'The data processor supports 1C:Enterprise 8.3.3 or later,
			|with disabled compatibility mode.';
			|tr = 'Обработка предназначена для запуска на версии платформы
			|1С:Предприятие 8.3.3 с отключенным режимом совместимости или выше'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSafeImportMode(Interactively = True)
	
	Items.SafeImportGroup.Enabled = Object.SafeImport;

	ThroughStorage = IsClient;
	
	#If WebClient Then
		ThroughStorage = True;
	#EndIf
	
	If Object.SafeImport And ThroughStorage Then
		PutImportRulesFileInStorage();
	EndIf;
	
EndProcedure

&AtClient
Procedure PutImportRulesFileInStorage()
	
	ThroughStorage = IsClient;
	
	#If WebClient Then
		ThroughStorage = True;
	#EndIf
	
	FileAddress = "";
	
	CallbackDescription = New CallbackDescription("PutImportRulesFileInStorageCompletion", ThisObject); 
	
	If ThroughStorage Then
				
		BeginPutFileToServer(CallbackDescription,,, FileAddress, 
			PreparedParametersOfFilePlacementDialog(), UUID);
		
	Else 
		
		BeginPutFileToServer(CallbackDescription,,, FileAddress, NameOfImportRulesFile, UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PutImportRulesFileInStorageCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result.PutFileCanceled Then
		Return;
	EndIf;
	
	ImportRulesFileAddressInStorage = Result.Address;
	
EndProcedure

&AtClient 
Procedure FileSystemExtensionAttachment(InstallIfNotAttachable) Export
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription("AfterConnecting", ThisObject, InstallIfNotAttachable));
		
EndProcedure

&AtClient
Procedure AfterConnecting(Attached, InstallIfNotAttachable) Export
	
	If Attached Then
		
		// 1C:Enterprise Extension is installed
		
	ElsIf InstallIfNotAttachable Then
		
		BeginInstallFileSystemExtension(
			New CallbackDescription("FileSystemExtensionAttachment", ThisObject, False));
		
	Else
		
		MessageText = NStr("vi = 'Không thể cài đặt hoặc kết nối phần mở rộng làm việc với tệp';
							|ru = 'Не удалось установить или подключить расширение работы с файлами';
							|en = 'Failed to install or attach 1C:Enterprise Extension'; fa = 'Failed to install or attach 1C:Enterprise Extension';
							|it = 'Не удалось установить или подключить расширение работы с файлами';
							|pl = 'Failed to install or attach 1C:Enterprise Extension';
							|tr = 'Dosya uzantısı yüklenemedi veya bağlanılamadı'");
		MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

// Returns data processor version.
&AtServer
Function VersionOfObjectAtServer()
	
	Return FormAttributeToValue("Object").ObjectVersion();
	
EndFunction

&AtClient
Function PreparedParametersOfFilePlacementDialog()
	
	RoomDialogParameters = New PutFilesDialogParameters;
	
	RoomDialogParameters.MultipleChoice = False;
	RoomDialogParameters.Filter = "All files (*.*)|*.*";
	RoomDialogParameters.Title = NStr("vi = 'Chọn tệp để kết nhập';
										|ru = 'Выберите файл для загрузки';
										|en = 'Select a file to import'; fa = 'Select a file to import';
										|it = 'Selezionare un file per l''esportazione';
										|pl = 'Wybierz plik do pobrania';
										|tr = 'Harici dosya seç'");
	
	Return RoomDialogParameters;
	
EndFunction 

// Returns:
//   Structure:
//     * AddressOfFileOnServer - String
//
&AtClient
Function AdditionalNotificationProcessingParameters()
	
	Structure = New Structure; 
	
	Structure.Insert("AddressOfFileOnServer", "");
	
	Return Structure;
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
