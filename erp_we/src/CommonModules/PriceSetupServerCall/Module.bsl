
#Region Public

#Region LayoutSettingsForTheseTypesOfPrices

// Returns parameters that can be changed in the data layout schema settings.
//
// Returns:
//  Array - Parameter name
//
Function NamesOfAllowedDataLayoutSchemeParameters() Export
	
	AllowedNames = New Array;
	AllowedNames.Add("DocumentDate");
	AllowedNames.Add("ThisIsGenerationFromBaseDocuments");
	AllowedNames.Add("PriceKind");
	AllowedNames.Add("Basis");
	
	AllowedNames.Add("FilterByProductSegmentIsUsed");
	AllowedNames.Add("QueryTextPackagingFactor1");
	AllowedNames.Add("QueryTextPackagingFactor2");
	AllowedNames.Add("QueryTextPackagingFactor3");
	
	Return AllowedNames;
	
EndFunction

// Returns parameters for which to leave empty values in the data layout schema settings.
//
// Returns:
//  Array - Parameter name
//
Function ParameterNamesOfDataLayoutSchemesWithAllowedEmptyValues(AllowedNames = Undefined) Export
	
	If AllowedNames = Undefined Then
		AllowedNames = New Array;
	EndIf;	
		
	AllowedNames.Add("AnalysisDepth");
	
	Return AllowedNames;
	
EndFunction

// Checks whether the required parameters of the data layout schema are filled in
//
// Parameters:
//  PriceKind - CatalogRef.TypesOfPrices - Link to the price type for which you need a description of the parameters
//  DataCompositionSettings - DataCompositionSettings - customize the layout data
//  ParametersOfLayoutSchemesForTheseTypesOfPrices - ValueTable - Table of parameters for layout schemes for these types of prices
//
// Returns:
//  Structure - structure with properties:
//   * ParametersDetails - String - Parameter description.
//
Function DescriptionOfDataLayoutSchemeParameters(PriceKind,
	                                            DataCompositionSettings,
	                                            ParametersOfLayoutSchemesForTheseTypesOfPrices) Export
	
	For Each Item In DataCompositionSettings.DataParameters.Items Do
		FoundRows = ParametersOfLayoutSchemesForTheseTypesOfPrices.FindRows(
			New Structure("Name, PriceKind", String(Item.Parameter), PriceKind));
		For Each FoundRow In FoundRows Do
			FoundRow.Value      = Item.Value;
			FoundRow.Use = Item.Use;
		EndDo;
	EndDo;
	
	ParametersDetails = "";
	ArrayOfParametersForLayoutSchemesForTheseTypesOfPrices = ParametersOfLayoutSchemesForTheseTypesOfPrices.FindRows(New Structure("PriceKind", PriceKind)); // Array of DataCompositionSchemaParameter
	For Each Parameter In ArrayOfParametersForLayoutSchemesForTheseTypesOfPrices Do
		
		ParameterValue = Undefined;
		If ValueIsFilled(Parameter.Use) Then
			If Parameter.AvailableValues = Undefined Then
				ParameterValue = Parameter.Value;
			Else
				AvailableValue = Parameter.AvailableValues.FindByValue(Parameter.Value);
				If AvailableValue <> Undefined Then
					ParameterValue = ?(ValueIsFilled(
						AvailableValue.Presentation), AvailableValue.Presentation, Parameter.Value);
				Else
					ParameterValue = Parameter.Value;
				EndIf;
			EndIf;
		EndIf;
		
		ParametersDetails = ?(ValueIsFilled(ParametersDetails), ParametersDetails, NStr("vi = 'Tham số:';
																						|ru = 'Параметры:';
																						|en = 'Parameters:'; fa = 'پارامترها:';
																						|it = 'Parametri:';
																						|pl = 'Parametry:';
																						|tr = 'Parametreler:'") + " ")
		                   + ?(Not ValueIsFilled(ParametersDetails), "" , ", ")
		                   + Parameter.Title
		                   + " = "
		                   + ?(ValueIsFilled(ParameterValue), String(ParameterValue), NStr("vi = '<chưa điền>';
																							|ru = '<не заполнен>';
																							|en = '<Not filled in>'; fa = '<Not filled in>';
																							|it = '<non compilato>';
																							|pl = '<nie wypełniony>';
																							|tr = '<doldurulmadı>'"));
	EndDo;
	
	ParametersDetails = ParametersDetails
	                   + ?(ValueIsFilled(String(DataCompositionSettings.Filter)),
	                      " " + NStr("vi = 'Lọc:';
									|ru = 'Отбор:';
									|en = 'Filter:'; fa = 'فیلتر:';
									|it = 'Selezione:';
									|pl = 'Filtr:';
									|tr = 'Filtre:'") + " " + String(DataCompositionSettings.Filter),
	                      "");
	
	Return New Structure("ParametersDetails", ParametersDetails);
	
EndFunction

// Returns the names and types of fields that must be present
// in the SKD used for filling in prices based on information security data.
//
// Returns:
//  Map - The keys contain field names, and the values contain field types.
//
Function GetRequiredDataLayoutSchemaFields(UsePriceManagementSystem25 = False) Export
	
	Fields = New Map();
	
	Fields.Insert("Products", New TypeDescription("CatalogRef.Products"));
	
	If UsePriceManagementSystem25 Then
		If GetFunctionalOption("UseItemVariants") Then
			Fields.Insert("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
			Fields.Insert("PricingVariant", New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		EndIf;
		
		If GetFunctionalOption("UseItemPackages") Then
			Fields.Insert("PricingPackage", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		EndIf;
		
		If GetFunctionalOption("UseItemsBatch") Then
			Fields.Insert("PricingBatch", New TypeDescription("CatalogRef.ItemsBatchesForPricing"));
		EndIf;
	Else
		If GetFunctionalOption("UseItemVariants") Then
			Fields.Insert("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		EndIf;
	EndIf;

	Return Fields;
	
EndFunction // Get the required fields of the Combined data()

// Checks whether the required parameters of the data layout schema are filled in
//
// Parameters:
//  SelectedPrices - Array of CatalogRef.TypesOfPrices - Array of price types to get the address of data layout settings for
//  StorageAddressDataLayoutSettings - String, UUID - Address with data layout settings for the price view
//  AddressOfTheStorageOfLayoutSchemeParametersByPriceType - String, UUID - Address with settings 
//                                                     for data layout settings for all types of prices.
//
// Returns:
//  Array of Structure - Array of descriptions of errors found:
//  * PriceKind - CatalogRef.TypesOfPrices - Type of price
//  * LongDesc - String - LongDesc
//
Function CheckWhetherRequiredDataLayoutSchemaParametersAreFull(SelectedPrices,
	                                                                      StorageAddressDataLayoutSettings,
	                                                                      AddressOfTheStorageOfLayoutSchemeParametersByPriceType) Export
	
	Errors = New Array;
	
	AllowedNames = NamesOfAllowedDataLayoutSchemeParameters();
	AllowedNames = ParameterNamesOfDataLayoutSchemesWithAllowedEmptyValues(AllowedNames);
	
	ParametersOfLayoutSchemesForTheseTypesOfPrices = GetFromTempStorage(AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
	DataLayoutSettingsTable      = GetFromTempStorage(StorageAddressDataLayoutSettings); // See SettingPricesServer.LoadDataLayoutSettingsTable
	
	For Each PriceKind In SelectedPrices Do
		FoundRow = DataLayoutSettingsTable.Find(PriceKind, "PriceKind");
		If FoundRow = Undefined Then
			LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền các tham số bắt buộc cho dạng giá ""%1""';
					|ru = 'Не заполнены обязательные параметры для вида цены ""%1""';
					|en = 'Parameters for the ""%1"" price type are required'; fa = 'Parameters for the ""%1"" price type are required';
					|it = 'Parametri obbligatori per il tipo di prezzo ""%1"" non compilati';
					|pl = 'Nie są wypełnione wymagane parametry dla rodzaju ceny ""%1""';
					|tr = '""%1"" fiyat türü için zorunlu parametreler doldurulmadı'"),
				String(PriceKind));
			Errors.Add(New Structure("PriceKind, LongDesc", PriceKind, LongDesc));
		Else
			FoundRows = ParametersOfLayoutSchemesForTheseTypesOfPrices.FindRows(New Structure("PriceKind", PriceKind)); // Array of DataCompositionSchemaParameter
			For Each DataParameter In FoundRows Do
				
				CheckCompleted = False;
				
				For Each TSRow In FoundRow.DataCompositionSettings.DataParameters.Items Do
					If String(TSRow.Parameter) = DataParameter.Name Then
						If Not ValueIsFilled(TSRow.Value)
							And AllowedNames.Find(DataParameter.Name) = Undefined Then
							LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Chưa điền giá trị của tham số ""%1"" cho dạng giá ""%2""';
									|ru = 'Не заполнено значение параметра ""%1"" для вида цены ""%2""';
									|en = 'Value of ""%1"" parameter is required for the ""%2"" price type'; fa = 'Value of ""%1"" parameter is required for the ""%2"" price type';
									|it = 'Valore del parametro ""%1"" per il tipo di prezzo ""%2"" non compilato';
									|pl = 'Nie jest wypełniona wartość parametru ""%1"" dla rodzaju ceny ""%2""';
									|tr = '""%2"" fiyat türü için ""%1"" parametresinin değeri doldurulmadı'"),
								DataParameter.Title,
								String(PriceKind));
							Errors.Add(New Structure("PriceKind, LongDesc", PriceKind, LongDesc));
						EndIf;
						CheckCompleted = True;
						Break;
					EndIf;
				EndDo;
				
				If Not CheckCompleted Then
					
					LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chưa điền giá trị của tham số ""%1"" cho dạng giá ""%2""';
							|ru = 'Не заполнено значение параметра ""%1"" для вида цены ""%2""';
							|en = 'Value of ""%1"" parameter is required for the ""%2"" price type'; fa = 'Value of ""%1"" parameter is required for the ""%2"" price type';
							|it = 'Valore del parametro ""%1"" per il tipo di prezzo ""%2"" non compilato';
							|pl = 'Nie jest wypełniona wartość parametru ""%1"" dla rodzaju ceny ""%2""';
							|tr = '""%2"" fiyat türü için ""%1"" parametresinin değeri doldurulmadı'"),
						DataParameter.Title,
						String(PriceKind));
					Errors.Add(New Structure("PriceKind, LongDesc", PriceKind, LongDesc));
					
				EndIf;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	Return Errors;
	
EndFunction

// Returns the address of the data layout settings for the default price view
//
// Parameters:
//  PriceKind - CatalogRef.TypesOfPrices - Link to the price view to get the address of the data layout settings for
//  AddressOfDataCompositionSchema - String - Address with data layout settings for all types of form prices
//  UUID - UUID - unique form ID.
//
// Returns:
//  String - The address of the data layout settings for the price type.
//
Function DefaultDataLayoutSchemeSettings(PriceKind,
	                                              AddressOfDataCompositionSchema,
	                                              UUID) Export
	
	PriceTypeOfSettingsStorage = Common.ObjectAttributesValues(PriceKind, 
		"StorageOfDataCompositionSettings, StorageOfFilterByItemsDataCompositionSettings");
	
	DataCompositionSettings = PriceTypeOfSettingsStorage.StorageOfDataCompositionSettings.Get();

	ProductSelectionDataLayoutSettings = PriceTypeOfSettingsStorage.StorageOfFilterByItemsDataCompositionSettings.Get();

	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	
	If Not ValueIsFilled(DataCompositionSettings) Then
		
		SettingsComposer = New DataCompositionSettingsComposer;
		SetPrivilegedMode(True);
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
		SetPrivilegedMode(False);
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
		
		DataCompositionSettings = SettingsComposer.GetSettings();
		
		If ValueIsFilled(ProductSelectionDataLayoutSettings) Then
			DataCompositionClientServer.CopyDataLayoutSettings(DataCompositionSettings, ProductSelectionDataLayoutSettings);
		EndIf;

		Return PutToTempStorage(DataCompositionSettings, UUID);
		
	Else
		
		If ValueIsFilled(ProductSelectionDataLayoutSettings) Then
			DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, DataCompositionSettings, ProductSelectionDataLayoutSettings);
		EndIf;
		
		Return PutToTempStorage(DataCompositionSettings, UUID);
	EndIf;
	
EndFunction

// Sets data layout settings for the price view
//
// Parameters:
//  PriceKind - CatalogRef.TypesOfPrices - Link to the price view to get the address of the data layout settings for
//  AddressOfSettingsStoreForPriceType - String - Address with data layout settings for the price view
//  StorageAddressDataLayoutSettings - String - Address with data layout settings for all types of prices
//  AddressOfTheStorageOfLayoutSchemeParametersByPriceType - String - Address with settings for data layout scheme parameters
//
// Returns:
//  Structure - Description of data layout scheme parameters.
//
Function SetDataLayoutSettingsForPriceView(PriceKind,
	                                                   AddressOfSettingsStoreForPriceType,
	                                                   StorageAddressDataLayoutSettings,
	                                                   AddressOfTheStorageOfLayoutSchemeParametersByPriceType) Export
	
	DataCompositionSettings        = GetFromTempStorage(AddressOfSettingsStoreForPriceType);
	DataLayoutSettingsTable = GetFromTempStorage(StorageAddressDataLayoutSettings);
	
	FoundRow = DataLayoutSettingsTable.Find(PriceKind, "PriceKind");
	If FoundRow = Undefined Then
		FoundRow = DataLayoutSettingsTable.Add();
		FoundRow.PriceKind = PriceKind;
	EndIf;
	FoundRow.DataCompositionSettings = DataCompositionSettings;
	
	PutToTempStorage(DataLayoutSettingsTable, StorageAddressDataLayoutSettings);
	
	ParametersOfLayoutSchemesForTheseTypesOfPrices = GetFromTempStorage(AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
	Return DescriptionOfDataLayoutSchemeParameters(PriceKind, DataCompositionSettings, ParametersOfLayoutSchemesForTheseTypesOfPrices);
	
EndFunction

// Returns the address of the data layout settings for the price view
//
// Parameters:
//  PriceKind - CatalogRef.TypesOfPrices - Link to the price view to get the address of the data layout settings for
//  StorageAddressDataLayoutSettings - String - Address with data layout settings for all types of form prices
//  UUID - UUID - Unique identifier of the form
//
// Returns:
//  String - The address of the data layout settings for the price type.
//
Function AddressOfDataLayoutSettingsForPriceView(PriceKind,
	                                             StorageAddressDataLayoutSettings,
	                                             UUID) Export
	
	DataLayoutSettingsTable = GetFromTempStorage(StorageAddressDataLayoutSettings);
	
	FoundRow = DataLayoutSettingsTable.Find(PriceKind, "PriceKind");
	If FoundRow = Undefined Then
		Return Undefined;
	Else
		Return PutToTempStorage(FoundRow.DataCompositionSettings, UUID);
	EndIf;
	
EndFunction

#EndRegion

#Region ProcessingWithExcel

// Processing an excel file at upload
//
// Parameters:
//  AddressOfBinaryData - String - Binary data address of the file
//  AdditionalParameters - Structure - Set of parameters
//
// Returns:
//  Structure - A set of spent data:
//		* OwnerForm - String- Owner
//		* TypesOfPrices - String -  Type of prices
//		* Goods - String - Goods
//
Function ProcessDownloadFromExcelPriceListOnServer(AddressOfBinaryData, AdditionalParameters) Export

	Return SettingPricesServer.ProcessDownloadFromExcelPriceListOnServer(AddressOfBinaryData, AdditionalParameters);	
	
EndFunction	

// Returns the document number within a day
//
// Parameters:
//  DocumentsArray - Array - documents to upload
//  UUID - UUID - Unique identifier of the form
//  PrintParameters - Structure - the print settings used in the preparation of documents for discharging.
//
// Returns:
//  Array of Structure - Data about the created files.
//
Function ExportToExcel(DocumentsArray, UUID, PrintParameters) Export
	
	ReturnedData = New Array;
	
	SetPrivilegedMode(True);
	
	For Each Document In DocumentsArray Do
	
		FileAddressInTempStorage = UploadToExcelWithoutLink(Document, UUID, PrintParameters);
		
		FileParameters = New Structure();
		FileParameters.Insert("Author", Users.AuthorizedUser());
		FileParameters.Insert("FilesOwner", Document);
		FileParameters.Insert("BaseName", "Excel" + " " + Format(CurrentSessionDate(), NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм:сс''';
																							|ru = 'ДФ=''dd.MM.yyyy ЧЧ.мм.сс''';
																							|en = 'DF=''dd.MM.yyyy HH.mm.ss'''; fa = 'DF=''dd.MM.yyyy HH.mm.ss''';
																							|it = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс''';
																							|pl = 'DF=''dd.MM.yyyy HH.mm.ss''';
																							|tr = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс'''")));
		FileParameters.Insert("ExtensionWithoutPoint", "xls");
		FileParameters.Insert("ModificationTimeUniversal", CurrentSessionDate());
		
		File = FilesOperations.AppendFile(FileParameters, FileAddressInTempStorage, Undefined);
			
		If File <> Undefined Then
			FilesOperationsInternal.BorrowFileToEditServer(File);
			FileData = FilesOperations.FileData(File, UUID, True);
			DataString1 = New Structure("FileData, File", FileData, File);
			ReturnedData.Add(DataString1);
		Else
			Return Undefined;
		EndIf;
	
	EndDo;
	
	Return ReturnedData;
	
EndFunction

// Returns the document number within a day
//
// Parameters:
//  Document - DocumentRef - documents to upload
//  UUID - UUID - Unique identifier of the form
//  PrintParameters - Structure - the print settings used in the preparation of documents for discharging.
//
// Returns:
//  Array of Structure - Data about the created files.
//
Function UploadToExcelWithoutLink(Document, UUID, PrintParameters) Export
	
	ObjectsArray = New Array;
	PrintObjects  = New ValueList;
	
	ObjectsArray.Add(Document);
	PrintObjects.Add(Document);
	
	SpreadsheetDocument = Documents.PriceSetup.CreatePrintedFormForSettingProductPrices(
		ObjectsArray,
		PrintObjects,
		PrintParameters);
		
	TempFileName = GetTempFileName();
	SpreadsheetDocument.Write(TempFileName, SpreadsheetDocumentFileType.XLS97);
	
	FileAddressInTempStorage = PutToTempStorage(
		New BinaryData(TempFileName), UUID);
	
	Try
		DeleteFiles(TempFileName);
	Except
		
		ExceptionText = NStr("vi = '%1';
							|ru = '%1';
							|en = '%1'; fa = '%1';
							|it = '%1';
							|pl = '%1';
							|tr = '%1'", Common.DefaultLanguageCode());
		ExceptionText = StrTemplate(ExceptionText, "PriceSetup.UploadingToExcel");
		
		WriteLogEvent(ExceptionText,
			EventLogLevel.Error,
			Metadata.Documents.PriceSetup,,
			ErrorDescription());
	EndTry;
	
	Return FileAddressInTempStorage;
	
EndFunction

// Uploads the price list to excel
//
// Parameters:
//  Document - DocumentRef - documents to upload
//  AdditionalParameters - Structure - Set of parameters
//
// Returns:
//  String - Temporary storage address
//
Function UploadToExcelWithoutWEBLink(Document, AdditionalParameters) Export
	
	ObjectsArray = New Array;
	PrintObjects  = New ValueList;
	
	ObjectsArray.Add(Document);
	PrintObjects.Add(Document);
	
	SpreadsheetDocument = Documents.PriceSetup.CreatePrintedFormForSettingProductPrices(
		ObjectsArray,
		PrintObjects,
		AdditionalParameters.PrintParameters);

	TempFileName = GetTempFileName("xls");
		
	SpreadsheetDocument.Write(TempFileName, SpreadsheetDocumentFileType.XLS97);
		
	DocumentsPackage = SettingPricesServer.AddAdditionalData(AdditionalParameters, TempFileName);	
		
	DocumentsPackage.Write(TempFileName, RepresentableDocumentBatchFileType.XLS);
	
	FileAddressInTempStorage = PutToTempStorage(
		New BinaryData(TempFileName), AdditionalParameters.UUID);
	
	Try
		DeleteFiles(TempFileName);
	Except
		
		ExceptionText = NStr("vi = '%1';
							|ru = '%1';
							|en = '%1'; fa = '%1';
							|it = '%1';
							|pl = '%1';
							|tr = '%1'", Common.DefaultLanguageCode());
		ExceptionText = StrTemplate(ExceptionText, "PriceSetup.UploadingToExcel");
		
		WriteLogEvent(ExceptionText,
			EventLogLevel.Error,
			Metadata.Documents.PriceSetup,,
			ErrorDescription());
	EndTry;
	
	Return FileAddressInTempStorage;
	
EndFunction

#EndRegion

#Region Other

// Returns the document number within a day
//
// Parameters:
//  DocumentDate - Date - The date on which it is necessary to calculate the number
//  Ref - DocumentRef.PriceSetup - Link to the price setting document
//
// Returns:
//  Number - document number
//
Function CalculateNumberWithinDay(DocumentDate, Ref) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	ISNULL(MAX(T.Period), DATETIME(1, 1, 1)) AS Date
	|FROM
	|	InformationRegister.ItemsPrices AS T
	|WHERE
	|	T.Recorder <> &Ref
	|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(MAX(T2.Period), DATETIME(1, 1, 1))
	|FROM
	|	InformationRegister.ItemsPrices25 AS T2
	|WHERE
	|	T2.Recorder <> &Ref
	|	AND T2.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|ORDER BY
	|	Date DESC");
	
	Query.SetParameter("BeginOfPeriod", BegOfDay(DocumentDate));
	Query.SetParameter("EndOfPeriod", EndOfDay(DocumentDate));
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() And ValueIsFilled(Selection.Date) Then
		// The beginning of the day is 0 seconds. Since at least one document already exists,
		// you need to add 1 (0 second corresponds to the document number 1).
		// We will also add one, since we need the number of the next document.
		Return Selection.Date - BegOfDay(DocumentDate) + 2;
	Else
		Return 1;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion
