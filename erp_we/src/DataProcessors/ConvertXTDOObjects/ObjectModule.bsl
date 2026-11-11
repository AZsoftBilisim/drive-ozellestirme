///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var DataImportDataProcessorField;

#EndRegion

#Region Public

#Region ExportProperties1

// Function for retrieving property: the result of data exchange.
//  Returns:
//      EnumRef.ExchangeExecutionResults - data exchange result.
//
Function ExchangeExecutionResult() Export
	
	If ExchangeComponents = Undefined Then
		Return Enums.ExchangeExecutionResults.Canceled;
	EndIf;
	
	ExchangeExecutionResult = ExchangeComponents.DataExchangeState.ExchangeExecutionResult;
	If ExchangeExecutionResult = Undefined Then
		Return Enums.ExchangeExecutionResults.Completed2;
	EndIf;
	
	Return ExchangeExecutionResult;
	
EndFunction

// Function for retrieving property: the result of data exchange.
//
//  Returns: 
//      String - data exchange result.
//
Function ExchangeExecutionResultString() Export
	
	Return Common.EnumerationValueName(ExchangeExecutionResult());
	
EndFunction


// Function for retrieving property: the number of imported objects.
//
//  Returns:
//      Number - number of imported objects.
//
Function ImportedObjectCounter() Export
	
	If ExchangeComponents = Undefined Then
		Return 0;
	EndIf;
	
	Return ExchangeComponents.ImportedObjectCounter;
	
EndFunction

// Function for retrieving property: the amount of exported objects.
//
//  Returns:
//      Number - number of exported objects.
//
Function ExportedObjectCounter() Export
	
	If ExchangeComponents = Undefined Then
		Return 0;
	EndIf;
	
	Return ExchangeComponents.ExportedObjectCounter;
	
EndFunction

// Function for retrieving properties: a data exchange error message string.
//
//  Returns:
//      String - a data exchange error message string.
//
Function ErrorMessageString() Export
	
	If ExchangeComponents = Undefined Then
		Return "";
	EndIf;
	
	Return ExchangeComponents.ErrorMessageString;
	
EndFunction

// Function for retrieving property: a flag that shows a data exchange execution error.
//
//  Returns:
//     Boolean - a flag that shows a data exchange execution error.
//
Function ErrorFlag() Export
	
	Return ExchangeComponents.ErrorFlag;
	
EndFunction

// Function for retrieving property: a number of data exchange message.
//
//  Returns:
//      Number - a number of the data exchange message.
//
Function MessageNo() Export
	
	Return ExchangeComponents.IncomingMessageNumber;
	
EndFunction

// Function for retrieving properties: a value table with incoming exchange message statistics and extra information.
//
//  Returns:
//      ValueTable - contains statistics and extra information on the incoming exchange message.
//
Function PackageHeaderDataTable() Export
	
	If ExchangeComponents = Undefined Then
		Return DataExchangeXDTOServer.NewDataBatchTitleTable();
	Else
		Return ExchangeComponents.PackageHeaderDataTable;
	EndIf;
	
EndFunction

// Function for retrieving properties: map with data tables of the received data exchange message.
//
//  Returns:
//      Map - contains data tables of the received data exchange message.
//
Function DataTablesExchangeMessages() Export
	
	If ExchangeComponents = Undefined Then
		Return New Map;
	Else
		Return ExchangeComponents.DataTablesExchangeMessages;
	EndIf;
	
EndFunction

#EndRegion

#Region DataExport

// Run data export
// -- All objects are exported to one file.
//
// Parameters:
//      DataProcessorForDataImport - DataProcessorObject.ConvertXTDOObjects - a data processor for import in COM connection.
//
Procedure RunDataExport(DataProcessorForDataImport = Undefined) Export
	
	DataExchangeServer.ClearErrorsListOnExportData(NodeForExchange);
	
	DataImportDataProcessorField = DataProcessorForDataImport;
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Send");
	
	AdditionalConversionParameters = New Structure("ChangeSelectionFilter,UseHandshake");
	FillPropertyValues(AdditionalConversionParameters, Parameters);
	
	If AdditionalConversionParameters.ChangeSelectionFilter <> Undefined Then
		ExchangeComponents.ChangeSelectionFilter = Common.CopyRecursive(AdditionalConversionParameters.ChangeSelectionFilter);
	EndIf;
	If AdditionalConversionParameters.UseHandshake <> Undefined Then
		ExchangeComponents.UseHandshake = AdditionalConversionParameters.UseHandshake;
	EndIf;
		
#Region SettingExchangeComponentsForNodeOperations
	ExchangeComponents.CorrespondentNode = NodeForExchange;
	
	DataExchangeValuationOfPerformance.Initialize(ExchangeComponents);
	
	ExchangeComponents.XDTOSettingsOnly = Not DataExchangeServer.SynchronizationSetupCompleted(
		ExchangeComponents.CorrespondentNode);
	If Not ExchangeComponents.XDTOSettingsOnly Then
		ExchangeComponents.ExchangeFormatVersion = Common.ObjectAttributeValue(
			ExchangeComponents.CorrespondentNode, "ExchangeFormatVersion");
	EndIf;
		
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
	ExchangeComponents.XMLSchema = DataExchangeXDTOServer.ExchangeFormat(ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
	
	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);
	
	If ExchangeComponents.XDTOSettingsOnly Then
		
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		
	Else
		
		ExchangeComponents.ExchangeManager = DataExchangeXDTOServer.FormatVersionExchangeManager(
			ExchangeComponents.ExchangeFormatVersion, ExchangeComponents.CorrespondentNode);
		
		ExchangeComponents.ObjectsRegistrationRulesTable = DataExchangeXDTOServer.ObjectsRegistrationRules(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ExchangePlanNodeProperties = DataExchangeXDTOServer.ExchangePlanNodeProperties(
			ExchangeComponents.CorrespondentNode);
			
		DataExchangeXDTOServer.InitializeExchangeRulesTables(ExchangeComponents);
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		DataExchangeXDTOServer.FillSupportedXDTOObjects(ExchangeComponents);
		
		ExchangeComponents.SkipObjectsWithSchemaCheckErrors = DataExchangeXDTOServer.SkipObjectsWithSchemaCheckErrors(
			ExchangeComponents.CorrespondentNode);
		
	EndIf;
	
#EndRegion
	
	If Not ExchangeComponents.XDTOSettingsOnly Then
		ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
		ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
		
		DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	EndIf;
	
	Cancel = False;
	If SetExchangePlanNodeLock
		And ExchangeComponents.IsExchangeViaExchangePlan Then
		
		DataExchangeServer.BlockTheExchangeNode(ExchangeComponents.CorrespondentNode, Cancel);
		
	EndIf;
	
	If Cancel = True Then
		
		Return;
		
	EndIf;
	
	// Open an exchange file.
	DataExchangeXDTOServer.OpenExportFile(ExchangeComponents, ExchangeFileName);
	
	Try
		AfterOpenExportFile(Cancel);
		// DATA EXPORT
		If Not Cancel Then
			DataExchangeXDTOServer.ExecuteDataExport(ExchangeComponents);
		EndIf;
	Except
		Info = ErrorInfo();
		ErrorCode = New Structure("BriefErrorDescription, DetailErrorDescription",
			ErrorProcessing.BriefErrorDescription(Info), ErrorProcessing.DetailErrorDescription(Info));
		
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		
		ExchangeComponents.ExchangeFile = Undefined;
		Cancel = True;
	EndTry;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		If ExchangeComponents.UseHandshake Then
			UnlockDataForEdit(ExchangeComponents.CorrespondentNode);
		EndIf;
	EndIf;
	
	If ExchangeComponents.ErrorFlag Then
		
		If Not IsBlankString(ExchangeFileName) Then
			Try
				DeleteFiles(ExchangeFileName);
			Except
				WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
					EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));	
			EndTry;
		EndIf;
	
	EndIf;
	
	If Cancel Then
		
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		
		Return;
		
	EndIf;
	
	XMLExportData = ExchangeComponents.ExchangeFile.Close();
	
	DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
	
	DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
	
	If IsExchangeOverExternalConnection() Then
		If DataProcessorForDataImport().DataImportMode = "ImportMessageForDataMapping" Then
			If Not ExchangeComponents.ErrorFlag Then
				DataProcessorForDataImport().PutMessageForDataMapping(XMLExportData);
			Else
				DataProcessorForDataImport().PutMessageForDataMapping(Undefined);
			EndIf;
		Else
			If Not ExchangeComponents.ErrorFlag Then
				If Common.HasObjectAttribute("DataImportedOverExternalConnection", DataProcessorForDataImport().Metadata())
					And DataProcessorForDataImport().DataImportedOverExternalConnection Then
					DataProcessorForDataImport().ToDownloadTheMessageDataExchange(XMLExportData);
				Else
					TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
					TempFileName = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, String(New UUID) + ".xml");
				
					TextDocument = New TextDocument;
					TextDocument.AddLine(XMLExportData);
					TextDocument.Write(TempFileName,,Chars.LF);
					
					DataProcessorForDataImport().ExchangeFileName = TempFileName;
					DataProcessorForDataImport().RunDataImport();
				
					DeleteFiles(TempFileName);
				EndIf;
			Else
				DataProcessorForDataImport().ExchangeFileName = "";
				DataProcessorForDataImport().RunDataImport();
			EndIf;
		EndIf;
	EndIf;
	
	If SetExchangePlanNodeLock
		And ExchangeComponents.IsExchangeViaExchangePlan Then
		
		DataExchangeServer.UnblockTheExchangeNode(ExchangeComponents.CorrespondentNode, Cancel);
		
	EndIf;
		
EndProcedure

#EndRegion

#Region DataImport

// Imports data from the exchange message file.
// Data is imported to the infobase.
//
// Parameters:
//  ImportParameters - Structure
//                    - Undefined - For internal use only.
//
Procedure RunDataImport(ImportParameters = Undefined) Export
	
	DataExchangeServer.ClearErrorsListOnDataImport(NodeForExchange);
	
	If ImportParameters = Undefined Then
		ImportParameters = New Structure;
	EndIf;
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Receive");
		
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	ExchangeComponents.UseCacheOfPublicIdentifiers = 
		DataExchangeCached.UseCacheOfPublicIdentifiers(ExchangeNodeDataImport.Metadata().Name);
	
	DataExchangeValuationOfPerformance.Initialize(ExchangeComponents);

	DataExchangeWithExternalSystem = Undefined;
	If ImportParameters.Property("DataExchangeWithExternalSystem", DataExchangeWithExternalSystem) Then
		ExchangeComponents.DataExchangeWithExternalSystem = DataExchangeWithExternalSystem;
	EndIf;
	
	DataImportMode = "ImportToInfobase";
	
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	
	DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);
	
	If IsBlankString(ExchangeFileName) Then
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 15);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		Return;
	EndIf;
	
	If ContinueOnError Then
		UseTransactions = False;
		ExchangeComponents.UseTransactions = False;
	EndIf;
	
#If ExternalConnection Then
	InformationRegisters.ArchiveOfExchangeMessages.PackMessageToArchive(
		ExchangeNodeDataImport, ExchangeFileName);
#EndIf
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	// Format extension can be initialized following reading the format version from a message file.
	DataExchangeXDTOServer.FormatExtensionsToExchangeComponents(ExchangeComponents);
	
	Cancel = False;
	AfterOpenImportFile(Cancel);
	If SetExchangePlanNodeLock
		And ExchangeComponents.IsExchangeViaExchangePlan Then
		
		DataExchangeServer.BlockTheExchangeNode(ExchangeComponents.CorrespondentNode, Cancel);
		
	EndIf;
	
	If Cancel Then
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		Return;
	EndIf;
	
	DataAnalysisResultToExport = DataExchangeServer.DataAnalysisResultToExport(ExchangeFileName, True);
	DataAnalysisResultToExport.Insert("CorrespondentSupportsDataExchangeID",
											ExchangeComponents.CorrespondentSupportsDataExchangeID);
	ExchangeComponents.Insert("ExchangeMessageFileSize", DataAnalysisResultToExport.ExchangeMessageFileSize);
	ExchangeComponents.Insert("ObjectsToImportCount", DataAnalysisResultToExport.ObjectsToImportCount);
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.RunReadingData(ExchangeComponents);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Information = ErrorInfo();
		MessageString = NStr("vi = 'Lỗi khi kết nhập dữ liệu: %1';
							|ru = 'Ошибка при загрузке данных: %1';
							|en = 'Data import error: %1'; fa = 'Data import error: %1';
							|it = 'Errore durante il download dei dati: %1';
							|pl = 'Błąd podczas pobierania danych: %1';
							|tr = 'Veri içe aktarılırken bir hata oluştu: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, ErrorProcessing.DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, MessageString, , , , , True);
		ExchangeComponents.ErrorFlag = True;
	EndTry;
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.DeleteTempObjectsCreatedByRefs(ExchangeComponents);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Information = ErrorInfo();
		MessageString = NStr("vi = 'Lỗi khi xóa các tệp tạm thời đã tạo theo tham chiếu: %1';
							|ru = 'Ошибка при удалении временных объектов, созданных по ссылкам: %1';
							|en = 'Cannot delete temporary objects created by references: %1'; fa = 'Cannot delete temporary objects created by references: %1';
							|it = 'Errore durante l''eliminazione di oggetti temporanei creati dai link: %1';
							|pl = 'Błąd podczas usuwania tymczasowych obiektów, utworzonych pod odnośnikami: %1';
							|tr = 'Referanslara göre oluşturulan geçici nesneler kaldırılırken bir hata oluştu: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, ErrorProcessing.DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, MessageString, , , , , True);
		ExchangeComponents.ErrorFlag = True;
	EndTry;
	
	ExchangeComponents.ExchangeFile.Close();
	
	If Not ExchangeComponents.ErrorFlag Then
		// Checking data From / NewFrom.
		CheckNodesCodes(DataAnalysisResultToExport, ExchangeComponents.CorrespondentNode);
		
		If ExchangeComponents.UseHandshake Then
			// Writing information on the incoming message number.
			BeginTransaction();
			Try
				DataLock = New DataLock;
				
				DataLockItem = DataLock.Add("ExchangePlan." + DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode));
				DataLockItem.SetValue("Ref", ExchangeComponents.CorrespondentNode);
				
				DataLock.Lock();
		
				NodeObject = ExchangeComponents.CorrespondentNode.GetObject();
				NodeObject.ReceivedNo = ExchangeComponents.IncomingMessageNumber;
				NodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
				NodeObject.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
		EndIf;
		
	EndIf;
	
	DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
	
	DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
	
	If SetExchangePlanNodeLock
		And ExchangeComponents.IsExchangeViaExchangePlan Then
		
		DataExchangeServer.UnblockTheExchangeNode(ExchangeComponents.CorrespondentNode, Cancel);
		
	EndIf;
	
EndProcedure

// Imports data from an exchange message file to an infobase of the specified object types only.
//
// Parameters:
//  TablesToImport - Array of String - Array of types to be imported from the exchange message.
//                       For example, to import from the exchange message the Demo:Counterparties catalog items only::
//                         TablesToImport = New Array;
//                         TablesToImport.Add(CatalogRef.Currencies);
//                       You can receive the list of all types that are contained in the current exchange message
//                       by calling the ExecuteExchangeMessageAnalysis() procedure.
// 
Procedure ExecuteDataImportForInfobase(TablesToImport) Export
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Receive");
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	
	ExchangeComponents.UseCacheOfPublicIdentifiers = 
		DataExchangeCached.UseCacheOfPublicIdentifiers(ExchangeNodeDataImport.Metadata().Name);
		
	DataExchangeValuationOfPerformance.Initialize(ExchangeComponents);
	
	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);
	
	DataImportMode = "ImportToInfobase";
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	Cancel = False;
	AfterOpenImportFile(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	// Record in the event log.
	MessageString = NStr("vi = 'Bắt đầu quá trình trao đổi dữ liệu đối với nút: %1';
						|ru = 'Начало процесса обмена данными для узла: %1';
						|en = 'Data exchange started. Node: %1.'; fa = 'Data exchange started. Node: %1.';
						|it = 'Inizia il processo di scambio dati per il nodo: %1';
						|pl = 'Rozpocznij proces komunikacji dla witryny: %1';
						|tr = 'Ünite için veri değişimi süreci başlatılıyor: %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(ExchangeNodeDataImport));
	DataExchangeXDTOServer.WriteEventLogDataExchange1(MessageString, ExchangeComponents, EventLogLevel.Information);
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.RunReadingData(ExchangeComponents, TablesToImport);
	Except
		Information = ErrorInfo();
		MessageString = NStr("vi = 'Lỗi khi kết nhập dữ liệu: %1';
							|ru = 'Ошибка при загрузке данных: %1';
							|en = 'Data import error: %1'; fa = 'Data import error: %1';
							|it = 'Errore durante il download dei dati: %1';
							|pl = 'Błąd podczas pobierania danych: %1';
							|tr = 'Veri içe aktarılırken bir hata oluştu: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, ErrorProcessing.DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteEventLogDataExchange1(MessageString, ExchangeComponents, EventLogLevel.Error);
	EndTry;
	
	Try
		DataExchangeXDTOServer.DeleteTempObjectsCreatedByRefs(ExchangeComponents);
	Except
		Information = ErrorInfo();
		MessageString = NStr("vi = 'Lỗi khi xóa các tệp tạm thời đã tạo theo tham chiếu: %1';
							|ru = 'Ошибка при удалении временных объектов, созданных по ссылкам: %1';
							|en = 'Cannot delete temporary objects created by references: %1'; fa = 'Cannot delete temporary objects created by references: %1';
							|it = 'Errore durante l''eliminazione di oggetti temporanei creati dai link: %1';
							|pl = 'Błąd podczas usuwania tymczasowych obiektów, utworzonych pod odnośnikami: %1';
							|tr = 'Referanslara göre oluşturulan geçici nesneler kaldırılırken bir hata oluştu: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, ErrorProcessing.DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteEventLogDataExchange1(MessageString, ExchangeComponents, EventLogLevel.Error);
	EndTry;
	DataExchangeInternal.DisableAccessKeysUpdate(False);
	
	// Record in the event log.
	MessageString = NStr("vi = 'Thao tác được thực hiện: %1;
		|Trạng thái hoàn thành: %2;
		|Đối tượng đã xử lý: %3.';
		|ru = 'Выполняемое действие: %1;
		|Статус завершения: %2;
		|Обработано объектов: %3.';
		|en = 'Action to execute: %1;
		|Completion status: %2;
		|Objects processed: %3.'; fa = 'Action to execute: %1;
		|Completion status: %2;
		|Objects processed: %3.';
		|it = 'Attività eseguibile: %1;
		|Stato esecuzione: %2;
		|Oggetti elaborati: %3.';
		|pl = 'Wykonywane działanie: %1;
		|Status zakończenia: %2;
		|Przetworzono obiektów: %3.';
		|tr = 'Yürütülen eylem: %1;
		|Tamamlanma durumu: %2;
		|İşlenen öğeler: %3.'",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
					ExchangeComponents.DataExchangeState.ExchangeExecutionResult,
					Enums.ActionsOnExchange.DataImport,
					Format(ExchangeComponents.ImportedObjectCounter, "NG=0"));
	
	DataExchangeXDTOServer.WriteEventLogDataExchange1(MessageString, ExchangeComponents, EventLogLevel.Information);
	ExchangeComponents.ExchangeFile.Close();
	
EndProcedure

// Performs sequential reading of the exchange message file while:
//  - registration of changes by the number of the incoming receipt is deleted
//  - exchange rules are imported
//  - information on data types is imported
//  - data mapping information is read and recorded to the infobase
//  - information on objects types and their amount is collected.
//
// Parameters:
//      AnalysisParameters - Structure - not used, left for the compatibility purposes.
// 
Procedure ExecuteExchangeMessageAnalysis(AnalysisParameters = Undefined) Export
	
	DataImportMode = "ImportToValueTable";
	UseTransactions = False;
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Receive");
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	ExchangeComponents.DataImportToInfobaseMode = False;
	
	ExchangeComponents.UseCacheOfPublicIdentifiers = 
		DataExchangeCached.UseCacheOfPublicIdentifiers(ExchangeNodeDataImport.Metadata().Name);
		
	DataExchangeValuationOfPerformance.Initialize(ExchangeComponents, True);
	
	DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);
		
	If IsBlankString(ExchangeFileName) Then
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 15);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		Return;
	EndIf;
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	// Format extension can be initialized following reading the format version from a message file.
	DataExchangeXDTOServer.FormatExtensionsToExchangeComponents(ExchangeComponents);
	
	Cancel = False;
	AfterOpenImportFile(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	Try
		
		// Reading data from the exchange message.
		DataExchangeXDTOServer.ReadDataInAnalysisMode(ExchangeComponents, AnalysisParameters);
		
		PackageHeaderDataTable = ExchangeComponents.PackageHeaderDataTable; // ValueTable
		
		// Generate a temporary data table.
		TemporaryPackageHeaderDataTable = PackageHeaderDataTable.Copy(, "SourceTypeString, DestinationTypeString, SearchFields, TableFields");
		TemporaryPackageHeaderDataTable.GroupBy("SourceTypeString, DestinationTypeString, SearchFields, TableFields");
		
		// Collapsing a table of a data batch title.
		PackageHeaderDataTable.GroupBy(
			"ObjectTypeString, SourceTypeString, DestinationTypeString, SynchronizeByID, IsClassifier, IsObjectDeletion, UsePreview",
			"ObjectCountInSource");
		
		PackageHeaderDataTable.Columns.Add("SearchFields",  New TypeDescription("String"));
		PackageHeaderDataTable.Columns.Add("TableFields", New TypeDescription("String"));
		
		For Each TableRow In PackageHeaderDataTable Do
			
			Filter = New Structure;
			Filter.Insert("SourceTypeString", TableRow.SourceTypeString);
			Filter.Insert("DestinationTypeString", TableRow.DestinationTypeString);
			
			TemporaryTableRows = TemporaryPackageHeaderDataTable.FindRows(Filter);
			
			TableRow.SearchFields  = TemporaryTableRows[0].SearchFields;
			TableRow.TableFields = TemporaryTableRows[0].TableFields;
			
		EndDo;
		
	Except
		MessageString = NStr("vi = 'Lỗi khi phân tích dữ liệu: %1';
							|ru = 'Ошибка при анализе данных: %1';
							|en = 'Data analysis error: %1'; fa = 'Data analysis error: %1';
							|it = 'Errore durante l''analisi dei dati: %1';
							|pl = 'Błąd podczas analizy danych: %1';
							|tr = 'Veri analiz edilirken bir hata oluştu: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, MessageString,,,,,True);
	EndTry;
	
	ExchangeComponents.ExchangeFile.Close();
	
	DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
EndProcedure

// Imports data from the exchange message file to values table of specified objects types.
//
// Parameters:
//  TablesToImport - Array of String - Array of types to be imported from the exchange message.
//                       For example, to import from the exchange message the Demo:Counterparties catalog items only::
//                         TablesToImport = New Array;
//                         TablesToImport.Add(CatalogRef.Currencies);
//                       You can receive the list of all types that are contained in the current exchange message
//                       by calling the ExecuteExchangeMessageAnalysis() procedure.
// 
Procedure ExecuteDataImportIntoValueTable(TablesToImport) Export
	
	DataImportMode = "ImportToValueTable";
	UseTransactions = False;
	
	InitializeRulesTables = (ExchangeComponents = Undefined);
	
	If ExchangeComponents = Undefined Then
		
		ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Receive");
		ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
		ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
		ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
		
		ExchangeComponents.UseCacheOfPublicIdentifiers = 
			DataExchangeCached.UseCacheOfPublicIdentifiers(ExchangeNodeDataImport.Metadata().Name);
			
		DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);
		
		DataExchangeValuationOfPerformance.Initialize(ExchangeComponents);
		
	EndIf;
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	// Format extension can be initialized following reading the format version from a message file.
	DataExchangeXDTOServer.FormatExtensionsToExchangeComponents(ExchangeComponents);
	
	Cancel = False;
	AfterOpenImportFile(Cancel, InitializeRulesTables);
	
	If Cancel Then
		Return;
	EndIf;
	
	ExchangeComponents.DataImportToInfobaseMode = False;
	
	// Initialize data tables of the data exchange message.
	For Each DataTableKey In TablesToImport Do
		
		SubstringsArray = StrSplit(DataTableKey, "#");
		
		ObjectType = SubstringsArray[1];
		
		ExchangeComponents.DataTablesExchangeMessages.Insert(DataTableKey, InitExchangeMessageDataTable(Type(ObjectType)));
		
	EndDo;
	
	DataExchangeXDTOServer.RunReadingData(ExchangeComponents, TablesToImport);
	
	DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
	
	ExchangeComponents.ExchangeFile.Close();
		
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Stores an exchange file to a file storage service for subsequent mapping.
// Data is not imported.
//
Procedure PutMessageForDataMapping(XMLExportData) Export
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Receive");
	
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	
	ExchangeComponents.UseCacheOfPublicIdentifiers = 
		DataExchangeCached.UseCacheOfPublicIdentifiers(ExchangeNodeDataImport.Metadata().Name);
		
	DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);
	
	If Not ValueIsFilled(XMLExportData) Then
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 15);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		
		FileID = "";
	Else
		DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
		TempFileName = DataExchangeServer.UniqueExchangeMessageFileName();
		
		TempFileFullName = CommonClientServer.GetFullFileName(
			DumpDirectory, TempFileName);
			
		TextDocument = New TextDocument;
		TextDocument.AddLine(XMLExportData);
		TextDocument.Write(TempFileFullName, , Chars.LF);
		
		FileID = DataExchangeServer.PutFileInStorage(TempFileFullName);
	EndIf;
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNodeDataImport, FileID);
	
EndProcedure

Procedure ToDownloadTheMessageDataExchange(XMLExportData) Export
	
	TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
	ExchangeFileName = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, String(New UUID) + ".xml");
			
	TextDocument = New TextDocument;
	TextDocument.AddLine(XMLExportData);
	TextDocument.Write(ExchangeFileName, , Chars.LF);
	
	RunDataImport();
	
	DeleteFiles(ExchangeFileName);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Function InitExchangeMessageDataTable(ObjectType)
	
	ExchangeMessageDataTable = New ValueTable;
	
	Columns = ExchangeMessageDataTable.Columns;
	
	// Required fields.
	Columns.Add("UUID", New TypeDescription("String",, New StringQualifiers(36)));
	Columns.Add("TypeAsString",              New TypeDescription("String",, New StringQualifiers(255)));
	
	MetadataObject = Metadata.FindByType(ObjectType);
	
	// Get details of all metadata object fields from the configuration.
	ObjectPropertiesDescriptionTable = Common.ObjectPropertiesDetails(MetadataObject, "Name, Type");
	
	For Each PropertyDetails In ObjectPropertiesDescriptionTable Do
		
		Columns.Add(PropertyDetails.Name, PropertyDetails.Type);
		
	EndDo;
	
	ExchangeMessageDataTable.Indexes.Add("UUID");
	
	Return ExchangeMessageDataTable;
	
EndFunction

Function DataProcessorForDataImport()
	
	Return DataImportDataProcessorField;
	
EndFunction

Function IsExchangeOverExternalConnection()
	
	Return DataProcessorForDataImport() <> Undefined;
	
EndFunction

Procedure AfterOpenImportFile(Cancel = False, InitializeRulesTables = True)
	
	DataExchangeXDTOServer.AfterOpenImportFile(ExchangeComponents, Cancel, InitializeRulesTables);
	
EndProcedure

Procedure AfterOpenExportFile(Cancel = False)
	
	If ExchangeComponents.ErrorFlag Then
		ExchangeComponents.ExchangeFile = Undefined;
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
		Cancel = True;
		Return;
	EndIf;
	
	If ExchangeComponents.XDTOSettingsOnly Then
		// XDTO settings are sent only for file communication channels.
		ExchangeComponents.ExchangeFile.WriteEndElement(); // Message
		ExchangeComponents.ExchangeFile.Close();
		Cancel = True;
		Return;
	EndIf;
	
	ExchangePlanName = "";
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan
		And DataExchangeServer.HasExchangePlanManagerAlgorithm("DataTransferLimitsCheckHandler", ExchangePlanName) Then
		
		ErrorMessage = "";
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Peer", ExchangeComponents.CorrespondentNode);
		HandlerParameters.Insert("SupportedXDTOObjects", ExchangeComponents.SupportedXDTOObjects);
		
		ExchangePlans[ExchangePlanName].DataTransferLimitsCheckHandler(Cancel, HandlerParameters, ErrorMessage);
		
		If Cancel Then
			DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage);
			DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
			DataExchangeValuationOfPerformance.ExitApp(ExchangeComponents);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  DataAnalysisResultToExport - Structure - see details of the DataExchangeServer.DataAnalysisResultToExport
