
////////////////////////////////////////////////////////////////////////////////
//  Procedures and functions that ensure the operation of the financial report generator
//  for obtaining financial statements.
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// LongDesc
// 
// Parameters:
// 	Parameters - Structure of KeyAndValue - :
// 	 * ReportKind - CatalogRef.FinancialReportTypes - 
// 	StorageAddress - String - LongDesc
// Returns:
// 	Structure - LongDesc:
// 	 * Result - SpreadsheetDocument
// 	 * ErrorsMessages - Array of String
// 	 * Measurements - Structure - Measurements Father:
// 	   ** ReportDescription1 - String
// 	   ** ReportOutput - Number -  Report output time in milliseconds
// 	   ** TotalReportGeneration - Number - Total report generation time in milliseconds
//
Function GenerateReport(Parameters, StorageAddress = Undefined) Export
	
	AttributeCache = Undefined;
	ReportItemTree = UpdateTheReportTree(Parameters.ReportKind,,AttributeCache,True);
	
	ExecutionResult = New Structure;
	
	ErrorText = "";
	CheckingLoopingOfReportTypes(ReportItemTree, ErrorText);
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText);
		ErrorsArray = New Array;
		AddErrorMessage(ErrorsArray, ErrorText);
		ExecutionResult.Insert("ErrorsMessages", ErrorsArray); 
		ExecutionResult.Insert("Result", New SpreadsheetDocument);
		If ValueIsFilled(StorageAddress) Then
			PutToTempStorage(ExecutionResult, StorageAddress);
		EndIf;
		Return ExecutionResult;
	EndIf;
	
	Parameters.Insert("AttributeCache", 			AttributeCache);
	Parameters.Insert("ErrorsMessages", 		New Array);
	Parameters.Insert("AdditionalSuffix", 				"");
	Parameters.Insert("ReportBlocks", 				New Array);
	Parameters.Insert("ItemsKinds", 			Enums.FinancialReportItemKinds.Cache());
	
	ValueFormat = "NZ=-; NN=0";
	If Parameters.MultiplierOfAmounts = Enums.NumberPresentationKinds.InThousands Then
		ValueFormat = "NZ=-; NN=0; NS=3; NFD=0";
	ElsIf Parameters.MultiplierOfAmounts = Enums.NumberPresentationKinds.InMillions Then
		ValueFormat = "NZ=-; NN=0; NS=6; NFD=0";
	EndIf;  
	Parameters.Insert("ValueFormat_", ValueFormat);
	
	Parameters.Insert("MaxNumberOfColumns", 	0);
	Parameters.Insert("StartOfReportGeneration", 	CurrentUniversalDateInMilliseconds());
	Parameters.Insert("ReportDetails", 		New Structure);
	
	Measurements = New Structure("ReportDescription1", String(Parameters.ReportKind));
	If Parameters.Property("IndicatorData") Then
		DerivedItemDrillDown(Parameters);
		ExecutionResult.Insert("Result", Parameters.Result);
		If ValueIsFilled(StorageAddress) Then
			PutToTempStorage(ExecutionResult, StorageAddress);
		EndIf;
		Return ExecutionResult;
	Else
		Begin = CurrentUniversalDateInMilliseconds();
		DescriptionOfReportType(Parameters, ReportItemTree);
		Measurements.Insert("DataCollection_", (CurrentUniversalDateInMilliseconds() - Begin) / 1000);
	EndIf;
	Parameters.Delete("AdditionalSuffix");
	
	Begin = CurrentUniversalDateInMilliseconds();
	ResultDocument = OutputReport(Parameters, ReportItemTree);
	
	Measurements.Insert("ReportOutput", (CurrentUniversalDateInMilliseconds() - Begin) / 1000);
	Measurements.Insert("TotalReportGeneration",(CurrentUniversalDateInMilliseconds() - Parameters.StartOfReportGeneration) / 1000);
	
	ExecutionResult.Insert("ErrorsMessages", Parameters.ErrorsMessages);
	ExecutionResult.Insert("Result", ResultDocument);
	ExecutionResult.Insert("Measurements", Measurements);
	
	If ValueIsFilled(StorageAddress) Then
		PutToTempStorage(ExecutionResult, StorageAddress);
	EndIf;
	Return ExecutionResult;
	
EndFunction

// Returns a table of intervals for the passed period.
//
// Parameters:
//  ReportPeriod - Structure - description of the period with the following key values:
//    *BeginOfPeriod - Date - Beginning of the period
//    *EndOfPeriod - Date - End of the period
//    *Periodicity - Array of Structure - :
//      **Periodicity - EnumRef.Periodicity - array of predefined intervals.
//
// Returns:
//   ValueTable - See NewIntervalTable - The table contains specific dates from the transmitted period for predefined intervals year,
//   					half-year, quarter, month, etc. If an empty array of intervals is passed in the period parameters
//   					, a table with a single row containing only the passed period is returned.
//
Function ReportIntervals(ReportPeriod) Export
	
	BeginOfPeriod = BegOfMonth(ReportPeriod.BeginOfPeriod);
	EndOfPeriod = EndOfMonth(ReportPeriod.EndOfPeriod);
	
	PeriodsForObtainingIndicators = New Array;
	PeriodsForObtainingIndicators.Add(New Structure("BeginOfPeriod, EndOfPeriod", BeginOfPeriod, EndOfPeriod));	
	
	Periodicity = New Array;
	ReportIntervals = NewIntervalTable();
	
	ThereIsPeriodicityOfYear = False;
	ThereIsPeriodicityOfHalfYear = False;
	ThereIsPeriodicityQuarter = False;
	ThereIsPeriodicityOfMonth = False;
	PeriodQuantum = Undefined;
	
	MinimumReportDate = BeginOfPeriod;
	
	If ReportPeriod.Periodicity.Count() Then
		Periodicity = New Array;
		For Each Period In ReportPeriod.Periodicity Do
			Periodicity.Add(Period.Periodicity);
			
			If Period.Periodicity = Enums.Periodicity.Year Then
				ThereIsPeriodicityOfYear = True;
			ElsIf Period.Periodicity = Enums.Periodicity.HalfYear Then
				ThereIsPeriodicityOfHalfYear = True;
			ElsIf Period.Periodicity = Enums.Periodicity.Quarter Then
				ThereIsPeriodicityQuarter = True;
			ElsIf Period.Periodicity = Enums.Periodicity.Month  Then
				ThereIsPeriodicityOfMonth = True;
			EndIf;
			
			If Period.OutputIndicatorsOfSimilarPeriodsOfPreviousYears <> Undefined
				And Period.OutputIndicatorsOfSimilarPeriodsOfPreviousYears Then
				For NumberOfPeriods = 1 To Period.NumberOfPreviousYears Do
					ComparativePeriod = ComparativePeriod(BeginOfPeriod, EndOfPeriod, Enums.Periodicity.Year, NumberOfPeriods);
					PeriodsForObtainingIndicators.Add(ComparativePeriod);
					If ComparativePeriod.BeginOfPeriod < MinimumReportDate Then
						MinimumReportDate = ComparativePeriod.BeginOfPeriod;
					EndIf;
				EndDo;
			EndIf;
			If Period.DisplayIndicatorsOfPreviousPeriods <> Undefined 
				And Period.DisplayIndicatorsOfPreviousPeriods Then
				For NumberOfPeriods = 1 To Period.NumberOfPreviousPeriods Do
					ComparativePeriod = ComparativePeriod(BeginOfPeriod, EndOfPeriod, Period.Periodicity, NumberOfPeriods);
					PeriodsForObtainingIndicators.Add(ComparativePeriod);
					If ComparativePeriod.BeginOfPeriod < MinimumReportDate Then
						MinimumReportDate = ComparativePeriod.BeginOfPeriod;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	Else
		NewInterval = ReportIntervals.Add();
		NewInterval.EndDate = EndOfPeriod;
		NewInterval.StartDate = BeginOfPeriod;
		Return ReportIntervals;
	EndIf;
	
	PeriodQuantum = Undefined;
	If ThereIsPeriodicityOfMonth Then
		PeriodQuantum = Enums.Periodicity.Month;
	ElsIf ThereIsPeriodicityQuarter Then
		PeriodQuantum = Enums.Periodicity.Quarter;
	ElsIf ThereIsPeriodicityOfHalfYear Then
		PeriodQuantum = Enums.Periodicity.HalfYear;
	ElsIf ThereIsPeriodicityOfYear Then
		PeriodQuantum = Enums.Periodicity.Year;
	EndIf;
	
	NumberOfMonthsOfReport = DateDifferenceInMonths(BeginOfPeriod, EndOfPeriod);
	
	If ThereIsPeriodicityOfYear And NumberOfMonthsOfReport < 12 Then
		Raise NStr("vi = 'Trong phần tử báo cáo đã chọn định kỳ ""Năm"". Kỳ lập báo cáo không thể nhỏ hơn 12 tháng.';
					|ru = 'В элементах отчета выбрана периодичность ""Год"". Период, за который строится отчет, не может быть менее 12 месяцев.';
					|en = '""Year"" frequency is selected in the report items. The report period cannot be less than 12 months.'; fa = '""Year"" frequency is selected in the report items. The report period cannot be less than 12 months.';
					|it = 'Negli elementi di report è stata selezionata la periodicità ""Anno"". Il periodo per il quale viene elaborato il report non può essere inferiore a 12 mesi.';
					|pl = 'W elementach raportu jest wybrana okresowość ""Rok"". Okres, z który jest budowany raport, nie może być mniejszy niż 12 miesiące.';
					|tr = 'Rapor öğelerinde ""Yıl"" sıklığını seçildi. Raporun oluşturulduğu süre 12 aydan az olamaz.'");
	ElsIf ThereIsPeriodicityOfHalfYear And NumberOfMonthsOfReport < 6 Then
		Raise NStr("vi = 'Trong các phần tử báo cáo đã chọn định kỳ ""6 tháng"". Kỳ lập báo cáo không thể nhỏ hơn 6 tháng.';
					|ru = 'В элементах отчета выбрана периодичность ""Полугодие"". Период, за который строится отчет, не может быть менее 6 месяцев.';
					|en = '""Half year"" frequency is selected in the report items. The report period cannot be less than 6 months.'; fa = '""Half year"" frequency is selected in the report items. The report period cannot be less than 6 months.';
					|it = 'Negli elementi di report è stata selezionata la periodicità ""Semestre"". Il periodo per il quale viene elaborato il report non può essere inferiore a 6 mesi.';
					|pl = 'W elementach raportu jest wybrana okresowość ""Półrocze"". Okres, z który jest budowany raport, nie może być mniejszy niż 6 miesiące.';
					|tr = 'Rapor öğelerinde ""Yarıyıl"" sıklığı seçildi. Raporun oluşturulduğu süre 6 aydan az olamaz.'");
	ElsIf ThereIsPeriodicityQuarter And NumberOfMonthsOfReport < 3 Then
		Raise NStr("vi = 'Trong phần tử báo cáo đã chọn định kỳ ""Năm"". Kỳ lập báo cáo không thể nhỏ hơn 3 tháng.';
					|ru = 'В элементах отчета выбрана периодичность ""Квартал"". Период, за который строится отчет, не может быть менее 3 месяцев.';
					|en = '""Quarter"" frequency is selected in the report items. The report period cannot be less than 3 months.'; fa = '""Quarter"" frequency is selected in the report items. The report period cannot be less than 3 months.';
					|it = 'Negli elementi di report è stata selezionata la periodicità ""Trimestre"". Il periodo per il quale viene elaborato il report non può essere inferiore a 3 mesi.';
					|pl = 'W elementach raportu jest wybrana okresowość ""Kwartał"". Okres, za który jest budowany raport, nie może być mniejszy niż 3 miesiące.';
					|tr = 'Rapor öğelerinde ""Çeyrek"" sıklığı seçildi. Raporun oluşturulduğu süre 3 aydan az olamaz.'");
	EndIf;
	
	FinancialPeriodsYear =
			FinancialPeriods(
				Enums.Periodicity.Year, 
				BeginOfPeriod,
				EndOfPeriod,
				MinimumReportDate);
	
	FinancialPeriodsHalfYear =
			FinancialPeriods(
				Enums.Periodicity.HalfYear,
				BeginOfPeriod,
				EndOfPeriod,
				MinimumReportDate);
	
	FinancialPeriodsQuarter = FinancialPeriods(
				Enums.Periodicity.Quarter, 
				BeginOfPeriod,
				EndOfPeriod,
				MinimumReportDate);
	
	For Each PeriodOfDataReceipt In PeriodsForObtainingIndicators Do
	
		PeriodStartDate = PeriodOfDataReceipt.BeginOfPeriod;
		PeriodEndDate = PeriodOfDataReceipt.BeginOfPeriod;
		
		While PeriodEndDate <  PeriodOfDataReceipt.EndOfPeriod Do
			
			PeriodEndDate = EndDateOfNewInterval(PeriodEndDate, PeriodQuantum, PeriodOfDataReceipt.EndOfPeriod);
			
			SearchResult = ReportIntervals.FindRows(New Structure("StartDate, EndDate", PeriodStartDate, PeriodEndDate));
			
			If SearchResult.Count() = 0 Then
				NewInterval = ReportIntervals.Add(); 
				NewInterval.StartDate = PeriodStartDate;
				NewInterval.EndDate = PeriodEndDate;
				
				NewInterval.YearPeriod = BoundariesOfFinancialPeriod(PeriodEndDate, FinancialPeriodsYear).EndOfPeriod;
				NewInterval.HalfYearPeriod = BoundariesOfFinancialPeriod(PeriodEndDate, FinancialPeriodsHalfYear).EndOfPeriod;
				NewInterval.QuarterPeriod = BoundariesOfFinancialPeriod(PeriodEndDate, FinancialPeriodsQuarter).EndOfPeriod;
				NewInterval.MonthPeriod = EndOfMonth(PeriodEndDate);
			EndIf;
			
			PeriodEndDate = PeriodEndDate + 1;
			PeriodStartDate = PeriodEndDate;
			
		EndDo;
	
	EndDo;
	
	Return ReportIntervals;
	
EndFunction

Procedure GenerateSetOfReports(Parameters, StorageAddress) Export
	
	MainStorageID = Parameters.MainStorageID;
	
	TotalInstances = Parameters.ReportInstances.Count();
	Counter = 1;
	
	ProgressMessage = NStr("vi = 'Tạo bộ báo cáo, vui lòng đợi...';
							|ru = 'Формирование комплектов отчетов, пожалуйста подождите...';
							|en = 'Generating report sets. Please, wait...'; fa = 'Generating report sets. Please, wait...';
							|it = 'Generating report sets. Please, wait...';
							|pl = 'Generating report sets. Please, wait...';
							|tr = 'Rapor kümeleri oluşturuluyor, lütfen bekleyin...'") + Chars.LF;
	InstanceData = New Map;
	For Each Instance In Parameters.ReportInstances Do
		
		ReportKind = Instance.Key;
		Parameters.Insert("DetailsData", PutToTempStorage(Undefined, MainStorageID));
		Parameters.ReportKind = ReportKind;
		Parameters.DisplayRowCode = ReportKind.DisplayRowCode;
		Parameters.DisplayNoteInReport = ReportKind.DisplayNoteInReport;
		Parameters.RowCodeHeader = ReportKind.RowCodeHeader;
		Parameters.CommentHeader = ReportKind.CommentHeader;
		Parameters.ReportLanguage = ReportKind.ReportLanguage;
		
		TimeConsumingOperations.ReportProgress(Int((Counter/TotalInstances)*100), 
			ProgressMessage + "Current_ report: " + Instance.Key);
		
		AddressOfReportData = Instance.Value;
		ReportExecutionResult = GenerateReport(Parameters);
		PutToTempStorage(ReportExecutionResult, AddressOfReportData);
		
		Parameters.ReportResult = ReportExecutionResult.Result;
		
		NewInstance = Documents.FinancialStatementCopy.CreateDocument();
		NewInstance.Date = CurrentSessionDate();
		NewInstance.EmployeeResponsible = Users.CurrentUser();
		NewInstance.Fill(Parameters);
		NewInstance.Currency = Parameters.Currency;
		
		NewInstance.Write();
		
		InstanceData.Insert(AddressOfReportData, ReportSettings(Parameters));
		
	EndDo;// by type of report
	
	BackgroundJobExecutionResult = New Structure;
	BackgroundJobExecutionResult.Insert("Completed2", True);
	BackgroundJobExecutionResult.Insert("ReportPeriod", Parameters.ReportPeriod);
	BackgroundJobExecutionResult.Insert("Filter", Parameters.Filter);
	BackgroundJobExecutionResult.Insert("SetOfReports", Parameters.SetOfReports);
	BackgroundJobExecutionResult.Insert("OpenForms", Parameters.OpenForms);
	BackgroundJobExecutionResult.Insert("InstanceData", InstanceData);
	
	PutToTempStorage(BackgroundJobExecutionResult, StorageAddress);
	
EndProcedure

#EndRegion

#Region Private

#Region GeneratingSetsOfReports

Function ReportSettings(Parameters)
	
	// Context Report Settings
	SettingsComposer = New DataCompositionSettingsComposer;
	UserSettings = SettingsComposer.UserSettings;
	NewSettings1 = New Structure;
	NewSettings1.Insert("ReportingSet", Parameters.ReportingSet);
	NewSettings1.Insert("ReportKind"         , Parameters.ReportKind);
	NewSettings1.Insert("BeginOfPeriod"     , Parameters.ReportPeriod.BeginOfPeriod);
	NewSettings1.Insert("EndOfPeriod"      , Parameters.ReportPeriod.EndOfPeriod);
	
	List = New ValueList;
	If ValueIsFilled(Parameters.Filter.Organization) Then
		List.Add(Parameters.Filter.Organization);
	EndIf;
	NewSettings1.Insert("Companies", List);
	
	List = New ValueList;
	If ValueIsFilled(Parameters.Filter.Department) Then
		List.Add(Parameters.Filter.Department);
	EndIf;
	NewSettings1.Insert("Departments", List);
	
	If Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed() Then
		List = New ValueList;
		If ValueIsFilled(Parameters.Filter.LineOfBusiness) Then
			List.Add(Parameters.Filter.LineOfBusiness);
		EndIf;
		NewSettings1.Insert("LinesOfBusiness", List);
	EndIf;
	
	NewSettings1.Insert("MultiplierOfAmounts"     , Parameters.MultiplierOfAmounts);
	NewSettings1.Insert("TitleOutput" , False);
	NewSettings1.Insert("OutputTheBasement"    , False);
	NewSettings1.Insert("HideSettingsWhenGeneratingReport", False);
	NewSettings1.Insert("VisibilityOfSettingsPanel", True);
	NewSettings1.Insert("Resource"            , Parameters.Resource);
	UserSettings.AdditionalProperties.Insert("ReportData", New ValueStorage(NewSettings1));
	
	Return UserSettings;
	
EndFunction

#EndRegion

#Region Reporting

#Region ProceduresAndFunctionsForGettingReportSettings

Procedure DescriptionOfReportType(Parameters, ReportItemTree)
	
	ItemsKinds = Parameters.ItemsKinds;
	If TypeOf(ReportItemTree) = Type("ValueTreeRow") Then
		If ReportItemTree.ItemKind = ItemsKinds.TableIndicatorsInColumns
			Or ReportItemTree.ItemKind = ItemsKinds.TableIndicatorsInRows
			Or ReportItemTree.ItemKind = ItemsKinds.ComplexTable Then
			Return;
		EndIf;
	EndIf;
	
	For Each ReportItem In ReportItemTree.Rows Do
		
		If ReportItem.ItemKind = ItemsKinds.ReportHeader
			Or ReportItem.ItemKind = ItemsKinds.UneditedText
			Or ReportItem.ItemKind = ItemsKinds.EditedText Then
			AddTextBlock(Parameters, ReportItem);
			DescriptionOfReportType(Parameters, ReportItem);
			
		ElsIf ReportItem.ItemKind = ItemsKinds.TableIndicatorsInColumns
			Or ReportItem.ItemKind = ItemsKinds.TableIndicatorsInRows
			Or ReportItem.ItemKind = ItemsKinds.ComplexTable Then
			AddTable(Parameters, ReportItem);
			
		ElsIf ThisIsIndicator(ReportItem.ItemKind, ItemsKinds, ReportItem.ThisIsReference) Then
			AddReportMetric(Parameters, ReportItem);
			
		EndIf;
		
	EndDo;// by lines of the report element
	
EndProcedure

Procedure AddTextBlock(Parameters, ReportItem)

	FinReportVariables = FinancialReportingClientServer.FinancialStatementVariables();
	
	ReportPeriod = Parameters.ReportPeriod;
	TitleText = FinancialReportingServer.ValueOfAdditionalProps(
		ReportItem.ReportItem, "Text", Parameters.AttributeCache);
	
	PresentationOfReportingSet = ReportingSetOfReportType(Parameters.ReportKind);
	TitleText = StrReplace(TitleText,
			FinReportVariables.ReportSet.Name, 
			PresentationOfReportingSet);
	
	TitleText = StrReplace(TitleText,
			FinReportVariables.ReportKind.Name,
			String(Parameters.ReportKind));
	
	If StrFind(TitleText, FinReportVariables.ReportingPeriod.Name) > 0 Then
		PeriodAsString = TMReportFunctionsClientServer.GetPeriodPresentation(ReportPeriod.BeginOfPeriod, ReportPeriod.EndOfPeriod, True, Parameters.ReportLanguage);
		TitleText = StrReplace(TitleText, FinReportVariables.ReportingPeriod.Name ,TrimAll(PeriodAsString));
	EndIf;
	
	If StrFind(TitleText, FinReportVariables.EndDateOfReportPeriod.Name) > 0 Then
		EndOfReport = Format(ReportPeriod.EndOfPeriod, "L=" + Parameters.ReportLanguage + "; DLF=DD");
		TitleText = StrReplace(TitleText, FinReportVariables.EndDateOfReportPeriod.Name, String(EndOfReport));
	EndIf;
	
	If StrFind(TitleText, FinReportVariables.CurrentDateAndTime.Name) > 0 Then
		DateReportWasGenerated = Format(Parameters.DateReportWasGenerated, "L=" + Parameters.ReportLanguage + "DLF=DT");
		TitleText = StrReplace(TitleText, FinReportVariables.CurrentDateAndTime.Name, DateReportWasGenerated);
	EndIf;
	
	If StrFind(TitleText, FinReportVariables.Organization.Name) > 0 Then
		If Parameters.Property("Filter") And Parameters.Filter.Property("Organization") Then
			FilterValue = Parameters.Filter.Organization;
			
			Companies = New Array;
			If TypeOf(FilterValue) = Type("CatalogRef.Companies") Then
				Companies.Add(FilterValue);
			ElsIf TypeOf(FilterValue) = Type("Array") Then
				Companies = FilterValue;
			ElsIf TypeOf(FilterValue) = Type("ValueList") Then
				Companies = FilterValue.UnloadValues();
			EndIf;
			
			CompanyName = "";
			AttributesNames = "Description,AbbreviatedDescription,DescriptionFull";
			Attributes = Common.ObjectsAttributesValues(Companies, AttributesNames);
			
			For Each Organization In Attributes Do
				CompanyName = CompanyName + ?(IsBlankString(CompanyName),"",", ");
				CompanyName = CompanyName + Organization.Value.AbbreviatedDescription;
			EndDo;
			
		EndIf; // There is a selection by organization
		TitleText = StrReplace(TitleText,
				FinReportVariables.Organization.Name,
				CompanyName);
	EndIf;
	
	Data = New Structure("Text", TitleText);
	AddDescriptionOfReportBlock(Parameters, ReportItem, Data);

EndProcedure

Procedure AddTable(Parameters, ReportItem)
	
	TableTree = ReportItem;
	If TableTree.ThisIsReference Then
		OwnerReport = Common.ObjectAttributesValues(ReportItem.LinkedItem1, "Owner");
		RelatedTable = UpdateTheReportTree(OwnerReport, ReportItem.LinkedItem1);
		TableTree = RelatedTable.Rows[0];
	EndIf;
	
	Parameters.Insert("TableType", ReportItem.ItemKind);
	
	TableData = PrepareTableData(TableTree, Parameters);
	
	If Parameters.DisplayNoteInReport Then
		NewRow = TableData.ReportColumns.Insert(0);
		NewRow.ColumnName = "Note";
		NewRow.TotalLevel = -1;
	EndIf;
	
	If Parameters.DisplayRowCode Then
		NewRow = TableData.ReportColumns.Insert(0);
		NewRow.ColumnName = "ReportRowCode";
		NewRow.TotalLevel = -1;
	EndIf;
	
	Parameters.MaxNumberOfColumns = Max(Parameters.MaxNumberOfColumns, TableData.ReportColumns.Count());
	AddDescriptionOfReportBlock(Parameters, ReportItem, TableData);
	Parameters.ReportPeriod.Periodicity.Clear();
	
EndProcedure

Procedure AddReportMetric(Parameters, ReportItem)
	
	IndicatorParameters = ParametersForObtainingMetric(Parameters);
	IndicatorParameters.Factor = ReportItem;
	
	IndicatorValue = ReportMetricValue(IndicatorParameters);
	
	DetailsCell = New Structure("StartDate, EndDate, ItemKind, GLAccount_, NonMonetaryItem");
	FillPropertyValues(DetailsCell, ReportItem);
	DetailsCell.StartDate = Parameters.ReportPeriod.BeginOfPeriod;
	DetailsCell.EndDate = Parameters.ReportPeriod.EndOfPeriod;
	DetailsCell.Insert("Factor", ReportItem.ReportItem);
	
	Data = New Structure("SelectItem,ThisIsReference");
	FillPropertyValues(Data,ReportItem);
	Data.Insert("Details", DetailsCell);
	Data.Insert("Value", IndicatorValue[0].Value);
	
	AddDescriptionOfReportBlock(Parameters, ReportItem, Data);
	
EndProcedure

Function PrepareTableData(TableTree, Parameters)
	
	ThisIsArbitrary = TableTree.ItemKind = Parameters.ItemsKinds.ComplexTable;
	TableIndicatorsInColumns = TableTree.ItemKind = Parameters.ItemsKinds.TableIndicatorsInColumns;
	TableDetails = TableDetails(ThisIsArbitrary, TableIndicatorsInColumns);
	TableDetails.Insert("ItemsKinds", Parameters.ItemsKinds);
	TableDetails.Insert("ReportLanguage", Parameters.ReportLanguage);
	
	TreeOfHorizontalTotals = TableDetails.ColumnTree.Copy();
	FillInTableDescription(TableTree, TableDetails, Parameters);
	
	IndicatorValues = TableDetails.IndicatorValues;
	For Each Dimension In TableDetails.RowDimensions Do
		If IndicatorValues.Columns.Find(Dimension) = Undefined Then
			IndicatorValues.Columns.Add(Dimension);
		EndIf;
	EndDo;
	For Each Dimension In TableDetails.TableMeasurements Do
		If IndicatorValues.Columns.Find(Dimension) = Undefined Then
			IndicatorValues.Columns.Add(Dimension);
		EndIf
	EndDo;
	If ThisIsArbitrary Then
		IndicatorValues.Columns.Add("TableRow");
	EndIf;
	If TableIndicatorsInColumns Then
		IndicatorValues.Columns.Add("StartDate");
		IndicatorValues.Columns.Add("EndDate");
	EndIf;
	
	SelectionOfIndicators = TableMetricValues(Parameters, TableDetails);
	GenerateTreeOfHorizontalTotals(TableDetails.ColumnTree, SelectionOfIndicators, TableDetails, TreeOfHorizontalTotals);
	DetermineCompositionOfOperandsOfHorizontalTotals(TreeOfHorizontalTotals, TableDetails);
	
	Indicators = TableDetails.Indicators;
	For Each Factor In Indicators Do
		
		IndicatorValue_ = Factor.Value; // See DescriptionIndicator
		TableDetails.CurrentIndicator = IndicatorValue_.LongDesc;
		If TableDetails.ThisIsArbitrary Then
			TableDetails.IndicatorLine_1 = IndicatorValue_.String;
			TableDetails.ColumnOfFactor = Factor.Value.Column;
		EndIf;
		Filter = New Structure("Factor", Factor.Key);
		IndicatorValue = SelectionOfIndicators.Copy(Filter);
		
		// Let's add columns of row groupings to the indicator table
		If ThisIsArbitrary Then
			VerticalDimensions = TableDetails.VerticalDimensions[IndicatorValue_.String];
		Else
			VerticalDimensions = TableDetails.VerticalDimensions[IndicatorValue_.LongDesc.ReportItem];
		EndIf;
		
		If ThisIsArbitrary Then
			LoadMetricValuesInColumn(IndicatorValue, TableDetails);
			LoadMetricValuesIntoString(IndicatorValue, VerticalDimensions, TableDetails, Parameters.ReportPeriod);
		ElsIf TableIndicatorsInColumns Then
			LoadMetricValuesInColumn(IndicatorValue, TableDetails);
			CalculateHorizontalTotals(TableDetails);
		Else
			LoadMetricValuesIntoString(IndicatorValue, VerticalDimensions, TableDetails, Parameters.ReportPeriod);
		EndIf;
		
	EndDo;
	
	// Calculate row totals
	TreeOfVerticalTotals = TableDetails.StringTree.Copy(); // ValueTable
	TreeOfVerticalTotals.Rows.Clear();
	NumberType = New TypeDescription("Number");
	For Each Name In TableDetails.Resources Do
		TreeOfVerticalTotals.Columns.Add(Name, NumberType);
		TreeOfVerticalTotals.Columns.Add(Name + "_Accuracy", Common.TypeDescriptionNumber(2));
	EndDo;
	GenerateTreeOfVerticalTotals(TableDetails.StringTree, TableDetails, TreeOfVerticalTotals);
	TableDetails.Insert("StringTree", TreeOfVerticalTotals);
	
	// We will return only the necessary
	DataToPrint = PrintTableData();
	FillPropertyValues(DataToPrint, TableDetails);
	Return DataToPrint;
	
EndFunction

Function TableMetricValues(Parameters, TableDetails)
	
	IndicatorValues = TableDetails.IndicatorValues; // ValueTable
	IndicatorParameters = ParametersForObtainingMetric(Parameters, TableDetails);
	SelectionOfIndicators = Undefined;
	For Each Factor In TableDetails.Indicators Do
		
		IndicatorValue_ = Factor.Value; // See DescriptionIndicator
		IndicatorParameters.Factor = IndicatorValue_.LongDesc;
		If Factor.Value.Property("ExtDimension") Then
			IndicatorParameters.ExtDimension = Factor.Value.ExtDimension;
		Else
			IndicatorParameters.ExtDimension = New Structure;
		EndIf;
		
		If TableDetails.Property("ExtDimension") Then
			For Each ExtdimensionOfReport  In TableDetails.ExtDimension Do
				
			ExtdimensionStructureForQuery = New Structure;
			ExtdimensionStructureForQuery.Insert("Kind",           ExtdimensionOfReport.Value.ExtDimensionType);
			ExtdimensionStructureForQuery.Insert("HasSettings", ExtdimensionOfReport.Value.HasSettings);
			ExtdimensionStructureForQuery.Insert("Filter",         ExtdimensionOfReport.Value.AdditionalSelection);
			ExtdimensionStructureForQuery.Insert("Description",  ExtdimensionOfReport.Value.NameForPrinting);
				
			IndicatorParameters.ExtDimension.Insert(ExtdimensionOfReport.Key, ExtdimensionStructureForQuery);
			EndDo; 
		EndIf;
		
		IndicatorValue = ReportMetricValue(IndicatorParameters);
		If IndicatorParameters.Property("CalculationError") Then
			IndicatorParameters.Delete("CalculationError");
		EndIf;
		
		If SelectionOfIndicators = Undefined Then
			SelectionOfIndicators = New ValueTable;
		EndIf;
		For Each IndicatorValueColumn In IndicatorValue.Columns Do
			If SelectionOfIndicators.Columns.Find(IndicatorValueColumn.Name) = Undefined Then
				If StrFind(IndicatorValueColumn.Name, "Dimension") > 0 Then 
					SelectionOfIndicators.Columns.Add(IndicatorValueColumn.Name, New TypeDescription);
				Else
					SelectionOfIndicators.Columns.Add(IndicatorValueColumn.Name, IndicatorValueColumn.ValueType);
				EndIf;
			EndIf;
		EndDo; 
		TMCommonUse.AddRowsToTable(SelectionOfIndicators, IndicatorValue);
		
		// Let's add columns of row groupings to the indicator table
		If TableDetails.ThisIsArbitrary Then
			VerticalDimensions = TableDetails.VerticalDimensions[IndicatorValue_.String];
		Else
			VerticalDimensions = TableDetails.VerticalDimensions[IndicatorValue_.LongDesc.ReportItem];
		EndIf;
		
		If ValueIsFilled(VerticalDimensions) Then
			For Each Group In VerticalDimensions Do
				If IndicatorValues.Columns.Find(Group.Key) = Undefined Then
					IndicatorValues.Columns.Add(Group.Key);
					SelectionOfIndicators.Columns.Add(Group.Key);
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
	If SelectionOfIndicators = Undefined Then
		
		ReportIntervals = IndicatorParameters.ReportIntervals.Copy();
		Dimensions = IndicatorParameters.Dimensions;
		SelectionOfIndicators = EmptyMetricValue(ReportIntervals, Dimensions);
		
	Else
		
		ColumnsNames = "";
		For Each Column In SelectionOfIndicators.Columns Do
			ColumnsNames = ColumnsNames + Column.Name + ",";
		EndDo;
		StringFunctionsClientServer.DeleteLastCharInString(ColumnsNames, 1);
		SelectionOfIndicators.GroupBy(ColumnsNames);
		
		// For empty indicators, fill in the measurements so that an extra empty column is not displayed
		EmptyMetrics = SelectionOfIndicators.FindRows(New Structure("EmptyValue", True));
		DimensionValues = SelectionOfIndicators.Copy(New Structure("EmptyValue", False));
		DimensionValues.GroupBy(StrConcat(TableDetails.TableMeasurements, ","));
		If DimensionValues.Count() > 0 Then
			For Each EmptyMetric In EmptyMetrics Do
				For Each Dimension In TableDetails.TableMeasurements Do
					EmptyMetric[Dimension] = DimensionValues[0][Dimension];
				EndDo;
			EndDo;
		EndIf;
		SelectionOfIndicators.Columns.Delete("EmptyValue");
		
		SortingLine = "";
		For Each Period In Parameters.ReportPeriod.Periodicity Do
			If ValueIsFilled(Period.Periodicity) Then
				SortingLine = SortingLine + ?(IsBlankString(SortingLine),"",",")
				+ Period.ColumnName +" "+Period.Sort;
			EndIf;
		EndDo;
		If SortingLine <> "" Then
			SelectionOfIndicators.Sort(SortingLine);
		EndIf;
		
	EndIf;
	
	Return SelectionOfIndicators;
	
EndFunction

// Fills in the report table structure.
// From the table tree, recursively retrieves the parameters necessary for building the table.
// Parameters:
//  TableTree - ValueTree - 
//  TableItems - See TableDetails
//  Parameters - Structure - report construction parameters:
//   * ItemsKinds - Structure - the types of elements are listed:
//     ** Key - String - name of the element type.
//     ** Value - EnumRef.FinancialReportItemKinds - 
//  TheseAreColumns - Boolean - Flag for report columns
//
Procedure FillInTableDescription(TableTree, TableItems, Parameters, TheseAreColumns = False)
	
	ThisIsRelatedGroup = False;
	ItemsKinds = Parameters.ItemsKinds;
	Indicators = TableItems.Indicators;
	
	If TableItems.ThisIsArbitrary Then
		CellsSettings = TableTree.Rows.Find(Enums.FinancialReportItemKinds.CellsSettings, "ItemKind");
		If CellsSettings <>  Undefined Then
			ArbitraryTableIndicators(CellsSettings, TableItems, Parameters, TheseAreColumns);
		EndIf;
	EndIf;
	LinkedItems1 = TableTree.Rows.UnloadColumn("LinkedItem1");
	RelatedReports = Common.ObjectsAttributesValues(LinkedItems1, "Owner");
	For Each Item In TableTree.Rows Do
		
		ThisIsIndicator = ThisIsIndicator(Item.ItemKind, ItemsKinds, Item.ThisIsReference);
		ItemID = ItemID(Item) + Parameters.AdditionalSuffix;
		AddedNewLevel = False;
		
		If Item.ItemKind = ItemsKinds.Dimension Then
			
			AddDimensionTableElement(TableItems, Item, Parameters.AdditionalSuffix, TheseAreColumns, ItemsKinds, Parameters.TableType);
			AddedNewLevel = True;
			
		ElsIf Item.ItemKind = ItemsKinds.Group Then
			
			If Item.ThisIsReference Then// follow the link to get the original tree
				LinkedReport = RelatedReports[Item.LinkedItem1];
				RelatedTree = UpdateTheReportTree(LinkedReport, Item.LinkedItem1);
				If RelatedTree.Rows.Count() > 0 Then
					GroupDetails = RelatedTree.Rows[0];
					Parameters.AdditionalSuffix = Parameters.AdditionalSuffix + "X";
					// Rough loop control
					If GroupDetails.ReportKind = Parameters.ReportKind Then
						Continue;
					EndIf;
					Item = GroupDetails;
					ThisIsRelatedGroup = True;
					ItemID = ItemID(Item) + Parameters.AdditionalSuffix;
				Else
					Continue;
				EndIf;
			EndIf;// ThisIsReference
			AddToOutputTree(TableItems, Item, ItemID);
			TableItems.CurGroupings.Insert(ItemID, Item.ReportItem);
			AddedNewLevel = True;
			
		ElsIf ThisIsIndicator And Not ThisIsIndicator(Item.Parent.ItemKind, ItemsKinds) Then
			
			If Indicators.Get(Item.ReportItem) = Undefined Then
				Indicators.Insert(Item.ReportItem, New Structure("LongDesc,ExtDimension", Item, New Structure));
			EndIf;
			ExtDimension = Indicators.Get(Item.ReportItem).ExtDimension;
			ExtDimensionNumber = ExtDimension.Count() + 1;
			ExtdimensionSubordinates(TableItems, Item.Rows, ExtDimension, ItemsKinds, ExtDimensionNumber, TheseAreColumns);
			Indicators.Insert(Item.ReportItem, New Structure("LongDesc,ExtDimension", Item, ExtDimension));
			If Not TheseAreColumns Then
				Parents = Common.CopyRecursive(TableItems.CurGroupings);
				TableItems.VerticalDimensions.Insert(Item.ReportItem, Parents);
			EndIf;
			If Item.Parent = Undefined 
					Or Not ThisIsIndicator(Item.Parent.ItemKind, ItemsKinds, Item.Parent.ThisIsReference) Then
				AddToOutputTree(TableItems, Item, ItemID);
				AddedNewLevel = True;
			EndIf;
			
		ElsIf Item.ItemKind = ItemsKinds.TotalByGroup And Not Item.ThisIsReference Then
			
			TotalID = "Total"+ItemID(Item.Parent) + Parameters.AdditionalSuffix;
			AddToOutputTree(TableItems, Item, TotalID, , TableTree.Rows.IndexOf(Item));
			AddedNewLevel = True;
			
		ElsIf Item.ItemKind = ItemsKinds.RowColumn Then
			
			If Not TheseAreColumns Then
				Parents = Common.CopyRecursive(TableItems.CurGroupings);
				TableItems.VerticalDimensions.Insert(Item.ReportItem, Parents);
			EndIf;
			AddToOutputTree(TableItems, Item, ItemID);
			AddedNewLevel = True;
			
		ElsIf Item.ItemKind = ItemsKinds.Columns Then
			
			TheseAreColumns = True;
			TableItems.CurrentLevel = TableItems.ColumnTree.Rows;
			
		ElsIf Item.ItemKind = ItemsKinds.Rows Then
			
			TheseAreColumns = False;
			TableItems.CurrentLevel = TableItems.StringTree.Rows;
			
		EndIf;
		
		If Item.ItemKind <> ItemsKinds.CellsSettings And Item.Rows.Count() Then
			FillInTableDescription(Item, TableItems, Parameters, TheseAreColumns);
		EndIf;
		
		If Item.ItemKind = ItemsKinds.Group And ThisIsRelatedGroup Then
			Parameters.AdditionalSuffix = Left(Parameters.AdditionalSuffix,StrLen(Parameters.AdditionalSuffix)-1);
		EndIf;
		
		If Item.ItemKind = ItemsKinds.Dimension Or Item.ItemKind = ItemsKinds.Group Then
			TableItems.CurGroupings.Delete(ItemID);
		EndIf;
		
		If AddedNewLevel And ValueIsFilled(TableItems.CurrentParent) Then
			Parent = TableItems.CurrentParent.Parent;
			TableItems.CurrentParent = Parent;
			If Parent = Undefined And TheseAreColumns Then
				CurrentLevel = TableItems.ColumnTree.Rows;
			ElsIf Parent = Undefined And Not TheseAreColumns Then
				CurrentLevel = TableItems.StringTree.Rows;
			Else
				CurrentLevel = Parent.Rows;
			EndIf;
			TableItems.CurrentLevel = CurrentLevel;
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	SelectingIndicator - ValueTable - LongDesc:
// * StartDate - Date -
// * EndDate - Date -
Procedure LoadMetricValuesInColumn(SelectingIndicator, TableDetails)
	
	Filter = New Structure("ReportItem", TableDetails.CurrentIndicator.ReportItem) ;
	Columns = TableDetails.ReportColumns.FindRows(Filter);
	If Columns.Count() = 0 Then
		Return;
	EndIf;
	
	If TableDetails.ResourceString_ = Undefined Then
		TableDetails.ResourceString_ = StrConcat(TableDetails.Resources,",");
	EndIf;
	
	IndicatorValues_2 = TableDetails.IndicatorValues.CopyColumns();
	PeriodsOfValues = New Map;
	
	For Each Column In Columns Do 
		
		If ValueIsFilled(Column.Filter) Then
			ColumnValues_ = SelectingIndicator.FindRows(Column.Filter); 
		Else
			ColumnValues_ = SelectingIndicator;
		EndIf;
		
		For Each Cell In ColumnValues_ Do
			Period = New Structure("StartDate,EndDate", Cell.StartDate, Cell.EndDate);
			PeriodsOfValues.Insert(Column.ColumnName, Period);
			
			NewRowOfValues = IndicatorValues_2.Add();
			FillPropertyValues(NewRowOfValues, Cell);
			FillPropertyValues(NewRowOfValues, TableDetails.CurrentIndicator);
			NewRowOfValues[Column.ColumnName] = Cell.Value;
			For Each Dimension In TableDetails.RowDimensions Do
				ReportLineID_ = Cell[Dimension];
				FillInCellDecryption(ReportLineID_, Column, TableDetails, PeriodsOfValues);
			EndDo;
			For Each Dimension In TableDetails.TableMeasurements Do
				ReportLineID_ = Cell[Dimension];
				FillInCellDecryption(ReportLineID_, Column, TableDetails, PeriodsOfValues);
			EndDo;
		EndDo;
	EndDo;
	
		Group = "StartDate,EndDate";
		For Each Dimension In TableDetails.TableMeasurements Do
			Group = Group + "," + Dimension;
		EndDo;
		LoadIntoValueTable(IndicatorValues_2, TableDetails.IndicatorValues);
		
		CurrentColumn = TableDetails.ColumnTree.Rows.Find(TableDetails.CurrentIndicator.ReportItem, "ReportItem");
		If CurrentColumn <> Undefined Then
			For Each SubordinateColumn In CurrentColumn.Rows Do
				TableDetails.CurrentIndicator = SubordinateColumn;
				LoadMetricValuesInColumn(SelectingIndicator, TableDetails);
			EndDo;
			TableDetails.CurrentIndicator = CurrentColumn;
		EndIf;
	
EndProcedure

// Parameters:
// 	SelectingIndicator - ValueTable - LongDesc:
// * StartDate - Date -
// * EndDate - Date -
Procedure LoadMetricValuesIntoString(SelectingIndicator, DimensionsOfIndicator, TableDetails, ReportPeriod)
	
	Filter = New Structure("TotalLevel", -2);
	DetailedColumns = TableDetails.ReportColumns.FindRows(Filter);
	PeriodsOfValues = New Map;
	IndicatorValues_2 = TableDetails.IndicatorValues.CopyColumns();
	
	ThisIndicator = TableDetails.CurrentIndicator.ReportItem;
	ThisIsRemainder = False;
	IndicatorTotalType = FinancialReportingServer.ValueOfAdditionalProps(Undefined, "TotalType", ThisIndicator.ItemKindAttributes);
	If IndicatorTotalType = Enums.TypesOfTotals.Balance_ Or IndicatorTotalType = Enums.TypesOfTotals.Balance_Dr 
				Or IndicatorTotalType = Enums.TypesOfTotals.Balance_Cr Then
		ThisIsRemainder = True;
	EndIf;
	DescriptionIndicator = TableDetails.Indicators[ThisIndicator];
	
	StandardColumns = "RowCode,Note,Factor,Value,EndDate";
	
	// Fill in the detailed columns of the row
	For Each Column In DetailedColumns Do
		
		DataOverPeriod = False;
		
		If TableDetails.TableIndicatorsInColumns Then 
			
			IndicatorColumns = StandardColumns;
			For Each FilterElement In Column.Filter Do
				IndicatorColumns = IndicatorColumns + "," + FilterElement.Key;
				If TypeOf(FilterElement.Value) = Type("Date") Then
					IndicatorColumns = IndicatorColumns + ",StartDate";
					DataOverPeriod = True;
				EndIf;
			EndDo;
			If DescriptionIndicator <> Undefined And DescriptionIndicator.Property("ExtDimension") Then
				For Each ExtdimensionOfIndicator In DescriptionIndicator.ExtDimension Do
					If StrFind(IndicatorColumns, ","+  ExtdimensionOfIndicator.Key) = 0 Then
						IndicatorColumns = IndicatorColumns + "," + ExtdimensionOfIndicator.Key;
					EndIf;
				EndDo; 
			EndIf;
			
			If ValueIsFilled(Column.Filter) Then
				SamplingByIndicatorColumns = SelectingIndicator.Copy(Column.Filter, IndicatorColumns);
			Else
				SamplingByIndicatorColumns = SelectingIndicator.Copy(, IndicatorColumns);
			EndIf;
			
			If Not SamplingByIndicatorColumns.Count() Then
				Continue;
			EndIf;
			
			If ThisIsRemainder Or (Not ThisIsRemainder And DataOverPeriod) Then
				SamplingByIndicatorColumns.Sort("EndDate Desc"); 
				SelectionByDate_1 = New Structure("EndDate", SamplingByIndicatorColumns[0].EndDate);
				SamplingByIndicatorColumns = SamplingByIndicatorColumns.Copy(SelectionByDate_1);
			EndIf;
			SamplingByIndicatorColumns.GroupBy(StrReplace(IndicatorColumns, ",Value", ""), "Value");
			
		Else
			
			If ValueIsFilled(Column.Filter) Then
				SamplingByIndicatorColumns = SelectingIndicator.FindRows(Column.Filter);
			Else
				SamplingByIndicatorColumns = SelectingIndicator;
			EndIf;
			
		EndIf;      
			
		FillInDecryption = False;
		
		For Each Cell In SamplingByIndicatorColumns Do
			
			Period = PeriodDetails(Cell.StartDate, Cell.EndDate);
			PeriodsOfValues.Insert(Column.ColumnName, Period);
			
			NewRowOfValues = IndicatorValues_2.Add();
			FillPropertyValues(NewRowOfValues, Cell);
			FillPropertyValues(NewRowOfValues, TableDetails.CurrentIndicator);
			If TableDetails.ThisIsArbitrary And Column.ReportItem = TableDetails.ColumnOfFactor
				Or Not TableDetails.ThisIsArbitrary Then
				NewRowOfValues[Column.ColumnName] = Cell.Value;
				FillInDecryption = True;
			EndIf;
		EndDo;
		
		If FillInDecryption Then
			If TableDetails.ThisIsArbitrary Then
				DetailsData = TableDetails.IndicatorLine_1;
			Else
				DetailsData = ThisIndicator;
			EndIf;
			FillInCellDecryption(DetailsData, Column, TableDetails, PeriodsOfValues);
		EndIf;
	EndDo;
	
	If TableDetails.ResourceString_ = Undefined Then
		TableDetails.ResourceString_ = StrConcat(TableDetails.Resources, ",");
	EndIf;
	
	Group = "ReportItem,NameForPrinting,ReportRowCode,Note";
	For Each Dimension In TableDetails.RowDimensions Do
		Group = Group + "," + Dimension;
	EndDo;
	For Each Dimension In TableDetails.TableMeasurements Do
		Group = Group + "," + Dimension;
	EndDo;
	If ValueIsFilled(DimensionsOfIndicator) Then
		For Each DimensionValue_1 In DimensionsOfIndicator Do
			Group = Group + "," + DimensionValue_1.Key;
			IndicatorValues_2.FillValues(DimensionValue_1.Value, DimensionValue_1.Key);
		EndDo;
	EndIf;
	IndicatorValues_2.GroupBy(Group, TableDetails.ResourceString_);
	If TableDetails.ThisIsArbitrary Then
		IndicatorValues_2.Columns.Add("TableRow");
		IndicatorValues_2.FillValues(TableDetails.IndicatorLine_1, "TableRow");
	EndIf;
	
	// Calculate line totals
	Filter = New Structure("TotalLevel");
	TotalLevel = TableDetails.TotalColumnLevels;
	For Cnt = 0 To TableDetails.TotalColumnLevels Do
		
		Filter.TotalLevel = TotalLevel;
		TotalColumns_ = TableDetails.ReportColumns.FindRows(Filter);
		For Each Column In TotalColumns_ Do
			For Each ValuesRow In IndicatorValues_2 Do
				ValuesRow[Column.ColumnName] = LineSummary(ValuesRow, Column, PeriodsOfValues);
			EndDo;
			If IndicatorValues_2.Count() Then
				FillInCellDecryption(ThisIndicator, Column, TableDetails, PeriodsOfValues);
			EndIf;
		EndDo;
		TotalLevel = TotalLevel - 1;
		
	EndDo;
	
	LoadIntoValueTable(IndicatorValues_2, TableDetails.IndicatorValues);
	
EndProcedure

Procedure CalculateHorizontalTotals(TableDetails)
	
	IndicatorValues = TableDetails.IndicatorValues;
	PeriodsOfValues = New Map;
	
	Filter = New Structure("TotalLevel");
	TotalLevel = TableDetails.TotalColumnLevels;
	For Cnt = 0 To TableDetails.TotalColumnLevels Do
		
		Filter.TotalLevel = TotalLevel;
		TotalColumns_ = TableDetails.ReportColumns.FindRows(Filter);
		For Each Column In TotalColumns_ Do
			If Not Column.Operands.Count() Then
				Continue;
			EndIf;
			For Each ValuesRow In IndicatorValues Do
				Period = New Structure("StartDate,EndDate",ValuesRow.StartDate, ValuesRow.EndDate);
				PeriodsOfValues.Insert(Column.ColumnName, Period);
				ValuesRow[Column.ColumnName] = LineSummary(ValuesRow, Column, PeriodsOfValues);
			EndDo;
		EndDo;
		TotalLevel = TotalLevel - 1;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	ColumnTree - See DescriptionOfReportColumnTree
// 	FetchingValues - ValueTable, Undefined - LongDesc:
// 	TableDetails - See TableDetails
// 	ReportColumn - See DescriptionOfReportColumnTree
// 	Filter - Structure - report selection
// 	GroupColumns - String 
//
Procedure GenerateTreeOfHorizontalTotals(ColumnTree, FetchingValues, TableDetails, ReportColumn, Filter = Undefined, Val GroupColumns = "")
	
	If Not ValueIsFilled(Filter) Then
		Filter = New Structure;
		TableDetails.ColumnNumber = 1;
		Data = FetchingValues.Copy();
	Else
		Data = FetchingValues.Copy(Filter);
	EndIf;
	
	ItemsKinds = TableDetails.ItemsKinds;
	PresentationPeriodName = Enums.PeriodPresentation.Description;
	
	For Each Column In ColumnTree.Rows Do
		
		If Column.ItemKind = ItemsKinds.Group Then
			
			NewReportColumn = ReportColumn.Rows.Add();
			FillPropertyValues(NewReportColumn, Column);
			GenerateTreeOfHorizontalTotals(Column, FetchingValues, TableDetails, NewReportColumn, Filter, GroupColumns);
			If NewReportColumn <> ReportColumn And TypeOf(ReportColumn) = Type("ValueTreeRow") Then
				ReportColumn.SubordinateElements = ReportColumn.SubordinateElements + NewReportColumn.SubordinateElements;
			EndIf;
			
		ElsIf Column.ItemKind = ItemsKinds.TotalByGroup And Column.DisplayItemTitle Then
			
			If TypeOf(ReportColumn) = Type("ValueTreeRow") Then
				ReportColumn.SubordinateElements = ReportColumn.SubordinateElements + 1;
			EndIf;
			NewReportColumn = ReportColumn.Rows.Add();
			FillPropertyValues(NewReportColumn, Column);
			ColumnName = Column.ItemID + "_" + String(TableDetails.ColumnNumber);
			AddTableColumn(ColumnName, NewReportColumn, Filter, TableDetails, True);
			
		ElsIf Column.ItemKind = ItemsKinds.Dimension Then
			
			If Not  Filter.Property("Factor") And TableDetails.TableIndicatorsInColumns Then
				ArrayOfIndicators = New Array;
				SubordinateIndicatorsOfExtdimension(TableDetails, Column, ItemsKinds, ArrayOfIndicators);
				If ArrayOfIndicators.Count() Then
					Data.Clear();
					For Each ExtdimensionRate In ArrayOfIndicators Do
						FilterByIndicator = New Structure(New FixedStructure(Filter));
						FilterByIndicator.Insert("Factor", ExtdimensionRate);
						TMCommonUse.AddRowsToTable(Data, FetchingValues.Copy(FilterByIndicator) );
					EndDo; 
				EndIf;
			EndIf;
			
			CurDimensionColumns = GroupColumns + ?(IsBlankString(GroupColumns),"",",") + Column.ColumnName;
			DimensionData_ = Data.Copy();
			DimensionData_.GroupBy(CurDimensionColumns);
			For Each ColumnData In DimensionData_ Do
				
				DimensionValue = ColumnData[Column.ColumnName];
				NewReportColumn = ReportColumn.Rows.Add();
				FillPropertyValues(NewReportColumn, Column);
				If Column.PeriodPresentation = PresentationPeriodName Then
					NewReportColumn.NameForPrinting = FinancialReportingServer.IntervalPresentation(
																	DimensionValue,Column.Periodicity,TableDetails.ReportLanguage);
				Else
					NewReportColumn.NameForPrinting = Format(DimensionValue, "L=" + TableDetails.ReportLanguage + "; DLF=DD");
				EndIf;
				If Column.Rows.Count() Then
					Filter.Insert(Column.ColumnName, DimensionValue);
					GenerateTreeOfHorizontalTotals(Column, FetchingValues, TableDetails, NewReportColumn, Filter, CurDimensionColumns);
					If TypeOf(ReportColumn) = Type("ValueTreeRow") Then
						ReportColumn.SubordinateElements = ReportColumn.SubordinateElements + NewReportColumn.SubordinateElements;
					EndIf;
					Filter.Delete(Column.ColumnName);
					
				Else
					If TypeOf(ReportColumn) = Type("ValueTreeRow") Then
						ReportColumn.SubordinateElements = ReportColumn.SubordinateElements + 1;
					EndIf;
					ColumnName = Column.ColumnName + String(TableDetails.ColumnNumber);
					Filter.Insert(Column.ColumnName, DimensionValue);
					AddTableColumn(ColumnName, NewReportColumn, Filter, TableDetails);
					Filter.Delete(Column.ColumnName);
					
				EndIf;
				
			EndDo;// by the unique values of the current measurement
			
		Else
			
			NewReportColumn = ReportColumn.Rows.Add();
			FillPropertyValues(NewReportColumn, Column);
			
			ColumnName = Column.ItemID + "_" + String(TableDetails.ColumnNumber);
			AddTableColumn(ColumnName, NewReportColumn, Filter, TableDetails);
			
			If Not TableDetails.ThisIsArbitrary Then
				Filter.Insert("Factor", Column.ReportItem);
			EndIf;
			GenerateTreeOfHorizontalTotals(Column, FetchingValues, TableDetails, NewReportColumn, Filter, GroupColumns);
			
			If TypeOf(ReportColumn) = Type("ValueTreeRow") Then
				ReportColumn.SubordinateElements = ReportColumn.SubordinateElements + 1;
			EndIf;
			
			If NewReportColumn.SubordinateElements > 0 Then
				LongDesc = NewReportColumn.LongDesc; 
				LongDesc.ThisIsTotal = True;
			EndIf;
			
			Filter.Delete("Factor");
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	ColumnName - String -
// 	NewReportColumn - See DescriptionOfReportColumnTree
// 	Filter - Undefined, Structure - LongDesc: 
// 	TableDetails - See TableDetails
// 	ThisIsTotal - Boolean - LongDesc
Procedure AddTableColumn(ColumnName, NewReportColumn, Filter, TableDetails, ThisIsTotal = False)
	
	IndicatorValues = TableDetails.IndicatorValues;
	
	NewReportColumn.ColumnName = ColumnName;
	If IndicatorValues.Columns.Find(ColumnName) <> Undefined Then
		Return;
	EndIf;
	
	NumberType = New TypeDescription("Number");
	IndicatorValues.Columns.Add(ColumnName, NumberType, NewReportColumn.NameForPrinting);
	
	ColumnDetails = TableDetails.ReportColumns.Add(); // ValueTableRow - See DescriptionOfReportColumns
	FillPropertyValues(ColumnDetails, NewReportColumn);
	TotalLevel = ?(ThisIsTotal,NewReportColumn.Level() - 1,-2);
	ColumnDetails.TotalLevel = TotalLevel;
	ColumnDetails.ColumnName = ColumnName;
	ColumnDetails.Operands = New Array;
	ColumnDetails.Filter = Common.CopyRecursive(Filter);
	ColumnDetails.ThisIsTotal = ThisIsTotal;
	
	NewReportColumn.LongDesc = ColumnDetails;
	
	TableDetails.Resources.Add(ColumnName);
	TableDetails.TotalColumnLevels = Max(TotalLevel, TableDetails.TotalColumnLevels);
	TableDetails.ColumnNumber = TableDetails.ColumnNumber + 1;
	
EndProcedure

Function FindParentTotal(Val TreeBranch1, ViewOfSummaryElement)
	
	ColumnName = TreeBranch1.ColumnName;
	While ValueIsFilled(TreeBranch1) Do
		Total = TreeBranch1.Rows.Find(ViewOfSummaryElement,"ItemKind");
		If ValueIsFilled(Total) And Total.ColumnName <> ColumnName Then
			Break;
		ElsIf ValueIsFilled(Total) And Total.ColumnName = ColumnName Then
			Total = Undefined;
		EndIf;
		TreeBranch1 = TreeBranch1.Parent;
	EndDo;
	Return Total;
	
EndFunction

Procedure AddTotalOperand(ColumnName, SummaryTree, TableDetails)
	
	HeaderColumn = SummaryTree.Rows.Find(ColumnName,"ColumnName", True);
	Total = FindParentTotal(HeaderColumn, TableDetails.ItemsKinds.TotalByGroup);
	If ValueIsFilled(Total) Then
		SummaryDescription = TableDetails.ReportColumns.Find(Total.ColumnName,"ColumnName");
		If ValueIsFilled(SummaryDescription) Then
			SummaryDescription.Operands.Add(ColumnName);
		EndIf;
	EndIf;
	
EndProcedure

Procedure DetermineCompositionOfOperandsOfHorizontalTotals(SummaryTree, TableDetails)
	
	Filter = New Structure("TotalLevel", -2);
	DetailedColumns = TableDetails.ReportColumns.FindRows(Filter);
	
	For Each Column In DetailedColumns Do
		AddTotalOperand(Column.ColumnName, SummaryTree, TableDetails);
	EndDo;
	
	TotalLevel = TableDetails.TotalColumnLevels;
	For Cnt = 0 To TableDetails.TotalColumnLevels Do
		
		Filter.TotalLevel = TotalLevel;
		SummaryColumns = TableDetails.ReportColumns.FindRows(Filter);
		For Each Column In SummaryColumns Do
			AddTotalOperand(Column.ColumnName, SummaryTree, TableDetails);
		EndDo;
		TotalLevel = TotalLevel - 1;
		
	EndDo;
	
	TableHeader = SummaryTree.Copy();
	TableHeader.Rows.Clear();
	CreateTableHeader(SummaryTree, TableHeader, TableDetails.NumberOfHeaderLevels, TableDetails.TableIndicatorsInColumns);
	TableDetails.Insert("TableHeader", TableHeader);
	
EndProcedure

Procedure CreateTableHeader(SummaryTree, TableHeader, DepthOfEverything = 0, IndicatorsInColumns = False)
	
	For Each Title In SummaryTree.Rows Do
		NewTitle = TableHeader;
		If  Title.DisplayItemTitle Then
			NewTitle = TableHeader.Rows.Add();
			FillPropertyValues(NewTitle, Title);
		ElsIf Title.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup Then
			NewTitle = TableHeader.Rows.Add();
			FillPropertyValues(NewTitle, Title);
			NewTitle.NameForPrinting = "";
		EndIf;
		CreateTableHeader(Title, NewTitle, DepthOfEverything, IndicatorsInColumns);
		If NewTitle.Rows.Count() = 0 And TypeOf(NewTitle) = Type("ValueTreeRow") Then
			DepthOfEverything = Max(DepthOfEverything, NewTitle.Level());
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInCellDecryption(ReportLineID_,ColumnData, TableDetails, ColumnPeriods = Undefined)
	
	DecryptingString = TableDetails.Details[ReportLineID_];
	If DecryptingString = Undefined Then
		DecryptingString = New Map;
		TableDetails.Details.Insert(ReportLineID_, DecryptingString);
	EndIf;
	
	DetailsCell = DecryptingString[ColumnData.ColumnName];
	If DetailsCell = Undefined Then
		DetailsCell = New Structure("Factor, StartDate, EndDate, ItemKind, GLAccount_, NonMonetaryItem, Filter, Accuracy");
		FillPropertyValues(DetailsCell, TableDetails.CurrentIndicator);
		DetailsCell.Factor = TableDetails.CurrentIndicator.ReportItem;
		DecryptingString.Insert(ColumnData.ColumnName, DetailsCell);
	EndIf;
	FillPropertyValues(DetailsCell, ColumnData);
	
	If ColumnPeriods <> Undefined And ColumnPeriods[ColumnData.ColumnName] <> Undefined Then
		FillPropertyValues(DetailsCell, ColumnPeriods[ColumnData.ColumnName]);
	EndIf;
	
EndProcedure

Procedure GenerateTreeOfVerticalTotals(StringTree, TableDetails, ReportRow, Filter = Undefined)
	
	ItemsKinds = TableDetails.ItemsKinds;
	PresentationPeriodName = Enums.PeriodPresentation.Description;
	
	For Each String In StringTree.Rows Do
		
		If Not ValueIsFilled(Filter) Then
			Filter = New Structure;
			If TableDetails.ThisIsArbitrary And String.ItemKind = ItemsKinds.RowColumn Then
				Filter.Insert("TableRow", String.ReportItem);
				Data = TableDetails.IndicatorValues.Copy(Filter);
			Else
				Data = TableDetails.IndicatorValues.Copy();
			EndIf;
		Else
			If TableDetails.ThisIsArbitrary And String.ItemKind = ItemsKinds.RowColumn Then
				Filter.Insert("TableRow", String.ReportItem);
			EndIf;
			Data = TableDetails.IndicatorValues.Copy(Filter);
		EndIf;
		
		If String.ItemKind = ItemsKinds.Group Then
			
			NewLineOfReport = ReportRow.Rows.Add();
			FillPropertyValues(NewLineOfReport, String);
			GenerateTreeOfVerticalTotals(String, TableDetails, NewLineOfReport, Filter);
			CalculateVerticalTotals(NewLineOfReport, TableDetails);
			
		ElsIf String.ItemKind = ItemsKinds.TotalByGroup And String.DisplayItemTitle And Not String.ThisIsReference Then
			
			NewLineOfReport = ReportRow.Rows.Add();
			FillPropertyValues(NewLineOfReport, String);
			
		ElsIf String.ItemKind = ItemsKinds.Dimension Then
			
			If Not  Filter.Property("ReportItem") And Not TableDetails.TableIndicatorsInColumns Then
				ArrayOfIndicators = New Array;
				SubordinateIndicatorsOfExtdimension(TableDetails, String, ItemsKinds, ArrayOfIndicators);
				If ArrayOfIndicators.Count() Then
					Data.Clear();
					For Each ExtdimensionRate In ArrayOfIndicators Do
						FilterByIndicator = New Structure(New FixedStructure(Filter));
						FilterByIndicator.Insert("ReportItem", ExtdimensionRate);
						TMCommonUse.AddRowsToTable(Data, TableDetails.IndicatorValues.Copy(FilterByIndicator) );
					EndDo; 
				EndIf;
			EndIf;
			
			If String.Rows.Count() Then
				Data.GroupBy(String.ColumnName);
			Else
				Data.GroupBy(String.ColumnName, TableDetails.ResourceString_);
			EndIf;
			If ValueIsFilled(String.Sort) Then
				Data.Sort(String.ColumnName + " " + String.Sort);
			Else
				Data.Sort(String.ColumnName);
			EndIf;
			
			If ValueIsFilled(String.Accuracy) Then
				Accuracy = String.Accuracy;
			Else
				Accuracy = 0;
			EndIf;
			
			For Each RowData In Data Do
				
				DimensionValue = RowData[String.ColumnName];
				ExtDimensionType = String.ExtDimensionType;// Structure
				If ValueIsFilled(String.ExtDimensionType) 
							And  Not ExtDimensionType.ValueType.ContainsType(TypeOf(DimensionValue))  Then
					Continue;
				EndIf;
				
				NewLineOfReport = ReportRow.Rows.Add();
				FillPropertyValues(NewLineOfReport, String);
				FillPropertyValues(NewLineOfReport, RowData);
				NewLineOfReport.Accuracy = Accuracy;
				If TableDetails.ThisIsArbitrary Then
					FillInEachRowOfArbitraryTable(NewLineOfReport, TableDetails, String.ReportItem);
				EndIf;
				NewLineOfReport.DimensionValue_1 = DimensionValue;
				If String.PeriodPresentation = PresentationPeriodName Then
					NewLineOfReport.NameForPrinting = FinancialReportingServer.IntervalPresentation(
																	DimensionValue,String.Periodicity,TableDetails.ReportLanguage);
				Else
					NewLineOfReport.NameForPrinting = Format(DimensionValue, "L=" + TableDetails.ReportLanguage + "; DLF=DD");
				EndIf;
				If String.Rows.Count() Then
					Filter.Insert(String.ColumnName, DimensionValue);
					GenerateTreeOfVerticalTotals(String, TableDetails, NewLineOfReport, Filter);
					CalculateVerticalTotals(NewLineOfReport, TableDetails);
					Filter.Delete(String.ColumnName);
				EndIf;
				
			EndDo;
			
			If Not ValueIsFilled(Filter) Then
				Data = TableDetails.IndicatorValues.Copy();
			Else
				Data = TableDetails.IndicatorValues.Copy(Filter);
			EndIf;
			
		Else
			
			NewLineOfReport = ReportRow.Rows.Add();
			FillPropertyValues(NewLineOfReport, String);
			If TableDetails.ThisIsArbitrary Then
				FillInEachRowOfArbitraryTable(NewLineOfReport, TableDetails, String.ReportItem);
			EndIf;
			If String.ItemKind <> ItemsKinds.RowColumn Then
				Filter.Insert("ReportItem", String.ReportItem);
			EndIf;
			GenerateTreeOfVerticalTotals(String, TableDetails, NewLineOfReport, Filter);
			CalculateVerticalTotals(NewLineOfReport, TableDetails);
			FillTableResources(NewLineOfReport, Data, TableDetails);
			
			If Filter  <> Undefined Then
				Filter.Delete("ReportItem");
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillTableResources(NewLineOfReport, ResourcesValues, TableDetails)
	
	If ResourcesValues.Count() Then
		If TableDetails.ThisIsArbitrary Then
			Filter = New Structure("TableRow", NewLineOfReport.ReportItem);
			RowResources = ResourcesValues.FindRows(Filter);
			If RowResources.Count() Then
				For Each Resource In TableDetails.Resources Do
					NewLineOfReport[Resource] = ColumnSummary_(RowResources, Resource, TableDetails);
				EndDo;
			EndIf;
		Else
			RowResources = ResourcesValues.FindRows(New Structure("ReportItem", NewLineOfReport.ReportItem));
			ArrayOfResources = StrSplit(TableDetails.ResourceString_,",");
			If RowResources.Count() Then
				For Each TableResource In ArrayOfResources Do 
					NewLineOfReport[TableResource] = 0;
					For Each RowResource In RowResources Do
						NewLineOfReport[TableResource] = NewLineOfReport[TableResource]
						+ RowResource[TableResource];
					EndDo;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure CalculateVerticalTotals(NewLineOfReport, TableDetails)
	
	Filter = New Structure("ItemKind,ThisIsReference",TableDetails.ItemsKinds.TotalByGroup,False);
	Rows = NewLineOfReport.Rows.FindRows(Filter);
	TotalByGroup = Undefined;
	If Rows.Count() Then
		TotalByGroup = Rows[0];
	EndIf;
	ReverseSign = 1;
	If TotalByGroup <> Undefined And TotalByGroup.ReverseSign Then
		ReverseSign = -1;
	EndIf;
	
	For Each Name In TableDetails.Resources Do
		TotalValue = ReverseSign * NewLineOfReport.Rows.Total(Name);
		NewLineOfReport[Name] = TotalValue;
		If TotalByGroup <> Undefined Then
			TotalByGroup[Name] = TotalValue;
		EndIf;
	EndDo;
	
EndProcedure

Function LineSummary(OperandValues, SummaryDescription, PeriodsOfValues);
	
	Total = 0;
	For Each Name In SummaryDescription.Operands Do
		Total = Total + OperandValues[Name];
		OperandPeriod = PeriodsOfValues[Name]; // See PeriodDetails
		TotalPeriod = PeriodsOfValues[SummaryDescription.ColumnName]; // See PeriodDetails
		If TotalPeriod = Undefined Then
			PeriodsOfValues.Insert(SummaryDescription.ColumnName, OperandPeriod);
		ElsIf OperandPeriod <> Undefined Then
			TotalPeriod.StartDate = Min(TotalPeriod.StartDate,OperandPeriod.StartDate);
			TotalPeriod.EndDate = Max(TotalPeriod.EndDate,OperandPeriod.EndDate);
		EndIf;
	EndDo;
	Total = ?(SummaryDescription.ReverseSign,-1,1)*Total;
	Return Total;
	
EndFunction

Function ColumnSummary_(TableRows, ColumnName, TableDetails)
	
	Result = 0;
	For Each String In TableRows Do
		Result = Result + String[ColumnName];
	EndDo;
	Return Result;
	
EndFunction

Procedure FillInEachRowOfArbitraryTable(ReportRow, TableDetails, String)
	
	For Each ResourceString_ In TableDetails.Resources Do
		Column = TableDetails.ReportColumns.Find(ResourceString_, "ColumnName");
		If Column = Undefined Then
			Break;
		EndIf;
		Factor = Undefined;
		
		For Each TableIndicator In TableDetails.Indicators Do
			StorageBinLocation = TableIndicator.Value; // See DescriptionIndicator
			If StorageBinLocation.String = String And TableIndicator.Value.Column = Column.ReportItem Then
				Factor =  TableIndicator.Key;
				Break;
			EndIf;
		EndDo;  
		
		If Factor <> Undefined Then
			AccuracyOfIndicator = FinancialReportingServer.ValueOfAdditionalProps(Undefined,"Accuracy", Factor.ItemKindAttributes);
			ReportRow[ResourceString_ + "_Accuracy"] = AccuracyOfIndicator;
		EndIf;
	EndDo; 
	
EndProcedure

Procedure ArbitraryTableIndicators(TableCells, TableItems, Parameters, TheseAreColumns = False)
	
	For Each CellElement In TableCells.Rows Do
		If ThisIsIndicator(CellElement.ItemKind, Parameters.ItemsKinds, CellElement.ThisIsReference) Then
			ReportItem = TableCells.ReportItem; // Structure - 
			StorageBinLocation = ReportItem.TableItems.Find(CellElement.ReportItem,"Item"); 
			If StorageBinLocation <> Undefined Then
				
				LongDesc = DescriptionIndicator(CellElement, StorageBinLocation.String, StorageBinLocation.Column);
				LongDesc.Insert("ExtDimension", New Structure);
				TableItems.Indicators.Insert(CellElement.ReportItem, LongDesc);
				
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure AddDimensionTableElement(TableItems, Item, AdditionalSuffix, TheseAreColumns, ItemsKinds, TableType)
	
	DimensionsTypes = Enums.TypesOfBudgetReportDimensions;
	ItemID = ItemID(Item);
	IsPeriod = Item.DimensionType = DimensionsTypes.Period;
	ThisIsAnExtraDimension = Item.DimensionType = DimensionsTypes.ExtDimension;
	
	If IsPeriod Then
		
		PeriodNames = New Map;
		PeriodNames.Insert(Enums.Periodicity.Day, "DayPeriod");
		PeriodNames.Insert(Enums.Periodicity.Week, "WeekPeriod");
		PeriodNames.Insert(Enums.Periodicity.TenDays, "TenDaysPeriod");
		PeriodNames.Insert(Enums.Periodicity.Month, "MonthPeriod");
		PeriodNames.Insert(Enums.Periodicity.Quarter, "QuarterPeriod");
		PeriodNames.Insert(Enums.Periodicity.HalfYear, "HalfYearPeriod");
		PeriodNames.Insert(Enums.Periodicity.Year, "YearPeriod");
		
		Data = New Structure("Periodicity", Item.Periodicity);
		Data.Insert("OutputIndicatorsOfSimilarPeriodsOfPreviousYears",Item.OutputIndicatorsOfSimilarPeriodsOfPreviousYears);
		Data.Insert("DisplayIndicatorsOfPreviousPeriods",Item.DisplayIndicatorsOfPreviousPeriods);
		Data.Insert("NumberOfPreviousYears",Item.NumberOfPreviousYears);
		Data.Insert("NumberOfPreviousPeriods",Item.NumberOfPreviousPeriods);
		Data.Insert("Presentation",Item.NameForPrinting);
		Data.Insert("Sort", ?(ValueIsFilled(Item.Sort),Item.Sort,"ASC"));
		TableItems.Periodicity.Add(Data);
		ColumnName = String(PeriodNames[Item.Periodicity]);
		Data.Insert("ColumnName", ColumnName);
		If Not TheseAreColumns Then
			TableItems.RowDimensions.Add(ColumnName);
		EndIf;
		
	ElsIf ThisIsAnExtraDimension Then
		
		If TableItems.Property("ExtDimension") Then
			CapExtdimensionNumber = TableItems.ExtDimension.Count() + 1;
		Else
			TableItems.Insert("ExtDimension",New Structure);
			CapExtdimensionNumber = 1;
		EndIf; 
		
		If (TheseAreColumns And TableType = Enums.FinancialReportItemKinds.TableIndicatorsInRows)
					Or (Not TheseAreColumns And TableType = Enums.FinancialReportItemKinds.TableIndicatorsInColumns) Then       
			ColumnName = "DimensionCaps" + CapExtdimensionNumber;
			TableItems.ExtDimension.Insert(ColumnName, Item);
			DimensionData = New Structure("Value, Presentation, Filter", ColumnName, ColumnName, Undefined);
			TableItems.RegisterDimensions.Add(DimensionData);
			TableItems.TableMeasurements.Add(ColumnName);
		Else 
			If TableItems.AnalystDescription[Item] = Undefined Then
				ExtDimension = New Structure();
				ItemArray = New Array;
				ItemArray.Add(Item);
				ExtdimensionSubordinates(TableItems, ItemArray, ExtDimension, ItemsKinds,  1 ,TheseAreColumns);
			EndIf;
			ExtDimensionNumber = TableItems.AnalystDescription[Item].DimensionNumber;
			If Not TableItems.ThisIsArbitrary Then
				ColumnName = "Dimension" + ExtDimensionNumber;
			Else
				ColumnName = ?(TheseAreColumns, "DimensionColumns1", "DimensionLines") + ExtDimensionNumber;
			EndIf;
			If TableItems.RowDimensions.Find(ColumnName) = Undefined Then
				TableItems.RowDimensions.Add(ColumnName);
			EndIf;
		EndIf;
		
	ElsIf Item.DimensionType = DimensionsTypes.AccountingRegisterDimension Then
		
		ColumnName = Item.DimensionName;
		DimensionData = New Structure("Value, Presentation, Filter", ColumnName, Item.NameForPrinting, Undefined);
		FilterValue = Item.AdditionalSelection; //ValueStorage
		Settings = FilterValue.Get();
		If Settings <> Undefined Then
			DimensionData.Filter = Settings.Filter;
		EndIf;
		TableItems.RegisterDimensions.Add(DimensionData);
		TableItems.TableMeasurements.Add(ColumnName);
		
	EndIf;
	
	AddToOutputTree(TableItems, Item, ItemID, ColumnName);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	TableItems - See TableDetails
// 	Item - ValueTreeRow - 
// 	ItemID - String - 
// 	ColumnName - String - 
// 	LocationOfTotal - Number, Undefined - 
Procedure AddToOutputTree(TableItems, Item, ItemID, ColumnName = "", LocationOfTotal = Undefined)
	
	CurrentLevel = TableItems.CurrentLevel; // ValueTreeRowCollection - 
	NewColumn = CurrentLevel.Add();
	FillPropertyValues(NewColumn, Item);
	NewColumn.ItemID = ItemID;
	If Item.ItemKind = TableItems.ItemsKinds.TotalByGroup Then
		If Item.DisplayItemTitle = True Then
			NewColumn.LocationOfTotal = LocationOfTotal;
		EndIf;
		If ValueIsFilled(NewColumn.Parent) Then
			NewColumn.Parent.LocationOfTotal = NewColumn.LocationOfTotal;
		EndIf;
	EndIf;
	
	If Not IsBlankString(ColumnName) Then
		NewColumn.ColumnName = ColumnName;
	EndIf;
	
	TableItems.CurrentLevel = NewColumn.Rows;
	TableItems.CurrentParent = NewColumn;
	
EndProcedure

// Parameters:
// 	ReportParameters - Structure
// 	TableDetails - See TableDetails
// Returns:
// 	Structure -See NewParametersForGettingMetric 
Function ParametersForObtainingMetric(ReportParameters, TableDetails = Undefined)
	
	IndicatorParameters = NewParametersForGettingMetric();
	IndicatorParameters.ReportPeriod = ReportParameters.ReportPeriod;
	IndicatorParameters.FilterReport_ = ReportParameters.Filter;
	IndicatorParameters.ErrorsMessages = ReportParameters.ErrorsMessages;
	IndicatorParameters.Resource = ReportParameters.Resource;
	IndicatorParameters.Insert("ItemsKinds", ReportParameters.ItemsKinds);
	
	If TableDetails <> Undefined Then
		IndicatorParameters.ReportPeriod.Insert("Periodicity", TableDetails.Periodicity);
		IndicatorParameters.Dimensions = TableDetails.RegisterDimensions;
	Else
		IndicatorParameters.ReportPeriod.Insert("Periodicity", New Array);
	EndIf;
	
	IndicatorParameters.ReportIntervals = ReportIntervals(ReportParameters.ReportPeriod);
	
	Return IndicatorParameters;
	
EndFunction

Function FinancialPeriods(Val Periodicity, Val BeginOfPeriod, Val EndOfPeriod, Val MinimumReportDate)
	
	FinancialPeriods = New Array;
	CurEndDateOfPeriod = BeginOfPeriod - 1;
	While CurEndDateOfPeriod > MinimumReportDate Do
		FinancialPeriod = New Structure("BeginOfPeriod, EndOfPeriod");
		FinancialPeriod.BeginOfPeriod = BeginningDateOfPeriod(CurEndDateOfPeriod, Periodicity);
		FinancialPeriod.EndOfPeriod = CurEndDateOfPeriod;
		FinancialPeriods.Add(FinancialPeriod);
		CurEndDateOfPeriod = FinancialPeriod.BeginOfPeriod - 1;
	EndDo;
	
	CurStartDateOfPeriod = BeginOfPeriod;
	While CurStartDateOfPeriod <= EndOfPeriod Do
		FinancialPeriod = New Structure("BeginOfPeriod, EndOfPeriod");
		FinancialPeriod.BeginOfPeriod = CurStartDateOfPeriod;
		FinancialPeriod.EndOfPeriod = EndDateOfNewInterval(CurStartDateOfPeriod, Periodicity, EndOfPeriod);
		FinancialPeriods.Add(FinancialPeriod);
		CurStartDateOfPeriod = FinancialPeriod.EndOfPeriod + 1;
	EndDo;

	Return FinancialPeriods;
	
EndFunction

Function BoundariesOfFinancialPeriod(Val Date, Val FinancialPeriods)
	
	Result = Undefined;
	For Each Period In FinancialPeriods Do
		If Date >= Period.BeginOfPeriod And Date <= Period.EndOfPeriod Then
			Result = Period;
			Break;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

Function EndDateOfNewInterval(Val PeriodDate_, Val Periodicity, Val EndOfPeriod)
	
	PeriodEndDate_ = PeriodDate_;
	If Periodicity = Enums.Periodicity.Month Then
		PeriodEndDate_ = EndOfMonth(PeriodEndDate_);
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		PeriodEndDate_ = AddMonth(PeriodEndDate_, 2);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		PeriodEndDate_ = AddMonth(PeriodEndDate_, 5);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		PeriodEndDate_ = AddMonth(PeriodEndDate_, 11);
	Else
		PeriodEndDate_ = EndOfPeriod;
	EndIf;
	PeriodEndDate_ = EndOfMonth(PeriodEndDate_);
	If PeriodEndDate_ > EndOfPeriod Then
		PeriodEndDate_ = EndOfPeriod;
	EndIf;
	Return PeriodEndDate_;
	
EndFunction

Function DateDifferenceInMonths(Val BeginOfPeriod, Val EndOfPeriod)
	
	Result = 0;
	CurrentDate = BeginOfPeriod;
	While CurrentDate < EndOfPeriod Do
		Result = Result + 1;
		CurrentDate = AddMonth(CurrentDate, 1);
	EndDo;
	
	Return Result;
	
EndFunction

Function ComparativePeriod(BeginOfPeriod, EndOfPeriod, Periodicity, Offset)
	
	Result = New Structure();
	Result.Insert("BeginOfPeriod");
	Result.Insert("EndOfPeriod");
	
	If Periodicity = Enums.Periodicity.Month Then
		Result.BeginOfPeriod = AddMonth(BeginOfPeriod, -Offset);
		Result.EndOfPeriod = AddMonth(EndOfPeriod, -Offset);
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Result.BeginOfPeriod = AddMonth(BeginOfPeriod, -3 * Offset);
		Result.EndOfPeriod = AddMonth(EndOfPeriod, -3 * Offset);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Result.BeginOfPeriod = AddMonth(BeginOfPeriod, -6 * Offset);
		Result.EndOfPeriod = AddMonth(EndOfPeriod, -6 * Offset);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		Result.BeginOfPeriod = AddMonth(BeginOfPeriod, -12 * Offset);
		Result.EndOfPeriod = AddMonth(EndOfPeriod, -12 * Offset);
	Else
		Raise NStr("vi = 'Đối với định kỳ chưa xác định quy tắc nhận kỳ so sánh';
					|ru = 'Для периодичности не определены правила получения сравнительного периода';
					|en = 'Comparison period rules are not defined for the frequency'; fa = 'Comparison period rules are not defined for the frequency';
					|it = 'Per la periodicità non sono indicate regole di ricezione del periodo di comparazione';
					|pl = 'Dla okresowości nie określono reguły uzyskania okresu porównawczego';
					|tr = 'Periyodiklik, karşılaştırmalı sıklık elde etmek için hiçbir kural belirtilmemiş.'");
	EndIf;
	
	Result.BeginOfPeriod = EndOfMonth(Result.BeginOfPeriod);
	Result.EndOfPeriod = EndOfMonth(Result.EndOfPeriod);
	
	Return Result;
	
EndFunction

Function BeginningDateOfPeriod(EndOfPeriod, Periodicity)
	
	BeginOfPeriod = EndOfPeriod + 1;
	
	If Periodicity = Enums.Periodicity.Month Then
		BeginOfPeriod = AddMonth(BeginOfPeriod, -1);
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		BeginOfPeriod = AddMonth(BeginOfPeriod, -3);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		BeginOfPeriod = AddMonth(BeginOfPeriod, -6);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		BeginOfPeriod = AddMonth(BeginOfPeriod, -12);
	Else
		Raise NStr("vi = 'Đối với định kỳ chưa xác định quy tắc nhận kỳ so sánh';
					|ru = 'Для периодичности не определены правила получения сравнительного периода';
					|en = 'Comparison period rules are not defined for the frequency'; fa = 'Comparison period rules are not defined for the frequency';
					|it = 'Per la periodicità non sono indicate regole di ricezione del periodo di comparazione';
					|pl = 'Dla okresowości nie określono reguły uzyskania okresu porównawczego';
					|tr = 'Periyodiklik, karşılaştırmalı sıklık elde etmek için hiçbir kural belirtilmemiş.'");
	EndIf;
	
	Return BeginOfPeriod;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Factor - CatalogRef.FinancialReportItems -
// * RowCode - String -
// * Note - String -
// * StartDate - Date -
// * EndDate - Date -
// * YearPeriod - Date - 
// * HalfYearPeriod - Date -
// * QuarterPeriod - Date -
// * MonthPeriod - Date -
Function NewIntervalTable()
	
	Intervals = New ValueTable;
	Intervals.Columns.Add("Factor", New TypeDescription("CatalogRef.FinancialReportItems"));
	Intervals.Columns.Add("RowCode" , New TypeDescription("String",,New StringQualifiers(20)));
	Intervals.Columns.Add("Note", New TypeDescription("String",,New StringQualifiers(100)));
	
	DateType = New TypeDescription("Date",,,New DateQualifiers(DateFractions.DateTime));
	Intervals.Columns.Add("StartDate",				DateType);
	Intervals.Columns.Add("EndDate",				DateType);
	Intervals.Columns.Add("YearPeriod",					DateType);
	Intervals.Columns.Add("HalfYearPeriod",			DateType);
	Intervals.Columns.Add("QuarterPeriod",				DateType);
	Intervals.Columns.Add("MonthPeriod",				DateType);
	
	Return Intervals;
	
EndFunction

// Parameters:
// 	Parameters - Structure - :
// 	 *ReportBlocks - Array of Structure - description of the blocks in the report.
// 	ReportItem - ValueTreeRow
// 	ElementData - Structure
//
Procedure AddDescriptionOfReportBlock(Parameters, ReportItem, ElementData)
	
	BlockDescription = DescriptionOfReportBlock();
	
	FillPropertyValues(BlockDescription, ReportItem);
	BlockDescription.Insert("LongDesc", ElementData);
	
	Parameters.ReportBlocks.Add(BlockDescription);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForObtainingIndicatorValues

// Parameters:
// 	Parameters - Structure - LongDesc:
// * ErrorsMessages - Array of UserMessage - 
// * Dimensions - ValueList
// * ExtDimension - Structure of KeyAndValue - 
// * FilterReport_ - ValueList -
// * ReportIntervals - See ReportIntervals
// * ReportPeriod - Structure of KeyAndValue -:
// ** BeginOfPeriod - Date -
// ** EndOfPeriod - Date -
// ** Periodicity - Array of EnumRef.Periodicity -
// * Resource - String -
// * Factor - Structure, ValueTableRow, Undefined, ValueTreeRow - LongDesc:
// 	Factor - Structure, ValueTableRow, Undefined, ValueTreeRow - LongDesc:
// * ThisIsReference - Boolean -
// * Error - Boolean -
// * ErrorDescription - String -
// 	Accuracy - Undefined, Number - LongDesc
// 	
// Returns:
// 	ValueTable - LongDesc:
// * Factor - CatalogRef.FinancialReportItems -
// * RowCode - String -
// * Note - String -
// * StartDate - Date -
// * EndDate - Date -
// * YearPeriod - EnumRef.Periodicity -
// * HalfYearPeriod - EnumRef.Periodicity -
// * QuarterPeriod - EnumRef.Periodicity -
// * MonthPeriod - EnumRef.Periodicity -
Function ValueOfSimpleIndicator(Parameters, Factor = Undefined, Accuracy = Undefined)
	
	ItemsKinds = Parameters.ItemsKinds;
	ReportItem = Factor;
	If ReportItem = Undefined Then
		ReportItem = Parameters.Factor;
	EndIf;
	ReportPeriod = Parameters.ReportPeriod;
	ReportIntervals = Parameters.ReportIntervals.Copy();
	ReportIntervals.FillValues(ReportItem.ReportItem  , "Factor");
	ReportIntervals.FillValues(ReportItem.ReportRowCode, "RowCode");
	ReportIntervals.FillValues(ReportItem.Note     , "Note");
	Dimensions = Parameters.Dimensions;
	ExtDimension = Parameters.ExtDimension;
	IndicatorValue = EmptyMetricValue(ReportIntervals, Dimensions, ExtDimension);
	Resource = Parameters.Resource;
	
	NonMonetary = ItemsKinds.NonMonetaryItem;
	Monetary_ = ItemsKinds.MonetaryIndicator;
	
	// Let's set the layout parameters
	IndicatorScheme = Catalogs.FinancialReportItems.IndicatorScheme(ReportItem, Dimensions, ExtDimension, Resource);
	Settings = IndicatorScheme.Settings;
	If ReportItem.ItemKind = Monetary_
		And Not ValueIsFilled(ReportItem.GLAccount_) Then
		TextTemplate1 = NStr("vi = 'Chưa xác định giá trị chỉ tiêu 
							|%1 (%2)
							|của dạng báo cáo %3
							|do nguyên nhân: chưa chỉ ra tài khoản trong hệ thống tài khoản.';
							|ru = 'Не определено значение показателя 
							|%1 (%2)
							|вида отчета %3
							|по причине: не указан счет плана счетов.';
							|en = 'Value of indicator 
							|%1 (%2)
							|of report kind %3 is not determined.
							|Reason: an account of the chart of accounts is not specified.'; fa = 'Value of indicator 
							|%1 (%2)
							|of report kind %3 is not determined.
							|Reason: an account of the chart of accounts is not specified.';
							|it = 'Il valore dell''indicatore 
							|%1 (%2)
							|del tipo di rapporto non è definito%3
							| per il motivo: il conto del piano dei conti non è specificato.';
							|pl = 'Nie jest określona wartość wskaźnika 
							|%1 (%2)
							|rodzaju raportu %3
							|z powodu: nie jest wskazany rachunek planu rachunków.';
							|tr = '%3
							|rapor türünün 
							|%1 (%2)
							|göstergesi şu nedenlerle tanımlanmadı: hesap planı hesabı belirtilmedi.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			TextTemplate1, 
			ReportItem.NameForPrinting, 
			ReportItem.Code,
			ReportItem.ReportKind);
		Common.MessageToUser(Text, ReportItem.ReportItem);
		AddErrorMessage(Parameters.ErrorsMessages, Text, ReportItem.ReportItem);
		Parameters.Insert("CalculationError");
	EndIf;
	
	For Each FilterElement In Parameters.FilterReport_ Do
		If ValueIsFilled(FilterElement.Value) Then
			If ReportItem.ItemKind = Monetary_
				Or (ReportItem.ItemKind = NonMonetary
					And StrFind(FilterElement.Key, "ExtDimension") = 0
					And StrFind(FilterElement.Key, "LineOfBusiness") = 0) Then
				NewFilter = FinancialReportingServer.NewFilter(Settings.Filter, FilterElement.Key, FilterElement.Value);
				If TypeOf(NewFilter.RightValue) = Type("Array") Then
					NewFilter.ComparisonType = DataCompositionComparisonType.InList;
				EndIf;
			EndIf;
		EndIf;// the selection value is filled in
	EndDo;
	
	AddPeriodicitySetting(Settings, ReportPeriod);
	
	IndicatorData = FinancialReportingServer.UploadDCSResults(IndicatorScheme.Schema, Settings, New Structure("ReportIntervals", ReportIntervals));
	
	GroupColonies = New Array;
	For Each Column In IndicatorData.Columns Do
		If Column.Name <> "Value" Then
			GroupColonies.Add(Column.Name);
		EndIf;
	EndDo;
	IndicatorData.GroupBy(StrConcat(GroupColonies, ","), "Value");
	
	AccuracyOfIndicator = 0;
	If Accuracy <> Undefined Then
		AccuracyOfIndicator = Accuracy;
	ElsIf ReportItem.Accuracy <>  Undefined Then
		AccuracyOfIndicator = ReportItem.Accuracy;
	EndIf;
	For Each IndicatorDataLine In IndicatorData Do
		IndicatorDataLine.Value = Round(IndicatorDataLine.Value, AccuracyOfIndicator);
	EndDo;
	
	If IndicatorData.Count() > 0 Then
		IndicatorValue.Clear();
		LoadIntoValueTable(IndicatorData, IndicatorValue);
	EndIf;
	
	Return IndicatorValue;
	
EndFunction

Function ValueOfDerivedIndicator(Parameters, Factor = Undefined)
	
	ReportItem = Factor; // ValueTreeRow - See UpdateTheReportTree
	If ReportItem = Undefined Then
		ReportItem = Parameters.Factor;
	EndIf;
	ReportPeriod = Parameters.ReportPeriod;
	ReportIntervals = Parameters.ReportIntervals.Copy();
	ReportIntervals.FillValues(ReportItem.ReportItem, 		"Factor");
	ReportIntervals.FillValues(ReportItem.ReportRowCode, 	"RowCode");
	ReportIntervals.FillValues(ReportItem.Note, 		"Note");
	IndicatorValue = EmptyMetricValue(ReportIntervals, Parameters.Dimensions, Parameters.ExtDimension);
	
	If ReportItem.ThisIsReference Then
		FormulaOperands = UnloadFormulaOperands(ReportItem.LinkedItem1);
	Else
		FormulaOperands = UnloadFormulaOperands(ReportItem.ReportItem);
	EndIf;
	If ValueIsFilled(FormulaOperands) Then
		OperandValues = New ValueTable;
		OperandIdentifiers = "";
		// We get the values of the operands of the formula
		For Each Operand In FormulaOperands Do
			OperandIdentifiers = OperandIdentifiers + Operand.Id + ",";
			OperandData = ReportItem.Rows.Find(Operand.Operand,"ReportItem");
			If OperandData = Undefined Then
				OperandData = Common.ObjectAttributesValues(
									Operand.Operand,
									"NameForPrinting,ItemKind,HasSettings,AdditionalSelection,ReverseSign");
				AddAttributes = FinancialReportingServerCall.AdditionalAttributesValues(
									Operand.Operand,
									"GLAccount_,TotalType,OpeningBalance,NonMonetaryItem,ReportRowCode,Note,Accuracy");
				For Each KeyValue In AddAttributes Do
					OperandData.Insert(KeyValue.Key, KeyValue.Value);
				EndDo;
				OperandData.Insert("ReportItem", Operand.Operand);
				OperandData.Insert("ThisIsReference", False);
			EndIf;
			ValueOperand = ValueOfSimpleIndicator(Parameters, OperandData, ReportItem.Accuracy);
			ValueColumn = ValueOperand.Columns.Value; // ValueTableColumn - 
			ValueColumn.Name = Operand.Id;
			If OperandValues.Columns.Count() = 0 Then
				OperandValues = ValueOperand.Copy();
				Continue;
			EndIf;
			OperandValues.Columns.Add(Operand.Id, New TypeDescription("Number"));
			LoadIntoValueTable(ValueOperand,OperandValues);
		EndDo;
		StringFunctionsClientServer.DeleteLastCharInString(OperandIdentifiers,1);
		If Parameters.Property("CalculationError") Then
			TextTemplate1 = NStr("vi = 'Giá trị chỉ tiêu không hợp lệ 
								|%1(%2)
								|do nguyên nhân: lỗi tính chỉ tiêu phức hợp.';
								|ru = 'Недостоверное значение показателя 
								|%1(%2)
								|по причине: ошибка расчета составных показателей.';
								|en = 'Unreliable value of indicator 
								|%1(%2).
								|Reason: an error occurred while calculating compound indicators.'; fa = 'Unreliable value of indicator 
								|%1(%2).
								|Reason: an error occurred while calculating compound indicators.';
								|it = 'Valore non valido dell''indicatore 
								|%1(%2)
								|per motivo: errore nel calcolo delle metriche composite.';
								|pl = 'Niewiarygodna wartość wskaźnika 
								|%1(%2)
								|z powodu: błąd obliczenia wskaźników składowych.';
								|tr = '
								|%1(%2)
								| göstergenin değerinin geçersizlik nedeni: bileşik gösterge hesaplama hatası.'");
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				TextTemplate1, 
				ReportItem.NameForPrinting, 
				ReportItem.Code);
			Common.MessageToUser(Text, ReportItem.ReportItem);
			AddErrorMessage(Parameters.ErrorsMessages, Text, ReportItem.ReportItem);
		EndIf;
		
		GroupColumns = "";
		For Each Column In OperandValues.Columns Do
			If StrFind(OperandIdentifiers, Column.Name) = 0 Then
				GroupColumns = GroupColumns + Column.Name + ",";
			EndIf;
		EndDo;
		StringFunctionsClientServer.DeleteLastCharInString(GroupColumns,1);
		
		OperandValues.FillValues(ReportItem.ReportItem  ,"Factor");
		OperandValues.FillValues(ReportItem.ReportRowCode,"RowCode");
		OperandValues.FillValues(ReportItem.Note     ,"Note");
		OperandValues.GroupBy(GroupColumns,OperandIdentifiers);
		
	Else
		OperandValues = ReportIntervals.Copy(); 
		
		For Each MeasurementOfIndicator In Parameters.Dimensions Do
			OperandValues.Columns.Add(MeasurementOfIndicator.Value);
		EndDo; 
		
		If Parameters.ExtDimension <> Undefined Then
			For Each ExtdimensionOfIndicator In Parameters.ExtDimension Do
				 If OperandValues.Columns.Find(ExtdimensionOfIndicator.Key) = Undefined Then
					OperandValues.Columns.Add(ExtdimensionOfIndicator.Key);
				EndIf;
			EndDo; 
		EndIf;
		
	EndIf;
	
	If IsBlankString(ReportItem.Formula) Then
		TextTemplate1 = NStr("vi = 'Chưa xác định giá trị chỉ tiêu 
							|%1 (%2)
							| do nguyên nhân: chưa chỉ ra công thức tính.';
							|ru = 'Не определено значение показателя 
							|%1 (%2)
							|по причине: не указана формула расчета.';
							|en = 'Value of indicator 
							|%1 (%2) is not determined.
							|Reason: calculation formula is not specified.'; fa = 'Value of indicator 
							|%1 (%2) is not determined.
							|Reason: calculation formula is not specified.';
							|it = 'Il valore dell''indicatore 
							|%1 (%2)
							|non è definito per il motivo: la formula di calcolo non è specificata.';
							|pl = 'Nie jest określona wartość wskaźnika 
							|%1 (%2)
							|z powodu: nie jest wskazana formuła obliczenia.';
							|tr = '
							|%1 (%2)
							| gösterge değeri şu nedenden dolayı tanımlanmadı: hesaplama formülü belirtilmedi.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			TextTemplate1, 
			ReportItem.NameForPrinting, 
			ReportItem.Code);
		Common.MessageToUser(Text);
		AddErrorMessage(Parameters.ErrorsMessages, Text, ReportItem.ReportItem);
		Parameters.Insert("CalculationError");
	EndIf;
	// Let 's execute the formula
	IndicatorScheme = Catalogs.FinancialReportItems.IndicatorScheme(ReportItem, Parameters.Dimensions, Parameters.ExtDimension);
	ExternalSets = New Structure;
	ExternalSets.Insert("OperandValues", OperandValues);
	ExternalSets.Insert("ReportIntervals", ReportIntervals);
	
	Settings = IndicatorScheme.Settings;
	FinancialReportingServer.SetLayoutParameter(Settings, "ReportItem", ReportItem.ReportItem);
	FinancialReportingServer.SetLayoutParameter(Settings, "ReverseSign" , ReportItem.ReverseSign);
	FinancialReportingServer.SetLayoutParameter(Settings, "BeginOfPeriod", ReportPeriod.BeginOfPeriod);
	FinancialReportingServer.SetLayoutParameter(Settings, "EndOfPeriod" , ReportPeriod.EndOfPeriod);
	FinancialReportingServer.SetLayoutParameter(Settings,"Periodicity" , ReportPeriod.Periodicity);
	AddPeriodicitySetting(Settings, ReportPeriod);
	
	IndicatorData = FinancialReportingServer.UploadDCSResults(IndicatorScheme.Schema, Settings, ExternalSets);
	If Not ValueIsFilled(IndicatorData) Then
		IndicatorData = OperandValues.Copy();
	EndIf;
	
	If ReportItem.Accuracy <>  Undefined Then
		For Each IndicatorDataLine In IndicatorData Do
			If TypeOf(IndicatorDataLine.Value) = Type("Number") Then
				IndicatorDataLine.Value = Round(IndicatorDataLine.Value, ReportItem.Accuracy);
			Else
				IndicatorDataLine.Value = IndicatorDataLine.Value;
			EndIf;
		EndDo; 
	EndIf;
	
	If IndicatorData.Count() > 0 Then
		IndicatorValue.Clear();
		LoadIntoValueTable(IndicatorData, IndicatorValue);
	EndIf;
	
	Return IndicatorValue;
	
EndFunction

Function UnloadFormulaOperands(Factor)
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	FormulaOperands.LineNumber,
	|	FormulaOperands.Id,
	|	FormulaOperands.Operand
	|FROM
	|	Catalog.FinancialReportItems.FormulaOperands AS FormulaOperands
	|WHERE
	|	FormulaOperands.Ref = &Ref";
	Query.SetParameter("Ref", Factor);
	
	Return Query.Execute().Unload();
	
EndFunction

Function GroupTotalValue(Parameters, Factor = Undefined)
	
	ReportItem = Factor;//Structure, ValueTreeRow - 
	If ReportItem = Undefined Then
		ReportItem = Parameters.Factor;
	EndIf;
	RelatedReport = Common.ObjectAttributeValue(ReportItem.LinkedItem1, "Owner");
	TotalIndicators = UpdateTheReportTree(RelatedReport, ReportItem.LinkedItem1);
	
	TotalByGroup = Undefined;
	For Each TotalIndicator In TotalIndicators.Rows Do
		
		IndicatorValue = ReportMetricValue(Parameters, TotalIndicator);
		If IndicatorValue = Undefined Then
			Continue;
		EndIf;
		
		If TotalByGroup = Undefined Then
			TotalByGroup = IndicatorValue.Copy();
		Else
			LoadIntoValueTable(IndicatorValue, TotalByGroup);
		EndIf;
		
	EndDo;
	If Parameters.Property("CalculationError") Then
		TextTemplate1 = NStr("vi = 'Giá trị tổng số không hợp lệ theo nhóm 
							|%1 (%2)
							|do nguyên nhân: lỗi tính toán các chỉ số phức hợp.';
							|ru = 'Недостоверное значение итога по группе 
							|%1 (%2)
							|по причине: ошибка расчета составных показателей.';
							|en = 'Unreliable value of total by group 
							|%1(%2).
							|Reason: an error occurred while calculating compound indicators.'; fa = 'Unreliable value of total by group 
							|%1(%2).
							|Reason: an error occurred while calculating compound indicators.';
							|it = 'Valore non valido del totale per gruppo 
							|%1(%2)
							|per motivo: errore nel calcolo delle metriche composite.';
							|pl = 'Niewiarygodna wartość sumy wg grupy 
							|%1 (%2)
							|z powodu: błąd obliczenia wskaźników składowych.';
							|tr = '
							|%1 (%2)
							| grup toplamının geçersiz değer nedeni: bileşik ölçümlerin hesaplanma hatası.'");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			TextTemplate1, 
			ReportItem.NameForPrinting, 
			ReportItem.Code);
		Common.MessageToUser(Text);
		Parameters.ErrorsMessages.Add(Text);
	EndIf;
	If TotalByGroup = Undefined Then
		ReportIntervals = Parameters.ReportIntervals.Copy();
		ReportIntervals.FillValues(ReportItem.ReportItem  , "Factor");
		ReportIntervals.FillValues(ReportItem.ReportRowCode, "RowCode");
		ReportIntervals.FillValues(ReportItem.Note     , "Note");
		Dimensions = Parameters.Dimensions;
		TotalByGroup = EmptyMetricValue(ReportIntervals, Dimensions);
	EndIf;
	
	TotalByGroup.FillValues(ReportItem.ReportItem  , "Factor");
	TotalByGroup.FillValues(ReportItem.ReportRowCode, "RowCode");
	TotalByGroup.FillValues(ReportItem.Note     , "Note");
	
	GroupColumns = "";
	For Each Column In TotalByGroup.Columns Do
		If Column.Name = "Value" Then
			Continue;
		EndIf;
		GroupColumns = GroupColumns + Column.Name + ",";
	EndDo;
	StringFunctionsClientServer.DeleteLastCharInString(GroupColumns,1);
	
	TotalByGroup.GroupBy(GroupColumns, "Value");
	If ReportItem.ReverseSign Then
		For Each Total In TotalByGroup Do
			Total.Value = -1 * Total.Value;
		EndDo;
	EndIf;
	Return TotalByGroup;
	
EndFunction

Function ReportMetricValue(Parameters, Factor = Undefined)
	
	ItemsKinds = Parameters.ItemsKinds;
	ReportItem = Factor;
	If ReportItem = Undefined Then
		ReportItem = Parameters.Factor;
	EndIf;
	If ReportItem.ItemKind = ItemsKinds.MonetaryIndicator 
		Or ReportItem.ItemKind = ItemsKinds.NonMonetaryItem Then
		Result = ValueOfSimpleIndicator(Parameters, Factor);
	ElsIf ReportItem.ItemKind = ItemsKinds.DerivedItem Then
		Result = ValueOfDerivedIndicator(Parameters, Factor);
	ElsIf ReportItem.ItemKind = ItemsKinds.TotalByGroup
		And ReportItem.ThisIsReference Then
		Result = GroupTotalValue(Parameters, Factor);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddPeriodicitySetting(Settings, ReportPeriod)
	
	For Each Period In ReportPeriod.Periodicity Do
		FinancialReportingServer.NewSelectionField(Settings, Period.ColumnName, Period.Presentation);
		FinancialReportingServer.NewOrder(Settings, Period.ColumnName, Period.Sort);
	EndDo;
	
EndProcedure

#EndRegion

#Region OutputToTabularDocument

// Parameters:
// 	Parameters - Structure of KeyAndValue- :
// 	 *AttributeCache - See FinancialReportingServer.CacheAdditionalElementFields
// 	 *ErrorsMessages - Array of UserMessage -
// 	 *ReportBlocks - Array of Structure - :
// 	  **LongDesc - Structure -
// 	 *ItemsKinds - See Enums.FinancialReportItemKinds.Cache
// 	ReportItemTree - See DescriptionOfReportTree
// Returns:
// 	SpreadsheetDocument - LongDesc
Function OutputReport(Parameters, ReportItemTree)
	
	ItemsKinds = Parameters.ItemsKinds;
	
	ResultDocument = New SpreadsheetDocument;
	ReportOutputParameters(Parameters);
	
	ResultDocument.StartRowAutoGrouping();
	For Each BlockDescription In Parameters.ReportBlocks Do
		
		If BlockDescription.ItemKind = ItemsKinds.ReportHeader
			Or BlockDescription.ItemKind = ItemsKinds.EditedText
			Or BlockDescription.ItemKind = ItemsKinds.UneditedText Then
			OutputText(Parameters.OutputLayout, BlockDescription, ResultDocument, ItemsKinds, Parameters.MaxNumberOfColumns);
			
		ElsIf BlockDescription.ItemKind = ItemsKinds.MonetaryIndicator
			Or BlockDescription.ItemKind = ItemsKinds.NonMonetaryItem 
			Or BlockDescription.ItemKind = ItemsKinds.DerivedItem
			Or BlockDescription.ItemKind = ItemsKinds.TotalByGroup Then
			
			OutputIndicator(Parameters, BlockDescription, ResultDocument);
			
		ElsIf BlockDescription.ItemKind = ItemsKinds.TableIndicatorsInRows
			Or BlockDescription.ItemKind = ItemsKinds.TableIndicatorsInColumns 
			Or BlockDescription.ItemKind = ItemsKinds.ComplexTable Then
			
			OutputTable_(Parameters, BlockDescription, ResultDocument);
			
		EndIf;
		
	EndDo;
	ResultDocument.EndRowAutoGrouping();
	
	Return ResultDocument;
	
EndFunction

Function ReportOutputParameters(Parameters)
	
	ItemsKinds = Parameters.ItemsKinds;
	AppearanceTemplate = Catalogs.FinancialReportTypes.GetTemplate("FinancialReport_");
	OutputLayout = New Structure;
	OutputLayout.Insert("ItemKind", New Map);
	
	// All output layouts
	OutputLayout.Insert("ReportHeader" , AppearanceTemplate.GetArea("ReportHeader"));
	OutputLayout.Insert("Text"           , AppearanceTemplate.GetArea("Text"));
	OutputLayout.Insert("TableHeading", AppearanceTemplate.GetArea("TableHeading"));
	OutputLayout.Insert("IsBlankString"    , AppearanceTemplate.GetArea("IsBlankString"));
	OutputLayout.Insert("ColumnSummary"     , AppearanceTemplate.GetArea("Group|Value"));
	
	OutputLayout.Insert("Header", RowTemplate(AppearanceTemplate, "Header"));
	OutputLayout.Insert("ReportRow", RowTemplate(AppearanceTemplate, "ReportRow"));
	OutputLayout.Insert("Group", RowTemplate(AppearanceTemplate, "Group"));
	OutputLayout.Insert("SummaryByLines", RowTemplate(AppearanceTemplate, "SummaryByLines"));
	OutputLayout.Insert("SingleIndicator", RowTemplate(AppearanceTemplate, "SingleIndicator"));
	OutputLayout.Insert("SingleIndicatorHighlighted", RowTemplate(AppearanceTemplate, "SingleIndicatorHighlighted"));
	OutputLayout.Insert("LowerBorderOfTable", RowTemplate(AppearanceTemplate, "LowerBorderOfTable"));
	
	// Decompose by types of elements
	RowTemplate = RowTemplate(AppearanceTemplate, "ReportRow");
	OutputLayout.ItemKind.Insert(ItemsKinds.MonetaryIndicator  , RowTemplate);
	OutputLayout.ItemKind.Insert(ItemsKinds.NonMonetaryItem, RowTemplate);
	OutputLayout.ItemKind.Insert(ItemsKinds.DerivedItem , RowTemplate);
	OutputLayout.ItemKind.Insert(ItemsKinds.RowColumn        , RowTemplate);
	
	RowTemplate = RowTemplate(AppearanceTemplate, "Group");
	OutputLayout.ItemKind.Insert(ItemsKinds.Dimension, RowTemplate);
	OutputLayout.ItemKind.Insert(ItemsKinds.Group, RowTemplate);
	
	RowTemplate = RowTemplate(AppearanceTemplate, "SummaryByLines");
	OutputLayout.ItemKind.Insert(ItemsKinds.TotalByGroup, RowTemplate);
	
	Parameters.Insert("OutputLayout", OutputLayout);
	
	Return OutputLayout;
	
EndFunction

// Parameters:
// 	OutputLayout - SpreadsheetDocument - 
// 	OutputItem - See DescriptionOfReportBlock
// 	ResultDocument - SpreadsheetDocument - LongDesc
// 	ItemsKinds - Structure - LongDesc
// 	TextWidth - Number - LongDesc
Procedure OutputText(OutputLayout, OutputItem, ResultDocument, ItemsKinds, TextWidth)
	
	If OutputItem.ItemKind = ItemsKinds.ReportHeader Then
		Area = OutputLayout.ReportHeader; // SpreadsheetDocument - 
		Area.Parameters.ReportHeader = OutputItem.LongDesc.Text;
	ElsIf OutputItem.ItemKind = ItemsKinds.ComplexTable
		Or OutputItem.ItemKind = ItemsKinds.TableIndicatorsInColumns
		Or OutputItem.ItemKind = ItemsKinds.TableIndicatorsInRows Then
		Area = OutputLayout.TableHeading; // SpreadsheetDocument -
		Area.Parameters.TableHeading = OutputItem.NameForPrinting;
	Else
		Area = OutputLayout.Text; // SpreadsheetDocument -
		Area.Parameters.Text  = OutputItem.LongDesc.Text;
	EndIf;
	MergeHorizontally(Area, 1, 3, 2);
	NewArea = ResultDocument.Put(Area, 0);
	
	If OutputItem.ItemKind = ItemsKinds.EditedText Then
		TextArea_ = ResultDocument.Area(NewArea.Top+1,1);
		TextArea_.Protection = False;
		TextArea_.BackColor = New Color(255,255,192);
	EndIf;
	
EndProcedure

// Parameters:
// 	Parameters - Structure of KeyAndValue - LongDesc: 
// 	 * OutputLayout - SpreadsheetDocument -
// 	OutputItem - See DescriptionOfReportBlock
// 	ResultDocument - SpreadsheetDocument - LongDesc
Procedure OutputIndicator(Parameters, OutputItem, ResultDocument)
	
	RowTemplate = Parameters.OutputLayout.SingleIndicator; // SpreadsheetDocument - 
	If OutputItem.LongDesc.SelectItem Then
		RowTemplate = Parameters.OutputLayout.SingleIndicatorHighlighted;
	EndIf;
	
	MetricTemplate = RowTemplate.Factor; //SpreadsheetDocument - 
	MetricTemplate.Parameters.Description = OutputItem.NameForPrinting;
	MetricTemplate.Parameters.Details = OutputItem.ReportItem;
	ResultDocument.Put(MetricTemplate);
	
	CellTemplate = RowTemplate.Value; // SpreadsheetDocument - 
	CellTemplate.Parameters.Value = Format(OutputItem.LongDesc.Value, Parameters.ValueFormat_);
	CellTemplate.Parameters.Details = OutputItem.LongDesc.Details;
	CellTemplate.CurrentArea.Format = Parameters.ValueFormat_;
	TemplateArea = ResultDocument.Join(CellTemplate);
	
	Parameters.ReportDetails.Insert(TemplateArea.Name, CellTemplate.Parameters.Details);
	
EndProcedure

#Region TableOutput

// Parameters:
// 	Parameters - Structure - LongDesc:
// 	OutputItem - See DescriptionOfReportBlock
// 	ResultDocument - SpreadsheetDocument - LongDesc
Procedure OutputTable_(Parameters, OutputItem, ResultDocument)
	
	If OutputItem.LongDesc.TableHeader = Undefined Then
		Return;
	EndIf;
	
	If OutputItem.DisplayItemTitle Then
		OutputText(Parameters.OutputLayout, OutputItem, ResultDocument, Parameters.ItemsKinds, Parameters.MaxNumberOfColumns);
	EndIf;
	PrintTableHeader_(Parameters, OutputItem, ResultDocument);
	
	StringTree = OutputItem.LongDesc.StringTree; // See DescriptionOfReportTree
	For Each TableRow In StringTree.Rows Do
		Parameters.Insert("FilterRows", New Structure);
		OutputTableRow(TableRow, ResultDocument, OutputItem.LongDesc, Parameters);
	EndDo;
	ResultDocument.EndRowAutoGrouping();
	ResultDocument.Put(Parameters.OutputLayout.IsBlankString);
	Parameters.Delete("FilterRows");
	
EndProcedure

Procedure PrintTableHeader_(Parameters, OutputItem, ResultDocument)
	
	OutputLayout = Parameters.OutputLayout.Header;
	MatchingElementsByLevels = New Map;
	TableHeader = OutputItem.LongDesc.TableHeader;
	NumberOfHeaderLevels = OutputItem.LongDesc.NumberOfHeaderLevels + 1;
	DistributeItemsByLevels(TableHeader.Rows, NumberOfHeaderLevels, MatchingElementsByLevels);
	
	FirstLineOfHeader = Undefined;
	CircleElements = NumberOfHeaderLevels > 1;
	
	For Cnt = 1 To NumberOfHeaderLevels Do
		
		DerivedArea = ResultDocument.Put(OutputLayout.Factor, 0);
		
		If FirstLineOfHeader = Undefined Then
			FirstLineOfHeader = DerivedArea.Top;
		EndIf;
		If Parameters.DisplayRowCode Then
			ResultDocument.Join(OutputLayout.ReportRowCode);
		EndIf;
		If Parameters.DisplayNoteInReport Then
			ResultDocument.Join(OutputLayout.Note);
		EndIf;
		
		If MatchingElementsByLevels.Count() Then // checking for column values
			
			LevelElements = MatchingElementsByLevels[Cnt];
			For Each LevelElement In LevelElements Do
				Section3 = OutputLayout.Value; // SpreadsheetDocument - 
				
				If LevelElement = Undefined
					Or Not ValueIsFilled(LevelElement.NameForPrinting) Then
					Section3.Parameters.Description = "";
				ElsIf Not LevelElement.DisplayItemTitle Then
					Continue;
				ElsIf ValueIsFilled(LevelElement.NameForPrinting) Then
					Section3.Parameters.Description = LevelElement.NameForPrinting;
				EndIf;
				
				DerivedArea = ResultDocument.Join(Section3);
				If LevelElement = Undefined Then
					Area = ResultDocument.Area(DerivedArea.Top - 1,
														DerivedArea.Left,
														DerivedArea.Top,
														DerivedArea.Left);
					Area.Merge();
					Continue;
				EndIf;
				
				NumberOfBins = NumberOfHeaderColumns(LevelElement);
				If NumberOfBins > 1 Then
					For ITER = 1 To NumberOfBins - 1 Do
						ResultDocument.Join(OutputLayout.Value);
					EndDo;
					GroupingArea_ = MergeHorizontally(ResultDocument, DerivedArea.Left, NumberOfBins, DerivedArea.Top);
					If GroupingArea_ <> Undefined Then
						CircleArea(GroupingArea_);
					EndIf;
				ElsIf CircleElements Then
					CircleArea(DerivedArea);
				EndIf;
				
			EndDo;
		EndIf;
	EndDo;
	
	FirstColumnOfHeader = 1;
	MergeVertically(ResultDocument, FirstLineOfHeader, NumberOfHeaderLevels, FirstColumnOfHeader);
	If Parameters.DisplayRowCode Then
		FirstColumnOfHeader = FirstColumnOfHeader + 1;
		MergeVertically(ResultDocument, FirstLineOfHeader, NumberOfHeaderLevels, FirstColumnOfHeader, Parameters.RowCodeHeader, True);
	EndIf;
	If Parameters.DisplayNoteInReport Then
		FirstColumnOfHeader = FirstColumnOfHeader + 1;
		MergeVertically(ResultDocument, FirstLineOfHeader, NumberOfHeaderLevels, FirstColumnOfHeader, Parameters.CommentHeader, True);
	EndIf;
	
EndProcedure

// Output a table row.
// 
// Parameters:
//  TableRowData - ValueTreeRow - Table row data:
// * ItemKind - EnumRef.FinancialReportItemKinds -
// * ItemID - String -
// * ReportItem - CatalogRef.FinancialReportItems -
// * NameForPrinting - String -
// * DisplayItemTitle - Boolean -
// * SelectItem - Boolean -
// * LocationOfTotal - Number -
// * ReverseSign - Boolean -
// * PeriodPresentation - String -
// * Periodicity - EnumRef.Periodicity -
// * ColumnName - String -
// * Sort - String -
// * Accuracy - Number -
// * ExtDimensionType - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
//  ResultDocument - SpreadsheetDocument - Result document
//  TableDetails - Structure - Table Description
//  Parameters - Structure - Parameters:
// * FilterRows - Structure -
// * Filter - Structure - report selection 
//  Level - Number - Level
Procedure OutputTableRow(TableRowData, ResultDocument, TableDetails, Parameters, Level = 0)
	
	If TableRowData.DisplayItemTitle Then
		OutputRowCells(TableRowData, ResultDocument, TableDetails, Parameters, Level);
	Else
		Level = Level - 1;
	EndIf;

	For Each TableRow In TableRowData.Rows Do
		OutputTableRow(TableRow, ResultDocument, TableDetails, Parameters, Level+1);
	EndDo;
	
	If TableRowData.ItemKind = Parameters.ItemsKinds.Group Then
		Parameters.Filter.Delete(TableRowData.ItemID);
	EndIf;
	
EndProcedure

// Parameters:
// 	TableRowData - ValueTreeRow - 
// 	ResultDocument - SpreadsheetDocument - LongDesc
// 	TableDetails - See TableDetails
// 	Parameters - Structure - LongDesc:
// * FilterRows - Structure -
// 	Level - Number - LongDesc
Procedure OutputRowCells(TableRowData, ResultDocument, TableDetails, Parameters, Level)
	
	ItemsKinds = Parameters.ItemsKinds;
	If TableRowData.ItemKind = ItemsKinds.TotalByGroup And TableRowData.LocationOfTotal = 0 Then
		Return;
	EndIf;
	
	ThereIsSummaryAtBeginning = TableRowData.LocationOfTotal = 0;
	IsFolder = TableRowData.ItemKind = ItemsKinds.Group;
	ThisIsPeriodMeasurement = ValueIsFilled(TableRowData.PeriodPresentation);
	ThisIsArbitrary = TableDetails.ThisIsArbitrary;
	// We output group headers without resources
	OutputResources = ((ThereIsSummaryAtBeginning And IsFolder)//groups with totals at the beginning of the group are displayed with resources
						Or Not IsFolder)// indicators, measurements, totals are displayed with resources
						And Not (TableDetails.ThisIsArbitrary And ThisIsPeriodMeasurement);//period measurements in matrix reports are output without resources
						
	
	If TableRowData.ItemKind = ItemsKinds.TotalByGroup And TableRowData.ThisIsReference
			Or TableRowData.ItemKind = ItemsKinds.Dimension Then
		RowTemplate = Parameters.OutputLayout.ReportRow;
	Else
		RowTemplate = Parameters.OutputLayout.ItemKind[TableRowData.ItemKind];
	EndIf;
	If TableRowData.SelectItem Then
		RowTemplate = Parameters.OutputLayout.Group;
	EndIf;
	
	IndicatorArea = RowTemplate.Factor; // SpreadsheetDocument - 
	If TableDetails.TableIndicatorsInColumns Then
		IndicatorArea = RowTemplate.IndicatorForIndicatorsInColumns;
	EndIf;
	
	IndicatorArea.Parameters.Description = TableRowData.NameForPrinting;
	IndicatorArea.Parameters.Details = TableRowData.ReportItem;
	IndicatorArea.CurrentArea.Indent = 2 * Level;
	ResultDocument.Put(IndicatorArea, Level);
	
	For Each Column In TableDetails.ReportColumns Do
		
		If Column.ThisIsTotal And Column.ItemKind <> ItemsKinds.TotalByGroup Then
			Continue;
		EndIf;
		
		HighlightedValue =  Column.SelectItem 
			Or Column.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup;
		Accuracy = Undefined;
		
		CellTemplate = RowTemplate.Value; // SpreadsheetDocument - 
		If RowTemplate.Property(Column.ColumnName) Then
			CellTemplate = RowTemplate[Column.ColumnName];
		ElsIf HighlightedValue Then
			CellTemplate = RowTemplate.HighlightedValue;
		EndIf;
		
		If OutputResources Then
			
			Details = DetailsCell(TableDetails, TableRowData, Column.ColumnName);
			CellTemplate.Parameters.Details = Details;
			
			If TableRowData.ItemKind = Enums.FinancialReportItemKinds.NonMonetaryItem
					Or Column.ItemKind = Enums.FinancialReportItemKinds.NonMonetaryItem Then
				
				If  ValueIsFilled(TableRowData.Accuracy) Then
					Accuracy = TableRowData.Accuracy;
				ElsIf ValueIsFilled(Column.ItemKind) Then
					Accuracy = Column.Accuracy;
				EndIf;
				FormatString = "NFD="+?(Accuracy = Undefined, "0", Accuracy);
				CellTemplate.Parameters.Value = Format(TableRowData[Column.ColumnName], FormatString);
				
			ElsIf ThisIsArbitrary Then
				
				If (Details = Undefined Or Details.Factor.ItemKind <> ItemsKinds.NonMonetaryItem) 
						And ValueIsFilled(Column.ReportItem) Then
					If TableRowData.ItemKind = Enums.FinancialReportItemKinds.RowColumn
								And Column.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup Then
						Accuracy = Column.Accuracy;
					ElsIf (TableRowData.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup
								And Column.ItemKind = Enums.FinancialReportItemKinds.RowColumn) Then
						Accuracy = TableRowData.Accuracy;
					Else
						Accuracy = TableRowData[Column.ColumnName+"_Accuracy"];
					EndIf;
				EndIf;
				
				If StrFind(Parameters.ValueFormat_, "NS=") = 0 Then 
					
					If Accuracy = Undefined Then
						CellTemplate.Parameters.Value = TableRowData[Column.ColumnName];
					Else
						FormatString = Parameters.ValueFormat_ + "; NFD="+?(Accuracy = Undefined, "0", Accuracy);
						CellTemplate.Parameters.Value = Format(TableRowData[Column.ColumnName], FormatString);
					EndIf;
					
				Else 
					FormatString = Parameters.ValueFormat_;
					CellTemplate.Parameters.Value = Format(TableRowData[Column.ColumnName], FormatString);
				EndIf;
			
			ElsIf (ThisIsIndicator(TableRowData.ItemKind, Parameters.ItemsKinds) Or ThisIsIndicator(Column.ItemKind, Parameters.ItemsKinds)
					Or TableRowData.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup
					Or Column.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup) Then
					
				FormatString = Parameters.ValueFormat_;
				If StrFind(Parameters.ValueFormat_, "NS=") = 0 Then 
					If ValueIsFilled(TableRowData.Accuracy) Then
						Accuracy = TableRowData.Accuracy;
					ElsIf ValueIsFilled(Column.ItemKind) Then
						Accuracy = Column.Accuracy;
					EndIf;
					FormatString = Parameters.ValueFormat_ + "; NFD="+?(Accuracy = Undefined, "0", Accuracy);
				EndIf;
				
				If ValueIsFilled(Column.ItemKind) And TableRowData.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup
						Or Column.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup Then
					TableRowData[Column.ColumnName] = Round(TableRowData[Column.ColumnName], ?(Accuracy = Undefined, 0, Accuracy));
				EndIf;
				
				CellTemplate.Parameters.Value = Format(TableRowData[Column.ColumnName], FormatString);
				
			Else
				
				If StrFind(Parameters.ValueFormat_, "NS=") = 0 Then 
					If ValueIsFilled(TableRowData.Accuracy) Then
						Accuracy = TableRowData.Accuracy;
					ElsIf ValueIsFilled(Column.ItemKind) Then
						Accuracy = Column.Accuracy;
					EndIf;
					FormatString = Parameters.ValueFormat_ + "; NFD="+?(Accuracy = Undefined, "0", Accuracy);
				Else
					FormatString = Parameters.ValueFormat_
				EndIf;
				
				CellTemplate.Parameters.Value = Format(TableRowData[Column.ColumnName], FormatString);
			EndIf;
			
		Else
			CellTemplate.Parameters.Value = "";
			CellTemplate.Parameters.Details = Undefined;
		EndIf;
		CellTemplate.CurrentArea.Format = FormatString;
		TemplateArea = ResultDocument.Join(CellTemplate);
		
		If CellTemplate.Parameters.Details <> Undefined Then
			Parameters.ReportDetails.Insert(TemplateArea.Name, CellTemplate.Parameters.Details);
		EndIf;
		
	EndDo;// by row cells
	
EndProcedure

Procedure DistributeItemsByLevels(Rows, DepthOfEverything, MatchingRowsToLevels, DepthCur = 0)
	
	If DepthCur > DepthOfEverything Then
		Return;
	EndIf;
	
	StringsList = MatchingRowsToLevels[DepthCur + 1];
	If StringsList = Undefined Then
		StringsList = New Array;
	EndIf;
	MatchingRowsToLevels.Insert(DepthCur + 1, StringsList);
	
	If Rows = Undefined Or Not Rows.Count() Then
		
		StringsList.Add(Undefined);
		DistributeItemsByLevels(Undefined, DepthOfEverything, MatchingRowsToLevels, DepthCur + 1);
		
	Else
		
		For Each IndicatorLine_1 In Rows Do
			
			StringsList.Add(IndicatorLine_1);
			DistributeItemsByLevels(IndicatorLine_1.Rows, DepthOfEverything, MatchingRowsToLevels, DepthCur + 1);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure MergeVertically(Document, TopRowNumber, Val NumberOfBins, ColumnNumber, AreaText = "", Center = False)
	
	Area = Document.Area(TopRowNumber, ColumnNumber, TopRowNumber + NumberOfBins - 1, ColumnNumber);
	
	If NumberOfBins <= 1 Then
		
		If Not IsBlankString(AreaText) Then
			Area.Text = AreaText;
		EndIf;
		
		Return;
	EndIf;
	
	Area.Merge();
	If Not IsBlankString(AreaText) Then
		Area.Text = AreaText;
	EndIf;
	If Center Then
		Area.HorizontalAlign = HorizontalAlign.Center;
		Area.VerticalAlign = VerticalAlign.Center;
	EndIf;
	
EndProcedure

Function RowTemplate(AppearanceTemplate, AreaName)
	
	RowTemplate = New Structure;
	RowTemplate.Insert("Factor",		 					AppearanceTemplate.GetArea(AreaName + "|Factor"));
	RowTemplate.Insert("IndicatorForIndicatorsInColumns", 
																	AppearanceTemplate.GetArea(AreaName + "|IndicatorForIndicatorsInColumns"));
	RowTemplate.Insert("ReportRowCode", 			AppearanceTemplate.GetArea(AreaName + "|ReportRowCode"));
	RowTemplate.Insert("Note", 						AppearanceTemplate.GetArea(AreaName + "|Note"));
	RowTemplate.Insert("Value", 								AppearanceTemplate.GetArea(AreaName + "|Value"));
	RowTemplate.Insert("HighlightedValue", 	AppearanceTemplate.GetArea(AreaName + "|HighlightedValue"));
	Return RowTemplate;
	
EndFunction

Function DetailsCell(TableDetails, TableRowData, ColumnName)
	
	ItemsKinds = TableDetails.ItemsKinds;
	
	ReportLineID_ = TableRowData.ReportItem;
	ItemKind = Common.ObjectAttributeValue(TableRowData.ReportItem, "ItemKind");
	If TableDetails.TableIndicatorsInColumns Then
		ReportLineID_ = TableRowData.DimensionValue_1;
	ElsIf TypeOf(ReportLineID_) = Type("CatalogRef.FinancialReportItems")
			And ItemKind = ItemsKinds.Dimension Then
		ReportLineID_ = ExtdimensionRate(ReportLineID_, ItemsKinds);
	EndIf;
	
	DecryptingString = TableDetails.Details[ReportLineID_];
	If DecryptingString = Undefined Then
		Return Undefined;
	EndIf;
	
	Details = DecryptingString[ColumnName];
	If TypeOf(Details) = Type("Structure") Then
		Details = Common.CopyRecursive(Details);
		ThisIsIndicator = ThisIsIndicator(Details.Factor.ItemKind, ItemsKinds);
		ListOfExtdimensionSpecies = New ValueList;
		If ThisIsIndicator Then
			DescriptionIndicator = TableDetails.Indicators[Details.Factor];
		ElsIf Details.Filter.Property("Factor") Then
			DescriptionIndicator = TableDetails.Indicators[Details.Filter.Factor];
		Else
			DescriptionIndicator = Undefined;
		EndIf;
		
		StringToDecrypt = TableRowData;
		While ValueIsFilled(StringToDecrypt) Do
			
			If StringToDecrypt.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
				
				DimensionValue_1   = StringToDecrypt.DimensionValue_1;
				NameOfDimensionColumn = StringToDecrypt.ColumnName;
				
				If ValueIsFilled(NameOfDimensionColumn) Then
					Details.Filter.Insert(NameOfDimensionColumn, DimensionValue_1);
					If DescriptionIndicator <> Undefined Then
						ExtdimensionOfIndicator = DescriptionIndicator.ExtDimension; // Structure of KeyAndValue
						If ExtdimensionOfIndicator.Property(NameOfDimensionColumn) Then
							ExtDimension = ExtdimensionOfIndicator[NameOfDimensionColumn]; // Structure of KeyAndValue
							If ListOfExtdimensionSpecies.FindByValue(ExtDimension.Kind) = Undefined Then
								ListOfExtdimensionSpecies.Add(ExtDimension.Kind);
							EndIf;
						EndIf;
						For Each FilterRows In Details.Filter Do
							If ExtdimensionOfIndicator.Property(FilterRows.Key) Then
								ExtDimension = ExtdimensionOfIndicator[FilterRows.Key]; // Structure of KeyAndValue
								If ListOfExtdimensionSpecies.FindByValue(ExtDimension.Kind) = Undefined Then
									ListOfExtdimensionSpecies.Add(ExtDimension.Kind);
								EndIf;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				
			EndIf;
			
			StringToDecrypt = StringToDecrypt.Parent;
			
		EndDo;
		
		If Details.Factor.ItemKind = ItemsKinds.Dimension Then
			Factor = ExtdimensionRate(Details.Factor, ItemsKinds);
			If Factor <> Undefined Then
				Details.Factor = Factor;
			EndIf;
		EndIf;
		
		If ListOfExtdimensionSpecies.Count() Then
			Details.Insert("ExtDimensionType", ListOfExtdimensionSpecies);
		EndIf;
		
	EndIf;
	
	Return Details;
	
EndFunction

Function MergeHorizontally(Document, LeftColumnNumber, Val NumberOfBins, LineNumber, AreaText = "", Center = False)
	
	If NumberOfBins <= 1 Then
		Return Undefined;
	EndIf;
	
	Area = Document.Area(LineNumber, LeftColumnNumber, LineNumber, LeftColumnNumber + NumberOfBins - 1);
	Area.Merge();
	If Not IsBlankString(AreaText) Then
		Area.Text = AreaText;
	EndIf;
	If Center Then
		Area.HorizontalAlign = HorizontalAlign.Center;
		Area.VerticalAlign = VerticalAlign.Center;
	EndIf;
	
	Return Area;
	
EndFunction

Procedure CircleArea(Area)
	
	FrameLine = New Line(SpreadsheetDocumentCellLineType.Solid);
	Area.TopBorder = FrameLine;
	Area.LeftBorder  = FrameLine;
	Area.RightBorder = FrameLine;
	
EndProcedure

Function NumberOfHeaderColumns(HeaderElement)
	
	ColumnsCount = HeaderElement.Rows.Count();
	NumberOfSubordinateColumns(HeaderElement, ColumnsCount);
	If ColumnsCount = 0 Then 
		Return 1;
	Else
		Return ColumnsCount;
	EndIf;
	
EndFunction

Procedure NumberOfSubordinateColumns(Column, ColumnsCount)
	
	For Each SubordinateItem In Column.Rows Do
		
		If SubordinateItem.Rows.Count() Then
			ColumnsCount = ColumnsCount + SubordinateItem.Rows.Count() - 1;
		EndIf;
		
		NumberOfSubordinateColumns(SubordinateItem, ColumnsCount);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region ReportDecryptionProceduresAndFunctions


// LongDesc
// 
// Parameters:
// 	ReportParameters - Structure - LongDesc:
// * IndicatorData - Structure - 	:
//  **Ref - CatalogRef.FinancialReportItems - 
Procedure DerivedItemDrillDown(ReportParameters)
	
	IndicatorData = ReportParameters.IndicatorData;
	ReverseSign = IndicatorData.ReverseSign;
	
	// Prepare the layout
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = Reports.FinancialReport.GetTemplate("DerivedItemDrillDown");
	SectionArea1 = Template.GetArea("Section3");
	
	///////////////////////////////////////////////////////////////////////////////////
	// Display the report title
	Area = Template.GetArea("Factor");
	Area.Parameters.Factor = IndicatorData.NameForPrinting;
	SpreadsheetDocument.Put(Area);
	OutputString(SpreadsheetDocument, SectionArea1);
	
	///////////////////////////////////////////////////////////////////////////////////
	// Output the parameters section
	AreaSectionHeader = Template.GetArea("SectionHeader_");
	AreaSectionHeader.Parameters.Title = "Parameters";
	SpreadsheetDocument.Put(AreaSectionHeader);
	SpreadsheetDocument.StartRowGroup();
	// Period
	Period = ReportParameters.ReportPeriod;
	PeriodAsString = TMReportFunctionsClientServer.GetPeriodPresentation(Period.BeginOfPeriod, Period.EndOfPeriod, False, ReportParameters.ReportLanguage);
	OutputString(SpreadsheetDocument, SectionArea1, NStr("vi = 'Kỳ';
														|ru = 'Период';
														|en = 'Period'; fa = 'دوره';
														|it = 'Periodo';
														|pl = 'Period';
														|tr = 'Dönem'")+": "+PeriodAsString);
	//The ratio of the amounts of
	MultiplierOfAmounts = ReportParameters.MultiplierOfAmounts;
	If MultiplierOfAmounts  <> Enums.NumberPresentationKinds.Unchanged Then
		OutputString(SpreadsheetDocument, SectionArea1, MultiplierOfAmounts);
	EndIf;
	
	SpreadsheetDocument.EndRowGroup();
	OutputString(SpreadsheetDocument, SectionArea1);

	
	///////////////////////////////////////////////////////////////////////////////////
	// Output the selection section
	If ReportParameters.Filter.Count() Then
		AreaSectionHeader.Parameters.Title = NStr("vi = 'Lọc';
													|ru = 'Отбор';
													|en = 'Filter'; fa = 'فیلتر';
													|it = 'Selezione';
													|pl = 'Filter';
													|tr = 'Filtre'");
		SpreadsheetDocument.Put(AreaSectionHeader);
		SpreadsheetDocument.StartRowGroup();
		For Each FilterElement In ReportParameters.Filter Do
			If ValueIsFilled(FilterElement.Value) Then
				Var_431_Template = "%1: %2";
				FilterValue = StrConcat(FilterElement.Value, ",");
				Text = StringFunctionsClientServer.SubstituteParametersToString(Var_431_Template, FilterElement.Key, FilterValue);
				OutputString(SpreadsheetDocument, SectionArea1, Text);
			EndIf;
		EndDo;
		SpreadsheetDocument.EndRowGroup();
		OutputString(SpreadsheetDocument, SectionArea1);
	EndIf;
	
	///////////////////////////////////////////////////////////////////////////////////
	// Output the formula text
	FormulaText = IndicatorData.Formula;
	If ReverseSign Then
		FormulaText = "-("+FormulaText+")";
	EndIf;
	AreaSectionHeader.Parameters.Title = NStr("vi = 'Công thức tính';
												|ru = 'Формула расчета';
												|en = 'Calculation formula'; fa = 'فرمول محاسبه';
												|it = 'Formula di calcolo';
												|pl = 'Formuła obliczenia';
												|tr = 'Hesaplama formülü'");
	SpreadsheetDocument.Put(AreaSectionHeader);
	SpreadsheetDocument.StartRowGroup();
	OutputString(SpreadsheetDocument, SectionArea1, FormulaText);
	SpreadsheetDocument.EndRowGroup();
	
	// We get the values of the operands of the formula
	FormulaText = "";
	FormulaOperands = GetOperandsOfFormula(IndicatorData, ReportParameters, FormulaText);
	
	///////////////////////////////////////////////////////////////////////////////////
	// Print the text of the formula with the substituted values
	If FormulaOperands.Count() Then
		If ReverseSign Then
			FormulaText = "-("+FormulaText+")";
		EndIf;
		AreaSectionHeader.Parameters.Title = NStr("vi = 'Tính toán';
													|ru = 'Вычисления';
													|en = 'Calculations'; fa = 'Calculations';
													|it = 'Calcoli';
													|pl = 'Calculations';
													|tr = 'Hesaplamalar'");
		SpreadsheetDocument.Put(AreaSectionHeader);
		SpreadsheetDocument.StartRowGroup();
		OutputString(SpreadsheetDocument, SectionArea1, FormulaText);
		SpreadsheetDocument.EndRowGroup();
	EndIf;
	
	///////////////////////////////////////////////////////////////////////////////////
	// Output the calculation result
	Area = Template.GetArea("IndicatorValue");
	Area.Parameters.Result = IndicatorData.Value;
	SpreadsheetDocument.Put(Area);
	OutputString(SpreadsheetDocument, SectionArea1);
	OutputString(SpreadsheetDocument, SectionArea1);
	
	///////////////////////////////////////////////////////////////////////////////////
	// Output the values of the operands
	AreaSectionHeader.Parameters.Title = NStr("vi = 'Toán tử của công thức';
												|ru = 'Операнды формулы';
												|en = 'Formula operands'; fa = 'عملوندهای فرمول';
												|it = 'Formula operandi';
												|pl = 'Operandy formuły';
												|tr = 'Formül işlenenleri'");
	SpreadsheetDocument.Put(AreaSectionHeader);
	
	Area = Template.GetArea("OperandHeader_");
	SpreadsheetDocument.Put(Area);
	
	Area = Template.GetArea("Operand");
	For Each Operand In FormulaOperands Do
		Area.Parameters.Fill(Operand);
		DetailsData = New Structure("Factor, StartDate, EndDate", Operand.ReportItem);
		DetailsData.Insert("StartDate", Period.BeginOfPeriod);
		DetailsData.Insert("EndDate", Period.EndOfPeriod);
		If IndicatorData.Property("ExtDimensionType") Then
			DetailsData.Insert("Filter",       IndicatorData.Filter);
			DetailsData.Insert("ExtDimensionType", IndicatorData.ExtDimensionType);
		EndIf;
		Area.Parameters.Factor = DetailsData;
		SpreadsheetDocument.Put(Area);
	EndDo;
	
	///////////////////////////////////////////////////////////////////////////////////
	// Set additional parameters of a tabular document
	SpreadsheetDocument.BlackAndWhite = True;
	SpreadsheetDocument.FitToPage = True;
	
	ReportParameters.Insert("Result", SpreadsheetDocument);
	
EndProcedure

Procedure OutputString(SpreadsheetDocument, Area, Text = "")
	
	Area.Parameters.String = Text;
	SpreadsheetDocument.Put(Area);
	
EndProcedure

Function GetOperandsOfFormula(ElementData, ReportParameters, FormulaText)
	
	ReportKind = ReportParameters.ReportKind;
	Accuracy = ElementData.Accuracy;
	If TypeOf(Accuracy) <> Type("Number") Then
		Accuracy = 0;
	EndIf;
	
	FormatString = ReportParameters.ValueFormat_;
	If StrFind(FormatString, "NS=") = 0 And Accuracy >= 0 Then
		FormatString = FormatString + "; NFD=" + Accuracy;
	EndIf;
	
	FinReports = FinancialReportingServer;
	TreeDiagram = Reports.FinancialReport.GetTemplate("DerivedItemOperands");
	TreeComposer = FinReports.SchemaComposer(TreeDiagram);
	FinReports.SetLayoutParameter(TreeComposer, "ReportKind", ReportKind);
	FinReports.SetLayoutParameter(TreeComposer, "ReportItem", ElementData.Ref);
	AttributeCache = FinReports.CacheAdditionalDetails(ReportKind);
	FinReports.SetLayoutParameter(TreeComposer, "AttributeCache", AttributeCache);
	
	FormulaOperands = FinReports.UploadDCSResults(TreeDiagram, TreeComposer);
	FormulaText = ElementData.Formula;
	IndicatorParameters = ParametersForObtainingMetric(ReportParameters);
	
	If ElementData.ExtDimensionType <> Undefined Then
		For Each FilterIndicator_ In ElementData.Filter Do
			
			If StrFind(FilterIndicator_.Key, "ExtDimension") > 0 Then
				
				ExtDimensionNumber = Number(StrReplace(FilterIndicator_.Key, "ExtDimension", ""));
				If ExtDimensionNumber  > ElementData.ExtDimensionType.Count() Then
					Break;
				EndIf;
				
				ExtdimensionSelectionStructure = New Structure;
				ExtdimensionSelectionStructure.Insert("Kind", ElementData.ExtDimensionType[ExtDimensionNumber - 1].Value);
				ExtdimensionSelectionStructure.Insert("HasSettings", True);
				ExtdimensionSelectionStructure.Insert("Description", FilterIndicator_.Key);
				FilterExtDimension = New DataCompositionFilter;
				ElementOfExtdimensionSelection = FilterExtDimension.Items.Add(Type("DataCompositionFilterItem"));
				ElementOfExtdimensionSelection.ComparisonType = DataCompositionComparisonType.Equal;
				ElementOfExtdimensionSelection.LeftValue = New DataCompositionField(FilterIndicator_.Key);
				ElementOfExtdimensionSelection.RightValue = FilterIndicator_.Value;
				FilterForDCS = New Structure("Filter", FilterExtDimension);
				ExtdimensionSelectionStructure.Insert("Filter", New ValueStorage(FilterForDCS));
				
				If IndicatorParameters.ExtDimension = Undefined Then
					IndicatorParameters.ExtDimension = New Structure;
				EndIf;
				IndicatorParameters.ExtDimension.Insert(FilterIndicator_.Key, ExtdimensionSelectionStructure);
				
			EndIf;
			
		EndDo;
	EndIf;
	
	For Each Operand In FormulaOperands Do
		FIlterRow = "";
		If Operand.HasSettings Then
			FilterValue = Operand.AdditionalSelection; //ValueStorage
			FilterSettings = FilterValue.Get();
			If FilterSettings <> Undefined Then
				FIlterRow = String(FilterSettings.Filter);
			EndIf;
		EndIf;
		Operand.Filter = FIlterRow;
		Operand.TotalPresentation = SummaryTypePresentation(Operand.TotalType, Operand.OpeningBalance);
		OperandValues_ = ValueOfSimpleIndicator(IndicatorParameters, Operand);
		If OperandValues_.Count() Then
			Value = OperandValues_.Total("Value");
			Operand.Value = Format(?(Accuracy >= 0, Value, Round(Value, Accuracy)), FormatString);
			Result = OperandValues_[0];
			ValueRow = Format(?(Accuracy >= 0, Result.Value, Round(Result.Value, Accuracy)), FormatString);
			If Value = 0 Then
				ValueRow = "0";
			EndIf;
			FormulaText = StrReplace(FormulaText, "["+Operand.Id+"]", ValueRow);
		EndIf;
	EndDo;
	
	If IsBlankString(FormulaText) Then
		FormulaText = "0";
	EndIf;
	
	Return FormulaOperands;
	
EndFunction

Function SummaryTypePresentation(TotalType, OpeningBalance)
	
	Result = "";
	TypesOfTotals = Enums.TypesOfTotals;
	If TotalType = TypesOfTotals.Balance_ And OpeningBalance Then
		Result = NStr("vi = 'Dư đầu kỳ';
						|ru = 'Сальдо на начало периода';
						|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
						|it = 'Saldo all''inizio del periodo';
						|pl = 'Saldo na początku okresu';
						|tr = 'Dönem başı bakiyesi'");
	ElsIf TotalType = TypesOfTotals.Balance_Dr And OpeningBalance Then
		Result = NStr("vi = 'Số dư Nợ bắt đầu';
						|ru = 'Дебетовое сальдо на начало периода';
						|en = 'Start debit balance'; fa = 'Start debit balance';
						|it = 'Saldo a debito all''inizio del periodo';
						|pl = 'Saldo debetowe na początek okresu';
						|tr = 'Dönem başı borç bakiyesi'");
	ElsIf TotalType = TypesOfTotals.Balance_Cr And OpeningBalance Then
		Result = NStr("vi = 'Số dư Có đầu kỳ';
						|ru = 'Кредитовое сальдо на начало периода';
						|en = 'Start credit balance'; fa = 'Start credit balance';
						|it = 'Saldo a credito all''inizio del periodo';
						|pl = 'Saldo kredytowe na początek okresu';
						|tr = 'Dönem başı kredi bakiyesi'");
	ElsIf TotalType = TypesOfTotals.Balance_ And Not OpeningBalance Then
		Result = NStr("vi = 'Dư cuối kỳ';
						|ru = 'Сальдо на конец периода';
						|en = 'Closing balance'; fa = 'مانده پایان دوره';
						|it = 'Saldo alla fine del periodo';
						|pl = 'Saldo na koniec okresu';
						|tr = 'Dönem sonu bakiyesi'");
	ElsIf TotalType = TypesOfTotals.Balance_Dr And Not OpeningBalance Then
		Result = NStr("vi = 'Số dư Nợ cuối kỳ';
						|ru = 'Дебетовое сальдо на конец периода';
						|en = 'Closing debit balance'; fa = 'Closing debit balance';
						|it = 'Saldo a debito alla fine del periodo';
						|pl = 'Saldo debetowe na koniec okresu';
						|tr = 'Dönem sonu borç bakiyesi'");
	ElsIf TotalType = TypesOfTotals.Balance_Cr And Not OpeningBalance Then
		Result = NStr("vi = 'Số dư Có cuối kỳ';
						|ru = 'Кредитовое сальдо на конец периода';
						|en = 'Closing credit balance'; fa = 'Closing credit balance';
						|it = 'Saldo a credito alla fine del periodo';
						|pl = 'Saldo kredytowe na koniec okresu';
						|tr = 'Dönem sonu kredi bakiyesi'");
	ElsIf TotalType = TypesOfTotals.Turnover Then
		Result = NStr("vi = 'Phát sinh trong kỳ';
						|ru = 'Оборот за период';
						|en = 'Turnover for the period'; fa = 'Turnover for the period';
						|it = 'Fatturato per il periodo';
						|pl = 'Obrót za okres';
						|tr = 'Dönem cirosu'");
	ElsIf TotalType = TypesOfTotals.TurnoverDr Then
		Result = NStr("vi = 'Phát sinh nợ trong kỳ';
						|ru = 'Дебетовый оборот за период';
						|en = 'Debit turnover for a period'; fa = 'Debit turnover for a period';
						|it = 'Fatturato a debito per il periodo';
						|pl = 'Obrót debetowy za okres';
						|tr = 'Dönem için borç cirosu'");
	ElsIf TotalType = TypesOfTotals.TurnoverCr Then
		Result = NStr("vi = 'Phát sinh Có trong kỳ';
						|ru = 'Кредитовый оборот за период';
						|en = 'Credit turnover for the period'; fa = 'Credit turnover for the period';
						|it = 'Fatturato a credito per il periodo';
						|pl = 'Obrót kredytowy za okres';
						|tr = 'Dönem için alacak cirosu'");
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctionsReporting

Function ReportPeriod(BeginOfPeriod = Undefined,EndOfPeriod = Undefined) Export
	
	Return New Structure("BeginOfPeriod,EndOfPeriod,Periodicity",
							 BeginOfPeriod,EndOfPeriod,New Array);
	
EndFunction

// Returns:
// 	Structure - LongDesc:
//  * StartDate - Date - the beginning of the period.
//  * EndDate - Date - end of the period.
// 
Function PeriodDetails(StartDate = Undefined, EndDate = Undefined)
	
	Return New Structure("StartDate,EndDate", StartDate, EndDate);
	
EndFunction


// LongDesc
// 
// Parameters:
// 	Item - ValueTreeRow, Undefined - LongDesc:
// * Parent - CatalogRef.FinancialReportItems -
// * ItemKind - EnumRef.FinancialReportItemKinds -
// * ReportItem - CatalogRef.FinancialReportItems -
// * ReportItemIsAnAssociatedItem - CatalogRef.FinancialReportItems -
// * NameForPrinting - String -
// * ReverseSign - Boolean -
// * HasSettings - Boolean -
// * LinkedItem1 - CatalogRef.FinancialReportItems -
// * Comment - String -
// * AdditionalSelection - ValueStorage -
// * ThisIsReference - Boolean -
// * Code - String -
// * AddressOfItemStructure - String -
// * AccountIndicatorDimension - ChartOfAccountsRef, CatalogRef.FinancialReportItems -
// * ReportKind - CatalogRef.FinancialReportTypes -
// * Note - CatalogRef.FinancialReportTypes -
// * Accuracy - Number -
// Returns:
// 	String - A unique string formed based on the data of the element
Function ItemID(Item) Export
	
	If TypeOf(Item) = Type("ValueTreeRow") Then
		ElementViewString = NameOfReference(Item.ItemKind) + String(Item.Code);
	ElsIf TypeOf(Item) = Type("CatalogRef.FinancialReportItems") Then
		Attributes = Common.ObjectAttributesValues(Item,"Code,ItemKind");
		ElementViewString = NameOfReference(Attributes.ItemKind) + String(Attributes.Code);
	ElsIf TypeOf(Item) = Type("Structure") Then
		ElementViewString = Item.Id;
	Else
		ElementViewString = StrReplace(Title(String(Item))," ","");
	EndIf;
	
	ElementViewString = StringFunctionsClientServer.ReplaceCharsWithOther("()/",ElementViewString,"");
	
	Return ElementViewString;
	
EndFunction

Procedure LoadIntoValueTable(SourceTable1, DestinationTable)
	
	CommonClientServer.SupplementTable(SourceTable1, DestinationTable);
	
EndProcedure

Function NameOfReference(InitialString)
	
	Return StrReplace(Title(String(InitialString))," ","");
	
EndFunction


// LongDesc
// 
// Returns:
// 	Structure - LongDesc:
// * ErrorsMessages - Array of UserMessage - 
// * Dimensions - ValueList -
// * ExtDimension - Structure of KeyAndValue -
// * FilterReport_ - ValueList -
// * ReportIntervals - See ReportIntervals
// * ReportPeriod - See ReportPeriod
// * Resource - String -
// * Factor - Structure, ValueTableRow, Undefined, ValueTreeRow - LongDesc:
Function NewParametersForGettingMetric()
	
	Result = New Structure;
	Result.Insert("Factor");
	Result.Insert("Resource", "Sum");
	Result.Insert("ReportPeriod", ReportPeriod());
	Result.Insert("ReportIntervals");
	Result.Insert("FilterReport_", New ValueList);
	Result.Insert("ExtDimension");
	Result.Insert("Dimensions", New ValueList);
	Result.Insert("ErrorsMessages");
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - Description of the indicator table:
//	* ThisIsArbitrary - Boolean -
//	* TableIndicatorsInColumns - Boolean - 
//	* Indicators - Map of KeyAndValue- description of indicators:
//	 ** Key     - String - the name of the metric.
//	 ** Value - See DescriptionIndicator 
//	* Periodicity - Array -  
//	* ResourceString_ - String - 
//	* IndicatorValues - See IndicatorValues
//	* TableHeader - Structure - 
//	* NumberOfHeaderLevels - Number -
//	* TotalColumnLevels - Number -
//	* ColumnNumber - Number - 
//	* Resources - Array of String -
//	* Details - Map - 
//	* ColumnTree - See DescriptionOfReportColumnTree
//	* StringTree - See DescriptionOfReportRowTree
//	* CurrentLevel - ValueTreeRowCollection - 
//	* CurrentParent - ValueTreeRow -
//	* CurrentIndicator - ValueTreeRow -
//	* ReportColumns - See DescriptionOfReportColumns
//	* VerticalDimensions - Map -
//	* RegisterDimensions - Array of String - 
//	* TableMeasurements - Array of String - 
//	* RowDimensions - Array of String - 
//	* CurGroupings - Structure - 
//	* AnalystDescription - Map - 
//
Function TableDetails(ThisIsArbitrary = False, TableIndicatorsInColumns = False)
	
	TableDetails = New Structure;
	TableDetails.Insert("ThisIsArbitrary",                   ThisIsArbitrary);
	TableDetails.Insert("TableIndicatorsInColumns",        TableIndicatorsInColumns);
	TableDetails.Insert("Indicators",                        New Map);
	TableDetails.Insert("Periodicity",                     New Array);
	TableDetails.Insert("ResourceString_",                    Undefined);
	
	// Common row tree and column tree columns
	StringTree = DescriptionOfReportRowTree();
	
	// Let's add the column table
	ColumnTree = DescriptionOfReportColumnTree();
	
	IndicatorValues = IndicatorValues();
	
	DescriptionOfColumns = DescriptionOfReportColumns();
	
	TableDetails.Insert("IndicatorValues",               IndicatorValues);
	TableDetails.Insert("TableHeader",                      Undefined);
	TableDetails.Insert("NumberOfHeaderLevels",            0);
	TableDetails.Insert("TotalColumnLevels",               0);
	TableDetails.Insert("ColumnNumber",                      1);
	TableDetails.Insert("Resources",                           New Array);
	TableDetails.Insert("Details",                       New Map);
	
	TableDetails.Insert("ColumnTree",                     ColumnTree);
	TableDetails.Insert("StringTree",                       StringTree);
	
	TableDetails.Insert("CurrentLevel",                    Undefined);
	TableDetails.Insert("CurrentParent",                   Undefined);
	TableDetails.Insert("CurrentIndicator",                 Undefined);
	
	TableDetails.Insert("ReportColumns",                     DescriptionOfColumns);
	TableDetails.Insert("VerticalDimensions",           New Map);
	
	TableDetails.Insert("RegisterDimensions",                 New Array);
	TableDetails.Insert("TableMeasurements",                  New Array);
	TableDetails.Insert("RowDimensions",                    New Array);
	TableDetails.Insert("CurGroupings",                New Structure);
	TableDetails.Insert("AnalystDescription",                  New Map);
	
	If ThisIsArbitrary Then
		TableDetails.Insert("IndicatorLine_1" ,             Undefined);
		TableDetails.Insert("ColumnOfFactor",             Undefined);
	EndIf;
	
	Return TableDetails;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * ReportItem - CatalogRef.FinancialReportItems - 
// * NameForPrinting - String - 
// * ReportRowCode - String - 
// * Note - String - 
Function IndicatorValues()
	
	StringType = New TypeDescription("String",,New StringQualifiers(0));
	ElementReferenceType = New TypeDescription("CatalogRef.FinancialReportItems");
	
	IndicatorValues = New ValueTable;
	IndicatorValues.Columns.Add("ReportItem" ,        ElementReferenceType);
	IndicatorValues.Columns.Add("NameForPrinting", StringType);
	IndicatorValues.Columns.Add("ReportRowCode",       StringType);
	IndicatorValues.Columns.Add("Note",            StringType);
	
	Return IndicatorValues;
	
EndFunction

// Returns:
// 	ValueTable - Contains a description of the report columns:
// * ColumnName - String - 
// * ItemKind - EnumRef.FinancialReportItemKinds - 
// * ReportItem - CatalogRef.FinancialReportItems - 
// * NameForPrinting - String- 
// * ReverseSign - Boolean -
// * Operands - Array -
// * Filter - Structure -
// * TotalLevel - Number -
// * ThisIsTotal - Boolean - 
// * SelectItem - Boolean -
// * Accuracy - Number -
Function DescriptionOfReportColumns()
	
	StringType = New TypeDescription("String",,New StringQualifiers(0));
	NumberType =  New TypeDescription("Number");
	BooleanType = New TypeDescription("Boolean");
	ElementReferenceType = New TypeDescription("CatalogRef.FinancialReportItems");
	
	DescriptionOfColumns = New ValueTable;
	DescriptionOfColumns.Columns.Add("ColumnName",                StringType);
	DescriptionOfColumns.Columns.Add("ItemKind");
	DescriptionOfColumns.Columns.Add("ReportItem",             ElementReferenceType);
	DescriptionOfColumns.Columns.Add("NameForPrinting",     StringType);
	DescriptionOfColumns.Columns.Add("ReverseSign",              BooleanType);
	DescriptionOfColumns.Columns.Add("Operands");
	DescriptionOfColumns.Columns.Add("Filter");
	DescriptionOfColumns.Columns.Add("TotalLevel",              NumberType);
	DescriptionOfColumns.Columns.Add("ThisIsTotal",                   BooleanType);
	DescriptionOfColumns.Columns.Add("SelectItem",           BooleanType);
	DescriptionOfColumns.Columns.Add("Accuracy");
	
	Return DescriptionOfColumns;
	
EndFunction

// Returns:
// 	ValueTree - LongDesc:
// 	 * ItemKind - EnumRef.FinancialReportItemKinds - 
// 	 * ItemID - String -
// 	 * ReportItem - CatalogRef.FinancialReportItems - 
// 	 * NameForPrinting - String -
// 	 * DisplayItemTitle - Boolean -
// 	 * SelectItem - Boolean -
// 	 * LocationOfTotal - Number - 
// 	 * ReverseSign - Boolean -
// 	 * PeriodPresentation - String -
// 	 * Periodicity - EnumRef.Periodicity -
// 	 * ColumnName - String -
// 	 * Sort - String -
// 	 * Accuracy - Number -
// 	 * ExtDimensionType - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
// 	 * ReportRowCode - String -
// 	 * Note - String -
// 	 * ThisIsReference - Boolean - 
// 	 * DimensionValue_1 - Structure -
//
Function DescriptionOfReportRowTree()
	
	BooleanType = New TypeDescription("Boolean");
	 
	Result = DescriptionOfReportTree();
	Result.Columns.Add("ReportRowCode");
	Result.Columns.Add("Note");
	Result.Columns.Add("ThisIsReference", BooleanType);
	Result.Columns.Add("DimensionValue_1");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTree - LongDesc:
// 	 * ItemKind - EnumRef.FinancialReportItemKinds -
// 	 * ItemID - String -
// 	 * ReportItem - CatalogRef.FinancialReportItems -
// 	 * NameForPrinting - String -
// 	 * DisplayItemTitle - Boolean -
// 	 * SelectItem - Boolean -
// 	 * LocationOfTotal - Number - 
// 	 * ReverseSign - Boolean -
// 	 * PeriodPresentation - String -
// 	 * Periodicity - EnumRef.Periodicity -
// 	 * ColumnName - String -
// 	 * Sort - String -
// 	 * Accuracy - Number -
// 	 * ExtDimensionType - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
// 	 * Operands - Array of String -
// 	 * SubordinateElements - Number - 
// 	 * IndicatorValue - See EmptyMetricValue
// 	 * LongDesc - ValueTableRow -  
Function DescriptionOfReportColumnTree()
	
	NumberType = New TypeDescription("Number");
	
	Result = DescriptionOfReportTree();
	Result.Columns.Add("Operands");
	Result.Columns.Add("SubordinateElements", NumberType);
	Result.Columns.Add("IndicatorValue");
	Result.Columns.Add("LongDesc");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTree - Common row tree and column tree columns:
// 	 * ItemKind - EnumRef.FinancialReportItemKinds -
// 	 * ItemID - String -
// 	 * ReportItem - CatalogRef.FinancialReportItems -
// 	 * NameForPrinting - String -
// 	 * DisplayItemTitle - Boolean -
// 	 * SelectItem - Boolean -
// 	 * LocationOfTotal - Number - 
// 	 * ReverseSign - Boolean -
// 	 * PeriodPresentation - String -
// 	 * Periodicity - EnumRef.Periodicity - 
// 	 * ColumnName - String -
// 	 * Sort - String- 
// 	 * Accuracy - Number -
// 	 * ExtDimensionType - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
Function DescriptionOfReportTree()
	
	BooleanType = New TypeDescription("Boolean");
	 
	Result = New ValueTree;
	Result.Columns.Add("ItemKind");
	Result.Columns.Add("ItemID");
	Result.Columns.Add("ReportItem");
	Result.Columns.Add("NameForPrinting");
	Result.Columns.Add("DisplayItemTitle", BooleanType);
	Result.Columns.Add("SelectItem",           BooleanType);
	Result.Columns.Add("LocationOfTotal");
	Result.Columns.Add("ReverseSign",              BooleanType);
	Result.Columns.Add("PeriodPresentation");
	Result.Columns.Add("Periodicity");
	Result.Columns.Add("ColumnName");
	Result.Columns.Add("Sort");
	Result.Columns.Add("Accuracy");
	Result.Columns.Add("ExtDimensionType");
	
	Return Result;
	
EndFunction

// Returns:
// 	Structure - Description:
// * LongDesc - ValueTreeRow - 
// * String - ValueTreeRow - 
// * Column - ValueTreeRow - 
// 
Function DescriptionIndicator(LongDesc= Undefined, String = Undefined, Column = Undefined)
	
	Return New Structure("LongDesc, String, Column", LongDesc, String, Column);
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * ItemKind - EnumRef.FinancialReportItemKinds - 
// * DisplayItemTitle - Boolean -
// * NameForPrinting - String - 
// * ReportItem - ValueTreeRow - 
// * LongDesc - Structure -
Function DescriptionOfReportBlock()
	
	BlockDescription = New Structure("ItemKind,DisplayItemTitle,NameForPrinting,ReportItem,LongDesc");
	Return BlockDescription;
	
EndFunction

Function PrintTableData()
	
	DataToPrint = New Structure;
	DataToPrint.Insert("ItemsKinds");
	DataToPrint.Insert("StringTree");
	DataToPrint.Insert("IndicatorValues");
	DataToPrint.Insert("NumberOfHeaderLevels");
	DataToPrint.Insert("ReportColumns");
	DataToPrint.Insert("Details");
	DataToPrint.Insert("Resources");
	DataToPrint.Insert("TableIndicatorsInColumns");
	DataToPrint.Insert("TableHeader");
	DataToPrint.Insert("ThisIsArbitrary");
	DataToPrint.Insert("Indicators");
	
	Return DataToPrint;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ReportIntervals - See ReportIntervals
// 	Dimensions - Undefined, ValueList - LongDesc
// 	ExtDimension - Structure of KeyAndValue - LongDesc
// 		
// Returns:
// 	ValueTable - LongDesc:
// * Factor - CatalogRef.FinancialReportItems -
// * RowCode - String -
// * Note - String -
// * StartDate - Date -
// * EndDate - Date -
// * YearPeriod - EnumRef.Periodicity - 
// * HalfYearPeriod - EnumRef.Periodicity -
// * QuarterPeriod - EnumRef.Periodicity -
// * MonthPeriod - EnumRef.Periodicity -
// 	
Function EmptyMetricValue(ReportIntervals, Dimensions = Undefined, ExtDimension = Undefined)
	
	DimensionsTypes = New Map;
	DimensionsTypes.Insert("Organization",New TypeDescription("CatalogRef.Companies"));
	DimensionsTypes.Insert("Department",New TypeDescription("CatalogRef.BusinessStructure"));
	DimensionsTypes.Insert("LineOfBusiness",New TypeDescription("CatalogRef.LinesOfBusiness"));
	
	Result = ReportIntervals.Copy();
	Result.Columns.Add("Value",  New TypeDescription("Number"));
	If Dimensions <> Undefined Then
		For Each Dimension In Dimensions Do
			Result.Columns.Add(Dimension.Value, DimensionsTypes[Dimension.Value], Dimension.Presentation);
			If Dimension.Value = "ExtDimension1" Then
				Result.Columns.Add("ExtDimensionType",, "ExtDimensionType");
			EndIf;
		EndDo;
	EndIf;
	
	If ExtDimension <> Undefined Then
		For Each ExtdimensionOfIndicator In ExtDimension Do
			CurExtdimension = ExtdimensionOfIndicator.Value; // Structure of KeyAndValue
			If Result.Columns.Find(ExtdimensionOfIndicator.Key) = Undefined Then
				Result.Columns.Add(ExtdimensionOfIndicator.Key, CurExtdimension.Kind.ValueType, CurExtdimension.Description);
			EndIf;
		EndDo;
	EndIf;
	
	Result.Columns.Add("EmptyValue", New TypeDescription("Boolean"));
	Result[0].EmptyValue = True;
	
	Return Result;
	
EndFunction

Function ThisIsIndicator(ItemKind, ItemsKinds, ThisIsReference = False)
	
	Return ItemKind = ItemsKinds.MonetaryIndicator
			Or ItemKind = ItemsKinds.NonMonetaryItem 
			Or ItemKind = ItemsKinds.DerivedItem
			Or ItemKind = ItemsKinds.TotalByGroup And ThisIsReference;
	
EndFunction

Procedure AddErrorMessage(ArrayOfMessages, MessageToUserText, DataKey = Undefined)
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.DataKey = DataKey;
	
	ArrayOfMessages.Add(Message);
	
EndProcedure

// The ExtDimension indicator.
// 
// Parameters:
//  Item - ValueTreeRow -
//  ItemsKinds - EnumRef.FinancialReportItemKinds
// 
// Returns:
//  Undefined - Extdimension Rate
Function ExtdimensionRate (Val Item, ItemsKinds) 
	
	While ValueIsFilled(Item.Parent) Do
		If ThisIsIndicator(Item.Parent.ItemKind, ItemsKinds) Then
			Return Item.Parent;
		EndIf;
		Item = Item.Parent;
	EndDo; 
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfStandardAccountingReports

Procedure SetCurrencyGrouping(SettingsComposer, Enable)
	
	CurrencyGrouping_ = FinancialReportingServer.FindGroup1(SettingsComposer.Settings.Structure, "Currency");
	
	If CurrencyGrouping_ = Undefined Then
		CurrencyGrouping_ = FinancialReportingServer.FindGroup1(SettingsComposer.Settings.Structure, "CurrencyWithoutHeader");
		If CurrencyGrouping_ <> Undefined Then
			CurrencyGrouping_.Name = "Currency";
		EndIf;
	EndIf;
	
	If CurrencyGrouping_ <> Undefined Then
		ParentGrouping_ = CurrencyGrouping_.Parent;
		
		If TypeOf(ParentGrouping_) = Type("DataCompositionGroup")
		And ParentGrouping_.Name = "NotTitleOutput" Then
			CurrencyGrouping_.Name = "CurrencyWithoutHeader";
		EndIf;
		
		If CurrencyGrouping_.Use <> Enable Then
			CurrencyGrouping_.Use = Enable;
		EndIf;
		For Each SubordinateGrouping In CurrencyGrouping_.Structure Do
			ExistingGrouping = Undefined;
			For Each Item In SubordinateGrouping.GroupFields.Items Do
				FindGroupingByField(ParentGrouping_.Structure, String(Item.Field), ExistingGrouping, CurrencyGrouping_);
				Break;
			EndDo;
			If Not ExistingGrouping = Undefined Then 
				ParentGrouping_.Structure.Delete(ExistingGrouping);
			EndIf;
			If Not CurrencyGrouping_.Use Then
				If TypeOf(ParentGrouping_) = Type("DataCompositionTableGroup") Then
					NewGrouping = ParentGrouping_.Structure.Add();
				Else
					NewGrouping = ParentGrouping_.Structure.Add(Type("DataCompositionGroup"));
				EndIf;
				MoveDimension(SubordinateGrouping, NewGrouping);
			EndIf;
		EndDo;
		
		ID = SettingsComposer.UserSettings.GetIDByObject(CurrencyGrouping_);
		CustomGrouping = SettingsComposer.UserSettings.GetObjectByID(ID);
		
		If CustomGrouping <> Undefined
		   And CustomGrouping.Use <> Enable Then
			CustomGrouping.Use = Enable;
			SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
		EndIf;
	EndIf;
	
EndProcedure

Procedure MoveDimension(SourceGrouping, GroupingReceiver, IncludingSubordinates = True)
	
	GroupingReceiver.Use 	= SourceGrouping.Use; 
	GroupingReceiver.Name 			= SourceGrouping.Name; 
	
	For Each Item In SourceGrouping.Selection.Items Do 
		AddFieldsToReportStructure(GroupingReceiver.Selection.Items,Item) 
	EndDo; 
		
	For Each Item In SourceGrouping.Filter.Items Do 
		AddSelectionToReportStructure(GroupingReceiver.Filter.Items,Item); 
	EndDo; 
	
	For Each Item In SourceGrouping.OutputParameters.Items Do 
		AddOutputParametersToReportStructure(GroupingReceiver.OutputParameters.Items,Item); 
	EndDo; 
	
	For Each Item In SourceGrouping.GroupFields.Items Do 
		
		If TypeOf(Item) = Type("DataCompositionGroupField") Then 
			
			NewElement = GroupingReceiver.GroupFields.Items.Add(TypeOf(Item)); 
			FillPropertyValues(NewElement, Item, 
					"Use,Field,GroupType,AdditionType,BeginOfPeriod,EndOfPeriod");
			
		ElsIf TypeOf(Item) = Type("DataCompositionAutoSelectedField") Then 
			
			NewElement = GroupingReceiver.GroupFields.Items.Add(TypeOf(Item)); 
			NewElement.Use = Item.Use; 
			
		EndIf; 
		
	EndDo; 
	
	For Each Item In SourceGrouping.Order.Items Do 
		AddOrderToReportStructure(GroupingReceiver.Order.Items,Item); 
	EndDo; 
	
	For Each Item In SourceGrouping.ConditionalAppearance.Items Do 
		AddConditionalAppearanceToReportStructure(GroupingReceiver.ConditionalAppearance.Items,Item); 
	EndDo; 
	
	If IncludingSubordinates Then
		For Each LowerLevelStructure In SourceGrouping.Structure Do 
			
			If TypeOf(GroupingReceiver) = Type("DataCompositionTableGroup") Then
				NewGrouping = GroupingReceiver.Structure.Add();
			Else
				NewGrouping = GroupingReceiver.Structure.Add(Type("DataCompositionGroup"));
			EndIf;
			
			MoveDimension(LowerLevelStructure, NewGrouping) 
		EndDo; 
	EndIf;
	
EndProcedure

Procedure FindGroupingByField(Groups, FieldName, FoundGrouping, GroupingException = Undefined)
	
	For Each Group In Groups Do

		If Group = GroupingException Then
			Continue;
		EndIf;
		
		If TypeOf(Group) = Type("DataCompositionTable") Then
			
			FindGroupingByField(Group.Rows, FieldName, FoundGrouping);
			If FoundGrouping <> Undefined Then
				Return;
			EndIf;
			FindGroupingByField(Group.Columns, FieldName, FoundGrouping);
			If FoundGrouping <> Undefined Then
				Return;
			EndIf; 
			
		ElsIf TypeOf(Group) = Type("DataCompositionGroup")
			Or TypeOf(Group) = Type("DataCompositionTableGroup") Then
			
			If Group.GroupFields.Items.Count() 
				And Group.GroupFields.Items[0].Field = New DataCompositionField(FieldName) Then
				FoundGrouping = Group;
				Return;
			EndIf;
			
			FindGroupingByField(Group.Structure, FieldName, FoundGrouping);
			
			If FoundGrouping <> Undefined Then
				Return;
			EndIf;
			
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure AddFieldsToReportStructure(ReceiverStructure, Item)
	
	If TypeOf(Item) = Type("DataCompositionSelectedField") Then
		
		NewElement = ReceiverStructure.Add(TypeOf(Item));
		FillPropertyValues(NewElement, Item, "Title,Use,Field");
		
	ElsIf TypeOf(Item) = Type("DataCompositionAutoSelectedField") Then
		
		NewElement = ReceiverStructure.Add(TypeOf(Item));
		NewElement.Use = Item.Use;
		
	ElsIf TypeOf(Item) = Type("DataCompositionSelectedFieldGroup") Then
		
		NewElement = ReceiverStructure.Add(TypeOf(Item));
		FillPropertyValues(NewElement, Item, "Title,Use,Placement,Field");
		For Each StructureItem In Item.Items Do
			AddFieldsToReportStructure(NewElement.Items, StructureItem);
		EndDo;
		
	EndIf;
	
EndProcedure 

Procedure AddOutputParametersToReportStructure(ReceiverStructure,Item) 
	
	NewElement = ReceiverStructure.Find(String(Item.Parameter)); 
	NewElement.Value = Item.Value; 
	NewElement.Use = Item.Use; 
	For Each Item In Item.NestedParameterValues Do 
		AddOutputParametersToReportStructure(NewElement.NestedParameterValues,Item); 
	EndDo; 
	
EndProcedure 

Procedure AddSelectionToReportStructure(ReceiverStructure, Item)
	
	If TypeOf(Item) = Type("DataCompositionFilterItem") Then 
		
		NewElement = ReceiverStructure.Add(TypeOf(Item));
		FillPropertyValues(NewElement, Item, 
			"ComparisonType,Use,LeftValue,RightValue,Presentation,Application,ViewMode");
		
	ElsIf TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then 
		
		NewElement = ReceiverStructure.Add(TypeOf(Item)); 
		FillPropertyValues(NewElement, Item, 
			"Use,Presentation,Application,ViewMode,GroupType");

		For Each FilterElement In Item.Items Do 
			AddSelectionToReportStructure(NewElement.Items, FilterElement); 
		EndDo; 
		
	EndIf; 
	
EndProcedure 

Procedure AddConditionalAppearanceToReportStructure(ReceiverStructure,Item) 
	
	NewElement = ReceiverStructure.Add(); 
	NewElement.Presentation = Item.Presentation; 
	NewElement.Use = Item.Use; 
	 
	For Each ElementSelection In Item.Filter.Items Do 
		AddSelectionToReportStructure(NewElement.Filter.Items,ElementSelection); 
	EndDo; 
	 
	For Each DesignElement In Item.Appearance.Items Do 
		AddOutputParametersToReportStructure(NewElement.Appearance.Items,DesignElement); 
	EndDo; 
	 
	For Each FieldElement In Item.Fields.Items Do 
		NewFieldElement = NewElement.Fields.Items.Add(); 
		NewFieldElement.Use 	= FieldElement.Use; 
		NewFieldElement.Field 			= FieldElement.Field; 
	EndDo; 
	
EndProcedure 

Procedure AddOrderToReportStructure(ReceiverStructure,Item) 
	
	If TypeOf(Item) = Type("DataCompositionOrderItem") Then 
		
		NewElement = ReceiverStructure.Add(TypeOf(Item)); 
		FillPropertyValues(NewElement, Item, "Use,Field,OrderType");
		 
	ElsIf TypeOf(Item) = Type("DataCompositionAutoOrderItem") Then 
		
		NewElement = ReceiverStructure.Add(TypeOf(Item)); 
		NewElement.Use = Item.Use; 
		
	EndIf; 
	
EndProcedure

// Is called from the standard report MFP.
//
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - 
// 	SettingsComposer - DataCompositionSettingsComposer - 
// 	ResultDocument - SpreadsheetDocument - 
// 	DetailsData - DataCompositionDetailsData - 
// 	StandardProcessing - Boolean - 
//
Procedure OnComposeResult(DataCompositionSchema, SettingsComposer, ResultDocument, DetailsData, StandardProcessing) Export
	
	StandardProcessing = False; 
	ResultDocument.Clear();
	MaxExtDimensionCount = FinancialAccountingServerCached.MaxExtDimensionCount();
	
	VariantKey = "";
	If SettingsComposer.UserSettings.AdditionalProperties.Property("VariantKey") Then
		VariantKey = SettingsComposer.UserSettings.AdditionalProperties.VariantKey;
	ElsIf SettingsComposer.FixedSettings.AdditionalProperties.Property("DescriptionOption") Then
		VariantKey = DataCompositionSchema.SettingVariants[SettingsComposer.FixedSettings.AdditionalProperties.DescriptionOption];
	EndIf;
	
	
	If GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		ChartOfAccountsParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ChartOfAccounts");
		If ChartOfAccountsParameter <> Undefined
			And ChartOfAccountsParameter.Use
			And Not ValueIsFilled(ChartOfAccountsParameter.Value) Then
			ChartOfAccountsParameter.Value = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
		EndIf;
	EndIf;
	
	ExtdimensionViewParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ExtDimensionType");
	If ExtdimensionViewParameter <> Undefined And  ExtdimensionViewParameter.Use Then
		
		If Not ValueIsFilled(ExtdimensionViewParameter.Value) Then
			ExtDimensionCount = 0
		ElsIf TypeOf(ExtdimensionViewParameter.Value) = Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes") Then
			ExtDimensionCount = 1;
		Else
			ExtDimensionCount = ExtdimensionViewParameter.Value.Count();
		EndIf;
		
		If ExtDimensionCount < MaxExtDimensionCount Then 
			ExtdimensionGrouping = Undefined;
			FindGroupingByField(SettingsComposer.Settings.Structure, "ExtDimension" + (ExtDimensionCount + 1), ExtdimensionGrouping); 
			
			If ExtdimensionGrouping <> Undefined Then
				ExtdimensionGrouping.Use = False;
				ID = SettingsComposer.UserSettings.GetIDByObject(ExtdimensionGrouping);
				CustomGrouping = SettingsComposer.UserSettings.GetObjectByID(ID);
				If CustomGrouping <> Undefined Then
					CustomGrouping.Use = False;
					SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
				EndIf;
				
				MainDataSet = DataCompositionSchema.DataSets.MainDataSet;
				If TypeOf(MainDataSet) = Type("DataCompositionSchemaDataSetUnion") Then
					QueryTextBalance = MainDataSet.Items.Find("Balances_International").Query;
					QueryTextTurnovers = MainDataSet.Items.Find("Revolutions_International").Query;
					For ExtDimensionNumber = ExtDimensionCount + 1 To FinancialAccountingServerCached.MaxExtDimensionCount() Do
						ExtdimensionText 		= ".ExtDimension" + ExtDimensionNumber + " AS ExtDimension" + ExtDimensionNumber + "," + Chars.LF;
						QueryTextBalance = StrReplace(QueryTextBalance, "BalanceAndTurnovers" + ExtdimensionText, "");
						QueryTextTurnovers = StrReplace(QueryTextTurnovers, "InternationalTurnover" + ExtdimensionText, "");
					EndDo;
					MainDataSet.Items.Find("Balances_International").Query = QueryTextBalance;
					MainDataSet.Items.Find("Revolutions_International").Query = QueryTextTurnovers;
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
	SetGeneralParametersForStandardReports(SettingsComposer);
	
	DataCompositionSettings = SettingsComposer.GetSettings();

	ReportIndicators = New Structure;
	ReportIndicators.Insert("CurrencyAmount", 			DataCompositionClientServer.GetParameter(SettingsComposer, "IndicatorCurrencyAmount"));
	ReportIndicators.Insert("PresentationAmount", 	DataCompositionClientServer.GetParameter(SettingsComposer, "IndicatorSumOfPresentation"));
	ReportIndicators.Insert("Sum", 					DataCompositionClientServer.GetParameter(SettingsComposer, "IndicatorAmount"));
	ReportIndicators.Insert("Count", 			DataCompositionClientServer.GetParameter(SettingsComposer, "IndicatorQuantity"));

	SetCurrencyGrouping(SettingsComposer, ReportIndicators.CurrencyAmount.Value);
	DataCompositionSettings = SettingsComposer.GetSettings();
		
	If SettingsComposer.FixedSettings.AdditionalProperties.Property("TotalType") Then
		
		TotalType = SettingsComposer.FixedSettings.AdditionalProperties.TotalType;
		OpeningBalance = SettingsComposer.FixedSettings.AdditionalProperties.OpeningBalance;
		ReportMetricsBasedOnTotalType(TotalType, OpeningBalance, ReportIndicators);
		
	EndIf;
	
	ConfigureSelectionFields(ReportIndicators, DataCompositionSettings);
	If DataCompositionSettings.Structure.Count() And TypeOf(DataCompositionSettings.Structure[0]) = Type("DataCompositionTable") Then
		ConfigureSelectionFields(ReportIndicators, DataCompositionSettings.Structure[0]);
	EndIf;
		
	FilterGroup = SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	FilterGroup.Presentation = NStr("vi = 'Lọc theo các lĩnh vực được chọn';
									|ru = 'Отбор по выбранным полям';
									|en = 'Filter upon selected fields'; fa = 'Filter upon selected fields';
									|it = 'Selezione per campi evidenziati';
									|pl = 'Filtr według wybranych pól';
									|tr = 'Seçili alanlara göre filtre'");
	FilterGroup.Use = True;
	FilterGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;	
	SetUpSelectionByAmount(DataCompositionSettings.Selection.Items, FilterGroup);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, , DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(DataCompositionProcessor, True);
	
	DeleteFieldHeaders(ResultDocument);

	GenerateFieldHeaders(VariantKey, SettingsComposer, DataCompositionSchema, "");
	
	AfterCompositingResult(DataCompositionSettings, ResultDocument, ReportIndicators, VariantKey);
	
EndProcedure

Procedure GenerateFieldHeaders(VariantKey, SettingsComposer, DataCompositionSchema, Title)
	
	DataSet = DataCompositionSchema.DataSets.Find("MainDataSet");
	If DataSet = Undefined Then
		Return;
	EndIf;
	
	For Each DataSetField In DataSet.Fields Do
		If TypeOf(DataSetField) = Type("DataCompositionSchemaDataSetField") Then		
			If StrFind(DataSetField.Field,"ReportIndicators") = 0 
				And (StrFind(DataSetField.Field,"CurrencyAmount") > 0 
				Or StrFind(DataSetField.Field,"PresentationAmount") > 0 
				Or StrFind(DataSetField.Field,".Sum") > 0
				Or StrFind(DataSetField.Field,"Count") > 0) Then 
				
				DataSetField.Title = Title;
				
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure DeleteFieldHeaders(Document)
		
	Area = Document.FindText("Function_.");
	If Area <> Undefined Then
		Area.Text = "";
	EndIf;
	
	MergeFieldHeaders(Document, NStr("vi = 'Chỉ tiêu';
									|ru = 'Показатели';
									|en = 'Indicators'; fa = 'شاخص‌ها';
									|it = 'Indici';
									|pl = 'Indicators';
									|tr = 'Göstergeler'"));
		
EndProcedure

Procedure MergeFieldHeaders(Document, AreaText) Export
	
	Area = Document.Area("R1C1");
	
	While Area <> Undefined Do
		Area = Document.FindText(AreaText,Area,,,True);
		If Area <> Undefined And Document.FixedTop <> 0 Then
			Column = "C"+String(Area.Left);
			AreaName = "R"+String(Area.Top)+Column+":R"+String(Document.FixedTop)+Column;
			CurrencyHeader = Document.Area(AreaName);
			CurrencyHeader.Merge();
		EndIf;
	EndDo;
	
EndProcedure

Procedure ConfigureSelectionFields(ReportIndicators, ReportItem)
	
	If TypeOf(ReportItem) = Type("DataCompositionTable") Then
		
		For Each ColumnOfDimensionTable In ReportItem.Columns Do
			ConfigureSelectionFields(ReportIndicators, ColumnOfDimensionTable);
		EndDo;
		Return;
		
	ElsIf TypeOf(ReportItem) = Type("DataCompositionTableGroup") Then
		
		For Each SubordinateGrouping In ReportItem.Structure Do
			ConfigureSelectionFields(ReportIndicators, SubordinateGrouping);
		EndDo;
		ConfigureSelectionFields(ReportIndicators,ReportItem.Selection.Items);
		
	ElsIf TypeOf(ReportItem) = Type("DataCompositionSettings") Then
		
		ConfigureSelectionFields(ReportIndicators,ReportItem.Selection.Items);
		
	Else
		
		For Each ComboBox In ReportItem Do	
			
			If TypeOf(ComboBox) = Type("DataCompositionAutoSelectedField") Then
				Continue;
			EndIf;
			
			FieldName = String(ComboBox.Field);
			If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
				ConfigureSelectionFields(ReportIndicators, ComboBox.Items);
			Else
				For Each Factor In ReportIndicators Do
					If StrFind(FieldName, Factor.Key) > 0 Then
						ComboBox.Use = Factor.Value.Value;
						Break;
					EndIf;
				EndDo;
			EndIf; 
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SetUpSelectionByAmount(ReportItems, FilterGroup)
	
	For Each ReportItem In ReportItems Do
		
		FieldName = String(ReportItem.Field);
		If TypeOf(ReportItem) = Type("DataCompositionSelectedFieldGroup") Then
			SetUpSelectionByAmount(ReportItem.Items, FilterGroup);
		Else
			If (StrFind(FieldName, "Turnover") > 0 Or StrFind(FieldName, "Balance_") > 0) And ReportItem.Use Then
				NewFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				NewFilter.LeftValue = ReportItem.Field;
				NewFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				NewFilter.RightValue = 0;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetGeneralParametersForStandardReports(SettingsComposer)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineGrandTotals", NStr("vi = 'Tổng kết chung';
																						|ru = 'Общие итоги';
																						|en = 'Grand totals'; fa = 'Grand totals';
																						|it = 'Totali comuni';
																						|pl = 'Łączne wyniki';
																						|tr = 'Toplam sonuçlar'"));
	
	ParameterEndOfPeriodBorder = DataCompositionClientServer.GetParameter(SettingsComposer, "PeriodEndBoundary");
	If ParameterEndOfPeriodBorder <> Undefined Then
		ParameterEndOfPeriodBorder.Use = True;
		PeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriod");
		If PeriodParameter <> Undefined Then
			PeriodValue_ = PeriodParameter.Value;// StandardPeriod - 
			If PeriodParameter.Use And ValueIsFilled(PeriodValue_.EndDate) Then  
				ParameterEndOfPeriodBorder.Value = New Boundary(EndOfDay(PeriodValue_.EndDate), BoundaryType.Including); 
			Else
				ParameterEndOfPeriodBorder.Value = Date(1,1,1)
			EndIf;	
		EndIf;
	EndIf;	
	
	ArrayOfExtdimensionSpecies = New Array;
	OtherExtdimensionTypes = DataCompositionClientServer.GetParameter(SettingsComposer, "ListOfExtdimensionSpecies");
	If OtherExtdimensionTypes <> Undefined And ValueIsFilled(OtherExtdimensionTypes.Value) Then
		If TypeOf(OtherExtdimensionTypes.Value) = Type("ValueList") Then
			ListOfExtdimensionSpecies = OtherExtdimensionTypes.Value;
			For Each ListItem In ListOfExtdimensionSpecies Do
				If ValueIsFilled(ListItem.Value) Then 
					ArrayOfExtdimensionSpecies.Add(ListItem.Value);
				EndIf;
			EndDo;
		Else
			ArrayOfExtdimensionSpecies.Add(OtherExtdimensionTypes.Value);
		EndIf;
		DataCompositionClientServer.SetParameter(SettingsComposer,"ListOfExtdimensionSpecies", ArrayOfExtdimensionSpecies);
	EndIf;
	
EndProcedure

Procedure ReportMetricsBasedOnTotalType(TotalType, OpeningBalance, ReportIndicators)
	
	FieldsNames = New Array;
	
	If TotalType = Enums.TypesOfTotals.Balance_Dr 
			Or TotalType = Enums.TypesOfTotals.Balance_Cr 
			Or TotalType = Enums.TypesOfTotals.Balance_ Then
		If OpeningBalance Then
			FieldsNames.Add("Turnover");
			FieldsNames.Add("ClosingBalance");
		Else
			FieldsNames.Add("OpeningBalance");
			FieldsNames.Add("Turnover");
		EndIf;
	EndIf;
	
	If TotalType = Enums.TypesOfTotals.TurnoverDr Then
		FieldsNames.Add("OpeningBalance");
		FieldsNames.Add("TurnoverCr");
		FieldsNames.Add("ClosingBalance");
	EndIf;	
	If TotalType = Enums.TypesOfTotals.TurnoverCr Then
		FieldsNames.Add("OpeningBalance");
		FieldsNames.Add("TurnoverDr");
		FieldsNames.Add("ClosingBalance");
	EndIf;
	If TotalType = Enums.TypesOfTotals.Turnover Then
		FieldsNames.Add("OpeningBalance");
		FieldsNames.Add("ClosingBalance");
	EndIf;
	
	NewReportMetrics = New Structure;
	
	For Each ReportIndicator In ReportIndicators Do
		If ReportIndicator.Value.Value Then
			For Each FieldName In FieldsNames Do
				NewReportMetrics.Insert(ReportIndicator.Key + FieldName, New Structure("Value", False));
			EndDo;
		EndIf; 
		NewReportMetrics.Insert(ReportIndicator.Key, ReportIndicator.Value);
	EndDo;
	
	ReportIndicators = NewReportMetrics;
		
EndProcedure

Procedure AfterCompositingResult(DataCompositionSettings, ResultDocument, ReportIndicators, VariantKey)
	
	If ReportIndicators.CurrencyAmount.Value And VariantKey = "AccountAnalysisInternational" Then
		Area = ResultDocument.FindText("Balanced. account");
		If Area <> Undefined Then
			Area.Text = Area.Text + "," + Chars.LF + "Currency";
		EndIf;
	EndIf;
	
	CompaniesList = FinancialReportingServer.FindSelectionElement(DataCompositionSettings.Filter, "Organization",, DataCompositionComparisonType.InList);
	If TypeOf(CompaniesList) = Type("DataCompositionFilterItem") And CompaniesList.Use Then
		CompaniesList = CompaniesList.RightValue;
	EndIf;
	
	CompanyArray = Undefined;
	If TypeOf(CompaniesList) = Type("ValueList") Then
		CompanyArray = CompaniesList.UnloadValues();
	EndIf;
	
	ReportPeriod = DataCompositionClientServer.GetParameter(DataCompositionSettings, "ReportPeriod").Value; // StandardPeriod - 

	TasksNotCompleted = FinancialAccountingOfMonthEndClosing.OutstandingDeferredTasks(
		Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting, ReportPeriod.EndDate, CompanyArray, Undefined);
	
	If TasksNotCompleted.Count() > 0 Then
		WarningText = NStr("vi = 'Dữ liệu báo cáo có thể chưa được cập nhật, bởi vì chưa thực hiện tất cả giai đoạn đóng tháng, bút toán chứng từ có thể thay đổi.';
							|ru = 'Данные отчета могут быть не актуальны, т.к. выполнены не все этапы закрытия месяца, проводки документов могут измениться.';
							|en = 'The report data might be outdated as some month-end closing stages were not performed. Document entries might change.'; fa = 'The report data might be outdated as some month-end closing stages were not performed. Document entries might change.';
							|it = 'Данные отчета могут быть не актуальны, т.к. выполнены не все этапы закрытия месяца, проводки документов могут измениться.';
							|pl = 'The report data might be outdated as some month-end closing stages were not performed. Document entries might change.';
							|tr = 'Rapor verileri güncel olmayabilir, çünkü ay sonu kapanışı tüm aşamaları tamamlanmadığı için belge girişleri değişebilir.'");
		ResultDocument.Area("R1C1").Text = WarningText;
		ResultDocument.Area("R1C1").TextColor = StyleColors.TextColorIssue;
		ResultDocument.Area(1,, 1,).RowHeight = 0;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region ProceduresAndFunctionsForFormingElementTrees

// The procedure fills in the palette of new elements that are available
// for selection in the report view instance in the formula constructor form.
//
// Parameters:
//  Form  - ClientApplicationForm - form for which elements are filled in
//  Parameters  - Structure - additional parameters of the tree.
//
Procedure UpdateTreeOfNewElements(Form, Parameters) Export
	
	QuickSearch = Undefined;
	NameOfTreeElement = Parameters.NameOfTreeElement;
	QuickSearch = Parameters.QuickSearch;
	WorkMode = Parameters.WorkMode;

	ItemsTree = NewItemTree(Form, NameOfTreeElement);
	ItemsTree.Rows.Clear();
	
	QuickSearchForQuery = "";
	If ValueIsFilled(QuickSearch) Then
		QuickSearchForQuery = "%" + QuickSearch + "%";
	EndIf;
	
	PicturesIndexes = FinancialReportingServer.ImageIndexTable();
	
	Query = New Query;
	Query.TempTablesManager = FinancialReportingServer.TemporaryTableOfImageIndexes();

#Region BasicReportElements
	Query.Text = 
	"SELECT
	|	ReportItemKinds.Ref AS ItemKind,
	|	ImageIndexTable.PictureIndex AS CustomPicture,
	|	PRESENTATION(ReportItemKinds.Ref) AS Description,
	|	PRESENTATION(ReportItemKinds.Ref) AS NameForPrinting
	|
	|FROM
	|	Enum.FinancialReportItemKinds AS ReportItemKinds
	|		LEFT JOIN ImageIndexTable
	|		ON ReportItemKinds.Ref = ImageIndexTable.ItemKind
	|		AND ImageIndexTable.NameOfAuxiliaryElement = """"
	|
	|WHERE
	|	ReportItemKinds.Ref IN (&AvailableItemKinds)
	|
	|ORDER BY
	|	ReportItemKinds.Order
	|";
	AvailableItemKinds = AvailableBasicReportElements(WorkMode);
	Query.SetParameter("AvailableItemKinds", AvailableItemKinds);
	FinancialReportingServer.QueryResultInTree(Query.Execute(), ItemsTree);
	
#EndRegion
	
#Region MonetaryIndicators
	IndexOf = 0;
	ArrayOfRequestTexts = New Array;
	NodesArray = New Array;
	For Each ChartOfAccounts In Parameters.ChartsOfAccounts Do
		
		NameOfChartOfAccountsParameter = "ChartOfAccounts" + IndexOf;
		PresentationOfChartOfAccounts = "";
		FilterChartOfAccounts = "TRUE";
		If TypeOf(ChartOfAccounts) = Type("CatalogRef.FinancialAccountingChartsOfAccounts") Then
			MetadataObjectChartOfAccounts = Metadata.ChartsOfAccounts.International;
			FilterChartOfAccounts = StrTemplate("FinReportElements.ChartOfAccounts = &%1", NameOfChartOfAccountsParameter);
			PresentationOfChartOfAccounts = String(ChartOfAccounts);
		Else
			MetadataObjectChartOfAccounts = Common.MetadataObjectByID(ChartOfAccounts);
			ChartOfAccountsManager = Common.ObjectManagerByFullName(MetadataObjectChartOfAccounts.FullName());
			PresentationOfChartOfAccounts = ChartOfAccountsManager.PresentationInFinancialStatements();
		EndIf;
		Query.SetParameter(NameOfChartOfAccountsParameter, ChartOfAccounts);
		
		Filter = New Structure();
		Filter.Insert(PicturesIndexes.Columns.ItemKind.Name,  Enums.FinancialReportItemKinds.MonetaryIndicator);
		Filter.Insert(PicturesIndexes.Columns.NameOfAuxiliaryElement.Name,  ChartOfAccounts);
		RowsIndexesOfImages = PicturesIndexes.FindRows(Filter);
		If RowsIndexesOfImages.Count() = 0 Then
			Filter = New Structure();
			Filter.Insert(PicturesIndexes.Columns.ItemKind.Name,  Enums.FinancialReportItemKinds.MonetaryIndicator);
			Filter.Insert(PicturesIndexes.Columns.NameOfAuxiliaryElement.Name, "");
			RowsIndexesOfImages = PicturesIndexes.FindRows(Filter);
		EndIf;
		PictureIndex = RowsIndexesOfImages[0].PictureIndex;
		
		NameOfImageIndexParameter = "PictureIndex" + IndexOf;
		Query.SetParameter(NameOfImageIndexParameter, PictureIndex);
		
		Particle = 
		"SELECT
		|	VALUE(Enum.FinancialReportItemKinds.MonetaryIndicator) AS ItemKind,
		|	&PictureIndex AS CustomPicture,
		|	FinReportElements.Ref AS ReportingKindItem,
		|	FinReportElements.Code AS AccountCode,
		|	FinReportElements.Order AS Code,
		|	FinReportElements.Description AS Description,
		|	FinReportElements.Description AS NameForPrinting
		|FROM
		|	&FullMetadataObjectName AS FinReportElements
		|	
		|WHERE
		|	NOT FinReportElements.DeletionMark
		|	AND &FilterChartOfAccounts
		|	AND &FilterByLine
		|
		|ORDER BY 
		|	Code HIERARCHY
		|";
		
		Particle = StrReplace(Particle, "&PictureIndex", "&" + NameOfImageIndexParameter);
		Particle = StrReplace(Particle, "&FullMetadataObjectName", MetadataObjectChartOfAccounts.FullName());
		Particle = StrReplace(Particle, "&FilterChartOfAccounts", FilterChartOfAccounts);
		
		FilterText1 = 
		?(ValueIsFilled(QuickSearchForQuery), 
			StrTemplate("(FinReportElements.Description LIKE ""%1"" OR FinReportElements.Code LIKE ""%1"")", QuickSearchForQuery),
			"TRUE");
		Particle = StrReplace(Particle, "&FilterByLine", FilterText1);
		ArrayOfRequestTexts.Add(Particle);
		
		MonetaryIndicatorLine = ItemsTree.Rows.Insert(3);
		MonetaryIndicatorLine.ItemKind = Enums.FinancialReportItemKinds.MonetaryIndicator;
		MonetaryIndicatorLine.Description = StrTemplate(NStr("vi = 'Hệ thống tài khoản ""%1""';
															|ru = 'План счетов ""%1""';
															|en = 'Chart of accounts ""%1""'; fa = 'Chart of accounts ""%1""';
															|it = 'Piano dei conti ""%1""';
															|pl = 'Plan rachunków ""%1""';
															|tr = 'Hesap planı %1'"), PresentationOfChartOfAccounts);
		MonetaryIndicatorLine.NameForPrinting = StrTemplate(NStr("vi = 'Hệ thống tài khoản ""%1""';
																|ru = 'План счетов ""%1""';
																|en = 'Chart of accounts ""%1""'; fa = 'Chart of accounts ""%1""';
																|it = 'Piano dei conti ""%1""';
																|pl = 'Plan rachunków ""%1""';
																|tr = 'Hesap planı %1'"),  PresentationOfChartOfAccounts);
		MonetaryIndicatorLine.CustomPicture = PictureIndex;
		MonetaryIndicatorLine.IsFolder = True;
		
		NodesArray.Add(MonetaryIndicatorLine);
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	RequestTextForMonetaryIndicators = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	If RequestTextForMonetaryIndicators <> "" Then
		Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
		QueryResults = Query.ExecuteBatch();
		For IndexOf = 0 To QueryResults.Count() - 1 Do
			FinancialReportingServer.QueryResultInTree(QueryResults[IndexOf], NodesArray[IndexOf]);
		EndDo;
	EndIf;
#EndRegion
	
#Region NonMonetaryItems
	Filter = New Structure();
	Filter.Insert(PicturesIndexes.Columns.ItemKind.Name,  Enums.FinancialReportItemKinds.NonMonetaryItem);
	Filter.Insert(PicturesIndexes.Columns.NameOfAuxiliaryElement.Name,  "");
	PictureIndex = PicturesIndexes.FindRows(Filter)[0].PictureIndex;
	
	NonMonetaryIndicatorLine = ItemsTree.Rows.Add();
	NonMonetaryIndicatorLine.ItemKind = Enums.FinancialReportItemKinds.NonMonetaryItem;
	NonMonetaryIndicatorLine.Description = NStr("vi = 'Các chỉ tiêu phi tiền tệ';
												|ru = 'Немонетарные показатели';
												|en = 'Non-monetary items'; fa = 'اقلام غیرپولی';
												|it = 'Indicatori non monetari';
												|pl = 'Wskaźniki niepieniężne';
												|tr = 'Gayrinakdi göstergeler'");
	NonMonetaryIndicatorLine.NameForPrinting = NStr("vi = 'Các chỉ tiêu phi tiền tệ';
													|ru = 'Немонетарные показатели';
													|en = 'Non-monetary items'; fa = 'اقلام غیرپولی';
													|it = 'Indicatori non monetari';
													|pl = 'Wskaźniki niepieniężne';
													|tr = 'Gayrinakdi göstergeler'");
	NonMonetaryIndicatorLine.CustomPicture = PictureIndex;
	NonMonetaryIndicatorLine.IsFolder = True;
	
	QueryText =
	"SELECT
	|	VALUE(Enum.FinancialReportItemKinds.NonMonetaryItem) AS ItemKind,
	|	ImageIndexTable.PictureIndex AS CustomPicture,
	|	NonMonetaryItems.Ref AS ReportingKindItem,
	|	NonMonetaryItems.Code AS Code,
	|	NonMonetaryItems.Description AS Description,
	|	NonMonetaryItems.NameForPrinting AS NameForPrinting,
	|	NonMonetaryItems.IsFolder AS IsFolder
	|
	|FROM
	|	Catalog.NonMonetaryItems AS NonMonetaryItems
	|		LEFT JOIN ImageIndexTable AS ImageIndexTable
	|		ON (CASE
	|				WHEN NonMonetaryItems.IsFolder
	|					THEN ImageIndexTable.NameOfAuxiliaryElement = ""Group""
	|				ELSE ImageIndexTable.ItemKind = VALUE(Enum.FinancialReportItemKinds.NonMonetaryItem)
	|						AND ImageIndexTable.NameOfAuxiliaryElement = """"
	|			END)
	|WHERE
	|	NonMonetaryItems.DeletionMark = FALSE
	|	AND NonMonetaryItems.Predefined = FALSE
	|	AND &FilterByLine
	|ORDER BY
	|	IsFolder HIERARCHY,
	|	Description
	|";
	
	FilterText1 = 
		?(ValueIsFilled(QuickSearchForQuery), 
			StrTemplate("NonMonetaryItems.NameForPrinting LIKE ""%1""", QuickSearchForQuery), 
			"TRUE");
	QueryText = StrReplace(QueryText, "&FilterByLine", FilterText1);
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	FinancialReportingServer.QueryResultInTree(QueryResult, NonMonetaryIndicatorLine);
#EndRegion
	
	If WorkMode = Enums.ModesOfNewItemTreeDisplay.ConfigureReportKind Then
	
		// Adding table elements
		TableRow = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.ComplexTable); 
		StringElement = TableRow.Rows.Add(); 
		RowColumn = Enums.FinancialReportItemKinds.RowColumn;
		StringElement.CustomPicture = FinancialReportingCached.CustomPicture(RowColumn);
		StringElement.Description = String(RowColumn);
		StringElement.NameForPrinting = String(RowColumn);
		StringElement.ItemKind = RowColumn;
		
		// Adding dimensions
		AddDimensionsToTreeOfNewItems(ItemsTree, Parameters.ChartsOfAccounts, QuickSearch);
		
	EndIf;// Work mode = Report View Setups
	
	Form.ValueToFormAttribute(ItemsTree, NameOfTreeElement);
	
EndProcedure

// The function returns a tree of report view elements
// 
// Parameters:
// 	ReportKind - CatalogRef.FinancialReportTypes - type of report for which you want to build a tree
// 	ItemsParent - Undefined - LongDesc
// 	AttributeCache - Undefined - LongDesc
// 	DisplayComplexTableItems - Boolean - indicates that you want to display elements that are subordinate to the "cell settings" element.
// 	
// Returns:
// 	ValueTree - the tree of elements of the financial report:
// 	* Parent - CatalogRef.FinancialReportItems - 
// 	* ItemKind - EnumRef.FinancialReportItemKinds - 
// 	* ReportItem - CatalogRef.FinancialReportItems - 
// 	* ReportItemIsAnAssociatedItem - CatalogRef.FinancialReportItems -
// 	* NameForPrinting - String - 
// 	* ReverseSign - Boolean -
// 	* HasSettings - Boolean - 
// 	* LinkedItem1 - CatalogRef.FinancialReportItems -
// 	* Comment - String - 
// 	* AdditionalSelection - ValueStorage - 
// 	* ThisIsReference - Boolean - 
// 	* Code - String - 
// 	* AddressOfItemStructure - String - 
// 	* AccountIndicatorDimension - ChartOfAccountsRef, CatalogRef.FinancialReportItems - 
// 	* ReportKind - CatalogRef.FinancialReportTypes -
// 	* Note - CatalogRef.FinancialReportTypes -
// 	* Accuracy - Number - 
// 	
Function UpdateTheReportTree(ReportKind, Val ItemsParent = Undefined, AttributeCache = Undefined, DisplayComplexTableItems = False) Export
	
	FinReports = FinancialReportingServer;
	TreeDiagram = Catalogs.FinancialReportTypes.GetTemplate("ReportItemTree");
	If ValueIsFilled(ItemsParent) Then
		Attributes = Common.ObjectAttributesValues(ItemsParent,"ItemKind,Parent");
		If Attributes.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup Then
			ItemsParent = Attributes.Parent;
			TreeDiagram.DataSetLinks.Delete(TreeDiagram.DataSetLinks[0]);
			QueryText = TreeDiagram.DataSets.ReportItems.Query;
			TreeDiagram.DataSets.ReportItems.Query = StrReplace(QueryText, "AND FinReportElements.Parent IN(&Parents)", "");
		EndIf;
	EndIf;
	TreeComposer = FinReports.SchemaComposer(TreeDiagram);
	FinReports.SetLayoutParameter(TreeComposer, "DisplayComplexTableItems", DisplayComplexTableItems);
	FinReports.SetLayoutParameter(TreeComposer, "ReportKind", ReportKind);
	AttributeCache = FinReports.CacheAdditionalDetails(ReportKind);
	FinReports.SetLayoutParameter(TreeComposer, "AttributeCache", AttributeCache);
	CacheAccountPlansForReportElements = FinReports.CacheAccountPlansForReportElements(ReportKind);
	FinReports.SetLayoutParameter(TreeComposer, "CacheAccountPlansForReportElements", CacheAccountPlansForReportElements);
	
	If ItemsParent <> Undefined Then
		FinReports.SetFilter(TreeComposer.Settings.Filter,"ReportItem",ItemsParent,DataCompositionComparisonType.InHierarchy);
	EndIf;
	
	Result = FinReports.UploadDCSResults(TreeDiagram, TreeComposer,,True);
	
	Return Result;
	
EndFunction

Procedure UpdateTreeOfSavedItems(Form, Parameters) Export
	
	FinReports = FinancialReportingServer;
	NameOfTreeElement = FinReports.GetParameter(Parameters,"NameOfTreeElement");
	FilterByReportKind = FinReports.GetParameter(Parameters,"FilterByReportKind");
	CurReportView = FinReports.GetParameter(Parameters,"CurReportView");
	QuickSearch = FinReports.GetParameter(Parameters,"QuickSearch");
	DisplayComplexTableItems = FinReports.GetParameter(Parameters,"DisplayComplexTableItems", False);
	WorkMode = Parameters.WorkMode;
	ReportAccountPlans = Parameters.ChartsOfAccounts;
	AvailableItemKinds = AvailableSavedReportItems(WorkMode);
	
	FinReports = FinancialReportingServer;
	TreeDiagram = Catalogs.FinancialReportTypes.GetTemplate("SavedItemsTree");
	TreeComposer = FinReports.SchemaComposer(TreeDiagram);
	DCSettings = TreeComposer.Settings;
	
	FinReports.SetLayoutParameter(DCSettings, "AvailableItemKinds", AvailableItemKinds);
	FinReports.SetLayoutParameter(DCSettings, "DisplayComplexTableItems", DisplayComplexTableItems);
	FinReports.SetLayoutParameter(DCSettings, "ChartsOfAccounts", ReportAccountPlans);
	FinReports.SetLayoutParameter(DCSettings, "CurrentReport", CurReportView);
	FinReports.SetLayoutParameter(DCSettings, "CacheAccountPlansForReportElements", FinReports.CacheAccountPlansForReportElements(FilterByReportKind));
	
	FinReports.SetFilter(DCSettings.Filter, "NameForPrinting", QuickSearch,,ValueIsFilled(QuickSearch));
	FinReports.SetFilter(DCSettings.Filter, "ReportKind", FilterByReportKind,,ValueIsFilled(FilterByReportKind));
	
	ItemsTree = FinReports.UploadDCSResults(TreeDiagram, TreeComposer,,True);
	
	AddAttributes = New Structure("GLAccount_,TotalType,OpeningBalance,NonMonetaryItem,DisplayItemTitle");
	For Each Column In ItemsTree.Columns Do
		For Each Attribute In AddAttributes Do
			If StrFind(Column.Name, Attribute.Key) > 0 Then
				Column.Name = Attribute.Key;
			EndIf;
		EndDo;
	EndDo;
	
	ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.MonetaryIndicator");
	Filter = New Structure("ItemKind", ItemKind);
	MonetaryIndicators = ItemsTree.Rows.FindRows(Filter, True);
		
	GroupTreeByReportType(ItemsTree);
	
	Form.ValueToFormAttribute(ItemsTree, NameOfTreeElement);
	
EndProcedure

Procedure UpdateElementReferenceTree(Form, Parameters) Export
	
	NameOfTreeElement = FinancialReportingServer.GetParameter(Parameters,"NameOfTreeElement");
	ReportItem = FinancialReportingServer.GetParameter(Parameters,"ReportItem");
	GLAccount_ = FinancialReportingServer.GetParameter(Parameters,"GLAccount_");
	
	Query = New Query;
	TempTablesManager = FinancialReportingServer.TemporaryTableOfImageIndexes();
	Query.TempTablesManager = TempTablesManager;
	Query.Text = RequestTextForLinksToReportElement();
	ThisIsIntSAccount = True;
	If ValueIsFilled(GLAccount_) Then
		ThisIsIntSAccount = TypeOf(GLAccount_) = FinancialAccountingClientServer.TypeChartOfAccounts();
	EndIf;
	Query.SetParameter("ThisIsIntSAccount", ThisIsIntSAccount);
	Query.SetParameter("ReportItem", ReportItem);
	Query.SetParameter("Owner", ReportItem.Owner);
	QueryResult = Query.Execute();
	
	ItemsTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	Parameters.Insert("RefsCount", ItemsTree.Rows.Count());
	
	GroupTreeByReportType(ItemsTree);
	
	Form.ValueToFormAttribute(ItemsTree, NameOfTreeElement);
	
EndProcedure

#Region ServiceProceduresAndFunctionsForFormingElementTrees

Function RequestTextForLinksToReportElement() Export
	
	QueryText = 
	"SELECT
	|	FinReportElements.Owner AS ReportKind,
	|	FinReportElements.Ref AS ReportItem,
	|	FinReportElements.NameForPrinting AS NameForPrinting,
	|	ImageIndexTable.PictureIndex + 1 AS CustomPicture
	|FROM
	|	Catalog.FinancialReportItems AS FinReportElements
	|		LEFT JOIN ImageIndexTable
	|		ON FinReportElements.ItemKind = ImageIndexTable.ItemKind
	|		AND ImageIndexTable.NameOfAuxiliaryElement = """"
	|WHERE
	|	FinReportElements.DeletionMark = FALSE
	|	AND (FinReportElements.LinkedItem1 = &ReportItem
	|				AND (FinReportElements.Owner <> &Owner OR &Owner = UNDEFINED)
	|	)
	|
	|ORDER BY
	|	NameForPrinting";
	
	Return QueryText;
	
EndFunction

Procedure GroupTreeByReportType(Tree)
	
	TreeByReportType = Tree.Copy();
	TreeByReportType.Rows.Clear();
	
	TreeRows = Tree.Rows;
	TreeRows.Sort("ReportKind");
	TreeRowsByReportType = TreeByReportType.Rows;
	GroupingString_ = Undefined;
	For Each TreeRow In TreeRows Do 
		
		If GroupingString_ = Undefined Or GroupingString_.ReportKind <> TreeRow.ReportKind Then
			GroupingString_ = TreeRowsByReportType.Add();
			GroupingString_.NameForPrinting = TreeRow.ReportKind;
			GroupingString_.ReportKind = TreeRow.ReportKind;
			GroupingString_.CustomPicture = 43;
		EndIf;
		
		InstallationParameters = FinancialReportingServer.TemplateForNewParentInstallationOptions();
		InstallationParameters.TheseAreSavedOnes = True;
		FinancialReportingServer.SetNewParent(TreeRow, GroupingString_, InstallationParameters);
		
	EndDo;
	
	Tree = TreeByReportType;
	
EndProcedure

Function AvailableBasicReportElements(TreeMode = Undefined)
	
	TreeOperationModes = Enums.ModesOfNewItemTreeDisplay;
	List = New ValueList;
	
	If TreeMode = TreeOperationModes.SetUpReportKindIndicatorsOnly Then
		List.Add(Enums.FinancialReportItemKinds.DerivedItem);
	EndIf;
	
	If TreeMode = TreeOperationModes.ConfigureReportKind Then// Rest
		List.Add(Enums.FinancialReportItemKinds.ReportHeader);
		List.Add(Enums.FinancialReportItemKinds.UneditedText);
		List.Add(Enums.FinancialReportItemKinds.EditedText);
		List.Add(Enums.FinancialReportItemKinds.DerivedItem);
		List.Add(Enums.FinancialReportItemKinds.ComplexTable);
		List.Add(Enums.FinancialReportItemKinds.Dimension);
		List.Add(Enums.FinancialReportItemKinds.Group);
		List.Add(Enums.FinancialReportItemKinds.TotalByGroup);
	EndIf;
	
	Return List;
	
EndFunction

Function AvailableSavedReportItems(TreeMode)
	
	TreeOperationModes = Enums.ModesOfNewItemTreeDisplay;
	List = New ValueList;
	List.Add(Enums.FinancialReportItemKinds.MonetaryIndicator);
	List.Add(Enums.FinancialReportItemKinds.NonMonetaryItem);
	List.Add(Enums.FinancialReportItemKinds.DerivedItem);
	
	If TreeMode = TreeOperationModes.ConfigureReportKind Then// the rest except measurements
		List.Add(Enums.FinancialReportItemKinds.ReportHeader);
		List.Add(Enums.FinancialReportItemKinds.UneditedText);
		List.Add(Enums.FinancialReportItemKinds.EditedText);
		List.Add(Enums.FinancialReportItemKinds.DerivedItem);
		List.Add(Enums.FinancialReportItemKinds.TableIndicatorsInRows);
		List.Add(Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
		List.Add(Enums.FinancialReportItemKinds.ComplexTable);
		List.Add(Enums.FinancialReportItemKinds.Group);
		List.Add(Enums.FinancialReportItemKinds.TotalByGroup);
	EndIf;
	
	Return List;
	
EndFunction

// Returns:
// 	ValueTree - LongDesc:
// 	 *AccountCode - String - 
// 	 *Description - String - 
// 	 *NameForPrinting - String - 
// 
Function NewItemTree(Form, NameOfTreeElement)
	
	ItemsTree = Form.FormAttributeToValue(NameOfTreeElement);
	
	Return ItemsTree;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ItemsTree - ValueTree - LongDesc:
// 	 *AccountCode - String - 
// 	 *Description - String - 
// 	 *NameForPrinting - String - 
// 	Var_ChartsOfAccounts - Array of CatalogRef.FinancialAccountingChartsOfAccounts - 
// 	            - Array of CatalogRef.MetadataObjectIDs - 
// 	QuickSearch - String -
//
Procedure AddDimensionsToTreeOfNewItems(ItemsTree, Var_ChartsOfAccounts, QuickSearch)

	MeasurementString_ = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.Dimension); 
	MeasurementString_.ItemKind = Undefined; //dimension grouping record cannot be transferred to report elements
	
	// Adding a period
	StringPeriod = AddDimensionLine(MeasurementString_, NStr("vi = 'Kỳ';
															|ru = 'Период';
															|en = 'Period'; fa = 'دوره';
															|it = 'Periodo';
															|pl = 'Okres';
															|tr = 'Dönem'"));
	StringPeriod.ItemKind = Undefined; //grouping record of measurements
	StringPeriod.IsFolder = True;         //cannot be transferred to budget items
	StringPeriod.CustomPicture = FinancialReportingServerCall.CustomPicture(Undefined, "Group");
	
	AddDimensionLine(StringPeriod, NStr("vi = 'Năm';
										|ru = 'Год';
										|en = 'Year'; fa = 'سال';
										|it = 'Anno';
										|pl = 'Year';
										|tr = 'yıl'")      , PredefinedValue("Enum.Periodicity.Year"));
	AddDimensionLine(StringPeriod, NStr("vi = 'Nửa năm';
										|ru = 'Полугодие';
										|en = 'Half-year'; fa = 'نیم‌سال';
										|it = 'Semestre';
										|pl = 'Half-year';
										|tr = 'Yarıyıl'"), PredefinedValue("Enum.Periodicity.HalfYear"));
	AddDimensionLine(StringPeriod, NStr("vi = 'Quý';
										|ru = 'Квартал';
										|en = 'Quarter'; fa = 'فصل';
										|it = 'Trimestre';
										|pl = 'Kwartał';
										|tr = 'Çeyrek'")  , PredefinedValue("Enum.Periodicity.Quarter"));
	AddDimensionLine(StringPeriod, NStr("vi = 'Tháng';
										|ru = 'Месяц';
										|en = 'Month'; fa = 'ماه';
										|it = 'Mese';
										|pl = 'Miesiąc';
										|tr = 'Ay'")    , PredefinedValue("Enum.Periodicity.Month"));
	
	AccountPlansByType = TMCommonUse.DecomposeArrayOfReferencesByType(Var_ChartsOfAccounts);
	
	For Each KeyAndValue In AccountPlansByType Do
		If KeyAndValue.Key = Type("CatalogRef.FinancialAccountingChartsOfAccounts") Then
			MetadataObjectTypesOfExtdimension = Metadata.ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes;
			AddExtdimensionViews(MeasurementString_, QuickSearch, MetadataObjectTypesOfExtdimension);
		Else
			For Each IDOfMetadataObjects In KeyAndValue.Value Do 
				MetadataObjectChartOfAccounts = Common.MetadataObjectByID(IDOfMetadataObjects);
				MetadataObjectTypesOfExtdimension = MetadataObjectChartOfAccounts.ExtDimensionTypes;
				AddExtdimensionViews(MeasurementString_, QuickSearch, MetadataObjectTypesOfExtdimension);
			EndDo;
		EndIf;
	EndDo;
	
	// Adding an organization
	AddDimensionLine(MeasurementString_, NStr("vi = 'Doanh nghiệp';
												|ru = 'Организация';
												|en = 'Company'; fa = 'Company';
												|it = 'Azienda';
												|pl = 'Organizacja';
												|tr = 'İş yeri'"));
	
	// Adding a division
	AddDimensionLine(MeasurementString_, NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'"));
	
	// Adding a line of business
	If Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed() Then
		AddDimensionLine(MeasurementString_, NStr("vi = 'Lĩnh vực hoạt động';
													|ru = 'Направление деятельности';
													|en = 'Line of business'; fa = 'خط کسب‌وکار';
													|it = 'Settore di attività';
													|pl = 'Rodzaj działalności';
													|tr = 'İş kolu'"));
	EndIf;
	
EndProcedure

Procedure AddExtdimensionViews(MeasurementString_, QuickSearch, MetadataObjectTypesOfExtdimension)
	
	StringExtdimension = AddDimensionLine(MeasurementString_, MetadataObjectTypesOfExtdimension.ListPresentation);
	StringExtdimension.ItemKind = Undefined;	//dimension grouping record 
	StringExtdimension.IsFolder = True; 		//cannot be transferred to report elements
	StringExtdimension.CustomPicture = FinancialReportingServerCall.CustomPicture(Undefined, "Group");
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	ExtDimensionTypes.Ref,
	|	ExtDimensionTypes.Description AS Description
	|FROM
	|	&ExtDimensionTypes AS ExtDimensionTypes
	|WHERE
	|	NOT ExtDimensionTypes.DeletionMark
	|	AND &FilterByDescription
	|ORDER BY
	|	Description";
	
	QueryText = StrReplace(QueryText,"&ExtDimensionTypes", MetadataObjectTypesOfExtdimension.FullName());
	
	If ValueIsFilled(QuickSearch) Then
		FilterByDescription = "ExtDimensionTypes.Description LIKE ""%" +  TrimAll(QuickSearch) + "%""";
	Else
		FilterByDescription = "TRUE";
	EndIf;
	QueryText = StrReplace(QueryText,"&FilterByDescription", FilterByDescription);
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewLineOfExtdimension = AddDimensionLine(StringExtdimension, Selection.Description, Selection.Ref);
		NewLineOfExtdimension.ThisIsAnExtraDimension = True;
	EndDo;
	
EndProcedure

Function AddDimensionLine(WhereToAddLine, Description, ReportItem = Undefined,NameForPrinting = "")
	
	NewRow = WhereToAddLine.Rows.Add();
	Dimension = PredefinedValue("Enum.FinancialReportItemKinds.Dimension");
	NewRow.ItemKind = Dimension;
	NewRow.CustomPicture = FinancialReportingCached.CustomPicture(Dimension);
	NewRow.Description = Description;
	NewRow.NameForPrinting = Description;
	If Not IsBlankString(NameForPrinting) Then
		NewRow.NameForPrinting = NameForPrinting;
	EndIf;
	NewRow.ReportingKindItem = ?(ReportItem = Undefined, Description, ReportItem);
	
	Return NewRow;
	
EndFunction

Function ReportingSetOfReportType(ReportKind)
	
	Result = Catalogs.FinancialReportSets.EmptyRef();
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	FinancialReportSetsReportsKinds.Ref AS Ref,
	|	PRESENTATION(FinancialReportSetsReportsKinds.Ref) AS Presentation
	|FROM
	|	Catalog.FinancialReportSets.ReportsKinds AS FinancialReportSetsReportsKinds
	|WHERE
	|	FinancialReportSetsReportsKinds.FinancialReportType = &FinancialReportType
	|
	|ORDER BY
	|	Ref";
	
	Query.SetParameter("FinancialReportType", ReportKind);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Presentation;
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the selection contains the passed values of the invoice, the subconto type, and the subconto value.
// The result is true if all non-empty values are contained in the selection. 
// If the value is empty, its presence in the selection is not checked and it does not affect the function result.
// For example: if an invoice and a subconto type are passed, the result is true if the selection contains both the invoice 
//           and the selection has fields with the type contained in the subconto type.
//           If only the score is passed, the result will be true if it is contained in the selection.
//
// Parameters:
// 	SelectionRepository - ValueStorage - 
// 	Account - ChartOfAccountsRef - 
// 	ExtDimensionType- ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes -
// 	ExtraDimensionValue - CatalogRef - 
// 	ExcludeInvoice - Boolean - LongDesc
// 
// Returns:
// 	Boolean - LongDesc
//
Function SelectionStoreContainsValues(SelectionRepository, Account, ExtDimensionType, ExtraDimensionValue, ExcludeInvoice = False) Export
	
	If SelectionRepository = Undefined Then
		Return False;
	EndIf;
	
	THEREISAccount = ValueIsFilled(Account) And Not ExcludeInvoice;
	ThereIsView  = ValueIsFilled(ExtDimensionType);
	ThereIs = ValueIsFilled(ExtraDimensionValue);
	If Not THEREISAccount And Not ThereIsView And Not ThereIs Then
		Return False;
	EndIf;
	
	Filter_Settings = SelectionRepository.Get();
	If Filter_Settings = Undefined Then
		Return False;
	EndIf;
	
	OKAccount = THEREISAccount And FilterContainsValue(Filter_Settings.Filter, Account);
	ViewOK  = ThereIsView And FilterContainsType(Filter_Settings.Filter, ExtDimensionType);
	Icon = ThereIs And FilterContainsValue(Filter_Settings.Filter, ExtraDimensionValue);
	
	Return Not THEREISAccount And (ViewOK And (Not ThereIs Or Icon) 
							Or Not ThereIsView And Icon)
			Or OKAccount And (ViewOK And (Not ThereIs Or Icon) 
							Or Not ThereIsView And (Not ThereIs Or Icon));
	
EndFunction

Function FilterContainsValue(FilterDQ, Value)
	
	Result = False;
	For Each FilterElement In FilterDQ.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			Result = FilterContainsValue(FilterElement, Value);
			If Result Then
				Break;
			EndIf;
			
		ElsIf TypeOf(FilterElement.RightValue) = Type("ValueList") Then
			ListItem = FilterElement.RightValue.FindByValue(Value);
			If ListItem <> Undefined Then
				Result = True;
				Break;
			EndIf;
			
		ElsIf FilterElement.RightValue = Value And FilterElement.RightValue <> Undefined Then
			Result = True;
			Break;
			
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// The selection contains a type.
// 
// Parameters:
//  FilterDQ - DataCompositionFilterItemGroup - CD selection
//  ExtDimensionType - ValueTableRow - Extra dimension type
// 
// Returns:
//  Boolean - The Selection Contains The Type
Function FilterContainsType(FilterDQ, ExtDimensionType)
	
	If Not ValueIsFilled(ExtDimensionType) Then
		Return False;
	EndIf;
	
	Result = False;
	For Each FilterElement In FilterDQ.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			Result = FilterContainsType(FilterElement, ExtDimensionType);
			If Result Then
				Break;
			EndIf;
			
		ElsIf FilterElement.RightValue = Undefined Then
			// Skip a move
		ElsIf TypeOf(FilterElement.RightValue) = Type("ValueList") Then
			For Each Item In FilterElement.RightValue Do
				If ExtDimensionType.ValueType.ContainsType(TypeOf(Item.Value)) Then
					Result = True;
					Break;
				EndIf;
			EndDo;
			
		ElsIf ExtDimensionType.ValueType.ContainsType(TypeOf(FilterElement.RightValue)) Then
			Result = True;
			Break;
		EndIf;
		
	EndDo;
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Other

Procedure FillInListOfReportResources(ResourceElement, ResourceCurrencies, Var_ChartsOfAccounts) Export
	
	ChoiceList = ResourceElement.ChoiceList;
	ChoiceList.Clear();
	
	ResourceCurrencyChange = New Structure();
	
	If Var_ChartsOfAccounts.Count() = 0 Then
		Return;
	EndIf;
	
	LocalAccountingSettings = LocalAccntingServer.AccountingSettings();
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	UsedInternational = False;
	RegulatedIsUsed = False;
	
	FunctionalCurrencyIsAvailable = False;
	
	PresentationCurrency = Undefined;
	PresentationCurrencyAvailable = False;
		
	AccountPlansByType = TMCommonUse.DecomposeArrayOfReferencesByType(Var_ChartsOfAccounts);
	If AccountPlansByType[Type("CatalogRef.FinancialAccountingChartsOfAccounts")] <> Undefined Then
		UsedInternational = True;
		
		FunctionalCurrencyIsAvailable = True;
		PresentationCurrencyAvailable = True;
		
		CurrencyValues = Common.ObjectsAttributesValues(
			AccountPlansByType[Type("CatalogRef.FinancialAccountingChartsOfAccounts")], "PresentationCurrency");
		
		For Each KeyAndValues In CurrencyValues Do
			If PresentationCurrency = Undefined Then
				PresentationCurrency = KeyAndValues.Value["PresentationCurrency"];
			EndIf;
			If KeyAndValues.Value["PresentationCurrency"] <> PresentationCurrency Then
				PresentationCurrencyAvailable = False;
			EndIf;
		EndDo;
	
	EndIf;
	
	If Not PresentationCurrencyAvailable Then
		PresentationCurrency = Undefined;
	EndIf;
	
	If AccountPlansByType[Common.MetadataObjectID(LocalAccntingClientServer.TypeChartOfAccounts(), False)] <> Null Then
		RegulatedIsUsed = True;
	EndIf;
	
	If UsedInternational Then
		
		If FunctionalCurrencyIsAvailable Then
			ChoiceList.Add("Sum", NStr("vi = 'Theo tiền tệ chức năng của doanh nghiệp';
										|ru = 'В функциональной валюте организации';
										|en = 'In company functional currency'; fa = 'In company functional currency';
										|it = 'Nella valuta funzionale dell''azienda';
										|pl = 'W walucie funkcjonalnej firmy';
										|tr = 'İş yerinin fonksiyonel para biriminde'"));
			ResourceCurrencyChange.Insert("Sum", Undefined);
		EndIf;
		If PresentationCurrencyAvailable Then
			ChoiceList.Add("PresentationAmount", NStr("vi = 'Bằng tiền trình bày';
														|ru = 'В валюте представления';
														|en = 'In presentation currency'; fa = 'به ارز ارائه';
														|it = 'Nella valuta di presentazione';
														|pl = 'W walucie funkcjonalnej';
														|tr = 'Sunum para biriminde'") + StrTemplate(" (%1)", PresentationCurrency));
			ResourceCurrencyChange.Insert("PresentationAmount", PresentationCurrency);
		EndIf;
		
	ElsIf RegulatedIsUsed Then
		
		ChoiceList.Add("Sum", NStr("vi = 'Kế toán doanh nghiệp theo tiền tệ pháp quy của doanh nghiệp';
									|ru = 'Бухгалтерский учет в регл. валюте организации';
									|en = 'Company local accounting currency'; fa = 'Company local accounting currency';
									|it = 'Contabilità nella valuta regolatoria dell''azienda';
									|pl = 'Ewidencja księgowa w walucie reglamentowanej firmy';
									|tr = 'İş yerinin yerel para biriminde muhasebe hesabı'"));
		ResourceCurrencyChange.Insert("Sum", Undefined);
		If LocalAccountingSettings.AdditionallyManagementAccountingIsConducted Then
			ChoiceList.Add("AmountOfUU", NStr("vi = 'Kế toán quản trị';
												|ru = 'Управленческий учет';
												|en = 'Management accounting'; fa = 'حسابداری مدیریت';
												|it = 'Contabilità gestionale';
												|pl = 'Ewidencja zarządcza';
												|tr = 'Yönetim muhasebesi'") + StrTemplate(" (%1)", ManagementAccountingCurrency));
			ResourceCurrencyChange.Insert("AmountOfUU", ManagementAccountingCurrency);
		EndIf;
		If LocalAccountingSettings.AdditionallyAccountingIsCarriedOutInCurrencyOfFinancialStatements Then
			ChoiceList.Add("FOAmount", 
				NStr("vi = 'Theo tiền tệ báo cáo tài chính';
					|ru = 'В валюте финансовой отчетности';
					|en = 'In financial reporting currency'; fa = 'In financial reporting currency';
					|it = 'Nella valuta della rendicontazione finanziaria';
					|pl = 'W walucie rachunkowości finansowej';
					|tr = 'Finansal raporlama para biriminde'") + StrTemplate(" (%1)", LocalAccountingSettings.FinReportingCurrency));
			ResourceCurrencyChange.Insert("FOAmount", LocalAccountingSettings.FinReportingCurrency);
		EndIf;
		
	ElsIf UsedInternational And RegulatedIsUsed Then
		
		ChoiceList.Add("Sum",NStr("vi = 'Theo tiền tệ pháp quy và chức năng của doanh nghiệp';
									|ru = 'В функц. и регл. валюте организации';
									|en = 'In functional and local accounting currency of the company'; fa = 'In functional and local accounting currency of the company';
									|it = 'Nella valuta funzionale e regolatoria dell''azienda';
									|pl = 'W walucie funkcjonalnej i reglamentowanej firmy';
									|tr = 'İş yerinin yönetim ve yerel para biriminde'"));
		ResourceCurrencyChange.Insert("Sum", Undefined);
		
	EndIf;
	
	ResourceCurrencies = New FixedStructure(ResourceCurrencyChange); // Since the storage is in the form's props, there must be a fixed structure
	
EndProcedure

Procedure CheckingLoopingOfReportTypes(Count_, TextOfFoundLoop = "", VertexColoring = Undefined)   Export
	
	If ValueIsFilled(TextOfFoundLoop) Then
		Return;
	EndIf;
	
	If VertexColoring = Undefined Then 
		VertexColoring = New Map;
	EndIf;
	
	For Each Vertex  In Count_.Rows  Do
		
		If VertexColoring.Get(Vertex.ReportItem) = Undefined Then
			
			If Vertex.ItemKind = Enums.FinancialReportItemKinds.ComplexTable
					Or Vertex.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
				Continue;
			EndIf;
			
			//New peak
			If Vertex.ItemKind <>  Enums.FinancialReportItemKinds.Group Then
				VertexColoring.Insert(Vertex.ReportItem, 1);
			EndIf;
			
			CheckingLoopingOfReportTypes(Vertex, TextOfFoundLoop, VertexColoring);
			
			If ValueIsFilled(Vertex.LinkedItem1) Then
				ReportKind = Common.ObjectAttributeValue(Vertex.LinkedItem1, "Owner");
				SubordinateCount_ = UpdateTheReportTree(ReportKind, Vertex.LinkedItem1);
				CheckingLoopingOfReportTypes(SubordinateCount_, TextOfFoundLoop, VertexColoring);
			EndIf;
			
			If Vertex.ItemKind =  Enums.FinancialReportItemKinds.TotalByGroup  And Not ValueIsFilled(Vertex.LinkedItem1)  Then
				VertexColoring.Insert(Vertex.ReportItem, 0);
				ReportKind = Common.ObjectAttributeValue(Vertex.ReportItem, "Owner");
				SubordinateCount_ = UpdateTheReportTree(ReportKind, Vertex.ReportItem);
				CheckingLoopingOfReportTypes(SubordinateCount_, TextOfFoundLoop, VertexColoring);
			EndIf;
			
			VertexColoring.Insert(Vertex.ReportItem, 0);
			
		ElsIf VertexColoring[Vertex.ReportItem] = 1 Then
			
			//Cycle found
			For Each Vertex In VertexColoring Do
				
				ReportItem = Vertex.Key;
				
				ExcludedKinds = New Array;
				ExcludedKinds.Add(Enums.FinancialReportItemKinds.TableIndicatorsInColumns );
				ExcludedKinds.Add(Enums.FinancialReportItemKinds.TableIndicatorsInRows);
				ExcludedKinds.Add(Enums.FinancialReportItemKinds.ComplexTable);
				ExcludedKinds.Add(Enums.FinancialReportItemKinds.Columns);
				ExcludedKinds.Add(Enums.FinancialReportItemKinds.Rows);
				
				If Vertex.Value = 1  
						And ValueIsFilled(ReportItem.ItemKind) 
						And ExcludedKinds.Find(ReportItem.ItemKind) = Undefined Then
					TextOfFoundLoop = TextOfFoundLoop + ReportItem.NameForPrinting + " ("  +  ReportItem.Owner + "), ";
				EndIf; 
			EndDo;
			
			TextOfFoundLoop = StrTemplate(NStr("vi = 'Đã phát hiện các mục vòng lặp báo cáo:%1';
												|ru = 'Обнаружено зацикливание элементов отчетов: %1';
												|en = 'Report items looping is detected: %1'; fa = 'Report items looping is detected: %1';
												|it = 'Trovato elementi di lopping dei report. %1';
												|pl = 'Stwierdzono zapętlenie się elementów raportów: %1';
												|tr = 'Rapor öğelerinin döngü yaptığı algılandı: %1'"), Left(TextOfFoundLoop, StrLen(TextOfFoundLoop)-2));
			Return;
			
		EndIf; 
	
	EndDo; 
	
EndProcedure

Procedure ExtdimensionSubordinates(TableDetails, RowsOfElements, ExtDimension, ItemsKinds, ExtDimensionNumber = 1, TheseAreColumns = False)
	                                                                                                                                                                                                                                                                                                            
	For Each ElementString In RowsOfElements Do
		
		If ElementString.DimensionType = Enums.TypesOfBudgetReportDimensions.ExtDimension Then
			
			ExtdimensionStructureForQuery = New Structure;
			ExtdimensionStructureForQuery.Insert("Kind", 								ElementString.ExtDimensionType);
			ExtdimensionStructureForQuery.Insert("HasSettings", 	ElementString.HasSettings);
			ExtdimensionStructureForQuery.Insert("Description", 	ElementString.NameForPrinting);
			
			NameExtdimension = "Dimension" + ExtDimensionNumber;
			
			If ElementString.HasSettings And Not TableDetails.ThisIsArbitrary  Then
				AdditionalSelection = ElementString.AdditionalSelection; //ValueStorage
				Filter_Settings = AdditionalSelection.Get();
				ReplaceNameExtdimensionInSelection(Filter_Settings.Filter, NameExtdimension);
				FilterAnalysts = New ValueStorage(Filter_Settings);
			Else
				FilterAnalysts = ElementString.AdditionalSelection;
			EndIf;
			ExtdimensionStructureForQuery.Insert("Filter", FilterAnalysts);
			
			ExtDimension.Insert(NameExtdimension, ExtdimensionStructureForQuery); 
			TableDetails.AnalystDescription.Insert(ElementString, New Structure("DimensionNumber", ExtDimensionNumber));
			
			//For a complex table, we add analytics to the indicators line by line
			If TableDetails.ThisIsArbitrary Then
				For Each ReportIndicator In TableDetails.Indicators Do
					If TheseAreColumns And ReportIndicator.Value.Column = ElementString.ReportItem
								Or Not  TheseAreColumns And ReportIndicator.Value.String = ElementString.ReportItem Then
						ExtdimensionNumber_ = 1;
						For Each ExtdimensionOfIndicator In ReportIndicator.Value.ExtDimension Do
							If StrFind(ExtdimensionOfIndicator.Key, ?(TheseAreColumns, "DimensionColumns1", "DimensionLines") ) <> 0 Then
								ExtdimensionNumber_ = ExtdimensionNumber_ + 1;
							EndIf;
						EndDo;
						For Each ExtraDimensionValue In ExtDimension Do
							NameExtdimension = ?(TheseAreColumns, "DimensionColumns1", "DimensionLines") + ExtdimensionNumber_; 
							If ExtraDimensionValue.Value.HasSettings Then
								FilterValue = ExtraDimensionValue.Value.Filter; //ValueStorage
								Filter_Settings = FilterValue.Get();
								ReplaceNameExtdimensionInSelection(Filter_Settings.Filter, NameExtdimension);
								FilterAnalysts = New ValueStorage(Filter_Settings);
							Else
								FilterAnalysts = ExtraDimensionValue.Value.Filter;
							EndIf;
							NewMeaningOfExtdimension = New Structure("Kind, HasSettings, Description");
							FillPropertyValues(NewMeaningOfExtdimension, ExtraDimensionValue.Value);
							NewMeaningOfExtdimension.Insert("Filter", FilterAnalysts);
							ReportIndicator.Value.ExtDimension.Insert(NameExtdimension, NewMeaningOfExtdimension);
							ExtdimensionNumber_ = ExtdimensionNumber_ + 1;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
			ExtDimensionNumber = ExtDimensionNumber + 1;
			
			If ElementString.Rows.Count() Then
				ExtdimensionSubordinates(TableDetails, ElementString.Rows, ExtDimension, ItemsKinds, ExtDimensionNumber, TheseAreColumns);
			EndIf;
			
		ElsIf ThisIsIndicator(ElementString.ItemKind, ItemsKinds) And Not ThisIsIndicator(ElementString.Parent.ItemKind, ItemsKinds) Then
			
			IndicatorData = TableDetails.Indicators.Get(ElementString.ReportItem);
			If IndicatorData = Undefined Then
				TableDetails.Indicators.Insert(ElementString.ReportItem, New Structure("LongDesc,ExtDimension", ElementString, ExtDimension));
			Else
				For Each ExtraDimensionValue In ExtDimension Do
					IndicatorData.ExtDimension.Insert(ExtraDimensionValue.Key, ExtraDimensionValue.Value);
				EndDo;  
			EndIf;
			
		ElsIf ElementString.ItemKind = ItemsKinds.RowColumn Then
			
			If  ExtDimension.Property("Dimension1") Then
				For Each ReportIndicator In TableDetails.Indicators Do
					If TheseAreColumns And ReportIndicator.Value.Column = ElementString.ReportItem
						Or Not  TheseAreColumns And ReportIndicator.Value.String = ElementString.ReportItem Then
						ExtdimensionNumber_ = 1;
						For Each ExtdimensionOfIndicator In ReportIndicator.Value.ExtDimension Do
							If StrFind(ExtdimensionOfIndicator.Key, ?(TheseAreColumns, "DimensionColumns1", "DimensionLines") ) <> 0 Then
								ExtdimensionNumber_ = ExtdimensionNumber_ + 1;
							EndIf;
						EndDo;
						For Each ExtraDimensionValue In ExtDimension Do
							NameExtdimension = ?(TheseAreColumns, "DimensionColumns1", "DimensionLines") + ExtdimensionNumber_; 
							
							If ExtraDimensionValue.Value.HasSettings Then
								FilterValue = ExtraDimensionValue.Value.Filter; //ValueStorage
								Filter_Settings = FilterValue.Get();
								ReplaceNameExtdimensionInSelection(Filter_Settings.Filter, NameExtdimension);
								FilterAnalysts = New ValueStorage(Filter_Settings);
							Else
								FilterAnalysts = ExtraDimensionValue.Value.Filter;
							EndIf;
							NewMeaningOfExtdimension = New Structure("Kind, HasSettings, Description");
							FillPropertyValues(NewMeaningOfExtdimension, ExtraDimensionValue.Value);
							NewMeaningOfExtdimension.Insert("Filter", FilterAnalysts);
							ReportIndicator.Value.ExtDimension.Insert(NameExtdimension, ExtraDimensionValue.Value);
							ExtdimensionNumber_ = ExtdimensionNumber_ + 1;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
			
		ElsIf ElementString.ItemKind = ItemsKinds.Group Then
			
			If ElementString.Rows.Count() Then
				ExtdimensionSubordinates(TableDetails, ElementString.Rows, ExtDimension, ItemsKinds, ExtDimensionNumber, TheseAreColumns);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SubordinateIndicatorsOfExtdimension(TableDetails, ElementString, ItemsKinds,  ArrayOfIndicators)
	
	For Each ReportRow In ElementString.Rows Do
		
		If ThisIsIndicator(ReportRow.ItemKind, ItemsKinds) Then
			ArrayOfIndicators.Add(ReportRow.ReportItem);
		EndIf;
		
		If ReportRow.Rows.Count() Then
			SubordinateIndicatorsOfExtdimension(TableDetails, ReportRow, ItemsKinds, ArrayOfIndicators);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReplaceNameExtdimensionInSelection(Setting, NewNameExtdimension)  Export
	
	For Each FilterSettings In Setting.Items Do
		
		If TypeOf(FilterSettings) = Type("DataCompositionFilterItemGroup") Then
			ReplaceNameExtdimensionInSelection(FilterSettings, NewNameExtdimension);
		Else
			
			If StrFind(FilterSettings.LeftValue, "ExtDimension") <> 0 Then
				
				For ExtdimensionNumberOfSelection = 1 To FinancialAccountingServerCached.MaxExtDimensionCount() Do
					If StrFind(FilterSettings.LeftValue, "ExtDimension" + ExtdimensionNumberOfSelection) <> 0 Then
						Break;
					EndIf;
				EndDo;
				
				FilterSettings.LeftValue = New DataCompositionField(
				StrReplace(FilterSettings.LeftValue, "ExtDimension"+ExtdimensionNumberOfSelection, NewNameExtdimension));
				
			EndIf; 
			
		EndIf;
		
	EndDo; 
	
EndProcedure

#EndRegion

#EndRegion