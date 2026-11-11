#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Loads the international accounting model from a file
//
// Parameters:
// 	Parameters - Structure - Contains the address of the data to upload:
// 	 * BinaryData - BinaryData - 
// 	StorageAddress - String - Address in temporary storage for placing the result.
//
Procedure ImportAccountingModel(Parameters, StorageAddress) Export
	
	DataProcessor = DataProcessors.UniversalDataExchangeXML.Create();	
	
	TempDataFileName = GetTempFileName("xml");
	Parameters.BinaryData.Write(TempDataFileName);
	
	DataProcessor.ExchangeFileName                        = TempDataFileName;
	DataProcessor.ExchangeMode                           = "Load";
	DataProcessor.RememberImportedObjects          = False;
	DataProcessor.OutputErrorMessagesToProtocol      = True;
	
	ExchangeProtocolTempFileName = GetTempFileName("txt");
	DataProcessor.OutputInfoMessagesToProtocol = False;
	DataProcessor.ExchangeProtocolFileName               = ExchangeProtocolTempFileName;
	
	DataProcessor.ImportDataInExchangeMode               			= True;
	DataProcessor.ImportReferencedObjectsWithoutDeletionMark 			= True;
	DataProcessor.OptimizedObjectsWriting             			= True;
	DataProcessor.RememberImportedObjects               			= True;
	DataProcessor.DontOutputInfoMessagesToUser	= True;
	DataProcessor.OutputInfoMessagesToMessageWindow 			= False;

	SetPrivilegedMode(True);
	DataProcessor.ExecuteImport();
	SetPrivilegedMode(False);
	
	ExchangeProtocol = New TextDocument;
	ExchangeProtocol.Read(ExchangeProtocolTempFileName);
	
	DeleteFiles(ExchangeProtocolTempFileName);
	DeleteFiles(TempDataFileName);
	
	Result = New Structure("ImportIsCompleted", Not DataProcessor.ErrorFlag);
	Result.Insert("ExchangeProtocol", ExchangeProtocol.GetText());
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Uploads the international accounting model to a file
//
// Parameters:
// 	Parameters - Structure - An empty structure. For compatibility with the mechanism for performing long operations
// 	StorageAddress - String - Address in temporary storage for placing the result.
//
Procedure ExportAccountingModel(Parameters, StorageAddress) Export
	
	DataProcessor = DataProcessors.UniversalDataExchangeXML.Create();
	
	ExchangeRulesTempFileName = GetTempFileName("xml");
	TemplateName = SystemSettings.NameOfExchangeRulesForUploadingLoadingInternationalAccountingModel();
	
	ThereAreRules = Metadata.DataProcessors.FinancialAccountingModelExportAndImportWizard.Templates.Find(TemplateName) <> Undefined;
	If Not ThereAreRules Then
		Result = New Structure("ImportIsCompleted", False);
		Result.Insert("ExportFile", Undefined);
		ErrorTemplate = NStr("vi = 'Thiếu biểu mẫu của các quy tắc trao đổi: %1';
							|ru = 'Отсутствует макет правил обмена: %1';
							|en = 'Missing exchange rules template: %1'; fa = 'Missing exchange rules template: %1';
							|it = 'Modello delle regole di scambio mancante: %1';
							|pl = 'Brak makiety warunków wymiany: %1';
							|tr = 'Değişim kurallarının düzeni eksik: %1'");
		ErrorText = StrTemplate(
					ErrorTemplate, "DataProcessors.FinancialAccountingModelExportAndImportWizard.Templates." + TemplateName);
		Result.Insert("ExchangeProtocol", ErrorText);
		PutToTempStorage(Result, StorageAddress);
		Return;
	EndIf;
	
	ExchangeRuleTemplate = DataProcessors.FinancialAccountingModelExportAndImportWizard.GetTemplate(TemplateName);
	ExchangeRuleTemplate.Write(ExchangeRulesTempFileName);
	
	DataProcessor.ExchangeRulesFileName = ExchangeRulesTempFileName;
	DataProcessor.ImportExchangeRules();
	
	ExchangeProtocolTempFileName = GetTempFileName("txt");
	DataProcessor.OutputInfoMessagesToProtocol = False;
	DataProcessor.ExchangeProtocolFileName               = ExchangeProtocolTempFileName;
	
	UploadFileName = GetTempFileName("xml");
	DataProcessor.ExchangeFileName = UploadFileName;
	DataProcessor.ExchangeMode    = "Upload0";
	DataProcessor.DontOutputInfoMessagesToUser = True;
	
	SetPrivilegedMode(True);
	DataProcessor.ExecuteExport();
	SetPrivilegedMode(False);
	
	ExchangeProtocol = New TextDocument;
	ExchangeProtocol.Read(ExchangeProtocolTempFileName);
	
	BinaryData = New BinaryData(UploadFileName);
	
	Result = New Structure("ImportIsCompleted", Not DataProcessor.ErrorFlag);
	Result.Insert("ExportFile", BinaryData);
	Result.Insert("ExchangeProtocol", ExchangeProtocol.GetText());
	PutToTempStorage(Result, StorageAddress);
	
	DeleteFiles(ExchangeProtocolTempFileName);
	DeleteFiles(ExchangeRulesTempFileName);
	DeleteFiles(UploadFileName);
	
EndProcedure

#EndRegion

#EndIf