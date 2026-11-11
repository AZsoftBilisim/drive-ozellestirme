#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//  			registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Budgeting");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.SetValuesForNonFinancialItems") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	TablesForRegisteredRecords = New Structure;
	GenerateTableNonFinancialItemValues(TablesForRegisteredRecords, DocumentRef, Registers);
	
	Return TablesForRegisteredRecords;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.NonFinancialItemProfiles.TemplateIndicators AS TemplateIndicators
	|	ON TemplateIndicators.Ref = ThisList.InputTemplate
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(Scenario, EmptyRef AS TRUE)
	| AND ValueAllowed(Organization, EmptyRef AS TRUE)
	| AND ValueAllowed(Department, EmptyRef AS TRUE)
	| AND ValueAllowed(NonFinancialItem)
	| AND ForAllRows(ValueAllowed(TemplateIndicators.Factor))";

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

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
EndProcedure

// Adds a command to create a document "Value of non-financial indicators".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.SetValuesForNonFinancialItems) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SetValuesForNonFinancialItems.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
			Metadata.Documents.SetValuesForNonFinancialItems);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseBudgeting";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#Region FormationOfDocumentForm

Function TypeOfDocumentFormPeriod(Parameter_Template, TempTableManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text = 
		"SELECT ALLOWED
		|	NonFinancialItemsOfBudgets.SetAValueForEachPeriod
		|INTO ValueForEachPeriod
		|FROM
		|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
		|WHERE
		|	(NonFinancialItemsOfBudgets.Ref = &Ref
		|			OR NonFinancialItemsOfBudgets.Ref IN
		|				(SELECT TOP 1
		|					Filter.Factor
		|				FROM
		|					TemplateIndicators_ AS Filter))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN VALUETYPE(&Ref) = TYPE(Catalog.NonFinancialItemsOfBudgets)
		|			THEN TRUE
		|		WHEN NOT HeaderTemplates_.DimensionName IS NULL
		|				OR StringPatterns.DimensionName IS NULL
		|					AND ColumnTemplates.DimensionName IS NULL
		|			THEN TRUE
		|	END AS InHeader,
		|	CASE
		|		WHEN VALUETYPE(&Ref) = TYPE(Catalog.NonFinancialItemsOfBudgets)
		|			THEN FALSE
		|		WHEN NOT StringPatterns.DimensionName IS NULL
		|			THEN TRUE
		|	END AS InStrings,
		|	CASE
		|		WHEN VALUETYPE(&Ref) = TYPE(Catalog.NonFinancialItemsOfBudgets)
		|			THEN FALSE
		|		WHEN NOT ColumnTemplates.DimensionName IS NULL
		|			THEN TRUE
		|	END AS InColumns
		|INTO Period
		|FROM
		|	(SELECT
		|		TRUE AS TemporaryValue) AS TimeLine_
		|		LEFT JOIN EditTemplateInHeader AS HeaderTemplates_
		|		ON (HeaderTemplates_.DimensionName = ""Period"")
		|		LEFT JOIN EditTemplateInLines AS StringPatterns
		|		ON (StringPatterns.DimensionName = ""Period"")
		|		LEFT JOIN EditTemplateInColumns AS ColumnTemplates
		|		ON (ColumnTemplates.DimensionName = ""Period"")
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN Period.InHeader
		|			THEN CASE
		|					WHEN ValueForEachPeriod.SetAValueForEachPeriod
		|						THEN ""Period""
		|					ELSE ""ValidFrom""
		|				END
		|		WHEN Period.InColumns
		|			THEN CASE
		|					WHEN ValueForEachPeriod.SetAValueForEachPeriod
		|						THEN ""Period""
		|				END
		|		WHEN Period.InStrings
		|			THEN ""None""
		|	END AS PeriodDetails
		|FROM
		|	Period AS Period
		|		INNER JOIN ValueForEachPeriod AS ValueForEachPeriod
		|		ON (TRUE)";
		
	If TypeOf(Parameter_Template) = Type("Structure") Then
		Query.SetParameter("Ref", Undefined);
	Else
		Query.SetParameter("Ref", Parameter_Template);
	EndIf;

	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();
	
	If Not ValueIsFilled(SelectionDetailRecords.PeriodDetails) Then
		Raise NStr("vi = 'Mẫu không hợp lệ: cài đặt tần số không nhất quán';
					|ru = 'Неверный шаблон: несогласованные настройки периодичности';
					|en = 'Incorrect template: unapproved frequency settings'; fa = 'Incorrect template: unapproved frequency settings';
					|it = 'Modello errato: impostazioni di periodicità non concordate';
					|pl = 'Niepoprawny szablon: nieuzgodnione ustawienia częstotliwości';
					|tr = 'Geçersiz şablon: uyumsuz sıklık ayarları'");
	EndIf;
	
	Return SelectionDetailRecords.PeriodDetails;
	
EndFunction

Function AddHeaderField(FieldList, Name, Presentation, ValueType)
	
	Field = New Structure();
	Field.Insert("Name", Name);
	Field.Insert("Presentation", Presentation);
	Field.Insert("ValueType", ValueType);
	
	FieldList.Add(Field);
	
	Return Field;
	
EndFunction

Function ColumnType(Dimension)
	
	If Dimension.DimensionName = "Organization" Then 
		Return New TypeDescription("CatalogRef.Companies");
	ElsIf Dimension.DimensionName = "Department" Then 
		Return New TypeDescription("CatalogRef.BusinessStructure");
	ElsIf Dimension.DimensionName = "Scenario" Then 
		Return New TypeDescription("CatalogRef.BudgetingScenarios");
	ElsIf Dimension.DimensionName = "Dimension" Then
		Return Dimension.ValueType;
	ElsIf Dimension.DimensionName = "SubperiodNumber" Then
		Return Common.TypeDescriptionNumber(3, 0);
	ElsIf Dimension.DimensionName = "Period" Then
		Return New TypeDescription("Date",,,New DateQualifiers(DateFractions.Date));
	Else
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Mẫu không hợp lệ: không xác định đơn vị tính ""%1""';
				|ru = 'Неверный шаблон: неизвестное измерение ""%1""';
				|en = 'Incorrect template: unknown dimension ""%1""'; fa = 'Incorrect template: unknown dimension ""%1""';
				|it = 'Modello non corretto: dimensione sconosciuta ""%1""';
				|pl = 'Nieprawidłowy szablon: nieznany pomiar ""%1""';
				|tr = 'Geçersiz şablon: boyut belirsiz ""%1""'"),
			Dimension.DimensionName);
		Raise ExceptionText;
	EndIf;
	
EndFunction

Function TextOfRequestToCalculateAnalyticsNumber()
	
	QueryText =
	"SELECT TOP 1
	|	&TextOfAnalyticsViewFields
	|INTO DimensionIndicator_
	|FROM
	|	TemplateIndicators_ AS TemplateIndicators_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HeaderParameters_.Dimension,
	|	HeaderParameters_.DimensionName AS DimensionName,
	|	CASE
	|		WHEN HeaderParameters_.DimensionName = ""Dimension""
	|			THEN &TextOfAnalyticsNumber
	|		ELSE """"
	|	END AS Postfix,
	|	HeaderParameters_.Dimension.ValueType AS ValueType,
	|	HeaderParameters_.Presentation
	|FROM
	|	HeaderParameters_ AS HeaderParameters_
	|		LEFT JOIN DimensionIndicator_ AS DimensionIndicator_
	|		ON (TRUE)";
	
	TextOfAnalyticsViewFields = "";
	TextOfAnalyticsNumber = "";
	AnalyticsNumberConditionTemplate =
	"					WHEN HeaderParameters_.Dimension = DimensionIndicator_.DimensionKind%1
	|						THEN ""%1""";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfAnalyticsViewFields = TextOfAnalyticsViewFields
			+ ?(TextOfAnalyticsViewFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"TemplateIndicators_.Factor.DimensionKind%1 AS DimensionKind%1",
				DimensionNumber);
		
		TextOfAnalyticsNumber = TextOfAnalyticsNumber + ?(TextOfAnalyticsNumber = "", "", Chars.LF)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				AnalyticsNumberConditionTemplate,
				DimensionNumber);
	EndDo;
	TextOfAnalyticsNumber = "CASE" + Chars.LF
	+ TextOfAnalyticsNumber + "
	|				END"; // @query-part-1
	
	QueryText = StrReplace(QueryText, "&TextOfAnalyticsViewFields", TextOfAnalyticsViewFields);
	QueryText = StrReplace(QueryText, "&TextOfAnalyticsNumber", TextOfAnalyticsNumber);
	
	QueryText =
	"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + QueryText;
	
	Return QueryText;
	
EndFunction

Function ListOfHeaderFields(IndicatorTemplate, TempTableManager)
	
	FieldList = New Array;
	
	If TypeOf(IndicatorTemplate) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		Fields = "NumberOfUsedDimensions, ByCompanies, ByBusinessUnits, ByScenarios";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			Fields = Fields + ", DimensionKind" + DimensionNumber + ", "
				+ "DimensionKind" + DimensionNumber + ".Presentation" + ", "
				+ "DimensionKind" + DimensionNumber + ".ValueType";
		EndDo;
		
		AttributesValues = Common.ObjectAttributesValues(IndicatorTemplate, Fields);
		
		TraversedFields = New Array;
		If AttributesValues.ByCompanies Then
			HeaderField = AddHeaderField(FieldList,
				"Organization",
				BudgetReportingClientServer.PresentationOfBudgetingDimension("Organization"),
				New TypeDescription("CatalogRef.Companies"));
			TraversedFields.Add(HeaderField);
		EndIf;
		
		If AttributesValues.ByBusinessUnits Then
			HeaderField = AddHeaderField(FieldList,
				"Department",
				BudgetReportingClientServer.PresentationOfBudgetingDimension("Department"),
				New TypeDescription("CatalogRef.BusinessStructure"));
			TraversedFields.Add(HeaderField);
		EndIf;
		
		If AttributesValues.ByScenarios Then
			HeaderField = AddHeaderField(FieldList,
				"Scenario",
				BudgetReportingClientServer.PresentationOfBudgetingDimension("Scenario"),
				New TypeDescription("CatalogRef.BudgetingScenarios"));
			TraversedFields.Add(HeaderField);
		EndIf;
		
		TypeRelationships = FinancialReportingCached.MatchingSelectionsByOwner();
		For Cnt = 1 To AttributesValues.NumberOfUsedDimensions Do
			Field = AddHeaderField(FieldList,
			                         "Dimension" + Cnt, 
			                         AttributesValues["DimensionKind" + Cnt + "Presentation"],
			                         AttributesValues["DimensionKind" + Cnt + "ValueType"]);
			
			TypeOwners = Undefined;
			For Each Type In Field.ValueType.Types() Do
				TypeOwners = TypeRelationships[Type];
				If TypeOwners <> Undefined Then
					Break;
				EndIf;
			EndDo;
			
			If TypeOwners <> Undefined Then
				For Each PassedField In TraversedFields Do
					For Each TypeOwner In TypeOwners Do
						If PassedField.ValueType.ContainsType(TypeOwner.Type) Then
							TypeStructure = New Structure("Column, Filter", PassedField.Name, TypeOwner.Attribute);
							Field.Insert("ChoiceParameterLinks", TypeStructure);
						EndIf;
					EndDo;
				EndDo;
			EndIf;
			
			// There is an algorithm for the values of additional details, since the owner does not explicitly specify in the document form.
			If Field.ValueType = New TypeDescription("CatalogRef.ObjectsPropertiesValues") Then
				AdditionalProperty = Common.ObjectAttributeValue(AttributesValues["DimensionKind" + Cnt], "AdditionalProperty");
				
				TypeStructure = New Structure("Filter, Value", "Owner", AdditionalProperty);
				Field.Insert("ChoiceParameters", TypeStructure);
			EndIf;
			
			TraversedFields.Add(Field);
		EndDo;
		
		Return FieldList;
		
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.Dimension,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.DimensionName,
	|	CASE
	|		WHEN TemplatesForEnteringNonFinancialIndicatorsEditInHeader.DimensionName = ""Dimension""
	|			THEN TemplatesForEnteringNonFinancialIndicatorsEditInHeader.Dimension.Presentation
	|		ELSE TemplatesForEnteringNonFinancialIndicatorsEditInHeader.DimensionName
	|	END AS Presentation
	|INTO HeaderParameters_
	|FROM
	|	EditTemplateInHeader AS TemplatesForEnteringNonFinancialIndicatorsEditInHeader
	|" + TextOfRequestToCalculateAnalyticsNumber();
	
	Query.TempTablesManager = TempTableManager;
	Query.SetParameter("Ref", IndicatorTemplate);
	CapMeasurements = Query.Execute().Select();
	DestroyAuxiliaryTables(Query);
	
	TraversedFields = New Array;
	TypeRelationships = FinancialReportingCached.MatchingSelectionsByOwner();
	
	While CapMeasurements.Next() Do
		
		If CapMeasurements.DimensionName = "Period" Then
			Continue; //the period is processed separately
		EndIf;
		
		Field = AddHeaderField(FieldList,
				CapMeasurements.DimensionName + CapMeasurements.Postfix,
				?(CapMeasurements.DimensionName = "Scenario"
				Or CapMeasurements.DimensionName = "Organization"
				Or CapMeasurements.DimensionName = "Department",
				BudgetReportingClientServer.PresentationOfBudgetingDimension(CapMeasurements.DimensionName),
				CapMeasurements.Presentation),
				ColumnType(CapMeasurements));
		
		TypeOwners = Undefined;
		For Each Type In Field.ValueType.Types() Do
			TypeOwners = TypeRelationships[Type];
			If TypeOwners <> Undefined Then
				Break;
			EndIf;
		EndDo;
		
		If TypeOwners <> Undefined Then
			For Each PassedField In TraversedFields Do
				For Each TypeOwner In TypeOwners Do
					If PassedField.ValueType.ContainsType(TypeOwner.Type) Then
						TypeStructure = New Structure("Column, Filter", PassedField.Name, TypeOwner.Attribute);
						Field.Insert("ChoiceParameterLinks", TypeStructure);
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		
		TraversedFields.Add(Field);
		
	EndDo;
	
	Return FieldList
	
EndFunction

Function EditableColumns(IndicatorTemplate, TempTableManager)
	
	FieldList = New Array;
	If TypeOf(IndicatorTemplate) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		If Common.ObjectAttributeValue(IndicatorTemplate, "ByPeriods") Then
			AddHeaderField(FieldList,
				"SubperiodNumber",
				BudgetReportingClientServer.PresentationOfBudgetingDimension("SubperiodNumber"),
				Common.TypeDescriptionNumber(3, 0));
		EndIf;
		Return FieldList;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.Dimension,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.DimensionName,
	|	CASE
	|		WHEN TemplatesForEnteringNonFinancialIndicatorsEditInLines.DimensionName = ""SubperiodNumber""
	|			THEN &SubperiodNumberPresentation
	|		WHEN TemplatesForEnteringNonFinancialIndicatorsEditInLines.DimensionName = ""Dimension""
	|			THEN TemplatesForEnteringNonFinancialIndicatorsEditInLines.Dimension.Presentation
	|		ELSE TemplatesForEnteringNonFinancialIndicatorsEditInLines.DimensionName
	|	END AS Presentation
	|INTO HeaderParameters_
	|FROM
	|	EditTemplateInLines AS TemplatesForEnteringNonFinancialIndicatorsEditInLines
	|" + TextOfRequestToCalculateAnalyticsNumber();
	
	Query.TempTablesManager = TempTableManager;
	Query.SetParameter("SubperiodNumberPresentation",
		BudgetReportingClientServer.PresentationOfBudgetingDimension("SubperiodNumber"));
	Query.SetParameter("Ref", IndicatorTemplate);
	ColumnDimensions = Query.Execute().Select();
	DestroyAuxiliaryTables(Query);
	
	TraversedFields = New Array;
	TypeRelationships = FinancialReportingCached.MatchingSelectionsByOwner();
	
	While ColumnDimensions.Next() Do
		
		Field = AddHeaderField(FieldList,
				ColumnDimensions.DimensionName + ColumnDimensions.Postfix,
				?(ColumnDimensions.DimensionName = "Scenario"
				Or ColumnDimensions.DimensionName = "Organization"
				Or ColumnDimensions.DimensionName = "Department",
				BudgetReportingClientServer.PresentationOfBudgetingDimension(ColumnDimensions.DimensionName),
				ColumnDimensions.Presentation),
				ColumnType(ColumnDimensions));
		Field.Insert("Dimension", ColumnDimensions.Dimension);
		
		TypeOwners = Undefined;
		For Each Type In Field.ValueType.Types() Do
			TypeOwners = TypeRelationships[Type];
			If TypeOwners <> Undefined Then
				Break;
			EndIf;
		EndDo;
		
		If TypeOwners <> Undefined Then
			For Each PassedField In TraversedFields Do
				For Each TypeOwner In TypeOwners Do
					If PassedField.ValueType.ContainsType(TypeOwner.Type) Then
						TypeStructure = New Structure("Column, Filter", PassedField.Name, TypeOwner.Attribute);
						Field.Insert("ChoiceParameterLinks", TypeStructure);
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		
		// There is an algorithm for the values of additional details, since the owner does not explicitly specify in the document form.
		If Field.ValueType = New TypeDescription("CatalogRef.ObjectsPropertiesValues") Then
			AdditionalProperty = Common.ObjectAttributeValue(Field.Dimension, "AdditionalProperty");
			
			TypeStructure = New Structure("Filter, Value", "Owner", AdditionalProperty);
			Field.Insert("ChoiceParameters", TypeStructure);
		EndIf;
			
		TraversedFields.Add(Field);
	EndDo;
	
	Return FieldList
	
EndFunction