//  InfobaseNode - ExchangePlanRef
// 
Procedure CheckNodesCodes(DataAnalysisResultToExport, InfobaseNode)
	
	If Not DataExchangeServer.IsXDTOExchangePlan(InfobaseNode) Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		DataLock = New DataLock;
		
		DataLockItem = DataLock.Add("ExchangePlan." + DataExchangeCached.GetExchangePlanName(InfobaseNode));
		DataLockItem.SetValue("Ref", InfobaseNode);
		
		DataLockItem = DataLock.Add("InformationRegister.PredefinedNodesAliases");
		DataLockItem.SetValue("Peer", InfobaseNode);
		
		DataLock.Lock();

		IBNodeCode = Common.ObjectAttributeValue(InfobaseNode, "Code");
		If ValueIsFilled(DataAnalysisResultToExport.NewFrom) Then
			CorrespondentNodeRecoded = (IBNodeCode = DataAnalysisResultToExport.NewFrom);
			If Not CorrespondentNodeRecoded
				And DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(InfobaseNode) Then
				
				ExchangeNodeObject = InfobaseNode.GetObject();
				
				NewNodeRef = ExchangePlans[InfobaseNode.Metadata().Name].FindByCode(DataAnalysisResultToExport.NewFrom);		
				CreateNewNode = NewNodeRef.IsEmpty();
		
				If CreateNewNode Then				
					
					ExchangeNodeObject.Code = DataAnalysisResultToExport.NewFrom;
					ExchangeNodeObject.DataExchange.Load = True;
					ExchangeNodeObject.Write();
				
					CorrespondentNodeRecoded = True;
					
				Else
					
					ExceptionText = NStr("vi = 'Đã tìm thấy sự trùng lặp trong tùy chỉnh đồng bộ dữ liệu.
                                |Để sửa lỗi, hãy chuyển đến cơ sở thông tin trao đổi.
                                |Mở biểu mẫu ""Tùy chỉnh đồng bộ dữ liệu"".
								|Trong menu ""Hơn nữa"" hãy chọn ""Mã mới của nút định trước..."".
								|Hãy chọn sơ đồ trao đổi cần chỉnh sửa.
                                |Hãy tham khảo với thông tin trên biểu mẫu và nhấn ""Đặt mã mới"".
                                |Sau đó hãy đồng bộ lại (hoặc tạo mới tùy chỉnh trao đổi).';
                                |ru = 'Обнаружено дублирование настроек синхронизации данных.
                                |Для исправления ошибки перейдите в корреспондирующую информационную базу.
                                |Откройте форму ""Настройки синхронизации данных"".
                                |В меню ""Еще"" выберите ""Новый код предопределенного узла..."".
                                |Выберите план обмена, который необходимо исправить.
                                |Ознакомьтесь с информацией на форме и нажмите ""Установить новый код"".
                                |После этого повторите синхронизацию (или создайте новую настройку обмена).';
                                |en = 'Duplicate data synchronization settings are detected.
                                |To fix the error, go to the peer infobase.
                                |Open the ""Data synchronization settings"" form.
                                |In the ""More actions"" menu, select ""New predefined node code…"".
                                |Select the exchange plan you want to fix.
                                |Read the information on the form and click ""Set new code"".
                                |Then retry the synchronization (or create a new exchange setting).'; fa = 'Duplicate data synchronization settings are detected.
                                |To fix the error, go to the peer infobase.
                                |Open the ""Data synchronization settings"" form.
                                |In the ""More actions"" menu, select ""New predefined node code…"".
                                |Select the exchange plan you want to fix.
                                |Read the information on the form and click ""Set new code"".
                                |Then retry the synchronization (or create a new exchange setting).';
                                |it = 'È stato rilevato un duplicato delle impostazioni di sincronizzazione dati. 
                                |Per la correzione dell''errore, andare all''infobase corrispondente.
                                |Aprire il modulo ""Impostazioni di sincronizzazione dati"".
                                |Nel menu ""Altro"", selezionare ""Nuove codice di nodo predefinito..."".
                                |Selezionare il piano di scambio da correggere.
                                |Visualizzare le informazioni nel modulo e cliccare su ""Impostare nuovo codice"".
                                |Poi, ripetere la sincronizzazione (oppure creare una nuova impostazione di scambio).';
                                |pl = 'Wykryto duplikowanie ustawień synchronizacji danych.
                                |W celu poprawienia błędu przejdź do odpowiedniej bazy informacyjnej.
                                |Otwórz formularz ""Ustawienia synchronizacji danych"".
                                |W menu ""Więcej"" wybierz ""Nowy kod predefiniowanego węzła..."".
                                |Wybierz plan wymiany, który należy poprawić.
                                |Zapoznaj się z informacją w formularzu i naciśnij ""Ustaw nowy kod"".
                                |Po tym powtórz synchronizację (lub utwórz nowe ustawienie wymiany).';
                                |tr = 'Verilerin senkronizasyonunun yinelenmesi algılandı.
                                |Hatanın onarılması için ilgili bilgi tabanına gidiniz.
                                |""Veri senkronizasyonu ayarları"" formunu açın.
                                |""Daha fazlası"" menüsünde "" Yeni öntanımlı ünite kodu"" seçiniz..."".
                                |Düzeltilmesi gereken değişim planını seçin.
                                |Formdaki bilgileri okuyun ve ""Yeni kod ayarlayın""a tıklayın.
                                |Daha sonra senkronizasyonu tekrarlayın (veya yeni değişim ayarı oluşturun).'");
		
					Raise ExceptionText;
		
				EndIf;	
					
			EndIf;
		Else
			CorrespondentNodeRecoded = True;
		EndIf;
		
		If CorrespondentNodeRecoded Then
			PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(InfobaseNode);
			If ValueIsFilled(PredefinedNodeAlias)
				And DataAnalysisResultToExport.CorrespondentSupportsDataExchangeID Then
				// Probably, it's time to delete the record. Check the "To" section.
				ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
				PredefinedNodeCode = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
				If TrimAll(PredefinedNodeCode) = DataAnalysisResultToExport.To Then
					DataExchangeInternal.DeleteRecordSetFromInformationRegister(
						New Structure("Peer", InfobaseNode),
						"PredefinedNodesAliases");
				EndIf;
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

Parameters = New Structure;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf