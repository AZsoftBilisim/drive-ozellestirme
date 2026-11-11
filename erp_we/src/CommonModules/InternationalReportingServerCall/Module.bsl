
////////////////////////////////////////////////////////////////////////////////
//  Procedures and functions that ensure the operation of the financial report generator
//  for obtaining financial statements.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ProcessingOfFormulas

// The function adds the stored operands to the operand table
//
// Parameters:
//  Operand - See InternationalReportingClientServer.NewOperandData
//  MainStorageID - UUID - ID of the report form.
//
// Returns:
//   Structure - array of added rows of the operand table:
//   *Formula - String
//   *NewOperands - See InternationalReportingClientServer.NewOperandData
//
Function AddStoredOperand(Operand, MainStorageID) Export
	
	FinReports = FinancialReportingServerCall;
	AddressOfItemStructure = InternationalReportingClientServer.PlaceCopyOfItemInRepository(
								Operand.LinkedItem1,
								MainStorageID);
	OperandData = GetFromTempStorage(AddressOfItemStructure); // See InternationalReportingClientServer.NewOperandData
	NewOperands = New Array;
	If OperandData.ItemKind = ItemKind("MonetaryIndicator") Then
		
		NewOperand = AddOperand(Operand, AddressOfItemStructure);
		NewOperand.AccountIndicatorDimension = Operand.GLAccount_;
		NewOperand.Code = FinReports.ObjectAttributeValue(NewOperand.AccountIndicatorDimension,"Order");
		NewOperands.Add(NewOperand);
		
	ElsIf OperandData.ItemKind = ItemKind("NonMonetaryItem") Then
		
		NewOperand = AddOperand(Operand, AddressOfItemStructure);
		NewOperand.AccountIndicatorDimension = Operand.NonMonetaryItem;
		NewOperand.Code = FinReports.ObjectAttributeValue(NewOperand.AccountIndicatorDimension,"Code");
		NewOperands.Add(NewOperand);
		
	ElsIf OperandData.ItemKind = ItemKind("DerivedItem") Then
		Formula = FinReports.ValueOfAdditionalProps(OperandData,"Formula");// String -
		FormulaOperands = OperandData.FormulaOperands; // See InternationalReportingClient.AddFormulaOperands.OperandsTable
		For Each FormulaOperand In FormulaOperands Do
			
			OperandAddress = FormulaOperand.AddressOfItemStructure;
			Data = GetFromTempStorage(OperandAddress);
			NewOperand = AddOperand(Data, OperandAddress);
			NewOperand.Id = FormulaOperand.Id;
			If Data.ItemKind = ItemKind("MonetaryIndicator") Then
				NewOperand.AccountIndicatorDimension = FinReports.ValueOfAdditionalProps(Data,"GLAccount_");
				NewOperand.GLAccount_ = NewOperand.AccountIndicatorDimension;
				NewOperand.TotalType = FinReports.ValueOfAdditionalProps(Data,"TotalType");
				NewOperand.OpeningBalance = FinReports.ValueOfAdditionalProps(Data,"OpeningBalance");
			ElsIf Data.ItemKind = ItemKind("NonMonetaryItem") Then
				NewOperand.AccountIndicatorDimension = FinReports.ValueOfAdditionalProps(Data,"NonMonetaryItem");
			EndIf;
			
			NewOperands.Add(NewOperand);
			
		EndDo;
	EndIf;
	
	Return New Structure("Formula,NewOperands",Formula,NewOperands);
	
EndFunction

// Checks the formula for the derivative indicator of the financial statement generator for feasibility.
//
// Parameters:
//  Formula - String - text of the formula for calculating the derived indicator.
//  Operands - See InternationalReportingClient.AddFormulaOperands.OperandsTable
//  Cancel - Boolean - The truth is, if you are not able to perform the calculation according to the formula.
//  Field - String - Name of the form details containing the formula.
//  DataPath - String - path to the form details containing the formula.
//
Procedure CheckFormula(Formula, Operands, Cancel, Field = "", DataPath = "") Export
	
	FinReports = FinancialReportingServer;
	OperandValues = EmptyIndicatorElementTable();
	
	If IsBlankString(Formula) Then
		NotificationText2 = NStr("vi = 'Chưa chỉ ra văn bản công thức.';
								|ru = 'Не указан текст формулы.';
								|en = 'Formula text is not specified.'; fa = 'Formula text is not specified.';
								|it = 'Il testo della formula non è specificato.';
								|pl = 'Nie jest wskazany tekst formuły.';
								|tr = 'Formulün metni belirtilmedi.'");
		CommonClientServer.MessageToUser(NotificationText2, , Field, DataPath,);
	EndIf;
	
	SamplePeriod_ = InternationalReportingServer.ReportPeriod(Date('00010101'), Date('00010101'));
	ReportIntervals = InternationalReportingServer.ReportIntervals(SamplePeriod_);
	
	DCSchema = Catalogs.FinancialReportItems.GetTemplate("DerivedItem");
	NumberType = TMCommonUse.MoneyFieldTypeDescription();
	Pstab = Chars.LF + Chars.Tab;
	UnusedOperands = "";
	Monetary_ = Enums.FinancialReportItemKinds.MonetaryIndicator;
	For Each Operand In Operands Do
		FinReports.NewSetField(DCSchema.DataSets.OperandValues, Operand.Id,,,NumberType);
		OperandValues.Columns.Add(Operand.Id, TMCommonUse.MoneyFieldTypeDescription());
		Id = "["+Operand.Id+"]";
		If StrFind(Formula, Id) = 0 Then
			UnusedOperands = UnusedOperands + Id + " " + Operand.NameForPrinting + Pstab;
		EndIf;
		If Operand.ItemKind = Monetary_ And Not ValueIsFilled(Operand.GLAccount_) Then
			Template = NStr("vi = 'Trong tùy chỉnh toán hạn [%1] %2
								|chưa chỉ ra tài khoản trong hệ thống tài khoản.';
								|ru = 'В настройках операнда [%1] %2
								|не указан счет плана счетов.';
								|en = 'Account of chart of accounts is not specified in the settings of operand [%1] %2.
								|'; fa = 'Account of chart of accounts is not specified in the settings of operand [%1] %2.
								|';
								|it = 'Nelle impostazioni dell''operando [%1] %2 
								|non è specificato il conto del piano dei conti.';
								|pl = 'W ustawieniach operandu [%1] %2
								|nie jest wskazany rachunek planu rachunków.';
								|tr = '[%1] %2
								| işlemin ayarlarında hesap planı hesabı belirtilmemiş.'");
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template, Operand.Id, Operand.NameForPrinting);
			CommonClientServer.MessageToUser(Text, , Field, DataPath,);
		EndIf;
	EndDo;
	If Not IsBlankString(UnusedOperands) Then
		NotificationText2 = NStr("vi = 'Các toán hạng không sử dụng được tìm thấy:';
								|ru = 'Найдены не используемые операнды:';
								|en = 'Unused operands are detected:'; fa = 'Unused operands are detected:';
								|it = 'Operandi non utilizzati trovati:';
								|pl = 'Są znalezione nie wykorzystywane operandy:';
								|tr = 'Kullanılmayan işlem bulundu:'") + Pstab + UnusedOperands;
		CommonClientServer.MessageToUser(NotificationText2, , Field, DataPath,);
	EndIf;
	ValueField = DCSchema.CalculatedFields[0];
	ValueField.Expression = ?(ValueIsFilled(Formula),Formula,"0");
	Composer = FinReports.SchemaComposer(DCSchema);
	Settings = Composer.GetSettings();
	ExternalSets = New Structure;
	ExternalSets.Insert("OperandValues", OperandValues);
	ExternalSets.Insert("ReportIntervals", ReportIntervals);
	
	Try
		FinReports.UploadDCSResults(DCSchema, Settings, ExternalSets);
	Except
		Info = ErrorInfo();
		ErrorDescriptionText = Info.Cause.Cause.Description;
		Cancel = True;
		CommonClientServer.MessageToUser(
					ErrorDescriptionText,
					,
					Field,
					DataPath,);
	EndTry;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForProcessingReportElements

// Returns the sum of the selected cells in a table document.
//
// Parameters:
//	Result - SpreadsheetDocument - A table document containing cells for summation.
//	SelectedAreaCache - Structure - Contains cells in the selected area.
//
// Returns:
//	Number - The sum of the cell values.
//
Function CalculateSumOfSelectedCellsInTableDocument(Val Result, SelectedAreaCache) Export
	
	Sum = 0;
	For Each KeyAndValue In SelectedAreaCache Do
		StructureAddressOfAllocatedArea = KeyAndValue.Value;
		For RowIndex1 = StructureAddressOfAllocatedArea.Top To StructureAddressOfAllocatedArea.Bottom Do
			For IndexColumn = StructureAddressOfAllocatedArea.Left To StructureAddressOfAllocatedArea.Right Do
				Try
					Cell = Result.Area(RowIndex1, IndexColumn, RowIndex1, IndexColumn);
					If Cell.Visible = True Then
						If Cell.ContainsValue And TypeOf(Cell.Value) = Type("Number") Then
							Sum = Sum + Cell.Value;
						ElsIf ValueIsFilled(Cell.Text) Then
							NumberInCell = Number(StringFunctionsClientServer.ReplaceCharsWithOther(Char(32)+Char(43), Cell.Text, Char(0)));
							Sum = Sum + NumberInCell;
						EndIf;
					EndIf;
				Except
					// No log entry is required.
				EndTry;
			EndDo;
		EndDo;
	EndDo;
	
	SelectedAreaCache.Insert("Sum", Sum);
	
	Return Sum;
	
EndFunction


// Searches for links in other reports to the submitted element of the financial report
//
//Parameters:
//  ReportItem - CatalogRef.FinancialReportItems
//  RefsCount - Number - the found number of links will be placed.
//
// Returns:
//  Boolean - True if the current report item is referenced in other reports.
//
Function ThereAreRefs(ReportItem, RefsCount = 0) Export

	ThereAreRefs = False;
	Query = New Query;
	TempTablesManager = FinancialReportingServer.TemporaryTableOfImageIndexes();
	Query.TempTablesManager = TempTablesManager;
	Query.Text = InternationalReportingServer.RequestTextForLinksToReportElement();
	Query.SetParameter("ReportItem", ReportItem);
	Query.SetParameter("Owner", Common.ObjectAttributeValue(ReportItem, "Owner"));
	
	Selection = Query.Execute().Select();
	RefsCount = Selection.Count();
	If Selection.Next() Then
		ThereAreRefs = True;
	EndIf;
	Return ThereAreRefs;

EndFunction

#EndRegion

#Region ReportDecryptionProceduresAndFunctions

// Prepares parameters for the decryption report based on data from the standard SCD decryption and parameters of the calling report.
// 
// Parameters:
//  Details - Structure of KeyAndValue - contains the value of the Cur dimension fields augmented:
//   *StartDate - Date -
//   *EndDate - Date - 
//   *Accuracy - Number -
//  ReportParameters - Structure of KeyAndValue - parameters of the calling report.
// 
// Returns:
//  Structure of KeyAndValue - See NewReportDecryptionParameters - Containing the parameters for the decryption report.
//
Function ReportDecryptionParameters(Details, ReportParameters) Export
	
	DetailsParameters = NewReportDecryptionParameters();
	FillPropertyValues(DetailsParameters, ReportParameters);
	FillPropertyValues(DetailsParameters.Filter, ReportParameters);
	
	If TypeOf(Details) <> Type("Structure") Then
		Return DetailsParameters;
	EndIf;
	
	If Details.Property("Filter") Then
		FillPropertyValues(DetailsParameters.Filter, Details.Filter);
		
		ExtDimensionNumber = 1;
		For Each FilterElement In Details.Filter Do
			If StrFind(FilterElement.Key, "Dimension")  Then
				DetailsParameters.Filter.Insert ("ExtDimension"+ExtDimensionNumber, FilterElement.Value);
				ExtDimensionNumber = ExtDimensionNumber + 1;
			ElsIf StrFind(FilterElement.Key, "ExtDimension") Then
				DetailsParameters.Filter.Insert (FilterElement.Key, FilterElement.Value);
			EndIf;
		EndDo; 
		
	EndIf;
	
	If Details.Property("ExtDimensionType") Then
		DetailsParameters.Insert("ExtDimensionType", Details.ExtDimensionType);
	EndIf;
	
	DetailsParameters.Factor = Details.Factor;
	
	If DetailsParameters.Factor = Undefined Then
		Return DetailsParameters;
	EndIf;
	
	ReportPeriod = New StandardPeriod;
	ReportPeriod.StartDate = Details.StartDate;
	ReportPeriod.EndDate = Details.EndDate;
	DetailsParameters.Insert("ReportPeriod", ReportPeriod);
	
	References_0 = References_0(DetailsParameters.Factor);// Structure
	References_0.Insert("Value", ReportParameters.Value);
	If Details.Property("Accuracy") Then
		References_0.Insert("Accuracy",  Details.Accuracy);
	Else
		References_0.Insert("Accuracy",  0);
	EndIf;
	For Each SelectingDecryptionParameters In DetailsParameters Do
		If StrFind(SelectingDecryptionParameters.Key, "ExtDimension")  And SelectingDecryptionParameters.Key <> "ExtDimensionType" Then
			DetailsParameters.Filter.Insert(SelectingDecryptionParameters.Key, SelectingDecryptionParameters.Value);
		EndIf;
	EndDo; 
	
	DetailsParameters.Factor = References_0;
	DetailsParameters.Insert("EmptyRef", Catalogs.FinancialReportItems.EmptyRef());
	
	// We will prepare the settings of the decryption reports
	If TypeOf(References_0.GLAccount_) = LocalAccntingClientServer.TypeChartOfAccounts() Then
		
		DetailsParameters.Filter.Insert("Account", References_0.GLAccount_);
		DetailsParameters.Insert("SettingUpLocalInvoiceAnalysis", ConfigureAccountAnalysisSelfSupporting(ReportParameters.SettingsAddress, DetailsParameters));
		
	ElsIf TypeOf(References_0.GLAccount_) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
	
		DetailsParameters.Insert("ParametersForOpeningInternationalAccountingReport", 
			ParametersForOpeningInternationalAccountingReportForDecryption(References_0.GLAccount_, DetailsParameters));
			
	EndIf;
	
	ActualSelection = New Structure;
	For Each FilterDecryptions In DetailsParameters.Filter Do
		If FilterDecryptions.Value <> Undefined Or StrStartsWith(FilterDecryptions.Key, "ExtDimension") Then
			ActualSelection.Insert(FilterDecryptions.Key, FilterDecryptions.Value);
		EndIf;
	EndDo; 
	DetailsParameters.Filter = ActualSelection;
	
	Return DetailsParameters;
	
EndFunction

// Prepares parameters for the decryption report Analysisaccountsaccountable
//
// Parameters:
//  Address - String - address in the temporary data store of the calling report decryption
//  Parameters - Structure of KeyAndValue- parameters of the calling report:
//   *Factor - Structure of KeyAndValue - see Attributes
//
// Returns:
//  Structure - Key Value - containing the settings for the report analysesscountscounts:
//   *SettingsAddress - String - the address in the temporary data store of the decryption of the calling report.
//
Function ConfigureAccountAnalysisSelfSupporting(Address, Parameters) Export
	
	// Settings for the decryption report
	ReportSettings1 = New Structure("SettingsAddress", Address);
	
	AccountAnalysis = New Structure("AccountAnalysis");
	DetailsData = New Structure("DecryptionSettings", AccountAnalysis);
	UserSettings = New DataCompositionUserSettings;
	UserSelection_ = UserSettings.Items.Add(Type("DataCompositionFilter"));
	UserSelection_.UserSettingID = "Filter";
	
	// Let's pass the selection of the monetary indicator
	Factor = Parameters.Factor;// Structure - See References_0
	AdditionalSelection = Factor.AdditionalSelection; //ValueStorage
	Filter_Settings = AdditionalSelection.Get();
	If Filter_Settings <> Undefined Then
		FinancialReportingServer.CopyFilter(
				Filter_Settings.Filter,
				UserSelection_,
				True);
	EndIf;
	
	// We will pass the details of the report
	ReportDetails_ = UserSettings.AdditionalProperties;
	ReportDetails_.Insert("IndicatorAccounting", True);
	ReportDetails_.Insert("DetailsMode", True);
	ReportDetails_.Insert("BeginOfPeriod", Parameters.ReportPeriod.StartDate);
	ReportDetails_.Insert("EndOfPeriod",  Parameters.ReportPeriod.EndDate);
	
	For Each Parameter In Parameters.Filter Do
		If ValueIsFilled(Parameter.Value) Then
			ReportDetails_.Insert(Parameter.Key, Parameter.Value);
			If (Parameter.Key = "Organization" Or Parameter.Key = "Department" Or Parameter.Key = "LineOfBusiness")
				And TypeOf(Parameter.Value) = Type("Array") Then
				ReportDetails_.Insert(Parameter.Key, Parameter.Value[0]);
			ElsIf StrStartsWith(Parameter.Key, "ExtDimension") Then
				FinancialReportingServer.NewFilter(UserSelection_, Parameter.Key, Parameter.Value); 
			EndIf;
		EndIf;
	EndDo;
	
	DetailsData.DecryptionSettings.AccountAnalysis = UserSettings;
	PutToTempStorage(DetailsData, Address);
	
	Return ReportSettings1;
	
EndFunction

// Prepares parameters for the decryption report on the international accounting account
//
// Parameters:
//  GLAccount - ChartOfAccountsRef.International - Accounting account
//  Parameters - Structure - parameters of the calling report.
//
// Returns:
//  Structure - Contains:
//  	* ReportName - String - Name of the decryption report
//  	* ReportOptionName - String - Name of the decryption option
//  	* SettingsComposer - DataCompositionSettingsComposer - Report settings Builder
//
Function ParametersForOpeningInternationalAccountingReportForDecryption(Val GLAccount, Val Parameters) Export
	
	AccountProperties = FinancialAccountingServerCached.AccountProperties(GLAccount);
	
	If AccountProperties.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		ReportName = Metadata.Reports.AccountingReportFinancialAccounting.Name;
		ReportOptionName = "OSV_OnAccountOfInternational";
		
		SchemaName = Metadata.Reports.AccountingReportFinancialAccounting.MainDataCompositionSchema.Name;
		DataCompositionSchema = Reports.AccountingReportFinancialAccounting.GetTemplate(SchemaName); // DataCompositionSchema -
		OptionSettings = DataCompositionSchema.SettingVariants[ReportOptionName].Settings;
	Else
		ReportName = Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
		ReportOptionName = "AccountAnalysisInternational";
		
		SchemaName = Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.MainDataCompositionSchema.Name;
		DataCompositionSchema = Reports.AccountingReportWithCorrespondenceFinancialAccounting.GetTemplate(SchemaName); // DataCompositionSchema -
		OptionSettings = DataCompositionSchema.SettingVariants[ReportOptionName].Settings;
	EndIf;
	
	// Settings for the decryption report
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.LoadSettings(OptionSettings);
	UserSettings = SettingsComposer.UserSettings;
	UserSelection_ = SettingsComposer.FixedSettings.Filter;
	For Each Item In UserSettings.Items Do
		If TypeOf(Item) = Type("DataCompositionFilter") Then
			UserSelection_ = Item;
			Break;
		EndIf;
	EndDo;
	
	// Let's set the parameters of the decryption report
	DataCompositionClientServer.SetParameter(UserSettings, "ReportPeriod", Parameters.ReportPeriod);
	DataCompositionClientServer.SetParameter(UserSettings, "PresentationOfInvoicesByCode", True);
	ItIsFunctionalCurrency = Parameters.Resource = "Sum";
	DataCompositionClientServer.SetParameter(UserSettings, "IndicatorAmount", ItIsFunctionalCurrency);
	DataCompositionClientServer.SetParameter(UserSettings, "IndicatorSumOfPresentation", Not ItIsFunctionalCurrency);
		
	// Let's set the selections for an exact match
	FinReports = FinancialReportingServer;
	For Each Filter In Parameters.Filter Do
		If ValueIsFilled(Filter.Value) Then
			FilterValue = Filter.Value;
			If TypeOf(FilterValue) = Type("Array") Then
				FilterValue = New ValueList;
				FilterValue.LoadValues(Filter.Value);
			EndIf;
			FinReports.NewFilter(UserSelection_,Filter.Key,FilterValue);
		ElsIf StrStartsWith(Filter.Key, "ExtDimension") Then
			FinReports.NewFilter(UserSelection_, Filter.Key, , , DataCompositionComparisonType.NotFilled);
		EndIf;
	EndDo;
	
	FilterAccounts = FinReports.NewFilter(UserSelection_,"Account", GLAccount);
	FilterAccounts.ComparisonType = DataCompositionComparisonType.InHierarchy;
	DataCompositionClientServer.SetParameter(UserSettings, "ChartOfAccounts", AccountProperties.ChartOfAccounts);
	
	// We will set the selection according to the monetary indicator
	If Parameters.Property("Factor") Then
		
		Factor = Parameters.Factor; //Structure - See References_0
		AdditionalSelection = Factor.AdditionalSelection; //ValueStorage
		Filter_Settings = AdditionalSelection.Get();
		If Filter_Settings <> Undefined Then
			Filter = Catalogs.FinancialReportItems.RenameExtdimensionFromDoPSelection(Filter_Settings.Filter, Parameters.Factor, Parameters.ExtDimensionType);
			FinReports.CopyFilter(
					Filter,
					UserSelection_,
					True);
		EndIf;
		
		SettingsComposer.FixedSettings.AdditionalProperties.Insert("TotalType", 			Factor.TotalType);
		SettingsComposer.FixedSettings.AdditionalProperties.Insert("OpeningBalance", 	Factor.OpeningBalance);
		
		If Parameters.Property("ExtDimensionType") And ValueIsFilled(Parameters.ExtDimensionType) Then
			DataCompositionClientServer.SetParameter(UserSettings, "ExtDimensionType", Parameters.ExtDimensionType);
		EndIf;
		
	EndIf;
	
	Result = New Structure();
	Result.Insert("ReportName", ReportName);
	Result.Insert("ReportOptionName", ReportOptionName);
	Result.Insert("SettingsComposer", SettingsComposer);
	
	Return Result;
	
EndFunction

#EndRegion

// The function gets the "this group of Templates" props for the passed transaction template
//
// Parameters:
//	PostingTemplate - CatalogRef.PostingTemplatesForFinancialAccounting - the wiring pattern.
//
// Returns:
//	Boolean - True if the transaction template is a group of templates.
//
Function ThisIsTemplateGroup(Val PostingTemplate) Export
	Return Common.ObjectAttributeValue(PostingTemplate, "ThisIsTemplateGroup");
EndFunction

// Forms a text representation of the document Regulationoperationinternational accounting
// with households. the operation closes the income expense Account.
//
// Parameters:
//  RepresentationOfTheReference - Boolean - True, returns the view template to be filled
//                                 in later in the viewreport handler.
//
// Returns:
//  String - The document presentation string.
//
Function PresentationOfClosingIncomeExpenses(RepresentationOfTheReference = True) Export
	
	Presentation = NStr("vi = 'Đóng tài khoản thu nhập và chi phí (kế toán quốc tế)';
						|ru = 'Закрытие счетов учета доходов и расходов (международный учет)';
						|en = 'Closing of ledger accounts of income and expenses (financial accounting)'; fa = 'Closing of ledger accounts of income and expenses (financial accounting)';
						|it = 'Chiusura dei conti delle entrate e delle spese (contabilità internazionale)';
						|pl = 'Zamknięcie rachunków ewidencji dochodów i rozchodów (ewidencja międzynarodowa)';
						|tr = 'Gelir ve gider muhasebe hesapların kapatılması (uluslararası muhasebe)'");
	If RepresentationOfTheReference Then
		Presentation = Presentation + " "+NStr("vi = '%1 ngày %2';
												|ru = '%1 от %2';
												|en = '%1 from %2'; fa = '%1 from %2';
												|it = '%1 del %2';
												|pl = '%1 z dn. %2';
												|tr = '%2 itibarıyla %1'");
	EndIf;
	Return Presentation;
	
EndFunction

// Forms a text representation of the document Regulationoperationinternational accounting
// with households. operation calculation of course differencesfunctional Currency.
//
// Parameters:
//  RepresentationOfTheReference - Boolean - True, returns the view template to be filled
//                                 in later in the viewreport handler.
//
// Returns:
//  String - The document presentation string.
//
Function PresentationCalculationOfExchangeDifferencesInFunctionalCurrency(RepresentationOfTheReference = True) Export
	
	Presentation = NStr("vi = 'Tính toán chênh lệch tỷ giá hối đoái (kế toán quốc tế)';
						|ru = 'Расчет курсовых разниц в функциональной валюте (международный учет)';
						|en = 'Exchange difference calculation in the functional currency (financial accounting)'; fa = 'Exchange difference calculation in the functional currency (financial accounting)';
						|it = 'Calcolo delle differenze di cambio nella valuta funzionale (International Accounting)';
						|pl = 'Obliczenie różnic kursowych w walucie funkcjonalnej (ewidencja międzynarodowa)';
						|tr = 'Fonksiyonel para birimi cinsinden kur farkı hesaplaması (uluslararası muhasebe)'");
	If RepresentationOfTheReference Then
		Presentation = Presentation + " "+NStr("vi = '%1 ngày %2';
												|ru = '%1 от %2';
												|en = '%1 from %2'; fa = '%1 from %2';
												|it = '%1 del %2';
												|pl = '%1 z dn. %2';
												|tr = '%2 itibarıyla %1'");
	EndIf;
	Return Presentation;
	
EndFunction

// Forms a text representation of the document Regulationoperationinternational accounting
// with households. operation calculation of Courseparticipationsreferences.
//
// Parameters:
//  RepresentationOfTheReference - Boolean - True, returns the view template to be filled
//                                 in later in the viewreport handler.
//
// Returns:
//  String - The document presentation string.
//
Function PresentationCalculationOfExchangeDifferencesCurrencyOfPresentation(RepresentationOfTheReference = True) Export
	
	Presentation = NStr("vi = 'Tính toán chênh lệch tỷ giá hối đoái (kế toán quốc tế)';
						|ru = 'Расчет курсовых разниц в валюте представления (международный учет)';
						|en = 'Exchange difference calculation in the presentation currency (financial accounting)'; fa = 'Exchange difference calculation in the presentation currency (financial accounting)';
						|it = 'Calcolo delle differenze di cambio nella valuta di presentazione (International Accounting)';
						|pl = 'Obliczenie różnic kursowych w walucie prezentacji (ewidencja międzynarodowa)';
						|tr = 'Sunum para birimi cinsinden kur farkı hesaplaması (uluslararası muhasebe)'");
	If RepresentationOfTheReference Then
		Presentation = Presentation + " "+NStr("vi = '%1 ngày %2';
												|ru = '%1 от %2';
												|en = '%1 from %2'; fa = '%1 from %2';
												|it = '%1 del %2';
												|pl = '%1 z dn. %2';
												|tr = '%2 itibarıyla %1'");
	EndIf;
	Return Presentation;
	
EndFunction

#EndRegion

#Region Private

// Indicator Attributes.
// 
// Parameters:
//  Factor - Structure of KeyAndValue, ValueTreeRow - References
// 
// Returns:
//  Structure - References:
// * Ref - CatalogRef.FinancialReportItems
// * Owner - CatalogRef.FinancialReportTypes, CatalogRef.BudgetProfiles - 
// * Description - String
// * Code - String
// * ItemKind - EnumRef.FinancialReportItemKinds
// * NameForPrinting  - String
// * ReverseSign - Boolean
// * Comment - String
// * AdditionalSelection - Structure of KeyAndValue -
// * HasSettings - Boolean
// * DimensionValue - Characteristic.BudgetFlowItemDimensions
// * LinkedItem1 - CatalogRef.FinancialReportItems
// * ItemKindAttributes - ValueTable
// * FormulaOperands  - ValueTable
// * TableItems - ValueTable
// * AdditionalFields  - ValueTable
// * AppearanceItems - ValueTable 
// * RegisteredRows - ValueTable
// * DesigningColumns - ValueTable
// * DrillDownOfAppearanceItemFilterFields - ValueTable
// * ValueSources - ValueTable
Function References_0(Val Factor)
	
	ElementData = FinancialReportingClientServer.ReportElementStructure();
	Attributes = "GLAccount_,NonMonetaryItem,Formula,TotalType,OpeningBalance";
	If ValueIsFilled(Factor.LinkedItem1) Then
		Factor = Factor.LinkedItem1;
	EndIf;
	
	ElementTables = "ItemKindAttributes,ValueSources,FormulaOperands,TableItems,AdditionalFields,AppearanceItems,RegisteredRows,DesigningColumns,DrillDownOfAppearanceItemFilterFields,CalculationsRules";
	
	AddAttributes = FinancialReportingServerCall.AdditionalAttributesValues(Factor, Attributes);
	FillPropertyValues(ElementData, Factor,,ElementTables);
	For Each Attribute In AddAttributes Do
		ElementData.Insert(Attribute.Key, Attribute.Value);
	EndDo;
	
	Return ElementData;
	
EndFunction

// New report decryption parameters.
// 
// Returns:
//  Structure - New Report Decryption Parameters:
// * ReportKind - CatalogRef.FinancialReportTypes
// * ReportingSet - CatalogRef.FinancialReportSets
// * Factor - CatalogRef.FinancialReportItems
// * Resource - String
// * Value - Number
// * ExtDimensionType - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes
// * MultiplierOfAmounts - Number
// * Accuracy - Number
// * Filter - Structure -:
// ** Organization - CatalogRef.Companies
// ** Department - CatalogRef.BusinessStructure
// ** LineOfBusiness - CatalogRef.LinesOfBusiness
Function NewReportDecryptionParameters()
	
	Result = New Structure;
	Result.Insert("ReportKind");
	Result.Insert("ReportingSet");
	Result.Insert("Factor");
	Result.Insert("Resource");
	Result.Insert("Value");
	Result.Insert("ExtDimensionType");
	Result.Insert("MultiplierOfAmounts");
	Result.Insert("Accuracy");
	
	Filter = New Structure("Organization,Department,LineOfBusiness");
	Result.Insert("Filter", Filter);
	
	Return Result;
	
EndFunction

Function EmptyIndicatorElementTable()
	
	Result = New ValueTable;
	Result.Columns.Add("Factor",    New TypeDescription("CatalogRef.FinancialReportItems"));
	Result.Columns.Add("Note",    New TypeDescription("String",,New StringQualifiers(100)));
	Result.Columns.Add("RowCode",     New TypeDescription("String",,New StringQualifiers(20)));
	Result.Columns.Add("StartDate",    New TypeDescription("Date",,,New DateQualifiers(DateFractions.DateTime)));
	Result.Columns.Add("EndDate", New TypeDescription("Date",,,New DateQualifiers(DateFractions.DateTime)));
	Result.Columns.Add("Value",      TMCommonUse.MoneyFieldTypeDescription());
	Return Result;
	
EndFunction

Function ItemKind(ElementTypeName)
	
	Return Enums.FinancialReportItemKinds[ElementTypeName];
	
EndFunction

Function AddOperand(OperandData, AddressOfItemStructure)
	
	NewOperand = InternationalReportingClientServer.NewOperandData();
	FillPropertyValues(NewOperand, OperandData,,"LinkedItem1");
	NewOperand.AddressOfItemStructure = AddressOfItemStructure;
	NewOperand.ThisIsReference = False;
	NewOperand.CustomPicture = FinancialReportingCached.CustomPicture(OperandData.ItemKind);
	
	Return NewOperand;
	
EndFunction

#EndRegion
