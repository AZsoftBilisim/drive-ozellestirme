#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Generates a table with the materials that have the greatest delay in providing data from the production schedule model.
//
// Parameters:
//  Parameters  - Structure - report generation parameters:
//		* ReferenceOrder - DocumentRef.ProductionOrder2_2 - the order whose schedule needs to be analyzed.
//		* QuantityOfUnits - Number - the maximum number of item items for which data should be returned.
//			Data sampling and traversal are performed in descending order of the time delay in the provision.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure GetMaterialsWithGreatestDelayInSecuring(Parameters, StorageAddress) Export
	
	ReferenceOrder = Parameters.ReferenceOrder;
	UnitsLeft = Parameters.QuantityOfUnits;
	
	DataCompositionSchema = Reports.DemandForMaterialsAccordingToProductionScheduleModel.GetTemplate("MainDataCompositionSchema");
	
	VariantName = "MaterialsWithDelayInProvidingContext";
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.LoadSettings(DataCompositionSchema.SettingVariants.Find(VariantName).Settings);
	
	ReportSettings = SettingsComposer.GetSettings();
	ExternalSets = New Structure;
	
	Parameter = OrderParameter(ReportSettings);
	Parameter.Value = ReferenceOrder;
	
	ConfigureDatasets(DataCompositionSchema, ReportSettings, ExternalSets);
	
	// Layout and output.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		ReportSettings,
		,
		,
		Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalSets, , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ResultOutput = New ValueTable;
	OutputProcessor.SetObject(ResultOutput);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	Result = ResultOutput.CopyColumns();
	For IndexOf = 0 To ResultOutput.Count()-1 Do
		
		NewRow = Result.Add();
		FillPropertyValues(NewRow, ResultOutput[IndexOf]);
		
		UnitsLeft = UnitsLeft - 1;
		If UnitsLeft = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DemandForMaterialsAccordingToProductionScheduleModel);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure ConfigureDatasets(DataCompositionSchema, ReportSettings, ExternalSets) Export
	
	// Changing the request text.
	QueryText = DataCompositionSchema.DataSets.Demand.Query;
	InsertVolumeWeightParametersInRequestText(QueryText);
	DataCompositionSchema.DataSets.Demand.Query = QueryText;
	
	// Filling in external data sets.
	FillExternalSets(ReportSettings, ExternalSets);
	
EndProcedure

Procedure InsertVolumeWeightParametersInRequestText(QueryText)
	
	QueryTextWeight = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"UsedMaterials.Products.UnitOfMeasure",
		"UsedMaterials.Products");
	QueryText = StrReplace(QueryText, "&ItemWeight", QueryTextWeight);
	
	QueryTextVolumeM3 = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"UsedMaterials.Products.UnitOfMeasure",
		"UsedMaterials.Products");
	QueryText = StrReplace(QueryText, "&TheVolumeOfTheItem", QueryTextVolumeM3);
	
EndProcedure

Procedure FillExternalSets(ReportSettings, ExternalSets)
	
	ReferenceOrder = OrderParameter(ReportSettings).Value;
	
	If Not ValueIsFilled(ReferenceOrder) Then
		Raise NStr("vi = 'Chưa điền giá trị tham số ""Lệnh"".';
					|ru = 'Не заполнено значение параметра ""Распоряжение"".';
					|en = 'The ""Reference"" parameter is blank.'; fa = 'The ""Reference"" parameter is blank.';
					|it = 'Не заполнено значение параметра ""Распоряжение"".';
					|pl = 'The ""Reference"" parameter is blank.';
					|tr = 'Не заполнено значение параметра ""Распоряжение"".'");
	EndIf;
	
	Supply = DatesOfMaterialProvision(ReferenceOrder);
	ExternalSets.Insert("Supply", Supply);
	
EndProcedure

Function OrderParameter(ReportSettings)
	
	LayoutParameter = New DataCompositionParameter("ReferenceOrder");
	Result = ReportSettings.DataParameters.FindParameterValue(LayoutParameter);
	If Result = Undefined Then
		Raise NStr("vi = 'Thiếu tham số ""Lệnh""';
					|ru = 'Отсутствует обязательный параметр ""Распоряжение""';
					|en = 'Missing required parameter: ""Reference""'; fa = 'Missing required parameter: ""Reference""';
					|it = 'Opzione obbligatoria ""Disposizione"" mancante';
					|pl = 'Brak wymaganego parametru ""Zamówienie""';
					|tr = 'Zorunlu ""Talimat"" parametresi bulunmamaktadır'");
	Else
		Return Result;
	EndIf;
	
EndFunction

Function DatesOfMaterialProvision(ReferenceOrder)
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	
	If Common.ObjectAttributeValue(ReferenceOrder, "DynamicStructure") Then
		
		ConditionsOfReceipt = New Structure;
		ConditionsOfReceipt.Insert("ProductionOrder", ReferenceOrder);
		ProductionManagement.CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(
			TempTablesManager, ConditionsOfReceipt, True, True, InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel());
		
		Query.TempTablesManager = TempTablesManager;
		Query.Text = 
		"SELECT
		|	Table.Stage             AS ProductionStage,
		|	Table.Products     AS Products,
		|	Table.Characteristic   AS Characteristic,
		|	Table.AvailabilityDate  AS AvailabilityDate
		|FROM
		|	TTProductionScheduleRestrictionsOnMaterials AS Table";
		
	Else
		
		Query.Text =
			"SELECT
			|	ProductionStage2_2.Ref AS Ref
			|FROM
			|	Document.ProductionStage2_2 AS ProductionStage2_2
			|WHERE
			|	ProductionStage2_2.ReferenceOrder = &ReferenceOrder
			|	AND ProductionStage2_2.Posted
			|	AND (ProductionStage2_2.Status IN (
			|		VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
			|		VALUE(Enum.StatusesOfProductionStages2_2.Generated1),
			|		VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion))
			|		OR ProductionStage2_2.DynamicStructure
			|			AND ProductionStage2_2.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
			|	)";
		Query.SetParameter("ReferenceOrder", ReferenceOrder);
		ProductionStages = Query.Execute().Unload().UnloadColumn("Ref");
		
		SetPrivilegedMode(True);
		ProductionManagement.CreateTTProductionScheduleConstraintsOnMaterials(
			TempTablesManager,
			ProductionStages,
			True,
			False);
		SetPrivilegedMode(False);
		
		Query.TempTablesManager = TempTablesManager;
		Query.Text = 
			"SELECT
			|	Table.ProductionStage AS ProductionStage,
			|	Table.Products     AS Products,
			|	Table.Characteristic   AS Characteristic,
			|	Table.AvailabilityDate  AS AvailabilityDate
			|FROM
			|	TTProductionScheduleRestrictionsOnMaterials AS Table";
			
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf
