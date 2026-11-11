#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	SetRequiredSettings(UserSettingsModified);
	
	// Substitution.
	QueryText = DataCompositionSchema.DataSets.CatProducts.Query;
	
	SourceOfPackaging = "AllProducts.UnitOfMeasure";
	SourceOfProducts = "AllProducts.Ref";
	Substitution = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(SourceOfPackaging, SourceOfProducts);
	QueryText = StrReplace(QueryText, "&QueryTextItemWeight", Substitution);
	Substitution = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(SourceOfPackaging, SourceOfProducts);
	QueryText = StrReplace(QueryText, "&QueryTextTheVolumeOfTheItem", Substitution);
	DataCompositionSchema.DataSets.CatProducts.Query = QueryText;
	
	// Report generation.
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	CompositionProcessor = New DataCompositionProcessor;
	ExternalDataSets = ExternalDataSets();
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//	Form			- ClientApplicationForm	- report form.
//	VariantKey	- String			- The name of the predefined report variant or the unique ID of the custom one.
//	Settings		- See ReportsClientServer.GetDefaultReportSettings.
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary									- parameters of the context in which the report is used.
//	SchemaKey							- String										- ID of the current configuration Builder schema.
//	VariantKey						- String, Undefined							- name of the predefined or unique ID of the custom
//																							version of the report.
//																							Undefined when calling for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings, Undefined		- report variant settings that will be loaded
//																							into the settings Builder after it is initialized.
//																							Undefined when the option settings do not need to be loaded (already loaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings,
//											Undefined - user settings that will be loaded into
//																							the settings Builder after it is initialized.
//																							Undefined when user settings do not need to be loaded
//																							(already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseGoodsQualityControl") Then
		
		FieldsToDelete__ = New Array();
		FieldsToDelete__.Add("FollowUpReceipt");
		FieldsToDelete__.Add("FollowUpExpense");
		FieldsToDelete__.Add("OpeningBalanceOnControl");
		FieldsToDelete__.Add("ClosingBalanceIsUnderControl");
		FieldsToDelete__.Add("QuantityUnderControlReceiptWeight");
		FieldsToDelete__.Add("QuantityUnderControlExpenseWeight");
		FieldsToDelete__.Add("OpeningBalanceOnControlIsWeight");
		FieldsToDelete__.Add("ClosingBalanceOnControlWeight");
		FieldsToDelete__.Add("QuantityUnderControlReceiptVolume");
		FieldsToDelete__.Add("QuantityUnderControlExpenseVolume");
		FieldsToDelete__.Add("OpeningBalanceOnVolumeControl");
		FieldsToDelete__.Add("ClosingBalanceOnVolumeControl");
		
		SettingsStructure = NewDCSettings.Structure;
		
		For Each StructureItem In SettingsStructure Do
			If TypeOf(StructureItem) = Type("DataCompositionTable") Then
				
				For Each LayoutStringInfo In StructureItem.Rows Do
					Items = LayoutStringInfo.Selection.Items;
					DeleteFields(Items, FieldsToDelete__);
				EndDo;
				For Each LayoutColumn In StructureItem.Columns Do
					Items = LayoutColumn.Selection.Items;
					DeleteFields(Items, FieldsToDelete__);
				EndDo;
				
			ElsIf TypeOf(StructureItem) = Type("DataCompositionGroup") Then
				
				Items = StructureItem.Selection.Items;
				DeleteFields(Items, FieldsToDelete__);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SchemaKey		= VariantKey;
	FieldHeaders	= ParameterizableFieldHeaders();
	
	DataCompositionServer.SetHeadersOfSelectedFields(NewDCSettings.Selection.Items, FieldHeaders);
	
	If TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	SettingID = NewDCSettings.Selection.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then 
			DataCompositionServer.SetHeadersOfSelectedFields(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	EndDate = DataCompositionClientServer.GetParameter(SettingsComposer, "EndDate");
	
	If EndDate <> Undefined And EndDate.Use Then
		If TypeOf(EndDate) = Type("StandardBeginningDate") Then
			If BegOfDay(EndDate.Value.Date) < BegOfDay(CurrentSessionDate()) Then
				EndDate.Value = BegOfDay(CurrentSessionDate());
			EndIf;
		Else
			If BegOfDay(EndDate.Value) < BegOfDay(CurrentSessionDate()) Then
				EndDate.Value = BegOfDay(CurrentSessionDate());
			EndIf;
		EndIf;
	EndIf;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Function ExternalDataSets()
	
	TemplateForFilters = GetTemplate("ExternalDataSource");
	Address = PutToTempStorage(TemplateForFilters);
	SettingsSource = New DataCompositionAvailableSettingsSource(Address);
	
	TemplateSettingsComposer = New DataCompositionSettingsComposer;
	TemplateSettingsComposer.Initialize(SettingsSource);
	TemplateSettingsComposer.LoadSettings(SettingsComposer.GetSettings());
	TemplateSettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	
	// Selection by segments.
	ThisParameterIsUsedForSegmentSelection = DataCompositionClientServer.GetParameter(
		SettingsComposer, "FilterByProductSegmentIsUsed");
	HasFilter = ThisParameterIsUsedForSegmentSelection.Value And ThisParameterIsUsedForSegmentSelection.Use;
	DataCompositionClientServer.SetParameter(TemplateSettingsComposer.Settings, "FilterByProductSegmentIsUsed", True, HasFilter);
	
	DisplayShipmentsOnCollateralDate = DataCompositionClientServer.GetParameter(SettingsComposer, "DisplayShipmentsOnCollateralDate");
	FilterByProductSegmentIsUsed = DataCompositionClientServer.GetParameter(SettingsComposer, "FilterByProductSegmentIsUsed");
	QuantityUnits = DataCompositionClientServer.GetParameter(SettingsComposer, "QuantityUnits");
	EndDate = DataCompositionClientServer.GetParameter(SettingsComposer, "EndDate");
	EndDateValue = '00010101';
	If TypeOf(EndDate.Value) = Type("StandardBeginningDate") Then
		EndDateValue = EndDate.Value.Date;
	Else
		EndDateValue = EndDate.Value;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(TemplateForFilters, TemplateSettingsComposer.GetSettings(), , , ,False);
	Query = DataCompositionServer.GETRequestFromLayoutTemplate(Template, "Set");
	Query.Text = QueryTextWithSubstitutions(Query.Text, DisplayShipmentsOnCollateralDate);
	
	DeleteFromTempStorage(Address);
	
	Query.SetParameter("DisplayShipmentsOnCollateralDate", DisplayShipmentsOnCollateralDate.Value);
	Query.SetParameter("FilterByProductSegmentIsUsed", FilterByProductSegmentIsUsed.Value);
	Query.SetParameter("QuantityUnits", QuantityUnits.Value);
	Query.SetParameter("EndDate", EndDateValue);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.Execute();

	PeriodsTable = New ValueTable();
	PeriodsTable.Columns.Add("Period", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	EndDateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "EndDate");
	If EndDateParameter = Undefined Then
		EndDate = BegOfDay(CurrentSessionDate());
	ElsIf TypeOf(EndDateParameter.Value) = Type("StandardBeginningDate") Then
		EndDate = EndDateParameter.Value.Date;
	ElsIf TypeOf(EndDateParameter.Value) = Type("Date") Then
		EndDate = EndDateParameter.Value;
	Else
		EndDate = BegOfDay(CurrentSessionDate());
	EndIf;
	
	PeriodMinimum = BegOfDay(CurrentSessionDate());
	PeriodMaximum = EndDate;
	
	While PeriodMinimum <= PeriodMaximum Do
		NewRow = PeriodsTable.Add();
		NewRow.Period = PeriodMinimum;
		PeriodMinimum = PeriodMinimum + 3600 * 24;
	EndDo;
	
	Query.SetParameter("PeriodsTable", PeriodsTable);
	Table = UploadTableForCalculatingBalances(Query);
	Query.TempTablesManager.Close();
	
	AddAndFillColumnsStartAndEndRemainder(Table);
	
	ExternalDataSets = New Structure("MainSet", Table);
	
	Return ExternalDataSets;
	
EndFunction

Procedure AddAndFillColumnsStartAndEndRemainder(Table)
	
	Table.Columns.Add("ClosingBalance", Common.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ClosingBalanceWeight", Common.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ClosingBalanceVolume", Common.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ClosingBalanceIsUnderControl", Common.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ClosingBalanceOnControlWeight", Common.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ClosingBalanceOnVolumeControl", Common.TypeDescriptionNumber(15, 3));
	
	ClosingBalance = 0;
	ClosingBalanceWeight = 0;
	ClosingBalanceVolume = 0;
	
	ClosingBalanceIsUnderControl = 0;
	ClosingBalanceOnControlWeight = 0;
	ClosingBalanceOnVolumeControl = 0;
	
	PropertiesNames = "Products, Characteristic, Warehouse, Purpose";
	RecordKey = New Structure(PropertiesNames);
	
	For Each TableRow In Table Do
		
		ChangedRecord = (RecordKey.Products <> TableRow.Products
				Or RecordKey.Characteristic <> TableRow.Characteristic
				Or RecordKey.Warehouse <> TableRow.Warehouse
				Or RecordKey.Purpose <> TableRow.Purpose);
		
		If ChangedRecord Then
			ClosingBalance = TableRow.OpeningBalance;
			ClosingBalanceWeight = TableRow.StartBalanceWeight;
			ClosingBalanceVolume = TableRow.StartBalanceVolume;
			ClosingBalanceIsUnderControl = TableRow.OpeningBalanceOnControl;
			ClosingBalanceOnControlWeight = TableRow.OpeningBalanceOnControlIsWeight;
			ClosingBalanceOnVolumeControl = TableRow.OpeningBalanceOnVolumeControl;
			FillPropertyValues(RecordKey, TableRow);
		EndIf;
		
		TableRow.OpeningBalance = ClosingBalance;
		TableRow.StartBalanceWeight = ClosingBalanceWeight;
		TableRow.StartBalanceVolume = ClosingBalanceVolume;
		
		TableRow.OpeningBalanceOnControl = ClosingBalanceIsUnderControl;
		TableRow.OpeningBalanceOnControlIsWeight = ClosingBalanceOnControlWeight;
		TableRow.OpeningBalanceOnVolumeControl = ClosingBalanceOnVolumeControl;
		
		If TableRow.GroupOfPeriods < 2 Then
			ClosingBalance = TableRow.OpeningBalance
				+ TableRow.CountReceipt - TableRow.CountExpense;
			ClosingBalanceWeight = TableRow.StartBalanceWeight
				+ TableRow.QuantityReceiptWeight - TableRow.QuantityConsumptionWeight;
			ClosingBalanceVolume = TableRow.StartBalanceVolume
				+ TableRow.QuantityReceiptVolume - TableRow.QuantityConsumptionVolume;
			ClosingBalanceIsUnderControl = TableRow.OpeningBalanceOnControl
				+ TableRow.FollowUpReceipt - TableRow.FollowUpExpense;
			ClosingBalanceOnControlWeight = TableRow.OpeningBalanceOnControlIsWeight
				+ TableRow.QuantityUnderControlReceiptWeight - TableRow.QuantityUnderControlExpenseWeight;
			ClosingBalanceOnVolumeControl = TableRow.OpeningBalanceOnVolumeControl
				+ TableRow.QuantityUnderControlReceiptVolume - TableRow.QuantityUnderControlExpenseVolume;
		EndIf;
		
		TableRow.ClosingBalance = ClosingBalance;
		TableRow.ClosingBalanceWeight = ClosingBalanceWeight;
		TableRow.ClosingBalanceVolume = ClosingBalanceVolume;
		TableRow.ClosingBalanceIsUnderControl = ClosingBalanceIsUnderControl;
		TableRow.ClosingBalanceOnControlWeight = ClosingBalanceOnControlWeight;
		TableRow.ClosingBalanceOnVolumeControl = ClosingBalanceOnVolumeControl;
		
	EndDo;
	
EndProcedure

Function QueryTextWithSubstitutions(QueryText, DisplayShipmentsOnCollateralDate)
	
	SourceOfProducts = "Table.Products";
	SourceOfPackaging = SourceOfProducts + ".UnitOfMeasure";
	Substitution = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(SourceOfPackaging, SourceOfProducts);
	QueryText = StrReplace(QueryText, "&QueryTextItemWeight", Substitution);
	Substitution = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(SourceOfPackaging, SourceOfProducts);
	QueryText = StrReplace(QueryText, "&QueryTextTheVolumeOfTheItem", Substitution);
	Substitution =
		"CASE
		|	WHEN &QuantityUnits = 0
		|		THEN
		|			1
		|	WHEN &QuantityUnits = 1
		|		THEN
		|			1/ %SourceOfProducts%.UnitFactorForReports
		|END";
	Substitution = StrReplace(Substitution, "%SourceOfProducts%", SourceOfProducts);
	QueryText = StrReplace(QueryText, "&RequestTextCoefficientOfOne", Substitution);
	
	SubstitutionMaximumDateOfShipmentDateOfReceipt = "";
	If DisplayShipmentsOnCollateralDate.Value Then
		SubstitutionMaximumDateOfShipmentDateOfReceipt =
			"CASE
			|	WHEN AvailabilityInformation.DateOfReceipt <
			|			CASE
			|				WHEN AvailabilityInformation.RequestShipmentOn = DATETIME(1, 1, 1)
			|					THEN
			|						BEGINOFPERIOD(ReportOrders.IBDocumentDate, DAY)
			|				ELSE AvailabilityInformation.RequestShipmentOn
			|			END
			|		THEN
			|			CASE
			|				WHEN AvailabilityInformation.RequestShipmentOn = DATETIME(1, 1, 1)
			|					THEN
			|						BEGINOFPERIOD(ReportOrders.IBDocumentDate, DAY)
			|				ELSE AvailabilityInformation.RequestShipmentOn
			|			END
			|	ELSE AvailabilityInformation.DateOfReceipt
			|END";
	Else
		SubstitutionMaximumDateOfShipmentDateOfReceipt =
			"CASE
			|	WHEN AvailabilityInformation.RequestShipmentOn = DATETIME(1, 1, 1)
			|		THEN
			|			BEGINOFPERIOD(ReportOrders.IBDocumentDate, DAY)
			|	ELSE AvailabilityInformation.RequestShipmentOn
			|END";
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&SubstitutionMaximumDateOfShipmentDateOfReceipt", SubstitutionMaximumDateOfShipmentDateOfReceipt);
	QueryText = StrReplace(QueryText,
		"&SubstitutionMaximumProductionScheduleDateOfShipmentDateOfReceipt",
		"CASE
		|	WHEN &SubstitutionDateOfReceiptAccordingToProductionSchedule < Demands.RequestShipmentOn THEN
		|		Demands.RequestShipmentOn
		|	ELSE
		|		&SubstitutionDateOfReceiptAccordingToProductionSchedule
		|	END");
	QueryText = StrReplace(QueryText,
		"&SubstitutionDateOfReceiptAccordingToProductionSchedule",
		"CASE
		|	WHEN AvailabilityInformation.DateOfReceipt <> DATETIME(1, 1, 1)
		|		THEN AvailabilityInformation.DateOfReceipt
		|	WHEN ScheduleDates.Ending IS NOT NULL
		|		THEN BEGINOFPERIOD(ScheduleDates.Ending, DAY)
		|	ELSE DATETIME(1, 1, 1)
		|END");
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	Return QueryText;
	
EndFunction

Function UploadTableForCalculatingBalances(Query)
	
	SetPrivilegedMode(True);
	Query.Text =
		"SELECT DISTINCT
		|	CAST(Table.Purpose AS Catalog.Assignments) AS Purpose,
		|	CAST(Table.Purpose AS Catalog.Assignments).Partner AS Partner,
		|	CAST(Table.Purpose AS Catalog.Assignments).LineOfBusiness AS LineOfBusiness,
		|	CAST(Table.Purpose AS Catalog.Assignments).Contract AS Contract
		|INTO Assignments
		|FROM
		|	TTProductCalendar AS Table
		|INDEX BY
		|	Purpose";
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text =
		"SELECT
		|	Table.Period AS Period
		|INTO TTPeriods
		|FROM
		|	&PeriodsTable AS Table
		|;
		|
		|/////////////////////////////
		|SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OpeningBalance AS OpeningBalance,
		|	Table.StartBalanceWeight AS StartBalanceWeight,
		|	Table.StartBalanceVolume AS StartBalanceVolume,
		|	Table.OpeningBalanceOnControl AS OpeningBalanceOnControl,
		|	Table.OpeningBalanceOnControlIsWeight AS OpeningBalanceOnControlIsWeight,
		|	Table.OpeningBalanceOnVolumeControl AS OpeningBalanceOnVolumeControl
		|INTO TTProducts_1
		|FROM
		|	TTProductCalendar AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|	
		|;
		|
		|/////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	ISNULL(Assignments.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
		|	ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
		|	ISNULL(Assignments.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Contract,
		|	1 AS GroupOfPeriods,
		|	TablePeriods.Period AS Period,
		|	ISNULL(Table.Recorder, UNDEFINED) AS Recorder,
		|	ISNULL(Table.Date, DATETIME(1, 1, 1)) AS Date,
		|	ISNULL(Table.CountReceipt, 0) AS CountReceipt,
		|	ISNULL(Table.QuantityReceiptWeight, 0) AS QuantityReceiptWeight,
		|	ISNULL(Table.QuantityReceiptVolume, 0) AS QuantityReceiptVolume,
		|	ISNULL(Table.CountExpense, 0) AS CountExpense,
		|	ISNULL(Table.QuantityConsumptionWeight, 0) AS QuantityConsumptionWeight,
		|	ISNULL(Table.QuantityConsumptionVolume, 0) AS QuantityConsumptionVolume,
		|	Goods.OpeningBalance AS OpeningBalance,
		|	Goods.StartBalanceWeight AS StartBalanceWeight,
		|	Goods.StartBalanceVolume AS StartBalanceVolume,
		|	ISNULL(Table.FollowUpReceipt, 0) AS FollowUpReceipt,
		|	ISNULL(Table.QuantityUnderControlReceiptWeight, 0) AS QuantityUnderControlReceiptWeight,
		|	ISNULL(Table.QuantityUnderControlReceiptVolume, 0) AS QuantityUnderControlReceiptVolume,
		|	ISNULL(Table.FollowUpExpense, 0) AS FollowUpExpense,
		|	ISNULL(Table.QuantityUnderControlExpenseWeight, 0) AS QuantityUnderControlExpenseWeight,
		|	ISNULL(Table.QuantityUnderControlExpenseVolume, 0) AS QuantityUnderControlExpenseVolume,
		|	Goods.OpeningBalanceOnControl AS OpeningBalanceOnControl,
		|	Goods.OpeningBalanceOnControlIsWeight AS OpeningBalanceOnControlIsWeight,
		|	Goods.OpeningBalanceOnVolumeControl AS OpeningBalanceOnVolumeControl
		|FROM
		|	TTProducts_1 AS Goods
		|		
		|		LEFT JOIN TTPeriods AS TablePeriods
		|		ON TRUE
		|		
		|		LEFT JOIN TTProductCalendar AS Table
		|		ON Table.Products = Goods.Products
		|		 AND Table.Characteristic = Goods.Characteristic
		|		 AND Table.Warehouse = Goods.Warehouse
		|		 AND Table.Purpose = Goods.Purpose
		|		 AND Table.Period = TablePeriods.Period
		|		
		|		LEFT JOIN Assignments AS Assignments
		|		ON Assignments.Purpose = Goods.Purpose
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	ISNULL(Assignments.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
		|	ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
		|	ISNULL(Assignments.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Contract,
		|	Table.GroupOfPeriods AS GroupOfPeriods,
		|	Table.Period AS Period,
		|	Table.Recorder AS Recorder,
		|	Table.Date AS Date,
		|	Table.CountReceipt AS CountReceipt,
		|	Table.QuantityReceiptWeight AS QuantityReceiptWeight,
		|	Table.QuantityReceiptVolume AS QuantityReceiptVolume,
		|	Table.CountExpense AS CountExpense,
		|	Table.QuantityConsumptionWeight AS QuantityConsumptionWeight,
		|	Table.QuantityConsumptionVolume AS QuantityConsumptionVolume,
		|	Table.OpeningBalance AS OpeningBalance,
		|	Table.StartBalanceWeight AS StartBalanceWeight,
		|	Table.StartBalanceVolume AS StartBalanceVolume,
		|	Table.FollowUpReceipt AS FollowUpReceipt,
		|	Table.QuantityUnderControlReceiptWeight AS QuantityUnderControlReceiptWeight,
		|	Table.QuantityUnderControlReceiptVolume AS QuantityUnderControlReceiptVolume,
		|	Table.FollowUpExpense AS FollowUpExpense,
		|	Table.QuantityUnderControlExpenseWeight AS QuantityUnderControlExpenseWeight,
		|	Table.QuantityUnderControlExpenseVolume AS QuantityUnderControlExpenseVolume,
		|	Table.OpeningBalanceOnControl AS OpeningBalanceOnControl,
		|	Table.OpeningBalanceOnControlIsWeight AS OpeningBalanceOnControlIsWeight,
		|	Table.OpeningBalanceOnVolumeControl AS OpeningBalanceOnVolumeControl
		|FROM
		|	TTProductCalendar AS Table
		|		
		|		LEFT JOIN TTPeriods AS TablePeriods
		|		ON TablePeriods.Period = Table.Period
		|		
		|		LEFT JOIN Assignments AS Assignments
		|		ON Assignments.Purpose = Table.Purpose
		|		
		|WHERE
		|	TablePeriods.Period IS NULL
		|ORDER BY
		|	Products, Characteristic, Warehouse, Purpose, Period, Date, Recorder, GroupOfPeriods";
	Table = Query.Execute().Unload();
	Return Table;
	
EndFunction

Procedure DeleteFields(Items, FieldsToDelete__)
	
	FieldsTotal = Items.Count();
	For Counter = 1 To FieldsTotal Do
		
		ChoiceItem = Items[FieldsTotal - Counter];
		If TypeOf(ChoiceItem) = Type("DataCompositionSelectedField") Then
			
			For Each FieldToBeDeleted In FieldsToDelete__ Do
				If ChoiceItem.Field = New DataCompositionField(FieldToBeDeleted) Then
					Items.Delete(ChoiceItem);
				EndIf;
			EndDo;
			
		ElsIf TypeOf(ChoiceItem) = Type("DataCompositionSelectedFieldGroup") Then
			
			DeleteFields(ChoiceItem.Items, FieldsToDelete__);
			If ChoiceItem.Items.Count() = 0 Then
				Items.Delete(ChoiceItem);
			EndIf;
			If ChoiceItem.Title = NStr("vi = 'Với chất lượng đã được xác nhận';
										|ru = 'С подтвержденным качеством';
										|en = 'With confirmed quality'; fa = 'با کیفیت تأییدشده';
										|it = 'With confirmed quality';
										|pl = 'With confirmed quality';
										|tr = 'Onaylanmış kaliteli'") Then
				ChoiceItem.Title = "";
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf