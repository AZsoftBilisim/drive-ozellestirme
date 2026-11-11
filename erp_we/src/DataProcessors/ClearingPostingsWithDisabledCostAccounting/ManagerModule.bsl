#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns whether there are unused movements at cost.
//
//	Returns:
//		Boolean - a sign of the presence of unused movements at cost.
//
Function ThereAreUnusedRegisteredRecordsOnCostRegisters() Export
	
	If Not CalculationOfCostCached.UnusedRegisteredRecordsOnCostRegistersArePossible() Then
		Return False;
	EndIf;
	
	TempTableManager = GenerateTableOfUnusedRegisteredRecords(True);
	
	Return CostCalculationAppliedAlgorithms.TemporaryTableSize(TempTableManager, "TTUnusedRegisteredRecords") > 0;
	
EndFunction

// Returns the number of registrars with unused movements at cost.
//
//	Returns:
//		Number - the number of registrars with unused movements at cost.
//
Function NumberOfRecordersWithUnusedRegisteredRecords() Export
	
	If Not CalculationOfCostCached.UnusedRegisteredRecordsOnCostRegistersArePossible() Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = GenerateTableOfUnusedRegisteredRecords(False);
	
	Query.Text =
	"SELECT
	|	COUNT(DISTINCT T.Recorder) AS NumberOfRegistrars
	|FROM
	|	TTUnusedRegisteredRecords AS T";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.NumberOfRegistrars;
	
EndFunction
	
#EndRegion

#Region Private

Function GenerateTableOfUnusedRegisteredRecords(OnlyCheckAvailability) Export
	
	ExceptionLoggers = New Array;
	
	For Each MetaLogger In CalculationOfCostCached.RecordersWithRegisteredRecordsWhenCostAccountingIsTurnedOff() Do
		MetadataOfDocument = MetaLogger.Key; // MetadataObjectDocument
		ExceptionLoggers.Add(Type("DocumentRef." + MetadataOfDocument.Name));
	EndDo;
	
	ArrayOfRequestTexts = New Array;
	
	QueryTemplate = 
	"SELECT TOP 1
	|	""&RegisterName"" AS RegisterName,
	|	T.Recorder AS Recorder,
	|	T.Organization AS Organization,
	|	BEGINOFPERIOD(T.Period, DAY) AS Period,
	|	&ClearAllRegisteredRecords AS ClearAllRegisteredRecords
	|	,&TextTemporaryTableName
	|FROM
	|	&RegisterName AS T
	|WHERE
	|	(NOT &KeepRecords
	|	AND &SelectionTextByPeriod
	|	)
	|	AND (&TextOfSelectionByServiceFields)";
	
	ListOfRegisters = CalculationOfCostCached.RegistersNotUsedWhenCostAccountingIsDisabled();
	ListOfUncountableRegisters = CalculationOfCostCached.RegistersThatAreNotCalculatedWhenCostAccountingIsTurnedOff();
	
	For Each KeyAndValue In ListOfUncountableRegisters Do
		ListOfRegisters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	For Each KeyAndValue In ListOfRegisters Do
		
		RegisterMetadata 	   = KeyAndValue.Key;
		ThereIsACompany 	   = RegisterMetadata.Dimensions.Find("Organization") <> Undefined;
		ThereAreAnalyticsPartners = RegisterMetadata.Dimensions.Find("AccountingDimensionByPartners") <> Undefined;
		SubordinateToRegistrar   = Not CostCalculationUniversalAlgorithms.IsIndependentInformationRegister(RegisterMetadata);
		
		If ThereIsACompany Then
			OrganizationFieldText = "T.Organization";
		ElsIf ThereAreAnalyticsPartners Then 
			OrganizationFieldText = "T.AccountingDimensionByPartners.Organization";
		Else		
			OrganizationFieldText = "VALUE(Catalog.Companies.EmptyRef)";
		EndIf;
		
		If SubordinateToRegistrar Then
			SelectionTextByPeriod = "
				|	OR (T.Period < &AccountingStartDate
				|		AND NOT VALUETYPE(T.Recorder) IN (&ExceptionLoggers))
				|	OR (T.Period < DATEADD(&AccountingStartDate, MONTH, -1)
				|		AND VALUETYPE(T.Recorder) IN (&ExceptionLoggers))";
		Else
			SelectionTextByPeriod = "
				|	OR (T.Period < DATEADD(&AccountingStartDate, MONTH, -1))";
		EndIf;
		
		If ListOfUncountableRegisters.Get(KeyAndValue.Key) = Undefined Then
			TextOfSelectionByServiceFields = "TRUE";
			TextClearAllRegisteredRecords = "TRUE";
		Else
			TextOfSelectionByServiceFields = TextOfSelectionByServiceFields(RegisterMetadata);
			TextClearAllRegisteredRecords = "FALSE";
		EndIf;
		
		CurrentQueryText = QueryTemplate;
		CurrentQueryText = StrReplace(CurrentQueryText, "TOP 1", ?(OnlyCheckAvailability, "TOP 1", "DISTINCT"));
		CurrentQueryText = StrReplace(CurrentQueryText, "&RegisterName", RegisterMetadata.FullName());
		CurrentQueryText = StrReplace(CurrentQueryText, ",&TextTemporaryTableName", ?(ArrayOfRequestTexts.Count() = 0, "INTO TTUnusedRegisteredRecords", ""));
		CurrentQueryText = StrReplace(CurrentQueryText, "&RegisterName", RegisterMetadata.FullName());
		If Not SubordinateToRegistrar Then
			CurrentQueryText = StrReplace(CurrentQueryText, "T.Recorder", "UNDEFINED");
		EndIf;
		CurrentQueryText = StrReplace(CurrentQueryText, "T.Organization", OrganizationFieldText);
		CurrentQueryText = StrReplace(CurrentQueryText, "AND &SelectionTextByPeriod", SelectionTextByPeriod);
		CurrentQueryText = StrReplace(CurrentQueryText, "&TextOfSelectionByServiceFields", TextOfSelectionByServiceFields);
		CurrentQueryText = StrReplace(CurrentQueryText, "&ClearAllRegisteredRecords", TextClearAllRegisteredRecords);
		
		ArrayOfRequestTexts.Add(CurrentQueryText);
		
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = StrConcat(ArrayOfRequestTexts, Chars.LF + "UNION ALL" + Chars.LF);
	
	Query.SetParameter("KeepRecords", 		 		GetFunctionalOption("UseCostAccounting"));
	Query.SetParameter("AccountingStartDate", 		BegOfMonth(Constants.CostAccountingStartDate.Get()));
	Query.SetParameter("ExceptionLoggers", ExceptionLoggers);
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

Procedure ClearUnusedRegisteredRecordsInCostRegisters(Parameters = "", StorageAddress = "") Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.TempTablesManager = GenerateTableOfUnusedRegisteredRecords(False);
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Recorder			AS Recorder,
	|	T.RegisterName			AS RegisterName,
	|	T.Period				AS Period,
	|	T.ClearAllRegisteredRecords	AS ClearAllRegisteredRecords
	|FROM
	|	TTUnusedRegisteredRecords AS T
	|
	|ORDER BY
	|	Period DESC
	|";
	
	QueryResult = Query.Execute();
	
	
	Selection = QueryResult.Select();
	
	RequestTextsByRegister = New Map;
	
	While Selection.Next() Do
		
		RegisterMetadata   = Metadata.FindByFullName(Selection.RegisterName);
		SubordinateToRegistrar = Not CostCalculationUniversalAlgorithms.IsIndependentInformationRegister(RegisterMetadata);
		
		If Metadata.AccumulationRegisters.Contains(RegisterMetadata) Then
			RecordSet = AccumulationRegisters[RegisterMetadata.Name].CreateRecordSet();
		Else
			RecordSet = InformationRegisters[RegisterMetadata.Name].CreateRecordSet();
		EndIf;
		
		If SubordinateToRegistrar Then
			FilterElement = RecordSet.Filter.Recorder; // FilterItem
			FilterElement.Set(Selection.Recorder);
		Else
			FilterElement = RecordSet.Filter.Period; // FilterItem
			FilterElement.Set(Selection.Period);
		EndIf;
		
		If Not Selection.ClearAllRegisteredRecords Then
			
			QueryText = RequestTextsByRegister.Get(Selection.RegisterName);
			
			If Not ValueIsFilled(QueryText) Then
				
				QueryText =
				"SELECT
				|	*
				|FROM
				|	&RegisterName AS T
				|WHERE
				|	&TextOfSelectionByMeasurements
				|	AND NOT (&TextOfSelectionByServiceFields)";
				
				TextOfSelectionByServiceFields = TextOfSelectionByServiceFields(RegisterMetadata);
				
				If SubordinateToRegistrar Then
					TextOfSelectionByMeasurements = "T.Recorder = &Recorder";
				Else
					TextOfSelectionByMeasurements = "T.Period = &Period";
				EndIf;
				
				QueryText = StrReplace(QueryText, "&RegisterName", Selection.RegisterName);
				QueryText = StrReplace(QueryText, "&TextOfSelectionByMeasurements", TextOfSelectionByMeasurements);
				QueryText = StrReplace(QueryText, "&TextOfSelectionByServiceFields", TextOfSelectionByServiceFields);
				
				RequestTextsByRegister.Insert(Selection.RegisterName, QueryText);
				
			EndIf;
			
			Query.Text = QueryText;
			
			If SubordinateToRegistrar Then
				Query.SetParameter("Recorder", Selection.Recorder);
			Else
				Query.SetParameter("Period", 	 Selection.Period);
			EndIf;
			
			RecordSet.Load(Query.Execute().Unload());
			
		EndIf;
		
		RecordSet.Write(True);
		
	EndDo;
	
	AccountingStartDate = BegOfMonth(Constants.CostAccountingStartDate.Get());
	
	InformationRegisters.JobsForCalculatingCost.ClearRecordsForPeriod(, AccountingStartDate - 1);
	InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(BegOfMonth(AccountingStartDate - 1));
	
EndProcedure 

Function TextOfSelectionByServiceFields(RegisterMetadata)
	
	ThereIsCalculationOfParties 		= (RegisterMetadata.Attributes.Find("LotCalculation") <> Undefined);
	ThereIsCostCalculation = (RegisterMetadata.Attributes.Find("CalculationOfCost") <> Undefined);
	
	If ThereIsCalculationOfParties And ThereIsCostCalculation Then
		FilterText1 = "T.LotCalculation OR T.CalculationOfCost";
	ElsIf ThereIsCalculationOfParties Then
		FilterText1 = "T.LotCalculation";
	ElsIf ThereIsCostCalculation Then
		FilterText1 = "T.CalculationOfCost";
	Else
		FilterText1 = "FALSE";
	EndIf;
	
	Return FilterText1;
	
EndFunction


#EndRegion

#EndIf
