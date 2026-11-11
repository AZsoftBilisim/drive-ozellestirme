
#Region Public

// Get addresses of the data layout scheme in temporary storage
//
// Parameters:
//  Form - ClientApplicationForm - The Form contains, among other things:
//  	* Object - DocumentObject - Document
//  Name - String - Schema name.
// 
// Returns:
//  Structure - addresses of the data layout scheme in the temporary storage.
//
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(Form, Name) Export
	
	If TypeOf(Form.Object.Ref) = Type("CatalogRef.DiscountsMarkups") Then
		If Name = "SettingsComposerFilterByProducts" Then
			TemplateName = "RowsFilterItems";
		Else
			If GetFunctionalOption("UseItemVariants") Then
				TemplateName = "RowsFilterAdditionalConditions";
			Else
				TemplateName = "RowsFilterAdditionalConditionsWithoutCharacteristic";
			EndIf;
		EndIf;
	ElsIf TypeOf(Form.Object.Ref) = Type("CatalogRef.DiscountMarkupTerms") Then
		TemplateName = "FilterTermsAmountQuantity";
	EndIf;
	
	Addresses = New Structure;
	
	Template = Catalogs.DiscountsMarkups.GetTemplate(TemplateName);
	Set = Template.DataSets.Find("DataSet");
	ProvisionInDocumentsServer.DiscountsSurchargesReplaceBalanceInWarehouseRedefinable(Set.Query);
	Fields = "FilterByProductCategory.Products,FilterByProductCategory.Characteristic,FilterByProductCategory.Warehouse";
	Set.Query = InformationRegisters.ProductRestrictions.SubstituteConnection(Set.Query, "SubstituteGoodsRestriction", Fields);
	
	Addresses.Insert("DataCompositionSchema", PutToTempStorage(Template, Form.UUID));
	Addresses.Insert("DataCompositionSettings",
		PutToTempStorage(
			Form[Name].GetSettings(), Form.UUID));
	
	Return Addresses;
	
EndFunction

// Description of the external processing action
//
// Parameters:
//  ExternalDataProcessor - ExternalDataProcessor - The object of connected processing.
//  AddressOfExternalDataProcessorSettings - String - Address of settings in temporary storage.
// 
// Returns:
//  String - Description of the external processing action.
//
Function DescriptionOfTheExternalProcessingAction(ExternalDataProcessor, AddressOfExternalDataProcessorSettings) Export
	
	ExternalObject = DiscountsMarkupsCached.ExternalDataProcessorObject(ExternalDataProcessor);
	
	If ValueIsFilled(AddressOfExternalDataProcessorSettings) Then
		Parameters = GetFromTempStorage(AddressOfExternalDataProcessorSettings);
	Else
		Parameters = Undefined;
	EndIf;
	
	SetSafeMode(True);
	LongDesc = ExternalObject.ActionDetails(Parameters);
	SetSafeMode(False);
	
	Return LongDesc;
	
EndFunction

// Auto-naming external processing
//
// Parameters:
//  ExternalDataProcessor - ExternalDataProcessor - The object of connected processing.
//  AddressOfExternalDataProcessorSettings - String - Address of settings in temporary storage.
// 
// Returns:
//  String - Description
//
Function AutomaticNamingOfExternalDataProcessor(ExternalDataProcessor, AddressOfExternalDataProcessorSettings) Export
	
	ExternalObject = DiscountsMarkupsCached.ExternalDataProcessorObject(ExternalDataProcessor);
	
	If ValueIsFilled(AddressOfExternalDataProcessorSettings) Then
		Parameters = GetFromTempStorage(AddressOfExternalDataProcessorSettings);
	Else
		Parameters = Undefined;
	EndIf;
	
	SetSafeMode(True);
	AutoDescription = ExternalObject.AutoDescription(Parameters);
	SetSafeMode(False);
	
	Return AutoDescription;
	
EndFunction

// Name of the external processing settings form
//
// Parameters:
//  ExternalDataProcessor - ExternalDataProcessor - The object of connected processing.
//  AddressOfExternalDataProcessorSettings - String - Address of settings in temporary storage.
// 
// Returns:
//  String - Name of the external processing settings form.
//
Function NameOfExternalDataProcessorSettingForm(ExternalDataProcessor, AddressOfExternalDataProcessorSettings) Export
	
	DataProcessorName = DiscountsMarkupsCached.AttachExternalDataProcessor(ExternalDataProcessor);
	ExternalObject = DiscountsMarkupsCached.ExternalDataProcessorObject(ExternalDataProcessor);
	
	SetSafeMode(True);
	Try
		SettingsFormName = ExternalObject.SettingsFormName();
		If TypeOf(SettingsFormName) <> Type("String") Then
			SettingsFormName = "";
		EndIf;
	Except
		SettingsFormName = "";
	EndTry;
	SetSafeMode(False);
	
	If ValueIsFilled(SettingsFormName) Then
		Return "ExternalDataProcessor."+ DataProcessorName +".Form."+SettingsFormName;
	Else
		Return "";
	EndIf;
	
EndFunction

// Description of external processing
//
// Parameters:
//  ExternalDataProcessor - ExternalDataProcessor - The object of connected processing.
//  AddressOfExternalDataProcessorSettings - String - Address of settings in temporary storage.
// 
// Returns:
//  Structure - Description of external processing.
//
Function DescriptionOfExternalProcessing(ExternalDataProcessor, AddressOfExternalDataProcessorSettings) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("SettingsFormName", NameOfExternalDataProcessorSettingForm(ExternalDataProcessor, AddressOfExternalDataProcessorSettings));
	ReturnValue.Insert("AutoDescription", AutomaticNamingOfExternalDataProcessor(ExternalDataProcessor, AddressOfExternalDataProcessorSettings));
	ReturnValue.Insert("ActionDetails", DescriptionOfTheExternalProcessingAction(ExternalDataProcessor, AddressOfExternalDataProcessorSettings));
	
	Return ReturnValue;
	
EndFunction

// Data for displaying a list of products
//
// Parameters:
//  Ref - CatalogRef.DiscountsMarkups - Discount (extra charge).
// 
// Returns:
//  Structure - Data for presenting a list of products.
//
Function DataForPresentationOfListOfProducts(Ref) Export

	Query = New Query("
	|SELECT TOP 3
	|	T.Products.Presentation AS NomenclatureName,
	|	T.Characteristic.Presentation AS CharacteristicName
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkupsByItems.SliceLast(&CurrentDate, Source = &Source) AS T
	|WHERE
	|	T.Status = &Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(1) AS NumberOfRows
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkupsByItems.SliceLast(&CurrentDate, Source = &Source) AS T
	|WHERE
	|	T.Status = &Status
	|");
	Query.Parameters.Insert("CurrentDate", CurrentSessionDate());
	Query.Parameters.Insert("Source", Ref);
	Query.Parameters.Insert("Status", Enums.DiscountValidityStatuses.Valid);
	
	FirstPositions = New Array;
	
	QueriesArray = Query.ExecuteBatch();
	QueryResult = QueriesArray[0]; // QueryResult
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		Description = ProductsClientServer.PresentationOfProductsForPrinting(
				Selection.NomenclatureName,
				Selection.CharacteristicName);
		FirstPositions.Add(Description);
	EndDo;
	
	QueryResult = QueriesArray[1]; // QueryResult
	Selection = QueryResult.Select();
	Selection.Next();
	
	ReturnValue = New Structure;
	ReturnValue.Insert("FirstPositions", FirstPositions);
	ReturnValue.Insert("TotalItems", Selection.NumberOfRows);
	
	Return ReturnValue;
	
EndFunction

#EndRegion