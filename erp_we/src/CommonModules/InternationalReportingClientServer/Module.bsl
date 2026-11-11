
#Region Public

// Hides the visibility of form elements associated with report settings.
//
// Parameters: 
//	Form - ClientApplicationForm - 
//	AdditionalParameters - Structure, Undefined - Structure containing keys:
//		* HideSettingsWhenGeneratingReport - Boolean - Indicates whether the settings should be hidden.
//		* NameGroupSettingsPanel - String - Name of the panel with settings on the form.
//		* NameButtonSettingsPanel - String - Name of the button to open the settings panel (optional).
//
Procedure HideSettingsWhenGeneratingReport(Form, AdditionalParameters = Undefined) Export
	
	SettingsPanelButton = Undefined; // CommandBarButton - 
	If AdditionalParameters = Undefined Then
		HideSettingsWhenGeneratingReport = Form.HideSettingsWhenGeneratingReport;
		SettingsPanel       = Form.Items.TheGroupSettingsPanel;
		SettingsPanelButton = Form.Items.SettingsPanel; // CommandBarButton -
	Else
		HideSettingsWhenGeneratingReport = AdditionalParameters.HideSettingsWhenGeneratingReport;
		SettingsPanel       = Form.Items[AdditionalParameters.NameGroupSettingsPanel];
		If AdditionalParameters.Property("NameButtonSettingsPanel") Then
			SettingsPanelButton = Form.Items[AdditionalParameters.NameButtonSettingsPanel];
		Else
			SettingsPanelButton = Undefined;
		EndIf;
	EndIf;
	
	If HideSettingsWhenGeneratingReport Then
		If SettingsPanel.Visible Then
			Form.Report.SettingsComposer.UserSettings.AdditionalProperties.Insert("SettingsPanelIsHiddenAutomatically", True);
		EndIf;
		SettingsPanel.Visible = False;
		If SettingsPanelButton <> Undefined Then
			SettingsPanelButton.Title = NStr("vi = 'Hiển thị tùy chỉnh';
											|ru = 'Показать настройки';
											|en = 'Show settings'; fa = 'نمایش تنظیمات';
											|it = 'Mostrare le impostazioni';
											|pl = 'Pokaż ustawienia';
											|tr = 'Ayarları göster'");
		EndIf;
	EndIf;
	
EndProcedure

// Puts the data of the passed report view element in the temporary storage of the form.
//
// Parameters:
//  Item - See FinancialReportingClientServer.ReportElementStructure
//  StorageAddress - UUID - UID of the report type form
//  ClearRefs - Boolean - If true, the reference of the reference list item and the reference of the report owner will be cleared.
//                            When writing such a report element, a new link will be generated, so the placed element
//                            will be copied.
//
// Returns:
//   String - Address in the store
//
Function PlaceItemInStorage(Item, StorageAddress = Undefined, ClearRefs = False) Export
	
	// If we form a repository based on a string 
	// , then we form it by element, if there is, otherwise by the string itself.
	If TypeOf(Item) = Type("FormDataTreeItem")
		Or TypeOf(Item) = Type("FormDataCollectionItem")
		Or TypeOf(Item) = Type("ValueTreeRow") Then
		
		If ValueIsFilled(Item.ReportItem) Then
			Return FinancialReportingServerCall.PlaceItemInStorage(Item.ReportItem, StorageAddress, ClearRefs);
		Else
			
			ElementStructure = FinancialReportingClientServer.ReportElementStructure();
			TotalType = PredefinedValue("Enum.TypesOfTotals.Balance_Dr");
			FillPropertyValues(ElementStructure, Item);
			ElementStructure.Insert("ThisIsReference", False);
			Accuracy = Item.Accuracy;
			If Item.ThisIsReference Then
				ElementStructure.Insert("ThisIsReference", True);
				ElementStructure.Insert("AdditionalAttribute_" + "DisplayItemTitle", True);
				ElementStructure.Insert("AdditionalAttribute_" + "ReportRowCode", "");
				ElementStructure.Insert("AdditionalAttribute_" + "Note", "");
				ElementStructure.Insert("AdditionalAttribute_" + "SelectItem", False);
				
			ElsIf ElementStructure.ItemKind = ItemKind("ReportHeader")
				Or ElementStructure.ItemKind = ItemKind("UneditedText")
				Or ElementStructure.ItemKind = ItemKind("EditedText")Then
				ElementStructure.Insert("AdditionalAttribute_" + "Text", Item.AccountIndicatorDimension);
				
			ElsIf ElementStructure.ItemKind = ItemKind("TableIndicatorsInRows")
				Or ElementStructure.ItemKind = ItemKind("TableIndicatorsInColumns")
				Or ElementStructure.ItemKind = ItemKind("ComplexTable")Then
				ElementStructure.Insert("AdditionalAttribute_" + "DisplayItemTitle", False);
				
			ElsIf ElementStructure.ItemKind = ItemKind("MonetaryIndicator") Then
				ElementStructure.Insert("AdditionalAttribute_" + "GLAccount_", Item.AccountIndicatorDimension);
				ElementStructure.Insert("AdditionalAttribute_" + "TotalType", TotalType);
				ElementStructure.Insert("AdditionalAttribute_" + "OpeningBalance", False);
				ElementStructure.Insert("AdditionalAttribute_" + "ReportRowCode", "");
				ElementStructure.Insert("AdditionalAttribute_" + "Note", "");
				ElementStructure.Insert("AdditionalAttribute_" + "SelectItem", False);
				ElementStructure.Insert("AdditionalAttribute_" + "Accuracy", Accuracy);
				
			ElsIf ElementStructure.ItemKind = ItemKind("NonMonetaryItem") Then
				ElementStructure.Insert("AdditionalAttribute_" + "NonMonetaryItem", Item.AccountIndicatorDimension);
				ElementStructure.Insert("AdditionalAttribute_" + "ReportRowCode", "");
				ElementStructure.Insert("AdditionalAttribute_" + "Note", "");
				ElementStructure.Insert("AdditionalAttribute_" + "SelectItem", False);
				ElementStructure.Insert("AdditionalAttribute_" + "Accuracy", Accuracy);
				
			ElsIf ElementStructure.ItemKind = ItemKind("DerivedItem") Then
				ElementStructure.Insert("AdditionalAttribute_" + "Formula", "");
				ElementStructure.Insert("AdditionalAttribute_" + "ReportRowCode", "");
				ElementStructure.Insert("AdditionalAttribute_" + "Note", "");
				ElementStructure.Insert("AdditionalAttribute_" + "SelectItem", False);
				ElementStructure.Insert("AdditionalAttribute_" + "Accuracy", Accuracy);
				
			ElsIf ElementStructure.ItemKind = ItemKind("Group")
				Or ElementStructure.ItemKind = ItemKind("TotalByGroup") Then
				ElementStructure.Insert("AdditionalAttribute_" + "DisplayItemTitle", True);
				ElementStructure.Insert("AdditionalAttribute_" + "ReportRowCode", "");
				ElementStructure.Insert("AdditionalAttribute_" + "Note", "");
				
			ElsIf ElementStructure.ItemKind = ItemKind("RowColumn") Then
				ElementStructure.Insert("AdditionalAttribute_" + "ReportRowCode", "");
				ElementStructure.Insert("AdditionalAttribute_" + "Note", "");
			
			ElsIf ElementStructure.ItemKind = ItemKind("Dimension") Then
				DimensionType = DetermineMeasurementTypeByValueType(Item.AccountIndicatorDimension, Item);
				ElementStructure.Insert("AdditionalAttribute_" + "DimensionType", DimensionType);
				
				If DimensionType = DimensionType("AccountingRegisterDimension") Then
					ElementStructure.Insert("AdditionalProps__", Accuracy);
					NameOfAdditionalProps = "AdditionalAttribute_" + "DimensionName";
				ElsIf DimensionType = DimensionType("Period") Then
					NameOfAdditionalProps = "AdditionalAttribute_" + "Periodicity";
					ElementStructure.Insert("AdditionalAttribute_" + "Sort", "ASC");
					ElementStructure.Insert("AdditionalAttribute_" + "PeriodPresentation", PredefinedValue("Enum.PeriodPresentation.EndingDate"));
				ElsIf DimensionType = DimensionType("ExtDimension") Then
					NameOfAdditionalProps = "AdditionalAttribute_" + "ExtDimensionType";
					ElementStructure.Insert("AdditionalAttribute_" + "Accuracy", Accuracy);
				EndIf;
				
				ElementStructure.Insert(NameOfAdditionalProps, Item.AccountIndicatorDimension);
				
			EndIf;
			
			Return FinancialReportingServerCall.PlaceItemInStorage(ElementStructure, StorageAddress, ClearRefs);
			
		EndIf;
	Else
		Return FinancialReportingServerCall.PlaceItemInStorage(Item, StorageAddress, ClearRefs);
	EndIf;
	
EndFunction

// Puts the data of the passed report type element in the temporary storage of the form without reference to the reference list element.
// When writing such a report element, a new link will be generated, so the placed element will be copied.
//
// Parameters:
//  Item - See FinancialReportingClientServer.ReportElementStructure
//  StorageAddress - UUID - UID of the report type form.
//
// Returns:
//   String - Address in the store
//
Function PlaceCopyOfItemInRepository(Item, StorageAddress = Undefined) Export
	
	Return PlaceItemInStorage(Item, StorageAddress, True);
	
EndFunction

// The function returns the parameter structure for the procedure populate tree Line
//
// Parameters:
//  AdditionalLineDetails_ - String - additional details of the tree line can be passed.
//
// Returns:
//  Structure - parameters for filling in a new row of the tree of values of report elements:
//   *Source - Structure -
//   *DestinationRow - FormDataTreeItem, FormDataCollectionItem -
//   *ItemAddressInStorage - String - 
//   *Field - FormDataCollection -
//
Function NewRowFillingData(AdditionalLineDetails_ = "") Export

	If IsBlankString(AdditionalLineDetails_) Then
		AdditionalLineDetails_ = "GLAccount_,TotalType,OpeningBalance,NonMonetaryItem,Text,ReportRowCode,Note,DisplayItemTitle,Accuracy";
	EndIf;

	Parameters = New Structure;
	Parameters.Insert("Source");
	Parameters.Insert("DestinationRow");
	Parameters.Insert("ItemAddressInStorage");
	Parameters.Insert("Field");
	Parameters.Insert("AdditionalLineDetails_", AdditionalLineDetails_);
	Return Parameters;

EndFunction

// Creates a standard parameter structure for getting a tree of report elements
//
// Returns:
//  Structure - Parameters:
//  	* NameOfTreeElement - String - Name of the element in the element tree
//  	* WorkMode - EnumRef.ModesOfNewItemTreeDisplay -
//  	* QuickSearch - String -
//  	* FilterByReportKind - CatalogRef.FinancialReportTypes - 
//  	* CurReportView - CatalogRef.FinancialReportTypes - 
//  	* ChartsOfAccounts - Array of CatalogRef.FinancialAccountingChartsOfAccounts - 
//  	              - Array of CatalogRef.MetadataObjectIDs -
//
Function NewElementTreeParameters() Export

	WorkMode = PredefinedValue("Enum.ModesOfNewItemTreeDisplay.ConfigureReportKind");
	TreeParameters = New Structure;
	TreeParameters.Insert("NameOfTreeElement", "NewItemTree");
	TreeParameters.Insert("WorkMode", WorkMode);
	TreeParameters.Insert("QuickSearch", "");
	TreeParameters.Insert("FilterByReportKind");
	TreeParameters.Insert("CurReportView");
	TreeParameters.Insert("ChartsOfAccounts", New Array);
	
	Return TreeParameters;

EndFunction

// Forms a standard structure of parameters for generating financial statements
//
// Returns:
//  Structure - fields of parameters for the formation of financial statements.
//
Function NewReportGenerationParameters() Export

	ReportParameters = New Structure;
	ReportParameters.Insert("PeriodType");
	ReportParameters.Insert("BeginOfPeriod");
	ReportParameters.Insert("EndOfPeriod");
	ReportParameters.Insert("Organization");
	ReportParameters.Insert("Department");
	ReportParameters.Insert("LineOfBusiness");
	ReportParameters.Insert("OpenForms", False);
	ReportParameters.Insert("FlagOpenForms", False);
	ReportParameters.Insert("MultiplierOfAmounts");
	ReportParameters.Insert("ChartsOfAccounts", New Array);
	ReportParameters.Insert("Resource");
	ReportParameters.Insert("Currency");
	
	Return ReportParameters;

EndFunction

// Creates a standard structure for a single element of a financial report
//
// Returns:
//  Structure - fields of a single element of the financial report.
//
Function NewOperandData() Export

	ReportParameters = New Structure;
	ReportParameters.Insert("AddressOfItemStructure","");
	ReportParameters.Insert("Id","");
	ReportParameters.Insert("CustomPicture");
	ReportParameters.Insert("ItemKind");
	ReportParameters.Insert("ReportItem");
	ReportParameters.Insert("NameForPrinting", "");
	ReportParameters.Insert("AccountIndicatorDimension");
	ReportParameters.Insert("GLAccount_");
	ReportParameters.Insert("TotalType");
	ReportParameters.Insert("OpeningBalance", False);
	ReportParameters.Insert("NonMonetaryItem");
	ReportParameters.Insert("HasSettings", False);
	ReportParameters.Insert("ThisIsReference", False);
	ReportParameters.Insert("HasSettings", False);
	ReportParameters.Insert("LinkedItem1");
	ReportParameters.Insert("Code","");
	Return ReportParameters;

EndFunction

#EndRegion

#Region Private

// This function defines the type of dimension of the financial report
//
// Parameters:
//  Value  - Arbitrary - the value of the financial report dimension that is used to determine the type of dimension.
//  AdditionalParameters  - Structure - more information.
//
// Returns:
//   EnumRef.TypesOfBudgetReportDimensions - type of measurement.
//
Function DetermineMeasurementTypeByValueType(Value, AdditionalParameters = Undefined)
	
	If TypeOf(Value) = Type("EnumRef.Periodicity") Then
		
		Return DimensionType("Period");
		
	ElsIf TypeOf(Value) = Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes")
		Or TypeOf(Value) = LocalAccntingClientServer.TypeSpeciesExtdimension() Then
		
		Return DimensionType("ExtDimension");
		
	ElsIf TypeOf(Value) = Type("String") Then
		
		Return DimensionType("AccountingRegisterDimension");
		
	Else
		
		Raise NStr("vi = 'Loại đơn vị tính cho báo cáo tài chính không xác định';
					|ru = 'Неизвестный тип измерения финансового отчета';
					|en = 'Unknown dimension type of financial report'; fa = 'Unknown dimension type of financial report';
					|it = 'Tipo sconosciuto della misura del rapporto finanziario';
					|pl = 'Nieznany typ pomiaru raportu finansowego';
					|tr = 'Bilinmeyen mali rapor boyut türü'");
		
	EndIf;
	
EndFunction

Function ItemKind(ElementTypeName)
	
	Return PredefinedValue("Enum.FinancialReportItemKinds."+ElementTypeName);
	
EndFunction

Function DimensionType(ElementTypeName)
	
	Return PredefinedValue("Enum.TypesOfBudgetReportDimensions."+ElementTypeName);
	
EndFunction

#EndRegion
