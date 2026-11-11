#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function checks whether the budget view is filled in.
//
// Parameters:
//  BudgetProfile  - CatalogRef.BudgetProfiles - the type of budget to check.
//
// Returns:
//   Boolean - the result of the check: true - there are no errors, false - there are errors.
//
Function BudgetViewIsFilledInCorrectly(BudgetProfile) Export
	
	SetPrivilegedMode(True);
	
	TypeOfCacheElement = Enums.BudgetCacheKinds.CheckResult;
	CheckResult = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile,
		TypeOfCacheElement);
	
	If CheckResult = True Then
		SetPrivilegedMode(False);
		Return True;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("BudgetProfile", BudgetProfile);
	DetailsOfBudgetType = Common.ObjectAttributesValues(BudgetProfile,
		"Owner, UseToEnterPlan, MainInputMethod, Periodicity");
	Parameters.Insert("Attributes", DetailsOfBudgetType);
	
	// checking that the same types of analytics are in the budget dimensions
	If DetailsOfBudgetType.UseToEnterPlan Then
		Parameters.Insert("GenerationMode", Enums.ModesOfBudgetReportGeneration.Document);
	Else
		Parameters.Insert("GenerationMode", Enums.ModesOfBudgetReportGeneration.Report);
	EndIf;
	Parameters.Insert("BudgetViewParameters", BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
		BudgetProfile, Parameters.GenerationMode));
	Parameters.Insert("ColumnStructureOfDataTable", Parameters.BudgetViewParameters.ColumnStructureOfDataTable);
	Parameters.Insert("StructureOfReportDescription", Parameters.BudgetViewParameters.StructureOfReportDescription);
	Parameters.Insert("ItemTreeWithoutAdditionalItems", BudgetReportingCacheCalculationServer.BudgetItemTree(
		BudgetProfile));
	Parameters.Insert("ItemTreeWithAdditionalItems", BudgetReportingCacheCalculationServer.BudgetItemTree(
		BudgetProfile, True));
	CheckSameTypesOfAnalyticsInBudgetDimensions(Parameters);
	
	ErrorsMessages = Undefined;
	
	// checking that at least one data source is specified
	CheckForDataSources(Parameters, ErrorsMessages);
	
	// checking cycles in formulas
	CheckForCycles(Parameters, ErrorsMessages);
	
	// checking the correspondence of the location of articles and analytics
	CheckIfAllElementsAreMissing(Parameters, ErrorsMessages);
	
	// checking for the absence of measurements (except "analytic1,2,3") in the input mode
	CheckCorrectnessOfAnalystIndication(Parameters, ErrorsMessages);
	
	// checking for the absence of measurements and unfixed analytics in the input mode
	CheckForMissingAnalystMeasurementsInInputMode(Parameters, ErrorsMessages);
	
	// checking for compliance of analytics with articles
	CheckCorrectnessOfMeasurementIndication(Parameters, ErrorsMessages);
	
	// checking for the correctness of entering periods
	CheckIfPeriodsDoNotIntersect(Parameters, ErrorsMessages);
	
	// checking for rows/columns
	CheckForColumnRows(Parameters, ErrorsMessages);
	
	// checking for duplicates of types of analytics within the owner
	CheckDuplicatesOfAnalystViews(Parameters, ErrorsMessages);
	
	// checking that non-currency items and indicators do not have a currency
	CheckCurrencyComplianceWithArticles(Parameters, ErrorsMessages);
	
	// checking that there are no articles with the same analytics to enter
	CheckDuplicatesOfLinesOfBudgetItemsByAnalytics(Parameters, ErrorsMessages);
	
	// checking that there are no identical articles within the same group, which distorts the output of the final indicators
	CheckDuplicatesOfLinesOfBudgetItemsByGroups(Parameters, ErrorsMessages);
	
	// checking that there are no intersections of the same analytical sections in the cells
	CheckIntersectionOfAnalyticalSections(Parameters, ErrorsMessages);
	
	// checking that there are no intersections of the same analytical sections in the cells
	CheckIfThereAreNoInputElementsOnGroupingLevels(Parameters, ErrorsMessages);
	
	// checking that the periodicity of elements is less than the periodicity of the budget type
	CheckFrequencyOfBudgetViewElements(Parameters, ErrorsMessages);
	
	// checking that the header and structure analysts do not overlap
	CheckIntersectionOfAnalyticsInHeaderAndStructure(Parameters, ErrorsMessages);
	
	// checking that there are no identical dimensions subordinate to each other
	CheckForIdenticalMeasurementsWithinSameBranch(Parameters, ErrorsMessages);
	
	// checking that there are no data sources for which the measurement is simultaneously set in the add. selections and in budget lines/columns
	CheckingForIntersectionOfMeasurementsInSourceDoppelgangersAndColumns(Parameters, ErrorsMessages);
	
	// Checking that there is no hierarchy output for analysts displayed together in one row or column
	CheckIfThereIsNoHierarchyOutputByAnalystsOutputTogether(Parameters, ErrorsMessages);
	
	HasErrors = ErrorsMessages <> Undefined And ErrorsMessages.Count();
	If HasErrors Then
		CommonClientServer.ReportErrorsToUser(ErrorsMessages);
	EndIf;
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile,
		TypeOfCacheElement, Not HasErrors);
	
	SetPrivilegedMode(False);
	
	Return Not HasErrors;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Owner");
	Result.Add("UseToEnterPlan");
	Result.Add("UseDeferredPostingOfBudgetEntryForms");
	Result.Add("GenerateRelatedBudgetTurnovers");
	
	Return Result;
	
EndFunction

// The function returns the result of checking whether there are Analytics in the header for the budget type passed to the parameter.
// 
// Parameters:
//  BudgetProfile  - CatalogRef.BudgetProfiles - the type of budget to check.
//
// Returns:
// 	- Boolean - True if the header analytics are used in the form of the budget passed in the parameter.
// 				False - if the caps are not used in the form of the budget passed in the analytics parameter.
// 	- Undefined - if an invalid value is passed as a parameter.
//
Function BudgetViewContainsAnalyticsCaps(BudgetProfile) Export
	
	Return ?(Not ValueIsFilled(BudgetProfile), 
		False, Not Common.ObjectAttributeValue(BudgetProfile, "HeaderDimensions").IsEmpty());
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN Catalog.BudgetProfiles.ItemAndIndicatorCache AS T1 
	|	ON T.Ref = T1.Ref AND T1.PrivilegedMode = FALSE
	|;
	|AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ForAllRows( ValueAllowed(T1.ItemIndicator, NULL AS TRUE)
	|	) AND ValueAllowed(T.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region CheckingBudgetType

Procedure CheckDuplicatesOfLinesOfBudgetItemsByAnalytics(Parameters, ErrorsMessages)
	
	If Parameters.GenerationMode <> Enums.ModesOfBudgetReportGeneration.Document Then
		Return;
	EndIf;
	
	ItemsTree = Parameters.ItemTreeWithoutAdditionalItems;
	ColumnStructureOfDataTable = Parameters.ColumnStructureOfDataTable;
	StructureOfReportDescription = Parameters.StructureOfReportDescription;
	
	CellParameters = StructureOfReportDescription.CellParameters;
	TheStructureOfTheSearch = New Structure("MainItem, ItemKind", True, Enums.FinancialReportItemKinds.BudgetFlowItem);
	CellStructure = StructureOfReportDescription.CellStructure.Copy(TheStructureOfTheSearch);
	CellStructure.Columns.Add("Flag");
	CellStructure.Columns.Add("FlagCount");
	CellStructure.Columns.Add("FlagSum");
	CellStructure.FillValues(1, "Flag");
	
	// we check only the lower level of cells for duplicates
	ArrayToDelete = New Array;
	For Each CellRow In CellStructure Do
		CellParameters_ = CellParameters.Find(CellRow.RowIndex, "RowIndex");
		CellRow.FlagCount = CellParameters_.FlagCount;
		CellRow.FlagSum = CellParameters_.FlagSum;
		FoundTreeElement = ItemsTree.Rows.Find(CellRow.String, "ReportItem", True);
		If FoundTreeElement.Rows.Count() Then
			ArrayToDelete.Add(CellRow);
			Continue;
		EndIf;
		If Not ValueIsFilled(CellRow.Column) Then
			Continue;
		EndIf;
		FoundTreeElement = ItemsTree.Rows.Find(CellRow.Column, "ReportItem", True);
		If FoundTreeElement.Rows.Count() Then
			ArrayToDelete.Add(CellRow);
		EndIf;
	EndDo;
	
	For Each RowToDelete In ArrayToDelete Do
		CellStructure.Delete(RowToDelete);
	EndDo;
	
	ConvolutionString = "";
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		ConvolutionString = ConvolutionString + Dimension + ", ";
	EndDo;
	
	For Each DimensionKind In ColumnStructureOfDataTable.DimensionKinds Do
		Dimension = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		ConvolutionString = ConvolutionString + Dimension + ", ";
	EndDo;
	
	For Each Periodicity In ColumnStructureOfDataTable.Periodicity_ Do
		Dimension = FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodExpression;
		ConvolutionString = ConvolutionString + Dimension + ", ";
	EndDo;
	
	CopyByQuantity = CellStructure;
	CopyByAmount = CellStructure.Copy();
	
	ConvolutionString = ConvolutionString + "BudgetFlowItem";
	CopyByQuantity.GroupBy(ConvolutionString + ", FlagCount", "Flag");
	CopyByAmount.GroupBy(ConvolutionString + ", FlagSum", "Flag");
	
	CellStructure = CopyByQuantity;
	CommonClientServer.SupplementTable(CellStructure, CopyByAmount);
	
	ComplianceOfArticles = New Map;
	For Each CheckString In CellStructure Do
		If CheckString.Flag > 1 And ValueIsFilled(CheckString.BudgetFlowItem) Then
			ComplianceOfArticles.Insert(CheckString.BudgetFlowItem);
		EndIf;
	EndDo;
	
	For Each KeysAndValue In ComplianceOfArticles Do
		ErrorText = NStr("vi = 'Dạng ""%1"" xuất hiện nhiều lần trong chế độ xem ngân sách với cùng một chỉ số';
						|ru = 'Статья ""%1"" встречается внутри вида бюджета несколько раз с одинаковой аналитикой';
						|en = 'Multiple copies of item ""%1"" with the same dimension are found in the budget profile'; fa = 'Multiple copies of item ""%1"" with the same dimension are found in the budget profile';
						|it = 'La voce ""%1"" viene riscontrata nel tipo di budget più volte con la stessa analisi';
						|pl = 'Pozycja ""%1"" pojawia się wewnątrz rodzaju budżetu kilka razy z jednakową analityką';
						|tr = '""%1"" maddesi bütçe profili dahilinde aynı boyut ile birkaç kez geçmektedir'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, KeysAndValue.Key);
		CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
	EndDo;
	
EndProcedure

Procedure CheckForMissingAnalystMeasurementsInInputMode(Parameters, ErrorsMessages)
	
	If Parameters.GenerationMode <> Enums.ModesOfBudgetReportGeneration.Document Then
		Return;
	EndIf;
	
	ItemsTree = Parameters.ItemTreeWithAdditionalItems;
	
	TheStructureOfTheSearch = New Structure("DimensionType", Enums.TypesOfBudgetReportDimensions.RegisterDimension);
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	For Each FoundRow In FoundRows Do
		
		ErrorText = NStr("vi = 'Đã tìm thấy phần tử ""%1"" không khả dụng để nhập';
						|ru = 'Обнаружен недоступный для ввода элемент ""%1""';
						|en = 'Item ""%1"" that cannot be entered is found'; fa = 'Item ""%1"" that cannot be entered is found';
						|it = 'Rilevato elemento ""%1"" non disponibile per immissione';
						|pl = 'Wykryto element ""%1"", którego wprowadzenie nie jest możliwe';
						|tr = '""%1"" öğesine giriş için erişim sağlanamadığı tespit edildi'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
			FoundRow.NameForPrinting);
		CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
		
	EndDo;
	
	TheStructureOfTheSearch = New Structure("DimensionType", Enums.TypesOfBudgetReportDimensions.Dimension);
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	For Each FoundRow In FoundRows Do
		IncludedInDerivedIndicator = False;
		CurrentRow = FoundRow.Parent;
		While CurrentRow <> Undefined Do
			If CurrentRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
				IncludedInDerivedIndicator = True;
				Break;
			EndIf;
			CurrentRow = CurrentRow.Parent;
		EndDo;
		
		If Not IncludedInDerivedIndicator Then 
			ErrorText = NStr("vi = 'Đã tìm thấy phần tử ""%1"" không khả dụng để nhập';
							|ru = 'Обнаружен недоступный для ввода элемент ""%1""';
							|en = 'Item ""%1"" that cannot be entered is found'; fa = 'Item ""%1"" that cannot be entered is found';
							|it = 'Rilevato elemento ""%1"" non disponibile per immissione';
							|pl = 'Wykryto element ""%1"", którego wprowadzenie nie jest możliwe';
							|tr = '""%1"" öğesine giriş için erişim sağlanamadığı tespit edildi'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				FoundRow.NameForPrinting);
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckDuplicatesOfAnalystViews(Parameters, ErrorsMessages)
	
	ItemsTree = Parameters.ItemTreeWithAdditionalItems;
	
	TheStructureOfTheSearch = New Structure("ItemKind, DimensionType",
		Enums.FinancialReportItemKinds.Dimension,
		Enums.TypesOfBudgetReportDimensions.FixedDimension);
	
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	
	TableOfParents = New ValueTable;
	TableOfParents.Columns.Add("ParentReportElement");
	
	For Each FoundRow In FoundRows Do
		If Not ValueIsFilled(FoundRow.Parent) Then
			TableOfParents.Add();
		Else
			TableOfParents.Add().ParentReportElement = FoundRow.Parent.ReportItem;
		EndIf;
	EndDo;
	
	TableOfParents.GroupBy("ParentReportElement");
	
	CheckTable = New ValueTable;
	CheckTable.Columns.Add("NameForPrinting");
	CheckTable.Columns.Add("Value");
	CheckTable.Columns.Add("Flag");
	
	For Each ParentElementString In TableOfParents Do
		
		If Not ValueIsFilled(ParentElementString.ParentReportElement) Then
			FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, False);
		Else
			ParentLevelRow = ItemsTree.Rows.Find(ParentElementString.ParentReportElement, "ReportItem", True);
			FoundRows = ParentLevelRow.Rows.FindRows(TheStructureOfTheSearch, False);
		EndIf;
		
		CheckTable.Clear();
		For Each FoundRow In FoundRows Do
			NewRow = CheckTable.Add();
			NewRow.NameForPrinting = FoundRow.NameForPrinting;
			NewRow.Value = FoundRow.DimensionValue;
			NewRow.Flag = 1;
		EndDo;
		
		CheckTable.GroupBy("NameForPrinting, Value", "Flag");
		CheckTable.Sort("Flag DESC");
		
		While CheckTable.Count() And CheckTable[0].Flag > 1 Do
			Message = NStr("vi = 'Giá trị cố định ""%1"" không được lặp lại nhiều lần';
							|ru = 'Фиксированное значение ""%1"" не должно повторятся более одного раза';
							|en = 'Fixed value ""%1"" must not be repeated more than once'; fa = 'Fixed value ""%1"" must not be repeated more than once';
							|it = 'Il valore fisso ""%1"" non deve essere ripetuto più di una volta';
							|pl = 'Wartość stała ""%1"" nie może powtarzać się więcej niż jeden raz';
							|tr = '""%1"" sabit değeri birden fazla kez tekrar etmemelidir'");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message,
				CheckTable[0].NameForPrinting);
			CommonClientServer.AddUserError(ErrorsMessages, "", Message, "");
			CheckTable.Delete(0);
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure PreparePeriodControlParameters(BudgetProfile, Parameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FinancialReportItems.Ref,
	|	FinancialReportItems.Parent,
	|	FinancialReportItems.ItemKind,
	|	OptionalMeasurementType.Value AS DimensionType,
	|	AdditionalDetailsPeriodicity.Value AS Periodicity
	|FROM
	|	Catalog.FinancialReportItems AS FinancialReportItems
	|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS OptionalMeasurementType
	|		ON (OptionalMeasurementType.Ref = FinancialReportItems.Ref)
	|			AND (OptionalMeasurementType.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionType))
	|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS AdditionalDetailsPeriodicity
	|		ON (AdditionalDetailsPeriodicity.Ref = FinancialReportItems.Ref)
	|			AND (AdditionalDetailsPeriodicity.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.Periodicity))
	|WHERE
	|	FinancialReportItems.Owner = &Owner
	|	AND NOT FinancialReportItems.DeletionMark";
	
	Query.SetParameter("Owner", BudgetProfile);
	QueryResult = Query.Execute();
	Parameters = QueryResult.Unload();
	Parameters.Indexes.Add("Ref");
	
EndProcedure

Function HigherPeriods(Item, ControlParameters, CacheOfPeriodChains)
	
	Value = CacheOfPeriodChains[Item];
	If Value <> Undefined Then
		Return Value;
	EndIf;
	
	Array = New Array;
	ControlString = ControlParameters.Find(Item, "Ref");
	
	While ControlString <> Undefined Do
		
		If ControlString.ItemKind = Enums.FinancialReportItemKinds.Dimension
			And ControlString.DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
			Array.Add(ControlString.Periodicity);
		EndIf;
		
		ControlString = ControlParameters.Find(ControlString.Parent, "Ref");
		
	EndDo;
	
	CacheOfPeriodChains.Insert(Item, Array);
	
	Return Array;
	
EndFunction

Function IncorrectOrderOfPeriods(ArrayOfPeriods)
	
	TimeIntervals = New Array;
	CommonClientServer.SupplementArray(TimeIntervals, ArrayOfPeriods);
	
	While TimeIntervals.Count() Do
		MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(TimeIntervals);
		If Not TimeIntervals[0] = MinimumPeriodicity Then
			Return True;
		EndIf;
		TimeIntervals.Delete(0);
	EndDo;
	
	Return False;
	
EndFunction

Procedure CheckIfPeriodsDoNotIntersect(Parameters, ErrorsMessages)
	Var ControlParameters;
	
	PreparePeriodControlParameters(Parameters.BudgetProfile, ControlParameters);
	
	StructureOfReportDescription = Parameters.StructureOfReportDescription;
	
	CellStructure = StructureOfReportDescription.CellStructure.Copy();
	
	CacheOfPeriodChains = New Map;
	
	For Each StructureString_ In CellStructure Do
		
		ArrayOfUpstreamPeriodsOfString = HigherPeriods(StructureString_.String, ControlParameters, CacheOfPeriodChains);
		ArrayOfHigherColumnPeriods = HigherPeriods(StructureString_.Column, ControlParameters, CacheOfPeriodChains);
		
		If ArrayOfHigherColumnPeriods.Count()
			And ArrayOfUpstreamPeriodsOfString.Count() Then
			
			MessageText = NStr("vi = 'Kỳ không thể ở trong hàng và cột';
								|ru = 'Период не может быть и в строках и в колонках';
								|en = 'Period cannot be both in lines and columns'; fa = 'Period cannot be both in lines and columns';
								|it = 'Il periodo non può essere sia nelle righe che nelle colonne';
								|pl = 'Okres nie może znajdować się i w wierszach i w kolumnach';
								|tr = 'Dönem satırlarda ve sütunlarda yer almamalıdır'");
			CommonClientServer.AddUserError(ErrorsMessages, "", MessageText, "");
			Break;
			
		EndIf;
		
		If IncorrectOrderOfPeriods(ArrayOfHigherColumnPeriods)
			Or IncorrectOrderOfPeriods(ArrayOfUpstreamPeriodsOfString) Then
			
			MessageText = NStr("vi = 'Một kỳ lớn hơn không nằm trong một kỳ nhỏ hơn';
								|ru = 'Больший период не может входить в меньший';
								|en = 'A shorter period cannot include a longer one'; fa = 'A shorter period cannot include a longer one';
								|it = 'Un periodo più lungo non può fare parte di uno più piccolo';
								|pl = 'Większy okres nie może być zawarty w mniejszym';
								|tr = 'Uzun bir dönem daha kısa bir döneme dahil edilemez'");
			CommonClientServer.AddUserError(ErrorsMessages, "", MessageText, "");
			Break;
			
		EndIf;
		
	EndDo;
	
	For Each StructureString_ In CellStructure Do
		
		ArrayOfUpstreamPeriodsOfString = HigherPeriods(StructureString_.String, ControlParameters, CacheOfPeriodChains);
		ArrayOfHigherColumnPeriods = HigherPeriods(StructureString_.Column, ControlParameters, CacheOfPeriodChains);
		
		If ThereIsWeekInDecades(ArrayOfUpstreamPeriodsOfString)
			Or ThereIsWeekInDecades(ArrayOfHigherColumnPeriods) Then
			
			MessageText = NStr("vi = 'Một tuần không thể có trong mười ngày';
								|ru = 'Неделя не может входить в декаду';
								|en = 'A ten-day period cannot include a week'; fa = 'A ten-day period cannot include a week';
								|it = 'La settimana non può far parte della decade';
								|pl = 'Tydzień nie może być zawarty w dekadzie';
								|tr = 'Hafta 10 günlük süreye dahil edilemez'");
			CommonClientServer.AddUserError(ErrorsMessages, "", MessageText, "");
			Break;
			
		EndIf;
			
	EndDo;
	
	PeriodsTable = ControlParameters.Copy(
		New Structure("DimensionType", Enums.TypesOfBudgetReportDimensions.Period),
		"Ref,Parent,Periodicity");
		
	Query = New Query;
	Query.SetParameter("PeriodsTable", PeriodsTable);
	Query.Text = 
	"SELECT
	|	CAST(PeriodsTable.Ref AS Catalog.FinancialReportItems) AS Ref,
	|	CAST(PeriodsTable.Parent AS Catalog.FinancialReportItems) AS Parent
	|INTO TimeIntervals
	|FROM
	|	&PeriodsTable AS PeriodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TimeIntervals.Parent AS Parent,
	|	PeriodValueAttributes.Value AS PeriodValue,
	|	PeriodicityAttributes.Value AS Periodicity
	|FROM
	|	TimeIntervals AS TimeIntervals
	|		INNER JOIN Catalog.FinancialReportItems.ItemKindAttributes AS PeriodicityAttributes
	|		ON TimeIntervals.Ref = PeriodicityAttributes.Ref
	|			AND (PeriodicityAttributes.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.Periodicity))
	|		INNER JOIN Catalog.FinancialReportItems.ItemKindAttributes AS PeriodValueAttributes
	|		ON TimeIntervals.Ref = PeriodValueAttributes.Ref
	|			AND (PeriodValueAttributes.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.PeriodValue))
	|
	|GROUP BY
	|	PeriodicityAttributes.Value,
	|	PeriodValueAttributes.Value,
	|	TimeIntervals.Parent
	|
	|HAVING
	|	COUNT(TimeIntervals.Ref) > 1";
	
	If Not Query.Execute().IsEmpty() Then
		
		MessageText = NStr("vi = 'Sắp xếp không hợp lý các giá trị giống nhau của kỳ trong một mức độ phân nhánh';
							|ru = 'Недопустимо расположение одинаковых значений периодов внутри одного уровня иерархии';
							|en = 'Cannot have the same period values within one hierarchy level'; fa = 'Cannot have the same period values within one hierarchy level';
							|it = 'Non è possibile inserire i valori dello stesso periodo nel medesimo livello gerarchico';
							|pl = 'Niedopuszczalna lokalizacja jednakowych wartości okresów wewnątrz jednego poziomu hierarchii';
							|tr = 'Aynı dönem değerlerinin aynı hiyerarşi seviyesi dahilinde yerleştirilmesine izin verilemez'");
		CommonClientServer.AddUserError(ErrorsMessages, "", MessageText, "");
		
	EndIf;
	
	PeriodsTable.GroupBy("Parent,Periodicity");
	GroupsOfPeriods = PeriodsTable.Copy(, "Parent");
	GroupsOfPeriods.GroupBy("Parent");
	
	TheStructureOfTheSearch = New Structure;
	
	For Each GroupString In GroupsOfPeriods Do
		
		TheStructureOfTheSearch.Insert("Parent", GroupString.Parent);
		PeriodsStrings = PeriodsTable.FindRows(TheStructureOfTheSearch);
		
		If PeriodsStrings.Count() > 1 Then
			
			MessageText = NStr("vi = 'Sử dụng không hợp lý định kỳ khác nhau trong một mức độ phân nhánh';
								|ru = 'Недопустимо использовать разную периодичность внутри одного уровня иерархии';
								|en = 'Cannot use different frequency within one hierarchy level'; fa = 'Cannot use different frequency within one hierarchy level';
								|it = 'Non è possibile utilizzare una periodicità diversa all''interno del medesimo livello gerarchico';
								|pl = 'Niedopuszczalne jest użycie różnych okresowości wewnątrz jednego poziomu hierarchii';
								|tr = 'Aynı hiyerarşi seviyesi dahilinde farklı sıklıklarda kullanılmasına izin verilemez'");
			CommonClientServer.AddUserError(ErrorsMessages, "", MessageText, "");
			Return;
			
		EndIf;
			
	EndDo;
	
EndProcedure

Function ThereIsWeekInDecades(ArrayOfPeriods)
	
	For Cnt = 0 To ArrayOfPeriods.UBound() - 1 Do
		
		CurrentItem = ArrayOfPeriods[Cnt];
		NextItem = ArrayOfPeriods[Cnt + 1];
		
		If CurrentItem = Enums.Periodicity.Week
			And NextItem = Enums.Periodicity.TenDays Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Procedure CheckIfAllElementsAreMissing(Parameters, ErrorsMessages)
	
	If Parameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Report Then
		Return;
	EndIf;
	
	ItemsTree = Parameters.ItemTreeWithAdditionalItems;
	
	TheStructureOfTheSearch = New Structure("ItemKind", Enums.FinancialReportItemKinds.AllBudgetBalanceItems);
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	
	For Each FoundRow In FoundRows Do
		IncludedInDerivedIndicator = ValueIsFilled(FoundRow.Parent)
			And FoundRow.Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		If Not IncludedInDerivedIndicator Then
			
			ErrorText = NStr("vi = 'Đã tìm thấy phần tử không được phép ""Tất cả chỉ số"" để nhập';
							|ru = 'Обнаружен недоступный для ввода элемент ""Все показатели""';
							|en = 'Item ""All indicators"" that cannot be entered is found'; fa = 'Item ""All indicators"" that cannot be entered is found';
							|it = 'Rilevato elemento ""Tutti i parametri"" non disponibile per immissione';
							|pl = 'Wykryto niedostępny do wprowadzania element ""Wszystkie wskaźniki""';
							|tr = '""Tüm göstergeler"" öğesinin giriş için kullanılamayacağı tespit edildi'");
			CommonClientServer.AddUserError(ErrorsMessages,, ErrorText, "");
			Break;
			
		EndIf;
	EndDo;
	
	TheStructureOfTheSearch = New Structure("ItemKind", Enums.FinancialReportItemKinds.AllBudgetFlowItems);
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	
	For Each FoundRow In FoundRows Do
		IncludedInDerivedIndicator = ValueIsFilled(FoundRow.Parent)
			And FoundRow.Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		If Not IncludedInDerivedIndicator Then
			
			ErrorText = NStr("vi = 'Đã tìm thấy phần tử không hợp lệ ""Tất cả các dạng"" để nhập';
							|ru = 'Обнаружен недоступный для ввода элемент ""Все статьи""';
							|en = 'Item ""All items"" that cannot be entered is found'; fa = 'Item ""All items"" that cannot be entered is found';
							|it = 'Rilevato elemento ""Tutte le voci"" non disponibile per immissione';
							|pl = 'Wykryto niedostępny do wprowadzania element ""Wszystkie pozycje""';
							|tr = '""Tüm maddeler"" öğesinin giriş için kullanılamayacağı tespit edildi'");
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckForCycles(Parameters, ErrorsMessages)
	
	StructureOfReportDescription = Parameters.StructureOfReportDescription;
	
	CellStructure = StructureOfReportDescription.CellStructure.Copy();
	CellParameters = StructureOfReportDescription.CellParameters;
	
	CellStructure.Columns.Add("CalculationLevel", New TypeDescription("Number"));
	CellStructure.Indexes.Add("CalculationLevel, MainItem");
	CellStructure.Indexes.Add("String, Column, MainItem");
	
	StructureOfOrderCheck = New Structure("CalculationLevel, MainItem", 0, True);
	FoundRows = CellStructure.FindRows(StructureOfOrderCheck);
	CurrentLevel = 1;
	While FoundRows.Count() Do
		
		TotalRows = FoundRows.Count();
		LinesToLevelUp = New Array;
		
		For Each FoundRow In FoundRows Do
			
			If Not FoundRow.MainItem Then
				Continue; //operands are not involved in the calculation
			EndIf;
			
			CellRowParameters = CellParameters.Find(FoundRow.RowIndex, "RowIndex");
			
			If ValueIsFilled(CellRowParameters.Formula) Then
				
				OperandSearchStructure = New Structure("String, Column, MainItem",
					FoundRow.String,
					FoundRow.Column,
					False);
				
				OperandStrings = CellStructure.FindRows(OperandSearchStructure);
				
				DataForFormulaIsReady = True;
				For Each OperandString_ In OperandStrings Do
					CellRowParameters = CellParameters.Find(OperandString_.RowIndex, "RowIndex");
					If OperandString_.OperandType = Enums.FinancialReportItemKinds.TableCell Then
						CellSearchStructure = New Structure("String, Column, MainItem",
							CellRowParameters.OperandString, CellRowParameters.OperandColumn_,
							True);
						
						RefRow = CellStructure.FindRows(CellSearchStructure);
						If RefRow.Count() And RefRow[0].CalculationLevel = 0 Then
							DataForFormulaIsReady = False;
							Break;
						EndIf;
					EndIf;
				EndDo;
				
				If Not DataForFormulaIsReady Then
					Continue;
				EndIf;
					
			EndIf;
			
			LinesToLevelUp.Add(FoundRow);
			
		EndDo;
		
		For Each LevelUpString In LinesToLevelUp Do
			LevelUpString.CalculationLevel = CurrentLevel;
		EndDo;
		CurrentLevel = CurrentLevel + 1;
		
		FoundRows = CellStructure.FindRows(StructureOfOrderCheck);
		MoreLines = FoundRows.Count();
		If MoreLines = TotalRows Then
			
			ErrorText = NStr("vi = 'Tìm thấy tài liệu tham khảo tròn trong công thức';
							|ru = 'Обнаружены циклические ссылки в формулах';
							|en = 'Circular references are found in formulas'; fa = 'Circular references are found in formulas';
							|it = 'Riferimenti ciclici trovati nelle formule';
							|pl = 'W formułach wykryto odnośniki cykliczne';
							|tr = 'Formüllerde döngüsel bağlantılar tespit edildi'");
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			
			Return;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckForDataSources(Parameters, ErrorsMessages)
	
	StructureOfReportDescription = Parameters.StructureOfReportDescription;
	
	DataSources = StructureOfReportDescription.DataSources;
	If Not DataSources.Count() Then
		ErrorText = NStr("vi = 'Không có khoản mục ngân sách hoặc số liệu ngân sách nào được chọn trong cấu trúc loại ngân sách';
						|ru = 'Не выбраны статьи бюджетов или показатели бюджетов в структуре вида бюджета';
						|en = 'Budget flow items or budget balance items are not selected in the budget profile structure'; fa = 'Budget flow items or budget balance items are not selected in the budget profile structure';
						|it = 'Non sono selezionate le voci di budget o indicatori di budget nella struttura del tipo di budget';
						|pl = 'Nie wybrano pozycji budżetów lub wskaźników budżetów w strukturze rodzaju budżetu';
						|tr = 'Profilinin yapısındaki bütçe kalemleri veya bütçe dengesi kalemleri seçilmedi'");
		CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
	EndIf;
	
	If Parameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document Then
		ThereIsSourceDocument = False;
		For Each DataSource In DataSources Do
			If DataSource.Id = "Document" Then
				ThereIsSourceDocument = True;
				Break;
			EndIf;
		EndDo;
		If Not ThereIsSourceDocument Then
			ErrorText = NStr("vi = 'Các mục ngân sách phải được chọn để nhập dữ liệu';
							|ru = 'Для ввода данных должны быть выбраны статьи бюджета';
							|en = 'To enter data, select budget flow items'; fa = 'To enter data, select budget flow items';
							|it = 'Le voci del budget devono essere selezionate per l''immissione dei dati';
							|pl = 'Aby wprowadzić dane, należy wybrać pozycje budżetu';
							|tr = 'Verilerin girişleri için bütçe kalemleri seçilmeli'");
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckCorrectnessOfAnalystIndication(Parameters, ErrorsMessages)
	
	BudgetProfile = Parameters.BudgetProfile;
	
	ColumnStructureOfDataTable = Parameters.ColumnStructureOfDataTable;
	StructureOfReportDescription = Parameters.StructureOfReportDescription;
	
	CellStructure = StructureOfReportDescription.CellStructure.Copy();
	
	CellTable = New ValueTable;
	CellTable.Columns.Add("ItemIndicator",
		New TypeDescription("CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems"));
	CellTable.Columns.Add("DimensionKind", New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	
	DimensionCaps = Common.ObjectAttributeValue(BudgetProfile, "HeaderDimensions").Unload().UnloadColumn("DimensionKind");
	
	For Each Cell In CellStructure Do
		If Cell.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
			Continue;
		EndIf;
		DimensionKinds = New Array;
		For Each DimensionKind In ColumnStructureOfDataTable.DimensionKinds Do
			Name = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			If ValueIsFilled(Cell["Flag" + Name]) Then
				DimensionKinds.Add(DimensionKind);
			EndIf;
		EndDo;
		CommonClientServer.SupplementArray(DimensionKinds, DimensionCaps, True);
		If ValueIsFilled(Cell.BudgetFlowItem) Then
			For Each DimensionKind In DimensionKinds Do
				NewRow = CellTable.Add();
				NewRow.ItemIndicator = Cell.BudgetFlowItem;
				NewRow.DimensionKind = DimensionKind;
			EndDo;
		EndIf;
		If ValueIsFilled(Cell.BudgetBalanceItem) Then
			For Each DimensionKind In DimensionKinds Do
				NewRow = CellTable.Add();
				NewRow.ItemIndicator = Cell.BudgetBalanceItem;
				NewRow.DimensionKind = DimensionKind;
			EndDo;
		EndIf;
	EndDo;
	
	Query = New Query;
	Text = "SELECT DISTINCT
	|	Table_.ItemIndicator,
	|	Table_.DimensionKind
	|INTO CellTable
	|FROM
	|	&Table AS Table_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PRESENTATION(CellTable.ItemIndicator) AS ItemIndicator,
	|	PRESENTATION(CellTable.DimensionKind) AS DimensionKind
	|FROM
	|	CellTable AS CellTable
	|		INNER JOIN Catalog.BudgetFlowItems AS Catalog
	|		ON CellTable.ItemIndicator = Catalog.Ref
	|WHERE
	|	&TextOfArticlesConditionsAnalyst
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PRESENTATION(CellTable.ItemIndicator) AS ItemIndicator,
	|	PRESENTATION(CellTable.DimensionKind) AS DimensionKind
	|FROM
	|	CellTable AS CellTable
	|		INNER JOIN Catalog.BudgetBalanceItems AS Catalog
	|		ON CellTable.ItemIndicator = Catalog.Ref
	|WHERE
	|	&TextOfIndicatorsAnalystConditions";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TextOfArticlesConditionsAnalyst = "";
	TextOfIndicatorsAnalystConditions = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfArticlesConditionsAnalyst = TextOfArticlesConditionsAnalyst
			+ ?(TextOfArticlesConditionsAnalyst = "", "", Chars.LF + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CellTable.DimensionKind <> Catalog.DimensionKind%1",
				DimensionNumber);
		
		TextOfIndicatorsAnalystConditions = TextOfIndicatorsAnalystConditions
			+ ?(TextOfIndicatorsAnalystConditions = "", "", Chars.LF + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CellTable.DimensionKind <> Catalog.DimensionKind%1",
				DimensionNumber);
	EndDo;
	Text = StrReplace(Text, "&TextOfArticlesConditionsAnalyst", TextOfArticlesConditionsAnalyst);
	Text = StrReplace(Text, "&TextOfIndicatorsAnalystConditions", TextOfIndicatorsAnalystConditions);
	Query.Text = Text;
	
	Query.SetParameter("Table", CellTable);
	ResultsArray = Query.ExecuteBatch();
	
	ArticleErrors = ResultsArray[1].Unload();
	ErrorsByIndicators = ResultsArray[2].Unload();
	Structure = New Structure("ARTICLES__, Indicators", ArticleErrors, ErrorsByIndicators);
	
	For Each KeysAndValue In Structure Do
		For Each ErrorString In KeysAndValue.Value Do
			If KeysAndValue.Key = "ARTICLES__" Then
				ErrorText = NStr("vi = 'Đối với dạng ""%1"" không có chỉ tiêu cho dạng chỉ số ""%2""';
								|ru = 'Для статьи ""%1"" указана недоступная на статье аналитика ""%2""';
								|en = 'For the item ""%1"", dimension ""%2"" (not available for this item) is specified'; fa = 'For the item ""%1"", dimension ""%2"" (not available for this item) is specified';
								|it = 'Per la voce ""%1"" è stata indicata l''analitica ""%2"" non disponibile per questa voce';
								|pl = 'Dla pozycji ""%1"" podano niedostępną dla pozycji analitykę""%2""';
								|tr = '""%1"" maddesi için ""%2"" boyut maddesi kullanılamıyor'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorText,
					ErrorString.ItemIndicator,
					ErrorString.DimensionKind);
			Else
				ErrorText = NStr("vi = 'Đối với chỉ tiêu ""%1"" không có chỉ tiêu cho chỉ số ""%2""';
								|ru = 'Для показателя ""%1"" указана недоступная на показателе аналитика ""%2""';
								|en = 'For the indicator ""%1"", dimension ""%2"" (not available for this indicator) is specified'; fa = 'For the indicator ""%1"", dimension ""%2"" (not available for this indicator) is specified';
								|it = 'Per l''indicatore ""%1"" è stata indicata l''analitica ""%2"" non disponibile per questo indicatore';
								|pl = 'Dla wskaźnika ""%1"" podano niedostępną dla wskaźnika analitykę ""%2""';
								|tr = '""%1"" göstergesi için ""%2"" boyut göstergesinde kullanılamıyor'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorText,
					ErrorString.ItemIndicator,
					ErrorString.DimensionKind);
			EndIf;
			
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "")
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckCurrencyComplianceWithArticles(Parameters, ErrorsMessages)
	
	ColumnStructureOfDataTable = Parameters.ColumnStructureOfDataTable;
	StructureOfReportDescription = Parameters.StructureOfReportDescription;

	If ColumnStructureOfDataTable.Dimensions.Find("Currency") = Undefined Then
		Return;
	EndIf;
	
	CellStructure = StructureOfReportDescription.CellStructure.Copy();
	
	CellTable = New ValueTable;
	CellTable.Columns.Add("ItemIndicator",
		New TypeDescription("CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems"));
	
	Cells = CellStructure.FindRows(New Structure("MainItem", True));
	For Each Cell In Cells Do
		If ValueIsFilled(Cell.BudgetFlowItem)
			And ValueIsFilled(Cell.Currency) Then
			NewRow = CellTable.Add();
			NewRow.ItemIndicator = Cell.BudgetFlowItem;
		EndIf;
		If ValueIsFilled(Cell.BudgetBalanceItem)
			And ValueIsFilled(Cell.Currency) Then
			NewRow = CellTable.Add();
			NewRow.ItemIndicator = Cell.BudgetBalanceItem;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Table_.ItemIndicator
	|INTO CellTable
	|FROM
	|	&Table AS Table_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellTable.ItemIndicator
	|FROM
	|	CellTable AS CellTable
	|		INNER JOIN Catalog.BudgetFlowItems AS Catalog
	|		ON CellTable.ItemIndicator = Catalog.Ref
	|			AND (NOT Catalog.RecordByCurrency)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellTable.ItemIndicator
	|FROM
	|	CellTable AS CellTable
	|		INNER JOIN Catalog.BudgetBalanceItems AS Catalog
	|		ON CellTable.ItemIndicator = Catalog.Ref
	|			AND (NOT Catalog.RecordByCurrency)";
	
	Query.SetParameter("Table", CellTable);
	ResultsArray = Query.ExecuteBatch();
	
	ArticleErrors = ResultsArray[1].Unload();
	ErrorsByIndicators = ResultsArray[2].Unload();
	Structure = New Structure("ARTICLES__, Indicators", ArticleErrors, ErrorsByIndicators);
	
	For Each KeysAndValue In Structure Do
		For Each ErrorString In KeysAndValue.Value Do
			If KeysAndValue.Key = "ARTICLES__" Then
				ErrorText = NStr("vi = 'Đối với dạng ""%1"" không có hạch toán theo tiền tệ';
								|ru = 'Для статьи ""%1"" недоступен учет по валюте';
								|en = 'Accounting by currency is not available for item ""%1""'; fa = 'Accounting by currency is not available for item ""%1""';
								|it = 'Per la voce ""%1"" non è disponibile la contabilità in valuta';
								|pl = 'Dla pozycji ""%1"" ewidencja walutowa nie jest dostępna';
								|tr = 'Para birimine göre ""%1"" maddesi için hesap yapılamıyor'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					ErrorString.ItemIndicator);
			Else
				ErrorText = NStr("vi = 'Đối với chỉ tiêu ""%1"" không có hạch toán theo tiền tệ';
								|ru = 'Для показателя ""%1"" недоступен учет по валюте';
								|en = 'Accounting by currency is unavailable for indicator ""%1""'; fa = 'Accounting by currency is unavailable for indicator ""%1""';
								|it = 'Per l''indicatore ""%1"" non è disponibile la contabilità in valuta';
								|pl = 'Dla wskaźnika ""%1"" ewidencja walutowa nie jest dostępna';
								|tr = 'Para birimine göre ""%1"" göstergesi için hesap yapılamıyor'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					ErrorString.ItemIndicator);
			EndIf;
			
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "")
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckCorrectnessOfMeasurementIndication(Parameters, ErrorsMessages)
	
	If Parameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document Then
		ScriptAvailable = False;
		AvailableDivision = False;
		OrganizationAvailable = False;
	Else
		ScriptAvailable = True;
		ModelSettings = Common.ObjectAttributesValues(Parameters.Attributes.Owner,
			"BudgetsByBusinessUnits, BudgetsByCompanies");
		AvailableDivision = ModelSettings.BudgetsByBusinessUnits;
		OrganizationAvailable = ModelSettings.BudgetsByCompanies;
	EndIf;
	
	ColumnStructureOfDataTable = Parameters.ColumnStructureOfDataTable;
	ArrayOfUnavailable = New Array;
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		
		If Dimension = "Scenario" And Not ScriptAvailable Then
			ArrayOfUnavailable.Add("Scenario");
		EndIf;
		If Dimension = "Organization" And Not OrganizationAvailable Then
			ArrayOfUnavailable.Add("Organization");
		EndIf;
		If Dimension = "Department" And Not AvailableDivision Then
			ArrayOfUnavailable.Add("Department");
		EndIf;
		
		For Each ArrayElement In ArrayOfUnavailable Do
			MessageText = NStr("vi = 'Đo lường báo cáo ""%1"" không khả dụng cho dạng ngân sách hiện tại';
								|ru = 'Измерение отчета ""%1"" недоступно для текущего вида бюджета';
								|en = 'The ""%1"" report dimension is not available for the current budget profile'; fa = 'The ""%1"" report dimension is not available for the current budget profile';
								|it = 'La misurazione del report ""%1"" non è disponibile per il tipo di budget corrente';
								|pl = 'Wymiar raportu ""%1"" nie jest dostępny dla bieżącego rodzaju budżetu';
								|tr = 'Mevcut bütçe profili için ""%1"" raporunun ölçümü yapılamıyor'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
				ArrayElement);
			CommonClientServer.AddUserError(ErrorsMessages, "", MessageText, "");
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CheckForColumnRows(Parameters, ErrorsMessages)
	
	ItemsTree = Parameters.ItemTreeWithAdditionalItems;
	
	TheStructureOfTheSearch = New Structure("ItemKind", Enums.FinancialReportItemKinds.Rows);
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	
	For Each FoundRow In FoundRows Do
		
		If Not FoundRow.Rows.Count() Then
			
			ErrorText = NStr("vi = 'Các hàng của bảng không được để trống';
							|ru = 'Строки таблицы не могут быть пустыми';
							|en = 'Table rows cannot be empty'; fa = 'Table rows cannot be empty';
							|it = 'Le righe della tabella non possono essere vuote';
							|pl = 'Wiersze tabeli nie mogą być puste';
							|tr = 'Tablo satırları boş kalamaz'");
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			Break;
			
		EndIf;
		
	EndDo;
	
	TheStructureOfTheSearch = New Structure("ItemKind", Enums.FinancialReportItemKinds.Columns);
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	
	For Each FoundRow In FoundRows Do
		
		If Not FoundRow.Rows.Count() Then
			
			ErrorText = NStr("vi = 'Cột bảng không thể để trống';
							|ru = 'Колонки таблицы не могут быть пустыми';
							|en = 'Table columns cannot be empty'; fa = 'Table columns cannot be empty';
							|it = 'Le colonne della tabella non possono essere vuote';
							|pl = 'Kolumny tabeli nie mogą być puste';
							|tr = 'Sütunlar boş kalamaz'");
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ElementsOfDirectionReportView(TreeRows, ItemsList = Undefined)
	
	If ItemsList = Undefined Then
		ItemsList = New Array;
	EndIf;
	
	For Each TreeRow In TreeRows.Rows Do
		ItemsList.Add(TreeRow);
		ElementsOfDirectionReportView(TreeRow, ItemsList);
	EndDo;
	
	Return ItemsList;
	
EndFunction

Function ConvertItemsToComparisonTable(TableItems, CacheOfAdditionalBankingDetails)
	
	ItemsKinds = Enums.FinancialReportItemKinds;
	DimensionsTypes = Enums.TypesOfBudgetReportDimensions;
	
	ComparisonTable = New ValueTable;
	ComparisonTable.Columns.Add("ObjectOfComparison");
	For Each RowColumn In TableItems Do
		
		ThisIsElementThatNeedsToBeChecked = 
			RowColumn.ItemKind = ItemsKinds.Dimension
			Or RowColumn.ItemKind = ItemsKinds.AllBudgetBalanceItems
			Or RowColumn.ItemKind = ItemsKinds.AllBudgetFlowItems;
		
		If Not ThisIsElementThatNeedsToBeChecked Then
			Continue;
		EndIf;
		
		If RowColumn.ItemKind = ItemsKinds.Dimension Then
			
			DimensionType = FinancialReportingServer.ValueOfAdditionalProps(
				RowColumn.ReportItem,
				"DimensionType",
				CacheOfAdditionalBankingDetails);
			
			If DimensionType = DimensionsTypes.Dimension Then
				
				ObjectOfComparison = FinancialReportingServer.ValueOfAdditionalProps(
					RowColumn.ReportItem,
					"DimensionKind",
					CacheOfAdditionalBankingDetails);
				
			ElsIf DimensionType = DimensionsTypes.Currency Then
				
				ObjectOfComparison = "Currency";
				
			ElsIf DimensionType = DimensionsTypes.RegisterDimension Then
				
				ObjectOfComparison = FinancialReportingServer.ValueOfAdditionalProps(
					RowColumn.ReportItem,
					"DimensionName",
					CacheOfAdditionalBankingDetails);
				
			ElsIf DimensionType = DimensionsTypes.Organization Then
				
				ObjectOfComparison = "Organization";
				
			ElsIf DimensionType = DimensionsTypes.Department Then
				
				ObjectOfComparison = "Department";
				
			ElsIf DimensionType = DimensionsTypes.Scenario Then
				
				ObjectOfComparison = "Scenario";
				
			ElsIf DimensionType = DimensionsTypes.FixedDimension Then
				
				ObjectOfComparison = FinancialReportingServer.ValueOfAdditionalProps(
					RowColumn.ReportItem,
					"DimensionKind",
					CacheOfAdditionalBankingDetails);
				
			Else
				
				Continue;
				
			EndIf;
			
			NewRow = ComparisonTable.Add();
			NewRow.ObjectOfComparison = ObjectOfComparison;
			
		Else
			
			NewRow = ComparisonTable.Add();
			NewRow.ObjectOfComparison = RowColumn.ItemKind;
			
		EndIf;
		
	EndDo;
	
	ComparisonTable.GroupBy("ObjectOfComparison");
	
	Return ComparisonTable;
	
EndFunction

Procedure CheckIntersectionOfAnalyticalSections(Parameters, ErrorsMessages)
	
	CacheOfAdditionalBankingDetails = FinancialReportingServer.CacheAdditionalDetails(Parameters.BudgetProfile);
	Tables = BudgetReportingCacheCalculationServer.GetBudgetViewTables(Parameters.BudgetProfile);
	ItemsTree = Parameters.ItemTreeWithoutAdditionalItems;
	
	For Each Table In Tables Do
		
		RootOfTable = ItemsTree.Rows.Find(Table.Ref);
		
		RowElements = ElementsOfDirectionReportView(
			RootOfTable.Rows.Find(Enums.FinancialReportItemKinds.Rows, "ItemKind"));
		RowElements = ConvertItemsToComparisonTable(RowElements, CacheOfAdditionalBankingDetails);
		
		ColumnElements_ = ElementsOfDirectionReportView(
			RootOfTable.Rows.Find(Enums.FinancialReportItemKinds.Columns, "ItemKind"));
		ColumnElements_ = ConvertItemsToComparisonTable(ColumnElements_, CacheOfAdditionalBankingDetails);
		
		CommonClientServer.SupplementTable(ColumnElements_, RowElements);
		RowElements.Columns.Add("Flag");
		RowElements.FillValues(1, "Flag");
		RowElements.GroupBy("ObjectOfComparison", "Flag");
		
		RowElements.Sort("Flag DESC");
		While RowElements.Count() And
			RowElements[0].Flag > 1 Do
			
			ErrorText = NStr("vi = 'Lặp lại các phần tử có dạng ""%1"" cùng lúc ở cả hàng và cột';
							|ru = 'Недопустим повтор элементов вида ""%1"" одновременно и в строках и в колонках';
							|en = 'Cannot repeat items of the ""%1"" kind both in lines and columns'; fa = 'Cannot repeat items of the ""%1"" kind both in lines and columns';
							|it = 'Non è ammissibile la ripetizione degli elementi del tipo ""%1"" simultaneamente nelle righe e colonne';
							|pl = 'Powtórzenie elementów rodzaju ""%1"" jednocześnie w wierszach i w kolumnach jest niedopuszczalne';
							|tr = '""%1"" türündeki öğelerin hem satırlarda hem de sütunlarda eş zamanlı tekrarlanmasına izin verilemez'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				RowElements[0].ObjectOfComparison);
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			
			RowElements.Delete(0);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CheckIfThereAreNoInputElementsOnGroupingLevels(Parameters, ErrorsMessages)
	
	If Parameters.GenerationMode <> Enums.ModesOfBudgetReportGeneration.Document Then
		Return;
	EndIf;
	
	ItemsTree = Parameters.ItemTreeWithoutAdditionalItems;
	StructureOfReportDescription = Parameters.StructureOfReportDescription;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("MainItem", True);
	TheStructureOfTheSearch.Insert("ItemKind", Enums.FinancialReportItemKinds.BudgetFlowItem);
	InputCells = StructureOfReportDescription.CellStructure.Copy(TheStructureOfTheSearch);
	ForDeletion = New Array;
	For Each TableRow In InputCells Do
		If Not StructureOfReportDescription.CellParameters.Find(TableRow.RowIndex, "RowIndex").TableComplex_ Then
			ForDeletion.Add(TableRow);
		EndIf;
	EndDo;
	
	For Each RowToDelete In ForDeletion Do
		InputCells.Delete(RowToDelete);
	EndDo;
	
	For Each ReportCell In InputCells Do
		Search = New Structure("ReportItem", ReportCell.String);
		FoundRows = ItemsTree.Rows.FindRows(Search, True);
		
		For Each BudgetFlowOrBalanceItem In FoundRows Do
			If BudgetFlowOrBalanceItem.Rows.Count() Then 
				Array = New Array;
				Array.Add(ReportCell.String);
				Array.Add(ReportCell.Column);
				Attributes = Common.ObjectsAttributesValues(Array, "NameForPrinting");
				ErrorText = NStr("vi = 'Lỗi trong ô [%1; %2]: cấm nhập ở mức độ gom nhóm';
								|ru = 'Ошибка в ячейке [%1; %2]: запрещен ввод на уровне группировок';
								|en = 'Error in cell [%1; %2]: input on the grouping level is prohibited'; fa = 'Error in cell [%1; %2]: input on the grouping level is prohibited';
								|it = 'Errore nella cella [%1; %2]: è vietata immissione a livello di raggruppamenti';
								|pl = 'Błąd w komórce [%1; %2]: wprowadzanie na poziomie grup jest zabronione';
								|tr = '[%1; %2] hücresinde hata: gruplama seviyelerine giriş yasak'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
					Attributes[ReportCell.String].NameForPrinting,
					Attributes[ReportCell.Column].NameForPrinting);
				CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CheckFrequencyOfBudgetViewElements(Parameters, ErrorsMessages)
	
	BudgetFrequency = Parameters.Attributes.Periodicity;
	ColumnStructure1 = Parameters.ColumnStructureOfDataTable;
	Order = Enums.Periodicity.OrderedPeriodicities();
	Cur_Index = Order.Find(BudgetFrequency);
	
	For Each Periodicity In ColumnStructure1.Periodicity_ Do
		ReportIndex = Order.Find(Periodicity);
		If ReportIndex > Cur_Index Then
			ErrorText = NStr("vi = 'Tần suất được chọn trong các nhóm không thể nhiều hơn tần suất của loại ngân sách (%1)';
							|ru = 'Периодичность, выбираемая в группировках, не может быть больше, чем периодичность самого вида бюджета (%1)';
							|en = 'Frequency selected in groupings cannot be greater than the frequency of the budget profile (%1)'; fa = 'Frequency selected in groupings cannot be greater than the frequency of the budget profile (%1)';
							|it = 'La frequenza selezionata nei raggruppamenti non può essere superiore alla frequenza del tipo stesso di budget (%1)';
							|pl = 'Okresowość, wybierana w grupowaniu nie może być większa od okresowości samego rodzaju budżetu (%1)';
							|tr = 'Sıklık ve gruplamalardaki seçili kısımlar, bütçe profilinin kendi sıklığından daha fazla olamaz (%1)'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
				Lower(BudgetFrequency));
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			Break;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckIntersectionOfAnalyticsInHeaderAndStructure(Parameters, ErrorsMessages)
	
	BudgetProfile = Parameters.BudgetProfile;
	ColumnStructureOfDataTable = Parameters.ColumnStructureOfDataTable;
	DimensionCaps = Common.ObjectAttributeValue(BudgetProfile, "HeaderDimensions").Unload().UnloadColumn("DimensionKind");
	CopyOfHeaderAnalytics = Common.CopyRecursive(DimensionCaps);
	ResultOfSubtraction = CommonClientServer.ArraysDifference(DimensionCaps, ColumnStructureOfDataTable.DimensionKinds);
	GeneralAnalytics = CommonClientServer.ArraysDifference(CopyOfHeaderAnalytics, ResultOfSubtraction);
	
	If GeneralAnalytics.Count() Then
		DimensionPresentation = StrConcat(GeneralAnalytics, ", ");
		ErrorText = NStr("vi = 'Các loại chỉ số ''%1'' không thể được chọn trong cấu trúc tiêu đề và ngân sách';
						|ru = 'Виды аналитик ""%1"" не могут быть выбраны и в шапке и в структуре бюджета';
						|en = 'The ""%1"" dimension kinds cannot be selected both in the header and in the budget structure'; fa = 'The ""%1"" dimension kinds cannot be selected both in the header and in the budget structure';
						|it = 'I tipi di analisi ""%1"" non possono essere selezionati sia nell''intestazione che nella struttura del budget';
						|pl = 'Rodzaje analityk ""%1"" nie mogą być wybrane i w nagłówku i w strukturze budżetu';
						|tr = '""%1"" boyut türleri üst bilgide ve bütçe yapısında seçilemez'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, DimensionPresentation);
		CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
	EndIf;
	
EndProcedure

Procedure CheckForIdenticalMeasurementsWithinSameBranch(Parameters, ErrorsMessages)
	
	ArrayOfUnrulyDimensions = New Array;
	ArrayOfUnrulyDimensions.Add(Enums.TypesOfBudgetReportDimensions.Currency);
	ArrayOfUnrulyDimensions.Add(Enums.TypesOfBudgetReportDimensions.Organization);
	ArrayOfUnrulyDimensions.Add(Enums.TypesOfBudgetReportDimensions.Department);
	ArrayOfUnrulyDimensions.Add(Enums.TypesOfBudgetReportDimensions.Scenario);
	ArrayOfUnrulyDimensions.Add(Enums.TypesOfBudgetReportDimensions.FixedDimension);
	ArrayOfUnrulyDimensions.Add(Enums.TypesOfBudgetReportDimensions.Dimension);
	
	ItemsTree = Parameters.ItemTreeWithoutAdditionalItems;
	Search = New Structure("ItemKind", Enums.FinancialReportItemKinds.Dimension);
	Dimensions = ItemsTree.Rows.FindRows(Search, True);
	CacheOfAdditionalBankingDetails = FinancialReportingServer.CacheAdditionalDetails(Parameters.BudgetProfile);
	
	For Each Dimension In Dimensions Do
		
		DimensionType = FinancialReportingServer.ValueOfAdditionalProps(Dimension.ReportItem,
			"DimensionType", CacheOfAdditionalBankingDetails);
		If ArrayOfUnrulyDimensions.Find(DimensionType) = Undefined Then
			Continue;
		EndIf;
		
		IntersectingDimensionTypes = New Array;
		IntersectingDimensionTypes.Add(DimensionType);
		If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
			IntersectingDimensionTypes.Add(Enums.TypesOfBudgetReportDimensions.FixedDimension);
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
			IntersectingDimensionTypes.Add(Enums.TypesOfBudgetReportDimensions.Dimension);
		EndIf;
		HasError = False;
		
		CurrentRow = Dimension.Parent;
		While CurrentRow <> Undefined Do
			If CurrentRow.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
				ParentDimensionType = FinancialReportingServer.ValueOfAdditionalProps(
					CurrentRow.ReportItem, "DimensionType", CacheOfAdditionalBankingDetails);
				If IntersectingDimensionTypes.Find(ParentDimensionType) <> Undefined Then
					If ParentDimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension
					 Or ParentDimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
						DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(
							Dimension.ReportItem, "DimensionKind", CacheOfAdditionalBankingDetails);
						ParentAnalyticsView = FinancialReportingServer.ValueOfAdditionalProps(
							CurrentRow.ReportItem, "DimensionKind", CacheOfAdditionalBankingDetails);
						If DimensionKind = ParentAnalyticsView Then
							HasError = True;
							Break;
						EndIf;
					Else
						HasError = True;
						Break;
					EndIf;
				EndIf;
			EndIf;
			CurrentRow = CurrentRow.Parent;
		EndDo;
		
		If HasError Then
			ErrorText = NStr("vi = 'Phần tử báo cáo ""%1"" không thể phụ thuộc vào phần tử ""%2""';
							|ru = 'Элемент отчета ""%1"" не может быть подчинен элементу ""%2""';
							|en = 'Report item ""%1"" cannot be subordinate to item ""%2""'; fa = 'Report item ""%1"" cannot be subordinate to item ""%2""';
							|it = 'Elemento del report ""%1"" non può essere subordinato all''elemento ""%2""';
							|pl = 'Element raportu ""%1"" nie może być podporządkowany elementowi ""%2""';
							|tr = '""%1"" rapor öğesi ""%2"" öğesinin alt öğesi olamaz'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				Dimension.NameForPrinting,
				CurrentRow.NameForPrinting);
			CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckingForIntersectionOfMeasurementsInSourceDoppelgangersAndColumns(Parameters, ErrorsMessages)
	
	If Parameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document Then
		Return;
	EndIf;
	
	DimensionsAndPropsNames = New Map; // Dimension name - The name of the props containing the attribute of the filter by dimension.
	ColumnStructure1 = Parameters.ColumnStructureOfDataTable;
	If ColumnStructure1.Dimensions.Find("Scenario") <> Undefined Then
		DimensionsAndPropsNames.Insert("Scenario", "UseFilterScenario");
	EndIf;
	If ColumnStructure1.Dimensions.Find("Organization") <> Undefined Then
		DimensionsAndPropsNames.Insert("Organization", "UseFilterByCompany");
	EndIf;
	If ColumnStructure1.Dimensions.Find("Department") <> Undefined Then
		DimensionsAndPropsNames.Insert("Department", "UseFilterByDepartment");
	EndIf;
	If DimensionsAndPropsNames.Count() = 0 Then
		Return;
	EndIf;
	
	CacheOfAdditionalBankingDetails = FinancialReportingServer.CacheAdditionalDetails(Parameters.BudgetProfile);
	AttributeCache = BudgetReportingCacheCalculationServer.CacheOfDetailsForBudgetViewElements(Parameters.BudgetProfile);
	
	CacheStructure = New Structure;
	CacheStructure.Insert("CacheOfAdditionalBankingDetails", CacheOfAdditionalBankingDetails);
	CacheStructure.Insert("AttributeCache", AttributeCache);
	
	BudgetItemTree = Parameters.ItemTreeWithAdditionalItems;
	
	ResourceStrings = New Array;
	ItemsKinds = Enums.FinancialReportItemKinds.TypesOfDataSourceElements();
	For Each ItemKind In ItemsKinds Do
		
		PickedRows = BudgetItemTree.Rows.FindRows(New Structure("ItemKind", ItemKind), True);
		CommonClientServer.SupplementArray(ResourceStrings, PickedRows);
	
	EndDo;
	
	For Each ResourceString In ResourceStrings Do
		
		FilterAvailabilityParameters = Undefined;
		
		For Each DimensionNameAndPropsName In DimensionsAndPropsNames Do
			
			DimensionName = DimensionNameAndPropsName.Key;
			AttributeName = DimensionNameAndPropsName.Value;
			
			ThereIsDimensionInDOPSelection = FinancialReportingServer.ValueOfAdditionalProps(
				ResourceString.ReportItem, AttributeName, CacheOfAdditionalBankingDetails); // Boolean or number.
			
			If ThereIsDimensionInDOPSelection = Undefined
				Or Not ThereIsDimensionInDOPSelection Then
				Continue;
			EndIf;
			
			If FilterAvailabilityParameters = Undefined Then
				FilterAvailabilityParameters = BudgetReportingCacheCalculationServer.FilterAvailabilityParameters(ResourceString,, CacheStructure);
			EndIf;
			
			HasError = Not FilterAvailabilityParameters[DimensionName];
			If HasError Then
				If ResourceString.Parent <> Undefined
					And ResourceString.Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
					ErrorText = NStr("vi = 'Toán tử ""%1"" trong chỉ tiêu tùy ý ""%2"" chứa một bộ lọc đơn vị ""%3"" trong một bộ lọc bổ sung và trong cấu trúc ngân sách.';
									|ru = 'Оператор ""%1"" в производном показателе ""%2"" содержит отбор по измерению ""%3"" в дополнительном отборе и в структуре бюджета.';
									|en = 'The operator ""%1"" in derived item ""%2"" contains a filter by dimension ""%3"" in additional filter and budget structure.'; fa = 'The operator ""%1"" in derived item ""%2"" contains a filter by dimension ""%3"" in additional filter and budget structure.';
									|it = 'L''operatore ""%1"" nell''indicatore derivato ""%2"" contiene il filtro per dimensione ""%3"" nel filtro aggiuntivo e nella struttura del bilancio.';
									|pl = 'Operator ""%1"" we wskaźniku pochodnym ""%2"" zawiera filtr wg pomiaru ""%3"" w filtrze dodatkowym i w strukturze budżetu.';
									|tr = '""%1"" operatörü ""%2"" türetilmiş göstergesinde ""%3"" ölçümüne göre ve bütçe yapısında ek filtre içerir.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
						ResourceString.NameForPrinting,
						ResourceString.Parent.NameForPrinting,
						BudgetReportingClientServer.PresentationOfBudgetingDimension(DimensionName));
				Else
					ErrorText = NStr("vi = 'Mục báo cáo ""%1"" chứa bộ lọc đơn vị ""%2"" trong một bộ lọc bổ sung và trong cấu trúc ngân sách.';
									|ru = 'Элемент отчета ""%1"" содержит отбор по измерению ""%2"" в дополнительном отборе и в структуре бюджета.';
									|en = 'The ""%1"" report element contains filter by ""%2"" dimension in additional filter and in budget structure.'; fa = 'The ""%1"" report element contains filter by ""%2"" dimension in additional filter and in budget structure.';
									|it = 'L''elemento di calcolo ""%1"" contiene il filtro per dimensione ""%2"" nel filtro aggiuntio e nella struttura del bilancio.';
									|pl = 'Element raportu ""%1"" zawiera filtr dla wymiaru ""%2"" w filtrze dodatkowym i w strukturze budżetu.';
									|tr = '""%1"" rapor öğesi ""%2"" ölçümüne göre ve bütçe yapısında ek filtre içerir.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
						ResourceString.NameForPrinting,
						BudgetReportingClientServer.PresentationOfBudgetingDimension(DimensionName));
				EndIf;
					
				CommonClientServer.AddUserError(ErrorsMessages, "", ErrorText, "");
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckSameTypesOfAnalyticsInBudgetDimensions(Parameters)
	
	If Parameters.Attributes.MainInputMethod <> Enums.BudgetEditingMethods.InList Then
		Return;
	EndIf;
	
	HasError = False;
	
	BudgetViewParameters = Parameters.BudgetViewParameters;
	ParametersList = BudgetViewParameters.InputListDescriptionStructure;
	
	ItemArray = New Array;
	For Each DescriptionValue In ParametersList Do
		ItemArray.Add(DescriptionValue.Value);
	EndDo;
	
	For Cnt = 1 To ItemArray.UBound() Do
		If ItemArray[Cnt] = Undefined
			Or ItemArray[Cnt-1] = Undefined Then
			HasError = True;
		EndIf;
		Value1 = StrConcat(ItemArray[Cnt].Dimensions, ",");
		Value2 = StrConcat(ItemArray[Cnt-1].Dimensions, ",");
		If Value1 <> Value2 Then
			HasError = True;
		EndIf;
		If ItemArray[Cnt].Property("BudgetFlowItems") Then
			For Each KeyAndValue In ItemArray[Cnt].BudgetFlowItems Do
				If ItemArray[Cnt-1].BudgetFlowItems[KeyAndValue.Key] = Undefined
					Or ItemArray[Cnt-1].BudgetFlowItems[KeyAndValue.Key].BudgetFlowItem <> KeyAndValue.Value.BudgetFlowItem
					Or ItemArray[Cnt-1].BudgetFlowItems[KeyAndValue.Key].IndicatorName <> KeyAndValue.Value.IndicatorName Then
					HasError = True;
				EndIf;
			EndDo;
		EndIf;
		If HasError Then
			Break;
		EndIf;
	EndDo;
	
	If HasError	Then
		ErrorText = NStr("vi = 'Trong các dòng đã tìm thấy các chỉ số khác nhau, hoặc trong các dòng đã cài đặt các dạng và chỉ tiêu khác nhau. Khuyến cáo nên cài đặt các chỉ số, dạng và chỉ tiêu giống nhau cho từng dòng.
			|Việc chỉnh sửa ngân sách sẽ tiện lợi hơn rất nhiều.';
			|ru = 'В строках обнаружены разнородные аналитики, либо для разных строк настроен разный состав статей и показателей. 
			|Рекомендуется настраивать одинаковые аналитики с одинаковым составом статей и показателей по строкам. Редактировать такие бюджеты будет удобнее.';
			|en = 'Heterogeneous dimensions are found in the lines or different content of items and indicators is set up for different lines.
			|It is recommended that you set up similar dimensions with similar content of items and indicators by lines. It will be more convenient to edit such budgets.'; fa = 'Heterogeneous dimensions are found in the lines or different content of items and indicators is set up for different lines.
			|It is recommended that you set up similar dimensions with similar content of items and indicators by lines. It will be more convenient to edit such budgets.';
			|it = 'Nelle righe sono state trovate le analisi diverse oppure è stata configurata una composizione di voci e parametri diversa per righe diverse. 
			|Si consiglia di configurare la stessa analisi con la stessa composizione di voci e parametri nelle righe. Modificare tali budget sarà più comodo.';
			|pl = 'W wierszach wykryto różnorodne analityki lub dla różnych wierszy ustawiono różny skład pozycji i wskaźników. 
			|Zalecane jest ustawienie jednakowych analityk z takim samym składem pozycji i wskaźników w wierszach. Edycja takich budżetów będzie wygodniejsza.';
			|tr = 'Satırlarda farklı boyutlar tespit edildi veya farklı satırlarda farklı satır öğeleri ve göstergeler ayarlı. 
			|Aynı boyutun özdeş madde ve satıra göre gösterge ile kurulması önerilmektedir. Bu tür bütçelerin düzenlenmeleri elverişli olacak.'");
		Common.MessageToUser(ErrorText);
	EndIf;
		
EndProcedure

Procedure CheckDuplicatesOfLinesOfBudgetItemsByGroups(Parameters, ErrorsMessages)
	
	ItemsTree = Parameters.ItemTreeWithoutAdditionalItems;
	ColumnStructureOfDataTable = Parameters.ColumnStructureOfDataTable;
	StructureOfReportDescription = Parameters.StructureOfReportDescription;

	GroupSearchStructure = New Structure("MainItem, ItemKind", True,
		Enums.FinancialReportItemKinds.Group);
	GroupCellStructure = StructureOfReportDescription.CellStructure.Copy(GroupSearchStructure);

	TheStructureOfTheSearch = New Structure("ItemKind", Enums.FinancialReportItemKinds.BudgetFlowItem);

	CheckResult = New ValueTable;

	CheckResult.Columns.Add("Group", New TypeDescription("CatalogRef.FinancialReportItems"));
	CheckResult.Columns.Add("GroupDescription", New TypeDescription("String"));
	CheckResult.Columns.Add("BudgetFlowItem", New TypeDescription("CatalogRef.BudgetFlowItems"));

	ArrayOfNamesOfTypesOfAnalytics = New Array;
	For Each DimensionKind In ColumnStructureOfDataTable.DimensionKinds Do
		NameOfAnalyticsType = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		ArrayOfNamesOfTypesOfAnalytics.Add(NameOfAnalyticsType);
		CheckResult.Columns.Add(NameOfAnalyticsType, DimensionKind.ValueType);
	EndDo;
	NamesOfTypesOfAnalytics = StrConcat(ArrayOfNamesOfTypesOfAnalytics, ", ");

	ProcessedReportElements = New Array;

	For Each RowCellGroup In GroupCellStructure Do
		If Not ValueIsFilled(RowCellGroup.BudgetFlowItem) Then
			Continue;
		EndIf;
		If ProcessedReportElements.Find(RowCellGroup.String) = Undefined Then
			TheStructureOfTheSearch.Insert("ReportItem", RowCellGroup.String);
			TreeRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
			For Each TreeRow In TreeRows Do
				If TreeRow.Parent.ItemKind = Enums.FinancialReportItemKinds.Rows Then
					Continue;
				EndIf;
				NewRow = CheckResult.Add();
				NewRow.Group = TreeRow.Parent.ReportItem;
				NewRow.GroupDescription = TreeRow.Parent.NameForPrinting;
				NewRow.BudgetFlowItem = RowCellGroup.BudgetFlowItem;
				For Each NameOfAnalyticsType In ArrayOfNamesOfTypesOfAnalytics Do
					NewRow[NameOfAnalyticsType] = RowCellGroup[NameOfAnalyticsType];
				EndDo;
			EndDo;
			ProcessedReportElements.Add(RowCellGroup.String);
		EndIf;
		If Not ValueIsFilled(RowCellGroup.Column) Then
			Continue;
		EndIf;
		If ProcessedReportElements.Find(RowCellGroup.Column) = Undefined Then
			TheStructureOfTheSearch.Insert("ReportItem", RowCellGroup.Column);
			TreeRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
			For Each TreeRow In TreeRows Do
				If TreeRow.Parent.ItemKind = Enums.FinancialReportItemKinds.Columns Then
					Continue;
				EndIf;
				NewRow = CheckResult.Add();
				NewRow.Group = TreeRow.Parent.ReportItem;
				NewRow.GroupDescription = TreeRow.Parent.NameForPrinting;
				NewRow.BudgetFlowItem = RowCellGroup.BudgetFlowItem;
				For Each NameOfAnalyticsType In ArrayOfNamesOfTypesOfAnalytics Do
					NewRow[NameOfAnalyticsType] = RowCellGroup[NameOfAnalyticsType];
				EndDo;
			EndDo;
			ProcessedReportElements.Add(RowCellGroup.Column);
		EndIf;
	EndDo;

	CheckResult.Columns.Add("Flag");
	CheckResult.FillValues(1, "Flag");
	If IsBlankString(NamesOfTypesOfAnalytics) Then
		CheckResult.GroupBy("Group, GroupDescription, BudgetFlowItem", "Flag");
	Else
		CheckResult.GroupBy("Group, GroupDescription, BudgetFlowItem," + NamesOfTypesOfAnalytics, "Flag");
	EndIf;

	ComplianceOfArticles = New Map;
	For Each CheckString In CheckResult Do
		If CheckString.Flag > 1 And ValueIsFilled(CheckString.BudgetFlowItem) Then
			ComplianceOfArticles.Insert(CheckString.BudgetFlowItem, CheckString.GroupDescription);
		EndIf;
	EndDo;

	ErrorText = NStr("vi = 'Dạng ""%1"" đã có trong nhóm ""%2"" nhiều lần';
					|ru = 'Статья ""%1"" встречается внутри группы ""%2"" несколько раз';
					|en = '""%1"" item is included in the ""%2"" group multiple times'; fa = '""%1"" item is included in the ""%2"" group multiple times';
					|it = 'La voce ""%1"" è riscontrata nel gruppo ""%2"" numerose volte';
					|pl = 'Pozycja ""%1"" spotyka się wewnątrz grupy ""%2"" kilka raz';
					|tr = '""%1"" maddesi ""%2"" grubunun içerisinde birkaç kez oluşur'");
	For Each KeysAndValue In ComplianceOfArticles Do
		CommonClientServer.AddUserError(ErrorsMessages, "", StrTemplate(ErrorText,
			KeysAndValue.Key, KeysAndValue.Value), "");
	EndDo;
	
EndProcedure

Procedure CheckIfThereIsNoHierarchyOutputByAnalystsOutputTogether(Parameters, ErrorsMessages)

	ItemsTree = Parameters.ItemTreeWithoutAdditionalItems;
	
	TheStructureOfTheSearch = New Structure("ItemKind, DisplayWithParent",
		Enums.FinancialReportItemKinds.Dimension, True);
	
	ErrorText = NStr("vi = 'Đối với đối tượng phân tích ""%1"" không cho phép sử dụng hiển thị phân nhánh';
					|ru = 'Для аналитики ""%1"" использование вывода иерархии недопустимо';
					|en = 'You cannot display a hierarchy for the ""%1"" dimension'; fa = 'You cannot display a hierarchy for the ""%1"" dimension';
					|it = 'Для аналитики ""%1"" использование вывода иерархии недопустимо';
					|pl = 'You cannot display a hierarchy for the ""%1"" dimension';
					|tr = '""%1"" boyutu için hiyerarşi çıkarımının kullanılmasına izin verilemez'");
	FoundRows = ItemsTree.Rows.FindRows(TheStructureOfTheSearch, True);
	For Each FoundRow In FoundRows Do
		If FoundRow.ShowItemHierarchy Then
			CommonClientServer.AddUserError(ErrorsMessages, "", StrTemplate(ErrorText,
				FoundRow.NameForPrinting), "");
		EndIf;
		If FoundRow.Parent.ShowItemHierarchy Then
			CommonClientServer.AddUserError(ErrorsMessages, "", StrTemplate(ErrorText,
				FoundRow.Parent.NameForPrinting), "");
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region BudgetDatesAndFactBoundaries

// Returns an indication that the budget profile uses the actual data boundaries.
//
// Parameters:
//  BudgetProfile - CatalogRef.BudgetProfiles - verifiable budget profile
//
// Returns:
//  Boolean - True if the budget profile uses the actual data boundary
//
Function BudgetViewUsesActualDataBoundary(BudgetProfile) Export
	
	If Not ValueIsFilled(BudgetProfile) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	TypeOfCacheElement = Enums.BudgetCacheKinds.UsesActualDataOffset;
	UsesActualDataOffset = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.GetCacheValue(BudgetProfile, TypeOfCacheElement);
	
	If UsesActualDataOffset <> Undefined Then
		SetPrivilegedMode(False);
		Return UsesActualDataOffset;
	EndIf;
	
	UsesActualDataOffset = False;
	ColumnStructure1 = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(BudgetProfile);
	DataSources = BudgetReportingCacheCalculationServer.GetDescriptionOfDataSources(
		BudgetProfile,
		ColumnStructure1,
		Enums.ModesOfBudgetReportGeneration.Report,
		True);
	SourcesOfGroupingPeriods = BudgetReportingCacheCalculationServer.SourcesOfGroupingPeriods(
		BudgetProfile,
		ColumnStructure1,
		Enums.ModesOfBudgetReportGeneration.Report);
	
	For Each Source In DataSources Do
		If StrFind(Upper(Source.ExpressionStartOfPeriod), Upper("&ActualDataLimit")) Then
			UsesActualDataOffset = True;
		EndIf;
		If StrFind(Upper(Source.ExpressionEndOfPeriod), Upper("&ActualDataLimit")) Then
			UsesActualDataOffset = True;
		EndIf;
		If StrFind(Upper(Source.ExpressionOfGroupingPeriod), Upper("&ActualDataLimit")) Then
			UsesActualDataOffset = True;
		EndIf;
	EndDo;
	
	For Each Source In SourcesOfGroupingPeriods Do
		If StrFind(Upper(Source.ExpressionBeginningOfGroupingPeriod), Upper("&ActualDataLimit")) Then
			UsesActualDataOffset = True;
		EndIf;
		If StrFind(Upper(Source.EndOfGroupingPeriodExpression), Upper("&ActualDataLimit")) Then
			UsesActualDataOffset = True;
		EndIf;
	EndDo;
	
	InformationRegisters.CacheOfAuxiliaryBudgetProfileData.SetCacheValue(BudgetProfile,
		TypeOfCacheElement, UsesActualDataOffset);
	
	SetPrivilegedMode(False);
	
	Return UsesActualDataOffset;
	
EndFunction

Procedure AlignDatesByBudgetFrequency(BudgetProfile, BeginOfPeriod, EndOfPeriod) Export
	
	If Not ValueIsFilled(BudgetProfile) Then
		Return;
	EndIf;
	
	Attributes = Common.ObjectAttributesValues(BudgetProfile, 
		"PlanningMethod, NumberOfPeriodsOfRollingBudget, Periodicity");
		
	If Attributes.PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod Then
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(BeginOfPeriod, Attributes.Periodicity);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(EndOfPeriod, Attributes.Periodicity);
	Else
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(BeginOfPeriod, Attributes.Periodicity);
		EndOfPeriod = WorkingWithClientServerPeriods.AddInterval(BeginOfPeriod, Attributes.Periodicity,
			Attributes.NumberOfPeriodsOfRollingBudget - 1);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(EndOfPeriod, Attributes.Periodicity);
	EndIf;
	
EndProcedure

// Returns the actual data boundary for the budget profile.
//
// Parameters:
//  BudgetProfile - CatalogRef.BudgetProfiles
//  BeginOfPeriod - Date
//
// Returns:
//  Date
//
Function BorderOfActualDataByBudgetType(BudgetProfile, BeginOfPeriod) Export
	
	If Not ValueIsFilled(BudgetProfile) Then
		Return BeginOfPeriod;
	EndIf;
	
	Attributes = Common.ObjectAttributesValues(BudgetProfile, 
		"LocationOptionOfActualDataOffset, 
		|ActualDataLimitOffset, 
		|ActualDataLimitTimeFence,
		|Periodicity");
		
	If Attributes.LocationOptionOfActualDataOffset =
				Enums.LocationOptionsOfActualDataOffsets.BeforeBudgetPreparation Then
		ActualDataLimit = WorkingWithClientServerPeriods.AddInterval(BeginOfPeriod,
			Attributes.ActualDataLimitTimeFence, -Attributes.ActualDataLimitOffset);
	Else
		ActualDataLimit = WorkingWithClientServerPeriods.BeginningDateOfPeriod(CurrentSessionDate(), Attributes.Periodicity) - 1;
	EndIf;
	
	Return ActualDataLimit;
	
EndFunction

// Managing form elements
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - Type of budget.
// 	Items - FormAllItems - Elements of the budget instance or budget report form.
// 	ActualDataLimit - Date - The boundary of the actual data.
Procedure ConfigureGroupOfPeriodElements(BudgetProfile, Items, ActualDataLimit) Export
	
	If ValueIsFilled(BudgetProfile) Then
		
		Attributes = Common.ObjectAttributesValues(BudgetProfile,
		"PlanningMethod,
		|NumberOfPeriodsOfRollingBudget,
		|Periodicity");
		
		PeriodHeader = "";
		If Attributes.PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod Then
			PeriodHeader = NStr("vi = 'Ngân sách cố định với giai đoạn lập kế hoạch %1';
								|ru = 'Фиксированный бюджет с периодом планирования %1';
								|en = 'Fixed budget with %1 as a planning period'; fa = 'Fixed budget with %1 as a planning period';
								|it = 'Budget fisso con periodo di pianificazione %1';
								|pl = 'Budżet stały z okresem planowania %1';
								|tr = '%1 planlama dönemiyle sabit bütçe'");
			PeriodHeader = StringFunctionsClientServer.SubstituteParametersToString(PeriodHeader, Lower(Attributes.Periodicity));
			EndOfPeriodFormField = Items.EndOfPeriod; // FormField - 
			EndOfPeriodFormField.Enabled = True;
			SelectPeriodFormField = Items.SelectPeriod; // FormField -
			SelectPeriodFormField.Visible = True;
		ElsIf Attributes.PlanningMethod = Enums.BudgetPreparationMethods.Rolling Then
			TimeIntervals = WorkingWithClientServerPeriods.PeriodInNumbersPeriodicityInWords(Attributes.NumberOfPeriodsOfRollingBudget, Attributes.Periodicity);
			PeriodHeader = NStr("vi = 'Ngân sách kỳ liên hoàn %1';
								|ru = 'Скользящий бюджет на %1';
								|en = 'Rolling budget for %1'; fa = 'Rolling budget for %1';
								|it = 'Budget rinnovabile per %1';
								|pl = 'Budżet kroczący na %1';
								|tr = '%1 için dinamik bütçe'");
			PeriodHeader = StringFunctionsClientServer.SubstituteParametersToString(PeriodHeader, TimeIntervals);
			EndOfPeriodFormField = Items.EndOfPeriod; // FormField -
			EndOfPeriodFormField.Enabled = False;
			SelectPeriodFormField = Items.SelectPeriod; // FormField -
			SelectPeriodFormField.Visible = False;
		EndIf;
		
		FormFieldLabelBudgetView = Items.LabelBudgetView; // FormField -
		FormFieldLabelBudgetView.Title = PeriodHeader;
		
	Else
		
		FormFieldLabelBudgetView = Items.LabelBudgetView; // FormField -
		FormFieldLabelBudgetView.Title = NStr("vi = 'Ngân sách cố định';
												|ru = 'Фиксированный бюджет';
												|en = 'Fixed budget'; fa = 'Fixed budget';
												|it = 'Budget fisso';
												|pl = 'Budżet stały';
												|tr = 'Sabit bütçe'");
		
	EndIf;
	
	If BudgetViewUsesActualDataBoundary(BudgetProfile) Then
	
		FormFieldBorderDataFact = Items.ActualDataLimit; // FormField -
		FormFieldBorderDataFact.Visible = True;
		FormFieldBorderDataFact.Title = NStr("vi = 'Ranh giới dữ liệu thực tế: %1';
											|ru = 'Граница факт.данных: %1';
											|en = 'Actual data boundary: %1'; fa = 'Actual data boundary: %1';
											|it = 'Limiti dei dati effettivi: %1';
											|pl = 'Granica danych fakt.: %1';
											|tr = 'Gerçek veri limiti %1'");
		FormFieldBorderDataFact.Title = StringFunctionsClientServer.SubstituteParametersToString(
				FormFieldBorderDataFact.Title,
				Format(ActualDataLimit, "DLF=D"));
	
	Else
		
		Items.ActualDataLimit.Visible = False;
	
	EndIf;
	
EndProcedure

#EndRegion

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export
	
	ThereAreRefs = Common.RefsToObjectFound(Parameters.Object);
	If Not ThereAreRefs Then
		ThereAreRefs = CheckUseOfObjectInActionSettingsOfBudgetStages(Parameters.Object);
	EndIf;
	PutToTempStorage(ThereAreRefs, StorageAddress);
	
EndProcedure

Function CheckUseOfObjectInActionSettingsOfBudgetStages(Ref)
	
	ThereAreRefs = False;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BudgetingSteps.Ref,
	|	BudgetingSteps.SettingOfAction
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Action = VALUE(Enum.TypesOfBudgetingStepActions.FillingBudgetEntryForm)
	|	AND BudgetingSteps.Owner = &Owner";
	
	Query.SetParameter("Owner", Ref.Owner);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ActionSettingsStore = Selection.SettingOfAction; // ValueStorage
		SettingOfAction = ActionSettingsStore.Get();
		If TypeOf(SettingOfAction) <> Type("ValueTable") Then
			Continue;
		EndIf;
		
		SearchParameters = New Structure;
		SearchParameters.Insert("Name","BudgetProfiles");
		Rows = SettingOfAction.FindRows(SearchParameters);
		If Rows.Count() = 0 Then 
			Continue;
		EndIf;
		
		BudgetProfiles = Rows[0].Value;
		
		For Each Page1 In BudgetProfiles Do
			If Page1.BudgetProfile = Ref Then 
				ThereAreRefs = True;
				Return ThereAreRefs;
			EndIf;
		EndDo;
		
	EndDo;
	
	Return ThereAreRefs;
	
EndFunction

#EndRegion

#EndIf
