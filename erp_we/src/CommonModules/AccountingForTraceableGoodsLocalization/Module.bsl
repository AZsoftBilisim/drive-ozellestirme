#Region Public

#Region SettingUpSystem

// Returns whether tracking of tracked, imported goods was used on the specified date.
//
// Parameters:
//	Date - Date - the date on which you want to get the value for whether tracking of tracked, imported
//					goods can be used.
//
// Returns:
//	Boolean - The truth means that the possibility of accounting for traceable, imported goods is available.
//
Function UseTraceableImportedGoodsAccounting(Date) Export
	
	UseTraceableImportedGoodsAccounting = False;
	
	Return UseTraceableImportedGoodsAccounting;
	
EndFunction

// Returns the value of the start date when tracking of tracked, imported goods is used.
//
// Returns:
//	Date - the date when tracking of traceable, imported goods began to be used.
//
Function DateOfTraceableImportedGoodsAccountingStart() Export
	
	AccountingStartDate = Date(2399, 1, 1);
	
	Return AccountingStartDate;
	
EndFunction

// Calculates the value of the constant used in accounting for the unit of measurement of foreign economic activity.
// The True value will be set if there is a nomenclature item in which
// the unit of measurement and the unit Of the fea are filled in and are not equal to each other.
//
Procedure SetFOAccountingIsUsedInUnitOfMeasurementOfFEA() Export
	
	
EndProcedure

// Procedure - To establish the use of accounting in the Unit of the fea in the nomenclature
//  Sets the value of the constant used in the accounting unit of measurement of the foreign economic activity by the Attributes Of the item item.
//  The True value will be set if the unit Of the item
//  and the unit Of the fea are filled in and are not equal to each other.
//  Only the need to set a constant is analyzed. There is no need to turn off the constant, because the
//  nomenclature with the FEA can be used in documents and the functionality should be used.
// Parameters:
//  Products - CatalogObject.Products - the element that triggered the event. 
//
Procedure EstablishUseOfAccountingInUnitOfMeasurementOfFEAByNomenclature(Products) Export

	
EndProcedure

// Returns an indication of the use of accounting of goods in the unit of measurement of the HS.
//
// Returns:
//	Boolean - True means that the accounting of goods is used in the unit of measurement of the HS.
//
Function AccountingInFEACNUnitOfMeasurementIsUsed() Export
	
	AccountingInFEACNUnitOfMeasurementIsUsed = False;
	
	Return AccountingInFEACNUnitOfMeasurementIsUsed;
	
EndFunction

#EndRegion

#Region KBSPConnection

// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands
//
// Parameters:
//	Objects - Array of MetadataObject - a collection of metadata objects with creation commands based on.
//
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	
EndProcedure

// See ReportsOptionsOverridable.DefineObjectsWithReportCommands
//
// Parameters:
//	Objects - Array of MetadataObject - a collection of metadata objects with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	
EndProcedure

#EndRegion

#Region KitConfigurations

// Returns parameters for checking a set of products.
//
// Returns:
//	Structure - kit verification parameters containing the following properties:
//		* Date - Date - the date of the object on which the work with the kit is carried out.
//		* KitAssembly - Boolean - indicates that the kit is being assembled. The default value is True.
//		* ThisIsConfigurationOrder - Boolean - indicates that a order is being placed for the complete set. The default value is False.
//		* Products - CatalogRef.Products, Undefined - The item of the kit. The default value is Undefined.
//		* Characteristic - CatalogRef.ItemsCharacteristics, Undefined - characteristics of the kit.
//																						The default value is Undefined.
//		* ProductsOfMainComponent -CatalogRef.Products, Undefined - The item of the main component.
//																							The default value is Undefined.
//		* MainComponentCharacteristic - CatalogRef.ItemsCharacteristics, Undefined - characteristics of the main component.
//																											The default value is Undefined.
//		* TSName - String - the name of the tabular part of the object.
//		* ToControl - Boolean - indicates that the kit needs to be checked.
//		* OptionForPresentationOfSetInPrintedFormsInHeader - Boolean - indicates that the field is present in the object.
//																	Otherwise, you need to extract the configuration options from the field.
//
Function SetValidationParameters() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("Date",					Date(1, 1, 1));
	CheckParameters.Insert("KitAssembly",		True);
	CheckParameters.Insert("ThisIsConfigurationOrder",	False);
	
	CheckParameters.Insert("Products", Undefined);
	CheckParameters.Insert("Characteristic", Undefined);
	
	CheckParameters.Insert("ProductsOfMainComponent", Undefined);
	CheckParameters.Insert("MainComponentCharacteristic", Undefined);
	
	CheckParameters.Insert("TSName", "Goods");
	
	CheckParameters.Insert("ToControl", True);
	
	CheckParameters.Insert("OptionForPresentationOfSetInPrintedFormsInHeader", True);
	
	Return CheckParameters;
	
EndFunction

// Returns parameters for checking CCD numbers.
//
// Returns:
//	Structure - kit verification parameters containing the following properties:
//		* TSName - String - The name of the TS of the document, which contained the columns analyticaccountcounts and numbers of the TDC.
Function ParametersForCheckingTraceableCCDNumbers() Export
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName", "InventoryKinds");
	Return CheckParameters;
EndFunction

// Performs verification of the correctness of the contents of the kit in terms of accounting for traceable goods according to the RNPT.
//
// Parameters:
//	Object - CatalogObject, DocumentObject - the object for which the check is being performed.
//	Cancel - Boolean - a sign of continuation of further processing of the checked object in the information database.
//	CheckParameters - See SetValidationParameters.
//
Procedure CheckIfKitIsCorrect(Object, Cancel, CheckParameters) Export
	
	
EndProcedure

// Performs verification of the correctness of the CCD number type and the presence of the Traceable Goods flag at the nomenclature item.
//
// Parameters:
//	Object - DocumentObject - the object for which the check is being performed.
//	Cancel - Boolean - a sign of continuation of further processing of the checked object in the information database.
//	CheckParameters - See ParametersForCheckingTraceableCCDNumbers.
Procedure CheckCorrectnessOfTraceableCCDNumbers(Object, Cancel, CheckParameters) Export
EndProcedure

#EndRegion

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - FixedStructure - document properties (See DocumentsPosting.DocumentProperties)
//                                      .
//
// Returns:
//  Structure - parameters of the accounting mechanism (See DocumentsPosting.ParametersOfAccountingMechanism)
//              .
//
Function ParametersForHoldingDocument(Document, Properties) Export
 
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure for the formation of movements on subordinate registers of traceable goods.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
		
	
	
EndProcedure

// The function returns the text of a temporary table to determine the presence of Recorders in the extended 
// traceability register.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//
// Returns:
//	String - query text.
//
Function QueryTextTTThereIsRegisteredRecordOfExtendedTraceabilityRegister(Query, QueryTexts) Export
	
	QueryText = "";
	
			
	Return QueryText;
	
EndFunction

// The function checks the need to update the Registered Records of the extended traceability register
//
// Parameters:
//  Tables - See DocumentsPosting.DocumentDataForPosting
//
// Returns:
//	Boolean
//
Function DoNotUpdateRegisterRecordsOfExtendedRegister(Tables) Export
	
	DoNotUpdateRegisterRecordsOfExtendedRegister = True;
	
		
	Return DoNotUpdateRegisterRecordsOfExtendedRegister;
			
EndFunction

#EndRegion

// Complements the parameters for checking the filling in the table of the 'Qty'field.
//
// Parameters:
//	CheckParameters - Structure - collection of validation parameters.
//
Procedure SupplementParametersForCheckingFillingOfQuantitiesByRNPT(CheckParameters) Export
	
	
EndProcedure

// Checks whether the 'Qty'field is filled in in the table.
//
// Parameters:
//	Object - DocumentObject, Structure, ClientApplicationForm - the object in the tabular part of which the check is performed and which contains:
//		* Ref - DocumentRef - link to the information database document.
//	Cancel - Boolean - True, indicates that the field to be checked is not filled in in the table part of the object.
//	CheckParameters - Structure, Undefined - the test parameters.
//
Procedure CheckFillingOfQuantityAccordingToRNPT(Object, Cancel, CheckParameters) Export
	
	
EndProcedure

// Returns the parameters used when setting the conditional design of the quantity field by RPT.
//
// Returns:
//	Structure - parameters used when setting the Conditional appearance of the quantity field according to ProductBatchID, with the following properties:
//		* NameOfInputFieldQuantityByRNPT - String - the name of the quantity field according to RNPT.
//		* FieldNameUnitOfMeasurementFEA - String - the name of the field is the unit of measurement of the FEA.
//		* PathToFieldIsRecordedAccordingToRNPT - String - the path to the value of the field that stores information about accounting for the RPT.
//		* PathToCCDNumberTypeField - String - the path to the value of the field that stores information about the CCD number type.
//		* PathToItemTypeField - String - path to the field value that stores information about the item type.
//		* PathToDocumentDateField - String - the path to the field value that stores information about the date of the object.
//		* PathToFieldOfCorrectionAttributePUPA - String - the path to the field value that stores information about the use of the document for adjusting the purchase of services and other assets.
//
Function ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT() Export
	
	ConditionalDesignParameters = New Structure;
	ConditionalDesignParameters.Insert("NameOfInputFieldQuantityByRNPT",	"GoodsQuantityByGBRN");
	ConditionalDesignParameters.Insert("FieldNameUnitOfMeasurementFEA",	"GoodsProductsFEACNUnitOfMeasure");
	ConditionalDesignParameters.Insert("PathToFieldIsRecordedAccordingToRNPT",		"Object.Goods.AccountingForTheRNPTIsMaintained");
	ConditionalDesignParameters.Insert("PathToCCDNumberTypeField",			"Object.Goods.CCDNumberType");
	ConditionalDesignParameters.Insert("PathToItemTypeField",		"Object.Goods.ItemsType");
	ConditionalDesignParameters.Insert("PathToDocumentDateField",			"Object.Date");
	ConditionalDesignParameters.Insert("PathToFieldOfCorrectionAttributePUPA","");
	
	Return ConditionalDesignParameters;
	
EndFunction

// We set the conditional registration of the amount for the RNPT
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//		* ConditionalAppearance - DataCompositionConditionalAppearance - conditional design of the line-up of these form elements.
//	ConditionalDesignParameters - See ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT
//
Procedure SetConditionalAppearanceOfQuantityAccordingToRNPT(Form, ConditionalDesignParameters = Undefined) Export
	
	If ConditionalDesignParameters = Undefined Then
		ConditionalDesignParameters = ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	EndIf;
	
	NameOfInputFieldQuantityByRNPT	= ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT;
	PathToItemTypeField		= ConditionalDesignParameters.PathToItemTypeField;
	StartDateOfTraceability		= DateOfTraceableImportedGoodsAccountingStart();
	
	FormItems		= Form.Items;
	ConditionalAppearance	= Form.ConditionalAppearance;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfInputFieldQuantityByRNPT].Name);
	
	FilterGroup1 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToDocumentDateField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<hàng hóa không theo dõi nguồn gốc xuất xứ>';
																		|ru = '<товар не прослеживается>';
																		|en = '<goods item is not traced>'; fa = '<goods item is not traced>';
																		|it = '<prodotto non tracciabile>';
																		|pl = '<towar nie jest śledzony>';
																		|tr = '<ürün izlenmiyor>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfInputFieldQuantityByRNPT].Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToCCDNumberTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CCDNumberTypes.KitRNPT;
	
	If ValueIsFilled(ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA) Then
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
	EndIf;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<bộ đóng gói có nguồn gốc xuất xứ>';
																		|ru = '<прослеживаемый комплект>';
																		|en = '<traceable kit>'; fa = '<traceable kit>';
																		|it = '<kit tracciabile>';
																		|pl = '<identyfikowalny zestaw>';
																		|tr = '<izlenebilir set>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False); 
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA].Name);
	
	FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToCCDNumberTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CCDNumberTypes.KitRNPT;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemsTypes = New ValueList;
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToItemTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ItemsTypes;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);
	
EndProcedure

// Returns the parameters used when setting the Conditional appearance of the CCD number field.
//
// Returns:
//	Structure - parameters used when setting the Conditional appearance of the CCD number field, with the following properties:
//		* PathToDocumentDateField - String - the path to the field value that stores information about the document date.
//		* NameOfFieldForEnteringCCDNumber - String - the name of the CCD number field.
//		* NameOfInputFieldCountryOfOrigin - String - the name of the country of origin field.
//		* PathToCCDNumberField - String - the path to the value of the field that stores information about the CCD number.
//		* PathToFieldIsRecordedAccordingToRNPT - String - the path to the value of the field that stores information about accounting for the RPT.
//		* PathToItemTypeField - String - path to the field value that stores information about the item type.
//
Function ParametersForSettingConditionalAppearanceOfCCDNumber() Export
	
	ConditionalDesignParameters = New Structure;
	ConditionalDesignParameters.Insert("PathToDocumentDateField",				"Object.Date");
	ConditionalDesignParameters.Insert("NameOfFieldForEnteringCCDNumber",				"GoodsCCDNumber");
	ConditionalDesignParameters.Insert("NameOfInputFieldCountryOfOrigin",	"");
	ConditionalDesignParameters.Insert("PathToCCDNumberField",					"Object.Goods.CCDNumber");
	ConditionalDesignParameters.Insert("PathToFieldIsRecordedAccordingToRNPT",			"Object.Goods.AccountingForTheRNPTIsMaintained");
	ConditionalDesignParameters.Insert("PathToItemTypeField",			"Object.Goods.ItemsType");
	
	Return ConditionalDesignParameters;
	
EndFunction

// Setting the conditional registration of GTD numbers
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//		* ConditionalAppearance - DataCompositionConditionalAppearance - conditional design of the line-up of these form elements.
//	ConditionalDesignParameters - See ParametersForSettingConditionalAppearanceOfCCDNumber.
//
Procedure SetConditionalAppearanceOfCCDNumber(Form, ConditionalDesignParameters = Undefined) Export
	
	If ConditionalDesignParameters = Undefined Then
		ConditionalDesignParameters = ParametersForSettingConditionalAppearanceOfCCDNumber();
	EndIf;
	
	PathToDocumentDateField			= ConditionalDesignParameters.PathToDocumentDateField;
	NameOfFieldForEnteringCCDNumber			= ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber;
	NameOfInputFieldCountryOfOrigin	= ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin;
	PathToFieldIsRecordedAccordingToRNPT		= ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT;
	PathToCCDNumberField				= ConditionalDesignParameters.PathToCCDNumberField;
	PathToItemTypeField		= ConditionalDesignParameters.PathToItemTypeField;
	
	StartDateOfTraceability = DateOfTraceableImportedGoodsAccountingStart();
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfFieldForEnteringCCDNumber].Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToDocumentDateField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToCCDNumberField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfFieldForEnteringCCDNumber].Name);
	
	If Not IsBlankString(NameOfInputFieldCountryOfOrigin) Then
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormItems[NameOfInputFieldCountryOfOrigin].Name);
	EndIf;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToDocumentDateField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ItemsTypes = New ValueList;
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToItemTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ItemsTypes;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Số đăng ký lô hàng không được sử dụng>';
																		|ru = '<РНПТ не используются>';
																		|en = '<RNPT is not used>'; fa = '<RNPT is not used>';
																		|it = '<РНПТ не используются>';
																		|pl = '<RNPT is not used>';
																		|tr = '<RNPT kullanılmamaktadır>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Sets the visibility of the 'Qty' column'in the corresponding table in the document.
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//	DocumentDate - Date - the document date required to check whether tracking of traceable,
//							imported goods can be used.
//	ElementGroupRNTP - String - name of the corresponding form element.
//
//	UsedForProductsInFA - Boolean - a sign of use in the functionality for Accounting RNPT in the OS.
//
Procedure EstablishVisibilityOfRNPTQuantity(Form,
											DocumentDate,
											ElementGroupRNTP = "ProductsGroupQuantityByRNPT",
											UsedForProductsInFA = False) Export
	
	AccountingInFEACNUnitOfMeasurementIsUsed = False;
	UseTraceableImportedGoodsAccounting = UseTraceableImportedGoodsAccounting(DocumentDate);
	
	Form.Items[ElementGroupRNTP].Visible = (AccountingInFEACNUnitOfMeasurementIsUsed Or UsedForProductsInFA)
													And UseTraceableImportedGoodsAccounting;
	
EndProcedure

// Sets page visibility 'Traceable goods' on the document form.
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//	DocumentDate - Date - the document date required to check whether tracking of traceable,
//							imported goods can be used.
//	TraceableGoodsPageElement - String - name of the corresponding form element.
//
Procedure SetVisibilityOfTraceableGoodsPage(Form,
											DocumentDate,
											TraceableGoodsPageElement = "TraceableProductsPage") Export
	
	Form.Items[TraceableGoodsPageElement].Visible =
		UseTraceableImportedGoodsAccounting(DocumentDate);
	
EndProcedure

// Sets the conditional design for the columns 'NomerGTD', 'Country of origin' in the corresponding table of the document.
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
// 	Adjusting - Boolean - takes the value True when called from the Acquisition adjustment document.
Procedure EstablishConditionalAppearanceInDocumentPurchaseOfGoodsServices(Form, Adjusting = False) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	#Region AvailabilityOfCCD
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	BusinessOperationsProcurementInEAEUCountries = New ValueList;
	BusinessOperationsProcurementInEAEUCountries.LoadValues(PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU));	
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	If Adjusting Then
		ItemFilter.LeftValue = New DataCompositionField("EconomicOperationOfFoundationDocument");
	Else
		ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	EndIf;
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = BusinessOperationsProcurementInEAEUCountries;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
EndProcedure

// Setting the conditional registration of GTD numbers
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//		* ConditionalAppearance - DataCompositionConditionalAppearance - conditional design of the line-up of these form elements.
//	NameOfFieldForEnteringCCDNumber - String - 
//	NameOfInputFieldQuantityByRNPT - String -
//	NameOfInputFieldUnitOfHS - String -  
//
Procedure SetConditionalAppearanceInDocumentEnteringItemBalances(Form,
	NameOfFieldForEnteringCCDNumber,
	NameOfInputFieldQuantityByRNPT,
	NameOfInputFieldUnitOfHS) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[NameOfFieldForEnteringCCDNumber].Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[NameOfInputFieldQuantityByRNPT].Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<не требуется>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[NameOfInputFieldUnitOfHS].Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

// Clear the data on the GTD number for traceable goods.
//
// Parameters:
//	Object - DocumentObject - an object in the tabular part of which data is being cleaned.
//
Procedure ClearGTDUNumberOfTraceableGoodsInDocumentPurchaseOfGoodsServices(Object) Export
	
	
EndProcedure

// Sets the visibility of the 'Qty' column'in the corresponding table in the document.
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - the form of the client application.
//	ThisIsCommissionAgentSReport - Boolean - indicates the document type.
//
Procedure EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(Form, ThisIsCommissionAgentSReport = True) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	CommissionTransactions = New ValueList;
	CommissionTransactions.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	
	#Region GTDiRNPTVisibility
	
	// The settings are derived from the agreement
	Item = ConditionalAppearance.Items.Add();
	
	If Items.Find("GoodsQuantityByGBRN") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsQuantityByGBRN.Name);
	EndIf;
	
	If Items.Find("GoodsProductsFEACNUnitOfMeasure") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsProductsFEACNUnitOfMeasure.Name);
	EndIf;
	
	If Items.Find("GoodsCCDNumber") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	EndIf;
	
	If Items.Find("GoodsCCDNumberOriginCountry") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	EndIf;
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTraceableImportedGoodsAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	If Not ThisIsCommissionAgentSReport Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = CommissionTransactions;
	EndIf;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region AvailabilityOfCCD
	//
	Item = ConditionalAppearance.Items.Add();
	
	If Items.Find("GoodsCCDNumber") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	EndIf;
	
	If Items.Find("GoodsCCDNumberOriginCountry") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	If Not ThisIsCommissionAgentSReport Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = CommissionTransactions;
	EndIf;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	If Items.Find("GoodsCCDNumber") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	EndIf;
	
	If Items.Find("GoodsCCDNumberOriginCountry") <> Undefined Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	If Not ThisIsCommissionAgentSReport Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = CommissionTransactions;
	EndIf;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không tiến hành kế toán theo số đăng ký lô hàng>';
													|ru = '<не ведется учет по РНПТ>';
													|en = '<records by RNPT are not kept>'; fa = '<records by RNPT are not kept>';
													|it = '<не ведется учет по РНПТ>';
													|pl = '<records by RNPT are not kept>';
													|tr = '<RNPT''ye göre kayıt tutulmuyor>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
EndProcedure

// Establishes the Conditional appearance of the accounting data for the CCD in the document.
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//
Procedure ToEstablishConditionalAppearanceOfAccountingForGTDVStockSurplusRecognition(Form) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	StartDateOfTraceability = DateOfTraceableImportedGoodsAccountingStart();
	
	CCDNumberTypes = New ValueList;
	CCDNumberTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
	CCDNumberTypes.Add(Enums.CCDNumberTypes.KitRNPT);
	
	// CCD number 
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["GoodsCCDNumber"].Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Quantity according to ProductBatchID
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["GoodsQuantityByGBRN"].Name);
	
	FilterGroup1 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumberType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = CCDNumberTypes;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có số đăng ký lô hàng>';
																		|ru = '<без РНПТ>';
																		|en = '<without RNPT>'; fa = '<without RNPT>';
																		|it = '<без РНПТ>';
																		|pl = '<without RNPT>';
																		|tr = '<RNPT olmadan>.'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// GoodsProductsFEACNUnitOfMeasure
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["GoodsProductsFEACNUnitOfMeasure"].Name);
	
	FilterGroup1 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumberType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = CCDNumberTypes;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);
	
EndProcedure

// Returns the parameters used when setting the conditional design of the CCD number field and the quantity according to the RPT
// in the document, the goods are re-sorted.
//
// Returns:
//	Structure - parameters used when setting the Conditional appearance of the CCD number field, with the following properties:
//		* PathToDocumentDateField - String - the path to the field value that stores information about the document date.
//		* NameOfFieldForEnteringCCDNumber - String - the name of the CCD number field.
//		* NameOfInputFieldCountryOfOrigin - String - the name of the country of origin field.
//		* NameOfInputFieldQuantityByRNPT - String - the name of the quantity field according to RNPT.
//		* PathToFieldIsRecordedAccordingToCCD - String - the path to the value of the field that stores information about accounting for the CCD nomenclature of registration.
//		* PathToFieldIsRecordedAccordingToRNPT - String - the path to the value of the field that stores information about accounting according to the ProductBatchID of the registration nomenclature.
//		* PathToFieldIsAccountedForByCCDWriteOff - String - the path to the value of the field that stores information about accounting for the CCD inventory item of the write-off.
//		* PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID - String - the path to the value of the field that stores information about accounting according to the ProductBatchID of the write-off item.
//		* PathToFieldUnitOfHS - String - the path to the field value that stores information about the unit of measurement of traceability of the registration number.
//		* PathToFieldUnitOfFuelAndEnergyConsumptionWriteOff - String - the path to the field value that stores information about the unit of measurement for the traceability of the write-off number.
//
Function ParametersOfConditionalAppearanceOfGTDAccountingInReSortingOfGoods() Export
	
	ConditionalDesignParameters = New Structure;
	ConditionalDesignParameters.Insert("PathToDocumentDateField",					"Object.Date");
	ConditionalDesignParameters.Insert("NameOfFieldForEnteringCCDNumber",					"GoodsCCDNumber");
	ConditionalDesignParameters.Insert("NameOfInputFieldCountryOfOrigin",		"GoodsCCDNumberOriginCountry");
	ConditionalDesignParameters.Insert("NameOfInputFieldQuantityByRNPT",			"GoodsQuantityByGBRN");
	ConditionalDesignParameters.Insert("PathToFieldIsRecordedAccordingToCCD",				"Object.Goods.TheRecordsAreKeptByCCD");
	ConditionalDesignParameters.Insert("PathToFieldIsRecordedAccordingToRNPT",				"Object.Goods.AccountingForTheRNPTIsMaintained");
	ConditionalDesignParameters.Insert("PathToFieldIsAccountedForByCCDWriteOff",		"Object.Goods.RecordsAreKeptForCCDWriteOff");
	ConditionalDesignParameters.Insert("PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID",		"Object.Goods.AccountingIsConductedAccordingToTheRNPTSPISITION");
	ConditionalDesignParameters.Insert("PathToFieldUnitOfHS",			"Object.Goods.FEACNUnitOfMeasure");
	ConditionalDesignParameters.Insert("PathToFieldUnitOfFuelAndEnergyConsumptionWriteOff",	"Object.Goods.UnitOfMeasurementOfFuelTaxWriteOff");
	
	Return ConditionalDesignParameters;
	
EndFunction

// We set the Conditional appearance of the CCD number field and the quantity according to the ProductBatchID in the document of the goods re-sorting.
//
// Parameters:
//	Form - FormDataStructure, ClientApplicationForm - contains data from a form that contains:
//		* Items - FormAllItems - elements of the client application form.
//		* ConditionalAppearance - DataCompositionConditionalAppearance - conditional design of the line-up of these form elements.
//	ConditionalDesignParameters - See ParametersOfConditionalAppearanceOfGTDAccountingInReSortingOfGoods.
//
Procedure ToEstablishConditionalAppearanceOfAccountingForCCDAtGoodsMisgrading(Form, ConditionalDesignParameters = Undefined) Export
	
	ConditionalAppearance	= Form.ConditionalAppearance;
	FormItems		= Form.Items;
	
	If ConditionalDesignParameters = Undefined Then
		ConditionalDesignParameters = ParametersOfConditionalAppearanceOfGTDAccountingInReSortingOfGoods();
	EndIf;
	
	NameOfFieldForEnteringCCDNumber				= ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber;
	NameOfInputFieldCountryOfOrigin		= ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin;
	PathToFieldIsRecordedAccordingToRNPT			= ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT;
	PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID	= ConditionalDesignParameters.PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID;
	
	StartDateOfTraceability = DateOfTraceableImportedGoodsAccountingStart();
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfFieldForEnteringCCDNumber].Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfInputFieldCountryOfOrigin].Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldIsAccountedForByCCDWriteOff);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField(PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", ProductsLocalization.TextOfCCDField("NotisSpecified"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfFieldForEnteringCCDNumber].Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfInputFieldCountryOfOrigin].Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField(PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	OrGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldUnitOfHS);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldUnitOfFuelAndEnergyConsumptionWriteOff);
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToDocumentDateField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = StartDateOfTraceability;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text",ProductsLocalization.TextOfCCDField("NotisSpecified"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT].Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField(PathToFieldIsRecordedAccordingToWriteOffOfProductBatchID);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToRNPT);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldUnitOfHS);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField(ConditionalDesignParameters.PathToFieldUnitOfFuelAndEnergyConsumptionWriteOff);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
																		|ru = '<не указывается>';
																		|en = '<not specified>'; fa = '<مشخص نشده>';
																		|it = '<не указывается>';
																		|pl = '<nie jest wskazywane>';
																		|tr = '<belirtilmiyor>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Clear data on the CCD number for traceable works.
//
// Parameters:
//	Object - DocumentObject - an object in the tabular part of which data is being cleaned.
//	TSName - String - the name of the table part where data is being cleaned.
//
Procedure ClearGTDUNumbersOfTraceableWorks(Object, TSName = "Goods") Export
	
	
EndProcedure

// Clear data on imported goods.
//
// Parameters:
//	Object - DocumentObject - an object in the tabular part of which data is being cleaned.
//	CommissionAgentKeepsRecordsOnRNPTWithoutAgreement - Boolean - a sign that the accounting of the commission of traceable goods
//														is carried out without the use of an agreement.
//														The default value is False.
//
Procedure ClearDataOnImportedGoodsInCommissionAgentSDocuments(Object,
																	CommissionAgentKeepsRecordsOnRNPTWithoutAgreement = False) Export
	
	
EndProcedure

// Checks the filling in of the 'NomerGTD' field in the table.
//
// Parameters:
//	Object - DocumentObject - object that is being checked in the table part.
//	Cancel - Boolean - True, indicates that the field to be checked is not filled in in the table part of the object.
//	CommissionAgentUsesInventoryAccountingByProductBatchID - Boolean - The truth is a sign that the commission agent keeps records of the RNPT.
//
Procedure CheckFillingInGTDNumberInCommissionAgentSDocuments(Object, Cancel, CommissionAgentUsesInventoryAccountingByProductBatchID = True) Export
	
	
EndProcedure

// Fills in the quantity of the RPT in the transmitted table part.
//
// Parameters:
//	RecalculationParameters - See AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient.
//	Goods - FormDataCollection - the goods table of the document with the following required fields:
//		* Products - CatalogRef.Products - product.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//		* StorageLocation - CatalogRef.Warehouses, CatalogRef.Partners, CatalogRef.CounterpartyContracts, DocumentRef.VendorInvoice, DocumentRef.ReturnOfGoodsToVendor, DocumentRef.PurchaseAdjustment - warehouse, required field if the warehouse is specified in the table part.
//		* Count - Number - amount of goods.
//		* QuantityByGBRN - Number - traceable quantity of the product.
//	FillInRows - Array of FormDataCollectionItem,
//						Array Of Stringable parts - filled rows in the tabular part.
//
Procedure FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods, FillInRows = Undefined) Export
	
	
EndProcedure

// To clear the amount of PPT.
//
// Parameters:
//	Object - DocumentObject - an object in the tabular part of which data is being cleaned.
//
Procedure ToClearQuantityByRPTVWhenSurplusGoodsAreStockSurplusRecognition(Object) Export
	
	
EndProcedure

// Checks the presence of the traceable product in the table part, and that the document date
// is after the start of traceability of the imported product.
//
// Parameters:
//	Goods - FormDataCollection - the goods table of the document with the following required fields:
//		* Products - CatalogRef.Products - product.
//	DocumentDate - Date - date of the document, to verify its use in traceability.
//	ColumnNameProducts - String - name of the item detail In the table part.
//
// Returns:
//	Boolean - True means that the document contains traceable goods in the tabular part and that the document date
//				is greater than the start date of accounting for traceable imported goods.
//
Function ThisIsTraceableDocument(Goods, DocumentDate, ColumnNameProducts = "Products") Export
	
	Result = False;
	
	Return Result;
	
EndFunction

// Displays a message to the user if tracking of traceable imported goods is enabled,
// and there is a traceable item in the product table, with tracking by GTD numbers disabled.
//
// Parameters:
//	Object - DocumentObject, Structure - object that is being checked in the table part.
//	Goods - FormDataCollection - the goods table of the document with the following required fields:
//		* Products - CatalogRef.Products - product.
//	DocumentDate - Date - date of the document, to verify its use in traceability.
//	TabularSectionName - String - name of the table part to highlight the cell with an error in it.
//	NameOfProductItemInTablePart - String - name of the table part's props to highlight the error in it.
//	LinesToVerify - Array of Structure, Undefined - a list of rows that need to be checked in the table.
//
Procedure CheckCorrectSettingsOfRNPTProducts(Object,
													Goods,
													DocumentDate,
													TabularSectionName = "Goods",
													NameOfProductItemInTablePart = "Products",
													LinesToVerify = Undefined) Export
	
	
EndProcedure

// Sets the query parameters required to determine the use of tracked products in the accounting system.
//
// Parameters:
//	Query - Query - the request for the setting of parameters.
//
Procedure SetParametersForUsingTrackingOfTraceableGoods(Query) Export
	
	If Query = Undefined Then
		Return;
	EndIf;
	
	UseAccounting = False;
	If Not Query.Parameters.Property("UseTraceableImportedGoodsAccounting") Then
		Query.SetParameter("UseTraceableImportedGoodsAccounting", UseAccounting);
	EndIf;
	
	If Not Query.Parameters.Property("DateOfTraceableImportedGoodsAccountingStart") Then
		AccountingStartDate = Date(2399, 1, 1);
		Query.SetParameter("DateOfTraceableImportedGoodsAccountingStart", AccountingStartDate);
	EndIf;

	
EndProcedure

// Returns the RNPT coefficients for the specified Organization and the list of products.
//
// Parameters:
//	ExcludedDocument - DocumentRef - a document whose movements are excluded when calculating the coefficient for the RNPT.
//	Organization - CatalogRef.Companies - the organization for which the RNPT coefficients are calculated.
//	Goods - ValueTable - a table containing information about products.
//	Terms - CatalogRef.TermsOfSale - the agreement for which the coefficients on the RNPT are calculated.
//	
// Returns:
//	ValueTable - contains the following columns:
//		* Products - CatalogRef.Products - the item for which you need to get the value
//															of the coefficient for the RNPT.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the item for which
//																			you need to get the value of the coefficient
//																			for the RNPT.
//		* StorageLocation - CatalogRef.Warehouses, CatalogRef.Partners, CatalogRef.CounterpartyContracts, DocumentRef.VendorInvoice, DocumentRef.ReturnOfGoodsToVendor, DocumentRef.PurchaseAdjustment -
//											the storage location where the nomenclature is stored, for which it is necessary to obtain
//											the value of the coefficient according to the RNPT.
//		* ZoomRatio - Number - the value of the coefficient according to the RNPT.
//
Function GetCoefficientsOfTraceableGoods(ExcludedDocument, Organization, Goods, Terms = Undefined) Export
	
	KeyOperation	= "AccountingForTraceableGoodsLocalization.GetCoefficientsOfTraceableGoods";
	MeasurementDetails		= PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	
	ReturnValue = CoefficientsOfTraceableGoods(ExcludedDocument, Organization, Terms, Goods);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ReturnValue.Count());
	
	Return ReturnValue;
	
EndFunction

// Checks the correctness of filling in the CCD card with traceable data in the document
//
// Parameters:
//	Object - DocumentObject, Structure - object that is being checked in the table part.
//	Goods - FormDataCollection - document table with the following required fields:
//		* CCDNumber - CatalogRef.CCDNumbers - the number of CCD.
//	DocumentDate - Date - date of the document, to verify its use in traceability.
//	TabularSectionName - String - name of the table part to highlight the cell with an error in it.
//	NameOfCCDNumberOfTabularPart - String - name of the table part's props to highlight the error in it.
//	LinesToVerify - Array of Structure, Undefined - a list of rows that need to be checked in the table.
//
Procedure CheckTraceabilityDataOfCCDNumbers(Object,
													Goods,
													DocumentDate,
													TabularSectionName = "Goods",
													NameOfCCDNumberOfTabularPart = "CCDNumber",
													LinesToVerify = Undefined) Export
	
	
EndProcedure

// Checks whether the CCD card is filled in correctly with traceable data
//
// Parameters:
//	CCDNumber - CatalogRef.CCDNumbers - the number of CCD.
//	
//	Returns:
//	 Number - 0 - there are no errors, 1 - it is necessary to check the cost indicators.
//
Function CheckTraceabilityDataOfCCDNumber(CCDNumber) Export
	
	Result = 0;
	
	
	Return Result;
	
EndFunction

// Returns the metadata object ID for the Customs Declaration document Import.
//
// Returns:
//	CatalogRef.MetadataObjectIDs - .
//
Function IDCustomsDeclarationImport() Export
	Return Common.MetadataObjectID("Document.CCDImport");
EndFunction

// Returns the number of orders to issue notifications.
// 
// Parameters:
//  TypesOfNotifications - Array of Type, Undefined - a list of notification types, if Undefined, then data is obtained for all types.
//  Organization - CatalogRef.Companies, Undefined - The organization for which data needs to be received, if it is Undefined, then for all organizations.
//
// Returns:
//  Map of KeyAndValue- Number of orders to be processed by notification type:
//   * Key - Type - Document type.
//   * Value - Number - number of documents.
//
Function NumberOfOrdersToIssueNotifications(TypesOfNotifications = Undefined, Organization = Undefined) Export
	
	Result = New Map;
	
	
	Return Result;
		
EndFunction

// Returns the number of returns to the registration.
//  
// Returns:
//  Number - Number of refunds for registration
//
Function NumberOfRefunds() Export
	
	DocumentsCount = 0;
	
	
	Return DocumentsCount;
	
EndFunction

// Returns the number of reports to be processed.
//  
// Returns:
//  Number - Number of reports to be processed
//
Function NumberOfReportsToBeProcessed() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	GoodsTransferred.Organization AS Organization,
		|	GoodsTransferred.ItemsLocationAttributes.StorageLocation AS Consignee,
		|	GoodsTransferred.Terms AS Terms,
		|	SUM(CASE
		|			WHEN ISNULL(GoodsTransferredBalance.CountBalance, 0) > 0
		|					AND GoodsTransferred.CountBalance > 0
		|				THEN CASE
		|						WHEN ISNULL(GoodsTransferredBalance.CountBalance, 0) < GoodsTransferred.CountBalance
		|							THEN ISNULL(GoodsTransferredBalance.CountBalance, 0)
		|						ELSE GoodsTransferred.CountBalance
		|					END
		|			ELSE 0
		|		END) AS CountBalance,
		|	SUM(CASE
		|			WHEN ISNULL(GoodsTransferredBalance.CountBalance, 0) < 0
		|					AND GoodsTransferred.CountBalance < 0
		|				THEN CASE
		|						WHEN ISNULL(-GoodsTransferredBalance.CountBalance, 0) < -GoodsTransferred.CountBalance
		|							THEN ISNULL(-GoodsTransferredBalance.CountBalance, 0)
		|						ELSE -GoodsTransferred.CountBalance
		|					END
		|			ELSE 0
		|		END) AS TheAmountOfTheRefund_3
		|FROM
		|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(
		|			&Boundary,
		|			ItemsLocationAttributes.StorageLocation <> VALUE(Catalog.Partners.OurEnterprise)
		|				AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)) AS GoodsTransferred
		|		LEFT JOIN AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(
		|				,
		|				ItemsLocationAttributes.StorageLocation <> VALUE(Catalog.Partners.OurEnterprise)
		|					AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)) AS GoodsTransferredBalance
		|		ON GoodsTransferred.Organization = GoodsTransferredBalance.Organization
		|			AND GoodsTransferred.ItemsLocationAttributes = GoodsTransferredBalance.ItemsLocationAttributes
		|			AND GoodsTransferred.Terms = GoodsTransferredBalance.Terms
		|
		|GROUP BY
		|	GoodsTransferred.Organization,
		|	GoodsTransferred.ItemsLocationAttributes.StorageLocation,
		|	GoodsTransferred.Terms";
	
	Boundary = New Boundary(EndOfDay(CurrentSessionDate()), BoundaryType.Including);
	Query.SetParameter("Boundary", Boundary);
	
	ReportCount = Query.Execute().Unload().Count();
	
	Return ReportCount;
	
EndFunction

// Fills in the 'RNPT' in the Name table.
//
// Parameters:
//	Object - DocumentObject - the object in the tabular part of which the RNPT is filled in
//	InventoryKinds - ValueTable - contains the following columns:
//		* OriginCountry - CatalogRef.WorldCountries - the country in the context of which 
//											the RNPT should be filled in in the name .
//		* ProductBatchID - CatalogRef.CCDNumbers - RNPT numbers for creation/selection
//	TSName - String - the name of the PM (Goods / types of supplies) in which we fill in the details
//	AttributeName - String - the name of the RNPT props (the number of the RTD/RNPT) to fill in
//
Procedure FillInNumbers(Object, InventoryKinds, TSName = "Goods", AttributeName = "CCDNumber") Export
EndProcedure

// Returns a collection of properties describing import notifications of goods registered based on the receipt document
//
// Parameters:
// 	RegistrationParameters - See VendorInvoiceLocalization.ParametersForRegisteringImportNotificationsOfTraceableGoods
// 
// Returns:
// 	Structure - structure with keys:
//		* PresentationOfOrderForRegistration - String, FormattedString - description of the orders for registration based on the receipt document.
//		* PresentationOfImportNotification - String, FormattedString - description of the documents registered on the basis of the receipt document.
//		* ImportNotifications - Array of DocumentRef - links to the notification of import of goods.
//		* NoticeOfImportationIsRequired - Boolean - a sign of the need to enter at least one document notifying the import of traceable goods on the basis of
//		* NumberOfOrdersForRegistration - Number - The number of orders required for execution.
//		* ThereIsRightToAddInteractiveImportNotification - Boolean - indicates whether you have the right to interactively add a document to the base.
Function NotificationsOfImportOfTraceableGoodsOnDocumentOfReceipt(RegistrationParameters) Export
	
	Result = New Structure;
	Result.Insert("PresentationOfOrderForRegistration", "");
	Result.Insert("PresentationOfImportNotification", "");	
	Result.Insert("ImportNotifications",  New Array);
	Result.Insert("NoticeOfImportationIsRequired",  False);
	Result.Insert("NumberOfOrdersForRegistration",  0);
	Result.Insert("ThereIsRightToAddInteractiveImportNotification", False);
	
	
	Return Result;

EndFunction

// Returns a collection of properties describing notifications about the movement of goods registered based on the implementation document
//
// Parameters:
// 	RegistrationParameters - See Documents.CustomerInvoice.ParametersForRegisteringNotificationsAboutMovementOfTraceableGoods
// 
// Returns:
// 	Structure - structure with keys:
//		* PresentationOfOrderForRegistration - String, FormattedString - description of the orders for execution based on the implementation document.
//		* PresentationOfMoveNotification - String, FormattedString - description of the documents registered on the basis of the implementation document.
//		* MovementNotifications - Array of DocumentRef - links to the notification of the movement of goods.
//		* NotificationOfMovementIsRequired - Boolean - an indication of the need to enter at least one document notifying the movement of traceable goods on the basis.
//		* NumberOfOrdersForRegistration - Number - the number of orders to be processed.
//		* ThereIsRightToInteractivelyAddNotificationOfMovement - Boolean - indicates whether you have the right to interactively add a document to the base.
Function NotificationsOfMovementOfTraceableGoodsUnderSalesDocument(RegistrationParameters) Export
	
	Result = New Structure;
	Result.Insert("PresentationOfOrderForRegistration", "");
	Result.Insert("PresentationOfMoveNotification", "");
	Result.Insert("MovementNotifications",  New Array);
	Result.Insert("NotificationOfMovementIsRequired", False);
	Result.Insert("NumberOfOrdersForRegistration", 0);
	Result.Insert("ThereIsRightToInteractivelyAddNotificationOfMovement", False);
	
	
	Return Result;

EndFunction

// Returns the number of transfers to be processed.
//  
// Parameters:
//	Warehouse - CatalogRef.Warehouses - Traceability warehouse.
//
// Returns:
//  Number - Number of transfers to be processed
//
Function NumberOfTransfersForRegistration(Warehouse) Export
	
	DocumentsCount = 0;
	
	
EndFunction

// Returns an indication of the presence of traceable goods in the document according to the RNPT.
//
// Parameters:
//	Ref - DocumentRef - a document in which the presence of traceable goods is checked according to the RNPT.
//
// Returns:
//	Boolean - True means that the document being checked contains traceable goods according to the RNPT.
//
Function ThereIsTraceableItemInDocument(Ref) Export
	
	ThereIsTraceableItem	= False;
	
	Return ThereIsTraceableItem;
		
EndFunction

// Fills in the tabular part of the document Traceable goods according to the Balance of the register of Traceable goods as part of the FA.
//
// Parameters:
//	Object - DocumentObject - the object in which the tabular part is filled in
//	AvailableFixedAssets - Array of CatalogRef- an array of fixed assets for which Balances are selected 
//	to fill in the tabular part.
//	CleanUpFA - Boolean - the FA cleanup flag.
//	ClearingAmount - Boolean - clear the amount by ProductBatchID 
Procedure FillInTabularPartOnRemainsOfTraceableGoods(Object, AvailableFixedAssets, CleanUpFA = False, ClearingAmount = False) Export 
	
	
EndProcedure

// Returns a description of the information table about the components to be tracked, which is used when printing data.
//
//
// Returns:
//	ValueTable - description of the table of information on traceable components, with the following columns:
//		* CCDNumber - CatalogRef.CCDNumbers - link to the RPT number of the kit.
//		* ProductBatchIDNumber - CatalogRef.CCDNumbers - a link to the data of the component of the RNPT number of the kit
//														in the information base.
//		* ProductItemNumber - String - product registration number.
//		* Count - Number - the standard number of components per unit of the kit.
//		* UnitOfMeasureCode - String - code of the unit of measurement for the ocean.
//		* UnitOfMeasurementName - String - name of the unit of measurement.
//
Function EmptyTableTraceableComponentsForPrintingData() Export
	
	CCDNumberTypeDescription	= New TypeDescription("CatalogRef.CCDNumbers");
	NumberTypeDescription		= New TypeDescription("Number");
	StringTypeDescription		= New TypeDescription("String");
	
	TraceableComponents = New ValueTable;
	TraceableComponents.Columns.Add("CCDNumber", CCDNumberTypeDescription);
	TraceableComponents.Columns.Add("ProductBatchIDNumber", CCDNumberTypeDescription);
	TraceableComponents.Columns.Add("ProductItemNumber", StringTypeDescription);
	TraceableComponents.Columns.Add("Count", NumberTypeDescription);
	TraceableComponents.Columns.Add("UnitOfMeasureCode", StringTypeDescription);
	TraceableComponents.Columns.Add("UnitOfMeasurementName", StringTypeDescription);
	TraceableComponents.Columns.Add("TotalAmountForSet", NumberTypeDescription);
	TraceableComponents.Columns.Add("AmountByProductBatchID", NumberTypeDescription);
	
	Return TraceableComponents;
	
EndFunction

// Returns a table of information about traceable components used when printing data.
//
// Parameters:
//	TraceableComponents - QueryResult - information about traceable components.
//
// Returns:
//	See EmptyTableTraceableComponentsForPrintingData
//
Function TraceableComponentsForDataPrinting(TraceableComponents) Export
	
	Selection = TraceableComponents.Select();
	TableOfComponents = EmptyTableTraceableComponentsForPrintingData();
	
	FillableProperties = "CCDNumber, ProductBatchIDNumber, Count, TotalAmountForSet, AmountByProductBatchID";
	
	While Selection.Next() Do
		NewRow = TableOfComponents.Add();
		FillPropertyValues(NewRow, Selection, FillableProperties);
		
		NewRow.ProductItemNumber						= TrimAll(String(Selection.ProductItemNumber));
		NewRow.UnitOfMeasureCode				= TrimAll(Selection.UnitOfMeasureCode);
		NewRow.UnitOfMeasurementName	= TrimAll(Selection.UnitOfMeasurementName);
	EndDo;
	
	Return TableOfComponents;
	
EndFunction

// supplements the parameters for checking the correctness of the indication of goods in the table of the damage document.
//
// Parameters:
//	CheckParameters - Structure - collection of validation parameters.
//
Procedure ToSupplementParametersOfCorrectnessOfSpecifyingNomenclatureOfDamageToGoods(CheckParameters) Export
	
	
EndProcedure

// Checks the correctness of the indication of the items to be debited and received in the table of the pochri document.
//
// Parameters:
//	Object - DocumentObject, Structure, ClientApplicationForm - the object in the tabular part of which the check is performed and which contains:
//		* Ref - DocumentRef - link to the information database document.
//	Cancel - Boolean - True, indicates that the field to be checked is not filled in in the table part of the object.
//	CheckParameters - Structure, Undefined - the test parameters.
//
Procedure CheckCorrectnessOfIndicationOfNomenclatureOfDamageToGoods(Object, Cancel, CheckParameters = Undefined) Export
	
	
EndProcedure

// Returns the currency of regulated accounting, which takes into account the cost indicators of the Catalog item 'GTD number'.
//
// Returns:
//	CatalogRef.Currencies - Currency of regulated accounting.
//
Function LocalAccountingCurrencyOfCCDNumber() Export
	
	Currency = Catalogs.Currencies.EmptyRef();
	
	
	Return Currency;
	
EndFunction

// Fills in the CHECKGTD number field in the inventory type tree
// 
// Parameters:
//	Form - ClientApplicationForm - The Form of the inventory formavodavidov of the Catalog Types of stocks.
//
Procedure FillInCheckGTDNumberFieldInTree(Form) Export
	
	
EndProcedure

// Returns the price type of the cost of the tracked products.
//
// Returns:
//	CatalogRef.TypesOfPrices - The price type of the cost of the tracked goods.
//
Function PriceTypeOfCostOfTraceableGoods() Export
	
	PriceKind = Catalogs.TypesOfPrices.EmptyRef();
	
	
	Return PriceKind;
	
EndFunction

// Changes the title to "CCD / ProductBatchID number" or "ProductBatchID Number" for the submitted form elements. 
//
// Parameters:
// 	FormItems     - FormAllItems - Form elements that contain the desired element
// 	ElementsOfCCDNumber  - String, Array of String - list of names of form elements with "CCD number"
// 	OnlyProductBatchID        - Boolean - indicates that only the ProductBatchID number is being entered
// 	Postfix          - String - additional description of the title
//	ChangeHint - Boolean - changing the hint for form elements.
//
Procedure SetTitleNumberOfCCD(FormItems, ElementsOfCCDNumber, OnlyProductBatchID = False, Postfix = "", ChangeHint = True) Export
	
	
	Return;
	
EndProcedure

// Sets the header for the 'CCD Number' field in the list of the 'GTD Number' Catalog selection form.
//
// Parameters:
//	FormItems - FormItems - form element.
//	ElementsOfCCDNumber - String - the name of the field is 'CCD number'.
//	ListOfCCDTypes - Array of EnumRef.CCDNumberTypes - the list of selection of CCD room types.
//	CCDNumberType - EnumRef.CCDNumberTypes - selection of the CCD number type.
//
Procedure SetTitleNumberOfCCDFormOfChoice(FormItems, ElementsOfCCDNumber, ListOfCCDTypes, CCDNumberType) Export
	
	
	Return;
	
EndProcedure

// Returns a string for the Presentation of the CCD settings in the user interface.
//
// Returns:
//	String - Presentation of the CCD settings in the user interface
Function PresentationOfCCD() Export
	
	PresentationOfCCD = NStr("vi = 'TKHQ';
							|ru = 'ГТД';
							|en = 'CCD'; fa = 'اظهارنامه گمرکی (CCD)';
							|it = 'ГТД';
							|pl = 'CCD';
							|tr = 'GKB'");
	
	
	Return PresentationOfCCD;
	
EndFunction

// Complements the parameters for checking the presence of traceable works in the tabular part of the object.
//
// Parameters:
//	CheckParameters - Structure - collection of validation parameters.
//
Procedure AddParametersForCheckingPresenceOfTraceableWorksInTabularPart(CheckParameters) Export
	
	
EndProcedure

// Checks for traceable works in the tabular part of the object.
//
// Parameters:
//	Object - DocumentObject, ClientApplicationForm - the object for which the check is performed and which contains:
//		* Ref - DocumentRef - link to the information database document.
//	Cancel - Boolean - a sign of continuation of further processing of the checked object in the information database.
//	CheckParameters - See AddParametersForCheckingPresenceOfTraceableWorksInTabularPart.
//
Procedure CheckForTraceableItemsInTablePart(Object, Cancel, CheckParameters = Undefined) Export
	
	
EndProcedure

#EndRegion

#Region Private


Function CoefficientsOfTraceableGoods(ExcludedDocument, Organization, Terms, Goods)
	
	ReturnValue = New ValueTable;
	ReturnValue.Columns.Add("Products",	New TypeDescription("CatalogRef.Products"));
	ReturnValue.Columns.Add("Characteristic",	New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ReturnValue.Columns.Add("StorageLocation",	New TypeDescription("CatalogRef.Warehouses,
																				|CatalogRef.Partners,
																				|CatalogRef.CounterpartyContracts,
																				|CatalogRef.Companies,
																				|DocumentRef.VendorInvoice,
																				|DocumentRef.ReturnOfGoodsToVendor,
																				|DocumentRef.PurchaseAdjustment"));
	
	Qualifier = New NumberQualifiers(23, 11);
	ReturnValue.Columns.Add("ZoomRatio", New TypeDescription("Number", , , Qualifier));
	
	
	Return ReturnValue;
	
EndFunction

Function AddQueryTextsOfDataSources(StructureOfActions,
		QueryDetails,
		CachedValues) Export
	
	
EndFunction


#EndRegion
