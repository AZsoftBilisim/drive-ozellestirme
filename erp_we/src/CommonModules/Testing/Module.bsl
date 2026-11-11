///////////////////////////////////////////////////////////
// Testing - Configuration Testing Module       //
//                                                       //
///////////////////////////////////////////////////////////
//
//

#Region Public

// This method places data in temporary tables for the specified registers and the specified month
// A temporary table is created for the datum ObjectName, 
// where datum ObjectName is the name of the register. 
// Example: Atlantarealestate.
// Parameters:
//		ControlRegisters - Array - List of registers for which data is saved.
//		QueryOptions - See Testing.QueryOptions
//		Month-date - the Beginning of the month for which data should be read.
//		ArrayOfLoggers - Array - List of documents for which movements are saved.
//										If this parameter is used, the month Is not used.
//		ReferenceData - ValueTable - Reference data to be compared with.
// Returns:
//	TempTablesManager - Contains temporary tables with selections for the specified registers.
Function SaveReferenceData(ControlRegisters, QueryOptions = Undefined, ArrayOfLoggers = Undefined, ReferenceData = Undefined) Export
	
	QueryText = "";
	SaveReferenceData = True;
	TemporaryTable = New TempTablesManager;
	If TypeOf(QueryOptions) = Type("Date") Or QueryOptions = Undefined Then
		// We will support the old interface, when the second parameter was passed the month of calculation:
		QueryOptions = QueryOptions(QueryOptions, ArrayOfLoggers);
	EndIf;
	
	DataRequest = New Query(QueryText);

	For Each ControlRegister In ControlRegisters Do

		ReferenceTable_ = Undefined;
		If ReferenceData <> Undefined And ReferenceData[ControlRegister] <> Undefined Then
			RegisterNameComponents = StrSplit(ControlRegister, ".");
			RegisterName = ?(RegisterNameComponents.Count() > 1, RegisterNameComponents[1], RegisterNameComponents[0]);

			ReferenceTable_ = GetFromTempStorage(ReferenceData[ControlRegister]);
			DataRequest.SetParameter("ExternalTable" + RegisterName, ReferenceTable_);
		EndIf;

		QueryText = QueryText + GenerateRequest(ControlRegister, SaveReferenceData, QueryOptions.SelectionByRegistrars, ReferenceTable_);
	EndDo;

	DataRequest.Text = QueryText;
	DataRequest.TempTablesManager = TemporaryTable;
	DataRequest.SetParameter("ArrayOfLoggers", QueryOptions.ArrayOfLoggers);
	DataRequest.SetParameter("BeginOfPeriod", QueryOptions.BeginOfPeriod);
	DataRequest.SetParameter("EndOfPeriod", QueryOptions.EndOfPeriod);
	
	WriteLogEvent(NStr("vi = 'Kiểm tra';
						|ru = 'Тестирование';
						|en = 'Testing'; fa = 'آزمون';
						|it = 'Testing';
						|pl = 'Testing';
						|tr = 'Test'", Common.DefaultLanguageCode())
		+ "." + NStr("vi = 'Bắt đầu lưu lại dữ liệu tham chiếu';
					|ru = 'Начато сохранение эталонных данных';
					|en = 'Saving reference data started'; fa = 'Saving reference data started';
					|it = 'Salvataggio dei documenti di riferimento avviato';
					|pl = 'Rozpoczęto zapisywanie danych referencyjnych';
					|tr = 'Referans verilerin kaydedilmesi başlandı'", Common.DefaultLanguageCode()));
	DataRequest.ExecuteBatch();
	WriteLogEvent(NStr("vi = 'Kiểm tra';
						|ru = 'Тестирование';
						|en = 'Testing'; fa = 'آزمون';
						|it = 'Testing';
						|pl = 'Testing';
						|tr = 'Test'", Common.DefaultLanguageCode())
		+ "." + NStr("vi = 'Kết thúc lưu lại dữ liệu tham chiếu';
					|ru = 'Завершено сохранение эталонных данных';
					|en = 'Finished saving reference data'; fa = 'Finished saving reference data';
					|it = 'È completato il processo di salvataggio dei dati di riferimento';
					|pl = 'Zakończono zapisywanie danych referencyjnych';
					|tr = 'Referans verilerin kaydedilmesi tamamlandı'", Common.DefaultLanguageCode()));
	
	Return TemporaryTable;
EndFunction

// The method compares data from temporary tables with data from control registers
//  and returns fields that differ in data with details up to the source and result
//  data.
//
// Parameters:
//  TemporaryTable		 - TempTablesManager	 - Contains reference data.
//  ControlRegisters		 - Array					 - List of registers for which data are compared.
//  QueryOptions 		 - See Testing.QueryOptions
//  Month-date - the Beginning of the month for which the data is compared.
//  ArrayOfLoggers		 - Array					 - List of documents for which movements are saved.
//  					If this parameter is used, the month Is not used.
//  ReferenceData 		 - ValueTable			 - Reference data to be compared with.
//  AdditionalParameters	 - See AdditionalParametersForFormingComparisonRequest
// 
// Returns:
//  Structure - It contains tables with discrepancies in control registers.
//
Function CompareWithReferenceData(TemporaryTable, ControlRegisters, QueryOptions = Undefined, ArrayOfLoggers = Undefined, ReferenceData = Undefined, AdditionalParameters = Undefined) Export

	SaveReferenceData = False;
	If TypeOf(QueryOptions) = Type("Date") Or QueryOptions = Undefined Then
		// We will support the old interface, when the third parameter was passed the month of calculation:
		QueryOptions = QueryOptions(QueryOptions, ArrayOfLoggers);
	EndIf;
	
	DataRequest = New Query();
	DataRequest.TempTablesManager = TemporaryTable;
	DataRequest.SetParameter("ArrayOfLoggers", QueryOptions.ArrayOfLoggers);
	DataRequest.SetParameter("BeginOfPeriod", QueryOptions.BeginOfPeriod);
	DataRequest.SetParameter("EndOfPeriod", QueryOptions.EndOfPeriod);
	DataRequest.SetParameter("BatchAccounting22", CalculationOfCostCached.BatchAccountingVersion22(QueryOptions.BeginOfPeriod));
	DataRequest.SetParameter("PoolStartDate", CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	
	Discrepancies = New Map();
	NumberOfDiscrepancies = 0;
	
	WriteLogEvent(NStr("vi = 'Kiểm tra';
						|ru = 'Тестирование';
						|en = 'Testing'; fa = 'آزمون';
						|it = 'Testing';
						|pl = 'Testing';
						|tr = 'Test'", Common.DefaultLanguageCode())
		+ "." + NStr("vi = 'Bắt đầu so sánh với dữ liệu tham chiếu';
					|ru = 'Начато сравнение c эталонными данными';
					|en = 'Started comparison with reference data'; fa = 'Started comparison with reference data';
					|it = 'È avviato il processo di confronto con dati di riferimento';
					|pl = 'Rozpoczęto porównanie z danymi referencyjnymi';
					|tr = 'Referans verilerle karşılaştırma başlandı'", Common.DefaultLanguageCode()));
	
	For Each ControlRegister In ControlRegisters Do
		
		WriteLogEvent(NStr("vi = 'Kết xuất';
							|ru = 'Выгрузили';
							|en = 'Exported'; fa = 'خارج‌شده';
							|it = 'Caricati';
							|pl = 'Exported';
							|tr = 'Yüklenildi'", Common.DefaultLanguageCode()) + " " + ControlRegister);
		AdditionalCaseSensitiveParameters = Testing.AdditionalParametersForFormingComparisonRequest();
		If AdditionalParameters <> Undefined Then
			AdditionalCaseSensitiveParameters = AdditionalParameters[StrReplace(ControlRegister,".","_")];
		EndIf;
		If QueryOptions.Property("ExcludedFields") Then
			For Each ExcludedField In QueryOptions.ExcludedFields Do
				AdditionalCaseSensitiveParameters.ExcludedFields.Insert(ExcludedField.Key);
			EndDo;
		EndIf;
		If QueryOptions.Property("AllowableVariance") Then
			AdditionalCaseSensitiveParameters.AllowableVariance = QueryOptions.AllowableVariance;
		EndIf;
		If QueryOptions.Property("DetermineOverallDiscrepancy") Then
			AdditionalCaseSensitiveParameters.DetermineOverallDiscrepancy = QueryOptions.DetermineOverallDiscrepancy;
		EndIf;

		ReferenceTable_ = Undefined;
		If ReferenceData <> Undefined And ReferenceData[ControlRegister] <> Undefined Then
			RegisterNameComponents = StrSplit(ControlRegister, ".");
			RegisterName = ?(RegisterNameComponents.Count() > 1, RegisterNameComponents[1], RegisterNameComponents[0]);
			ReferenceTable_ = GetFromTempStorage(ReferenceData[ControlRegister]);
		EndIf;
		DataRequest.Text = GenerateRequest(ControlRegister, SaveReferenceData, QueryOptions.SelectionByRegistrars, ReferenceTable_, AdditionalCaseSensitiveParameters);
		Result = DataRequest.ExecuteBatch();
		Position = 2;
		Boundary = Result.Count();
		While Position < Boundary Do
			If Not Result[Position].IsEmpty() Then
				
				Table = Result[Position].Unload(); // ValueTable
				PivotTable = Table.Copy(, "TypeOfTestRecord");
				PivotTable.Columns.Add("LineCounter");
				PivotTable.FillValues(1, "LineCounter");
				PivotTable.GroupBy("TypeOfTestRecord", "LineCounter");
				BeforeCalculation = 0;
				AfterCalculation = 0;
				For Each String In PivotTable Do
					If String.TypeOfTestRecord = "RecordsBeforeCalculation" Then
						BeforeCalculation = String.LineCounter;
					ElsIf String.TypeOfTestRecord = "RecordsAfterCalculation" Then
						AfterCalculation = String.LineCounter;
					EndIf;
				EndDo;
				NumberOfDiscrepancies = NumberOfDiscrepancies + Max(BeforeCalculation, AfterCalculation);
				RegisterName = Table[0].FullRegisterName;

				If AdditionalCaseSensitiveParameters.DetermineOverallDiscrepancy Then
					NameOfRegistrar = Testing.NameOfRegisterRegistrarField(ControlRegister);
					RegisterStructure = New Structure("Table, Count", Table, Max(BeforeCalculation, AfterCalculation));
					Table.Indexes.Add(NameOfRegistrar);
					RegisterStructure.Insert("Documents", Result[3].Unload().UnloadColumn(NameOfRegistrar));
				Else
					Records = Common.ValueToXMLString(Table);
					RegisterStructure = New Structure("Records, Count", Records, Max(BeforeCalculation, AfterCalculation));
					Table.Clear();
				EndIf;
				
				Discrepancies.Insert(RegisterName, RegisterStructure);
				
			EndIf;
			Position = Position + 3;
		EndDo;
	EndDo;
	
	WriteLogEvent(NStr("vi = 'Kiểm tra';
						|ru = 'Тестирование';
						|en = 'Testing'; fa = 'آزمون';
						|it = 'Testing';
						|pl = 'Testing';
						|tr = 'Test'", Common.DefaultLanguageCode())
		+ "." + NStr("vi = 'Kết thúc so sánh với dữ liệu tham chiếu';
					|ru = 'Завершено сравнение c эталонными данными';
					|en = 'Finished comparison with reference data'; fa = 'Finished comparison with reference data';
					|it = 'È completato il processo di confronto con dati di riferimento';
					|pl = 'Zakończono porównanie z danymi referencyjnymi';
					|tr = 'Referans verilerle karşılaştırma tamamlandı'", Common.DefaultLanguageCode()));
	
	Discrepancies.Insert("NumberOfDiscrepancies", NumberOfDiscrepancies);
	
	Return Discrepancies;
	
EndFunction

// This method generates the request text for all fields for the specified metadata object.
//
// Parameters:
//  PathToMetadata				 - String	 - The path to the object where data is saved.
//  	Example " Accumulation Register.Cost of goods".
//  SaveToTemporaryTable	 - Boolean	 - The query result will be saved to a temporary table in the form
//  	" etalonymyobjectmetad Data"
//  SelectionByRegistrars		 - Boolean	 - Optional parameter. when set to true, the query will impose
//  	a condition on the data selection, where the logger is in the array of loggers. There will be no selection
//  	by period.
//	ReferenceTable_			 - ValueTable - Reference data to be compared with.
//  AdditionalParameters		 - See AdditionalParametersForFormingComparisonRequest.
// 
// Returns:
//  String - query text.
//
Function GenerateRequest(PathToMetadata,	SaveToTemporaryTable = False, SelectionByRegistrars = False, ReferenceTable_ = Undefined, AdditionalParameters = Undefined) Export

	ReadingFromReferenceData = ReferenceTable_ <> Undefined;
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalParametersForFormingComparisonRequest();
	EndIf;
	If RegistersWithServiceRegistrar().Find(PathToMetadata) <> Undefined Then
		AdditionalParameters.ExcludedFields.Insert("Recorder");
	Else
		
		MetaRegister = Metadata.FindByFullName(PathToMetadata);
		
		If Metadata.InformationRegisters.Contains(MetaRegister)
		 And MetaRegister.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			AdditionalParameters.SubordinateToRegistrar = False;
			AdditionalParameters.DetermineOverallDiscrepancy = False;
		EndIf;
		
	EndIf;
	ExcludedFields = ExceptionsList(AdditionalParameters.ExcludedFields);
	FieldsToExpand = AdditionalParameters.FieldsToExpand;
	
	MetadataCollection = Metadata.FindByFullName(PathToMetadata);
	RegisterName = MetadataCollection.Name;
	ThisIsBuhRegister = Common.IsAccountingRegister(MetadataCollection);
	// For the boom. we use a virtual table (to get a subconto):
	PathToMetadataInRequest = PathToMetadata + ?(ThisIsBuhRegister, ".RecordsWithExtDimensions", "");
	// For a virtual table, boom. the register may contain NULL values, we define them as UNDEFINED:
	FieldClarification = DefaultRequestFieldNames();
	If ThisIsBuhRegister Then
		AdditionalParameters.InCaseOfDiscrepanciesChooseFirst = 50;
		FieldClarification.Insert("ExpressionBefore", "ISNULL(");
		FieldClarification.Insert("ExpressionAfter", ", Undefined)");
		FieldClarification.Insert("Alias");
	EndIf;
	
	FieldsStructure = StructureOfCollectionFields(MetadataCollection, AdditionalParameters);

	If ReadingFromReferenceData Then

		// Removing missing dimensions and details from the comparison
		For Each FieldsCollection In FieldsStructure Do
			Counter = FieldsCollection.Value.Count() - 1;
			While Counter >= 0 Do

				FieldName = FieldsCollection.Value[Counter];
				If ReferenceTable_.Columns.Find(FieldName) = Undefined Then
					FieldsCollection.Value.Delete(Counter);
				EndIf;
				Counter = Counter - 1;

			EndDo;
		EndDo;

	EndIf;
	
	If AdditionalParameters.GroupByDimensions Then
		DimensionsArray_ = FieldsStructure.Dimensions;
	Else
		DimensionsArray_ = New Array();
		CommonClientServer.SupplementArray(DimensionsArray_, FieldsStructure.Dimensions, True);
		CommonClientServer.SupplementArray(DimensionsArray_, FieldsStructure.Resources, True);
		CommonClientServer.SupplementArray(DimensionsArray_, FieldsStructure.Attributes, True);
	EndIf;

	FieldsExcludedByString = CommonClientServer.StructureKeysToString(ExcludedFields);
	ArrayOfExcludedFields = StrSplit(FieldsExcludedByString, ",");
	CommonClientServer.ArraysDifference(DimensionsArray_, ArrayOfExcludedFields);
	
	ArrayOfDimensionsAfter = Common.CopyRecursive(DimensionsArray_);
	
	ExpandKeysFields(DimensionsArray_, FieldsToExpand, ExcludedFields);
	
	ExpandKeysFields(ArrayOfDimensionsAfter, FieldsToExpand, ExcludedFields, True);
	
	If SaveToTemporaryTable Then
		
		If ReadingFromReferenceData Then
			
			RequestTextTemplate = "
			|SELECT
			|	&MeasurementTextDetails,
			|	&AmountText,
			|	TRUE
			|INTO ReferenceMetadataObjectName
			|FROM
			|	&ExternalTableMetadataObjectName AS DD
			|WHERE
			|	&TextOfSelectionConditions
			|;
			|///////////////////////////////////
			|";
			
		Else 
		
			RequestTextTemplate = "
			|SELECT
			|	&MeasurementTextDetails,
			|	&AmountText,
			|	TRUE
			|INTO ReferenceMetadataObjectName
			|FROM
			|	MetadataObject AS DD
			|WHERE
			|	&TextOfSelectionConditions
			|;
			|///////////////////////////////////
			|";
			
		EndIf;
		
		MeasurementTextDetails = AddFieldsToRequest(DimensionsArray_, FieldClarification);
		
		FullTextOfRequest = StrReplace(RequestTextTemplate, "&MeasurementTextDetails,", MeasurementTextDetails + ",");
		
		If FieldsStructure.NumericFields.Count() > 0 Then
			FieldClarification.ExpressionAfter = StrReplace(FieldClarification.ExpressionAfter, "Undefined", "0");
			AmountText = AddFieldsToRequest(FieldsStructure.NumericFields, FieldClarification) + ",";
		Else
			AmountText = "";
		EndIf;
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&AmountText,", AmountText);
		
		If ThereIsPeriodInCollection(MetadataCollection) And Not SelectionByRegistrars Then
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfSelectionConditions", "DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod");
		ElsIf SelectionByRegistrars Then
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfSelectionConditions", "DD.Recorder IN (&ArrayOfLoggers)");
		Else
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfSelectionConditions", "TRUE");
		EndIf;
		
		FullTextOfRequest = StrReplace(FullTextOfRequest, "ReferenceMetadataObjectName", "Etalon" + RegisterName);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "ExternalTableMetadataObjectName", "ExternalTable" + RegisterName);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "MetadataObject", PathToMetadataInRequest);
	Else
		RequestTextTemplate = "
		|SELECT DISTINCT
		|	&MeasurementTextDetails,
		|	&TextOfDiscrepancyAmount,
		|	DD.CommonField
		|	, SUM(DD.CheckValue)
		|INTO DiscrepancyFieldsMetadataObjectName
		|FROM
		|	(SELECT
		|		&MeasurementTextDetailsUpTo,
		|		&TextOfAmountUpTo,
		|		UNDEFINED AS CommonField,
		|		1 AS CheckValue
		|	FROM
		|		ReferenceMetadataObjectName AS DD
		|	WHERE
		|		&TextOfSelectionConditionsBefore AND 
		|		TRUE
		|	GROUP BY
		|		&GroupTextBefore
		|	
		|	UNION ALL
		|
		|	SELECT
		|		&MeasurementTextDetailsAfter,
		|		&AmountTextAfter,
		|		UNDEFINED AS CommonField,
		|		- 1 AS CheckValue
		|	FROM
		|		MetadataObject AS DD
		|	WHERE
		|		&TextOfSelectionConditionsAfter AND 
		|		TRUE
		|	GROUP BY
		|		&GroupTextAfter
		|	) AS DD
		|GROUP BY
		|	&GroupIndexText, 
		|	DD.CommonField
		|HAVING 
		|	&ControlFieldText AND
		|	FALSE
		|	AND &ConditionTextByNumberOfRecords
		|;
		|/////////////////////////////////////////
		|SELECT
		|	""RecordsBeforeCalculation""      AS TypeOfTestRecord,
		|	&MeasurementTextDetails,
		|	&TextOfAmountOfDiscrepancyUpTo,
		|	""FullMetadataObjectName"" AS FullRegisterName,
		|	""MetadataObjectName"" AS RegisterName
		|
		|INTO DetailedRecordsMetadataObjectName
		|FROM
		|	DiscrepancyFieldsMetadataObjectName AS DD
		|
		|WHERE &TextInternalConnectionToReference
		|
		|UNION ALL
		|
		|SELECT
		|	""RecordsAfterCalculation""   AS TypeOfTestRecord,
		|	&MeasurementTextAttributesOrAfter,
		|	&TextOfDiscrepancyAmountAfter,
		|	""FullMetadataObjectName"" AS FullRegisterName,
		|	""MetadataObjectName"" AS RegisterName
		|FROM DiscrepancyFieldsMetadataObjectName AS DD
		|
		|WHERE &TextInternalConnectionToResult
		|;
		|/////////////////////////////////////////
		|SELECT
		|	DD.TypeOfTestRecord,
		|	&MeasurementTextDetails,
		|	&TextSumOfSums,
		|	DD.FullRegisterName,
		|	DD.RegisterName
		|FROM DetailedRecordsMetadataObjectName AS DD
		|GROUP BY
		|	&GroupIndexText,
		|	DD.TypeOfTestRecord,
		|	DD.FullRegisterName,
		|	DD.RegisterName
		|;
		|/////////////////////////////////////////
		|";
		
		If ThisIsBuhRegister Then
			RequestTextTemplate = StrReplace(RequestTextTemplate, "&MeasurementTextAttributesOrAfter,", "&MeasurementTextDetails,");
		Else
			RequestTextTemplate = StrReplace(RequestTextTemplate, "&MeasurementTextAttributesOrAfter,", "&MeasurementTextDetailsAfter,");
		EndIf;
		
		MeasurementTextDetails = AddFieldsToRequest(DimensionsArray_);
		FullTextOfRequest = StrReplace(RequestTextTemplate, "&MeasurementTextDetails,", MeasurementTextDetails + ",");
		
		If Not AdditionalParameters.GroupByDimensions Then
			FullTextOfRequest = StrReplace(FullTextOfRequest, "AND &ConditionTextByNumberOfRecords", "OR SUM(DD.CheckValue) <> 0");
		Else
			FullTextOfRequest = StrReplace(FullTextOfRequest, "AND &ConditionTextByNumberOfRecords", "");
		EndIf;
		
		MeasurementTextDetailsUpTo = MeasurementTextDetails;
		ReplaceFields(MeasurementTextDetailsUpTo, AdditionalParameters.ReplacingFieldsBefore);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&MeasurementTextDetailsUpTo,", MeasurementTextDetailsUpTo + ",");
		
		FieldsNames = DefaultRequestFieldNames();
		FieldsNames.ExpressionAfter = " ";
		GroupTextBefore = AddFieldsToRequest(DimensionsArray_, FieldsNames);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&GroupTextBefore", GroupTextBefore);
		
		MeasurementTextDetailsAfter = AddFieldsToRequest(ArrayOfDimensionsAfter, FieldClarification);
		ReplaceFields(MeasurementTextDetailsAfter, AdditionalParameters.ReplacingFieldsAfter);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&MeasurementTextDetailsAfter,", MeasurementTextDetailsAfter + ",");
		
		FieldsNames = DefaultRequestFieldNames();
		FillPropertyValues(FieldsNames, FieldClarification);
		FieldsNames.ExpressionAfter = ?(FieldsNames.ExpressionAfter = "", " ", FieldsNames.ExpressionAfter);
		GroupTextAfter = AddFieldsToRequest(DimensionsArray_, FieldsNames);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&GroupTextAfter", GroupTextAfter);
		
		If FieldsStructure.NumericFields.Count() > 0 Then
			FieldsNames = DefaultRequestFieldNames();
			FieldsNames.ExpressionBefore = "SUM(ISNULL(";
			FieldsNames.ExpressionAfter = ", 0))";
			FieldsNames.Insert("Alias");
			TextOfAmountUpTo = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames) + ",";
			ReplaceFields(TextOfAmountUpTo, AdditionalParameters.ReplacingFieldsBefore);
			
			FieldsNames.ExpressionBefore = "-"+FieldsNames.ExpressionBefore;
			AmountTextAfter = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames) + ",";
			ReplaceFields(AmountTextAfter, AdditionalParameters.ReplacingFieldsAfter);
			
			FieldsNames = DefaultRequestFieldNames();
			FieldsNames.FieldName = "Table";
			TextOfAmountOfDiscrepancyUpTo = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames) + ",";
			ReplaceFields(TextOfAmountOfDiscrepancyUpTo, AdditionalParameters.ReplacingFieldsBefore, "Table");
			FieldsNames.ExpressionBefore = "ISNULL(";
			FieldsNames.ExpressionAfter = ", 0)";
			FieldsNames.Insert("Alias");
			TextOfDiscrepancyAmountAfter = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames) + ",";
			ReplaceFields(TextOfDiscrepancyAmountAfter, AdditionalParameters.ReplacingFieldsAfter, "Table");
			
			FieldsNames = DefaultRequestFieldNames();
			FieldsNames.ExpressionBefore = "SUM(";
			FieldsNames.ExpressionAfter = ")";
			TextSumOfSums = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames) + ",";
		Else
			TextOfAmountUpTo = "";
			AmountTextAfter = "";
			TextOfAmountOfDiscrepancyUpTo = "";
			TextOfDiscrepancyAmountAfter = "";
			TextSumOfSums = "";
		EndIf;
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfAmountUpTo,", TextOfAmountUpTo);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&AmountTextAfter,", AmountTextAfter);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfAmountOfDiscrepancyUpTo,", TextOfAmountOfDiscrepancyUpTo);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfDiscrepancyAmountAfter,", TextOfDiscrepancyAmountAfter);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextSumOfSums,", TextSumOfSums);
		If AdditionalParameters.DetermineOverallDiscrepancy Then
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfDiscrepancyAmount,", TextSumOfSums);
		Else
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfDiscrepancyAmount,", "");
		EndIf;
		
		TextOfSelectionConditionsBefore = "";
		If ValueIsFilled(AdditionalParameters.SelectionConditionsUpTo) Then
			TextOfSelectionConditionsBefore = AdditionalParameters.SelectionConditionsUpTo + " " + "And";
		EndIf;
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfSelectionConditionsBefore And", TextOfSelectionConditionsBefore);	
		If SelectionByRegistrars Then
			TextOfSelectionConditionsAfter = "DD.Recorder IN (&ArrayOfLoggers) AND";
		ElsIf ThereIsPeriodInCollection(MetadataCollection) Then
			TextOfSelectionConditionsAfter = "DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod AND";
		Else
			TextOfSelectionConditionsAfter = "TRUE AND"	
		EndIf;
			
		If ValueIsFilled(AdditionalParameters.SelectionConditionsAfter) Then
			TextOfSelectionConditionsAfter = TextOfSelectionConditionsAfter + "
				|(" + AdditionalParameters.SelectionConditionsAfter + ") " + "And";
		EndIf;
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&TextOfSelectionConditionsAfter And", TextOfSelectionConditionsAfter);	
		
		FieldsNames = DefaultRequestFieldNames();
		FieldsNames.ExpressionBefore = "SUM(";
		FieldsNames.ExpressionAfter = ") <> 0 ";
		FieldsNames.CompoundExpression = "OR ";
		
		FieldsNames = DefaultRequestFieldNames();
		FieldsNames.ExpressionBefore = "SUM(";
		FieldsNames.CompoundExpression = "OR"+ " ";
		FieldsNames.ExpressionAfter = ") > &AllowableVariance" + " ";
		ControlFieldText1 = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames);
		FieldsNames.ExpressionAfter = ") < -&AllowableVariance" + " ";
		ControlFieldText2 = AddFieldsToRequest(FieldsStructure.NumericFields, FieldsNames);
		ControlFieldText = StrReplace(
			ControlFieldText1 + " OR " + ControlFieldText2,
			"&AllowableVariance",
			AdditionalParameters.AllowableVariance);
		
		If ValueIsFilled(ControlFieldText1) Then
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&ControlFieldText And", ControlFieldText + " " + "OR");
		Else
			FullTextOfRequest = StrReplace(FullTextOfRequest, "&ControlFieldText And", "");
		EndIf;
		
		FieldsNames = DefaultRequestFieldNames();
		FieldsNames.ExpressionBefore = "";
		FieldsNames.ExpressionAfter = " ";
		GroupIndexText = AddFieldsToRequest(DimensionsArray_, FieldsNames);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "&GroupIndexText,", GroupIndexText + ",");
		
		InternalConnectionToReference = InnerConnectionText(DimensionsArray_, "ReferenceMetadataObjectName");
		FullTextOfRequest = StrReplace(FullTextOfRequest, "WHERE &TextInternalConnectionToReference", InternalConnectionToReference);
		
		If AdditionalParameters.DetermineOverallDiscrepancy Then
			PatternOfDiscrepancies = " + SUM(CASE WHEN DD.%1 > 0 THEN DD.%1 ELSE -DD.%1 END)";
			TextSumOfDiscrepancies = "0";
			For Each Field In FieldsStructure.NumericFields Do
				TextSumOfDiscrepancies = TextSumOfDiscrepancies 
					+ StringFunctionsClientServer.SubstituteParametersToString(
						PatternOfDiscrepancies,
						Field);
			EndDo;
			RequestingDiscrepancies = "
			|SELECT TOP 5
			|	DD.Recorder AS Recorder,
			|	&TextSumOfDiscrepancies AS SumOfDiscrepancies,
			|	""MetadataObjectName"" AS RegisterName
			|FROM DiscrepancyFieldsMetadataObjectName AS DD
			|GROUP BY
			|	DD.Recorder
			|ORDER BY
			|	SumOfDiscrepancies DESC
			|;
			|/////////////////////////////////////////
			|";
			If AdditionalParameters.InCaseOfDiscrepanciesChooseFirst <> 5 Then
				RequestingDiscrepancies = StrReplace(RequestingDiscrepancies, "5", AdditionalParameters.InCaseOfDiscrepanciesChooseFirst);
			EndIf;
			If ExcludedFields.Property("Recorder") Then
				RequestingDiscrepancies = StrReplace(RequestingDiscrepancies, "Recorder", "DocumentRecorder");
			EndIf;
			RequestingDiscrepancies = StrReplace(RequestingDiscrepancies, "&TextSumOfDiscrepancies", TextSumOfDiscrepancies);
			FullTextOfRequest = FullTextOfRequest + RequestingDiscrepancies;
		EndIf;
		
		If FieldsToExpand.Count() > 0 Then
			InternalConnectionToResult = InnerConnectionText(ArrayOfDimensionsAfter, "MetadataObject", FieldClarification);
			For Each Field In FieldsToExpand Do
				InternalConnectionToResult = StrReplace(InternalConnectionToResult, "DD." + Field + ".", "DD." + Field);
			EndDo;
		Else
			InternalConnectionToResult = InnerConnectionText(DimensionsArray_, "MetadataObject", FieldClarification);
		EndIf;
		FullTextOfRequest = StrReplace(FullTextOfRequest, "WHERE &TextInternalConnectionToResult", InternalConnectionToResult);
		
		FullTextOfRequest = StrReplace(FullTextOfRequest, "FullMetadataObjectName", PathToMetadata);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "MetadataObjectName", RegisterName);
		FullTextOfRequest = StrReplace(FullTextOfRequest, "MetadataObject", PathToMetadataInRequest);
	EndIf;
	
	Return FullTextOfRequest;
	
EndFunction

// Function-constructor of the parameter structure for generating a comparison request
// 
// Returns:
// 	Structure - LongDesc:
// * DetermineOverallDiscrepancy - Boolean -
// * CheckChecksum - Boolean -
// * AllowableVariance - String -
// * SelectionConditionsAfter - String -
// * SelectionConditionsUpTo - String -
// * FieldsToExpand - Array -
// * GroupByDimensions - Boolean -
// * ReplacingFieldsAfter - Structure -
// * ReplacingFieldsBefore - Structure -
// * ExcludedFields - Structure -
// * InCaseOfDiscrepanciesChooseFirst - Number - when the flag is set, determine the total discrepancy controls how many first
// 		maximum discrepancies will be displayed when sampling discrepancies
//
Function AdditionalParametersForFormingComparisonRequest() Export
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ExcludedFields", New Structure);
	AdditionalParameters.Insert("ReplacingFieldsBefore", New Structure);
	AdditionalParameters.Insert("ReplacingFieldsAfter", New Structure);
	AdditionalParameters.Insert("GroupByDimensions", False);
	AdditionalParameters.Insert("FieldsToExpand", New Array);
	AdditionalParameters.Insert("SelectionConditionsUpTo", "");
	AdditionalParameters.Insert("SelectionConditionsAfter", "");
	AdditionalParameters.Insert("AllowableVariance", "0.02");
	AdditionalParameters.Insert("CheckChecksum", True);
	AdditionalParameters.Insert("DetermineOverallDiscrepancy", False);
	AdditionalParameters.Insert("SubordinateToRegistrar", True);
	AdditionalParameters.Insert("InCaseOfDiscrepanciesChooseFirst", 10);
	Return AdditionalParameters;
EndFunction

// The constructor function of the creation parameter structure of the query.
//
// Returns:
//	Structure - parameter structure:
// * BeginOfPeriod - Date -
// * EndOfPeriod - Date - 
// * ArrayOfLoggers - Array - 
// * SelectionByRegistrars - Boolean - 
//
Function QueryOptions(Month, ArrayOfLoggers = Undefined) Export
	
	QueryOptions = New Structure("BeginOfPeriod, EndOfPeriod, ArrayOfLoggers, SelectionByRegistrars");
	If Not ValueIsFilled(ArrayOfLoggers) Then // reinitialize the parameter so that the request does not fall
		QueryOptions.ArrayOfLoggers = New Array();
		QueryOptions.SelectionByRegistrars = False;
	Else
		QueryOptions.SelectionByRegistrars = True;
		QueryOptions.ArrayOfLoggers = ArrayOfLoggers;
	EndIf;
	If ValueIsFilled(Month) Then
		QueryOptions.BeginOfPeriod = BegOfMonth(Month);
		QueryOptions.EndOfPeriod = EndOfMonth(Month);
	Else
		QueryOptions.BeginOfPeriod = Date("00010101000000");
		QueryOptions.EndOfPeriod = Date("39991212235959");
	EndIf;
	
	Return QueryOptions;
EndFunction

Function RegistersWithServiceRegistrar() Export
	
	ReturnArray = New Array;
	
	ReturnArray.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName());
	ReturnArray.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.FullName());
	ReturnArray.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.FullName());
	ReturnArray.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments.FullName());
	ReturnArray.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.FullName());
	ReturnArray.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.FullName());
	
	Return ReturnArray;
	
