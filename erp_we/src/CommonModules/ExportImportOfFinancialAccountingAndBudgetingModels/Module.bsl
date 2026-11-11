
#Region Public

// Unload the model completely.
// 
// Parameters:
//  FileNameAtServer - String - The name of the file on the server
Procedure UnloadMFPModelCompletely(FileNameAtServer) Export

	UploadData_0 = UnloadingDataTable();
	
	Selection = Catalogs.FinancialAccountingChartsOfAccounts.Select();
	PlansOfAccountsOfInternationalAccountingForUnloading = New Array();
	While Selection.Next() Do
		PlansOfAccountsOfInternationalAccountingForUnloading.Add(Selection.Ref);
	EndDo;
	If PlansOfAccountsOfInternationalAccountingForUnloading.Count() Then
		MetadataObjectsList = Metadata.Catalogs.FinancialAccountingChartsOfAccounts;
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, PlansOfAccountsOfInternationalAccountingForUnloading);
		
		MetadataObjectsList = Metadata.ChartsOfAccounts.International;
		AddRowToUploadData(UploadData_0,
									MetadataObjectsList,
									Undefined,
									PlansOfAccountsOfInternationalAccountingForUnloading,
									Metadata.ChartsOfAccounts.International.Attributes.ChartOfAccounts.Name);
		
		If UploadData_0.Find(MetadataObjectsList.FullName(), "MDName") <> Undefined Then
			MetadataObjectsList = Metadata.ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes;
			AddRowToUploadData(UploadData_0, MetadataObjectsList);
		EndIf;
	EndIf;
	
	Selection = Catalogs.FinancialReportTypes.Select();
	TypesOfFinancialReportsToUpload = New Array();
	While Selection.Next() Do
		TypesOfFinancialReportsToUpload.Add(Selection.Ref);
	EndDo;
	If TypesOfFinancialReportsToUpload.Count() Then
		MetadataObjectsList = Metadata.Catalogs.FinancialReportTypes;
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, TypesOfFinancialReportsToUpload);
		
		MetadataObjectsList = Metadata.Catalogs.FinancialReportItems;
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, TypesOfFinancialReportsToUpload, "Owner");
	EndIf;
	
	Selection = Catalogs.FinancialReportSets.Select();
	SetsOfFinancialReportsToBeUploaded = New Array();
	While Selection.Next() Do
		SetsOfFinancialReportsToBeUploaded.Add(Selection.Ref);
	EndDo;
	If SetsOfFinancialReportsToBeUploaded.Count() Then
		MetadataObjectsList = Metadata.Catalogs.FinancialReportSets;
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SetsOfFinancialReportsToBeUploaded);
	EndIf;
	
	Selection = ChartsOfCharacteristicTypes.AssetLiabilityItems.Select();
	ItemsOfAssetsLiabilitiesToBeUnloaded = New Array();
	While Selection.Next() Do
		ItemsOfAssetsLiabilitiesToBeUnloaded.Add(Selection.Ref);
	EndDo;
	If ItemsOfAssetsLiabilitiesToBeUnloaded.Count() Then
		MetadataObjectsList = Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems;
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, ItemsOfAssetsLiabilitiesToBeUnloaded);
	EndIf;
	
	Selection = Catalogs.FinancialAccountingPostingGenerationSetting.Select();
	SettingsForGeneratingTransactionsForUploading = New Array();
	While Selection.Next() Do
		SettingsForGeneratingTransactionsForUploading.Add(Selection.Ref);
	EndDo;
	If SettingsForGeneratingTransactionsForUploading.Count() Then
		MDSelectionObject = Metadata.Catalogs.FinancialAccountingPostingGenerationSetting;
		AddRowToUploadData(UploadData_0, MDSelectionObject, Undefined, SettingsForGeneratingTransactionsForUploading);
		
		MetadataObjectsList = Metadata.InformationRegisters.RulesOfPostingsInFinancialAccounting;
		NameOfTheDimensionToSelect = NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SettingsForGeneratingTransactionsForUploading, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.BusinessTransactionsNotPostedInFinancialAccounting;
		NameOfTheDimensionToSelect = NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SettingsForGeneratingTransactionsForUploading, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting;
		NameOfTheDimensionToSelect = NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SettingsForGeneratingTransactionsForUploading, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.SettingsOfFinancialAccountingAccountsByObject;
		NameOfTheDimensionToSelect = NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SettingsForGeneratingTransactionsForUploading, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.SettingsForFillingExtraDimensionOnFinancialAccountingAccounts;
		NameOfTheDimensionToSelect = NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SettingsForGeneratingTransactionsForUploading, NameOfTheDimensionToSelect);
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	RulesOfPostingsInFinancialAccounting.PostingTemplate AS PostingTemplate
			|FROM
			|	InformationRegister.RulesOfPostingsInFinancialAccounting AS RulesOfPostingsInFinancialAccounting
			|WHERE
			|	RulesOfPostingsInFinancialAccounting.PostingGenerationSetting IN (&PostingGenerationSetting)";
		Query.SetParameter("PostingGenerationSetting", SettingsForGeneratingTransactionsForUploading);
		TemplatesOfTransactionsToBeUploaded = Query.Execute().Unload().UnloadColumn("PostingTemplate");
		
		MDSelectionObject = Metadata.Catalogs.PostingTemplatesForFinancialAccounting;
		AddRowToUploadData(UploadData_0, MDSelectionObject, Undefined, TemplatesOfTransactionsToBeUploaded);
		
		MetadataObjectsList = Metadata.InformationRegisters.RulesOfSpecifyingAccountsFinancialAccounting;
		NameOfTheDimensionToSelect = NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, TemplatesOfTransactionsToBeUploaded, NameOfTheDimensionToSelect);
	EndIf;
	
	Selection = Catalogs.StandardTransactionsOfFinancialAccounting.Select();
	TypicalOperationsInternationalAccountingForUnloading = New Array();
	While Selection.Next() Do
		TypicalOperationsInternationalAccountingForUnloading.Add(Selection.Ref);
	EndDo;
	If TypicalOperationsInternationalAccountingForUnloading.Count() Then
		MetadataObjectsList = Metadata.Catalogs.StandardTransactionsOfFinancialAccounting;
		AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, TypicalOperationsInternationalAccountingForUnloading);
	EndIf;
	
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.FinancialAccountingGroupsOfARAP);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.GroupsOfFinancialAccountingOfCash);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.IncomeExpensesAccountingGroups);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.InventoryAccountingGroups);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.CashFlowReportItems);
	AddRowToUploadData(UploadData_0, Metadata.ChartsOfCharacteristicTypes.IncomeItems);
	AddRowToUploadData(UploadData_0, Metadata.ChartsOfCharacteristicTypes.ExpenseItems);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.IntangibleAssetsGroups);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.FixedAssetsGroupsFinancialAccounting);
	AddRowToUploadData(UploadData_0, Metadata.Catalogs.NonMonetaryItems);

	Parameters = New Structure;
	Parameters.Insert("UploadData_0", UploadData_0);
	Parameters.Insert("ThisIsInternationalAccountingModel", True);
	
	ExportAccountingModel(Parameters, FileNameAtServer)

EndProcedure

// Loads the international accounting model from a file
//
// Parameters:
// 	Parameters - Structure - Contains the address of the data to upload:
// 	 * BinaryData - BinaryData - 
//
Procedure ImportAccountingModel(Parameters) Export
	
	TypeOfLoadedModel = ModelType(Parameters);
	
	If Parameters.Property("ThisIsBudgetingModel") And Parameters.ThisIsBudgetingModel Then
		ThisIsBudgetingModel = True;
	Else
		ThisIsBudgetingModel = False;
	EndIf;
	
	TempDataFileName = GetTempFileName("xml");
	Parameters.BinaryData.Write(TempDataFileName);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(TempDataFileName);
	// checking the exchange file format
	If Not XMLReader.Read()
		Or XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "_1CV8DtUD"
		Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then
		
		ErrorDescription = NStr("vi = 'Sai định dạng tệp kết nhập';
								|ru = 'Неверный формат файла загрузки';
								|en = 'Incorrect import file format'; fa = 'Incorrect import file format';
								|it = 'Formato non valido del file di download';
								|pl = 'Niepoprawny format pliku importu';
								|tr = 'Yükleme dosyasının yanlış formatı'");
		Raise ErrorDescription;
		
	EndIf;
	
	VersionDetails = Metadata.Name + " " + Metadata.Version;
	If XMLReader.AttributeValue("Version") <> VersionDetails Then
		
		ErrorDescription = NStr("vi = 'Phiên bản cấu hình kết xuất mô hình không trùng với phiên bản cấu hình hiện tại';
								|ru = 'Версия конфигурации выгрузки модели не совпадает с текущей версией конфигурации';
								|en = 'The version of the model export configuration does not match the current configuration version'; fa = 'The version of the model export configuration does not match the current configuration version';
								|it = 'Версия конфигурации выгрузки модели не совпадает с текущей версией конфигурации';
								|pl = 'The version of the model export configuration does not match the current configuration version';
								|tr = 'Model yüklemesinin konfigürasyon sürümü geçerli konfigürasyon sürümüyle eşleşmemektedir'");
		Raise ErrorDescription;
		
	EndIf;
	
	If XMLReader.AttributeValue("ModelType") <> TypeOfLoadedModel Then
		
		ErrorDescription = NStr("vi = 'Sai kiểu mô hình kết nhập';
								|ru = 'Неверный тип загружаемой модели';
								|en = 'Incorrect type of model to import'; fa = 'Incorrect type of model to import';
								|it = 'Tipo non valido di modello scaricabile';
								|pl = 'Niepoprawny typ importowanego modelu';
								|tr = 'Yanlış tipte yüklenen model'");
		Raise ErrorDescription;
		
	EndIf;

	If Not XMLReader.Read()
		Or XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "Data" Then
		
		ErrorDescription = NStr("vi = 'Sai định dạng tệp kết xuất';
								|ru = 'Неверный формат файла выгрузки';
								|en = 'Incorrect export file format'; fa = 'Incorrect export file format';
								|it = 'Formato non valido del file di upload';
								|pl = 'Niepoprawny format pliku eksportu';
								|tr = 'Dışa aktarım dosyası formatı yanlış'");
		Raise ErrorDescription;
		
	EndIf;
	
	NotRecordedUIN = New Array;
	If ThisIsBudgetingModel Then
		ProcessPredefinedData(XMLReader, Parameters.ReplaceableUIN, NotRecordedUIN);
		ReplaceRefsInFile(TempDataFileName, Parameters.ReplaceableUIN);
		
		For Each String In Parameters.ReplaceDimensionValues Do
			NotRecordedUIN.Add(XMLString(String.Dimensiondb));
		EndDo;
			
		For Each String In Parameters.ReplaceableUIN Do
			If Parameters.DownloadableUIN.Find(String.ReplacementLink) = Undefined Then
				NotRecordedUIN.Add(String.ReplacementLink);
			EndIf;
		EndDo;
	Else
		TableOfReplacedUINs = TableOfReplacedUINs();//ValueTable
		ProcessPredefinedData(XMLReader, TableOfReplacedUINs, NotRecordedUIN);
		ReplaceRefsInFile(TempDataFileName, TableOfReplacedUINs);
	EndIf;
	
	XMLReader.OpenFile(TempDataFileName);
	XMLReader.Read();
	XMLReader.Read();
	
	// reading and writing to the IB of objects recorded in the upload
	If Not XMLReader.Read() Then 
		
		ErrorDescription = NStr("vi = 'Vi phạm định dạng tệp sau khi thay thế tham chiếu định trước';
								|ru = 'Нарушен формат файла после замены предопределенных ссылок';
								|en = 'File format is violated after replacing predefined links'; fa = 'File format is violated after replacing predefined links';
								|it = 'Formato file violato dopo la sostituzione dei collegamenti predefiniti';
								|pl = 'Format pliku został naruszony po zmianie predefiniowanych odnośników';
								|tr = 'Önceden tanımlanmış bağlantıları değiştirdikten sonra dosya formatı bozuldu'");
		Raise ErrorDescription;
		
	EndIf;
	
	Serializer = XdtoSerializerWithTypeAnnotation();
	
	DataSeparationEnabled = False;
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		ModuleSaaSOperationsCached = Common.CommonModule("SaaSOperationsCached");
		ApplicationMigrationModuleCached = Common.CommonModule("ApplicationsMigrationCached");
		
		DataSeparationEnabled = ModuleSaaSOperationsCached.DataSeparationEnabled();
		If DataSeparationEnabled Then
			SeparatedMetadataObjects = ApplicationMigrationModuleCached.AreaDataModel();
		EndIf;
	EndIf;
	
	BeginTransaction();
	Try
		
		If ThisIsBudgetingModel Then
			SelectedBudgetTypes = Parameters.SelectedBudgetTypes;
			For Each SelectedBudgetProfile In SelectedBudgetTypes Do
				
				ReplacementString = Parameters.ReplaceableUIN.Find(SelectedBudgetProfile, "SearchRef");
				If ReplacementString = Undefined Then
					UINBudgetProfile = SelectedBudgetProfile;
				Else
					UINBudgetProfile = ReplacementString.ReplacementLink;
				EndIf;
				
				BudgetProfileUID = New UUID(UINBudgetProfile);
				BudgetTypeFound = Catalogs.BudgetProfiles.GetRef(BudgetProfileUID);
				If ValueIsFilled(Common.ObjectAttributeValue(BudgetTypeFound, "Description")) Then
					//@skip-check query-in-loop - it is necessary for each type of budget before recording
					DeleteFinancialReportItems(BudgetTypeFound);
				
					RecordSet = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
					RecordSet.Filter.BudgetProfile.Set(BudgetTypeFound);
					RecordSet.Write(True);
				EndIf;
			EndDo;
		EndIf;
			
		While Serializer.CanReadXML(XMLReader) Do
			
			TypeOfObjectToUpload = XMLReader.LocalName;
			
			Recorded_Value = Serializer.ReadXML(XMLReader); //CatalogObject
			Recorded_Value.DataExchange.Load = True;
			
			If DataSeparationEnabled Then
				If SeparatedMetadataObjects[Recorded_Value.Metadata()] = Undefined Then
					Continue;
				EndIf;
			EndIf;

			If TMCommonUseClientServer.HasObjectAttribute(Recorded_Value, "Ref") Then
				
				If Recorded_Value.IsNew() Then
					XMLStringYouAreLookingFor = XMLString(Recorded_Value.GetNewObjectRef());
				Else
					XMLStringYouAreLookingFor = XMLString(Recorded_Value.Ref);
				EndIf;

				FoundRow = NotRecordedUIN.Find(XMLStringYouAreLookingFor);
				If FoundRow <> Undefined Then
					Continue;
				EndIf;
			
			EndIf;
			
			Write = True;
			If ThisIsBudgetingModel Then
				If StrFind(TypeOfObjectToUpload, "InformationRegisterRecordSet") <> 0 Then
					For Each Filter In Recorded_Value.Filter Do
						If Parameters.DownloadableUIN.Find(XMLString(Filter.Value)) = Undefined Then
							Write = False;
							Break;
						EndIf;
					EndDo;
				Else
					If Recorded_Value.IsNew() Then
						XMLStringYouAreLookingFor = XMLString(Recorded_Value.GetNewObjectRef());
					Else
						XMLStringYouAreLookingFor = XMLString(Recorded_Value.Ref);
					EndIf;
					If Parameters.DownloadableUIN.Find(XMLStringYouAreLookingFor) = Undefined Then
						Write = False;
					EndIf;
					If Write And Not IsBlankString(Recorded_Value.Code) And Not Parameters.UseSourceCodesOfDownloadedData Then
						If Recorded_Value.IsNew() Then
							Recorded_Value.SetNewCode();
						Else
							Recorded_Value.Code = Common.ObjectAttributeValue(Recorded_Value.Ref, "Code");
						EndIf;
					EndIf;
				EndIf;
				
				If Write Then
					If TypeOf(Recorded_Value) = Type("CatalogObject.FinancialReportItems") Then
						StorageAttributes = Recorded_Value.AdditionalSelection;
						ReplacingLinksInCDSettings(StorageAttributes, Parameters);
						Recorded_Value.AdditionalSelection = StorageAttributes;
					ElsIf TypeOf(Recorded_Value) = Type("CatalogObject.ActualDataQueryRulesByBudgetBalanceItems")
						Or TypeOf(Recorded_Value) = Type("CatalogObject.ActualDataQueryRulesByBudgetFlowItems") Then
							StorageAttributes = Recorded_Value.SettingsComposer;
							ReplacingLinksInCDSettings(StorageAttributes, Parameters);
							Recorded_Value.SettingsComposer = StorageAttributes;
					ElsIf TypeOf(Recorded_Value) = Type("CatalogObject.NonFinancialItemProfiles") Then
						For Each Page1 In Recorded_Value.TemplateIndicators Do
							StorageAttributes = Page1.StorageOfDataCompositionSettings;
							ReplacingLinksInCDSettings(StorageAttributes, Parameters);
							Page1.StorageOfDataCompositionSettings = StorageAttributes;
						EndDo;
					ElsIf TypeOf(Recorded_Value) = Type("CatalogObject.RuleForCalculatingRelatedBudgetBalancesAndTurnovers") Then
						StorageAttributes = Recorded_Value.RequestStorage;
						ReplacingLinksInCDSettings(StorageAttributes, Parameters);
						Recorded_Value.RequestStorage = StorageAttributes;
						For Each Page1 In Recorded_Value.DataCalculationSettings Do
							StorageAttributes = Page1.SettingsComposer;
							ReplacingLinksInCDSettings(StorageAttributes, Parameters);
							Page1.SettingsComposer = StorageAttributes;
							StorageAttributes = Page1.StorageOfDataCompositionSchema;
							ReplacingLinksInCDSettings(StorageAttributes, Parameters);
							Page1.StorageOfDataCompositionSchema = StorageAttributes;
							StorageAttributes = Page1.StorageOfDataCompositionSettings;
							ReplacingLinksInCDSettings(StorageAttributes, Parameters);
							Page1.StorageOfDataCompositionSettings = StorageAttributes;
						EndDo;
					EndIf;
				EndIf;
				
			EndIf;
			
			If Write Then
				
				Recorded_Value.Write();
				
				If TypeOf(Recorded_Value) = Type("CatalogObject.BudgetProfiles") Then
					RecordSet = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
					RecordSet.Filter.BudgetProfile.Set(Recorded_Value.Ref);
					RecordSet.Write(True);
				EndIf;
				
			EndIf;
			
		EndDo;
		
		// checking the exchange file format
		If XMLReader.NodeType <> XMLNodeType.EndElement
			Or XMLReader.LocalName <> "Data" Then
			
			ErrorDescription = NStr("vi = 'Sai định dạng tệp kết xuất';
									|ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format'; fa = 'Incorrect export file format';
									|it = 'Formato non valido del file di upload';
									|pl = 'Niepoprawny format pliku eksportu';
									|tr = 'Dışa aktarım dosyası formatı yanlış'");
			Raise ErrorDescription;
			
		EndIf;
		
		If Not XMLReader.Read()
			Or XMLReader.NodeType <> XMLNodeType.StartElement
			Or XMLReader.LocalName <> "PredefinedData" Then
			
			ErrorDescription = NStr("vi = 'Sai định dạng tệp kết xuất';
									|ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format'; fa = 'Incorrect export file format';
									|it = 'Formato non valido del file di upload';
									|pl = 'Niepoprawny format pliku eksportu';
									|tr = 'Dışa aktarım dosyası formatı yanlış'");
			Raise ErrorDescription;
			
		EndIf;
		
		XMLReader.Skip();
		
		If ThisIsBudgetingModel Then
			XMLReader.Skip();
			XMLReader.Skip();
		EndIf;
		
		If Not XMLReader.Read()
			Or XMLReader.NodeType <> XMLNodeType.EndElement
			Or XMLReader.LocalName <> "_1CV8DtUD"
			Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then
			
			ErrorDescription = NStr("vi = 'Sai định dạng tệp kết xuất';
									|ru = 'Неверный формат файла выгрузки';
									|en = 'Incorrect export file format'; fa = 'Incorrect export file format';
									|it = 'Formato non valido del file di upload';
									|pl = 'Niepoprawny format pliku eksportu';
									|tr = 'Dışa aktarım dosyası formatı yanlış'");
			Raise ErrorDescription;
			
		EndIf;
		
		XMLReader.Close();
		DeleteFiles(TempDataFileName);
		
		If Parameters.Property("ThisIsInternationalAccountingModel") And Parameters.ThisIsInternationalAccountingModel Then
			
			ProcessFunctionalOptions();
			
			ResultStructure1 = New Structure();
			PutToTempStorage(ResultStructure1, Parameters.ResultAddress);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		XMLReader.Close();
		DeleteFiles(TempDataFileName);
		
		ArrayOfErrorLines = New Array;
		ArrayOfErrorLines.Add(NStr("vi = 'Có thể, cấu trúc dữ liệu đã kết nhập không tương ứng với cấu hình, hãy kiểm tra tính khả dụng của tệp dữ liệu';
									|ru = 'Возможно структура загружаемых данных не соответствует конфигурации, проверьте актуальность файла данных';
									|en = 'Structure of the data to import might not correspond to the application. Check the data file relevance'; fa = 'Structure of the data to import might not correspond to the application. Check the data file relevance';
									|it = 'Probabilmente la struttura di dati caricati non è conforme alla configurazione, controllare che il file dati sia aggiornato';
									|pl = 'Możliwe, że struktura pobieranych danychi nie jest zgodna z konfiguracją, sprawdź aktualność pliku danych';
									|tr = 'İndirilen verilerin yapısı konfigürasyon ile uyuşmuyor olabilir, veri dosyasının ilgi düzeyini kontrol et'"));
		ArrayOfErrorLines.Add(ErrorDescription());
		ErrorText = StrConcat(ArrayOfErrorLines, Chars.LF);
		
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

// Uploads the international accounting model to a file
//
// Parameters:
// 	Parameters - Structure - parameter structure
// 	FileNameAtServer - String - The name of the file on the server
//
Procedure ExportAccountingModel(Parameters, FileNameAtServer = Undefined) Export
	
	TypeOfModelToBeUploaded = ModelType(Parameters);
	If Parameters.Property("ThisIsBudgetingModel") And Parameters.ThisIsBudgetingModel Then
		ThisIsBudgetingModel = True;
	Else
		ThisIsBudgetingModel = False;
	EndIf;
	
	If FileNameAtServer = Undefined Then
		FileName = GetTempFileName("xml");
	Else
		FileName = FileNameAtServer;
	EndIf;
	
	ExportComposition = ExportComposition(Parameters.UploadData_0);
	
	If ExportComposition.Count() = 0 Then
		
		ErrorDescription = NStr("vi = 'Chưa đặt thành phần kết xuất';
								|ru = 'Не задан состав выгрузки';
								|en = 'Export is not specified'; fa = 'Export is not specified';
								|it = 'Composizione upload non indicata';
								|pl = 'Nie określono składu eksportu';
								|tr = 'Dışa aktarım içeriği belirtilmedi'");
		Raise ErrorDescription;
		
	EndIf;
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(FileName, "UTF-8");
		
	XMLWriter.WriteXMLDeclaration();	
	XMLWriter.WriteStartElement("_1CV8DtUD", "http://www.1c.ru/V8/1CV8DtUD/");
	XMLWriter.WriteNamespaceMapping("V8Exch", "http://www.1c.ru/V8/1CV8DtUD/");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("core", "http://v8.1c.ru/data");
	
	XMLWriter.WriteNamespaceMapping("v8", "http://v8.1c.ru/8.1/data/enterprise/current-config");
	XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");
	
	XMLWriter.WriteAttribute("Version", Metadata.Name + " " + Metadata.Version);
	XMLWriter.WriteAttribute("ModelType", TypeOfModelToBeUploaded);

	XMLWriter.WriteStartElement("Data");
	
	Serializer = XdtoSerializerWithTypeAnnotation();
	PredefinedDataTable = PredefinedDataTable1();
	FilteringTable = FilteringTable();

	DataExport(Serializer, XMLWriter, ExportComposition, PredefinedDataTable, FilteringTable, ThisIsBudgetingModel);
	
	FilteringTable.GroupBy("TableName, Ref, OwnerRef, PresentationRef, PresentationLinkOwner");
	
	XMLWriter.WriteEndElement(); //V8Exc:Data
	ExportPredefinedItemsTable(PredefinedDataTable, XMLWriter);
	
	If ThisIsBudgetingModel Then
		UploadFilteringTable(FilteringTable, XMLWriter);
	EndIf;
	
	XMLWriter.WriteEndElement(); //V8Exc:_1CV8DtUD 
	
	XMLWriter.Close();
	
	If FileNameAtServer = Undefined Then
		BinaryData = New BinaryData(FileName);
		PutToTempStorage(BinaryData, Parameters.StorageAddress);
	
		DeleteFiles(FileName);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// The data table is ready to be uploaded.
// 
// Returns:
//  ValueTable - LongDesc:
//   * MetadataObjectsList - MetadataObject - metadata object to upload
//   * QueryResult - QueryResult - result of the link upload request
//
Function UnloadingDataTable() Export
	
	UploadData_0 = New ValueTable;
	UploadData_0.Columns.Add("MDName");
	UploadData_0.Columns.Add("QueryText");
	UploadData_0.Columns.Add("Owner"); 
	UploadData_0.Columns.Add("FilterArray"); 
	UploadData_0.Columns.Add("FilterField"); 
	
	Return UploadData_0;
	
EndFunction

// Adds a row to the upload data, taking into account the selection.
// 
// Parameters:
//  UploadData_0 - ValueTable - Upload data:
//   * MetadataObjectsList - MetadataObject - metadata object to upload
//   * QueryResult - QueryResult - result of the link upload request
//  MetadataObjectsList - MetadataObjectCatalog, MetadataObjectChartOfCharacteristicTypes, MetadataObjectInformationRegister, MetadataObjectChartOfAccounts - MD object
//  Owner - AnyRef - Link to the owner of the upload filter
//  FilterByRefs - Undefined, Array of AnyRef - Selection by links
//  FilterField - String - Selection field for selection
Procedure AddRowToUploadData(UploadData_0, MetadataObjectsList, Owner = Undefined, FilterByRefs = Undefined, FilterField = "") Export
	
	ThereIsSelectionByLinks = FilterByRefs <> Undefined;
	
	QueryText = GetQueryText(MetadataObjectsList, ThereIsSelectionByLinks, FilterField);
	
	NewRow = UploadData_0.Add();
	NewRow.MDName = MetadataObjectsList.FullName();
	NewRow.QueryText = QueryText;
	NewRow.Owner = Owner;
	NewRow.FilterArray = FilterByRefs;
	NewRow.FilterField = FilterField;
	
EndProcedure

// Gets the name of the dimension to be selected in the register
// 
// Parameters:
//  MDSelectionObject - MetadataObject - The metadata object in which we are looking for the type
//  MetadataObjectsList - MetadataObject - Search Metadata Object
// 
// Returns:
//  String - Name of the dimension to select
//
Function NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList) Export
	
	ObjectManager = Common.ObjectManagerByFullName(MDSelectionObject.FullName());
	SearchableType = TypeOf(ObjectManager.GetRef());
		
	MeasurementsOfMDObject = MetadataObjectsList.Dimensions;
	For Each Dimension In MeasurementsOfMDObject Do
		If Dimension.Type.ContainsType(SearchableType) Then
			Return Dimension.Name;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion

#Region Private

Function ModelType(Parameters)
	
	ModelType = "";
	
	If Parameters.Property("ThisIsBudgetingModel") And Parameters.ThisIsBudgetingModel Then
		ModelType = "Budgeting Model";
	ElsIf Parameters.Property("ThisIsInternationalAccountingModel") And Parameters.ThisIsInternationalAccountingModel Then
		ModelType = "International Accounting Model";
	Else 
		ErrorDescription = NStr("vi = 'Chưa xác định kiểu mô hình';
								|ru = 'Не определен тип модели';
								|en = 'Model type is not determined'; fa = 'Model type is not determined';
								|it = 'Tipo di modello non indicato';
								|pl = 'Nie określono typu modelu';
								|tr = 'Model tipi tanımlanmadı'");
		Raise ErrorDescription;
	EndIf;
	
	Return ModelType;
	
EndFunction

Function TypesOfBudgetingAnalytics()
	
	TypesOfDimensions = BudgetingServer.AllTypesOfAnalytics().Types();
	
	TypesOfDimensions.Add(Type("CatalogRef.SalesOperationsPlanningScenarios"));
	TypesOfDimensions.Add(Type("CatalogRef.PlanProfiles"));
	
	Return TypesOfDimensions;
	
EndFunction

Procedure DataExport(Serializer, XMLWriter, ExportComposition, PredefinedDataTable, FilteringTable, ThisIsBudgetingModel)
	
	ExportedObjects = New ValueTable;
	ExportedObjects.Columns.Add("Ref");
	ExportedObjects.Indexes.Add("Ref");
	
	TypesOfBudgetingAnalytics = TypesOfBudgetingAnalytics();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ThisIsBudgetingModel", ThisIsBudgetingModel);
	AdditionalParameters.Insert("PredefinedDataTable", PredefinedDataTable);
	AdditionalParameters.Insert("ExportedObjects", ExportedObjects);
	AdditionalParameters.Insert("FilteringTable", FilteringTable);
	AdditionalParameters.Insert("TypesOfBudgetingAnalytics", TypesOfBudgetingAnalytics);
	
	Try
		
		For Each ExportString In ExportComposition Do
			
			If Common.ObjectManagerByFullName(ExportString.MetadataObjectsList.FullName()) = Undefined Then
				ErrorDescription = NStr("vi = 'Kết xuất dữ liệu. Lỗi nội bộ';
										|ru = 'Выгрузка данных. Внутренняя ошибка';
										|en = 'Data export. Internal error'; fa = 'Data export. Internal error';
										|it = 'Upload dati. Errore interno';
										|pl = 'Eksport danych. Błąd wewnętrzny';
										|tr = 'Veriler dışa aktarılıyor. Dahili hata'");
				Raise ErrorDescription;
			EndIf;
			
			If Metadata.InformationRegisters.Contains(ExportString.MetadataObjectsList) Then
				RegisterRecord(ExportString, Serializer, XMLWriter, AdditionalParameters);
			Else
				WritingObjectTypeData(ExportString, Serializer, XMLWriter, AdditionalParameters);
			EndIf;
		
		EndDo;
		
	Except
		Raise;
	EndTry;
	
EndProcedure

Procedure WritingObjectTypeData(ExportString, Serializer, XMLWriter, AdditionalParameters)
	RequestAndRecord(ExportString.QueryResult, ExportString.Owner, Serializer, XMLWriter, AdditionalParameters);
EndProcedure

Procedure RequestAndRecord(QueryResult, Owner, Serializer, XMLWriter, AdditionalParameters)
	QueryResultProcessing(QueryResult, Owner, Serializer, XMLWriter, True, AdditionalParameters);
EndProcedure

Procedure QueryResultProcessing(QueryResult, Owner, Serializer, XMLWriter, ThisIsRequestForObject, AdditionalParameters)
	
	ThisIsBudgetingModel = AdditionalParameters.ThisIsBudgetingModel;
	PredefinedDataTable = AdditionalParameters.PredefinedDataTable;
	ExportedObjects = AdditionalParameters.ExportedObjects;
	FilteringTable = AdditionalParameters.FilteringTable;
	TypesOfBudgetingAnalytics = AdditionalParameters.TypesOfBudgetingAnalytics;
	
	SamplingFromQueryResults = QueryResult.Select(); 
	While SamplingFromQueryResults.Next() Do
		
		If ThisIsRequestForObject Then
			
			// Unloading reference objects
			Ref = SamplingFromQueryResults.Ref;
			Object = Ref.GetObject();
			ObjectMetadata = Object.Metadata();
			
			If ThisIsBudgetingModel Then
				AddRowToFilteringTable(FilteringTable, ObjectMetadata.FullName(), Ref, Owner); //Object metadata.Fullname()
			EndIf;
			
			If LinkUnloaded(ExportedObjects, Ref) Then
				Continue;
			EndIf;
			
			AddLinkToUploaded(ExportedObjects, Ref);
			
		EndIf;
		
		If ThisIsBudgetingModel And TypesOfBudgetingAnalytics.Find(TypeOf(Ref)) = Undefined Then
			
			// We are going through the columns of the query in search of reference values that may need to be unloaded
			For Each QueryColumn In QueryResult.Columns Do
				
				ColumnValue = SamplingFromQueryResults[QueryColumn.Name];
				If TypeOf(ColumnValue) = Type("QueryResult") Then
					//@skip-check query-in-loop - fetching reference data for recording required for referential integrity
					QueryResultProcessing(ColumnValue, Owner, Serializer, XMLWriter, False, AdditionalParameters);
				Else
					If TypeOf(ColumnValue) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo") Then
						Continue;
					EndIf;
					//@skip-check query-in-loop - record data required for referential integrity
					WriteValueIfNecessary(ColumnValue, Owner, Serializer, XMLWriter, AdditionalParameters);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If ThisIsRequestForObject Then
			
			Object = Ref.GetObject();
			
			Try
				
				Serializer.WriteXML(XMLWriter, Object);
				
				ObjectMetadata = Object.Metadata();
				
				If ThisIsMetadataWithPredefinedElements(ObjectMetadata) And Object.Predefined Then
					
					AddPredefinedTableRow(
							PredefinedDataTable,
							ObjectMetadata.FullName(),
							XMLString(Ref),
							"PredefinedDataName",
							Object.PredefinedDataName);
					
				ElsIf TypeOf(Object) = Type("CatalogObject.Currencies") Then
					
					AddPredefinedTableRow(
							PredefinedDataTable,
							ObjectMetadata.FullName(),
							XMLString(Ref),
							Object.Metadata().StandardAttributes.Code.Name,
							Object.Code);
				
				ElsIf TypeOf(Object) = Type("CatalogObject.MetadataObjectIDs") Then
					
					AddPredefinedTableRow(
							PredefinedDataTable,
							ObjectMetadata.FullName(),
							XMLString(Ref),
							Object.Metadata().StandardAttributes.Description.Name,
							Object.Description);
					
				EndIf;

			Except
				
				ErrorTemplate = NStr("vi = 'Khi kết xuất đối tượng %1(%2) đã xảy ra lỗi: |%3';
									|ru = 'При выгрузке объекта %1(%2) возникла ошибка: |%3';
									|en = 'An error occurred when exporting the %1(%2) object: |%3'; fa = 'An error occurred when exporting the %1(%2) object: |%3';
									|it = 'Durante l''upload dell''oggetto %1(%2) si è verificato un errore: |%3';
									|pl = 'Podczas eksportu obiektu %1(%2) wystąpił błąd: |%3';
									|tr = '%1(%2) nesnesinin dışa aktarımı sırasında  hata oluştu: |%3'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Object, TypeOf(Object), ErrorDescription());
				Raise ErrorText;
				
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteValueIfNecessary(AnalyzedValue, Owner, Serializer, XMLWriter, AdditionalParameters)
	
	ThisIsBudgetingModel = AdditionalParameters.ThisIsBudgetingModel;
	ExportedObjects = AdditionalParameters.ExportedObjects;
	FilteringTable = AdditionalParameters.FilteringTable;
	TypesOfBudgetingAnalytics = AdditionalParameters.TypesOfBudgetingAnalytics;
	
	If Not ValueIsFilled(AnalyzedValue) Then
		Return;
	EndIf;
	
	ValueType = TypeOf(AnalyzedValue);
	
	If ValueType = Type("ValueStorage") Then
		UploadingLinksFromCDSettings(AnalyzedValue, Owner, Serializer, XMLWriter, AdditionalParameters);
	EndIf;
	
	If Not Common.IsReference(ValueType) Then
		Return; // this is not a link
	EndIf;
	
	MetadataObjectsList = Metadata.FindByType(ValueType);
	
	If Common.IsEnum(MetadataObjectsList) Then
		Return; // this is an enumeration
	EndIf;
	
	If LinkUnloaded(ExportedObjects, AnalyzedValue) Then
		Return; // the object has already been unloaded
	EndIf;
	
	If ThisIsBudgetingModel And TypesOfBudgetingAnalytics.Find(TypeOf(AnalyzedValue)) <> Undefined Then
		
		AddRowToFilteringTable(FilteringTable, MetadataObjectsList.FullName(), AnalyzedValue, Owner);
		
		SubqueryText = "SELECT ObjectTable.Ref FROM #Table AS ObjectTable WHERE Ref = &Ref";
		
	Else
		SubqueryText = "SELECT * FROM #Table AS ObjectTable WHERE Ref = &Ref";
	EndIf;
	
	SubqueryText = StrReplace(SubqueryText, "#Table", MetadataObjectsList.FullName());
	
	AdditionalRequest = New Query;
	AdditionalRequest.Text = SubqueryText;
	AdditionalRequest.SetParameter("Ref", AnalyzedValue);
	QueryResult = AdditionalRequest.Execute();
	
	RequestAndRecord(QueryResult, Owner, Serializer, XMLWriter, AdditionalParameters);
	
EndProcedure

Procedure RegisterRecord(ExportString, Serializer, XMLWriter, AdditionalParameters)
	
	MetadataObjectsList = ExportString.MetadataObjectsList;
	QueryResult = ExportString.QueryResult;
	Owner = ExportString.Owner;

	RecordingViaRecordset(MetadataObjectsList, QueryResult, Owner, Serializer, XMLWriter, AdditionalParameters);
	
EndProcedure

Procedure RecordingViaRecordset(MetadataObjectsList, QueryResult, Owner, Serializer, XMLWriter, AdditionalParameters)
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObjectsList.FullName());
	RecordSet = ObjectManager.CreateRecordSet();
	Filter = RecordSet.Filter;
	
	ColumnCollection_ = QueryResult.Columns; // QueryResultColumnsCollection -
	
	SamplingFromResult = QueryResult.Select();
	While SamplingFromResult.Next() Do
		
		// We set the selection for registers that have at least one selection (measurement)
		For Each Column In ColumnCollection_ Do 
			Filter[Column.Name].Value = SamplingFromResult[Column.Name];
			Filter[Column.Name].ComparisonType = ComparisonType.Equal;
			Filter[Column.Name].Use = True;
		EndDo;
			
		RecordSet.Read();
		
		// we check all the values recorded in the set for the need to write "by reference"
		//@skip-check query-in-loop - record data required for referential integrity
		UnloadSubordinateValuesOfSet(Serializer, XMLWriter, RecordSet, Owner, ColumnCollection_, AdditionalParameters);
		
		Try
			Serializer.WriteXML(XMLWriter, RecordSet);
		Except
			Raise ErrorDescription();
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure UnloadSubordinateValuesOfSet(Serializer, XMLWriter, RecordSet, Owner, ColumnsArray1, AdditionalParameters)
	
	ThisIsBudgetingModel = AdditionalParameters.ThisIsBudgetingModel;
	TypesOfBudgetingAnalytics = AdditionalParameters.TypesOfBudgetingAnalytics;
	
	For Each RecordingFromSet In RecordSet Do
		
		For Each Column In ColumnsArray1 Do //QueryResultColumn
			
			SavedValue = RecordingFromSet[Column.Name]; // QueryResultColumnsCollection -
			
			If ThisIsBudgetingModel And TypesOfBudgetingAnalytics.Find(TypeOf(SavedValue)) <> Undefined Then
				Continue;
			EndIf;
			
			//@skip-check query-in-loop - record data required for referential integrity
			WriteValueIfNecessary(SavedValue, Owner, Serializer, XMLWriter, AdditionalParameters);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function ExportComposition(UploadData_0)
	
	ExportComposition = New ValueTable;
	ExportComposition.Columns.Add("MetadataObjectsList");
	ExportComposition.Columns.Add("Owner");
	ExportComposition.Columns.Add("QueryResult");
	
	For Each String In UploadData_0 Do
		
		ThereIsSelectionByLinks = String.FilterArray <> Undefined;
		
		Query = New Query;
		Query.Text = String.QueryText;
		If ThereIsSelectionByLinks Then
			Query.SetParameter("ReferencesArrray", String.FilterArray);
		EndIf;
		//@skip-check query-in-loop - it is necessary for the formation of a sample for each type of data
		QueryResult = Query.Execute();
		
		NewRow = ExportComposition.Add();
		NewRow.MetadataObjectsList = Metadata.FindByFullName(String.MDName);
		NewRow.Owner = String.Owner;
		NewRow.QueryResult = QueryResult;
		
	EndDo;
	
	Return ExportComposition;
	
EndFunction

Function FilteringTable()
	
	FilteringTable = New ValueTable;
	FilteringTable.Columns.Add("TableName");
	FilteringTable.Columns.Add("Ref");
	FilteringTable.Columns.Add("OwnerRef");
	FilteringTable.Columns.Add("PresentationRef");
	FilteringTable.Columns.Add("PresentationLinkOwner");
	
	Return FilteringTable;
	
EndFunction

Procedure AddRowToFilteringTable(FilteringTable, NameOfSearchTable, ItemRef, OwnerRef)
	
	NewRow = FilteringTable.Add();
	NewRow.TableName = NameOfSearchTable;
	NewRow.Ref = XMLString(ItemRef);
	NewRow.OwnerRef = XMLString(OwnerRef);
	NewRow.PresentationRef = ItemRef;
	NewRow.PresentationLinkOwner = OwnerRef;

EndProcedure

Procedure UploadFilteringTable(FilteringTable, XMLWriter)
	
	XMLWriter.WriteStartElement("FilterData");
	
	If FilteringTable.Count() > 0 Then
		
		For Each Item In FilteringTable Do
			
			XMLWriter.WriteStartElement("itemFilterData");
			XMLWriter.WriteAttribute("TableName", Item.TableName);
			XMLWriter.WriteAttribute("Ref", Item.Ref);
			XMLWriter.WriteAttribute("OwnerRef", Item.OwnerRef);
			XMLWriter.WriteEndElement();
			
		EndDo;
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Function TableOfReplacedUINs()
	
	TableOfReplacedUINs = New ValueTable;
	TableOfReplacedUINs.Columns.Add("SearchRef");
	TableOfReplacedUINs.Columns.Add("ReplacementLink");
	
	Return TableOfReplacedUINs;
	
EndFunction

Function PredefinedDataTable1()
	
	PredefinedDataTable = New ValueTable;
	PredefinedDataTable.Columns.Add("TableName");
	PredefinedDataTable.Columns.Add("Ref");
	PredefinedDataTable.Columns.Add("FieldForSearch");
	PredefinedDataTable.Columns.Add("SearchValue");
	
	Return PredefinedDataTable;
	
EndFunction

Procedure AddPredefinedTableRow(PredefinedDataTable, NameOfSearchTable, ItemRef, FieldForSearch, SearchValue)
	
	NewRow = PredefinedDataTable.Add();
	NewRow.TableName = NameOfSearchTable;
	NewRow.Ref = ItemRef;
	NewRow.FieldForSearch = FieldForSearch;
	NewRow.SearchValue = SearchValue;
	
EndProcedure

Procedure ExportPredefinedItemsTable(PredefinedDataTable, XMLWriter)
	
	XMLWriter.WriteStartElement("PredefinedData");
	
	If PredefinedDataTable.Count() > 0 Then
		
		PredefinedDataTable.Sort("TableName");
		
		NameOfPreviousTable = "";
		
		For Each Item In PredefinedDataTable Do
			
			If NameOfPreviousTable <> Item.TableName Then
				If Not IsBlankString(NameOfPreviousTable) Then
					XMLWriter.WriteEndElement();
				EndIf;
				XMLWriter.WriteStartElement(Item.TableName);
			EndIf;
			
			XMLWriter.WriteStartElement("itemPredefinedData");
			XMLWriter.WriteAttribute("Ref", Item.Ref);
			XMLWriter.WriteAttribute("FieldForSearch", Item.FieldForSearch);
			XMLWriter.WriteAttribute("SearchValue", Item.SearchValue);
			XMLWriter.WriteEndElement();
			
			NameOfPreviousTable = Item.TableName;
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure ProcessPredefinedData(XMLReader, TableOfReplacedUINs, NotRecordedUIN)
	
	PredefinedDataTable = PredefinedDataTable1();
	
	XMLReader.Skip(); // At the first reading, the main data block is skipped
	XMLReader.Read();
	
	TimeLine_ = PredefinedDataTable.Add();
	
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.LocalName <> "itemPredefinedData" Then
				TimeLine_.TableName = XMLReader.LocalName;
				
				QueryText = 
				"SELECT
				|	Table.Ref AS Ref
				|FROM
				|	#Table AS Table
				|WHERE
				|	&FieldForSearch = &SearchValue";
				QueryText = StrReplace(QueryText, "#Table", TimeLine_.TableName);
			Else
				
				While XMLReader.ReadAttribute() Do
					TimeLine_[XMLReader.LocalName] = XMLReader.Value;
				EndDo;
				
				QueryText = StrReplace(QueryText, "&FieldForSearch", "Table." + TimeLine_.FieldForSearch);
				Query = New Query(QueryText);

				Query.SetParameter("SearchValue", TimeLine_.SearchValue);
				
				//@skip-check query-in-loop - it is necessary for the formation of a sample for each type of data
				QueryResult = Query.Execute();
				If QueryResult.IsEmpty() Then
					
					If TimeLine_.FieldForSearch = "PredefinedDataName" Then
						ExceptionText = NStr("vi = 'Không tìm thấy phần tử định trước %1 trong bảng %2';
											|ru = 'Не найден предопределнный элемент %1 в таблице %2';
											|en = 'Predefined %1 item is not found in the %2 table'; fa = 'Predefined %1 item is not found in the %2 table';
											|it = 'Не найден предопределнный элемент %1 в таблице %2';
											|pl = 'Predefined %1 item is not found in the %2 table';
											|tr = '%2 tablosunda önceden tanımlanan %1 öğesi bulunamadı'");
						ExceptionText = StrReplace(ExceptionText, "%1", TimeLine_.PredefinedDataName);
						ExceptionText = StrReplace(ExceptionText, "%2", TimeLine_.TableName);
						
						Raise ExceptionText;
					EndIf;
					
				Else
					
					Selection = QueryResult.Select();
					
					If Selection.Count() = 1 Then
						Selection.Next();
						
						LinkInDatabase = XMLString(Selection.Ref);
						LinkInFile = TimeLine_.Ref;
						
						If LinkInDatabase <> LinkInFile Then
							NewRow = TableOfReplacedUINs.Add();
							NewRow.SearchRef = LinkInFile;
							NewRow.ReplacementLink = LinkInDatabase;
						EndIf;
						
						NotRecordedUIN.Add(LinkInDatabase);
						
					Else
						ExceptionText = NStr("vi = 'Đã tìm thấy phần tử định trước bị trùng theo trường ""%1"" %2 trong bảng %3';
											|ru = 'Обнаружено дублирование предопределенных элементов по полю ""%1"" %2 в таблице %3';
											|en = 'Duplicate predefined items are detected in the ""%1"" %2 field in the %3 table'; fa = 'Duplicate predefined items are detected in the ""%1"" %2 field in the %3 table';
											|it = 'Обнаружено дублирование предопределенных элементов по полю ""%1"" %2 в таблице %3';
											|pl = 'Duplicate predefined items are detected in the ""%1"" %2 field in the %3 table';
											|tr = '%3 tablosunda ""%1"" %2 alanında kopyalanan önceden tanımlanmış öğeler tespit edildi'");
						ExceptionText = StrReplace(ExceptionText, "%1", TimeLine_.FieldForSearch);
						ExceptionText = StrReplace(ExceptionText, "%2", TimeLine_.SearchValue);
						ExceptionText = StrReplace(ExceptionText, "%3", TimeLine_.TableName);
						
						Raise ExceptionText;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	XMLReader.Close();
	
EndProcedure

Procedure ReplaceRefsInFile(FileName, TableOfReplacedUINs)
	
	ReaderStream = New TextReader(FileName);
	
	TempFile = GetTempFileName("xml");
	
	WriteStream = New TextWriter(TempFile);
	
	// Constants for parsing text
	BeginningOfType = "xsi:type=""v8:";
	TypeStartLength = StrLen(BeginningOfType);
	EndOfType = """>";
	TypeEndLength = StrLen(EndOfType);
	
	InitialString = ReaderStream.ReadLine();
	While InitialString <> Undefined Do
		
		RowBalance = Undefined;
		
		CurrentPosition = 1;
		TypePosition = Find(InitialString, BeginningOfType);
		While TypePosition > 0 Do
			
			WriteStream.Write(Mid(InitialString, CurrentPosition, TypePosition - 1 + TypeStartLength));
			
			RowBalance = Mid(InitialString, CurrentPosition + TypePosition + TypeStartLength - 1);
			CurrentPosition = CurrentPosition + TypePosition + TypeStartLength - 1;
			
			PositionOfEndOfType = Find(RowBalance, EndOfType);
			If PositionOfEndOfType = 0 Then
				Break;
			EndIf;
			
			TypeName = Left(RowBalance, PositionOfEndOfType - 1);
			
			WriteStream.Write(TypeName);
			WriteStream.Write(EndOfType);
			
			OriginalXMLLink = Mid(RowBalance, PositionOfEndOfType + TypeEndLength, 36);
			
			ReplacementString = TableOfReplacedUINs.Find(OriginalXMLLink, "SearchRef");
			If ReplacementString = Undefined Then
				WriteStream.Write(OriginalXMLLink);
			Else
				WriteStream.Write(ReplacementString.ReplacementLink);
			EndIf;
			
			CurrentPosition = CurrentPosition + PositionOfEndOfType - 1 + TypeEndLength + 36;
			RowBalance = Mid(RowBalance, PositionOfEndOfType + TypeEndLength + 36);
			TypePosition = Find(RowBalance, BeginningOfType);
			
		EndDo;
		
		If RowBalance <> Undefined Then
			WriteStream.WriteLine(RowBalance);
		Else
			WriteStream.WriteLine(InitialString);
		EndIf;
		
		InitialString = ReaderStream.ReadLine();
		
	EndDo;
	
	ReaderStream.Close();
	WriteStream.Close();
	
	//@skip-check bsl-legacy-check-static-feature-access
	CopyFile(TempFile, FileName);
	DeleteFiles(TempFile);
	
EndProcedure

Procedure ReplacingLinksInCDSettings(StorageAttributes, Parameters)
	
	If TypeOf(StorageAttributes) = Type("ValueStorage") Then
		CompositionSettings = StorageAttributes.Get();
		If TypeOf(CompositionSettings) = Type("DataCompositionSettings") Then 
			For Each Page1 In CompositionSettings.Filter.Items Do
				If TypeOf(Page1) <> Type("DataCompositionFilterItem") Then
					Continue;
				EndIf;	
				If TypeOf(Page1.RightValue) = Type("ValueList") Then
					For Each It_ In Page1.RightValue Do
						ProcessSelectionValue(It_.Value, Parameters);
					EndDo;
				Else 
					ProcessSelectionValue(Page1.RightValue, Parameters);
				EndIf;
			EndDo;
			StorageAttributes = New ValueStorage(CompositionSettings);
		ElsIf TypeOf(CompositionSettings) = Type("Structure") Then
			ProcessStructureRecursivelyWhenLoading(CompositionSettings, Parameters);
		EndIf;
	EndIf;
EndProcedure

Procedure ProcessStructureRecursivelyWhenLoading(StructureOfData, Parameters)
	
	For Each KeyAndValue In StructureOfData Do
		If TypeOf(KeyAndValue.Value) = Type("Structure") Then
			ProcessStructureRecursivelyWhenLoading(KeyAndValue.Value, Parameters);
		Else
			Value = KeyAndValue.Value;
			ProcessSelectionValue(Value, Parameters);
			StructureOfData[KeyAndValue.Key] = Value;
		EndIf;
	EndDo;
	
EndProcedure

Procedure ProcessSelectionValue(Value, Parameters)
	
	If Value <> Undefined Then 
		
		ValueType = TypeOf(Value);
		If (Catalogs.AllRefsType().ContainsType(ValueType) 
			Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ValueType)) Then
			
			WIN = String(Value.UUID());
			FoundRow = Parameters.ReplaceDimensionValues.Find(WIN, "PaymentIDFileDimension");
			If FoundRow <> Undefined Then
				Dimensiondb = FoundRow.Dimensiondb;
				If ValueIsFilled(Dimensiondb) Then
					Value = Dimensiondb;
				EndIf;
			Else
				ReplacementString = Parameters.ReplaceableUIN.Find(WIN, "SearchRef");
				If ReplacementString <> Undefined Then
					UID = New UUID(ReplacementString.ReplacementLink);
					CatalogName = Metadata.FindByType(ValueType).Name;
					Value = Catalogs[CatalogName].GetRef(UID);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function ThisIsMetadataWithPredefinedElements(MetadataObject)
	
	Return Common.IsCatalog(MetadataObject)
		Or Common.IsChartOfAccounts(MetadataObject)
		Or Common.IsChartOfCharacteristicTypes(MetadataObject)
		Or Common.IsChartOfCalculationTypes(MetadataObject);
	
EndFunction

Procedure UploadingLinksFromCDSettings(StorageAttributes, Owner, Serializer, XMLWriter, AdditionalParameters)
	
	If TypeOf(StorageAttributes) = Type("ValueStorage") Then
		CompositionSettings = StorageAttributes.Get();
		If TypeOf(CompositionSettings) = Type("DataCompositionSettings") Then 
			For Each Page1 In CompositionSettings.Filter.Items Do
					If TypeOf(Page1) <> Type("DataCompositionFilterItem") Then
						Continue;
					EndIf;			
					If TypeOf(Page1.RightValue) = Type("ValueList") Then
						For Each It_ In Page1.RightValue Do
							If It_.Value <> Undefined And (Catalogs.AllRefsType().ContainsType(TypeOf(It_.Value)) 
									Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(TypeOf(It_.Value))) Then
								//@skip-check query-in-loop - record data required for referential integrity
								WriteValueIfNecessary(It_.Value, Owner, Serializer, XMLWriter, AdditionalParameters);
							EndIf;
						EndDo;
					Else 
						If Page1.RightValue <> Undefined And (Catalogs.AllRefsType().ContainsType(TypeOf(Page1.RightValue)) 
								Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(TypeOf(Page1.RightValue))) Then
							//@skip-check query-in-loop - record data required for referential integrity
							WriteValueIfNecessary(Page1.RightValue, Owner, Serializer, XMLWriter, AdditionalParameters);
						EndIf;
					EndIf;
			EndDo;
		ElsIf TypeOf(CompositionSettings) = Type("Structure") Then
			ProcessStructureRecursivelyWhenUnloading(CompositionSettings, Owner, Serializer, XMLWriter, AdditionalParameters);
		EndIf;
	EndIf;
EndProcedure

Procedure ProcessStructureRecursivelyWhenUnloading(StructureOfData, Owner, Serializer, XMLWriter, AdditionalParameters)
	
	For Each KeyAndValue In StructureOfData Do
		If TypeOf(KeyAndValue.Value) = Type("Structure") Then
			//@skip-check query-in-loop - record data required for referential integrity
			ProcessStructureRecursivelyWhenUnloading(KeyAndValue.Value, Owner, Serializer, XMLWriter, AdditionalParameters);
		ElsIf KeyAndValue.Value <> Undefined And (Catalogs.AllRefsType().ContainsType(TypeOf(KeyAndValue.Value)) 
			Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(TypeOf(KeyAndValue.Value))) Then
			//@skip-check query-in-loop - record data required for referential integrity
			WriteValueIfNecessary(KeyAndValue.Value, Owner, Serializer, XMLWriter, AdditionalParameters);
		EndIf;
		
	EndDo;
	
EndProcedure

// The XDTO serializer uses type notation.
// 
// Returns:
//  XDTOSerializer - The XDTO serializer with type notation
Function XdtoSerializerWithTypeAnnotation() Export
	
	TypesWithAnnotatedLinks = PredefinedTypesWhenUnloading();
	
	If TypesWithAnnotatedLinks.Count() > 0 Then
		Factory = GetFactoryWithTypesSpecified(TypesWithAnnotatedLinks);
		Serializer = New XDTOSerializer(Factory);
	Else
		Serializer = XDTOSerializer;
	EndIf;
	
	Return Serializer;
	
EndFunction

Function PredefinedTypesWhenUnloading()
	
	Types = New Array;
	
	For Each MetadataObject In Metadata.Catalogs Do
		If ThisIsConfigurationMetadataObject(MetadataObject) Then
			Types.Add(MetadataObject);	
		EndIf;
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		If ThisIsConfigurationMetadataObject(MetadataObject) Then
			Types.Add(MetadataObject);	
		EndIf;
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		If ThisIsConfigurationMetadataObject(MetadataObject) Then
			Types.Add(MetadataObject);	
		EndIf;
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		If ThisIsConfigurationMetadataObject(MetadataObject) Then
			Types.Add(MetadataObject);	
		EndIf;
	EndDo;
	
	Return Types;
	
EndFunction

Function ThisIsConfigurationMetadataObject(MetadataObject)
	ObjectID = Common.MetadataObjectID(MetadataObject);
	If TypeOf(ObjectID) = Type("CatalogRef.MetadataObjectIDs") Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

Function GetFactoryWithTypesSpecified(Val Types)
	
	SetOfSchemes = XDTOFactory.ExportXMLSchema("http://v8.1c.ru/8.1/data/enterprise/current-config");
	Schema = SetOfSchemes[0];
	Schema.UpdateDOMElement();
	
	SpecifiedTypes = New Map;
	For Each Type In Types Do
		SpecifiedTypes.Insert(XMLRefType(Type), True);
	EndDo;
	
	Namespace = New Map;
	Namespace.Insert("xs", "http://www.w3.org/2001/XMLSchema");
	DOMNamespaceResolver = New DOMNamespaceResolver(Namespace);
	XPathText = "/xs:schema/xs:complexType/xs:sequence/xs:element[starts-with(@type,'tns:')]";
	
	Query = Schema.DOMDocument.CreateXPathExpression(XPathText, DOMNamespaceResolver);
	
	SetSafeMode(True);
	Result = Query.Evaluate(Schema.DOMDocument);
	SetSafeMode(False);

	While True Do
		
		FieldNode_ = Result.IterateNext();
		If FieldNode_ = Undefined Then
			Break;
		EndIf;
		AttributeType = FieldNode_.Attributes.GetNamedItem("type");
		TypeWithoutNSPrefix = Mid(AttributeType.TextContent, StrLen("tns:") + 1);
		
		If SpecifiedTypes.Get(TypeWithoutNSPrefix) = Undefined Then
			Continue;
		EndIf;
		
		FieldNode_.SetAttribute("nillable", "true");
		FieldNode_.RemoveAttribute("type");
	EndDo;
	
	XMLWriter = New XMLWriter;
	SchemaFileName = GetTempFileName("xsd");
	XMLWriter.OpenFile(SchemaFileName);
	DOMWriter = New DOMWriter;
	DOMWriter.Write(Schema.DOMDocument, XMLWriter);
	XMLWriter.Close();
	
	Factory = CreateXDTOFactory(SchemaFileName);
	
	Try
		DeleteFiles(SchemaFileName);
	Except
		ExceptionText = NStr("vi = 'Lỗi tạo nhà máy XML';
							|ru = 'Ошибка создания фабрики XML';
							|en = 'An error occurred while creating the XML factory'; fa = 'An error occurred while creating the XML factory';
							|it = 'Errore di creazione di factory XML';
							|pl = 'Błąd utworzenia zakładu XML';
							|tr = 'XML fabrika oluşturma hatası'");
		Raise ExceptionText;
	EndTry;
	
	Return Factory;
	
EndFunction

Function XMLRefType(Val Value)
	
	If TypeOf(Value) = Type("MetadataObject") Then
		MetadataObject = Value;
		ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Ref = ObjectManager.GetRef();
	Else
		MetadataObject = Value.Metadata();
		Ref = Value;
	EndIf;
	
	If Common.IsReference(TypeOf(Ref)) Then
		
		Return XDTOSerializer.XMLTypeOf(Ref).TypeName;
		
	Else
		
		ExceptionText = NStr("vi = 'Lỗi khi xác định kiểu tham chiếu XML với đối tượng %1: đối tượng không phải là tham chiếu';
							|ru = 'Ошибка при определении XML-типа ссылки для объекта %1: объект не является ссылочным';
							|en = 'An error occurred while determining the XML ref type for the %1 object: this is not a reference object'; fa = 'An error occurred while determining the XML ref type for the %1 object: this is not a reference object';
							|it = 'Errore durante la definizione del collegamento di tipo XML per l''oggetto %1: non è un oggetto di collegamento';
							|pl = 'Błąd przy określeniu XML typu odnośnika dla obiektu%1: obiekt nie jest linkowym';
							|tr = '%1 nesnesi için XML bağlantı türü belirlenirken hata oluştu: nesne bağlantı değil'");
		ExceptionText = StrReplace(ExceptionText, "%1", MetadataObject.FullName());
		
		Raise ExceptionText;
		
	EndIf;
	
EndFunction

Function GetQueryText(MetadataObject, ThereIsSelectionByLinks, FilterField = "")
	
	NameOfMetadataObjects = MetadataObject.FullName();
	
	If Common.IsInformationRegister(MetadataObject) Then
		
		Manager = Common.ObjectManagerByFullName(NameOfMetadataObjects);
		RecordSet = Manager.CreateRecordSet();
		
		Filter = RecordSet.Filter;
		StringOfFieldsToSelect = "";
		For Each FilterElement In Filter Do 
			StringOfFieldsToSelect = ?(IsBlankString(StringOfFieldsToSelect), StringOfFieldsToSelect, StringOfFieldsToSelect + ", ") + FilterElement.Name;
		EndDo;
		
	Else
		StringOfFieldsToSelect = "_.*";
	EndIf;
	
	QueryText = "SELECT ALLOWED &SelectionFields1 FROM #Table AS _ ";
	QueryText = StrReplace(QueryText, "&SelectionFields1", StringOfFieldsToSelect);
	QueryText = StrReplace(QueryText, "#Table", NameOfMetadataObjects);
	
	If ThereIsSelectionByLinks Then
		
		StringSelection_ = "
		|	WHERE
		|		_." + ?(ValueIsFilled(FilterField), FilterField, "Ref") + " IN(&ReferencesArrray)";
		
		QueryText = QueryText + Chars.LF + StringSelection_;
		
	EndIf;
	
	Return QueryText;
	
EndFunction 

Function LinkUnloaded(ExportedObjects, Ref)
	
	Return ExportedObjects.Find(Ref, "Ref") <> Undefined;
	
EndFunction

// Add a link to the uploaded ones.
// 
// Parameters:
//  ExportedObjects - ValueTable - Uploaded objects:
// 	* Ref - AnyRef - Link to the uploaded object
//  Ref - AnyRef - Link to the object being uploaded
Procedure AddLinkToUploaded(ExportedObjects, Ref)
	
	AddLine = ExportedObjects.Add();
	AddLine.Ref = Ref;
	
EndProcedure

Procedure ProcessFunctionalOptions()
	
	If Not GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	COUNT(FinancialAccountingChartsOfAccounts.Ref) AS Count
		|FROM
		|	Catalog.FinancialAccountingChartsOfAccounts AS FinancialAccountingChartsOfAccounts";
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			If Selection.Count > 1 Then
				Constants.UseSeveralChartsOfAccountsInFinancialAccounting.Set(True);
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		NumberOfCurrencies = Catalogs.Currencies.NumberOfCurrencies();
		If NumberOfCurrencies > 1 Then
			Constants.UseMultipleCurrencies.Set(True);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DeleteFinancialReportItems(ReportKind)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FinancialReportItems.Ref AS Ref,
	|	FinancialReportItems.Description AS Description
	|FROM
	|	Catalog.FinancialReportItems AS FinancialReportItems
	|WHERE
	|	FinancialReportItems.Owner = &Owner";

	Query.SetParameter("Owner", ReportKind);

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();

	While Selection.Next() Do
		Object = Selection.Ref.GetObject(); // CatalogObject
		If Object <> Undefined Then
			Try
				Object.Delete();
			Except
				
				LogEventName = NStr("vi = 'Bản ghi loại ngân sách';
									|ru = 'Запись вида бюджета';
									|en = 'Save budget profile'; fa = 'Save budget profile';
									|it = 'Registrazione del tipo di bilancio';
									|pl = 'Zapis rodzaju budżetu';
									|tr = 'Bütçe türünün kaydı'");
				ErrorText = NStr("vi = 'Khi ghi loại ngân sách %1, không thể xóa mục báo cáo tài chính: %2 do: %3';
								|ru = 'При записи вида бюджета %1 не удалось удалить элемент финансового отчета: %2 по причине: %3';
								|en = 'Cannot delete financial report item: %2 while saving the budget profile %1. Reason: %3'; fa = 'Cannot delete financial report item: %2 while saving the budget profile %1. Reason: %3';
								|it = 'Durante la registrazione del tipo di bilancio %1non è stato possibile eliminare l''elemento del report finanziario:%2 a causa di:%3';
								|pl = 'Podczas zapisywania rodzaju budżetu %1 usuwanie elementu raportu finansowego: %2 nie powiodło się z powodu: %3';
								|tr = '%1 bütçe profilinin kaydedilmesi için finansal rapor öğesi silinemedi: %2 şu sebeple: %3'",);
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, ReportKind,
					Selection.Description, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(LogEventName,
						EventLogLevel.Error,
						Metadata.Catalogs.FinancialReportItems,
						Selection.Ref,
						ErrorText);
						
				Raise ErrorText;
			EndTry;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
