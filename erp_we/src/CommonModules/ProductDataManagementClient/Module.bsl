////////////////////////////////////////////////////////////////////////////////
// NSI of production: Procedures of the subsystem of product data management
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Specifications

// Opens a form to select specifications for the item
//
// Parameters:
//  ProductData				 - See ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection
//  BOMSelectionParameters	 - See ProductDataManagementClientServer.BOMSelectionParameters
//  Owner					 - ClientApplicationForm		- owner of the form.
//
Procedure OpenFormForSelectingSpecificationsByProductType(ProductData, BOMSelectionParameters = Undefined, Owner = Undefined) Export
	
	FormParameters = New Structure;
	
	For Each KeyAndValue In ProductData Do
		FormParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	If BOMSelectionParameters <> Undefined Then
		SourceOfParameters = BOMSelectionParameters;
	Else
		SourceOfParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	EndIf;
	
	For Each KeyAndValue In SourceOfParameters Do
		If KeyAndValue.Key <> "GetProductBOM"
			And KeyAndValue.Key <> "GetSpecificationsFromListOfProducts" Then
			FormParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndIf;
	EndDo;
	
	FormParameters.Insert("GetProductBOM", True);
	
	OpenForm("Catalog.BillsOfMaterials.Form.ChoiceFormByItems", FormParameters, Owner);
	
EndProcedure

// Opens the form for selecting specifications from the list of items
//
// Parameters:
//  ProductData_2			 - See ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection
//  BOMSelectionParameters	 - See ProductDataManagementClientServer.BOMSelectionParameters
//  Owner					 - ClientApplicationForm	 - owner of the form.
//  CallbackDescription			 - CallbackDescription - description of the alert.
//
Procedure OpenFormForSelectingSpecificationsFromListOfProducts(ProductData_2, BOMSelectionParameters = Undefined, Owner = Undefined, CallbackDescription = Undefined) Export
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ProductData_2", ProductData_2);
	
	If BOMSelectionParameters <> Undefined Then
		SourceOfParameters = BOMSelectionParameters;
	Else
		SourceOfParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	EndIf;
	For Each KeyAndValue In SourceOfParameters Do
		If KeyAndValue.Key <> "GetProductBOM"
			And KeyAndValue.Key <> "GetSpecificationsFromListOfProducts" Then
			FormParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndIf;
	EndDo;
	FormParameters.Insert("GetSpecificationsFromListOfProducts", True);
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ChoiceFormByItems",
		FormParameters,
		Owner,,,,
		CallbackDescription);
		
EndProcedure

// Copies the specification and production process
//
// Parameters:
//  Source							- CatalogRef.BillsOfMaterials - specification you want to copy
//  DescriptionOfPostCopyProcessing	- CallbackDescription - contains a description of the procedure to be called after copying.
//
Procedure CopyResourceSpecification(Source, DescriptionOfPostCopyProcessing = Undefined) Export

	QueryText = NStr("vi = 'Sẽ tạo và ghi bản sao của bảng kê chi tiết nguồn lực.
								|Sao chép?';
								|ru = 'Будет создана и записана копия ресурсной спецификации.
								|Скопировать?';
								|en = 'A BOM copy will be created and saved.
								|Do you want to copy?'; fa = 'A BOM copy will be created and saved.
								|Do you want to copy?';
								|it = 'Будет создана и записана копия ресурсной спецификации.
								|Скопировать?';
								|pl = 'A BOM copy will be created and saved.
								|Do you want to copy?';
								|tr = 'Ürün reçetesinin kopyası oluşturulacak ve kaydedilecektir.
								|Kopyalansın mı?'");
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Sao chép';
												|ru = 'Скопировать';
												|en = 'Copy'; fa = 'کپی';
												|it = 'Copiare';
												|pl = 'Copy';
												|tr = 'Kopyala'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	AdditionalParameters = New Structure("Source,DescriptionOfPostCopyProcessing", Source, DescriptionOfPostCopyProcessing);
	CallbackDescription = New CallbackDescription("CopyResourceSpecificationCompletion", ThisObject, AdditionalParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

// Sets a new status for specifications
//
// Parameters:
//	NewStatus				- EnumRef.BOMStatuses - New status
//	StatusPresentation	- String - the introduction of the new status
//  ArrayOfSpecifications		- Array - list of specifications.
//
Procedure SetStatusOfSpecifications(NewStatus, StatusPresentation, ArrayOfSpecifications) Export
	
	If ArrayOfSpecifications.Count() = 0 Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StatusValue",      NewStatus);
	AdditionalParameters.Insert("StatusPresentation", StatusPresentation);
	AdditionalParameters.Insert("HighlightedLinks",     ArrayOfSpecifications);
	CallbackDescription = New CallbackDescription("SetStatusOfSpecificationsCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất được chọn sẽ được đặt thành trạng thái ""%1"". Tiếp tục?';
					|ru = 'Выбранным спецификациям будет установлен статус ""%1"". Продолжить?';
					|en = 'Status ""%1"" will be set for the selected BOMs. Continue?'; fa = 'Status ""%1"" will be set for the selected BOMs. Continue?';
					|it = 'Alle specifiche selezionate sarà impostato lo stato ""%1"". Continuare?';
					|pl = 'Wybranej specyfikacji zostanie zainstalowany status ""%1"". Kontynuować?';
					|tr = 'Seçili ürün reçetesinde ""%1"" durumu ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, StatusPresentation);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Issue a disassembly specification based on the assembly
// 
// Parameters:
//  Source - CatalogRef.BillsOfMaterials
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure CreateReverseKittingBasedOnKitting(Source, ExecutionParameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", ProductDataManagementServerCall.FillingReverseKittingDataBasedOnKITTING(Source));
	
	OpenForm("Catalog.BillsOfMaterials.Form.ItemForm", FormParameters);
	
EndProcedure


#EndRegion

#Region RouteSheets

// Generates a notification about the main route map entry.
// Used to update data in forms and to inform the user about a completed operation.
//
// Parameters:
//  RecordProperties - Structure, InformationRegisterRecord.MainRouteSheets - contains the values of the record properties.
//  URL - String - navigation link to the modified record.
//
Procedure NotifyAboutRecordingOfMainRouteMap(RecordProperties = Undefined, URL = Undefined) Export
	
	If RecordProperties <> Undefined Then
		RecordStructure = New Structure;
		RecordStructure.Insert("Department",   RecordProperties.Department);
		RecordStructure.Insert("Products",    RecordProperties.Products);
		RecordStructure.Insert("Characteristic",  RecordProperties.Characteristic);
		RecordStructure.Insert("RouteSheet", RecordProperties.RouteSheet);
	Else
		RecordStructure = Undefined;
	EndIf; 
	
	Notify("Write_MainRouteSheets", RecordStructure);
	NotifyChanged(Type("InformationRegisterRecordKey.MainRouteSheets"));
	
	If URL <> Undefined Then
		ShowUserNotification(NStr("vi = 'Sơ đồ quy trình chính đã thay đổi.';
									|ru = 'Изменена основная маршрутная карта';
									|en = 'Main route sheet is changed'; fa = 'Main route sheet is changed';
									|it = 'Scheda di lavorazione modificata';
									|pl = 'Zmieniono podstawową kartę technologiczną';
									|tr = 'Temel rota değiştirildi'"), URL);
		UserWorkHistory.Add(URL);
	EndIf; 
	
EndProcedure

// Sets a new status for specifications
//
// Parameters:
//	NewStatus				- EnumRef.BOMStatuses - New status
//	StatusPresentation	- String - the introduction of the new status
//  ObjectsArray			- Array - list of route maps.
//
Procedure SetRouteMapStatus(NewStatus, StatusPresentation, ObjectsArray) Export
	
	If ObjectsArray.Count() = 0 Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StatusValue",      NewStatus);
	AdditionalParameters.Insert("StatusPresentation", StatusPresentation);
	AdditionalParameters.Insert("HighlightedLinks",     ObjectsArray);
	CallbackDescription = New CallbackDescription("SetRouteMapStatusCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Sơ đồ quy trình đã chọn sẽ được đặt thành trạng thái ""%1"". Tiếp tục?';
					|ru = 'Выбранным маршрутным картам будет установлен статус ""%1"". Продолжить?';
					|en = 'Status ""%1"" will be set for the selected route sheets. Continue?'; fa = 'Status ""%1"" will be set for the selected route sheets. Continue?';
					|it = 'Alle schede di lavorazione selezionate verrà impostato lo stato ""%1"". Continuare?';
					|pl = 'Dla wybranych kart technologicznych będzie zmieniony status ""%1"". Kontynuować?';
					|tr = 'Seçili rotalar için ""%1"" durumu ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, StatusPresentation);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

// Opens the automatic item selection settings form
//
// Parameters:
//  OwnerForm - ClientApplicationForm - the form from which the Autoselect setting is called
//  TSName - String - name of the table part
//  PropertyMapping	- TabularSection - contains properties that are used for automatic feature selection
//  ProductTypeOrProductRange - CatalogRef.ItemKinds - defines a list of available properties to select
//  PropertyNameIsSpecifiedByVNSI - String - the title of the enumeration value is specified by the Enum
//  ReadOnly - Boolean - open the form for viewing only.
//
Procedure ConfigureProductsAutoselection(
	OwnerForm,
	TSName,
	PropertyMapping,
	ProductTypeOrProductRange,
	PropertyNameIsSpecifiedByVNSI,
	ReadOnly = False) Export
	
	RowData = OwnerForm.Items[TSName].CurrentData;
	
	If RowData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	FormParameters.Insert("PropertyMapping", PropertyMapping);
	
	FormParameters.Insert("ProductTypeOrProductRange",        ProductTypeOrProductRange);
	FormParameters.Insert("PropertyThatContainsProducts",   RowData.PropertyThatContainsProducts);
	FormParameters.Insert("MethodOfProductsAutoselection",     RowData.MethodOfProductsAutoselection);
	FormParameters.Insert("MethodOfItemVariantAutoselection",   RowData.MethodOfItemVariantAutoselection);
	FormParameters.Insert("ItemVariantAutoSelectionAlgorithm", RowData.ItemVariantAutoSelectionAlgorithm);
	
	FormParameters.Insert("Products",   RowData.Products);
	FormParameters.Insert("Characteristic", RowData.Characteristic);
	
	FormParameters.Insert("LongDesc", Undefined);
	If Not RowData.Property("MaterialApplication", FormParameters.LongDesc) Then
		RowData.Property("ProductDescription", FormParameters.LongDesc);
	EndIf;
	
	FormParameters.Insert("TSName", TSName);
	FormParameters.Insert("PropertyNameIsSpecifiedByVNSI", PropertyNameIsSpecifiedByVNSI);
	
	OpenForm("CommonForm.ConfigureProductAutoSelection", FormParameters, OwnerForm);
	
EndProcedure

// Opens the form for configuring selection by properties and the algorithm for calculating the quantity
//
// Parameters:
//  OwnerForm - ClientApplicationForm - the form from which the setting is called
//  TSName - String - table name (materials, Services, labor Costs, types of work Centers)
//  SelectionByProperties - TabularSection - the table part with selections for properties
//  ProductTypeOrProductRange  - CatalogRef.ItemKinds - defines a list of available properties to select
//  ReadOnly - Boolean - open the form for viewing only
//  CompositionOfSettings  - Structure  - settings open the form
//  AdditionalDataAddress  - String  - 
//
Procedure ConfigureSelectionByPropertiesAndCalculationByFormulas(
	OwnerForm,
	TSName,
	SelectionByProperties,
	ProductTypeOrProductRange,
	ReadOnly,
	CompositionOfSettings = Undefined,
	AdditionalDataAddress = "") Export
	
	RowData = OwnerForm.Items[TSName].CurrentData;
	
	If RowData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure(
		"TSName,
		|ReadOnly,
		|CompositionOfSettings,
		|
		|QuantityCalculationAlgorithm,
		|
		|ProductTypeOrProductRange,
		|AdditionalDataAddress
		|");
	
	FillPropertyValues(FormParameters, RowData);
	
	FormParameters.TSName = TSName;
	
	FormParameters.ReadOnly = ReadOnly;
	FormParameters.CompositionOfSettings = CompositionOfSettings;
	
	FormParameters.ProductTypeOrProductRange = ProductTypeOrProductRange;
	FormParameters.AdditionalDataAddress = AdditionalDataAddress;
	
	FormParameters.Insert("SelectionByProperties", SelectionByProperties);
	
	OpenForm("CommonForm.ConfigureFilterByPropertiesAndCalculationUsingFormulas", FormParameters, OwnerForm);
	
EndProcedure

// Performs actions when deleting from the table part
// - removes the settings for auto-select.
//
// Parameters:
//  FormTable				- FormTable - table of the form where the list of items is located
//  SelectedRows			- Array - contains an array of IDs of the selected rows
//  PropertyMapping			- FormDataCollection - the tabular part of the "Sootvetstvovat".
//
Procedure ClearProductSelectionSettings(FormTable, SelectedRows, PropertyMapping) Export

	For Each RowID In SelectedRows Do
		RowData = FormTable.RowData(RowID);
		
		ProductDataManagementClientServer.ClearAutoSelectionSettingsByLine(
			RowData,
			PropertyMapping);
		
	EndDo; 
	
EndProcedure

// Performs actions when deleting from the table part
// - removes the settings selection on properties
//
// Parameters:
//  FormTable				- FormTable - table of the form where the list of items is located
//  SelectedRows			- Array - contains an array of IDs of the selected rows
//  SelectionByProperties			- FormDataCollection - the tabular part of the "AMBROSIASTER"
//
Procedure ClearSelectionSettingsByProperties(FormTable, SelectedRows, SelectionByProperties) Export
	
	For Each RowID In SelectedRows Do
		RowData = FormTable.RowData(RowID);
		
		ProductDataManagementClientServer.ClearSelectionSettingsByPropertiesByRow(
			RowData,
			SelectionByProperties);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Performs actions when deleting work center views from the table part
// - removes alternative types of work centers.
//
// Parameters:
//  FormTable								- FormTable - table of the form where the list of types of work centers is located
//  AlternateWorkCenterTypes			- FormDataCollection - table part containing alternative types of work centers.
//
Procedure BeforeRemovingKindsOfWorkCenters(FormTable, AlternateWorkCenterTypes) Export

	SelectedRows = FormTable.SelectedRows;
	For Each RowID In SelectedRows Do
		RowData = FormTable.RowData(RowID);
		
		TheStructureOfTheSearch = New Structure("LinkKeyWorkCenterTypes", RowData.ConnectionKey);
		StringsList = AlternateWorkCenterTypes.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In StringsList Do
			AlternateWorkCenterTypes.Delete(FoundRow);
		EndDo; 
	EndDo; 
	
EndProcedure

// Resource specification copy notification
// 
// Parameters:
// 	QuestionResult - DialogReturnCode - user selection
// 	AdditionalParameters - Structure - From:
//		* Source - CatalogRef.BillsOfMaterials - copied specification
//		* DescriptionOfPostCopyProcessing - String - procedure name
Procedure CopyResourceSpecificationCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Ref = ProductDataManagementServerCall.CopyResourceSpecification(AdditionalParameters.Source);
	
	CopyResourceSpecificationAfterCopying(Ref, AdditionalParameters.DescriptionOfPostCopyProcessing);
	
EndProcedure

Procedure CopyResourceSpecificationAfterCopying(Ref, DescriptionOfPostCopyProcessing = Undefined) Export
	
	If Ref <> Undefined Then
		
		NotifyChanged(Type("CatalogRef.BillsOfMaterials"));
		Notify("Write_ProductionStages");
		ShowValue(, Ref);
		
		ShowUserNotification(
				NStr("vi = 'Tạo:';
					|ru = 'Создание:';
					|en = 'Create:'; fa = 'ایجاد:';
					|it = 'Создание:';
					|pl = 'Create:';
					|tr = 'Oluşturma:'"), 
				GetURL(Ref), 
				Ref);
		
		If DescriptionOfPostCopyProcessing <> Undefined Then
			RunCallback(DescriptionOfPostCopyProcessing, Ref);
		EndIf; 
		
	Else
		
		ShowMessageBox(, NStr("vi = 'Không thể sao chép bảng kê chi tiết nguồn lực.';
								|ru = 'Не удалось скопировать ресурсную спецификацию.';
								|en = 'Cannot copy BOM.'; fa = 'Cannot copy BOM.';
								|it = 'Non è stato possibile copiare la specifica delle risorse.';
								|pl = 'Nie udało się skopiować specyfikację zasobów.';
								|tr = 'Ürün reçetesi kopyalanamadı.'"));
		
	EndIf;
	
EndProcedure

Procedure SetStatusOfSpecificationsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = ProductDataManagementServerCall.SetStatusOfSpecifications(
										AdditionalParameters.HighlightedLinks, 
										AdditionalParameters.StatusValue);
										
	TMCommonUseClient.NotifyUserAboutSettingStatus(
			Undefined,
			ProcessedItemsCount, 
			AdditionalParameters.HighlightedLinks.Count(), 
			AdditionalParameters.StatusPresentation);
			
	Notify("Write_BillsOfMaterials");
	NotifyChanged(Type("CatalogRef.BillsOfMaterials"));
	
EndProcedure

Procedure SetRouteMapStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = ProductDataManagementServerCall.SetRouteMapStatus(
										AdditionalParameters.HighlightedLinks, 
										AdditionalParameters.StatusValue);
										
	TMCommonUseClient.NotifyUserAboutSettingStatus(
			Undefined,
			ProcessedItemsCount, 
			AdditionalParameters.HighlightedLinks.Count(), 
			AdditionalParameters.StatusPresentation);
			
	Notify("Write_RouteSheets");
	NotifyChanged(Type("CatalogRef.RouteSheets"));
	
EndProcedure

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

// Notification of completion of auto-selection settings
// 
// Parameters:
// 	SettingsResult - Structure - the result of the setting:
// 		* LongDesc - String - configuration description
// 	RowData - FormDataCollectionItem - this line
// 	PropertyMapping - FormDataCollection - table setting matching the properties of
// Returns:
// 	Boolean - Result status
//
Function ConfigureProductsAutoselectionCompletion(SettingsResult, RowData, PropertyMapping) Export

	If SettingsResult = Undefined Then
		Return False;
	EndIf;
	
	FillPropertyValues(RowData,
							SettingsResult,
							"Products,Characteristic,ProductsAsAString,CharacteristicAsAString,
							|MethodOfProductsAutoselection,MethodOfItemVariantAutoselection,
							|ItemVariantAutoSelectionAlgorithm, PropertyThatContainsProducts");
	
	If RowData.Property("MaterialApplication") Then
		RowData.MaterialApplication = SettingsResult.LongDesc;
	ElsIf RowData.Property("ProductDescription") Then
		RowData.ProductDescription = SettingsResult.LongDesc;
	EndIf;
	
	// Delete the old settings
	TheStructureOfTheSearch = New Structure("ConnectionKey", RowData.ConnectionKey);
	StringsList = PropertyMapping.FindRows(TheStructureOfTheSearch);
	For Each String_Matching In StringsList Do
		PropertyMapping.Delete(String_Matching);
	EndDo;
	
	// Update the data
	If ValueIsFilled(SettingsResult.PropertyMapping) Then
		For Each Item In SettingsResult.PropertyMapping Do
			ConfiguringCompliance = PropertyMapping.Add();
			FillPropertyValues(ConfiguringCompliance, Item);
			ConfiguringCompliance.ConnectionKey = RowData.ConnectionKey;
		EndDo;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    RowData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", RowData.Package);
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowData, StructureOfActions, Undefined);
	
	Return True;
	
EndFunction

Function ConfigureSelectionByPropertiesAndCalculationByFormulasCompletion(SettingsResult, RowData, SelectionByProperties) Export

	If SettingsResult = Undefined Then
		Return False;
	EndIf;
	
	RowData.QuantityCalculationAlgorithm = SettingsResult.QuantityCalculationAlgorithm;
	RowData.CalculationByFormula = Not IsBlankString(RowData.QuantityCalculationAlgorithm);
	
	UpdateSelectionSettingsByPropertiesByKey(SelectionByProperties, SettingsResult.SelectionByProperties, RowData.ConnectionKey);
	
	RowData.FilterByPropertiesIsSet = SettingsResult.SelectionByProperties.Count() > 0;
	
	Return True;
	
EndFunction

Procedure UpdateSelectionSettingsByPropertiesByKey(Table, Setting, ConnectionKey) Export
	
	TheStructureOfTheSearch = New Structure("ConnectionKey", ConnectionKey);
	StringsList = Table.FindRows(TheStructureOfTheSearch);
	For Each StringCondition In StringsList Do
		Table.Delete(StringCondition);
	EndDo;
	
	For Each Condition In Setting Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Condition);
		NewRow.ConnectionKey = ConnectionKey;
	EndDo;
	
EndProcedure

Function DetailsOfSettingsByLineInArray(RowData, SettingsTable, AttributesList) Export
	
	Result = New Array;
	
	TheStructureOfTheSearch = New Structure("ConnectionKey", RowData.ConnectionKey);
	
	StringsList = SettingsTable.FindRows(TheStructureOfTheSearch);
	For Each String In StringsList Do
		StringDataStructure = New Structure(AttributesList);
		FillPropertyValues(StringDataStructure, String);
		Result.Add(StringDataStructure);
	EndDo; 
	
	Return Result;
	
EndFunction

Procedure SelectionByPropertiesBeforeRowChange(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	PropertySelectionSetTypeConstraintForValue(Form, CurrentData, ConditionsStructure, PropertyTableRows[0].ValueType);
	
EndProcedure

Procedure SelectionOfPropertiesPropertyIsWhenYouChange(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	CurrentData.Condition  = "Equal";
	
	TypeOfValueGiven = 
		PropertySelectionSetTypeConstraintForValue(Form, CurrentData, ConditionsStructure, PropertyTableRows[0].ValueType);
	
	CurrentData.Value = TypeOfValueGiven.AdjustValue(Undefined);
	
EndProcedure

Procedure TheSelectionOfThePropertiesSubjectToChange(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	CurrentCondition = ConditionsStructure[CurrentData.Condition];
	
	TypeOfValueGiven = 
		PropertySelectionSetTypeConstraintForValue(Form, CurrentData, ConditionsStructure, PropertyTableRows[0].ValueType);
	
	If CurrentCondition.List Then
		
		CurrentData.Value = New ValueList;
		CurrentData.Value.ValueType = TypeOfValueGiven;
		
	Else
		
		If CurrentCondition.Interval Or CurrentCondition.Fullness Then
			CurrentData.Value = Undefined;
		EndIf;
		
		CurrentData.Value = TypeOfValueGiven.AdjustValue(CurrentData.Value);
		
	EndIf;
	
	For It = 1 To 2 Do
		CurrentData["Value"+It] = TypeOfValueGiven.AdjustValue(Undefined);
	EndDo;
	
EndProcedure

// Handler for the start of the selection conditions for the selection of properties
// 
// Parameters:
// 	Form - ClientApplicationForm- Form
// 	CurrentData - FormDataCollectionItem - row of the table forms
// 	TableOfAvailableProperties - ValueTable - available properties
// 	ConditionsStructure - Structure - Conditions
Procedure SelectionOfPropertiesTheConditionOfTheBeginningOfTheSelection(
	Form,
	CurrentData,
	TableOfAvailableProperties,
	ConditionsStructure) Export
	
	ChoiceList = Form.Items.Condition.ChoiceList;
	ChoiceList.Clear();
	
	PropertyTableRows = 
		TableOfAvailableProperties.FindRows(New Structure("Property", CurrentData.Property));
		
	If Not ValueIsFilled(PropertyTableRows) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ConditionsStructure Do
		Condition = KeyAndValue.Value; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
		If Condition.Comparison 
			And Not PropertyTableRows[0].ValueType.ContainsType(Type("Number"))
			And Not PropertyTableRows[0].ValueType.ContainsType(Type("Date"))
		Then
			Continue;
		EndIf;
		ChoiceList.Add(Condition.Id, Condition.Presentation);
	EndDo;
	
EndProcedure

Procedure SelectionByPropertiesValueIntervalWhenChanging(CurrentData, AttributeName) Export

	ValueTypeFilter = New TypeDescription(
		CommonClientServer.ValueInArray(TypeOf(CurrentData[AttributeName])));
	
	For It = 1 To 2 Do
		CurrentData["Value"+It] = ValueTypeFilter.AdjustValue(CurrentData["Value"+It]);
	EndDo;
	
EndProcedure

// Sets the type restriction for the selection element by properties
// 
// Parameters:
// 	Form - ClientApplicationForm- Form
// 	CurrentData - FormDataCollectionItem - Form table row - from:
// 		* Condition - String - condition ID
// 	ConditionsStructure - Structure - Conditions
// 	ValueType - TypeDescription - the value type of the source
// Returns:
// 	TypeDescription - the type of value given
Function PropertySelectionSetTypeConstraintForValue(
	Form,
	CurrentData,
	ConditionsStructure,
	ValueType) Export
	
	CurrentCondition = ConditionsStructure[CurrentData.Condition]; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
	
	If CurrentCondition.Comparison Then
		RemovedTypes = New Array;
		For Each Type In ValueType.Types() Do
			If Not Type = Type("Date") And Not Type = Type("Number") Then
				RemovedTypes.Add(Type);
			EndIf;
		EndDo;
		TypeOfValueGiven = New TypeDescription(ValueType,,RemovedTypes);
	Else
		TypeOfValueGiven = ValueType;
	EndIf;
	
	ChoiceParameters = New Array;
	If ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", CurrentData.Property));
	EndIf;
	
	Form.Items.Value.ChoiceParameters = New FixedArray(ChoiceParameters);
	If CurrentCondition.List Then
		Form.Items.Value.TypeRestriction = New TypeDescription("ValueList");
	ElsIf CurrentCondition.Interval Then
		Form.Items.Value1.TypeRestriction = TypeOfValueGiven;
		Form.Items.Value2.TypeRestriction = TypeOfValueGiven;
	Else
		Form.Items.Value.TypeRestriction  = TypeOfValueGiven;
	EndIf;
	
	Return TypeOfValueGiven;
	
EndFunction

// Checks whether the selection by properties is configured correctly
// 
// Parameters:
// 	SelectionByProperties - FormDataCollection - table of set selections
// 	TableOfAvailableProperties - FormDataCollection - property sheet
// 	HasErrors - Boolean - a sign of the presence of errors
// Returns:
// 	Array - array of configuration items
//
Function SelectionByPropertiesPerformControlGenerateResultOfSetting(
	SelectionByProperties,
	TableOfAvailableProperties,
	HasErrors) Export
	
	TemplateFieldNotFilledIn  = NStr("vi = 'Lỗi điền cài đặt trên dòng  %1.';
									|ru = 'Ошибка заполнения настройки в строке %1.';
									|en = 'An error occurred when filling in settings in line %1.'; fa = 'An error occurred when filling in settings in line %1.';
									|it = 'Errore durante la compilazione dell''impostazione nella riga %1.';
									|pl = 'Błąd wypełnienia ustawienia w wierszu %1.';
									|tr = '%1 satırındaki ayar doldurma hatası.'");
	TemplateInvalidProperty = NStr("vi = 'Thuộc tính được chỉ định không hợp lệ trên dòng  %1.';
									|ru = 'Указано неверное свойство в строке %1.';
									|en = 'Incorrect property is specified in line %1.'; fa = 'Incorrect property is specified in line %1.';
									|it = 'Parametro incorretto indicato nella riga %1.';
									|pl = 'Wskazano nieprawidłową właściwość w wierszu %1.';
									|tr = '%1 satırında yanlış özellik belirtildi.'");
	TemplateInvalidCondition  = NStr("vi = 'Lỗi điền cài đặt trên dòng  %1. Giá trị bên trái không thể lớn hơn bên phải.';
									|ru = 'Ошибка заполнения настройки в строке %1. Левое значение не может быть больше правого.';
									|en = 'An error occurred when filling in settings in line %1. The left value cannot be greater than the right one.'; fa = 'An error occurred when filling in settings in line %1. The left value cannot be greater than the right one.';
									|it = 'Errore di compilazione dell''impostazione nella riga %1. Il valore sinistro non può essere maggiore di quello destro.';
									|pl = 'Błąd wypełnienia ustawienia w wierszu %1. Lewa wartość nie może być większa od prawej.';
									|tr = '%1 satırındaki ayar doldurma hatası. Soldaki değer, sağdakinden büyük olamaz.'");
	DataPathTemplate      = "SelectionByProperties[%1].%2";
	
	Attributes        = ProductDataManagementClientServer.DetailsSettingUpSelectionByProperties();
	ConditionsStructure = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
	
	Result = New Array;
	
	For Each FIlterRow In SelectionByProperties Do
		
		If IsBlankString(FIlterRow.Condition) Then
			Continue;
		EndIf;
		
		RowIndex = SelectionByProperties.IndexOf(FIlterRow);
		
		CurrentCondition = ConditionsStructure[FIlterRow.Condition]; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
		
		If CurrentCondition.Interval Then
			If FIlterRow.Value1 <> Undefined
				And FIlterRow.Value2 <> Undefined
				And FIlterRow.Value1 > FIlterRow.Value2 Then
				CommonClient.MessageToUser(
					StrTemplate(TemplateInvalidCondition,RowIndex+1),,
					StrTemplate(DataPathTemplate, RowIndex, "Value1"),,
					HasErrors);
				Continue;
			EndIf;
			VerificationFields = StrSplit(StrReplace(Attributes,"Value","Value1,Value2"), ",");
		Else
			VerificationFields = StrSplit(Attributes, ",");
		EndIf;
		
		For Each Field In VerificationFields Do
			If Not ValueIsFilled(FIlterRow[Field])
				And Not FIlterRow[Field] = 0 
				And Not CurrentCondition.Fullness Then
				CommonClient.MessageToUser(
					StrTemplate(TemplateFieldNotFilledIn,RowIndex+1),,
					StrTemplate(DataPathTemplate, RowIndex, Field),,
					HasErrors);
			ElsIf Field = "Property" 
					And TableOfAvailableProperties.FindRows(New Structure("Property", FIlterRow[Field])).Count() = 0 Then
				CommonClient.MessageToUser(
					StrTemplate(TemplateInvalidProperty,RowIndex+1),,
					StrTemplate(DataPathTemplate, RowIndex, Field),,
					HasErrors);
			EndIf;
		EndDo;
		
		If HasErrors Then
			Continue;
		EndIf;
		
		If CurrentCondition.List Then
			For Each ListItem In FIlterRow.Value Do
				ConditionSettingsElement = New Structure(Attributes);
				FillPropertyValues(ConditionSettingsElement, FIlterRow);
				ConditionSettingsElement.Value = ListItem.Value;
				Result.Add(ConditionSettingsElement);
			EndDo;
		ElsIf CurrentCondition.Interval Then
			ConditionSettingsElement = New Structure(Attributes);
			ConditionSettingsElement.Property = FIlterRow.Property;
			ConditionSettingsElement.Condition  = ?(CurrentCondition.Id = "InInterval", "Greater", "GreaterOrEqual");
			ConditionSettingsElement.Value = FIlterRow.Value1;
			Result.Add(ConditionSettingsElement);
			
			ConditionSettingsElement = New Structure(Attributes);
			ConditionSettingsElement.Property = FIlterRow.Property;
			ConditionSettingsElement.Condition  = ?(CurrentCondition.Id = "InInterval", "Less", "LessOrEqual");
			ConditionSettingsElement.Value = FIlterRow.Value2;
			Result.Add(ConditionSettingsElement);
		Else
			ConditionSettingsElement = New Structure(Attributes);
			FillPropertyValues(ConditionSettingsElement, FIlterRow);
			Result.Add(ConditionSettingsElement);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

Procedure ShowCopyRouteMapWithOperationsQuestion(CallbackDescription) Export
	
	QueryText = NStr("vi = 'Sẽ tạo và ghi lại bản sao sơ đồ quy trình (bao gồm thao tác kỹ thuật).
								|Sao chép?';
								|ru = 'Будет создана и записана копия маршрутной карты (включая техоперации).
								|Скопировать?';
								|en = 'A copy of the route sheet will be created and saved (including manufacturing operations).
								|Continue?'; fa = 'A copy of the route sheet will be created and saved (including manufacturing operations).
								|Continue?';
								|it = 'Verrà creata e registrata una copia della scheda di lavorazione (incluse le operazioni tecniche)
								|Copiarla?';
								|pl = 'Zostanie utworzona i zapisana kopia karty technologicznej (łącznie z operacjami technicznymi).
								|Skopiować?';
								|tr = 'Rotanın bir kopyası oluşturulacak ve kaydedilecektir (teknolojik işlemler dahil).
								|Kopyalansın mı?'");
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Sao chép';
												|ru = 'Скопировать';
												|en = 'Copy'; fa = 'کپی';
												|it = 'Copiare';
												|pl = 'Copy';
												|tr = 'Kopyala'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

Procedure NotifyAboutCopyingRouteMapWithOperations() Export
	
	NotifyChanged(Type("CatalogRef.RouteSheets"));
	Notify("Write_ManufacturingOperations");
	
EndProcedure

Procedure ShowQuestionCopyWorkflowWithOperations(CallbackDescription) Export
	QueryText = NStr("vi = 'Sẽ tạo và ghi lại bản sao quy trình kỹ thuật (bao gồm các thao tác kỹ thuật).
								|Sao chép?';
								|ru = 'Будет создана и записана копия технологического процесса (включая техоперации).
								|Скопировать?';
								|en = 'A copy of the technological process (including technical operations) will be created and saved.
								|Copy?'; fa = 'A copy of the technological process (including technical operations) will be created and saved.
								|Copy?';
								|it = 'Verrà creata e registrata una copia del processo tecnologico (operazioni tecnologiche incluse).
								|Copiare?';
								|pl = 'Zostanie utworzona i zapisana kopia procesu technologicznego (w typ operacje techniczne).
								|Skopiować?';
								|tr = 'Teknolojik sürecin bir kopyası oluşturulacak ve kaydedilecektir (teknolojik işlemler dahil).
								|Kopyalansın mı?'");
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Sao chép';
												|ru = 'Скопировать';
												|en = 'Copy'; fa = 'کپی';
												|it = 'Copiare';
												|pl = 'Copy';
												|tr = 'Kopyala'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

Procedure NotifyAboutCopyingTechnologicalProcessWithOperations() Export
	NotifyChanged(Type("CatalogRef.TechnologicalProcesses"));
	Notify("Write_TechnologicalProcesses");
EndProcedure

#Region BOMsTree

Procedure SaveExpandedTreeLevels(Form, TreeRow = Undefined) Export
	
	Form.ExpandedLevelsOfCacheTree.ExpandedLevels = New Structure;
	
	SaveTreeLevelState(Form, 0, New Array, ?(TreeRow = Undefined, Form.BOMsTree, TreeRow));
	
EndProcedure

Procedure RestoreExpandedTreeLevels(Form, TreeRow = Undefined) Export
	
	ExpandedLevels = Form.ExpandedLevelsOfCacheTree.ExpandedLevels;
	If ExpandedLevels = Undefined Or ExpandedLevels.Count() = 0 Then
		Return;
	EndIf;
	
	RestoreTreeLevelState(Form, 0, New Array, ?(TreeRow = Undefined, Form.BOMsTree, TreeRow));
	
EndProcedure

// Saves the state of the specification tree
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	Level - Number - level of the tree
// 	ArrayOfIndexes - Array of Number - indexes on the path to the element
// 	Tree - ValueTree - Tree
Procedure SaveTreeLevelState(Form, Level, ArrayOfIndexes, Tree)
	
	Items = Form.Items;
	ExpandedLevels = Form.ExpandedLevelsOfCacheTree.ExpandedLevels;
	
	TreeRows = Tree.GetItems();
	For IndexOf = 0 To TreeRows.Count() - 1 Do
		
		ArrayOfIndexes.Insert(0,IndexOf);
		String = TreeRows[IndexOf];
		Id = String.GetID();
		
		Expanded = Items.BOMsTree.Expanded(Id);
		Current_   = Items.BOMsTree.CurrentRow = Id;
		If Expanded Or Current_ Then
			RowData = DescriptionOfTreeLevelStateElement();
			RowData.Level         = Level;
			RowData.PathToItem   = StrConcat(ArrayOfIndexes,"-");
			RowData.LineKind       = String.LineKind;
			RowData.Products    = String.Products;
			RowData.Characteristic  = String.Characteristic;
			RowData.Expanded       = Expanded;
			RowData.Current_         = Current_;
			ExpandedLevels.Insert("_"+Format(ExpandedLevels.Count(),"NZ=0; NG="), RowData);
			SaveTreeLevelState(Form, Level+1, ArrayOfIndexes, String);
		EndIf;
		ArrayOfIndexes.Delete(0);
	EndDo;
	
EndProcedure

// Restores the state of the tree level
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	Level - Number - level of the tree
// 	ArrayOfIndexes - Array of Number - indexes on the path to the element
// 	Tree - ValueTree - Tree
Procedure RestoreTreeLevelState(Form, Level, ArrayOfIndexes, Tree)
	
	Items = Form.Items;
	ExpandedLevels = Form.ExpandedLevelsOfCacheTree.ExpandedLevels;
	
	TreeRows = Tree.GetItems();
	For IndexOf = 0 To TreeRows.Count() - 1 Do
		
		ArrayOfIndexes.Insert(0,IndexOf);
		String = TreeRows[IndexOf];
		
		PathToItem = StrConcat(ArrayOfIndexes,"-");
		For Each KeyAndValue In ExpandedLevels Do
			RowData = KeyAndValue.Value; // See DescriptionOfTreeLevelStateElement
			If Level = RowData.Level
				And PathToItem = RowData.PathToItem
				And String.LineKind = RowData.LineKind
				And String.Products = RowData.Products
				And String.Characteristic = RowData.Characteristic
			Then
				Id = String.GetID();
				If RowData.Expanded Then
					Items.BOMsTree.Expand(Id, False);
				EndIf;
				If RowData.Current_ Then
					Items.BOMsTree.CurrentRow = Id;
				EndIf;
			EndIf;
		EndDo;
		RestoreTreeLevelState(Form, Level+1, ArrayOfIndexes, String);
		ArrayOfIndexes.Delete(0);
	EndDo;
	
EndProcedure

// Constructor for the tree-level state element
// 
// Returns:
// 	Structure - From:
// * Level - Number - level of the tree
// * PathToItem - String - The Path To The Element
// * LineKind - EnumRef.TypesOfSpecificationLines - tree row view
// * Products - CatalogRef.Products - Products
// * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
// * Expanded - Boolean - indicates that the line has been expanded
// * Current_ - Boolean - indicates that the line is the Cur
Function DescriptionOfTreeLevelStateElement()
	
	Result = New Structure;
	
	Result.Insert("Level");
	Result.Insert("PathToItem");
	Result.Insert("LineKind");
	Result.Insert("Products");
	Result.Insert("Characteristic");
	
	Result.Insert("Expanded");
	Result.Insert("Current_");
	
	Return Result;
	
EndFunction

// Expand all levels of the tree.
// 
// Parameters:
//  Form - ClientApplicationForm
//  WithSubordinates - Boolean - With subordinates
Procedure ExpandAllLevelsOfTree(Form, WithSubordinates = True) Export
	
	Form.ExpandedLevelsOfCacheTree.ExpandAllMode = 1;
	
	TreeRows = Form.BOMsTree.GetItems();
	For Each TreeRow In TreeRows Do
		Form.Items.BOMsTree.Expand(TreeRow.GetID(), WithSubordinates);
	EndDo;
	
	If Form.ExpandedLevelsOfCacheTree.ExpandAllMode > 1 Then
		Control_Level = Form.ExpandedLevelsOfCacheTree.Control_Level;
		Notification = New CallbackDescription("ExpandAllLevelsOfTreeCompletion", ThisObject, New Structure("Form", Form));
		ShowQueryBox(Notification,
			StrTemplate(NStr("vi = 'Đã đặt trạng thái cây ở mức chi tiết %1. Tiếp tục?';
							|ru = 'Достигнуто состояние дерева в %1 развернутых уровней. Продолжить?';
							|en = 'A tree state of %1 expanded levels is reached. Continue?'; fa = 'A tree state of %1 expanded levels is reached. Continue?';
							|it = 'Достигнуто состояние дерева в %1 развернутых уровней. Продолжить?';
							|pl = 'A tree state of %1 expanded levels is reached. Continue?';
							|tr = 'Достигнуто состояние дерева в %1 развернутых уровней. Продолжить?'"), Format(Control_Level,"NG=;")),
			QuestionDialogMode.YesNo);
	EndIf;
	
	Form.ExpandedLevelsOfCacheTree.ExpandAllMode = 0;
	
EndProcedure

Procedure ExpandAllLevelsOfTreeCompletion(QuestionResult, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ProductDataManagementClientServer.RecalculateReferenceLevelOfTree(Form);
		
		ExpandAllLevelsOfTree(Form);
		
	EndIf;
	
EndProcedure

// Collapse all levels of the tree.
// 
// Parameters:
//  Form - ClientApplicationForm
Procedure CollapseAllLevelsOfTree(Form) Export
	
	TreeRows = Form.BOMsTree.GetItems();
	For Each TreeRow In TreeRows Do
		Form.Items.BOMsTree.Collapse(TreeRow.GetID());
	EndDo; 
	
EndProcedure

// Called before the specification tree node is expanded.
//
// Parameters:
//  Form			 - ClientApplicationForm	 - managed form where the specification tree is located
//  Id	 - Number			 - line to be expanded
//  Cancel			 - Boolean			 - indicates that the node is not being expanded.
//
Procedure BOMsTreeBeforeExpand(Form, Id, Cancel) Export
	
	If Not Form.DynamicReading Then
		Return;
	EndIf;
	
	CurrentData = Form.BOMsTree.FindByID(Id);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentData.ThereIsBOM Then
		Return;
	EndIf;
	
	ExpandedLevelsOfCacheTree = Form.ExpandedLevelsOfCacheTree;
	If ExpandedLevelsOfCacheTree.ExpandAllMode > 0 Then
		Control_Level = ExpandedLevelsOfCacheTree.Control_Level;
		If CurrentData.Level >= Control_Level Then
			ExpandedLevelsOfCacheTree.ExpandAllMode = 2;
			Cancel = True;
			Return;
		EndIf;
	Else
		ProductDataManagementClientServer.RecalculateReferenceLevelOfTree(Form, CurrentData);
	EndIf;
	
	CurrentDataStructure = ProductDataManagementClientServer.TreeStringWithStructure(CurrentData);
	
	ItemsCollection = ProductDataManagementServerCall.TreeSpecificationsReadElements(
		CurrentDataStructure, Form.BORTreeAddressInTheStorage);
	
	ProductDataManagementClientServer.TreeSpecificationsOutputElements(CurrentData, ItemsCollection);
	
EndProcedure

// Called before collapsing a node in the specification tree.
//
// Parameters:
//  Form			 - ClientApplicationForm	 - managed form where the specification tree is located
//  Id	 - Number			 - line to be collapsed
//  Cancel			 - Boolean			 - indicates that the node is not being collapsed.
//
Procedure BOMsTreeBeforeCollapse(Form, Id, Cancel) Export
	
	If Not Form.DynamicReading Then
		Return;
	EndIf;
	
	CurrentData = Form.BOMsTree.FindByID(Id);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentData.ThereIsBOM Then
		Return;
	EndIf;
	
	SubordinateItems = CurrentData.GetItems();
	SubordinateItems.Clear();
	SubordinateItems.Add();
	
EndProcedure

// The Bill of Materials tree before the start of the change.
// 
// Parameters:
//  Item - FormTable
//  Cancel - Boolean
Procedure BOMsTreeBeforeRowChange(Item, Cancel) Export
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "BOMsTreeBillOfMaterials"
		And ProductDataManagementClientServer.TypeOfProductionProcessOfStringTree(CurrentData)
					= PredefinedValue("Enum.ProductionProcessTypes.PerformRM")
		And Not CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		Cancel = True;
	EndIf;
	
EndProcedure

// The beginning of the selection of the bill of materials in the tree.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Item - FormTable
//  ChoiceData - Array of  String
//  StandardProcessing - Boolean
Procedure BOMsTreeBillOfMaterialsStartChoice(Form, Item, ChoiceData, StandardProcessing) Export
	
	StandardProcessing = False;
	
	CurrentData = Form.Items.BOMsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Var_Key = ProductDataManagementClientServer.KeyParametersForSelectingTreeSpecifications(CurrentData);
	
	ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
	FillPropertyValues(ProductData, CurrentData);
	ProductData.ProductionStart      = Form.TreeDate;
	ProductData.ProductionDispatcherBusinessUnit  = Form.AssignmentParameterDivisionManager;
	ProductData.LineOfBusiness = Form.DestinationParameterActivityDirection;
	
	ProductDataManagementClient.OpenFormForSelectingSpecificationsByProductType(
		ProductData,
		Form.BOMSelectionParameters[Var_Key],
		Form);
	
EndProcedure

#EndRegion

#Region MaterialsAndWorksSets

// Clears the service Attributes in the row of the table part
// 
// Parameters:
//  RowData - FormDataCollectionItem - this line
Procedure ClearSetDetailsInLine(RowData) Export
	
	RowData.CommunicationKeySet = Undefined;
	RowData.IncludedInSet    = False;
	
EndProcedure

// Determines whether there are rows in the specified table part that are part of the set
// 
// Parameters:
//  Object - DocumentObject.ProductionStage2_2
//  RowsIDs - Array of Number - lines to check
//  SourceOfMaterials - String - name of the table part
// 
// Returns:
//  Boolean
Function ThereAreLinesIncludedInSet(Object, RowsIDs, SourceOfMaterials = "SupplyWithMaterialsAndWorks") Export
	
	ThereAreLinesIncludedInSet = False;
	
	For Each Id In RowsIDs Do
		RowData = Object[SourceOfMaterials].FindByID(Id);
		If ValueIsFilled(RowData.CommunicationKeySet) Then
			ThereAreLinesIncludedInSet = True;
			Break;
		EndIf;
	EndDo;
	
	Return ThereAreLinesIncludedInSet;
	
EndFunction

#EndRegion

#EndRegion