EndFunction

// Returns the name of the registrar field for the register. For registers with a service registrar, "Document Registrar" will be returned,
//	if the register is an independent register of information, then "Batch" will be returned.
//
//	Parameters:
//		MetadataCollection - ConfigurationMetadataObject, String - the metadata object being analyzed or its full name
//			(as a rule, the Accumulation register or the register of information).
//
//	Returns:
//		String - the name of the logger field that should be used for this register.
//
Function NameOfRegisterRegistrarField(MetadataCollection) Export
	RecorderFieldName = "Recorder";
	FullRegisterName = ?(TypeOf(MetadataCollection) = Type("String"), MetadataCollection, MetadataCollection.FullName());
	If Testing.RegistersWithServiceRegistrar().Find(FullRegisterName) <> Undefined Then
		RecorderFieldName = "DocumentRecorder";
	ElsIf TypeOf(MetadataCollection) <> Type("String") And Metadata.InformationRegisters.Contains(MetadataCollection)
		And MetadataCollection.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
		RecorderFieldName = "Lot";
	EndIf;
	Return RecorderFieldName;
EndFunction

Function GetReferenceData() Export
	
	AdditionalParameters = AdditionalParametersForFormingComparisonRequest();
	TestingParameters = DataProcessors.TestingOfMonthEndClosingTransactions.TestStartupParameters();
	ComplianceOfControlRegisters = DataProcessors.TestingOfMonthEndClosingTransactions.ComplianceOfControlRegisters();
	
	QueryText = "";
	For Each ControlRegister In TestingParameters.ControlRegisters Do
		QueryText = QueryText + GenerateRequestToUploadData(ControlRegister, AdditionalParameters);
	EndDo; 
	
	Query = New Query;
	Query.Text = QueryText;
	PackageResult = Query.ExecuteBatch();
	
	ReferenceDataTables = New Map;
	Counter = 0;
	For Each ResultSelection In PackageResult Do
		
		RegisterName = TestingParameters.ControlRegisters[Counter];
		Upload0    = ResultSelection.Unload();
		
		ReferenceDataTables.Insert(RegisterName, Upload0);
		Counter = Counter + 1;
		
	EndDo; 
	
	Return ReferenceDataTables;
	
EndFunction

#EndRegion // Public

#Region Private

Function StructureOfCollectionFields(Collection, AddlParameters) Export
	
	ArrayOfNumericFields = New Array;
	ExceptionsList = ExceptionsList(AddlParameters.ExcludedFields);
	ThisIsBuhRegister = Common.IsAccountingRegister(Collection);
	Correspondence = ?(ThisIsBuhRegister, Collection.Correspondence, False);
	
	#Region Resources
	
	ArrayOfResources = New Array;
	
	For Each Field In Collection.Resources Do
		If Not ExceptionsList.Property(Field.Name) Then
			NumericTypeField = String(Field.Type) = String(New TypeDescription("Number",,,Field.Type.NumberQualifiers));
			ArrayToAdd = ?(NumericTypeField, ArrayOfNumericFields, ArrayOfResources);
			If Field.Type <> New TypeDescription("String") Then
				If ThisIsBuhRegister And Correspondence And Not Field.Balance Then
					ArrayToAdd.Add(Field.Name+"Dr");
					ArrayToAdd.Add(Field.Name+"Cr");
				Else
					ArrayToAdd.Add(Field.Name);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#Region Dimensions
	
	ArrayOfDimensions_ = New Array;
	
	For Each Field In Collection.Dimensions Do
		If Not ExceptionsList.Property(Field.Name) Then
			NumericTypeField = String(Field.Type) = String(New TypeDescription("Number",,,Field.Type.NumberQualifiers));
			ArrayToAdd = ?(Not AddlParameters.GroupByDimensions And NumericTypeField, ArrayOfNumericFields, ArrayOfDimensions_);
			If Field.Type <> New TypeDescription("String") Then
				If ThisIsBuhRegister And Correspondence And Not Field.Balance Then
					ArrayToAdd.Add(Field.Name+"Dr");
					ArrayToAdd.Add(Field.Name+"Cr");
				Else
					ArrayToAdd.Add(Field.Name);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If ThisIsBuhRegister Then
		ArrayToAdd.Insert(1, "Content");
	EndIf;
	
	#EndRegion
	
	#Region StandardAttributes
	
	RequiredStandardDetails = StrSplit("Period,Recorder,RecordType,Active", ",");
	
	For Each CurRegisterDetails In Collection.StandardAttributes Do
		
		AttributeOfRegister = CurRegisterDetails; // StandardAttributeDescription
		If Not ExceptionsList.Property(AttributeOfRegister.Name) And RequiredStandardDetails.Find(AttributeOfRegister.Name) <> Undefined Then
			
			ArrayOfDimensions_.Add(AttributeOfRegister.Name);
				
		EndIf;
		
	EndDo;
	
	If ThisIsBuhRegister Then
		// Adding an account and a sub-account:
		If Correspondence Then
			ArrayOfDimensions_.Add("AccountDr");
			ArrayOfDimensions_.Add("AccountCr");
			ArrayOfDimensions_.Add("ExtDimensionDr1");
			ArrayOfDimensions_.Add("ExtDimensionCr1");
			ArrayOfDimensions_.Add("ExtDimensionDr2");
			ArrayOfDimensions_.Add("ExtDimensionCr2");
			ArrayOfDimensions_.Add("ExtDimensionDr3");
			ArrayOfDimensions_.Add("ExtDimensionCr3");
		Else
			ArrayOfDimensions_.Add("RecordType");
			ArrayOfDimensions_.Add("Account");
			ArrayOfDimensions_.Add("ExtDimension1");
			ArrayOfDimensions_.Add("ExtDimension2");
			ArrayOfDimensions_.Add("ExtDimension3");
		EndIf;
	EndIf;
	
	#EndRegion
	
	#Region Attributes
	
	AttributesArray = New Array;
	
	For Each Field In Collection.Attributes Do
		If Not ExceptionsList.Property(Field.Name) Then
			NumericTypeField = String(Field.Type) = String(New TypeDescription("Number",,,Field.Type.NumberQualifiers));
			ArrayToAdd = ?(Not AddlParameters.GroupByDimensions And NumericTypeField, ArrayOfNumericFields, AttributesArray);
			If Field.Type <> New TypeDescription("String") Then
				ArrayToAdd.Add(Field.Name);
			EndIf;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#Region ReturnStructure
	
	FieldsStructure = New Structure;
	FieldsStructure.Insert("Dimensions", ArrayOfDimensions_);
	FieldsStructure.Insert("Attributes", AttributesArray);
	FieldsStructure.Insert("Resources", ArrayOfResources);
	FieldsStructure.Insert("NumericFields", ArrayOfNumericFields);
	
	#EndRegion
	
	Return FieldsStructure;
	
EndFunction

// Returns an array of fields to exclude when forming
// the query text.
Function ExceptionsList(ExcludedFields)
	ExceptionsList = New Structure;
	ExceptionsList.Insert("RowID", True);
	ExceptionsList.Insert("LineNumber", True);
	ExceptionsList.Insert("Comment", True);
	CommonClientServer.SupplementStructure(ExceptionsList,ExcludedFields);
	
	Return ExceptionsList;
EndFunction

Function GenerateRequestToUploadData(PathToMetadata, AdditionalParameters)
	
	MetadataCollection = Metadata.FindByFullName(PathToMetadata);
	RegisterName = MetadataCollection.Name;
	ThisIsBuhRegister = Common.IsAccountingRegister(MetadataCollection);
	// For the boom. we use a virtual table (to get a subconto):
	PathToMetadataInRequest = PathToMetadata + ?(ThisIsBuhRegister, ".RecordsWithExtDimensions", "");
	// For a virtual table, boom. the register may contain NULL values, we define them as UNDEFINED:
	FieldClarification = DefaultRequestFieldNames();
	If ThisIsBuhRegister Then
		FieldClarification.Insert("ExpressionBefore", "ISNULL(");
		FieldClarification.Insert("ExpressionAfter", ", Undefined)");
		FieldClarification.Insert("Alias");
	EndIf;
	
	FieldsStructure = Testing.StructureOfCollectionFields(MetadataCollection, AdditionalParameters);
	
	DimensionsArray_ = New Array;
	CommonClientServer.SupplementArray(DimensionsArray_, FieldsStructure.Dimensions, True);
	CommonClientServer.SupplementArray(DimensionsArray_, FieldsStructure.Resources, True);
	CommonClientServer.SupplementArray(DimensionsArray_, FieldsStructure.Attributes, True);
	
	MeasurementTextDetails = AddFieldsToRequest(DimensionsArray_, FieldClarification);
	
	If FieldsStructure.NumericFields.Count() > 0 Then
		FieldClarification.ExpressionAfter = StrReplace(FieldClarification.ExpressionAfter, "Undefined", "0");
		AmountText = AddFieldsToRequest(FieldsStructure.NumericFields, FieldClarification);
	Else
		AmountText = "";
	EndIf;
	
	NameOfRegistrar = NameOfRegisterRegistrarField(MetadataCollection);
	
	SortFields = New Array;
	If DimensionsArray_.Find("Period") <> Undefined Then
		SortFields.Add("DD.Period");
	EndIf;
	SortFields.Add("DD." + NameOfRegistrar);
	If DimensionsArray_.Find("Organization") <> Undefined Then
		SortFields.Add("DD.Organization");
	EndIf;
	TextOfSortField = StrConcat(SortFields, "," + Chars.LF + Chars.Tab);

	FullTextOfRequest = "
	|SELECT
	|	&MeasurementTextDetails,
	|   &AmountText,
	|	TRUE
	|FROM
	|	MetadataObject AS DD
	|ORDER BY
	|	DD.SortFields
	|;
	|///////////////////////////////////
	|";

	FullTextOfRequest = StrReplace(FullTextOfRequest, "&MeasurementTextDetails", MeasurementTextDetails);
	FullTextOfRequest = StrReplace(FullTextOfRequest, "&AmountText", AmountText);
	FullTextOfRequest = StrReplace(FullTextOfRequest, "MetadataObjectName", RegisterName);
	FullTextOfRequest = StrReplace(FullTextOfRequest, "MetadataObject", PathToMetadataInRequest);
	FullTextOfRequest = StrReplace(FullTextOfRequest, "DD.SortFields", TextOfSortField);
	
	Return FullTextOfRequest;
	
EndFunction

// Generates the internal connection text for the specified fields and source.
Function InnerConnectionText(FieldArray, SourceName, AdditionalRefinementOfSourceField = Undefined)
	
	If AdditionalRefinementOfSourceField = Undefined Then 
		AdditionalRefinementOfSourceField = DefaultRequestFieldNames();
	EndIf;
	
	Template = "INNER JOIN NameOfDataSource AS Table
	|ON ";
	InnerConnectionText = StrReplace(Template, "NameOfDataSource", SourceName);
	
	ThisIsBuhRegister = FieldArray.Find("ExtDimensionDr1") <> Undefined Or FieldArray.Find("ExtDimension1") <> Undefined;
	
	FirstRecord = True;
	For Each Field In FieldArray Do
		If ThisIsBuhRegister And ValueIsFilled(AdditionalRefinementOfSourceField.ExpressionAfter) Then
			// Bypassing the platform error (for non-currency accounts, the currency will be filled with an empty link after restructuring)
			If StrStartsWith(Field, "Currency") Then
				ExpressionAfter = ", VALUE(Catalog.Currencies.EmptyRef))";
			ElsIf StrStartsWith(Field, "Department") Then
				ExpressionAfter = ", VALUE(Catalog.BusinessStructure.EmptyRef))";
			ElsIf StrStartsWith(Field, "LineOfBusiness") Then
				ExpressionAfter = ", VALUE(Catalog.LinesOfBusiness.EmptyRef))";
			Else
				ExpressionAfter = AdditionalRefinementOfSourceField.ExpressionAfter;
			EndIf;
		Else
			ExpressionAfter = AdditionalRefinementOfSourceField.ExpressionAfter;
		EndIf;
		
		If ThisIsBuhRegister And Field = "RecordType" And ValueIsFilled(ExpressionAfter) Then
			SourceTableField = AdditionalRefinementOfSourceField.ExpressionBefore + "CASE
			|	WHEN Table.FieldName = VALUE(AccountingRecordType.Debit)
			|		THEN ""Debit""
			|	WHEN Table.FieldName = VALUE(AccountingRecordType.Credit)
			|		THEN ""Credit""
			|	ELSE """"
			|END" + ExpressionAfter;
		Else
			SourceTableField = AdditionalRefinementOfSourceField.ExpressionBefore + "Table.FieldName" + ExpressionAfter;
		EndIf;
		
		Template = "DD.FieldName = " + SourceTableField;
		TextBY = StrReplace(Template, "FieldName", Field);
		If Not FirstRecord Then
			TextBY = " And " + TextBY;
		EndIf;
		InnerConnectionText = InnerConnectionText + "
		| " + TextBY;
		FirstRecord = False;
	EndDo;
	Return InnerConnectionText;
EndFunction

Function DefaultRequestFieldNames()
	DefaultFieldNames = New Structure;
	DefaultFieldNames.Insert("ExpressionBefore", "");
	DefaultFieldNames.Insert("ExpressionAfter", "");
	DefaultFieldNames.Insert("CompoundExpression", ",");
	DefaultFieldNames.Insert("FieldName", "DD");
	
	Return DefaultFieldNames;
EndFunction

Function AddFieldsToRequest(FieldArray, FieldsNames = Undefined)
	If FieldsNames = Undefined Then 
		FieldsNames = DefaultRequestFieldNames();
	EndIf;
	FieldTexts = "";
	Counter = 1;
	Boundary = FieldArray.Count();
	ThisIsBuhRegister = FieldArray.Find("ExtDimensionDr1") <> Undefined Or FieldArray.Find("ExtDimension1") <> Undefined;
	For Each Field In FieldArray  Do
		If ThisIsBuhRegister And ValueIsFilled(FieldsNames.ExpressionAfter) Then
			// Bypassing the platform error (for non-currency accounts, the currency will be filled with an empty link after restructuring)
			If StrStartsWith(Field, "Currency") Then
				ExpressionAfter = ", VALUE(Catalog.Currencies.EmptyRef))";
			ElsIf StrStartsWith(Field, "Department") Then
				ExpressionAfter = ", VALUE(Catalog.BusinessStructure.EmptyRef))";
			ElsIf StrStartsWith(Field, "LineOfBusiness") Then
				ExpressionAfter = ", VALUE(Catalog.LinesOfBusiness.EmptyRef))";
			Else
				ExpressionAfter = FieldsNames.ExpressionAfter;
			EndIf;
		Else
			ExpressionAfter = FieldsNames.ExpressionAfter;
		EndIf;
		
		If ThisIsBuhRegister And Field = "RecordType" And ValueIsFilled(ExpressionAfter) Then
			FieldTexts = FieldTexts  + "
			|" + FieldsNames.ExpressionBefore + "CASE
			|	WHEN " + FieldsNames.FieldName + "." + Field + " = VALUE(AccountingRecordType.Debit)
			|		THEN ""Debit""
			|	WHEN " + FieldsNames.FieldName + "." + Field + " = VALUE(AccountingRecordType.Credit)
			|		THEN ""Credit""
			|	ELSE """"
			|END" + ExpressionAfter;
		Else
			FieldTexts = FieldTexts  + "
			|" + FieldsNames.ExpressionBefore + FieldsNames.FieldName + "." + Field + ExpressionAfter;
		EndIf;
		
		If FieldsNames.ExpressionAfter = "" Or FieldsNames.ExpressionAfter = ")" Or FieldsNames.Property("Alias") Then
			FieldTexts = FieldTexts + " AS "+ StrReplace(Field,".","");
		EndIf;
		If Counter < Boundary Then
			FieldTexts = FieldTexts + FieldsNames.CompoundExpression;
		EndIf;
		Counter = Counter + 1;
	EndDo;
	Return FieldTexts;
EndFunction

// check collection for the existence of the field "Period"
Function ThereIsPeriodInCollection(Collection)
	ThereIsPeriod = False;
	For Each CurItem In Collection.StandardAttributes Do
		Item = CurItem; // StandardAttributeDescription
		If Item.Name = "Period" Then
			ThereIsPeriod = True;
		EndIf;
	EndDo;
	Return ThereIsPeriod;
EndFunction

Procedure ExpandKeysFields(ArrayOfDimensions_, FieldsToExpand, ExcludedFields, GetFieldsSeparatedByPoint = False)
	
	For Each Field In FieldsToExpand Do
		ElementIndex = ArrayOfDimensions_.Find(Field);
		If ElementIndex <> Undefined Then
			ArrayOfDimensions_.Delete(ElementIndex);
		EndIf;
		For Each MetaAnalytics In Metadata.Catalogs.InventoryLocationAttributeKeys.Attributes Do
			FieldAlias = Field + MetaAnalytics.Name;
			If Not ExcludedFields.Property(FieldAlias) Then
				If GetFieldsSeparatedByPoint Then
					ArrayOfDimensions_.Add(Field + "." + MetaAnalytics.Name);
				Else
					ArrayOfDimensions_.Add(FieldAlias);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure ReplaceFields(SourceText, FieldReplacements, TableAlias = "DD")
	For Each KeyAndValue In FieldReplacements Do
		 SourceText = StrReplace(SourceText, TableAlias + "." + KeyAndValue.Key + " " + "AS",StrReplace(KeyAndValue.Value,"T.",TableAlias + ".") + " " + "AS");
	EndDo;
EndProcedure

#EndRegion // Private