Function AddTreeRow(PlaceAdded, Dimension, Value, AccumulatedSelection, Cache, PeriodicityParameters, LastLevel)
	
	NewTreeRow = PlaceAdded.Add();
	If BudgetReportingClientServer.LeftPartOfNameMatches(Value, "Currency_") Then
		NewTreeRow.Name = Value;
	ElsIf BudgetReportingClientServer.LeftPartOfNameMatches(Value, "Ed_") Then
		NewTreeRow.Name = Value;
	Else
		NewTreeRow.Name = Dimension.DimensionName + "_" + StrReplace(New UUID, "-", "_");
	EndIf;
	
	If Value = Undefined Then
		NewTreeRow.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '<không được chỉ định ""%1"">';
				|ru = '<не указаны ""%1"">';
				|en = '<""%1"" are not specified>'; fa = '<""%1"" are not specified>';
				|it = '<non indicati ""%1"">';
				|pl = '<nie podano ""%1"">';
				|tr = '<belirtilmeyen ""%1"">'"),
			Dimension.Presentation);
	Else
		If TypeOf(Value) = Type("Number") Then //period number
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Phân kỳ %1';
																					|ru = 'Подпериод %1';
																					|en = 'Subperiod %1'; fa = 'Subperiod %1';
																					|it = 'Subperiod %1';
																					|pl = 'Subperiod %1';
																					|tr = '%1 alt dönem'"), Value);
		ElsIf TypeOf(Value) = Type("Date") Then //period number
			Title = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(
				Value,
				PeriodicityParameters.Periodicity);
		ElsIf TypeOf(Value) = Type("String") And Value = "PeriodNotSpecified" Then
			Title = NStr("vi = 'Chưa chỉ ra kỳ';
						|ru = 'Период не указан';
						|en = 'Period is not specified'; fa = 'Period is not specified';
						|it = 'Periodo non indicato';
						|pl = 'Okres nie podano';
						|tr = 'Dönem belirtilmedi'");
		ElsIf BudgetReportingClientServer.LeftPartOfNameMatches(Value, "Currency_") Then
			Title = NStr("vi = 'Tiền tệ';
						|ru = 'Валюта';
						|en = 'Currency'; fa = 'ارز';
						|it = 'Valuta';
						|pl = 'Waluta';
						|tr = 'Para birimi'");
		ElsIf BudgetReportingClientServer.LeftPartOfNameMatches(Value, "Ed_") Then
			Title = NStr("vi = 'Đơn vị tính';
						|ru = 'Ед. изм.';
						|en = 'Unit'; fa = 'واحد';
						|it = 'Unità di misura';
						|pl = 'J. m.';
						|tr = 'Ölçü birimi'");
		ElsIf TypeOf(Value) = Type("String") And Value = "Value" Then
			Title = NStr("vi = 'Giá trị';
						|ru = 'Значение';
						|en = 'Value'; fa = 'مقدار';
						|it = 'Valore';
						|pl = 'Wartość';
						|tr = 'Değer'");
		Else
			Title = Cache.Find(Value, "Value").Presentation;
		EndIf;
		NewTreeRow.Title = Title;
	EndIf;
	
	If LastLevel Then
		NewTreeRow.AccumulatedSelection = Common.CopyRecursive(AccumulatedSelection);
	EndIf;
	
	Return NewTreeRow;
	
EndFunction

Function AdditionalColumns(IndicatorLine_1)
	
	CurrencyRequired = False; UnitOfMeasurementRequired = False;
	If IndicatorLine_1.IndicatorKind = Enums.NonFinancialItemKinds.Cash_ Then
		CurrencyRequired = True;
	ElsIf IndicatorLine_1.IndicatorKind = Enums.NonFinancialItemKinds.Quantitative Then
		If IndicatorLine_1.UnitOfMeasureIsDeterminedByDimension Then
			UnitOfMeasurementRequired = True;
		EndIf;
	EndIf;
	
	Return New Structure("CurrencyRequired, UnitOfMeasurementRequired", CurrencyRequired, UnitOfMeasurementRequired);
	
EndFunction

Procedure FillColumnTree(TreeParameters, PlaceAdded, AccumulatedSelection = Undefined, Level = 0)
	
	ColumnsTable1 = TreeParameters.ColumnsTable1;
	ColumnValues = TreeParameters.ColumnValues;
	Cache = TreeParameters.Cache;
	Indicators = TreeParameters.Indicators;
	PeriodicityParameters = TreeParameters.PeriodicityParameters;
	PeriodParameters_ = TreeParameters.PeriodParameters_;
	
	If AccumulatedSelection = Undefined Then
		AccumulatedSelection = New Structure;
	EndIf;
	
	If Level = ColumnsTable1.Count() Then
		If Indicators <> Undefined Then
			
			ColumnDetails = New Structure("DimensionName", "NonFinancialItem");
			DonTAddMetricColumn = False;
			If Indicators.Count() = 1 Then
				AdditionalColumns = AdditionalColumns(Indicators[0]);
				If ValueIsFilled(PlaceAdded.Parent) Or 
					(AdditionalColumns.CurrencyRequired Or AdditionalColumns.UnitOfMeasurementRequired) Then
					DonTAddMetricColumn = True;
				EndIf;
			EndIf;
			
			If DonTAddMetricColumn Then
				
				Factor = Indicators[0].Factor;
				ThereWillBeMoreColumns = AdditionalColumns.CurrencyRequired Or AdditionalColumns.UnitOfMeasurementRequired;
				
				AccumulatedSelection.Insert("NonFinancialItem", Factor);
				If Not ThereWillBeMoreColumns Then
					PlaceAdded.Parent.AccumulatedSelection = Common.CopyRecursive(AccumulatedSelection);
				Else
					NewRow = AddTreeRow(PlaceAdded,
							ColumnDetails,
							"Value",
							AccumulatedSelection,
							Cache,
							PeriodicityParameters,
							True);
					If AdditionalColumns.CurrencyRequired Then
						RowCurrency = AddTreeRow(PlaceAdded,
								ColumnDetails,
								"Currency_" + NewRow.Name,
								AccumulatedSelection,
								Cache,
								PeriodicityParameters,
								True);
						If Indicators[0].CurrencyIsDeterminedByDimension Then
							RowCurrency.ReadOnly = True;
						EndIf;
					EndIf;
					If AdditionalColumns.UnitOfMeasurementRequired Then
						TreeLineUnitOfISM = AddTreeRow(PlaceAdded,
								ColumnDetails,
								"Ed_" + NewRow.Name,
								AccumulatedSelection,
								Cache,
								PeriodicityParameters,
								True);
						
						TreeLineUnitOfISM.ReadOnly = True;
					EndIf;
						
				EndIf;
				
			Else
				
				For Each IndicatorLine_1 In Indicators Do
					
					Factor = IndicatorLine_1.Factor;
					AccumulatedSelection.Insert(ColumnDetails.DimensionName, Factor);
					
					AdditionalColumns = AdditionalColumns(IndicatorLine_1);
					ThereWillBeMoreColumns = AdditionalColumns.CurrencyRequired Or AdditionalColumns.UnitOfMeasurementRequired;
					
					NewRow = AddTreeRow(PlaceAdded,
							ColumnDetails,
							Factor,
							AccumulatedSelection,
							Cache,
							PeriodicityParameters,
							Not ThereWillBeMoreColumns);
					
					If ThereWillBeMoreColumns Then
						AddTreeRow(NewRow.Rows,
								ColumnDetails,
								"Value",
								AccumulatedSelection,
								Cache,
								PeriodicityParameters,
								True);
						If AdditionalColumns.CurrencyRequired Then
							AddTreeRow(NewRow.Rows,
									ColumnDetails,
									"Currency_" + NewRow.Name,
									AccumulatedSelection,
									Cache,
									PeriodicityParameters,
									True);
						EndIf;
						If AdditionalColumns.UnitOfMeasurementRequired Then
							AddTreeRow(NewRow.Rows,
									ColumnDetails,
									"Ed_" + NewRow.Name,
									AccumulatedSelection,
									Cache,
									PeriodicityParameters,
									True);
						EndIf;
					EndIf;
					
				EndDo;
				
			EndIf;
		EndIf;
		Return;
	EndIf;
	
	LastLevel = Level = ColumnsTable1.Count() - 1 And Indicators = Undefined;
	
	ColumnDetails = ColumnsTable1[Level];
	
	If ColumnDetails.DimensionName = "SubperiodNumber" Then
	
		FoundValues = New Array;
		NumberOfPeriods = Enums.Periodicity.NumberOfPeriods(PeriodicityParameters.Periodicity,
			PeriodicityParameters.SubperiodFrequency);
		
		For Cnt = 1 To NumberOfPeriods Do
			FoundValues.Add(New Structure("Value", Cnt));
		EndDo;
		
	ElsIf ColumnDetails.DimensionName = "Period" Then
		
		FoundValues = New Array;
		If Not ValueIsFilled(PeriodParameters_.BeginOfPeriod)
			Or Not ValueIsFilled(PeriodParameters_.PeriodEnding) Then
			
			FoundValues.Add(New Structure("Value", "PeriodNotSpecified"));
			
		Else
			
			BeginOfPeriod = PeriodParameters_.BeginOfPeriod;
			While BeginOfPeriod < PeriodParameters_.PeriodEnding Do
				FoundValues.Add(New Structure("Value", BeginOfPeriod));
				BeginOfPeriod = WorkingWithClientServerPeriods.AddInterval(BeginOfPeriod, PeriodicityParameters.Periodicity, 1);
			EndDo;
			
		EndIf;
		
	Else
		
		ValueSearchStructure = New Structure("DimensionName, Dimension");
		FillPropertyValues(ValueSearchStructure, ColumnDetails);
		FoundValues = ColumnValues.FindRows(ValueSearchStructure);
	
	EndIf;
	
	DimensionName = ColumnDetails.DimensionName + ColumnDetails.Postfix;
	
	If Not FoundValues.Count() Then
		
		AccumulatedSelection.Insert(DimensionName, Undefined);
		NewRow = AddTreeRow(PlaceAdded,
				ColumnDetails,
				Undefined,
				AccumulatedSelection,
				Cache,
				PeriodParameters_,
				LastLevel);
		
		FillColumnTree(TreeParameters, NewRow.Rows, AccumulatedSelection, Level + 1);
		
	EndIf;
	
	For Each ValueFound In FoundValues Do
		
		Value = ValueFound.Value;
		AccumulatedSelection.Insert(DimensionName, Value);
		NewRow = AddTreeRow(PlaceAdded,
				ColumnDetails,
				Value,
				AccumulatedSelection,
				Cache,
				PeriodicityParameters,
				LastLevel);
		
		FillColumnTree(TreeParameters, NewRow.Rows, AccumulatedSelection, Level + 1);
		
	EndDo;
	
EndProcedure

Function PropertiesOfIndicators(IndicatorTemplate, TempTableManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	If TypeOf(IndicatorTemplate) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		Query.Text = "SELECT ALLOWED
		|	TemplateIndicators.Ref AS Factor,
		|	TemplateIndicators.SubperiodFrequency AS SubperiodFrequency,
		|	TemplateIndicators.Periodicity AS Periodicity,
		|	TemplateIndicators.DimensionCurrencies AS DimensionCurrencies,
		|	TemplateIndicators.DimensionUnitsOfMeasurement AS DimensionUnitsOfMeasurement,
		|	TemplateIndicators.UnitOfMeasure AS UnitOfMeasure,
		|	TemplateIndicators.UnitOfMeasureIsDeterminedByDimension AS UnitOfMeasureIsDeterminedByDimension,
		|	TemplateIndicators.DimensionAddressCurrency AS DimensionAddressCurrency,
		|	TemplateIndicators.QuantityDimensionAddress AS QuantityDimensionAddress,
		|	TemplateIndicators.CurrencyIsDeterminedByDimension AS CurrencyIsDeterminedByDimension,
		|	TemplateIndicators.IndicatorKind,
		|	TemplateIndicators.DimensionCurrencies.CurrencyFilling AS CurrencyFilling,
		|	TemplateIndicators.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS UnitOfMeasureFilling
		|FROM
		|	Catalog.NonFinancialItemsOfBudgets AS TemplateIndicators
		|WHERE
		|	TemplateIndicators.Ref = &Ref";
		Query.SetParameter("Ref", IndicatorTemplate);
		Indicators = Query.Execute().Unload();
	Else
		Query.Text = "SELECT ALLOWED
		|	TemplateIndicators.Factor,
		|	TemplateIndicators.Factor.IndicatorKind AS IndicatorKind,
		|	TemplateIndicators.Factor.SubperiodFrequency AS SubperiodFrequency,
		|	TemplateIndicators.Factor.Periodicity AS Periodicity,
		|	TemplateIndicators.Factor.DimensionCurrencies AS DimensionCurrencies,
		|	TemplateIndicators.Factor.DimensionUnitsOfMeasurement AS DimensionUnitsOfMeasurement,
		|	TemplateIndicators.Factor.UnitOfMeasure AS UnitOfMeasure,
		|	TemplateIndicators.Factor.UnitOfMeasureIsDeterminedByDimension AS UnitOfMeasureIsDeterminedByDimension,
		|	TemplateIndicators.Factor.DimensionAddressCurrency AS DimensionAddressCurrency,
		|	TemplateIndicators.Factor.QuantityDimensionAddress AS QuantityDimensionAddress,
		|	TemplateIndicators.Factor.CurrencyIsDeterminedByDimension AS CurrencyIsDeterminedByDimension,
		|	TemplateIndicators.Factor.DimensionCurrencies.CurrencyFilling AS CurrencyFilling,
		|	TemplateIndicators.Factor.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS UnitOfMeasureFilling
		|FROM
		|	TemplateIndicators_ AS TemplateIndicators";
		Indicators = Query.Execute().Unload();
	EndIf;
	
	Return Indicators;
	
EndFunction

Procedure DestroyAuxiliaryTables(Query)
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, "HeaderParameters_,DimensionIndicator_");
	
EndProcedure

Function TreeOfHeaderColumns(IndicatorTemplate, ColumnValues, PropertiesOfIndicators, PeriodParameters_, TempTableManager)
	
	ColumnTree = New ValueTree;
	ColumnTree.Columns.Add("Name");
	ColumnTree.Columns.Add("Title");
	ColumnTree.Columns.Add("AccumulatedSelection");
	ColumnTree.Columns.Add("ReadOnly");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Dimension,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.DimensionName,
	|	CASE
	|		WHEN TemplatesForEnteringNonFinancialIndicatorsEditInColumns.DimensionName = ""Dimension""
	|			THEN TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Dimension.Presentation
	|		ELSE TemplatesForEnteringNonFinancialIndicatorsEditInColumns.DimensionName
	|	END AS Presentation,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Dimension.ValueType AS ValueType
	|INTO HeaderParameters_
	|FROM
	|	EditTemplateInColumns AS TemplatesForEnteringNonFinancialIndicatorsEditInColumns
	|" + TextOfRequestToCalculateAnalyticsNumber();
	
	Query.TempTablesManager = TempTableManager;
	
	If TypeOf(IndicatorTemplate) = Type("Structure") Then
		Query.SetParameter("Ref", Undefined);
	Else
		Query.SetParameter("Ref", IndicatorTemplate);
	EndIf;
	ColumnsTable1 = Query.Execute().Unload();
	DestroyAuxiliaryTables(Query);
	
	Query.Text =
	"SELECT
	|	TableValue.Value AS Value
	|INTO TempTable
	|FROM
	|	&Values AS TableValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TempTable.Value
	|INTO AllValuesForPresentationDefinition
	|FROM
	|	TempTable AS TempTable
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Factor
	|FROM
	|	TemplateIndicators_ AS TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	NonFinancialItemsOfBudgets.Ref
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|WHERE
	|	NonFinancialItemsOfBudgets.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	AllValuesForPresentationDefinition.Value,
	|	NonFinancialItemsOfBudgets.Ref AS NFP,
	|	NonFinancialItemsOfBudgets.Description,
	|	NonFinancialItemsOfBudgets.IndicatorKind,
	|	NonFinancialItemsOfBudgets.UnitOfMeasureIsDeterminedByDimension,
	|	NonFinancialItemsOfBudgets.UnitOfMeasure.Description AS UnitOfMeasure
	|INTO AllIndicators
	|FROM
	|	AllValuesForPresentationDefinition AS AllValuesForPresentationDefinition
	|		LEFT JOIN Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|		ON AllValuesForPresentationDefinition.Value = NonFinancialItemsOfBudgets.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllIndicators.Value,
	|	AllIndicators.Description + CASE
	|		WHEN AllIndicators.IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Quantitative)
	|				AND NOT AllIndicators.UnitOfMeasureIsDeterminedByDimension
	|			THEN "", "" + AllIndicators.UnitOfMeasure
	|		ELSE """"
	|	END AS Presentation
	|FROM
	|	AllIndicators AS AllIndicators
	|WHERE
	|	NOT AllIndicators.NFP IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	AllIndicators.Value,
	|	PRESENTATION(AllIndicators.Value)
	|FROM
	|	AllIndicators AS AllIndicators
	|WHERE
	|	AllIndicators.NFP IS NULL";
	
	Query.SetParameter("Values", ColumnValues);
	
	Cache = Query.Execute().Unload();
	
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	TemplateIndicators.Factor.SubperiodFrequency AS SubperiodFrequency,
	|	TemplateIndicators.Factor.Periodicity AS Periodicity
	|FROM
	|	TemplateIndicators_ AS TemplateIndicators
	|
	|UNION ALL
	|
	|SELECT
	|	NonFinancialItemsOfBudgets.SubperiodFrequency,
	|	NonFinancialItemsOfBudgets.Periodicity
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|WHERE
	|	NonFinancialItemsOfBudgets.Ref = &Ref";
	
	PeriodicityParameters = Query.Execute().Unload()[0];
	
	PeriodParameters_.Insert("Periodicity", PeriodicityParameters.Periodicity);
	If ValueIsFilled(PeriodParameters_.Periodicity) And PeriodParameters_.Property("DocumentDate")
		And Not (ValueIsFilled(PeriodParameters_.BeginOfPeriod) And ValueIsFilled(PeriodParameters_.PeriodEnding)) Then
		PeriodParameters_.Insert("BeginOfPeriod", WorkingWithClientServerPeriods.BeginningDateOfPeriod(
			PeriodParameters_.DocumentDate, PeriodParameters_.Periodicity));
		PeriodParameters_.Insert("PeriodEnding", WorkingWithClientServerPeriods.PeriodEndDate_(
			PeriodParameters_.BeginOfPeriod, PeriodParameters_.Periodicity));
	EndIf;
	
	TreeParameters = New Structure;
	TreeParameters.Insert("ColumnsTable1", ColumnsTable1);
	TreeParameters.Insert("ColumnValues", ColumnValues);
	TreeParameters.Insert("Cache", Cache);
	TreeParameters.Insert("Indicators", PropertiesOfIndicators);
	TreeParameters.Insert("PeriodicityParameters", PeriodicityParameters);
	TreeParameters.Insert("PeriodParameters_", PeriodParameters_);
	TreeParameters.Insert("CurrencyRequired", PeriodParameters_);
	
	FillColumnTree(TreeParameters, ColumnTree.Rows);
	Query.Execute();
	
	Return ColumnTree;
	
EndFunction

Function TypesOfMetricsByColumnName(TreeOfHeaderColumns, PropertiesOfIndicators)
	
	TypesOfIndicatorsForFormElements = New Map;
	FillInKindsOfIndicatorsByColumnNameRecursively(TypesOfIndicatorsForFormElements,
			TreeOfHeaderColumns.Rows,
			PropertiesOfIndicators);
	
	Return TypesOfIndicatorsForFormElements;
	
EndFunction

Procedure FillInKindsOfIndicatorsByColumnNameRecursively(TypesOfIndicatorsForFormElements, RowsOfHeaderColumnTree, PropertiesOfIndicators)
	For Each TreeRow In RowsOfHeaderColumnTree Do
		AccumulatedSelection = TreeRow.AccumulatedSelection;
		If TypeOf(AccumulatedSelection) = Type("Structure")
			And AccumulatedSelection.Property("NonFinancialItem") Then
			NonFinancialItem = AccumulatedSelection.NonFinancialItem;
			
			FoundRows = PropertiesOfIndicators.FindRows(New Structure("Factor", NonFinancialItem));
			If FoundRows.Count() > 0 Then
				TypesOfIndicatorsForFormElements.Insert(TreeRow.Name, FoundRows[0].IndicatorKind);
			EndIf;
		EndIf;
		FillInKindsOfIndicatorsByColumnNameRecursively(TypesOfIndicatorsForFormElements, TreeRow.Rows, PropertiesOfIndicators);
	EndDo;
EndProcedure

Function ColumnsOfValuesOfTablePart(TreeOfHeaderColumns, Result = Undefined)
	
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	For Each TreeRow In TreeOfHeaderColumns.Rows Do
		
		If TreeRow.Rows.Count() Then
			ColumnsOfValuesOfTablePart(TreeRow, Result);
		Else
			Result.Add(TreeRow.Name);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function IndicatorsEditableInHeader(IndicatorTemplate, TempTableManager)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	NonFinancialItemsOfBudgets.Ref AS Factor,
	|	CASE
	|		WHEN NonFinancialItemsOfBudgets.IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Cash_)
	|				AND NOT NonFinancialItemsOfBudgets.CurrencyIsDeterminedByDimension
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CurrencyRequired,
	|	NonFinancialItemsOfBudgets.IndicatorKind AS IndicatorKind,
	|	PRESENTATION(NonFinancialItemsOfBudgets.Ref) AS Presentation
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|WHERE
	|	NOT NonFinancialItemsOfBudgets.ByPeriods
	|	AND (NonFinancialItemsOfBudgets.Ref = &Ref
	|			OR NonFinancialItemsOfBudgets.Ref IN
	|				(SELECT
	|					Template.Factor
	|				FROM
	|					TemplateIndicators_ AS Template,
	|					TemplateHeader AS TemplateHeader
	|				WHERE
	|					(TemplateHeader.TypeOfIndicatorInputForm = VALUE(Enum.TemplateFormTypesOfNonFinancialItems.AllInHeader)
	|						OR TemplateHeader.TypeOfIndicatorInputForm = VALUE(Enum.TemplateFormTypesOfNonFinancialItems.SimpleTable)
	|							AND NOT TemplateHeader.IndicatorsInTabularForm)))";
	
	Query.TempTablesManager = TempTableManager;
	If TypeOf(IndicatorTemplate) = Type("Structure") Then
		Query.SetParameter("Ref", Undefined);
	Else
		Query.SetParameter("Ref", IndicatorTemplate);
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure PrepareTemplateTables(Template, TempTableManager) Export
	
	TempTableManager = New TempTablesManager;
	
	If TypeOf(Template) = Type("Structure") Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Factor,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.FillIn,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.DataCompositionSchema
		|INTO TemplateIndicators_
		|FROM
		|	&TemplateIndicators AS TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.Dimension,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.DimensionName
		|INTO EditTemplateInLines
		|FROM
		|	&EditInRows AS TemplatesForEnteringNonFinancialIndicatorsEditInLines
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.Dimension,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.DimensionName
		|INTO EditTemplateInHeader
		|FROM
		|	&EditInHeader AS TemplatesForEnteringNonFinancialIndicatorsEditInHeader
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Dimension,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.DimensionName
		|INTO EditTemplateInColumns
		|FROM
		|	&EditInColumns AS TemplatesForEnteringNonFinancialIndicatorsEditInColumns
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&TypeOfIndicatorInputForm AS TypeOfIndicatorInputForm,
		|	&IndicatorsInTabularForm AS IndicatorsInTabularForm
		|INTO TemplateHeader";
		
		Query.SetParameter("EditInColumns", Template.EditInColumns);
		Query.SetParameter("EditInHeader", 	Template.EditInHeader);
		Query.SetParameter("EditInRows", 	Template.EditInRows);
		Query.SetParameter("TemplateIndicators", 		Template.TemplateIndicators);
		Query.SetParameter("TypeOfIndicatorInputForm", 	Template.TypeOfIndicatorInputForm);
		Query.SetParameter("IndicatorsInTabularForm", 	Template.IndicatorsInTabularForm);
		Query.TempTablesManager = TempTableManager;
		Query.Execute();
	Else
		Query = New Query;
		Query.Text =
		"SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Factor,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.FillIn,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.DataCompositionSchema,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.StorageOfDataCompositionSchema,
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.StorageOfDataCompositionSettings
		|INTO TemplateIndicators_
		|FROM
		|	Catalog.NonFinancialItemProfiles.TemplateIndicators AS TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators
		|WHERE
		|	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.Dimension,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.DimensionName
		|INTO EditTemplateInLines
		|FROM
		|	Catalog.NonFinancialItemProfiles.EditInRows AS TemplatesForEnteringNonFinancialIndicatorsEditInLines
		|WHERE
		|	TemplatesForEnteringNonFinancialIndicatorsEditInLines.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Dimension,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.DimensionName
		|INTO EditTemplateInColumns
		|FROM
		|	Catalog.NonFinancialItemProfiles.EditInColumns AS TemplatesForEnteringNonFinancialIndicatorsEditInColumns
		|WHERE
		|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.LineNumber,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.Dimension,
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.DimensionName
		|INTO EditTemplateInHeader
		|FROM
		|	Catalog.NonFinancialItemProfiles.EditInHeader AS TemplatesForEnteringNonFinancialIndicatorsEditInHeader
		|WHERE
		|	TemplatesForEnteringNonFinancialIndicatorsEditInHeader.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NonFinancialItemProfiles.TypeOfIndicatorInputForm,
		|	NonFinancialItemProfiles.IndicatorsInTabularForm
		|INTO TemplateHeader
		|FROM
		|	Catalog.NonFinancialItemProfiles AS NonFinancialItemProfiles
		|WHERE
		|	NonFinancialItemProfiles.Ref = &Ref";
		Query.SetParameter("Ref", Template);
		Query.TempTablesManager = TempTableManager;
		Query.Execute();
	EndIf;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	OperationKind - EnumRef.OperationKindsOfSettingOfNonFinancialItemValues - type of operation.
// 	Factor - CatalogRef.NonFinancialItemsOfBudgets - Indicator.
// 	Template - CatalogRef.NonFinancialItemProfiles - Template.
// 	ColumnValues - See TemplateColumnValues
// 	PeriodParameters_ - Structure - LongDesc:
// * BeginOfPeriod - Date - the beginning of the period.
// * PeriodEnding - Date - end of the period.
// Returns:
// 	Structure, Undefined - LongDesc:
// * TypesOfMetricsByColumnName - Map -
// * ColumnsOfValuesOfTablePart - Array, Undefined -
// * ValueColumns - ValueTree -:
// ** Name - String - 
// ** Title - String - 
// ** AccumulatedSelection - String -
// ** ReadOnly - Boolean - 
// * Periodicity - EnumRef.Periodicity - 
// * PropertiesOfIndicators - ValueTable -
// * EditableColumns - Array of Structure - array of structures with properties:
// ** Name - String - 
// ** Presentation - String - 
// * IndicatorsEditableInHeader - ValueTable -
// * RightColumn - Array of Structure - array of structures with properties:
// ** Name - String - 
// * LeftColumn - Array of Structure -array of structures with properties:
// ** Name - String - 
Function DescriptionStructureOfInputDocumentFields(OperationKind, Factor, Template, ColumnValues, PeriodParameters_) Export
	Var TempTableManager;
	
	If OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		IndicatorTemplate = Template;
		If TypeOf(IndicatorTemplate) = Type("String") Then
			IndicatorTemplate = GetFromTempStorage(IndicatorTemplate);
		EndIf;
	Else
		IndicatorTemplate = Factor;
	EndIf;
	
	If Not ValueIsFilled(IndicatorTemplate) Then
		Return Undefined;
	EndIf;
	
	PrepareTemplateTables(Template, TempTableManager);
	
	StructureOfDescriptionOfDocumentFields = New Structure;
	StructureOfDescriptionOfDocumentFields.Insert("Period", TypeOfDocumentFormPeriod(IndicatorTemplate, TempTableManager));
	
	HeaderFields = ListOfHeaderFields(IndicatorTemplate, TempTableManager);
	
	LeftColumn = New Array;
	RightColumn = New Array;
	
	FlagLeftColumn = True;
	For Each HeaderField In HeaderFields Do
		
		If FlagLeftColumn Then
			LeftColumn.Add(HeaderField);
		Else
			RightColumn.Add(HeaderField);
		EndIf;
		
		FlagLeftColumn = Not FlagLeftColumn;
		
	EndDo;
	
	StructureOfDescriptionOfDocumentFields.Insert("LeftColumn", LeftColumn);
	StructureOfDescriptionOfDocumentFields.Insert("RightColumn", RightColumn);
	
	HeaderIndicators = IndicatorsEditableInHeader(IndicatorTemplate, TempTableManager);
	StructureOfDescriptionOfDocumentFields.Insert("IndicatorsEditableInHeader", HeaderIndicators);
	StructureOfDescriptionOfDocumentFields.Insert("EditableColumns", EditableColumns(IndicatorTemplate, TempTableManager));
	
	PropertiesOfIndicators = PropertiesOfIndicators(IndicatorTemplate, TempTableManager);
	StructureOfDescriptionOfDocumentFields.Insert("PropertiesOfIndicators", PropertiesOfIndicators);
	
	If HeaderIndicators.Count() Then
		PropertiesOfIndicators = Undefined;
	EndIf;
	
	If StructureOfDescriptionOfDocumentFields.Period <> "Period" And PeriodParameters_.Property("DocumentDate") Then
		PeriodParameters_.Delete("DocumentDate");
	EndIf;
	TreeOfHeaderColumns = TreeOfHeaderColumns(IndicatorTemplate, ColumnValues, PropertiesOfIndicators, PeriodParameters_, TempTableManager);
	StructureOfDescriptionOfDocumentFields.Insert("Periodicity", PeriodParameters_.Periodicity);
	StructureOfDescriptionOfDocumentFields.Insert("ValueColumns", TreeOfHeaderColumns);
	StructureOfDescriptionOfDocumentFields.Insert("ColumnsOfValuesOfTablePart", ColumnsOfValuesOfTablePart(TreeOfHeaderColumns));
	StructureOfDescriptionOfDocumentFields.Insert("TypesOfMetricsByColumnName", TypesOfMetricsByColumnName(TreeOfHeaderColumns, PropertiesOfIndicators));
	
	If OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
		If TypeOf(IndicatorTemplate) = Type("Structure") Then
			Tables = New Structure("TemplateIndicators, EditInColumns",
				IndicatorTemplate.TemplateIndicators,
				IndicatorTemplate.EditInColumns);
		Else
			Tables = New Structure("TemplateIndicators, EditInColumns",
				IndicatorTemplate.TemplateIndicators.Unload(),
				IndicatorTemplate.EditInColumns.Unload());
		EndIf;
		PopulationTable = Tables.TemplateIndicators.Copy(New Structure("FillIn", True));
		If PopulationTable.Count() Then
			StructureOfDescriptionOfDocumentFields.Insert("FillingRules", PopulationTable);
		EndIf;
		FoundRows = Tables.EditInColumns.Copy(New Structure("DimensionName", "Dimension"));
		If FoundRows.Count() Then
			StructureOfDescriptionOfDocumentFields.Insert("DimensionColumns1", FoundRows);
		EndIf;
	EndIf;
	
	Return StructureOfDescriptionOfDocumentFields;
	
EndFunction

// Returns a table of column values for the template.
// 
// Parameters:
// 	Template - CatalogRef.NonFinancialItemProfiles - The entry template.
// Returns:
// 	ValueTable - column values:
// 	 *Value - Arbitrary - Arbitrary value.
// 	 *DimensionName - String - Dimension name.
// 	 *Dimension - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//
Function TemplateColumnValues(Template) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Ref,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.LineNumber,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Dimension,
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.DimensionName
	|INTO EditInColumns
	|FROM
	|	Catalog.NonFinancialItemProfiles.EditInColumns AS TemplatesForEnteringNonFinancialIndicatorsEditInColumns
	|WHERE
	|	TemplatesForEnteringNonFinancialIndicatorsEditInColumns.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NonFinancialItemProfilesDefaultComplexTableValues.Ref,
	|	NonFinancialItemProfilesDefaultComplexTableValues.LineNumber,
	|	NonFinancialItemProfilesDefaultComplexTableValues.Value,
	|	NonFinancialItemProfilesDefaultComplexTableValues.DimensionName,
	|	NonFinancialItemProfilesDefaultComplexTableValues.Dimension
	|INTO DefaultValues
	|FROM
	|	Catalog.NonFinancialItemProfiles.DefaultComplexTableValues AS NonFinancialItemProfilesDefaultComplexTableValues
	|WHERE
	|	NonFinancialItemProfilesDefaultComplexTableValues.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DefaultValues.Value,
	|	DefaultValues.DimensionName,
	|	DefaultValues.Dimension
	|FROM
	|	EditInColumns AS EditInColumns
	|		INNER JOIN DefaultValues AS DefaultValues
	|		ON EditInColumns.Dimension = DefaultValues.Dimension
	|			AND EditInColumns.DimensionName = DefaultValues.DimensionName";
	
	Query.SetParameter("Ref", Template);
	
	Return Query.Execute().Unload();
	
EndFunction

// adds elements to the form.
// 
// Parameters:
// 	InputDescriptionStructure - See DescriptionStructureOfInputDocumentFields
// 	Items - FormAllItems - form element.
// 	AddedItems - Array of String - Array of element names to add.
Procedure ReflectDocumentHeaderDetails(InputDescriptionStructure, Items, AddedItems) Export
	
	For Each Item In InputDescriptionStructure.LeftColumn Do
		NewItem = Items.Add(Item.Name, Type("FormField"), Items.LeftColumn);
		NewItem.DataPath = "Object." + Item.Name;
		NewItem.Title = Item.Presentation;
		NewItem.Type = FormFieldType.InputField;
		NewItem.TypeRestriction = Item.ValueType;
		NewItem.AutoMarkIncomplete = True;
		AddedItems.Add(NewItem.Name);
		NewItem.SetAction("OnChange", "Attachable_WhenChangingHeaderAnalytics");
		If Item.Property("ChoiceParameterLinks") Then
			NewLink = New ChoiceParameterLink("Filter." + Item.ChoiceParameterLinks.Filter, 
									"Object." + Item.ChoiceParameterLinks.Column);
			NewArray = New Array();
			NewArray.Add(NewLink);
			NewLinks = New FixedArray(NewArray);
			NewItem.ChoiceParameterLinks = NewLinks;
		EndIf;
		
		If Item.Property("ChoiceParameters") Then
			NewParameter1 = New ChoiceParameter("Filter." + Item.ChoiceParameters.Filter,
					Item.ChoiceParameters.Value);
			NewArray = New Array();
			NewArray.Add(NewParameter1);
			NewParameters = New FixedArray(NewArray);
			NewItem.ChoiceParameters = NewParameters;
		EndIf;
	EndDo;
	
	For Each Item In InputDescriptionStructure.RightColumn Do
		NewItem = Items.Add(Item.Name, Type("FormField"), Items.RightColumn);
		NewItem.DataPath = "Object." + Item.Name;
		NewItem.Title = Item.Presentation;
		NewItem.Type = FormFieldType.InputField;
		NewItem.TypeRestriction = Item.ValueType;
		NewItem.AutoMarkIncomplete = True;
		AddedItems.Add(NewItem.Name);
		NewItem.SetAction("OnChange", "Attachable_WhenChangingHeaderAnalytics");
		If Item.Property("ChoiceParameterLinks") Then
			NewLink = New ChoiceParameterLink("Filter." + Item.ChoiceParameterLinks.Filter,
					"Object." + Item.ChoiceParameterLinks.Column);
			NewArray = New Array();
			NewArray.Add(NewLink);
			NewLinks = New FixedArray(NewArray);
			NewItem.ChoiceParameterLinks = NewLinks;
		EndIf;
		
		If Item.Property("ChoiceParameters") Then
			NewParameter1 = New ChoiceParameter("Filter." + Item.ChoiceParameters.Filter,
					Item.ChoiceParameters.Value);
			NewArray = New Array();
			NewArray.Add(NewParameter1);
			NewParameters = New FixedArray(NewArray);
			NewItem.ChoiceParameters = NewParameters;
		EndIf;
	EndDo;
	
EndProcedure

// Adds controls to the form.
// 
// Parameters:
// 	InputDescriptionStructure - See DescriptionStructureOfInputDocumentFields
// 	Items - FormAllItems -
// 	AddedItems - Array of String - 
// 	IndicatorValues - ValueTable - 
Procedure ReflectIndicatorsEditedInHeader(InputDescriptionStructure, Items, AddedItems, IndicatorValues) Export
	
	For Each Factor In InputDescriptionStructure.IndicatorsEditableInHeader Do
		
		NewRow = IndicatorValues.Add();
		FillPropertyValues(NewRow, Factor);
		
		Postfix = StrReplace(New UUID(), "-", "_");
		
		Group = Items.Add("IndicatorGroup_" + Postfix, Type("FormGroup"), Items.Indicators);
		Group.Type = FormGroupType.UsualGroup;
		Group.Group = ChildFormItemsGroup.Horizontal;
		Group.Representation = UsualGroupRepresentation.None;
		Group.ShowTitle = False;
		AddedItems.Add(Group.Name);
		
		NewItem = Items.Add("Factor" + Postfix, Type("FormField"), Group);
		NewItem.DataPath = "IndicatorValues[" + IndicatorValues.IndexOf(NewRow) + "].Value";
		NewItem.Title = Factor.Presentation;
		NewItem.Type = FormFieldType.InputField;
		NewItem.HorizontalStretch = False;
		If Factor.IndicatorKind = Enums.NonFinancialItemKinds.Quantitative Then
			NewItem.TypeRestriction = Common.TypeDescriptionNumber(15, 3);
		ElsIf Factor.IndicatorKind = Enums.NonFinancialItemKinds.Coefficients Then
			NewItem.TypeRestriction = Metadata.InformationRegisters.NonFinancialItemValues.Resources.IndicatorValue.Type;
		Else
			NewItem.TypeRestriction = TMCommonUse.MoneyFieldTypeDescription();
		EndIf;
		AddedItems.Add(NewItem.Name);
		
		If Factor.CurrencyRequired Then
		
			NewItem = Items.Add("IndicatorCurrency" + Postfix, Type("FormField"), Group);
			NewItem.DataPath = "IndicatorValues[" + IndicatorValues.IndexOf(NewRow) + "].Currency";
			NewItem.TitleLocation = FormItemTitleLocation.None;
			NewItem.Type = FormFieldType.InputField;
			NewItem.HorizontalStretch = False;
			AddedItems.Add(NewItem.Name);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds controls to the form.
// 
// Parameters:
// 	ValueColumns - ValueTree - a tree with columns:
// 	 *Name - String - 
// 	PlaceAdded - FormGroup - 
// 	Items - FormAllItems -
// 	AddedItems - Array of String -
Procedure DisplayColumnsByTree(ValueColumns, PlaceAdded, Items, AddedItems)
	
	For Each TreeRow In ValueColumns.Rows Do
		If TreeRow.Rows.Count() Then
			NewItem = Items.Add(TreeRow.Name, Type("FormGroup"), PlaceAdded);
			NewItem.Title = TreeRow.Title;
			NewItem.ShowInHeader = True;
			NewItem.Type = FormGroupType.ColumnGroup;
			NewItem.Group = ColumnsGroup.Horizontal;
			AddedItems.Add(NewItem.Name);
			DisplayColumnsByTree(TreeRow, NewItem, Items, AddedItems);
		Else
			NewItem = Items.Add(TreeRow.Name, Type("FormField"), PlaceAdded);
			NewItem.DataPath = "TabularSection." + TreeRow.Name;
			NewItem.Title = TreeRow.Title;
			NewItem.Type = FormFieldType.InputField;
			NewItem.HorizontalStretch = False;
			NewItem.Width = 6;
			AddedItems.Add(NewItem.Name);
			If TreeRow.ReadOnly = True Then
				NewItem.ReadOnly = True;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds controls to the form.
// 
// Parameters:
// 	InputDescriptionStructure - See DescriptionStructureOfInputDocumentFields
// 	Items - FormAllItems -
// 	Form - ClientApplicationForm - 
// 	AddedItems - Array of String - 
// 	ItemsToDelete_ - Array of FormAttribute - 
Procedure ReflectTabularPartOfDocument(InputDescriptionStructure, Items, Form, AddedItems, ItemsToDelete_) Export
	
	If InputDescriptionStructure.ColumnsOfValuesOfTablePart.Count() + 
			InputDescriptionStructure.EditableColumns.Count() = 0 Then
			
		Items.TabularSection.Visible = False;
			
	Else
			
		Items.TabularSection.Visible = True;
		
	EndIf;
	
	NewAttributes = New Array;
	For Each AttributeName In InputDescriptionStructure.ColumnsOfValuesOfTablePart Do
		
		If BudgetReportingClientServer.LeftPartOfNameMatches(AttributeName, "Currency_") Then
			Attribute = New FormAttribute(AttributeName, New TypeDescription("CatalogRef.Currencies"), "TabularSection");
		ElsIf BudgetReportingClientServer.LeftPartOfNameMatches(AttributeName, "Ed_") Then
			Attribute = New FormAttribute(AttributeName, New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"), "TabularSection");
		Else
			IndicatorKind = InputDescriptionStructure.TypesOfMetricsByColumnName.Get(AttributeName);
			If IndicatorKind = Enums.NonFinancialItemKinds.Quantitative Then
				MetricDataType = Common.TypeDescriptionNumber(15, 3);
			ElsIf IndicatorKind = Enums.NonFinancialItemKinds.Coefficients Then
				MetricDataType = Metadata.InformationRegisters.NonFinancialItemValues.Resources.IndicatorValue.Type;
			Else
				MetricDataType = TMCommonUse.MoneyFieldTypeDescription();
			EndIf;
			Attribute = New FormAttribute(AttributeName, MetricDataType, "TabularSection");
		EndIf;
		NewAttributes.Add(Attribute);
		
	EndDo;
	
	For Each Column In InputDescriptionStructure.EditableColumns Do
		
		Attribute = New FormAttribute(Column.Name, Column.ValueType, "TabularSection");
		NewAttributes.Add(Attribute);
		
	EndDo;
	
	Form.ChangeAttributes(NewAttributes, ItemsToDelete_);
	
	For Each Item In InputDescriptionStructure.EditableColumns Do
		NewItem = Items.Add(Item.Name, Type("FormField"), Items.TabularSection);
		NewItem.DataPath = "TabularSection." + Item.Name;
		NewItem.Title = Item.Presentation;
		NewItem.Type = FormFieldType.InputField;
		NewItem.Width = 17;
		NewItem.HorizontalStretch = False;
		NewItem.AutoMarkIncomplete = True;
		AddedItems.Add(NewItem.Name);
		NewItem.SetAction("OnChange", "Attachable_WhenChangingListColumn");
		If Item.Property("ChoiceParameterLinks") Then
			NewLink = New ChoiceParameterLink("Filter." + Item.ChoiceParameterLinks.Filter, 
									"Items.TabularSection.CurrentData." + Item.ChoiceParameterLinks.Column);
			NewArray = New Array();
			NewArray.Add(NewLink);
			NewLinks = New FixedArray(NewArray);
			NewItem.ChoiceParameterLinks = NewLinks;
		EndIf;
		
		If Item.Property("ChoiceParameters") Then
			NewParameter1 = New ChoiceParameter("Filter." + Item.ChoiceParameters.Filter, 
									Item.ChoiceParameters.Value);
			NewArray = New Array();
			NewArray.Add(NewParameter1);
			NewParameters = New FixedArray(NewArray);
			NewItem.ChoiceParameters = NewParameters;
		EndIf;
	EndDo;
	
	DisplayColumnsByTree(InputDescriptionStructure.ValueColumns,
			Items.TabularSection,
			Items,
			AddedItems);
	
EndProcedure

#EndRegion

#Region FillingInDocument_

// Returns the Analytics value
// 
// Parameters:
// 	ObjectAndCalculationParameters - See ObjectAndParametersOfCalculationAndSettingValuesOfNonFinancialIndicators
// 	TabSectionRow - ValueTableRow - LongDesc
// 	AnalyticsAddress - Number - 
// 	ColumnValues - Structure - values of accumulated selection:
// 	 *NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - 
// Returns:
// 	Characteristic.BudgetFlowItemDimensions - the value of analytics.
//
Function DimensionValue(ObjectAndCalculationParameters, TabSectionRow, AnalyticsAddress, ColumnValues) Export
	
	Object = ObjectAndCalculationParameters.Object;
	InputDescriptionStructure = ObjectAndCalculationParameters.InputDescriptionStructure;
	
	NameOfAnalytics = "Dimension" + AnalyticsAddress;
	
	FromHeader = False;
	For Each ColumnProperties In InputDescriptionStructure.LeftColumn Do
		If ColumnProperties.Name = NameOfAnalytics Then
			FromHeader = True;
			Break;
		EndIf;
	EndDo;
	If Not FromHeader Then
		For Each ColumnProperties In InputDescriptionStructure.RightColumn Do
			If ColumnProperties.Name = NameOfAnalytics Then
				FromHeader = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If FromHeader Then
		Return Object[NameOfAnalytics];
	ElsIf ColumnValues.Property(NameOfAnalytics) Then
		Return ColumnValues[NameOfAnalytics];
	ElsIf ValueIsFilled(TabSectionRow[NameOfAnalytics]) Then
		Return TabSectionRow[NameOfAnalytics];
	EndIf;
	
EndFunction

Procedure SetValueFromAnalytics(ObjectAndCalculationParameters, ValueType, RowIndex, SourceOfChange, CacheOfAnalyticsValues = Undefined) Export
	
	TabularSection = ObjectAndCalculationParameters.TabularSection;
	InputDescriptionStructure = ObjectAndCalculationParameters.InputDescriptionStructure;
	IndicatorPropertyCache = ObjectAndCalculationParameters.InputDescriptionStructure.PropertiesOfIndicators;
	
	If CacheOfAnalyticsValues = Undefined Then
		CacheOfAnalyticsValues = New Map;
	EndIf;
	
	If TypeOf(RowIndex) = Type("ValueTableRow") Then
		LineOfATabularSection = RowIndex;
	Else
		LineOfATabularSection = TabularSection.FindByID(RowIndex);
	EndIf;
	
	ColumnsOfValuesOfTablePart = InputDescriptionStructure.ColumnsOfValuesOfTablePart;
	TreeOfValueColumns = InputDescriptionStructure.ValueColumns;
	
	If SourceOfChange <> Undefined Then
		AnalyticsAddress = Number(StrReplace(SourceOfChange, "Dimension", ""));
	EndIf;
	
	If ValueType = "Currency_" Then
		NameOfAnalyticsAddress                  = "DimensionAddressCurrency";
		NameOfMetricIsDeterminedByAnalytics = "CurrencyIsDeterminedByDimension";
		MetricNameFillIn             = "CurrencyFilling";
	Else
		NameOfAnalyticsAddress                   = "QuantityDimensionAddress";
		NameOfMetricIsDeterminedByAnalytics  = "UnitOfMeasureIsDeterminedByDimension";
		MetricNameFillIn              = "UnitOfMeasureFilling";
	EndIf;
	
	For Each Column In ColumnsOfValuesOfTablePart Do
		
		If BudgetReportingClientServer.LeftPartOfNameMatches(Column, "Ed_")
			Or BudgetReportingClientServer.LeftPartOfNameMatches(Column, "Currency_") Then
			Continue;
		EndIf;
		
		If ColumnsOfValuesOfTablePart.Find(ValueType + Column) = Undefined Then
			Continue;
		EndIf;
		
		ColumnFields = TreeOfValueColumns.Rows.Find(Column, "Name", True).AccumulatedSelection;
		
		If SourceOfChange = Undefined Then
			PropertyStrings = IndicatorPropertyCache.FindRows(New Structure("Factor", ColumnFields.NonFinancialItem));
		Else
			PropertyStrings = IndicatorPropertyCache.FindRows(New Structure("Factor, " + NameOfAnalyticsAddress, 
															ColumnFields.NonFinancialItem, AnalyticsAddress));
			If Not PropertyStrings.Count() Then
				// there is no indicator whose currency depends on the changed analytics
				Continue;
			EndIf;
		EndIf;
		
		IndicatorProperties = PropertyStrings[0];
		If IndicatorProperties[NameOfMetricIsDeterminedByAnalytics] Then
			DimensionValue = DimensionValue(ObjectAndCalculationParameters,
					LineOfATabularSection, IndicatorProperties[NameOfAnalyticsAddress], ColumnFields);
			Value = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(CacheOfAnalyticsValues,
					DimensionValue,
					IndicatorProperties[MetricNameFillIn]);
			LineOfATabularSection[ValueType + Column] = Value;
		EndIf;
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ObjectAndCalculationParameters - See ObjectAndParametersOfCalculationAndSettingValuesOfNonFinancialIndicators
// 	DeleteRows_1 - Boolean - Flag for deleting rows.
Procedure FillInConfiguredDocument(ObjectAndCalculationParameters, DeleteRows_1) Export
	
	Object = ObjectAndCalculationParameters.Object;
	InputDescriptionStructure = ObjectAndCalculationParameters.InputDescriptionStructure;
	TabularSection = ObjectAndCalculationParameters.TabularSection;
	
	FillingRules = InputDescriptionStructure.FillingRules;
	
	FillParameters = BudgetingServer.TemplateForParametersForObtainingValuesOfNonFinancialIndicators();
	If InputDescriptionStructure.Period = "None" Then
		Period = New StandardPeriod(CurrentSessionDate(), CurrentSessionDate())
	ElsIf InputDescriptionStructure.Period = "ValidFrom" Then
		Period = New StandardPeriod(Object.BeginOfPeriod, Object.BeginOfPeriod)
	ElsIf InputDescriptionStructure.Period = "Period" Then
		Period = New StandardPeriod(Object.BeginOfPeriod, Object.PeriodEnding)
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	NonFinancialItemsOfBudgets.Ref AS NonFinancialItem,
	|	NonFinancialItemsOfBudgets.*
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|WHERE
	|	NonFinancialItemsOfBudgets.Ref = &Ref";
	Query.SetParameter("Ref", FillingRules[0].Factor);
	Attributes = Query.Execute().Unload()[0];
	
	FillParameters.Insert("Period", Period);
	FillParameters.Insert("Periodicity", Attributes.Periodicity);
	
	FillParameters.Insert("DimensionKinds", New Array);
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		If ValueIsFilled(Attributes["DimensionKind" + Cnt]) Then
			FillParameters.DimensionKinds.Add(Attributes["DimensionKind" + Cnt]);
		EndIf;
	EndDo;
	
	FillParameters.Insert("ByCompanies", Attributes.ByCompanies);
	FillParameters.Insert("ByBusinessUnits", Attributes.ByBusinessUnits);
	
	FillingParametersPeriod = FillParameters.Period; // StandardPeriod - 
	PeriodsTable = Planning.PeriodTableTemplate();
	If Not ValueIsFilled(FillParameters.Periodicity) Then
		Period = PeriodsTable.Add();
		Period.StartDate = FillingParametersPeriod.StartDate;
		Period.EndDate = FillingParametersPeriod.EndDate;
	Else
		Planning.FillInPeriodTable(
			PeriodsTable,
			FillParameters.Periodicity,
			FillingParametersPeriod.StartDate,
			FillingParametersPeriod.EndDate);
		If Attributes.ByPeriods Then
			TableOfPeriods_Copy = PeriodsTable.CopyColumns();
			SubperiodsTable = PeriodsTable.CopyColumns("StartDate,EndDate,ColumnNumber");
			For Each PeriodString_ In PeriodsTable Do
				Planning.FillInPeriodTable(
					TableOfPeriods_Copy,
					Attributes.SubperiodFrequency,
					PeriodString_.StartDate,
					PeriodString_.EndDate);
				TableOfPeriods_Copy.FillValues(PeriodString_.StartDate, "StartDate");
				CommonClientServer.SupplementTable(TableOfPeriods_Copy, SubperiodsTable);
			EndDo;
			SubperiodsTable.Columns.ColumnNumber.Name = "SubperiodNumber";
			SubperiodsTable.Columns.EndDate.Name = "InstallationDate";
			FillParameters.Insert("SubperiodsTable", SubperiodsTable);
		EndIf;
	EndIf;
	FillParameters.Insert("PeriodsTable", PeriodsTable);
	FillParameters.Insert("NFPEntryTemplate", Object.InputTemplate);
	
	ValueTable = BudgetingServer.TemplateForTableOfValuesOfNonFinancialIndicators(FillParameters);
	
	For Each IndicatorLine_ In FillingRules Do
		If ValueIsFilled(IndicatorLine_.DataCompositionSchema) Then
			DataAcquisitionScheme = Catalogs.NonFinancialItemsOfBudgets.PredefinedDataAcquisitionScheme(
				IndicatorLine_.DataCompositionSchema);
		Else
			StorageOfDataCompositionSchema = IndicatorLine_.StorageOfDataCompositionSchema; // ValueStorage
			DataAcquisitionScheme = StorageOfDataCompositionSchema.Get();
		EndIf;
		StorageOfDataCompositionSettings = IndicatorLine_.StorageOfDataCompositionSettings; // ValueStorage
		DataAcquisitionSchemeSettings = StorageOfDataCompositionSettings.Get();
		Rule = BudgetingServer.RuleForObtainingNonFinancialIndicatorValues(Attributes,
			DataAcquisitionScheme,
			DataAcquisitionSchemeSettings);
		BudgetingServer.NonFinancialIndicatorValuesAccordingToRule(Rule, FillParameters, ValueTable);
	EndDo;
	
	ColumnsOfValuesOfTablePart = InputDescriptionStructure.ColumnsOfValuesOfTablePart;
	TreeOfValueColumns = InputDescriptionStructure.ValueColumns;
	EditableColumns = InputDescriptionStructure.EditableColumns;
	
	ColumnsList = "";
	For Each Structure In EditableColumns Do
		ColumnsList = ColumnsList + ?(IsBlankString(ColumnsList), "", ",") + Structure.Name;
	EndDo;
	
	If DeleteRows_1 Then
		TabularSection.Clear();
		CrawlLines = ValueTable.Copy(,ColumnsList);
		CrawlLines.GroupBy(ColumnsList);
		For Each CrawlString In CrawlLines Do
			NewRow = TabularSection.Add();
			FillPropertyValues(NewRow, CrawlString);
			NewRow.DocumentRowNumber = TabularSection.IndexOf(NewRow) + 1;
		EndDo;
	EndIf;
	
	CacheOfAnalyticsValues = New Map;
	
	For Each LineOfATabularSection In TabularSection Do
		TheStructureOfTheSearch = New Structure(ColumnsList);
		FillPropertyValues(TheStructureOfTheSearch, LineOfATabularSection);
		For Each ListColumn In ColumnsOfValuesOfTablePart Do
			// Currencies and units of measurement are processed separately
			If BudgetReportingClientServer.LeftPartOfNameMatches(ListColumn, "Currency_") Then
				Continue;
			EndIf;
			If BudgetReportingClientServer.LeftPartOfNameMatches(ListColumn, "Ed_") Then
				Continue;
			EndIf;
			ColumnStructure = TreeOfValueColumns.Rows.Find(ListColumn, "Name", True).AccumulatedSelection;
			CommonClientServer.SupplementStructure(TheStructureOfTheSearch, ColumnStructure, True);
			ValueStrings = ValueTable.FindRows(TheStructureOfTheSearch);
			If ValueStrings.Count() Then
				LineOfATabularSection[ListColumn] = ValueStrings[0].IndicatorValue;
				If ColumnsOfValuesOfTablePart.Find("Currency_" + ListColumn) <> Undefined Then
					LineOfATabularSection["Currency_" + ListColumn] = ValueStrings[0].Currency;
				EndIf;
			EndIf;
		EndDo;
		
		If TypeOf(LineOfATabularSection) = Type("ValueTableRow") Then
			RowID = LineOfATabularSection;
		Else
			RowID = LineOfATabularSection.GetID();
		EndIf;
		
		SetValueFromAnalytics(ObjectAndCalculationParameters,
				"Currency_",
				RowID,
				Undefined,
				CacheOfAnalyticsValues);
		SetValueFromAnalytics(ObjectAndCalculationParameters,
				"Ed_",
				RowID,
				Undefined,
				CacheOfAnalyticsValues);
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ObjectAndCalculationParameters - See ObjectAndParametersOfCalculationAndSettingValuesOfNonFinancialIndicators
// 	CurrentObject - DocumentObject.SetValuesForNonFinancialItems - 
Procedure SaveTabularPartToDocument(ObjectAndCalculationParameters, CurrentObject) Export
	
	CurrentObject = ObjectAndCalculationParameters.Object;
	InputDescriptionStructure = ObjectAndCalculationParameters.InputDescriptionStructure;
	TabularSection = ObjectAndCalculationParameters.TabularSection;
	IndicatorValues = ObjectAndCalculationParameters.IndicatorValues;
	
	CurrentObject.IndicatorValues.Clear();
	CurrentObject.DocumentRows.Clear();
	CurrentObject.DocumentColumns.Clear();
	
	If InputDescriptionStructure = Undefined Then
		Return;
	EndIf;
	
	MeasurementString = "Organization, Department, Scenario";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		MeasurementString = MeasurementString + ", Dimension" + DimensionNumber;
	EndDo;
	Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		MeasurementString,,, True);
		
	For Each Item In InputDescriptionStructure.LeftColumn Do
		IndexOf = Array.Find(Item.Name);
		Array.Delete(IndexOf)
	EndDo;
	
	For Each Item In InputDescriptionStructure.RightColumn Do
		IndexOf = Array.Find(Item.Name);
		Array.Delete(IndexOf)
	EndDo;
	
	For Each Attribute In Array Do
		CurrentObject[Attribute] = Undefined;
	EndDo;
	
	ColumnsOfValuesOfTablePart = InputDescriptionStructure.ColumnsOfValuesOfTablePart;
	TreeOfValueColumns = InputDescriptionStructure.ValueColumns;
	
	For Each LineOfATabularSection In TabularSection Do
		DocumentLine = CurrentObject.DocumentRows.Add();
		FillPropertyValues(DocumentLine, LineOfATabularSection);
		For Each Column In ColumnsOfValuesOfTablePart Do
			If BudgetReportingClientServer.LeftPartOfNameMatches(Column, "Ed_")
				Or BudgetReportingClientServer.LeftPartOfNameMatches(Column, "Currency_") Then
				Continue;
			EndIf;
			TreeColumn = TreeOfValueColumns.Rows.Find(Column, "Name", True);
			ColumnFields = TreeColumn.AccumulatedSelection;
			DocumentColumn = CurrentObject.DocumentColumns.Add();
			FillPropertyValues(DocumentColumn, ColumnFields);
			DocumentColumn.DocumentRowNumber = DocumentLine.DocumentRowNumber;
			DocumentColumn.Value = LineOfATabularSection[Column];
			If ColumnsOfValuesOfTablePart.Find("Currency_" + Column) <> Undefined Then
				DocumentColumn.Currency = LineOfATabularSection["Currency_" + Column];
			ElsIf TreeColumn.Parent <> Undefined
				And ColumnsOfValuesOfTablePart.Find("Currency_" + TreeColumn.Parent.Name) <> Undefined Then
				DocumentColumn.Currency = LineOfATabularSection["Currency_" + TreeColumn.Parent.Name];
			EndIf;
		EndDo;
	EndDo;
	
	CurrentObject.IndicatorValues.Load(IndicatorValues.Unload());
	CurrentObject.PeriodType = InputDescriptionStructure.Period;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	Object - DocumentObject.SetValuesForNonFinancialItems - 
// Returns:
// 	Structure - structure with properties:
// 	 *Object - DocumentObject.SetValuesForNonFinancialItems -
// 	 *InputDescriptionStructure - See DescriptionStructureOfInputDocumentFields
// 	 *TabularSection - ValueTable - table with columns:
// 	   **DocumentRowNumber - Number - 
// 	 *IndicatorValues - ValueTable - Table of values with columns:
// 	   **Factor - CatalogRef.NonFinancialItemsOfBudgets -
// 	   **Value - Number - 
// 	   **Currency - CatalogRef.Currencies -
//
Function ObjectAndParametersOfCalculationAndSettingValuesOfNonFinancialIndicators(Object) Export
	
	ObjectAndCalculationParameters = New Structure;
	ObjectAndCalculationParameters.Insert("Object", Object);
	
	PeriodParameters_ = New Structure("BeginOfPeriod, PeriodEnding", 
										Object.BeginOfPeriod, Object.PeriodEnding);
	InputDescriptionStructure = DescriptionStructureOfInputDocumentFields(
		Object.OperationKind,
		Object.NonFinancialItem,
		Object.InputTemplate,
		Object.ColumnValues.Unload(),
		PeriodParameters_);
	
	ObjectAndCalculationParameters.Insert("InputDescriptionStructure", InputDescriptionStructure);
	
	TabularSection = New ValueTable;
	
	TabularSection.Columns.Add("DocumentRowNumber");
	
	For Each AttributeName In InputDescriptionStructure.ColumnsOfValuesOfTablePart Do
		
		If BudgetReportingClientServer.LeftPartOfNameMatches(AttributeName, "Currency_") Then
			TabularSection.Columns.Add(AttributeName, New TypeDescription("CatalogRef.Currencies"));
		ElsIf BudgetReportingClientServer.LeftPartOfNameMatches(AttributeName, "Ed_") Then
			TabularSection.Columns.Add(AttributeName, New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		Else
			IndicatorKind = InputDescriptionStructure.TypesOfMetricsByColumnName.Get(AttributeName);
			If IndicatorKind = Enums.NonFinancialItemKinds.Quantitative Then
				MetricDataType = Common.TypeDescriptionNumber(15, 3);
			ElsIf IndicatorKind = Enums.NonFinancialItemKinds.Coefficients Then
				MetricDataType = Metadata.InformationRegisters.NonFinancialItemValues.Resources.IndicatorValue.Type;
			Else
				MetricDataType = TMCommonUse.MoneyFieldTypeDescription();
			EndIf;
			TabularSection.Columns.Add(AttributeName, MetricDataType);
		EndIf;
		
	EndDo;
	
	For Each Column In InputDescriptionStructure.EditableColumns Do
		
		TabularSection.Columns.Add(Column.Name, Column.ValueType);
		
	EndDo;
	
	ObjectAndCalculationParameters.Insert("TabularSection", TabularSection);
	
	ObjectAndCalculationParameters.Insert("IndicatorValues", Object.IndicatorValues);
	
	Return ObjectAndCalculationParameters;
	
EndFunction

#EndRegion

#Region CarryingOutDocument

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure GenerateTableNonFinancialItemValues(TablesForRegisteredRecords, Document, Registers)
	
	RegisterName = "NonFinancialItemValues";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	DataCompositionSchema = Documents.SetValuesForNonFinancialItems.GetTemplate("DataToPost");
	Composer = FinancialReportingServer.SchemaComposer(DataCompositionSchema);
	FinancialReportingServer.SetLayoutParameter(Composer.Settings, "Ref", Document);
	
	StructureOfData = New Structure("NonFinancialItem, InputTemplate, BeginOfPeriod, PeriodEnding");
	StructureOfData.Insert("NonFinancialIndicatorByPeriod", "NonFinancialItem.ByPeriods");
	StructureOfData.Insert("TemplateForEnteringIndicatorsInTablePart", "InputTemplate.IndicatorsInTabularForm");
	
	Attributes = Common.ObjectAttributesValues(Document, StructureOfData);
		
	If (Not Attributes.InputTemplate.IsEmpty() And Not Attributes.TemplateForEnteringIndicatorsInTablePart) 
		Or (Not Attributes.NonFinancialItem.IsEmpty() And Not Attributes.NonFinancialIndicatorByPeriod) Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(Composer, "ValuePresence");
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DocumentData",
		FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Composer));
	Query.SetParameter("BeginOfPeriod", Attributes.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", Attributes.PeriodEnding);
	Query.SetParameter("Ref", Document);
	
	Query.Text =
	"SELECT ALLOWED
	|	DocumentData.PeriodType AS PeriodType,
	|	&TextAnalyst1,
	|	DocumentData.Scenario AS Scenario,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Period AS Period,
	|	DocumentData.SubperiodNumber AS SubperiodNumber,
	|	DocumentData.NonFinancialItem AS NonFinancialItem,
	|	DocumentData.Value AS Value,
	|	DocumentData.Currency AS Currency
	|INTO DataOfTableParts
	|FROM
	|	&DocumentData AS DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SetValuesForNonFinancialItemsIndicatorValues.Factor AS Factor,
	|	SetValuesForNonFinancialItemsIndicatorValues.Value AS Value,
	|	SetValuesForNonFinancialItemsIndicatorValues.Currency AS Currency
	|INTO HeaderIndicators
	|FROM
	|	Document.SetValuesForNonFinancialItems.IndicatorValues AS SetValuesForNonFinancialItemsIndicatorValues
	|WHERE
	|	SetValuesForNonFinancialItemsIndicatorValues.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE AS Active,
	|	&BeginOfPeriod AS BeginOfPeriod,
	|	&PeriodEnding AS PeriodEnding,
	|	CAST(ISNULL(HeaderIndicators.Factor, DataOfTableParts.NonFinancialItem) AS Catalog.NonFinancialItemsOfBudgets).Periodicity AS Periodicity,
	|	DataOfTableParts.PeriodType AS PeriodType,
	|	DataOfTableParts.Period AS Period,
	|	&TextAnalyst2,
	|	DataOfTableParts.Scenario AS Scenario,
	|	DataOfTableParts.Organization AS Organization,
	|	DataOfTableParts.Department AS Department,
	|	DataOfTableParts.SubperiodNumber AS SubperiodNumber,
	|	ISNULL(HeaderIndicators.Factor, DataOfTableParts.NonFinancialItem) AS NonFinancialItem,
	|	ISNULL(HeaderIndicators.Value, DataOfTableParts.Value) AS IndicatorValue,
	|	ISNULL(HeaderIndicators.Currency, DataOfTableParts.Currency) AS Currency
	|FROM
	|	DataOfTableParts AS DataOfTableParts
	|		LEFT JOIN HeaderIndicators AS HeaderIndicators
	|		ON (TRUE)";
	
	TextAnalyst1 = "";
	TextAnalyst2 = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst1 = TextAnalyst1 + ?(TextAnalyst1 = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"DocumentData.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextAnalyst2 = TextAnalyst2 + ?(TextAnalyst2 = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"DataOfTableParts.Dimension%1 AS Dimension%1",
				DimensionNumber);
	EndDo;
	Query.Text = StrReplace(Query.Text, "&TextAnalyst1", TextAnalyst1);
	Query.Text = StrReplace(Query.Text, "&TextAnalyst2", TextAnalyst2);
	
	DocumentData = Query.Execute().Select();
	
	TableOfConduct = InformationRegisters.NonFinancialItemValues.CreateRecordSet().Unload();
	
	While DocumentData.Next() Do
		
		If ValueIsFilled(DocumentData.Period) Then
			
			NewRow = TableOfConduct.Add();
			FillPropertyValues(NewRow, DocumentData);
			NewRow.EndDate = WorkingWithClientServerPeriods.PeriodEndDate_(NewRow.Period,
					DocumentData.Periodicity);
			
		ElsIf DocumentData.PeriodType = "ValidFrom" Then
			
			NewRow = TableOfConduct.Add();
			FillPropertyValues(NewRow, DocumentData);
			NewRow.Period = DocumentData.BeginOfPeriod;
			
		Else
			
			DateOfProcessing = DocumentData.BeginOfPeriod;
			While DateOfProcessing <= DocumentData.PeriodEnding Do
				NewRow = TableOfConduct.Add();
				FillPropertyValues(NewRow, DocumentData);
				NewRow.Period = DateOfProcessing;
				NewRow.EndDate = WorkingWithClientServerPeriods.PeriodEndDate_(DateOfProcessing,
						DocumentData.Periodicity);
				DateOfProcessing = WorkingWithClientServerPeriods.AddInterval(DateOfProcessing,
						DocumentData.Periodicity,
						1);
			EndDo;
			
		EndIf;
		
	EndDo;
	
	TablesForRegisteredRecords.Insert("TableNonFinancialItemValues", TableOfConduct);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
