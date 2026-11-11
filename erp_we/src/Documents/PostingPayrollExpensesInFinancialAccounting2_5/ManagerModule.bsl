#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//   DocumentMechanisms - Array of String - contains a list of names of accounting mechanisms that will be
//                        registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("WIPAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	//++ WE
	DocumentMechanisms.Add("PayrollAccountingHR");
	//-- WE
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.PostingPayrollExpensesInFinancialAccounting2_5") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	FillInInitializationParameters(Query, DocumentRef);
	
	QueryTexts = New ValueList;
	
	QueryTextDocumentTables(QueryTexts);
	
	QueryTextTableOtherExpenses(QueryTexts, Registers);
	QueryTextTableItemisedExpensesLots(QueryTexts, Registers);
	QueryTextTableWIPLaborCosts(QueryTexts, Registers);
	
	QueryTextTableOtherAssetsLiabilities(QueryTexts, Registers);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts, Registers);
	//++ WE
	QueryTextTablePayrollCalculations(QueryTexts, Registers);
	//-- WE
	QueryTextTableRecordsCashIncomeExpenses(QueryTexts, Registers);
	QueryTextTableRecordsCounterpartyIncomeExpenses(QueryTexts, Registers);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts, Registers);
	
	QueryTextTableOtherIncome(QueryTexts, Registers);
	QueryTextTableAdvanceHolderCash(QueryTexts, Registers);
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
	
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	If DocumentsPosting.ThereIsQueryTable("TTTableEmployeeOutput", QueryTexts) Then
		ProductionOutputTable = DistributeChargesByStagesOfProduction(Query.Parameters);
		Query.SetParameter("TableEmployeeDevelopment", ProductionOutputTable);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of fill commands.
//
// Parameters:
//   FillingCommands - See ObjectsFillingOverridable.BeforeAddFillCommands.FillingCommands
//   Parameters - See ObjectsFillingOverridable.BeforeAddFillCommands.Parameters
//
Procedure AddFillCommands(FillingCommands, Parameters) Export
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// StandardSubsystems.AccessManagement
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";
	
EndProcedure
// End StandardSubsystems.AccessManagement

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//   Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
EndProcedure
// End StandardSubsystems.ObjectsVersioning

// Returns parameters for setting up accounting accounts in the document.
// 
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	ParametersArray = New Array();
	
	#Region Accruals
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Accruals";
	SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	SetupParameters.Presentation = "";
	
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.Companies"),          "Object.Organization");
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.BusinessStructure"), "Object.Accruals.Department");
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.Persons"),       "Object.Accruals.Individual");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region PayrollTaxes
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.PayrollTaxes";
	SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	SetupParameters.Presentation = "";
	
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.Companies"),          "Object.Organization");
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.BusinessStructure"), "Object.PayrollTaxes.Department");
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.Persons"),       "Object.PayrollTaxes.Individual");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region Deductions
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Deductions";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	SetupParameters.Presentation = "";
	
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.Companies"),          "Object.Organization");
	SetupParameters.ExtDimensionSelectionSources.Add(
		Type("CatalogRef.BusinessStructure"), "Object.Deductions.Department");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//              .
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ParametersArray = New Array;
	
	#Region Accruals_OnOtherExpensesLiabilities
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Accruals";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ReflectionOptions = New Array;
	ReflectionOptions.Add(Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses);
	ReflectionOptions.Add(Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities);
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("PostingOption", ReflectionOptions);
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region TaxesOrganizationContributions_OtherExpensesLiabilities
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.PayrollTaxes";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ReflectionOptions = New Array;
	ReflectionOptions.Add(Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses);
	ReflectionOptions.Add(Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities);
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("PostingOption", ReflectionOptions);
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region Deductions_OnOtherIncomeAssets
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Deductions";
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ReflectionOptions = New Array;
	ReflectionOptions.Add(Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome);
	ReflectionOptions.Add(Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities);
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("PostingOption", ReflectionOptions);
	
	ParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ParametersArray;

EndFunction

#Region ImportDataFromFile

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
//  AddressOfUploadedData    - String - address of the temporary storage with a table of values that
//                                       contains the downloaded data from the file.
//  AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
//  ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//   * Column       - String - name of the column where the ambiguity was detected;
//   * Id - Number  - ID of the string where the ambiguity was detected.
//  FullTabularSectionName - String - full name of the table part where data is loaded.
//  AdditionalParameters - Arbitrary - Any additional information.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	PathParts = StrSplit(FullTabularSectionName, ".");
	TabularSectionName = PathParts.Get(PathParts.UBound());
	
	DataToImport    = GetFromTempStorage(AddressOfUploadedData); // ValueTable - 
	MappingTable = GetFromTempStorage(AddressOfMappingTable); // ValueTable - 
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("DataToImport", DataToImport);
	Query.SetParameter("Organization", AdditionalParameters.Organization);
	Query.SetParameter("LoadingDeductions", TabularSectionName = "Deductions");
	Query.SetParameter("DutiesOfTaxAgent", TabularSectionName = "DutiesOfTaxAgent");
	
	QueriesArray = New Array;
	QueriesArray.Add(RequestTextForUploadedData(DataToImport.Columns));
	QueriesArray.Add(DataMatchingRequestText(DataToImport.Columns));
	QueriesArray.Add(RequestTextForSelectionOfMatchedData());
	
	Query.Text = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = MappingTable.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.NumberOfDivisions_ > 1 Then
			WritingAboutAmbiguity = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id; 
			WritingAboutAmbiguity.Column = "DivisionName_";
		EndIf;
		
		If Selection.NumberOfIndividuals > 1 Then
			WritingAboutAmbiguity = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id; 
			WritingAboutAmbiguity.Column = "IndividualFULLName";
		EndIf;
		
		If Selection.NumberOfTypesOfAccrualsDeductions > 1 Then
			WritingAboutAmbiguity = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id; 
			WritingAboutAmbiguity.Column = "TypeOfAccrualDeductionName";
		EndIf;
		
		If Selection.NumberOfTypesOfTaxes > 1 Then
			WritingAboutAmbiguity = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id; 
			WritingAboutAmbiguity.Column = "TypeOfTaxName";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(MappingTable, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
//
// Parameters:
//   FullTabularSectionName   - String - full name of the table part where data is loaded.
//   ConflictsList    - Array - An array to fill in with ambiguous data.
//   ColumnName                - String - Name of the column where the ambiguity occurred. 
//   LoadedValuesString - String - Downloadable data, on the basis of which there was ambiguity.
//   AdditionalParameters   - Arbitrary - Any additional information
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	PathParts = StrSplit(FullTabularSectionName, ".");
	TabularSectionName = PathParts.Get(PathParts.UBound());
	
	If ColumnName = "Department" Then
		
		Query = New Query;
		Query.Text =
		"SELECT Ref
		|FROM Catalog.BusinessStructure
		|WHERE Description = &Description";
		
		Query.SetParameter("Description",
			LoadedValuesString.DivisionName_);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
	If ColumnName = "Individual" Then
		
		Query = New Query;
		Query.Text =
		"SELECT Ref
		|FROM Catalog.Persons
		|WHERE Description = &Description";
		
		Query.SetParameter("Description",
			LoadedValuesString.IndividualFULLName);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
	If ColumnName = "AccrualKind" Or ColumnName = "DeductionKind" Then
		
		Query = New Query;
		Query.Text =
		"SELECT Ref
		|FROM Catalog.AccrualAndDeductionKinds
		|WHERE ItIsADeduction = &ItIsADeduction
		|	AND Description = &Description";
		
		Query.SetParameter("Description",
			LoadedValuesString.TypeOfAccrualDeductionName);
		Query.SetParameter("ItIsADeduction", TabularSectionName = "Deductions");
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
	If ColumnName = "TaxKind" Then
		
		Query = New Query;
		Query.Text =
		"SELECT Ref
		|FROM Catalog.TaxContributionKinds
		|WHERE DeductedFromEmployeeWages = &DeductedFromEmployeeWages
		|	AND Description = &Description";
		
		Query.SetParameter("Description",
			LoadedValuesString.TypeOfTaxName);
		Query.SetParameter("DeductedFromEmployeeWages", TabularSectionName = "DutiesOfTaxAgent");
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function OptionsForReflectingAccruals() Export
	
	ReflectionOptions = New Map;
	
	// Reflection of costs by item of expenditure
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses,
		NStr("vi = 'Số tiền được đưa vào tài khoản dưới dạng chi phí được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма принимается к учету как постатейный расход и распределяется в соответствии с настройками статьи';
			|en = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings'; fa = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings';
			|it = 'L''importo viene registrato in contabilità come spesa dettagliata per articolo e ripartita secondo le impostazioni della voce di spesa';
			|pl = 'Wartość jest przyjmowana do ewidencji jako rozchód wg pozycji i dzielony zgodnie z ustawieniami pozycji';
			|tr = 'Tutar, kalemler bazında gider olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"ExpenseItem, DimensionOfExpenses, LineOfBusiness");
	OptionDetails.CheckFilling = False;
	
	ExpenseItem = OptionDetails.AttributeProperties.ExpenseItem; // See PropertiesOfReflectionProps
	ExpenseItem.Main = True;
	
	LineOfBusiness = OptionDetails.AttributeProperties.LineOfBusiness; // See PropertiesOfReflectionProps
	LineOfBusiness.Used = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	LineOfBusiness.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Reflection of costs under the item of assets/liabilities
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities,
		NStr("vi = 'Số tiền được đưa vào tài khoản dưới dạng chi phí được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма принимается к учету как постатейный расход и распределяется в соответствии с настройками статьи';
			|en = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings'; fa = 'The amount is accounted for as an itemized expense and is allocated according to the item''s settings';
			|it = 'L''importo viene registrato in contabilità come spesa dettagliata per articolo e ripartita secondo le impostazioni della voce di spesa';
			|pl = 'Wartość jest przyjmowana do ewidencji jako rozchód wg pozycji i dzielony zgodnie z ustawieniami pozycji';
			|tr = 'Tutar, kalemler bazında gider olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"ExpenseItem, AssetsLiabilitiesDimension, GLAccountSettings, LineOfBusiness");
	OptionDetails.CheckFilling = False;
	
	OptionDetails.Used = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	ExpenseItem = OptionDetails.AttributeProperties.ExpenseItem; // See PropertiesOfReflectionProps
	ExpenseItem.Main = True;
	
	GLAccountSettings = OptionDetails.AttributeProperties.GLAccountSettings; // See PropertiesOfReflectionProps
	GLAccountSettings.Used =
		GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	LineOfBusiness = OptionDetails.AttributeProperties.LineOfBusiness; // See PropertiesOfReflectionProps
	LineOfBusiness.Used = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	LineOfBusiness.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Distribution of production costs
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.AllocateToProduction,
		NStr("vi = 'Số tiền đã trích được phân bổ vào các lô sản xuất theo sản lượng của nhân viên';
			|ru = 'Начисленная сумма распределяется на партии производства по выработке сотрудников';
			|en = 'Accrued amount is allocated to production lots for timesheets charge'; fa = 'Accrued amount is allocated to production lots for timesheets charge';
			|it = 'L''importo maturato viene ripartito per lotti di produzione in base alla produttività dei dipendenti';
			|pl = 'Naliczona kwota przydziela się na partie produkcji wg wydajności pracowników';
			|tr = 'Tahakkuk eden tutar,  zaman çizelgesi bazlı ücretlendirmeye dayalı olarak üretim lotlarına dağıtılır'"),
		"AllocationBaseType, ProductCostElement");
	
	AllocationBaseType = OptionDetails.AttributeProperties.AllocationBaseType; // See PropertiesOfReflectionProps
	AllocationBaseType.Main = True;
	
	ProductCostElement = OptionDetails.AttributeProperties.ProductCostElement; // See PropertiesOfReflectionProps
	ProductCostElement.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// 
	
	Return New FixedMap(ReflectionOptions);
	
EndFunction

Function OptionsForReflectingDeductions() Export
	
	ReflectionOptions = New Map;
	
	// Reflection of deductions by income item
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome,
		NStr("vi = 'Số tiền khấu trừ được tính đến dưới dạng thu nhập được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма удержания принимается к учету как постатейный доход и распределяется в соответствии с настройками статьи';
			|en = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.'; fa = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.';
			|it = 'L''importo della trattenuta viene registrato come entrata dettagliata per articolo e ripartita secondo le impostazioni della voce';
			|pl = 'Wartość potrącenia jest przyjmowana do ewidencji dochód wg pozycji i przydziela się zgodnie z ustawieniami pozycji';
			|tr = 'Stopaj tutarı kalem bazlı gelir olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"IncomeItem, DimensionOfRevenue");
	OptionDetails.CheckFilling = False;
	
	IncomeItem = OptionDetails.AttributeProperties.IncomeItem; // See PropertiesOfReflectionProps
	IncomeItem.Main = True;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Reflection of deductions under the item of assets/liabilities
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities,
		NStr("vi = 'Số tiền khấu trừ được tính đến dưới dạng thu nhập được chia thành từng khoản và được phân bổ theo các cài đặt của dạng';
			|ru = 'Сумма удержания принимается к учету как постатейный доход и распределяется в соответствии с настройками статьи';
			|en = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.'; fa = 'The amount of deduction is accounted for as itemized income and is allocated according to the item''s settings.';
			|it = 'L''importo della trattenuta viene registrato come entrata dettagliata per articolo e ripartita secondo le impostazioni della voce';
			|pl = 'Wartość potrącenia jest przyjmowana do ewidencji dochód wg pozycji i przydziela się zgodnie z ustawieniami pozycji';
			|tr = 'Stopaj tutarı kalem bazlı gelir olarak muhasebeleştirilir ve kalem ayarlarına uygun olarak dağıtılır'"),
		"IncomeItem, AssetsLiabilitiesDimension, GLAccountSettings");
	OptionDetails.CheckFilling = False;
	
	OptionDetails.Used = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	IncomeItem = OptionDetails.AttributeProperties.IncomeItem; // See PropertiesOfReflectionProps
	IncomeItem.Main = True;
	
	GLAccountSettings = OptionDetails.AttributeProperties.GLAccountSettings; // See PropertiesOfReflectionProps
	GLAccountSettings.Used =
		GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Repayment of mutual settlements by withholding
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.PayOffAccountsPayable,
		NStr("vi = 'Số tiền khấu trừ được hướng đến việc thanh toán đối trừ';
			|ru = 'Сумма удержания направляется на погашение взаиморасчетов';
			|en = 'The amount of deduction is directed to the mutual settlements repayment'; fa = 'The amount of deduction is directed to the mutual settlements repayment';
			|it = 'L''importo della trattenuta viene destinato all''estinzione di regolamenti reciproci';
			|pl = 'Wartość potrącenia jest skierowana na umorzenie rozliczeń wzajemnych';
			|tr = 'Stopaj tutarı mutabakat yapılması için kullanılır'"),
		"Counterparty, ARAPObject");
	
	Counterparty = OptionDetails.AttributeProperties.Counterparty; // See PropertiesOfReflectionProps
	Counterparty.Main = True;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// Repayment of settlements with the accountable person
	
	OptionDetails = NewVersionOfReflection(
		Enums.AccrualsDeductionsRecordOptions.PayOffAdvanceHolderAccountsPayable,
		NStr("vi = 'Số tiền khấu trừ được hướng đến giảm hạch toán với người nhận tạm ứng';
			|ru = 'Сумма удержания направляется на погашение расчетов с подотчетным лицом';
			|en = 'The amount of deduction is directed to the settlement repayment with advance holder'; fa = 'The amount of deduction is directed to the settlement repayment with advance holder';
			|it = 'L''importo della trattenuta viene destinato all''estinzione di regolamenti con la persona responsabile';
			|pl = 'Wartość potrąceń jest skierowana na umorzenie rozliczeń z zaliczkobiorcą';
			|tr = 'Stopaj tutarı, sorumlu kişiye ödenecek hesapları kapatmak için kullanılır'"),
		"IssuancePurpose");
	
	IssuancePurpose = OptionDetails.AttributeProperties.IssuancePurpose; // See PropertiesOfReflectionProps
	IssuancePurpose.Used = GetFunctionalOption("ControlIssueOfCashByPurposes");
	IssuancePurpose.AttributeIsRequired = False;
	
	ReflectionOptions.Insert(OptionDetails.Value, New FixedStructure(OptionDetails));
	
	// 
	
	Return New FixedMap(ReflectionOptions);
	
EndFunction

Function PropertiesOfReflectionArticle(AssetRef) Export
	
	Result = IncomeAndExpensesServerCallCached.ArticleDetailsValues(AssetRef);
	Result.Insert("YouCanConfigureAccountingAccounts", False);
	Result.Insert("AutocompletionIsAvailable", False);
	
	If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		SelectedTypes_ = TypesOfAccrualAnalyticsAvailableForFillingIn();
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		SelectedTypes_ = TypesOfRetentionAnalyticsAvailableForFilling();
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Result.YouCanConfigureAccountingAccounts = Not
			GLAccountSettingsInternalServerCall.AccountingAccountsAreSpecifiedInTransactionSettings(AssetRef);
		Return Result;
	EndIf;
	
	For Each TypeOfAnalytics In SelectedTypes_ Do
		If Result.ValueType.ContainsType(TypeOfAnalytics) Then
			Result.AutocompletionIsAvailable = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function DescriptionOfTemplateColumnsToLoadFromFile(TabularSectionName, UnitsRequired, IndividualsAreRequired, TypesOfCalculationsRequired) Export
	
	TemplateColumns = New Array;
	
	If UnitsRequired Then
		
		Group = NStr("vi = 'Bộ phận';
					|ru = 'Подразделение';
					|en = 'Business unit'; fa = 'Business unit';
					|it = 'Reparto';
					|pl = 'Dział';
					|tr = 'Departman'");
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"UnitCode_", New TypeDescription("String",, New StringQualifiers(9)));
		Column.Title = NStr("vi = 'Mã';
							|ru = 'Код';
							|en = 'Code'; fa = 'کد';
							|it = 'Codice';
							|pl = 'Kod';
							|tr = 'Kod'");
		Column.Group = Group;
		Column.Width = 10;
		Column.Parent = "Department";
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"DivisionName_", New TypeDescription("String",, New StringQualifiers(100)));
		Column.Title = NStr("vi = 'Tên gọi';
							|ru = 'Наименование';
							|en = 'Description'; fa = 'شرح';
							|it = 'Nome';
							|pl = 'Nazwa';
							|tr = 'Ad'");
		Column.IsRequiredInfo = True;
		Column.Group = Group;
		Column.Parent = "Department";
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
	EndIf;
	
	If IndividualsAreRequired Or TabularSectionName ="Deductions" Then
		
		Group = NStr("vi = 'Cá nhân';
					|ru = 'Физическое лицо';
					|en = 'Person'; fa = 'شخص';
					|it = 'Persona fisica';
					|pl = 'Osoba fizyczna';
					|tr = 'Gerçek kişi'");
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"IndividualCode", New TypeDescription("String",, New StringQualifiers(10)));
		Column.Title = NStr("vi = 'Mã';
							|ru = 'Код';
							|en = 'Code'; fa = 'کد';
							|it = 'Codice';
							|pl = 'Kod';
							|tr = 'Kod'");
		Column.Group = Group;
		Column.Width = 10;
		Column.Parent = "Individual";
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"IndividualFULLName", New TypeDescription("String",, New StringQualifiers(100)));
		Column.Title = NStr("vi = 'Họ tên';
							|ru = 'ФИО';
							|en = 'Full name'; fa = 'نام کامل';
							|it = 'Cognome, nome, patronimico';
							|pl = 'Imię i nazwisko';
							|tr = 'Tam adı'");
		Column.IsRequiredInfo = True;
		Column.Group = Group;
		Column.Parent = "Individual";
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("TypeOfAccrualDeductionName",
		New TypeDescription("String",, New StringQualifiers(100)));
	If TabularSectionName = "Deductions" Then
		Column.Title = NStr("vi = 'Dạng giữ lại';
							|ru = 'Вид удержания';
							|en = 'Deduction kind'; fa = 'نوع کسر';
							|it = 'Tipo di trattenuta';
							|pl = 'Typ potrącenia';
							|tr = 'Stopaj türü'");
		Column.Parent = "DeductionKind";
	Else
		Column.Title = NStr("vi = 'Dạng tính lương';
							|ru = 'Вид начисления';
							|en = 'Accrual item'; fa = 'قلم محاسبه';
							|it = 'Tipo di importo maturato';
							|pl = 'Rodzaj naliczania';
							|tr = 'Tahakkuk türü'");
		Column.Parent = "AccrualKind";
	EndIf;
	Column.Group = Column.Title;
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	If TypesOfCalculationsRequired And TabularSectionName <> "PayrollTaxes" Then
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"ARAPType", New TypeDescription("CatalogRef.TypesOfEmployeeCompensations"));
		Column.Title = NStr("vi = 'Dạng hạch toán';
							|ru = 'Вид расчетов';
							|en = 'Payroll item'; fa = 'قلم حقوق و دستمزد';
							|it = 'Tipo di regolamenti';
							|pl = 'Rodzaj rozliczeń';
							|tr = 'Alacak/Borç türü'");
		Column.IsRequiredInfo = True;
		Column.Group = Column.Title;
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
	EndIf;
	
	If TabularSectionName = "PayrollTaxes" Or TabularSectionName = "DutiesOfTaxAgent" Then
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"TypeOfTaxName", New TypeDescription("String",, New StringQualifiers(100)));
		Column.IsRequiredInfo = True;
		Column.Title = NStr("vi = 'Dạng thuế';
							|ru = 'Вид налога';
							|en = 'Tax kind'; fa = 'نوع مالیات';
							|it = 'Tipo di tassa';
							|pl = 'Rodzaj podatku';
							|tr = 'Vergi türü'");
		Column.Group = Column.Title;
		Column.Parent = "TaxKind";
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"TaxBase", New TypeDescription("Number", New NumberQualifiers()));
		Column.Title = NStr("vi = 'Cơ sở thuế';
							|ru = 'Налоговая база';
							|en = 'Tax base'; fa = 'مبنای مالیات';
							|it = 'Base Imponibile';
							|pl = 'Podstawa opodatkowania';
							|tr = 'Vergi matrahı'");
		Column.Group = Column.Title;
		Column.Width = 15;
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails(
		"Sum", New TypeDescription("Number", New NumberQualifiers()), NStr("vi = 'Tổng số';
																			|ru = 'Сумма';
																			|en = 'Amount'; fa = 'مبلغ';
																			|it = 'Importo';
																			|pl = 'Wartość';
																			|tr = 'Tutar'"));
	Column.IsRequiredInfo = True;
	Column.Group = Column.Title;
	Column.Width = 15;
	Column.Position = TemplateColumns.UBound() + 1;
	TemplateColumns.Add(Column);
	
	If TabularSectionName <> "DutiesOfTaxAgent" Then
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails(
			"PostingOption", New TypeDescription("EnumRef.AccrualsDeductionsRecordOptions"));
		Column.Title = NStr("vi = 'Phương án phản ánh';
							|ru = 'Вариант отражения';
							|en = 'Posting option'; fa = 'گزینه ثبت';
							|it = 'Opzione di visualizzazione';
							|pl = 'Wariant odzwierciedlenia';
							|tr = 'Yansıtma seçeneği'");
		Column.Group = Column.Title;
		Column.Position = TemplateColumns.UBound() + 1;
		TemplateColumns.Add(Column);
		
	EndIf;
	
	Return TemplateColumns;
	
EndFunction

#Region FillingProcedures

Function DocumentFillingParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Organization");
	Parameters.Insert("BeginOfPeriod", '00010101');
	Parameters.Insert("EndOfPeriod",  '00010101');
	Parameters.Insert("IndividualsInDetail", False);
	Parameters.Insert("Department");
	
	Parameters.Insert("Sources", New Structure);
	
	Return Parameters;
	
EndFunction

Function PrepareFillingData(Parameters) Export
	
	Sources = Parameters.Sources;
	
	Result = New Structure;
	If Sources.Property("WorkOutput") Or Sources.Count() = 0 Then
		Result.Insert("WorkOutput", GetProductionData(Parameters));
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function NewVersionOfReflection(Value, LongDesc, Attributes)
	
	PostingOption = New Structure;
	
	PostingOption.Insert("Value", Value);
	PostingOption.Insert("OptionDetails", LongDesc);
	
	PostingOption.Insert("Used", True);
	
	PostingOption.Insert("Attributes", Attributes);
	
	AttributesList = New Array;
	AttributeProperties = New Structure;
	For Each ListItem In StrSplit(Attributes, ",") Do
		AttributeName = TrimAll(ListItem);
		AttributeProperties.Insert(AttributeName, PropertiesOfReflectionProps());
		AttributesList.Add(AttributeName);
	EndDo;
	
	PostingOption.Insert("TemplateOfPresentation", "[" + StrConcat(AttributesList, "][") + "]");
	PostingOption.Insert("AttributeProperties", New FixedStructure(AttributeProperties));
	PostingOption.Insert("CheckFilling", True);
	
	Return PostingOption;
	
EndFunction

// Properties of the reflection props
//
// Returns:
//  Structure - Empty Structure:
//    * Used - Boolean - indication of the use of props for the reflection option,
//    * AttributeIsRequired - Boolean - a sign of mandatory filling,
//    * Main - Boolean - basic Attributes.
//
Function PropertiesOfReflectionProps()
	
	PropsProperties = New Structure;
	PropsProperties.Insert("Used", True);
	PropsProperties.Insert("AttributeIsRequired", True);
	PropsProperties.Insert("Main", False);
	
	Return PropsProperties;
	
EndFunction

Function TypesOfAccrualAnalyticsAvailableForFillingIn()
	
	TypesArray = New Array;
	
	TypesArray.Add(Type("CatalogRef.Persons"));
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.Companies"));
	
	Return New FixedArray(TypesArray);
	
EndFunction

Function TypesOfRetentionAnalyticsAvailableForFilling()
	
	TypesArray = New Array;
	
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.Companies"));
	
	Return New FixedArray(TypesArray);
	
EndFunction

Function GetProductionData(Parameters)
	
	Query = New Query;
	Query.SetParameter("Organization",   Parameters.Organization);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  Parameters.EndOfPeriod);
	
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("FilterByDivision", ValueIsFilled(Parameters.Department));
	
	Query.SetParameter("IndividualsInDetail", Parameters.IndividualsInDetail);
	
	Query.Text =
	"SELECT
	|	Development_1.Date AS Date,
	|	Development_1.Ref AS Development_1,
	|	Development_1.Department AS Department,
	|	CASE
	|		WHEN &IndividualsInDetail = TRUE THEN TSEmployees.Employee_
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|	END AS Individual,
	|	SUM(TSEmployees.Sum) AS Sum
	|FROM
	|	Document.WorkOutput AS Development_1
	|	INNER JOIN Document.WorkOutput.Employees AS TSEmployees
	|	ON Development_1.WorkOrderKind = VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|		AND Development_1.Ref = TSEmployees.Ref
	|		AND Development_1.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Development_1.Organization = &Organization
	|		AND (NOT &FilterByDivision
	|			OR Development_1.Department = &Department)
	|		AND Development_1.Posted
	|
	|GROUP BY
	|	Development_1.Ref,
	|	Development_1.Department,
	|	CASE
	|		WHEN &IndividualsInDetail = TRUE THEN TSEmployees.Employee_
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	Development_1.Date,
	|	Development_1.Ref,
	|	Development_1.Department,
	|	CASE
	|		WHEN &IndividualsInDetail = TRUE THEN TSActivityKinds.Employee_
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|	END,
	|	SUM(TSActivityKinds.Sum)
	|FROM
	|	Document.WorkOutput AS Development_1
	|	INNER JOIN Document.WorkOutput.ActivityKinds AS TSActivityKinds
	|	ON Development_1.WorkOrderKind <> VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|		AND TSActivityKinds.Employee_ <> VALUE(Catalog.Persons.EmptyRef)
	|		AND Development_1.Ref = TSActivityKinds.Ref
	|		AND Development_1.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Development_1.Organization = &Organization
	|		AND (NOT &FilterByDivision
	|			OR Development_1.Department = &Department)
	|		AND Development_1.Posted
	|
	|GROUP BY
	|	Development_1.Ref,
	|	Development_1.Department,
	|	CASE
	|		WHEN &IndividualsInDetail = TRUE THEN TSActivityKinds.Employee_
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|	END";
	
	Return Query.Execute().Unload();
	
EndFunction

#Region ProceduresForConducting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.Ref          AS Ref,
	|	Attributes.Date            AS Date,
	|	Attributes.Number           AS Number,
	|	Attributes.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	Attributes.CalculationsPeriod  AS CalculationsPeriod,
	|	Attributes.Organization     AS Organization,
	|	Attributes.Currency          AS Currency,
	|	Attributes.Patch     AS Patch,
	|	Attributes.ReversedDocument AS ReversedDocument,
	|	Attributes.CorrectedDocument AS CorrectedDocument,
	|	Attributes.AccrualsAndTaxesDetailedByPersons AS AccrualsAndTaxesDetailedByPersons
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5 AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Attributes.Currency, Attributes.Currency, EndOfMonth(Attributes.CalculationsPeriod), Attributes.Organization);
	
	TypesOfPayrollAnalytics = Common.ObjectAttributeValue(ChartsOfCharacteristicTypes.AssetLiabilityItems.Payroll, "ValueType");
	
	Query.SetParameter("Ref",                                 Attributes.Ref);
	Query.SetParameter("Period",                                 EndOfMonth(Attributes.CalculationsPeriod));
	Query.SetParameter("Date",                                   Attributes.Date);
	Query.SetParameter("AdjustmentPeriod_",					Attributes.AdjustmentPeriod_);
	Query.SetParameter("Number",                                  Attributes.Number);
	Query.SetParameter("CalculationsPeriod",                         Attributes.CalculationsPeriod);
	Query.SetParameter("Organization",                            Attributes.Organization);
	Query.SetParameter("StartDate",                             BegOfMonth(Attributes.CalculationsPeriod));
	Query.SetParameter("EndDate",                          EndOfMonth(Attributes.CalculationsPeriod));
	
	Query.SetParameter("ManagementAccountingCurrency",             Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("LocalAccountingCurrency",         LocalAccountingCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",        Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency",         Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("Patch",                            Attributes.Patch);
	Query.SetParameter("ReversedDocument",                   Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",                   Attributes.CorrectedDocument);
	
	Query.SetParameter("AccrualsAndTaxesDetailedByPersons",             Attributes.AccrualsAndTaxesDetailedByPersons);
	Query.SetParameter("UseAccountingOfOtherAssetsAndLiabilities",  GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID(
		EmptyRef().Metadata().FullName()));
	Query.SetParameter("PayrollAnalytics",                   TypesOfPayrollAnalytics.AdjustValue());  
	
	//++ WE
	
	StartDatePayrollAndHumanResources = BegOfDay(Constants.StartDatePayrollAndHumanResources.Get());
	
	Query.SetParameter("PayrollAndPersonnelUsageModeIsEnabledWE",  
				GetFunctionalOption("PayrollAndHumanResourcesWE") 
					And StartDatePayrollAndHumanResources<=Attributes.CalculationsPeriod);
	//-- WE
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure QueryTextDocumentTables(QueryTexts)
	
	TableName = "DocumentsToBeReflected";
	
	QueryText =
	"SELECT
	|	Document.Ref AS Ref
	|INTO DocumentsToBeReflected
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5 AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
	// Table parts of the document
	
	TableName = "TTAccruals";
	
	QueryText =
	"SELECT
	|	Table.Ref,
	|	&Organization AS Organization,
	|	Table.LineNumber,
	|	Table.Department,
	|	Table.Individual,
	|	Table.Employee,
	|	Table.ARAPType,
	|	Table.AccrualKind,
	|	Table.PostingOption,
	|	Table.AllocationBaseType,
	|	Table.ProductCostElement,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	CASE Table.DimensionOfExpenses
	|		WHEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Table.Department
	|		WHEN VALUE(Catalog.Persons.EmptyRef)
	|			THEN Table.Individual
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE Table.DimensionOfExpenses
	|	END AS AutoExpenseAnalytics,
	|	Table.AssetsLiabilitiesDimension,
	|	CASE Table.AssetsLiabilitiesDimension
	|		WHEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Table.Department
	|		WHEN VALUE(Catalog.Persons.EmptyRef)
	|			THEN Table.Individual
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE Table.AssetsLiabilitiesDimension
	|	END AS AutoAnalyticsOfAssetsLiabilities,
	|	Table.GLAccountSettings,
	|	Table.LineOfBusiness,
	|	Table.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.WageRecord) AS BusinessTransactionSetting,
	|	CAST(Table.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(Table.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	Table.Sum
	|INTO TTAccruals
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5.Accruals AS Table
	|	INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON Table.Ref = DocumentsToBeReflected.Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
	TableName = "TTTaxesOrganizationFees";
	
	QueryText =
	"SELECT
	|	Table.Ref,
	|	&Organization AS Organization,
	|	Table.LineNumber,
	|	Table.Department,
	|	Table.Individual,
	|	Table.TaxKind,
	|	Table.PostingOption,
	|	Table.AllocationBaseType,
	|	Table.ProductCostElement,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	CASE Table.DimensionOfExpenses
	|		WHEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Table.Department
	|		WHEN VALUE(Catalog.Persons.EmptyRef)
	|			THEN Table.Individual
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE Table.DimensionOfExpenses
	|	END AS AutoExpenseAnalytics,
	|	Table.AssetsLiabilitiesDimension,
	|	CASE Table.AssetsLiabilitiesDimension
	|		WHEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Table.Department
	|		WHEN VALUE(Catalog.Persons.EmptyRef)
	|			THEN Table.Individual
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE Table.AssetsLiabilitiesDimension
	|	END AS AutoAnalyticsOfAssetsLiabilities,
	|	Table.GLAccountSettings,
	|	Table.LineOfBusiness,
	|	Table.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordTaxesContributionsFromSalary) AS BusinessTransactionSetting,
	|	CAST(Table.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(Table.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	Table.Sum
	|INTO TTTaxesOrganizationFees
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5.PayrollTaxes AS Table
	|	INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON Table.Ref = DocumentsToBeReflected.Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
	TableName = "TTTaxesEmployeeContributions";
	
	QueryText =
	"SELECT
	|	Table.Ref,
	|	&Organization AS Organization,
	|	Table.LineNumber,
	|	Table.Department,
	|	CASE
	|		WHEN &AccrualsAndTaxesDetailedByPersons THEN Table.Individual
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|	END AS Individual,
	|	Table.TaxKind,
	|	Table.ARAPType,
	|	Table.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PersonalIncomeTaxRecord) AS BusinessTransactionSetting,
	|	CAST(Table.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(Table.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	Table.Sum
	|INTO TTTaxesEmployeeContributions
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5.DutiesOfTaxAgent AS Table
	|	INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON Table.Ref = DocumentsToBeReflected.Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
	TableName = "TTHold";
	
	QueryText =
	"SELECT
	|	Table.Ref,
	|	&Organization AS Organization,
	|	Table.LineNumber,
	|	Table.Department,
	|	Table.Individual,
	|	Table.ARAPType,
	|	Table.DeductionKind,
	|	Table.PostingOption,
	|	Table.Counterparty,
	|	Table.IssuancePurpose,
	|	Table.IncomeItem,
	|	Table.DimensionOfRevenue,
	|	CASE Table.DimensionOfRevenue
	|		WHEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Table.Department
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE Table.DimensionOfRevenue
	|	END AS AutoRevenueAnalytics,
	|	Table.AssetsLiabilitiesDimension,
	|	CASE Table.AssetsLiabilitiesDimension
	|		WHEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Table.Department
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE Table.AssetsLiabilitiesDimension
	|	END AS AutoAnalyticsOfAssetsLiabilities,
	|	Table.GLAccountSettings,
	|	Table.ARAPObject,
	|	Table.LineOfBusiness,
	|	Table.RowID AS FinRecordID,
	|	CASE
	|		WHEN Table.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.PayOffAdvanceHolderAccountsPayable)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DeductionOfNonSpentImprest)
	|		WHEN Table.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.PayOffAccountsPayable)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DeductionFromAnEmployeeSalaryAgainstSale)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.DeductionFromAnEmployeeSalary)
	|	END AS BusinessTransactionSetting,
	|	CAST(Table.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(Table.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	Table.Sum
	|INTO TTHold
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5.Deductions AS Table
	|	INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON Table.Ref = DocumentsToBeReflected.Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTOtherExpenses_(QueryTexts)
	
	TableName = "TTOtherExpenses_";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,	
	|	TTAccruals.Department AS Department,
	|	TTAccruals.LineOfBusiness AS LineOfBusiness,
	|	TTAccruals.ExpenseItem AS ExpenseItem,
	|	TTAccruals.AutoExpenseAnalytics AS DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|	SUM(TTAccruals.SumMan) AS AmountIncludingVAT,
	|	SUM(TTAccruals.SumMan) AS AmountExcludingVAT,
	|	SUM(TTAccruals.SumMan) AS AmountExcludingVATMan,
	|	SUM(TTAccruals.SumCompl) AS AmountIncludingVATCompl,
	|	SUM(TTAccruals.SumCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	TTAccruals.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTAccruals AS TTAccruals
	|
	|WHERE
	|	TTAccruals.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses)
	|	AND TTAccruals.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND TTAccruals.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	
	|GROUP BY
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.ExpenseItem,
	|	TTAccruals.AutoExpenseAnalytics,
	|	TTAccruals.FinRecordID,
	|	TTAccruals.BusinessTransactionSetting
	|
	|UNION ALL
	|	
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,	
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.AutoExpenseAnalytics,
	|	UNDEFINED,
	|	SUM(TTTaxesOrganizationFees.SumMan),
	|	SUM(TTTaxesOrganizationFees.SumMan),
	|	SUM(TTTaxesOrganizationFees.SumMan),
	|	SUM(TTTaxesOrganizationFees.SumCompl),
	|	SUM(TTTaxesOrganizationFees.SumCompl),
	|	0,
	|	0,
	|	UNDEFINED,
	|	UNDEFINED,
	|	
	|	TTTaxesOrganizationFees.FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting
	|
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses)
	|	AND TTTaxesOrganizationFees.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND TTTaxesOrganizationFees.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|GROUP BY
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.AutoExpenseAnalytics,
	|	TTTaxesOrganizationFees.FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting";
	
	QueryTexts.Add(QueryText, "TTInitialOtherExpenses");
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableOtherExpenses(QueryTexts, Registers)
	
	TableName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOtherExpenses_(QueryTexts);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, TableName, True);
	
EndProcedure

Procedure QueryTextTableTTLotsOfOtherExpenses(QueryTexts)
	
	TableName = "TTLotsOfOtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTAccruals.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	TTAccruals.ExpenseItem AS ExpenseItem,
	|	TTAccruals.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	TTAccruals.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	SUM(TTAccruals.SumMan) AS Cost,
	|	SUM(TTAccruals.SumMan) AS CostExcludingVAT,
	|	0 AS VATManag,
	|	SUM(TTAccruals.SumCompl) AS LocalCost,
	|	0 AS CostTD,
	|	0 AS PermanentDifference,
	|	0 AS VATLocal,
	|	UNDEFINED AS BusinessOperation,
	|	
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	TTAccruals.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses)
	|	AND TTAccruals.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND TTAccruals.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|GROUP BY
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.ExpenseItem,
	|	TTAccruals.DimensionOfExpenses,
	|	TTAccruals.FinRecordID,
	|	TTAccruals.BusinessTransactionSetting
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTTaxesOrganizationFees.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	TTTaxesOrganizationFees.ExpenseItem AS ExpenseItem,
	|	TTTaxesOrganizationFees.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	TTTaxesOrganizationFees.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|
	|	SUM(TTTaxesOrganizationFees.SumMan) AS Cost,
	|	SUM(TTTaxesOrganizationFees.SumMan) AS CostExcludingVAT,
	|	0 AS VATManag,
	|	SUM(TTTaxesOrganizationFees.SumCompl) AS LocalCost,
	|	0 AS CostTD,
	|	0 AS PermanentDifference,
	|	0 AS VATLocal,
	|	UNDEFINED AS BusinessOperation,
	|	
	|	TTTaxesOrganizationFees.FinRecordID AS FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses)
	|	AND TTTaxesOrganizationFees.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND TTTaxesOrganizationFees.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|GROUP BY
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.DimensionOfExpenses,
	|	TTTaxesOrganizationFees.FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting";
	
	QueryTexts.Add(QueryText, "TTInitialBatchesOfOtherExpenses");
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableItemisedExpensesLots(QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTLotsOfOtherExpenses(QueryTexts);
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherAssetsLiabilities(QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	// Salary payable on liabilities
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(TTAccruals.SumMan) AS Sum
	|FROM
	|	TTAccruals AS TTAccruals
	|HAVING
	|	SUM(TTAccruals.SumMan) <> 0
	|
	|UNION ALL
	|
	// Taxes, contributions from salaries to be transferred to liabilities
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes),
	|	TTTaxesOrganizationFees.TaxKind AS Dimension,
	|	SUM(TTTaxesOrganizationFees.SumMan) AS Sum
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|GROUP BY
	|	TTTaxesOrganizationFees.TaxKind
	|HAVING
	|	SUM(TTTaxesOrganizationFees.SumMan) <> 0
	|
	|UNION ALL
	|
	// Salary, taxes and contributions to other assets/liabilities
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Organization,
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.ExpenseItem,
	|	TTAccruals.AutoAnalyticsOfAssetsLiabilities,
	|	SUM(TTAccruals.SumMan)
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTAccruals.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTAccruals.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|
	|GROUP BY
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.ExpenseItem,
	|	TTAccruals.AutoAnalyticsOfAssetsLiabilities
	|
	|HAVING
	|	SUM(TTAccruals.SumMan) <> 0
	|
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Organization,
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.AutoAnalyticsOfAssetsLiabilities,
	|	SUM(TTTaxesOrganizationFees.SumMan)
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTTaxesOrganizationFees.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTTaxesOrganizationFees.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|
	|GROUP BY
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.AutoAnalyticsOfAssetsLiabilities
	|
	|HAVING
	|	SUM(TTTaxesOrganizationFees.SumMan) <> 0
	|
	|UNION ALL
	|
	// We reduce the amount of remuneration by the amount of deductions
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll),
	|	UNDEFINED,
	|	SUM(TTHold.SumMan)
	|FROM
	|	TTHold AS TTHold
	|HAVING
	|	SUM(TTHold.SumMan) <> 0
	|
	|UNION ALL
	|
	// We reduce the amount of remuneration by the amount of taxes withheld from employees
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll),
	|	UNDEFINED,
	|	SUM(TTTaxesEmployeeContributions.SumMan)
	|FROM
	|	TTTaxesEmployeeContributions AS TTTaxesEmployeeContributions
	|HAVING
	|	SUM(TTTaxesEmployeeContributions.SumMan) <> 0
	|
	|UNION ALL
	|
	// Deductions for other assets/liabilities
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Organization,
	|	TTHold.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	TTHold.IncomeItem,
	|	TTHold.AutoAnalyticsOfAssetsLiabilities,
	|	SUM(TTHold.SumMan)
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTHold.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTHold.IncomeItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|
	|GROUP BY
	|	TTHold.Department,
	|	TTHold.IncomeItem,
	|	TTHold.AutoAnalyticsOfAssetsLiabilities
	|
	|HAVING
	|	SUM(TTHold.SumMan) <> 0
	|
	|UNION ALL
	|
	// PersonalIncomeTax
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes),
	|	UNDEFINED,
	|	SUM(TTTaxesEmployeeContributions.SumMan)
	|FROM
	|	TTTaxesEmployeeContributions AS TTTaxesEmployeeContributions
	|HAVING
	|	SUM(TTTaxesEmployeeContributions.SumMan) <> 0";
	
	QueryText = QueryText + Chars.LF + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	// Salary payable on liabilities
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTAccruals.Department AS Department,
	|	TTAccruals.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	|	CASE
	|		WHEN &PayrollAnalytics = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN TTAccruals.Department
	|		WHEN &PayrollAnalytics = VALUE(Catalog.Persons.EmptyRef)
	|			THEN TTAccruals.Individual
	|		WHEN &PayrollAnalytics = VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE UNDEFINED
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTAccruals.SumCompl AS SumCompl,
	|	TTAccruals.SumMan AS SumMan,
	|	TTAccruals.SumMan AS AmountIncludingVAT,
	|	TTAccruals.SumMan AS AmountExcludingVAT,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	TTAccruals.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	(TTAccruals.SumMan <> 0 OR TTAccruals.SumCompl <> 0)
	//++ WE
	|	AND NOT &PayrollAndPersonnelUsageModeIsEnabledWE
	//-- WE
	|
	|UNION ALL
	|
	// Taxes, contributions from salaries to be transferred to liabilities
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTTaxesOrganizationFees.Department AS Department,
	|	TTTaxesOrganizationFees.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
	|	TTTaxesOrganizationFees.TaxKind AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTTaxesOrganizationFees.SumCompl AS SumCompl,
	|	TTTaxesOrganizationFees.SumMan AS SumMan,
	|	TTTaxesOrganizationFees.SumMan AS AmountIncludingVAT,
	|	TTTaxesOrganizationFees.SumMan AS AmountExcludingVAT,
	|
	|	TTTaxesOrganizationFees.FinRecordID AS FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.SumMan <> 0 OR TTTaxesOrganizationFees.SumCompl <> 0
	|
	|UNION ALL
	|
	// Salary, taxes and contributions to other assets/liabilities
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTAccruals.Department AS Department,
	|	TTAccruals.LineOfBusiness AS LineOfBusiness,
	|	TTAccruals.ExpenseItem AS AssetRef,
	|	TTAccruals.AutoAnalyticsOfAssetsLiabilities AS Dimension,
	|	TTAccruals.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTAccruals.SumCompl AS SumCompl,
	|	TTAccruals.SumMan AS SumMan,
	|	TTAccruals.SumMan AS AmountIncludingVAT,
	|	TTAccruals.SumMan AS AmountExcludingVAT,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	TTAccruals.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTAccruals.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTAccruals.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND (TTAccruals.SumMan <> 0 OR TTAccruals.SumCompl <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTTaxesOrganizationFees.Department AS Department,
	|	TTTaxesOrganizationFees.LineOfBusiness AS LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem AS AssetRef,
	|	TTTaxesOrganizationFees.AutoAnalyticsOfAssetsLiabilities AS Dimension,
	|	TTTaxesOrganizationFees.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTTaxesOrganizationFees.SumCompl AS SumCompl,
	|	TTTaxesOrganizationFees.SumMan AS SumMan,
	|	TTTaxesOrganizationFees.SumMan AS AmountIncludingVAT,
	|	TTTaxesOrganizationFees.SumMan AS AmountExcludingVAT,
	|
	|	TTTaxesOrganizationFees.FinRecordID AS FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting BusinessTransactionSetting
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTTaxesOrganizationFees.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTTaxesOrganizationFees.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND (TTTaxesOrganizationFees.SumMan <> 0 OR TTTaxesOrganizationFees.SumCompl <> 0)
	|
	|UNION ALL
	|
	// We reduce the amount of remuneration by the amount of deductions
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTHold.Department AS Department,
	|	TTHold.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	|	CASE
	|		WHEN &PayrollAnalytics = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN TTHold.Department
	|		WHEN &PayrollAnalytics = VALUE(Catalog.Persons.EmptyRef)
	|			THEN TTHold.Individual
	|		WHEN &PayrollAnalytics = VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE UNDEFINED
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTHold.SumCompl AS SumCompl,
	|	TTHold.SumMan AS SumMan,
	|	TTHold.SumMan AS AmountIncludingVAT,
	|	TTHold.SumMan AS AmountExcludingVAT,
	|
	|	TTHold.FinRecordID AS FinRecordID,
	|	TTHold.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	(TTHold.SumMan <> 0 OR TTHold.SumCompl <> 0)
	//++ WE
	|	AND NOT &PayrollAndPersonnelUsageModeIsEnabledWE
	//-- WE
	|
	|UNION ALL
	|
	// We reduce the amount of remuneration by the amount of taxes withheld from employees
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTTaxesEmployeeContributions.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	|	CASE
	|		WHEN &PayrollAnalytics = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN TTTaxesEmployeeContributions.Department
	|		WHEN &PayrollAnalytics = VALUE(Catalog.Persons.EmptyRef)
	|			THEN TTTaxesEmployeeContributions.Individual
	|		WHEN &PayrollAnalytics = VALUE(Catalog.Companies.EmptyRef)
	|			THEN &Organization
	|		ELSE UNDEFINED
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTTaxesEmployeeContributions.SumCompl AS SumCompl,
	|	TTTaxesEmployeeContributions.SumMan AS SumMan,
	|	TTTaxesEmployeeContributions.SumMan AS AmountIncludingVAT,
	|	TTTaxesEmployeeContributions.SumMan AS AmountExcludingVAT,
	|
	|	TTTaxesEmployeeContributions.FinRecordID AS FinRecordID,
	|	TTTaxesEmployeeContributions.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTaxesEmployeeContributions AS TTTaxesEmployeeContributions
	|WHERE
	|	(TTTaxesEmployeeContributions.SumMan <> 0 OR TTTaxesEmployeeContributions.SumCompl <> 0)
	//++ WE
	|	AND NOT &PayrollAndPersonnelUsageModeIsEnabledWE
	//-- WE
	|
	|UNION ALL
	|
	// Deductions for other assets/liabilities
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTHold.Department AS Department,
	|	TTHold.LineOfBusiness AS LineOfBusiness,
	|	TTHold.IncomeItem AS AssetRef,
	|	TTHold.AutoAnalyticsOfAssetsLiabilities AS Dimension,
	|	TTHold.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTHold.SumCompl AS SumCompl,
	|	TTHold.SumMan AS SumMan,
	|	TTHold.SumMan AS AmountIncludingVAT,
	|	TTHold.SumMan AS AmountExcludingVAT,
	|
	|	TTHold.FinRecordID AS FinRecordID,
	|	TTHold.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTHold.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTHold.IncomeItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND (TTHold.SumMan <> 0 OR TTHold.SumCompl <> 0)
	|
	|UNION ALL
	|
	// PersonalIncomeTax
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTTaxesEmployeeContributions.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
	|	TTTaxesEmployeeContributions.TaxKind AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTTaxesEmployeeContributions.SumCompl AS SumCompl,
	|	TTTaxesEmployeeContributions.SumMan AS SumMan,
	|	TTTaxesEmployeeContributions.SumMan AS AmountIncludingVAT,
	|	TTTaxesEmployeeContributions.SumMan AS AmountExcludingVAT,
	|
	|	TTTaxesEmployeeContributions.FinRecordID AS FinRecordID,
	|	TTTaxesEmployeeContributions.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTaxesEmployeeContributions AS TTTaxesEmployeeContributions
	|WHERE
	|	TTTaxesEmployeeContributions.SumMan <> 0 OR TTTaxesEmployeeContributions.SumCompl <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

//++ WE
Procedure QueryTextTablePayrollCalculations(QueryTexts, Registers)
	
	RegisterName = "PayrollCalculationsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	// Accrued payroll
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTAccruals.Department AS Department,
	|	TTAccruals.LineOfBusiness AS LineOfBusiness,
	|	TTAccruals.ARAPType AS ARAPType,
	|	TTAccruals.SumCompl AS SumCompl,
	|	TTAccruals.SumMan  AS SumMan,
	|	TTAccruals.Sum     AS Sum,
	|	TTAccruals.Individual AS Individual,
	|	TTAccruals.Employee AS Employee,
	|	VALUE(Enum.BusinessTransactions.WageRecord) AS BusinessOperation,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	TTAccruals.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	(TTAccruals.SumMan <> 0 OR TTAccruals.SumCompl <> 0)
	|	AND &PayrollAndPersonnelUsageModeIsEnabledWE
	|
	|UNION ALL
	// Taxes withheld from employees correspond to the article assets \ liabilities remuneration
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTTaxesEmployeeContributions.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	TTTaxesEmployeeContributions.ARAPType AS ARAPType,
	|
	|	TTTaxesEmployeeContributions.SumCompl AS SumCompl,
	|	TTTaxesEmployeeContributions.SumMan  AS SumMan,
	|	TTTaxesEmployeeContributions.Sum     AS Sum,
	|	TTTaxesEmployeeContributions.Individual AS Individual,
	|	UNDEFINED,
	|	VALUE(Enum.BusinessTransactions.WageRecord) AS BusinessOperation,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	TTTaxesEmployeeContributions.FinRecordID AS FinRecordID,
	|	TTTaxesEmployeeContributions.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTaxesEmployeeContributions AS TTTaxesEmployeeContributions
	|WHERE
	|	(TTTaxesEmployeeContributions.SumMan <> 0 OR TTTaxesEmployeeContributions.SumCompl <> 0)
	|	AND &PayrollAndPersonnelUsageModeIsEnabledWE
	|
	|UNION ALL
	|
	// Deductions due to PO
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TTHold.Department AS Department,
	|	TTHold.LineOfBusiness AS LineOfBusiness,
	|	TTHold.ARAPType AS ARAPType,
	|
	|	TTHold.SumCompl AS SumCompl,
	|	TTHold.SumMan  AS SumMan,
	|	TTHold.Sum     AS Sum,
	|	TTHold.Individual AS Individual,
	|	UNDEFINED,
	|	VALUE(Enum.BusinessTransactions.WageRecord) AS BusinessOperation,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	TTHold.FinRecordID AS FinRecordID,
	|	TTHold.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	(TTHold.SumMan <> 0 OR TTHold.SumCompl <> 0)
	|	AND &PayrollAndPersonnelUsageModeIsEnabledWE
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure	
//-- WE

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	// Accrued salary for expenses
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.WageRecord) AS BusinessOperation,
	|	&Organization AS Organization,

	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	|	UNDEFINED                                      AS DimensionOfRevenue,
	|	UNDEFINED                                      AS DimensionOfExpenses,
	|	UNDEFINED                                      AS AssetsLiabilitiesDimension,
	|	TTAccruals.Department                        AS DebitBusinessUnit,
	|	TTAccruals.LineOfBusiness              AS CorLineOfBusiness,
	|	TTAccruals.ExpenseItem                       AS CorItem,
	|	UNDEFINED                                      AS CorIncomeDimension,
	|	TTAccruals.AutoExpenseAnalytics                AS CorExpenditureDimension,
	|	UNDEFINED                                      AS CorDimensionOfAssetsLiabilities,

	|	SUM(TTAccruals.SumMan) AS Sum,
	|	SUM(TTAccruals.SumMan) AS SumMan,
	|	SUM(TTAccruals.SumCompl) AS SumCompl,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|	
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses)
	|	AND TTAccruals.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND TTAccruals.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|GROUP BY
	|	TTAccruals.Department,
	|	TTAccruals.ExpenseItem,
	|	TTAccruals.AutoExpenseAnalytics,
	|	TTAccruals.LineOfBusiness
	|
	|UNION ALL
	|
	// Taxes, contributions of the organization for expenses
	|SELECT
	|	&Period,
	|	VALUE(Enum.BusinessTransactions.RecordTaxesContributionsFromSalary),
	|	&Organization,

	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes),
	|	UNDEFINED                                      AS DimensionOfRevenue,
	|	UNDEFINED                                      AS DimensionOfExpenses,
	|	TTTaxesOrganizationFees.TaxKind               AS AssetsLiabilitiesDimension,
	|	TTTaxesOrganizationFees.Department           AS DebitBusinessUnit,
	|	TTTaxesOrganizationFees.LineOfBusiness AS CorLineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem          AS CorItem,
	|	UNDEFINED                                      AS CorIncomeDimension,
	|	TTTaxesOrganizationFees.AutoExpenseAnalytics   AS CorExpenditureDimension,
	|	UNDEFINED                                      AS CorDimensionOfAssetsLiabilities,

	|	SUM(TTTaxesOrganizationFees.SumMan) AS Sum,
	|	SUM(TTTaxesOrganizationFees.SumMan) AS SumMan,
	|	SUM(TTTaxesOrganizationFees.SumCompl) AS SumCompl,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|	
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses)
	|	AND TTTaxesOrganizationFees.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND TTTaxesOrganizationFees.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|GROUP BY
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.AutoExpenseAnalytics,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.TaxKind
	|
	|UNION ALL
	|
	// Accrued salary for other assets/liabilities
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.WageRecord),
	|	&Organization AS Organization,

	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll),
	|	UNDEFINED                                           AS DimensionOfRevenue,
	|	UNDEFINED                                           AS DimensionOfExpenses,
	|	UNDEFINED                                           AS AssetsLiabilitiesDimension,

	|	TTAccruals.Department                                AS DebitBusinessUnit,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	TTAccruals.ExpenseItem                               AS CorItem,
	|	UNDEFINED                                              AS CorIncomeDimension,
	|	UNDEFINED                                              AS CorExpenditureDimension,
	|	TTAccruals.AutoAnalyticsOfAssetsLiabilities                 AS CorDimensionOfAssetsLiabilities,

	|	SUM(TTAccruals.SumMan) AS Sum,
	|	SUM(TTAccruals.SumMan) AS SumMan,
	|	SUM(TTAccruals.Sum) AS SumCompl,
	|	
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTAccruals.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTAccruals.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|
	|GROUP BY
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.ExpenseItem,
	|	TTAccruals.AutoAnalyticsOfAssetsLiabilities
	|
	|UNION ALL
	|
	// Taxes, contributions of the organization to other assets/liabilities
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordTaxesContributionsFromSalary),
	|	&Organization AS Organization,

	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes),
	|	UNDEFINED                                           AS DimensionOfRevenue,
	|	UNDEFINED                                           AS DimensionOfExpenses,
	|	TTTaxesOrganizationFees.TaxKind                    AS AssetsLiabilitiesDimension,

	|	TTTaxesOrganizationFees.Department                   AS DebitBusinessUnit,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem                  AS CorItem,
	|	UNDEFINED                                              AS CorIncomeDimension,
	|	UNDEFINED                                              AS CorExpenditureDimension,
	|	TTTaxesOrganizationFees.AutoAnalyticsOfAssetsLiabilities    AS CorDimensionOfAssetsLiabilities,

	|	SUM(TTTaxesOrganizationFees.SumMan) AS Sum,
	|	SUM(TTTaxesOrganizationFees.SumMan) AS SumMan,
	|	SUM(TTTaxesOrganizationFees.SumCompl) AS SumCompl,
	|	
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTTaxesOrganizationFees.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTTaxesOrganizationFees.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|
	|GROUP BY
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.ExpenseItem,
	|	TTTaxesOrganizationFees.AutoAnalyticsOfAssetsLiabilities,
	|	TTTaxesOrganizationFees.TaxKind
	|
	|UNION ALL
	|
	// Deductions for other assets/liabilities
	|SELECT
	|	&Period,
	|	VALUE(Enum.BusinessTransactions.DeductionFromAnEmployeeSalary),
	|	&Organization,
	
	|	TTHold.Department,
	|	TTHold.LineOfBusiness,
	|	TTHold.IncomeItem,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTHold.AssetsLiabilitiesDimension,
	
	|	VALUE(Catalog.BusinessStructure.EmptyRef)    AS DebitBusinessUnit,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS CorItem,
	|	UNDEFINED                                   AS CorIncomeDimension,
	|	UNDEFINED                                   AS CorExpenditureDimension,
	|	UNDEFINED                                   AS CorDimensionOfAssetsLiabilities,
	
	|	SUM(TTHold.SumMan) AS Sum,
	|	SUM(TTHold.SumMan) AS SumMan,
	|	SUM(TTHold.SumCompl) AS SumCompl,
	|	
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities)
	|	AND TTHold.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND TTHold.IncomeItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|
	|GROUP BY
	|	TTHold.Department,
	|	TTHold.LineOfBusiness,
	|	TTHold.IncomeItem,
	|	TTHold.AssetsLiabilitiesDimension
	|
	|UNION ALL
	|
	// Deductions from salary for other income
	|SELECT
	|	&Period,
	|	VALUE(Enum.BusinessTransactions.DeductionFromAnEmployeeSalary),
	|	&Organization,
	
	|	TTHold.Department,
	|	TTHold.LineOfBusiness,
	|	TTHold.IncomeItem,
	|	TTHold.AutoRevenueAnalytics,
	|	UNDEFINED                                  AS DimensionOfExpenses,
	|	UNDEFINED                                  AS AssetsLiabilitiesDimension,

	|	VALUE(Catalog.BusinessStructure.EmptyRef)    AS DebitBusinessUnit,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS CorItem,
	|	UNDEFINED                                  AS CorIncomeDimension,
	|	UNDEFINED                                  AS CorExpenditureDimension,
	|	UNDEFINED                                  AS CorDimensionOfAssetsLiabilities,
	
	|	SUM(TTHold.SumMan) AS Sum,
	|	SUM(TTHold.SumMan) AS SumMan,
	|	SUM(TTHold.SumCompl) AS SumCompl,
	|	
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome)
	|	AND TTHold.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
	|	AND TTHold.IncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|
	|GROUP BY
	|	TTHold.Department,
	|	TTHold.LineOfBusiness,
	|	TTHold.IncomeItem,
	|	TTHold.AutoRevenueAnalytics
	|
	// Taxes withheld from employees correspond to the article assets \ liabilities remuneration
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(Enum.BusinessTransactions.RecordTaxesContributionsFromSalary),
	|	&Organization,

	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes),
	|	UNDEFINED                                      AS DimensionOfRevenue,
	|	UNDEFINED                                      AS DimensionOfExpenses,
	|	UNDEFINED                                      AS AssetsLiabilitiesDimension,

	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll),
	|	UNDEFINED                                      AS CorIncomeDimension,
	|	UNDEFINED                                      AS CorExpenditureDimension,
	|	UNDEFINED                                      AS CorDimensionOfAssetsLiabilities,

	|	SUM(TTTaxesEmployeeContributions.SumMan) AS Sum,
	|	SUM(TTTaxesEmployeeContributions.SumMan) AS SumMan,
	|	SUM(TTTaxesEmployeeContributions.SumCompl) AS SumCompl,
	|	
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS AmountInCurrency
	|
	|FROM
	|	TTTaxesEmployeeContributions AS TTTaxesEmployeeContributions
	|HAVING
	|	SUM(TTTaxesEmployeeContributions.SumCompl) <> 0
	|	AND SUM(TTTaxesEmployeeContributions.SumMan) <> 0";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableRecordsCashIncomeExpenses(QueryTexts, Registers)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DeductionOfNonSpentImprest) AS BusinessOperation,
	|	&Organization AS Organization,
	|	TTHold.Department AS Department,
	|
	|	TTHold.Individual AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	UNDEFINED AS CashFlowItem,
	|	&LocalAccountingCurrency AS Currency,
	|
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|
	|	TTHold.SumMan  AS Sum,
	|	TTHold.SumCompl AS SumCompl,
	|	TTHold.Sum     AS AmountInCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup
	|FROM
	|	TTHold AS TTHold
	|	
	|WHERE
	|	TTHold.PostingOption =
	|		VALUE(Enum.AccrualsDeductionsRecordOptions.PayOffAdvanceHolderAccountsPayable)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsCounterpartyIncomeExpenses(QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DeductionFromAnEmployeeSalaryAgainstSale) AS BusinessOperation,
	|	&Organization AS Organization,
	|	TTHold.Department AS Department,
	|	TTHold.ARAPObject.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	TTHold.ARAPObject.Partner AS Partner,
	|	TTHold.ARAPObject.Counterparty AS Counterparty,
	|	TTHold.ARAPObject.Contract AS Contract,
	|	TTHold.ARAPObject AS ARAPObject,
	|	
	|	TTHold.LineOfBusiness AS LineOfBusinessItems,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	TTHold.SumMan AS Sum,
	|	0 AS AmountExcludingVAT,
	|	TTHold.SumCompl AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,

	|	TTHold.Ref.Currency AS Currency,
	|	TTHold.Sum AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,

	|	TTHold.Ref.Currency AS ARAPCurrency,
	|	TTHold.Sum AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	TTHold.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TTHold.FinRecordID AS FinRecordID
	|FROM
	|	TTHold AS TTHold
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.PayOffAccountsPayable)";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherIncome(QueryTexts, Registers)
	
	TableName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,	
	|	TTHold.Department AS Department,
	|	TTHold.IncomeItem AS IncomeItem,
	|	TTHold.AutoRevenueAnalytics AS DimensionOfRevenue,
	|	SUM(TTHold.Sum * &ConversionRateToManCurrency) AS Sum,
	|	SUM(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN TTHold.SumMan
	|		ELSE 0 END) AS SumMan,
	|	SUM(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN TTHold.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	UNDEFINED AS BusinessOperation,
	|	
	|	TTHold.FinRecordID AS FinRecordID,
	|	TTHold.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTHold AS TTHold
	|
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome)
	|	AND TTHold.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
	|	AND TTHold.IncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|
	|GROUP BY
	|	TTHold.IncomeItem,
	|	TTHold.AutoRevenueAnalytics,
	|	TTHold.Department,
	|	TTHold.FinRecordID,
	|	TTHold.BusinessTransactionSetting";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableAdvanceHolderCash(QueryTexts, Registers)
	
	TableName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	TTHold.Individual AS AdvanceHolder,
	|	TTHold.Department AS Department,
	|	&LocalAccountingCurrency AS Currency,
	|
	|	TTHold.IssuancePurpose AS IssuancePurpose,
	|	
	|	TTHold.SumCompl AS Sum,
	|	TTHold.SumCompl AS SumCompl,
	|	TTHold.SumMan AS SumMan,
	|	TTHold.SumCompl AS ToReport,
	|	
	|	VALUE(Enum.BusinessTransactions.DeductionOfNonSpentImprest) AS BusinessOperation,
	|	
	|	TTHold.FinRecordID AS FinRecordID,
	|	TTHold.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	TTHold AS TTHold
	|	
	|WHERE
	|	TTHold.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.PayOffAdvanceHolderAccountsPayable)";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTTTableEmployeeOutput(QueryTexts)
	
	TableName = "TTTableEmployeeOutput";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	Table.Period,
	|	Table.Organization,
	|	Table.Department,
	
	|	Table.ProductionLot,
	|	Table.ProductionOrder,
	|	Table.RowCodeProducts,
	|	Table.WorkKind,
	|	Table.ProductsGroup,
	|	Table.Stage,
	
	|	Table.ProductCostElement,
	|	Table.Employee,
	
	|	Table.LocalCost,
	|	Table.Cost,

	|	Table.FinRecordID,
	|	Table.BusinessTransactionSetting
	
	|INTO TTTableEmployeeOutput
	|FROM
	|	&TableEmployeeDevelopment AS Table";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableWIPLaborCosts(QueryTexts, Registers)
	
	TableName = "WIPLaborCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTTTableEmployeeOutput(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Organization                              AS Organization,
	|	WorkOutput.Department        AS Department,
	|	WorkOutput.ProductionLot   AS ProductionLot,
	|	WorkOutput.ProductionOrder  AS ProductionOrder,
	|	WorkOutput.RowCodeProducts   AS RowCodeProducts,
	|	WorkOutput.Stage                 AS Stage,
	|	WorkOutput.ProductCostElement    AS ProductCostElement,
	|	WorkOutput.WorkKind             AS WorkKind,
	|	WorkOutput.ProductsGroup      AS ProductsGroup,
	|	SUM(WorkOutput.Cost)     AS Cost,
	|	SUM(WorkOutput.LocalCost) AS LocalCost,
	|	
	|	WorkOutput.FinRecordID AS FinRecordID,
	|	WorkOutput.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTableEmployeeOutput AS WorkOutput
	|
	|GROUP BY
	|	WorkOutput.Department,
	|	WorkOutput.ProductionLot,
	|	WorkOutput.ProductionOrder,
	|	WorkOutput.RowCodeProducts,
	|	WorkOutput.Stage,
	|	WorkOutput.ProductCostElement,
	|	WorkOutput.WorkKind,
	|	WorkOutput.ProductsGroup,
	|	WorkOutput.FinRecordID,
	|	WorkOutput.BusinessTransactionSetting";
	
	QueryTexts.Add(QueryText, TableName, True);
	
EndProcedure

#Region DistributionOfProductionCosts

Function DistributeChargesByStagesOfProduction(QueryOptions)
	
	Query = New Query;
	Query.SetParameter("Ref", QueryOptions.Ref);
	Query.SetParameter("Organization", QueryOptions.Organization);
	Query.SetParameter("StartDate",    QueryOptions.StartDate);
	Query.SetParameter("EndDate", QueryOptions.EndDate);
	Query.SetParameter("AccrualsAndTaxesDetailedByPersons", QueryOptions.AccrualsAndTaxesDetailedByPersons);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", QueryOptions.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency",  QueryOptions.ConversionRateToManCurrency);
	
	QueryTexts = New ValueList;
	QueryTextDocumentTables(QueryTexts);
	
	RequestTextCostsAllocatedForProduction(QueryTexts);
	ExpenseTableIndex = QueryTexts.Count() - 1;
	
	RequestTextTableOfEmployees(QueryTexts);
	IndexOfOutputTable = QueryTexts.Count() - 1;
	
	Query.Text = StrConcat(QueryTexts.UnloadValues(), Common.QueryBatchSeparator());
	
	Result = Query.ExecuteBatch();
	DistributableExpenses = Result[ExpenseTableIndex].Unload();
	ProductionOutputTable = Result[IndexOfOutputTable].Unload();
	
	DistributionTable_1 = NewEmployeeDevelopmentTable();
	
	FilterStructure1 = New Structure("Organization, Department, Individual");
	
	For Each DistributableString In DistributableExpenses Do
		
		FillPropertyValues(FilterStructure1, DistributableString);
		AllocationBase = ProductionOutputTable.FindRows(FilterStructure1);
		
		If DistributableString.AllocationBaseType = Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel Then
			DistributionCoefficients = GetDistributionCoefficients_WageStandards(AllocationBase);
		ElsIf DistributableString.AllocationBaseType = Enums.TypesOfCostAllocatingBase.WorkPerformanceDuration Then
			DistributionCoefficients = GetDistributionCoefficients_DurationOfWork(AllocationBase);
		Else
			DistributionCoefficients = New Array();
		EndIf;
		
		ArrayOfLocalDistribution = TMCommonUse.DistributeSumProportionallyToCoefficientsOfDifferentSigns(
			DistributableString.SumCompl, DistributionCoefficients);
		
		If DistributableString.SumCompl = DistributableString.SumMan Then
			ManDistributionArray = ArrayOfLocalDistribution;
		Else
			ManDistributionArray = TMCommonUse.DistributeSumProportionallyToCoefficientsOfDifferentSigns(
				DistributableString.SumMan, DistributionCoefficients);
		EndIf;
		
		If ArrayOfLocalDistribution = Undefined Or ManDistributionArray = Undefined Then
			Continue;
		EndIf;
		
		For IndexOf = 0 To AllocationBase.UBound() Do
			
			DistributionBaseString = AllocationBase[IndexOf];
			
			NewRow = DistributionTable_1.Add();
			FillPropertyValues(NewRow, DistributionBaseString);
			
			If DistributionBaseString.RedefiningCalculationArticleIsAvailable
				And ValueIsFilled(DistributableString.ProductCostElement) Then
				NewRow.ProductCostElement = DistributableString.ProductCostElement;
			Else
				NewRow.ProductCostElement = DistributionBaseString.ArticleCalculationOfOutput;
			EndIf;
			
			NewRow.Cost     = ManDistributionArray[IndexOf];
			NewRow.LocalCost = ArrayOfLocalDistribution[IndexOf];
			NewRow.FinRecordID = DistributableString.FinRecordID;
			NewRow.BusinessTransactionSetting = DistributableString.BusinessTransactionSetting;
			
		EndDo;
		
	EndDo;
	
	Return DistributionTable_1;
	
EndFunction

Procedure RequestTextCostsAllocatedForProduction(QueryTexts)
	
	QueryText =
	"SELECT
	|	TTAccruals.Ref,
	|	TTAccruals.Organization,
	|	TTAccruals.LineNumber,
	|	TTAccruals.Department,
	|	TTAccruals.Individual,
	|	TTAccruals.AccrualKind,
	|	TTAccruals.AllocationBaseType,
	|	TTAccruals.ProductCostElement,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.FinRecordID,
	|	TTAccruals.BusinessTransactionSetting,
	|	TTAccruals.SumCompl,
	|	TTAccruals.SumMan
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.PostingOption =
	|		VALUE(Enum.AccrualsDeductionsRecordOptions.AllocateToProduction)
	|
	|UNION ALL
	|
	|SELECT
	|	TTTaxesOrganizationFees.Ref,
	|	TTTaxesOrganizationFees.Organization,
	|	TTTaxesOrganizationFees.LineNumber,
	|	TTTaxesOrganizationFees.Department,
	|	TTTaxesOrganizationFees.Individual,
	|	TTTaxesOrganizationFees.TaxKind,
	|	TTTaxesOrganizationFees.AllocationBaseType,
	|	TTTaxesOrganizationFees.ProductCostElement,
	|	TTTaxesOrganizationFees.LineOfBusiness,
	|	TTTaxesOrganizationFees.FinRecordID,
	|	TTTaxesOrganizationFees.BusinessTransactionSetting,
	|	TTTaxesOrganizationFees.SumCompl,
	|	TTTaxesOrganizationFees.SumMan
	|FROM
	|	TTTaxesOrganizationFees AS TTTaxesOrganizationFees
	|WHERE
	|	TTTaxesOrganizationFees.PostingOption =
	|		VALUE(Enum.AccrualsDeductionsRecordOptions.AllocateToProduction)";
	
	QueryTexts.Add(QueryText);
	
EndProcedure

Procedure RequestTextTableOfEmployees(QueryTexts)
	
	QueryText = "
	// We will get the periods of distribution bases by production Lot references,
	// for which there was a reversal of the s/n reflection in the current period.
	|SELECT
	|	CancelledLaborCostsOfUnfinishedProduction.Organization                    AS Organization,
	|	BatchOutput.ProductionLot                      AS ProductionLot,
	|	BEGINOFPERIOD(BatchOutput.Period, MONTH)            AS StartDate,
	|	ENDOFPERIOD(BatchOutput.Period, MONTH)             AS EndDate
	|INTO PeriodsOfBatchDistributionBaseWithReversal
	|FROM
	|	InformationRegister.DocumentsRegistry AS ReversingDocuments
	|	
	|	INNER JOIN Document.PostingPayrollExpensesInFinancialAccounting2_5 AS ReversedDocuments
	|	ON ReversedDocuments.Ref = ReversingDocuments.ReversedDocument
	|	
	|	INNER JOIN AccumulationRegister.WIPLaborCosts AS CancelledLaborCostsOfUnfinishedProduction
	|	ON CancelledLaborCostsOfUnfinishedProduction.Recorder = ReversedDocuments.Ref
	|	
	|	INNER JOIN AccumulationRegister.WIPLaborCosts AS BatchOutput
	|	ON BatchOutput.Organization = CancelledLaborCostsOfUnfinishedProduction.Organization
	|	AND BatchOutput.ProductionLot = CancelledLaborCostsOfUnfinishedProduction.ProductionLot
	|	AND BatchOutput.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT BatchOutput.StandardCost = 0
	|	AND BatchOutput.Period < &StartDate
	|
	|WHERE
	|	ReversingDocuments.Organization = &Organization
	|	AND ReversingDocuments.IBDocumentDate BETWEEN &StartDate AND &EndDate
	|	AND ReversingDocuments.ReverseTransactionCorrection
	|	AND NOT ReversingDocuments.AdditionalRecord
	|	AND ReversingDocuments.Posted
	|
	|GROUP BY
	|	CancelledLaborCostsOfUnfinishedProduction.Organization,
	|	BatchOutput.ProductionLot,
	|	BEGINOFPERIOD(BatchOutput.Period, MONTH),
	|	ENDOFPERIOD(BatchOutput.Period, MONTH)
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot
	|";
	QueryTexts.Add(QueryText, "PeriodsOfBatchDistributionBaseWithReversal");
	
	QueryText =
	"SELECT
	|	LaborCosts.Organization AS Organization,
	|	LaborCosts.Department AS Department,
	|	LaborCosts.Individual AS Individual,
	|	LaborCosts.ProductionLot AS ProductionLot,
	|	LaborCosts.ProductionOrder AS ProductionOrder,
	|	LaborCosts.LineOfBusiness AS LineOfBusiness,
	|	LaborCosts.RowCodeProducts AS RowCodeProducts,
	|	LaborCosts.Stage AS Stage,
	|	LaborCosts.WorkKind AS WorkKind,
	|	LaborCosts.ProductsGroup AS ProductsGroup,
	|	LaborCosts.ArticleCalculationOfOutput AS ArticleCalculationOfOutput,
	|	LaborCosts.SetID AS SetID,
	|	LaborCosts.ProductsAccountingDimension AS ProductsAccountingDimension,
	|	LaborCosts.RedefiningCalculationArticleIsAvailable AS RedefiningCalculationArticleIsAvailable,
	|	SUM(LaborCosts.Count) AS Count,
	|	SUM(LaborCosts.StandardCost) AS StandardCost
	|INTO TTLaborCosts
	|FROM
	|	(SELECT
	|		LaborCostsOfUnfinishedProduction.Organization,
	|		LaborCostsOfUnfinishedProduction.Department,
	|		CASE
	|			WHEN &AccrualsAndTaxesDetailedByPersons
	|				THEN LaborCostsOfUnfinishedProduction.Employee
	|			ELSE VALUE(Catalog.Persons.EmptyRef)
	|		END AS Individual,
	|		LaborCostsOfUnfinishedProduction.ProductionLot,
	|		LaborCostsOfUnfinishedProduction.ProductionOrder,
	|		CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|		LaborCostsOfUnfinishedProduction.RowCodeProducts,
	|		LaborCostsOfUnfinishedProduction.Stage,
	|		LaborCostsOfUnfinishedProduction.WorkKind,
	|		LaborCostsOfUnfinishedProduction.ProductsGroup,
	|		LaborCostsOfUnfinishedProduction.ProductCostElement AS ArticleCalculationOfOutput,
	|		LaborCostsOfUnfinishedProduction.StandardCost AS StandardCost,
	|		""WIPLaborCosts"" AS SetID,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|		LaborCostsOfUnfinishedProduction.Count,
	|		TRUE AS RedefiningCalculationArticleIsAvailable
	|	FROM
	|		AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = LaborCostsOfUnfinishedProduction.ProductionLot
	|	
	|	WHERE
	|		LaborCostsOfUnfinishedProduction.Organization = &Organization
	|		AND LaborCostsOfUnfinishedProduction.Period BETWEEN &StartDate AND &EndDate
	|		AND LaborCostsOfUnfinishedProduction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND VALUETYPE(LaborCostsOfUnfinishedProduction.Recorder) IN(
	|			TYPE(Document.WorkOutput),
	|			TYPE(Document.ReversingEntry))
	|		AND NOT LaborCostsOfUnfinishedProduction.StandardCost = 0
	|	
	|	UNION ALL
	|	
	// Let's add to the calculation the data of past periods, suspended in the current one.
	|	SELECT
	|		LaborCostsOfUnfinishedProduction.Organization,
	|		LaborCostsOfUnfinishedProduction.Department,
	|		CASE
	|			WHEN &AccrualsAndTaxesDetailedByPersons
	|				THEN LaborCostsOfUnfinishedProduction.Employee
	|			ELSE VALUE(Catalog.Persons.EmptyRef)
	|		END AS Individual,
	|		LaborCostsOfUnfinishedProduction.ProductionLot,
	|		LaborCostsOfUnfinishedProduction.ProductionOrder,
	|		CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|		LaborCostsOfUnfinishedProduction.RowCodeProducts,
	|		LaborCostsOfUnfinishedProduction.Stage,
	|		LaborCostsOfUnfinishedProduction.WorkKind,
	|		LaborCostsOfUnfinishedProduction.ProductsGroup,
	|		LaborCostsOfUnfinishedProduction.ProductCostElement AS ArticleCalculationOfOutput,
	|		LaborCostsOfUnfinishedProduction.StandardCost AS StandardCost,
	|		""WIPLaborCosts"" AS SetID,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|		LaborCostsOfUnfinishedProduction.Count,
	|		TRUE AS RedefiningCalculationArticleIsAvailable
	|	FROM
	|		PeriodsOfBatchDistributionBaseWithReversal AS DistributionBasePeriods
	|	
	|		INNER JOIN AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction
	|		ON LaborCostsOfUnfinishedProduction.Organization = DistributionBasePeriods.Organization
	|		AND LaborCostsOfUnfinishedProduction.ProductionLot = DistributionBasePeriods.ProductionLot
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = LaborCostsOfUnfinishedProduction.ProductionLot
	|	
	|	WHERE
	|		LaborCostsOfUnfinishedProduction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND LaborCostsOfUnfinishedProduction.Period BETWEEN DistributionBasePeriods.StartDate AND DistributionBasePeriods.EndDate
	|		AND VALUETYPE(LaborCostsOfUnfinishedProduction.Recorder) IN(
	|			TYPE(Document.WorkOutput),
	|			TYPE(Document.ReversingEntry))
	|		AND NOT LaborCostsOfUnfinishedProduction.StandardCost = 0
	|	) AS LaborCosts
	|
	|GROUP BY
	|	LaborCosts.Organization,
	|	LaborCosts.Department,
	|	LaborCosts.Individual,
	|	LaborCosts.ProductionLot,
	|	LaborCosts.ProductionOrder,
	|	LaborCosts.LineOfBusiness,
	|	LaborCosts.RowCodeProducts,
	|	LaborCosts.Stage,
	|	LaborCosts.WorkKind,
	|	LaborCosts.ProductsGroup,
	|	LaborCosts.ArticleCalculationOfOutput,
	|	LaborCosts.SetID,
	|	LaborCosts.ProductsAccountingDimension,
	|	LaborCosts.RedefiningCalculationArticleIsAvailable
	|";
	QueryTexts.Add(QueryText, "TTLaborCosts");
	
	QueryText =
	"SELECT
	|	TTLaborCosts.Organization,
	|	TTLaborCosts.Department,
	|	TTLaborCosts.Individual,
	|	TTLaborCosts.ProductionLot,
	|	TTLaborCosts.ProductionOrder,
	|	TTLaborCosts.LineOfBusiness,
	|	TTLaborCosts.RowCodeProducts,
	|	TTLaborCosts.Stage,
	|	TTLaborCosts.WorkKind,
	|	TTLaborCosts.ProductsGroup,
	|	TTLaborCosts.ProductsAccountingDimension,
	|	TTLaborCosts.SetID,
	|	TTLaborCosts.ArticleCalculationOfOutput,
	|	TTLaborCosts.RedefiningCalculationArticleIsAvailable,
	|	TTLaborCosts.StandardCost,
	|	TTLaborCosts.Count,
	|	ISNULL(ActivityKinds.LaborInputMultiplier, 0) AS LaborInputMultiplier,
	|	ISNULL(ActivityKinds.LaborInput, 0) AS LaborInput
	|FROM
	|	TTLaborCosts AS TTLaborCosts
	|	LEFT JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON TTLaborCosts.WorkKind = ActivityKinds.Ref";
	
	QueryTexts.Add(QueryText);
	
EndProcedure

Function NewEmployeeDevelopmentTable()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 0
	|	LaborCostsOfUnfinishedProduction.Period,
	|	LaborCostsOfUnfinishedProduction.Recorder,
	|	LaborCostsOfUnfinishedProduction.LineNumber,
	|	LaborCostsOfUnfinishedProduction.Active,
	|	LaborCostsOfUnfinishedProduction.Organization,
	|	LaborCostsOfUnfinishedProduction.Department,
	|	LaborCostsOfUnfinishedProduction.WorkKind,
	|	LaborCostsOfUnfinishedProduction.Stage,
	|	LaborCostsOfUnfinishedProduction.Employee,
	|	LaborCostsOfUnfinishedProduction.ProductsGroup,
	|	LaborCostsOfUnfinishedProduction.ProductionOrder,
	|	LaborCostsOfUnfinishedProduction.RowCodeProducts,
	|	LaborCostsOfUnfinishedProduction.ProductCostElement,
	|	LaborCostsOfUnfinishedProduction.ProductionLot,
	|	LaborCostsOfUnfinishedProduction.LocalCost,
	|	LaborCostsOfUnfinishedProduction.Cost,
	|	LaborCostsOfUnfinishedProduction.FinRecordID,
	|	LaborCostsOfUnfinishedProduction.BusinessTransactionSetting
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction";
	
	Return Query.Execute().Unload();
	
EndFunction

Function GetDistributionCoefficients_WageStandards(AllocationBase)
	
	ArrayOfCoefficients = New Array(AllocationBase.Count());
	
	For IndexOf = 0 To AllocationBase.UBound() Do
		ArrayOfCoefficients[IndexOf] = AllocationBase[IndexOf].StandardCost;
	EndDo;
	
	Return ArrayOfCoefficients;
	
EndFunction

Function GetDistributionCoefficients_DurationOfWork(AllocationBase)
	
	ArrayOfCoefficients = New Array(AllocationBase.Count());
	
	For IndexOf = 0 To AllocationBase.UBound() Do
		LaborInputMultiplier = AllocationBase[IndexOf].LaborInputMultiplier;
		LaborInput = AllocationBase[IndexOf].LaborInput;
		Count = AllocationBase[IndexOf].Count;
		If LaborInputMultiplier > 0 Then
			ZoomRatio = Count * LaborInput / LaborInputMultiplier;
		Else
			ZoomRatio = 0;
		EndIf;
		ArrayOfCoefficients[IndexOf] = ZoomRatio;
	EndDo;
	
	Return ArrayOfCoefficients;
	
EndFunction

#EndRegion

Procedure QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers)
	
	TableName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                      AS Period,
	|	&Organization                 AS Organization,
	|	BEGINOFPERIOD(&Period, DAY) AS DateRecord";
	
	QueryTexts.Add(QueryText, TableName, True);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";
	
	QueryTextDocumentExchangeRates = 
		"SELECT
		|	Deductions.Ref AS Ref,
		|	Deductions.Organization AS Organization,
		|	Deductions.Ref.Date AS DateOfCourse,
		|	Deductions.ARAPObject AS ARAPObject,
		|	Deductions.Ref.Currency AS DocumentCurrency,
		|	Deductions.Ref.Currency AS ARAPCurrency
		|FROM
		|	TTHold AS Deductions";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(
		Query, QueryTexts, Registers, QueryTextTablePaymentFromCustomer());

EndProcedure

Function QueryTextTablePaymentFromCustomer()
	
	QueryText =
	"SELECT
	|	Deductions.Ref                                 AS Ref,
	|	Deductions.Organization                            AS Organization,
	|	Deductions.ARAPObject.Partner                 AS Partner,
	|	
	|	Deductions.Ref.Currency                          AS ARAPCurrency,
	|	Deductions.ARAPObject                         AS ARAPObject,
	|	
	|	Deductions.Sum                                  AS AmountARAP,
	|	Deductions.Sum                                  AS Sum,
	|	0                                                AS IncreaseIsPaid,
	|	0                                                AS ReductionIsPaid,
	|	
	|	Deductions.Ref.Date                            AS RecorderDate,
	|	Deductions.Ref.Date                            AS DateOfCourse,
	|	DATETIME(1,1,1)                                 AS MaturityDate,
	|	Deductions.Ref.Number                           AS RecorderNumber,
	|	VALUE(Enum.BusinessTransactions.DeductionFromAnEmployeeSalaryAgainstSale) AS BusinessOperation,
	|	UNDEFINED                                     AS PaymentMethod,
	|	UNDEFINED                                     AS CashFlowItem,
	|	UNDEFINED                                     AS ProformaInvoice,
	|	Deductions.Ref.Currency                          AS DocumentCurrency,
	|	UNDEFINED                                     AS LinkedDocument,
	|	Deductions.FinRecordID                 AS FinRecordID,
	|	Deductions.BusinessTransactionSetting         AS BusinessTransactionSetting
	|FROM
	|	TTHold AS Deductions
	|WHERE
	|	Deductions.PostingOption = VALUE(Enum.AccrualsDeductionsRecordOptions.PayOffAccountsPayable)";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Date AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	UNDEFINED AS Counterparty,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	UNDEFINED AS Sum,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	&Date AS SourceDocumentDate,
	|	&Number AS SourceDocumentNumber,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Date AS RecordingInAccountingDate
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			,);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ImportDataFromFile

Function RequestTextForUploadedData(Columns)
	
	QueryText =
	"SELECT
	|	Table.Id AS Id
	|INTO DataToImport
	|FROM &DataToImport AS Table";
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	Query = QuerySchema.QueryBatch[0].Operators[0];
	For Each Column In Columns Do
		If Column.Name = "Id" Then
			Continue;
		EndIf;
		Query.SelectedFields.Add("Table." + Column.Name);
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
	Return QueryText;
	
EndFunction

Function DataMatchingRequestText(Columns)
	
	QueriesArray = New Array;
	
	If Columns.Find("UnitCode_") = Undefined Then
		QueryText =
		"SELECT TOP 0
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Ref,
		|	0 AS RowID,
		|	0 AS Priority
		|INTO UnitsMapped";
	Else
		QueryText =
		"SELECT
		|	Departments.Ref AS Ref,
		|	DataToImport.Id AS RowID,
		|	2 AS Priority
		|INTO UnitsMapped
		|FROM Catalog.BusinessStructure AS Departments
		|	INNER JOIN DataToImport AS DataToImport
		|		ON Departments.Code = DataToImport.UnitCode_
		|			AND Departments.Description = DataToImport.DivisionName_
		|
		|UNION ALL
		|
		|SELECT
		|	Departments.Ref,
		|	DataToImport.Id,
		|	1
		|FROM Catalog.BusinessStructure AS Departments
		|	INNER JOIN DataToImport AS DataToImport
		|		ON Departments.Description = DataToImport.DivisionName_
		|			AND DataToImport.UnitCode_ = """"
		|
		|INDEX BY
		|	RowID";
	EndIf;
	QueriesArray.Add(QueryText);
	
	If Columns.Find("IndividualFULLName") = Undefined Then
		QueryText =
		"SELECT TOP 0
		|	VALUE(Catalog.Persons.EmptyRef) AS Ref,
		|	0 AS RowID,
		|	0 AS Priority
		|INTO IndividualsMatched";
	Else
		QueryText =
		"SELECT
		|	Persons.Ref AS Ref,
		|	DataToImport.Id AS RowID,
		|	2 AS Priority
		|INTO IndividualsMatched
		|FROM Catalog.Persons AS Persons
		|	INNER JOIN DataToImport AS DataToImport
		|		ON Persons.Code = DataToImport.IndividualCode
		|			AND Persons.Description = DataToImport.IndividualFULLName
		|
		|UNION ALL
		|
		|SELECT
		|	Persons.Ref,
		|	DataToImport.Id,
		|	1
		|FROM Catalog.Persons AS Persons
		|	INNER JOIN DataToImport AS DataToImport
		|		ON Persons.Description = DataToImport.IndividualFULLName
		|			AND DataToImport.IndividualCode = """"
		|
		|INDEX BY
		|	RowID";
	EndIf;
	QueriesArray.Add(QueryText);
	
	If Columns.Find("TypeOfAccrualDeductionName") = Undefined Then
		QueryText =
		"SELECT TOP 0
		|	VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef) AS Ref,
		|	0 AS RowID
		|INTO TypesOfAccrualsOfDeductionsCompared";
	Else
		QueryText =
		"SELECT
		|	AccrualAndDeductionKinds.Ref AS Ref,
		|	DataToImport.Id AS RowID
		|INTO TypesOfAccrualsOfDeductionsCompared
		|FROM Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
		|	INNER JOIN DataToImport AS DataToImport
		|		ON AccrualAndDeductionKinds.Description = DataToImport.TypeOfAccrualDeductionName
		|			AND AccrualAndDeductionKinds.ItIsADeduction = &LoadingDeductions
		|
		|INDEX BY
		|	RowID";
	EndIf;
	QueriesArray.Add(QueryText);
	
	If Columns.Find("TypeOfTaxName") = Undefined Then
		QueryText =
		"SELECT TOP 0
		|	VALUE(Catalog.TaxContributionKinds.EmptyRef) AS Ref,
		|	0 AS RowID
		|INTO TypesOfTaxesCompared";
	Else
		QueryText =
		"SELECT
		|	TaxContributionKinds.Ref AS Ref,
		|	DataToImport.Id AS RowID
		|INTO TypesOfTaxesCompared
		|FROM Catalog.TaxContributionKinds AS TaxContributionKinds
		|	INNER JOIN DataToImport AS DataToImport
		|		ON TaxContributionKinds.Description = DataToImport.TypeOfTaxName
		|			AND TaxContributionKinds.DeductedFromEmployeeWages = &DutiesOfTaxAgent
		|
		|INDEX BY
		|	RowID";
	EndIf;
	QueriesArray.Add(QueryText);
	
	QueryText =
	"SELECT
	|	Table.Id AS Id,
	|	MAX(ISNULL(Departments.Priority, 0)) AS PriorityOfDivisions,
	|	MAX(ISNULL(Persons.Priority, 0)) AS PriorityOfIndividuals
	|INTO ComparisonPriorities
	|FROM DataToImport AS Table
	|	LEFT JOIN UnitsMapped AS Departments
	|		ON Table.Id = Departments.RowID
	|	LEFT JOIN IndividualsMatched AS Persons
	|		ON Table.Id = Persons.RowID
	|
	|GROUP BY
	|	Table.Id
	|;
	|
	|SELECT
	|	Table.Id AS RowID,
	|	MAX(Departments.Ref) AS Department,
	|	COUNT(DISTINCT Departments.Ref) AS NumberOfDivisions_,
	|	MAX(Persons.Ref) AS Individual,
	|	COUNT(DISTINCT Persons.Ref) AS NumberOfIndividuals,
	|	MAX(AccrualAndDeductionKinds.Ref) AS TypeOfAccrualDeduction,
	|	COUNT(DISTINCT AccrualAndDeductionKinds.Ref) AS NumberOfTypesOfAccrualsDeductions,
	|	MAX(TaxesKinds.Ref) AS TaxKind,
	|	COUNT(DISTINCT TaxesKinds.Ref) AS NumberOfTypesOfTaxes
	|INTO MappedData
	|FROM ComparisonPriorities AS Table
	|	LEFT JOIN UnitsMapped AS Departments
	|		ON Table.Id = Departments.RowID
	|		AND Table.PriorityOfDivisions = Departments.Priority
	|	LEFT JOIN IndividualsMatched AS Persons
	|		ON Table.Id = Persons.RowID
	|		AND Table.PriorityOfIndividuals = Persons.Priority
	|	LEFT JOIN TypesOfAccrualsOfDeductionsCompared AS AccrualAndDeductionKinds
	|		ON Table.Id = AccrualAndDeductionKinds.RowID
	|	LEFT JOIN TypesOfTaxesCompared AS TaxesKinds
	|		ON Table.Id = TaxesKinds.RowID
	|
	|GROUP BY
	|	Table.Id";
	
	QueriesArray.Add(QueryText);
	
	QueryText =
	"DROP ComparisonPriorities;
	|DROP UnitsMapped;
	|DROP IndividualsMatched;
	|DROP TypesOfAccrualsOfDeductionsCompared;
	|DROP TypesOfTaxesCompared";
	
	QueriesArray.Add(QueryText);
	
	Return StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
EndFunction

Function RequestTextForSelectionOfMatchedData()
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN MappedData.NumberOfDivisions_ = 1
	|			THEN MappedData.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|	CASE
	|		WHEN MappedData.NumberOfIndividuals = 1
	|			THEN MappedData.Individual
	|		ELSE UNDEFINED
	|	END AS Individual,
	|	CASE
	|		WHEN MappedData.NumberOfTypesOfAccrualsDeductions = 1 AND NOT &LoadingDeductions
	|			THEN MappedData.TypeOfAccrualDeduction
	|		ELSE UNDEFINED
	|	END AS AccrualKind,
	|	CASE
	|		WHEN MappedData.NumberOfTypesOfAccrualsDeductions = 1 AND &LoadingDeductions
	|			THEN MappedData.TypeOfAccrualDeduction
	|		ELSE UNDEFINED
	|	END AS DeductionKind,
	|	CASE
	|		WHEN MappedData.NumberOfTypesOfTaxes = 1
	|			THEN MappedData.TaxKind
	|		ELSE UNDEFINED
	|	END AS TaxKind,
	|	MappedData.NumberOfDivisions_ AS NumberOfDivisions_,
	|	MappedData.NumberOfIndividuals AS NumberOfIndividuals,
	|	MappedData.NumberOfTypesOfAccrualsDeductions AS NumberOfTypesOfAccrualsDeductions,
	|	MappedData.NumberOfTypesOfTaxes AS NumberOfTypesOfTaxes,
	|	DataToImport.*
	|FROM DataToImport AS DataToImport
	|	LEFT JOIN MappedData AS MappedData
	|		ON DataToImport.Id = MappedData.RowID";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf