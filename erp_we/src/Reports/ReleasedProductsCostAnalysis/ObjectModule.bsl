#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary								- parameters of the context in which the report is used.
//	SchemaKey							- String									- ID of the current configuration Builder schema.
//	VariantKey						- String									- name of the predefined or unique ID of the custom
//																						version of the report.
//										- Undefined 								- a call for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		If NewDCUserSettings = Undefined Then
			UserSettings = Context.Report.SettingsComposer.UserSettings; // DataCompositionUserSettings -
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, UserSettings);
		Else
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		EndIf;
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
		ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Report.ReleasedProductsCostAnalysis.ObjectModule.OnComposeResult");
	
	StandardProcessing = False;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	BatchAccountingParameterVersion22 = DataCompositionClientServer.GetParameter(SettingsComposer, "BatchAccountingVersion22");
	If BatchAccountingParameterVersion22 <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "BatchAccountingVersion22",
			CalculationOfCostCached.BatchAccountingVersion22());
	EndIf;
	
	ParameterDateOfTransitionToBatchAccountingVersion22 = DataCompositionClientServer.GetParameter(SettingsComposer, "DateOfMigrationToBatchAccounting22");
	If ParameterDateOfTransitionToBatchAccountingVersion22 <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "DateOfMigrationToBatchAccounting22",
			CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	EndIf;
	
	QueryTextMaterial_ = CalculationOfCostLocalization.AnalysisOfCostOfProduction_RequestText_();
	If ValueIsFilled(QueryTextMaterial_) Then
		
		DataSet = DataCompositionSchema.DataSets.Costs; // DataCompositionSchemaDataSetUnion
		DataSet.Items.Material_.Query = QueryTextMaterial_;
		
	EndIf;
	
	QueryTextMaterial_Version22 = QueryTextMaterial_Version22();
	
	DataSet = DataCompositionSchema.DataSets.Costs; // DataCompositionSchemaDataSetUnion
	DataSet.Items.Material_Version22.Query = QueryTextMaterial_Version22;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	RemoveMetricsFromDecryptionSelections(SettingsComposer, ReportSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ResultDocument.TableHeight);
	
EndProcedure

#EndRegion

#Region Private

// Adjusts the available values for the "cost Data" data layout parameter, depending on the option.
// 
// Parameters:
//	Document - Document Link.Distribution of labor costs - a decoding document.
//	NewDCSettings - DataCompositionSettings - overriding the report settings.
//	NewDCUserSettings - DataCompositionUserSettings - data layout scheme settings.
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	OptionsKeys = KeysOfPredefinedOptions();
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	PredefinedOptionKey = Common.ObjectAttributeValue(PredefinedOption, "VariantKey");
	If Not ValueIsFilled(PredefinedOption) 
		Or OptionsKeys.Find(PredefinedOptionKey) = Undefined Then
		Return;
	EndIf;
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("Cost_Data");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOption.VariantKey = "AnalysisOfReleasedProductCostByEnterprise"
		Or PredefinedOption.VariantKey = "AnalysisOfCostOfManufacturedProducts22ForEnterprise"
		Or PredefinedOption.VariantKey = "CompareReleasedProductCostByOrdersByEnterprise"
		Or PredefinedOption.VariantKey = "ProductionAtPlannedCostOfEnterprise" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	Else
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Bằng tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
	EndIf;
	
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = KeysOfPredefinedOptions();
	
	While OptionsKeys.Find(Variant.VariantKey) = Undefined
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

Function KeysOfPredefinedOptions()
	
	OptionsKeys = New Array;
	OptionsKeys.Add("ReleasedProductsCostAnalysis");
	OptionsKeys.Add("AnalysisOfReleasedProductCostByEnterprise");
	OptionsKeys.Add("ComparisonOfCostOfManufacturedProductsByOrders");
	OptionsKeys.Add("CompareReleasedProductCostByOrdersByEnterprise");
	OptionsKeys.Add("ProductionAtPlannedCostByCompany");
	
	Return OptionsKeys;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = New Array; // Array of String
		FieldsToDelete__.Add("PermanentDifference");
		FieldsToDelete__.Add("CostTD");
		FieldsToDelete__.Add("CostInTaxAccounting");
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		For Each Field In FieldsToDelete__ Do 
			RemoveSelectionElementRecursivelyFromAllReportSettings(FormSettingsComposer, Field);
		EndDo;
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
	If Not GetFunctionalOption("AITAccounting") Then
		FieldsToDelete__ = New Array; // Array of String
		FieldsToDelete__.Add("AIT");
		For Each Field In FieldsToDelete__ Do 
			RemoveSelectionElementRecursivelyFromAllReportSettings(FormSettingsComposer, Field);
		EndDo;
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

Procedure RemoveMetricsFromDecryptionSelections(Var_SettingsComposer, ReportSettings)
	If Var_SettingsComposer.FixedSettings.AdditionalProperties.Property("DetailsMode")
		And Var_SettingsComposer.FixedSettings.AdditionalProperties.DetailsMode Then
		Indicators = New Array; // Array of String
		Indicators.Add("NumberOfCosts");
		Indicators.Add("CostOfCosts");
		Indicators.Add("CostPerProductItem");
		Indicators.Add("QuantityOfCostsPerProductUnit");
		Indicators.Add("CostOfOffBalanceSheetCosts");
		Indicators.Add("CostInTaxAccounting");
		Indicators.Add("CostTD");
		Indicators.Add("PermanentDifference");
		Indicators.Add("CostPerUnitCostOffBalance");
		Indicators.Add("AIT");
		Indicators.Add("TargetCost");
		Indicators.Add("DeviationInCostOfManufacturedProducts");
		Indicators.Add("ProductsQuantity");
		
		For Each Factor In Indicators Do 
			RemoveSelectionElementRecursivelyFromAllReportSettings(ReportSettings, Factor);
		EndDo;
	EndIf;
EndProcedure

Function QueryTextMaterial_Version22()
	
	Return "
	|SELECT ALLOWED DISTINCT
	|	Segments.Products AS Products,
	|	Segments.Characteristic AS Characteristic,
	|	TRUE AS FilterByProductSegmentIsUsed
	|INTO SelectionByProductSegment
	|FROM
	|	InformationRegister.SegmentProducts AS Segments
	|{WHERE
	|	Segments.Segment.* AS ProductSegment,
	|	Segments.Products.* AS Products,
	|	Segments.Characteristic.* AS Characteristic}
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	FilterByProductSegmentIsUsed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	InventoryCost.Organization AS Organization,
	|	BEGINOFPERIOD(InventoryCost.Period, MONTH) AS ActionPeriod
	|INTO PeriodsOfActionOfMediumSlip
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|WHERE
	|	InventoryCost.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|	AND (InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	OR &EndOfPeriod = DATETIME(1, 1, 1))
	|{WHERE
	|	InventoryCost.Organization.*}
	|
	|INDEX BY
	|	ActionPeriod,
	|	Organization
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN NOT Constants.UseProductionManagement2_2
	|			THEN UNDEFINED
	|		WHEN IssueAnalytics.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN IssueAnalytics.Department
	|		WHEN IssueAnalytics.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|			THEN IssueAnalytics.Partner
	|		ELSE IssueAnalytics.WarehouseArea.Department
	|	END AS ProductDepartment,
	|	DD.CorItemsLocationAttributes AS ManufacturedProductDimension,
	|	IssueAnalytics.Products AS ManufacturedProduct,
	|	IssueAnalytics.Characteristic AS ItemVariant,
	|	IssueAnalytics.Products.UnitOfMeasure AS ProductUnitOfMeasure,
	|	CASE
	|		WHEN &ShowDetailsByReleaseSeries
	|			THEN IssueAnalytics.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS ProductionSeries_,
	|	CASE
	|		WHEN Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			THEN Dimension.ProductCostElement
	|		ELSE DD.ProductCostElement
	|	END AS ProductCostElement,
	|	""Lots"" AS CostKind,
	|	Dimension.Products AS Cost_,
	|	Dimension.Characteristic AS CostCharacteristic,
	|	Dimension.Series AS SeriesCosts,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN Dimension.Products.UnitOfMeasure
	|		WHEN &QuantityUnits = 1
	|			THEN Dimension.Products.UnitForReports
	|	END AS CostUnitOfMeasure,
	|	Dimension.StorageLocation AS Department,
	|	CASE
	|		WHEN DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			THEN UNDEFINED
	|		WHEN ProductionStage2_2.Ref IS NOT NULL
	|			THEN ProductionStage2_2.ReferenceOrder
	|		ELSE UNDEFINED
	|	END AS ProductionOrder,
	|	CASE
	|		WHEN &DetailByBatchOfProduction
	|			THEN DD.Lot
	|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
	|	END AS ProductionLot,
	|	CASE
	|		WHEN DD.FinancialAccountingDimension REFS Catalog.AnalyticalInventoryGroups
	|			THEN DD.FinancialAccountingDimension
	|		ELSE VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|	END AS ProductsGroup,
	|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	IssueAnalytics.Purpose AS AssignmentOfProducts,
	|	CASE
	|		WHEN NOT &DetailByPurposes
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		WHEN NOT ManufacturedProduct.Purpose IS NULL
	|			THEN ManufacturedProduct.Purpose
	|		WHEN NOT StageByProducts_.Purpose IS NULL
	|			THEN StageByProducts_.Purpose
	|		WHEN TRUE
	|			THEN IssueAnalytics.Purpose
	|	END AS AssignAProductReceiver,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN DD.Count
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN Dimension.Products.UnitFactorForReports <> 0
	|					THEN DD.Count / Dimension.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS NumberOfCosts,
	|	CASE
	|		WHEN CostCalculationDocument.Ref IS NULL
	|			THEN CASE
	|				WHEN &Cost_Data = 1
	|					THEN DD.Count * (Prices.Cost + Prices.AdditionalExpenseCost + Prices.LaborCosts +
	|						Prices.ItemizedFixedCostsIncludingVAT + Prices.ItemizedVariableCostsIncludingVAT)
	|				WHEN &Cost_Data = 2
	|					THEN DD.Count * (Prices.CostExcludingVAT + Prices.AdditionalExpensesCostExcludingVAT + Prices.LaborCosts +
	|						Prices.ItemizedFixedCostsExcludingVAT + Prices.ItemizedVariableCostsExcludingVAT)
	|				WHEN &Cost_Data = 3
	|					THEN DD.Count * (Prices.CostMan + Prices.AddExpensesMan + Prices.LaborCostsMan +
	|						Prices.ItemizedFixedCostsManag + Prices.ItemizedVariableCostsManag)
	|				WHEN &Cost_Data = 4
	|					THEN DD.Count * (Prices.LocalCost + Prices.AddExpensesLocal + Prices.LaborCostsLocal +
	|						Prices.ItemizedFixedCostsCompl + Prices.ItemizedVariableCostsCompl)
	|				ELSE CASE
	|					WHEN &ByEnterprise
	|						THEN DD.Count * (Prices.CostExcludingVAT + Prices.AdditionalExpensesCostExcludingVAT + Prices.LaborCosts +
	|							Prices.ItemizedFixedCostsExcludingVAT + Prices.ItemizedVariableCostsExcludingVAT)
	|					ELSE DD.Count * (Prices.CostMan + Prices.AddExpensesMan + Prices.LaborCostsMan +
	|						Prices.ItemizedFixedCostsManag + Prices.ItemizedVariableCostsManag)
	|				END
	|			END
	|		ELSE CASE
	|			WHEN &Cost_Data = 1
	|				THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|			WHEN &Cost_Data = 2
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT +
	|					DD.ItemizedVariableCostsExcludingVAT
	|			WHEN &Cost_Data = 3
	|				THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag +
	|					DD.ItemizedVariableCostsManag
	|			WHEN &Cost_Data = 4
	|				THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl +
	|					DD.ItemizedVariableCostsCompl
	|			ELSE CASE
	|				WHEN &ByEnterprise
	|					THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT +
	|						DD.ItemizedVariableCostsExcludingVAT
	|				ELSE DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag +
	|					DD.ItemizedVariableCostsManag
	|			END
	|		END
	|	END AS CostOfCosts,
	|	CASE
	|		WHEN DocumentCalculation.Ref IS NULL
	|			THEN CASE
	|				WHEN &Cost_Data = 4
	|					THEN DD.Count * Prices.CostTD
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN &Cost_Data = 4
	|				THEN DD.CostTD
	|			ELSE 0
	|		END
	|	END AS CostTD,
	|	CASE
	|		WHEN DocumentCalculation.Ref IS NULL
	|			THEN CASE
	|				WHEN &Cost_Data = 4
	|					THEN DD.Count * Prices.PermanentDifference
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN &Cost_Data = 4
	|				THEN DD.PermanentDifference
	|			ELSE 0
	|		END
	|	END AS PermanentDifference,
	|	CASE
	|		WHEN DocumentCalculation.Ref IS NULL
	|			THEN CASE
	|				WHEN &Cost_Data = 4
	|					THEN DD.Count * Prices.CostOfPersonalIncomeTax
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN &Cost_Data = 4
	|				THEN DD.CostOfPersonalIncomeTax
	|			ELSE 0
	|		END
	|	END AS AIT,
	|	CASE
	|		WHEN CostCalculationDocument.Ref IS NULL
	|			THEN CASE
	|				WHEN &Cost_Data = 4
	|					THEN DD.Count * Prices.OffBalanceCostLocal
	|				ELSE DD.Count * Prices.OffBalanceCost
	|			END
	|		ELSE CASE
	|			WHEN &Cost_Data = 4
	|				THEN DD.OffBalanceCostLocal
	|			ELSE DD.OffBalanceCost
	|		END
	|	END AS CostOfOffBalanceSheetCosts,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.CostCalculationRecorder)
	|			THEN UNDEFINED
	|		WHEN PeriodsOfActionOfMediumSlip.Organization IS NULL
	|			THEN DD.Recorder
	|		ELSE UNDEFINED
	|	END AS Recorder
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON (Dimension.Ref = DD.ItemsLocationAttributes)
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS IssueAnalytics
	|		ON (IssueAnalytics.Ref = DD.CorItemsLocationAttributes)
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.GoodsCost AS Prices
	|		ON (Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes)
	|			AND (Prices.Organization = DD.Organization)
	|			AND (Prices.Period = BEGINOFPERIOD(DD.Period, MONTH))
	|			AND (Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute)
	|			AND (CASE
	|				WHEN Prices.AccountingSection = DD.AccountingSection
	|					THEN TRUE
	|				WHEN DD.Count < 0
	|						AND (DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|								AND Prices.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|							OR Prices.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress), VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)))
	|					THEN TRUE
	|				ELSE FALSE
	|			END)
	|		LEFT JOIN Document.InventoryCostCalculation.Companies AS CostCalculationDocument
	|		ON (BEGINOFPERIOD(CostCalculationDocument.Ref.Date, MONTH) = BEGINOFPERIOD(DD.Period, MONTH))
	|			AND (CostCalculationDocument.Organization = DD.Organization)
	|			AND (CostCalculationDocument.Ref.Posted)
	|			AND (CostCalculationDocument.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef))
	|			AND (NOT CostCalculationDocument.Ref.PreliminaryCalculation)
	|		LEFT JOIN PeriodsOfActionOfMediumSlip AS PeriodsOfActionOfMediumSlip
	|		ON (PeriodsOfActionOfMediumSlip.Organization = DD.Organization)
	|			AND (PeriodsOfActionOfMediumSlip.ActionPeriod = BEGINOFPERIOD(DD.Period, MONTH))
	|		LEFT JOIN Catalog.KeysForLotVendorAttributes AS PartyAnalysts_
	|		ON (PartyAnalysts_.Ref = DD.LotVendorAttributesCorr)
	|		LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS ManufacturedProduct
	|		ON DD.Recorder = ManufacturedProduct.Ref
	|			AND (PartyAnalysts_.RowCode = ManufacturedProduct.RowCode)
	|			AND (NOT ManufacturedProduct.Canceled)
	|		LEFT JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS StageByProducts_
	|		ON DD.Recorder = StageByProducts_.Ref
	|			AND (PartyAnalysts_.RowCode = StageByProducts_.RowCode)
	|			AND (NOT StageByProducts_.Canceled)
	|		LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
	|		ON DD.Recorder = ProductionStage2_2.Ref
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON (Register3.ReversedDocument = DD.Recorder)
	|			AND (Register3.ReverseTransactionCorrection)
	|			AND (Register3.IBDocumentDate <= &EndOfPeriod
	|				OR &EndOfPeriod = DATETIME(1, 1, 1))
	|			AND (Register3.Posted)
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			OR &EndOfPeriod = DATETIME(1, 1, 1))
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND DD.Active
	|	AND (VALUETYPE(DD.Recorder) IN (TYPE(Document.BackflushProduction), TYPE(Document.CostCalculationRecorder))
	|			AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|		OR DD.Recorder REFS Document.ReversingEntry
	|			AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)

	|		OR DD.Recorder REFS Document.ProductionStage2_2
	|			AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|		OR DD.Recorder REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|			AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|		OR DD.Recorder REFS Document.SubcontractorReport2_5
	|			AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|	AND &BatchAccountingVersion22
	|	AND DD.Period >= &DateOfMigrationToBatchAccounting22
	
	// We exclude documents for which a correction has been entered or storno in the current period.
	|	AND Register3.Ref IS NULL
	|	AND NOT DD.ReversingEntry
	|{WHERE
	|	((IssueAnalytics.Products, IssueAnalytics.Characteristic) IN
	|			(SELECT
	|				SelectionByProductSegment.Products,
	|				SelectionByProductSegment.Characteristic
	|			FROM
	|				SelectionByProductSegment
	|			WHERE
	|				SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed))}
	|
	|";
	
EndFunction

// Recursively removes the selection from the settings and user settings of the report.
//
// Parameters:
//  DataCompositionSettings - DataCompositionSettingsComposer, DataCompositionSettings, DataCompositionGroup, DataCompositionTableGroup - customization.
//  TagName  - String - name of the item to be deleted.
Procedure RemoveSelectionElementRecursivelyFromAllReportSettings(DataCompositionSettings, TagName) Export
	
	If TypeOf(DataCompositionSettings) = Type("DataCompositionSettingsComposer") Then
		Settings = DataCompositionSettings.Settings;
		UserSettings = DataCompositionSettings.UserSettings;
	ElsIf TypeOf(DataCompositionSettings) = Type("DataCompositionSettings")
		Or TypeOf(DataCompositionSettings) = Type("DataCompositionGroup")
		Or TypeOf(DataCompositionSettings) = Type("DataCompositionTableGroup") Then
		Settings = DataCompositionSettings;
		UserSettings = New DataCompositionUserSettings;
	ElsIf TypeOf(DataCompositionSettings) = Type("DataCompositionSettingStructureItemCollection")
	 Or TypeOf(DataCompositionSettings) = Type("DataCompositionTableStructureItemCollection") Then
		For Each StringOfStructureElements In DataCompositionSettings Do
			RemoveSelectionElementRecursivelyFromAllReportSettings(StringOfStructureElements, TagName);
		EndDo;
		// There are no selection settings in the item collection itself.
		Return;
	ElsIf TypeOf(DataCompositionSettings) = Type("DataCompositionTable") Then
		For Each StringOfStructureElements In DataCompositionSettings.Rows Do
			RemoveSelectionElementRecursivelyFromAllReportSettings(StringOfStructureElements, TagName);
		EndDo;
		For Each StringOfStructureElements In DataCompositionSettings.Columns Do
			RemoveSelectionElementRecursivelyFromAllReportSettings(StringOfStructureElements, TagName);
		EndDo;
		// There are no selection settings in the table itself.
		Return;
	Else
		Return;
	EndIf;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(Settings.Filter, TagName); // Array of DataCompositionFilterItem
	
	For Each FilterElement In FilterItems1 Do
		UserSettingID = FilterElement.UserSettingID;
		If FilterElement.Parent <> Undefined Then
			FilterElement.Parent.Items.Delete(FilterElement);
		Else
			Settings.Filter.Items.Delete(FilterElement);
		EndIf;
		
		ItemTheCustomSettings = UserSettings.Items.Find(FilterElement.UserSettingID);
		If ItemTheCustomSettings <> Undefined Then
			UserSettings.Items.Delete(UserSettingID);
		Else
			For Each SettingsUsesElement In UserSettings.Items Do
				If TypeOf(SettingsUsesElement) = Type("DataCompositionFilter") Then
					CustomSelectionElements = CommonClientServer.FindFilterItemsAndGroups(SettingsUsesElement, TagName);
					For Each UserSelectionElement In CustomSelectionElements Do
						SettingsUsesElement.Items.Delete(UserSelectionElement);
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings")
	 Or TypeOf(DataCompositionSettings) = Type("DataCompositionGroup")
	 Or TypeOf(DataCompositionSettings) = Type("DataCompositionTableGroup") Then
		If DataCompositionSettings.Structure.Count() <> 0 Then
			RemoveSelectionElementRecursivelyFromAllReportSettings(DataCompositionSettings.Structure, TagName);
		EndIf;
	Else
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf