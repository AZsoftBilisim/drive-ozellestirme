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
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	// Additional command
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If (Not Parameters.Property("CommandParameter") Or Not ValueIsFilled(Parameters.CommandParameter)) And (Not Parameters.Property("Details") Or Not Parameters.Details <> Undefined) Then
		MessageText = NStr("vi = 'Không được phép mở trực tiếp báo cáo ""Nhu cầu kế hoạch bán thành phẩm"".
			|Để mở báo cáo, có thể sử dụng lệnh ""Nhu cầu bán thành phẩm"" trng các biểu mẫu văn bản.';
			|ru = 'Непосредственное открытие отчета ""Плановая потребность в полуфабрикатах"" не предусмотрено. 
			|Для открытия отчета можно воспользоваться командой ""Потребность в полуфабрикатах"" в формах документов.';
			|en = 'The application cannot open the ""Planned demand for semi-finished products"" report. 
			|To open the report, use the ""Planned demand for semi-finished products"" command in document forms.'; fa = 'The application cannot open the ""Planned demand for semi-finished products"" report. 
			|To open the report, use the ""Planned demand for semi-finished products"" command in document forms.';
			|it = 'Непосредственное открытие отчета ""Плановая потребность в полуфабрикатах"" не предусмотрено. 
			|Для открытия отчета можно воспользоваться командой ""Потребность в полуфабрикатах"" в формах документов.';
			|pl = 'The application cannot open the ""Planned demand for semi-finished products"" report. 
			|To open the report, use the ""Planned demand for semi-finished products"" command in document forms.';
			|tr = '""Planlanan yarı mamul ürünlerin gereksinimi"" raporu açılması sağlanamadı. 
			| Raporun açılması için belge formunda yer alan ""Yarı mamul ürün gereksinimi"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.Filter.Insert("ProductionPlan", Parameters.CommandParameter);
		
		Scenario = Parameters.CommandParameter.Scenario;
		If Not Scenario.UseForMaterialsPlanning Then
			
			MessageText = NStr("vi = 'Kịch bản ""%Scenario%"" không bao gồm việc tính toán nhu cầu dự tính!';
								|ru = 'В сценарии ""%Scenario%"" не включен расчет плановых потребностей!';
								|en = 'The scenario ""%Scenario%"" does not have the planned demands calculation enabled!'; fa = 'The scenario ""%Scenario%"" does not have the planned demands calculation enabled!';
								|it = 'Nello scenario ""%Scenario%"" non è incluso il calcolo di fabbisogni pianificati!';
								|pl = 'Do scenariusza ""%Scenario%"" nie dodano obliczenia planowanych zapotrzebowań!';
								|tr = '""%Scenario%"" senaryosuna planlanan gereksinimlerin hesaplanması dahil değildir!'");
			MessageText = StrReplace(MessageText, "%Scenario%", Scenario);
			Common.MessageToUser(MessageText, , , , Cancel);
			
		EndIf;
		
	EndIf;
	
	If Parameters.Property("Details")
		And Parameters.Details <> Undefined Then
		
		ReplaceOption = False;
		
		If Parameters.Details.UsedSettings.Structure.Count() > 0 Then
			
			ProductProductsField = New DataCompositionField("ProductsItems");
			FieldCharacteristicOfProduction = New DataCompositionField("ItemVariant");
			SpecificationField = New DataCompositionField("BillOfMaterials");
			ProductAssignmentField = New DataCompositionField("AssignmentOfProducts");
			
			GroupFields = Parameters.Details.UsedSettings.Structure[0].GroupFields; // DataCompositionGroupFields - 
			
			For Each Group In GroupFields.Items Do
			
				If Group.Field = ProductProductsField 
					Or Group.Field = FieldCharacteristicOfProduction
					Or Group.Field = SpecificationField
					Or Group.Field = ProductAssignmentField Then
					
					ReplaceOption = True;
					Break;
				
				EndIf; 
			
			EndDo; 
		
		EndIf; 
		
		// filling in the decryption parameters
		If IsTempStorageURL(Parameters.Details.Data) Then
		
			DetailsData = GetFromTempStorage(Parameters.Details.Data);
			
			If Not DetailsData.Settings.AdditionalProperties.Property("CurrentVariantKey")
				Or DetailsData.Settings.AdditionalProperties.CurrentVariantKey <> "PlannedDemandForSemiFinishedProductsContext" Then
			
				Return;
			
			EndIf; 
		EndIf; 
		
		If Not ReplaceOption Then
			Return;
		EndIf; 
		
		If Parameters.Property("VariantKey") Then
			Parameters.VariantKey = "DecodingContext";
		EndIf; 
		If Parameters.Property("PurposeUseKey") Then
			Parameters.PurposeUseKey = "DecodingContext";
		EndIf;
		
		ThisForm.CurrentVariantKey = "DecodingContext";
		
		ThisForm.DetailsMode = False;
		ThisForm.ReportSettings.EditOptionsAllowed = False;
		ThisForm.ReportSettings.OptionRef = ReportsOptions.ReportVariant(ThisForm.ReportSettings.ReportRef, ThisForm.CurrentVariantKey);
		
	EndIf;
	

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	If FormSettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey") 
		And FormSettingsComposer.Settings.AdditionalProperties.CurrentVariantKey = "PlannedDemandForSemiFinishedProductsContext"
		And ThisForm.CurrentVariantKey = "DecodingContext" Then
		
		Scenario = Undefined;
		SpecifyTargets = Undefined;
		FormSettingsComposer.Settings.AdditionalProperties.Property("Scenario", Scenario);
		ProductionPlan = Undefined;
		FormSettingsComposer.Settings.AdditionalProperties.Property("ProductionPlan", ProductionPlan);
		FormSettingsComposer.Settings.AdditionalProperties.Property("SpecifyTargets", SpecifyTargets);
		
		ReportObject = Reports.PlannedDemandForSemiFinishedProducts.Create();
		Variant = ReportObject.DataCompositionSchema.SettingVariants.Find(ThisForm.CurrentVariantKey);
		
		DataCompositionClientServer.FillInElements(Variant.Settings.DataParameters,	FormSettingsComposer.Settings.DataParameters);
		DataCompositionClientServer.CopyElements(Variant.Settings.Filter,			FormSettingsComposer.Settings.Filter, False);
		
		FormSettingsComposer.LoadSettings(Variant.Settings);
		
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"ProductionPlan", 
			ProductionPlan);
		
		If Scenario <> Undefined Then
		
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer, 
				"Scenario", 
				Scenario);
		
		EndIf; 
		
		If SpecifyTargets <> Undefined Then
		
			DataCompositionClientServer.SetParameter(
				FormSettingsComposer, 
				"SpecifyTargets", 
				SpecifyTargets);
		
		EndIf;
		
	EndIf;
	
	FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	If ThisForm.ParametersForm.Filter.Property("ProductionPlan") Then
		
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"ProductionPlan", 
			ThisForm.ParametersForm.Filter.ProductionPlan);
		
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"Scenario", 
			Common.ObjectAttributeValue(ThisForm.ParametersForm.Filter.ProductionPlan, "Scenario"));
		
		DataCompositionClientServer.SetParameter(
			FormSettingsComposer, 
			"Scenario", 
			FormSettingsComposer.Settings.AdditionalProperties.Scenario);
		
		PlanningByAssignments = Common.ObjectAttributeValue(FormSettingsComposer.Settings.AdditionalProperties.Scenario
			, "PlanningByAssignments");
			
		FormSettingsComposer.Settings.AdditionalProperties.Insert(
			"SpecifyTargets", 
			PlanningByAssignments);
			
		DataCompositionClientServer.SetParameter(
			FormSettingsComposer, 
			"SpecifyTargets", 
			PlanningByAssignments);
			
	EndIf; 
	NewDCSettings = FormSettingsComposer.Settings;
	

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ScenarioParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Scenario");
	
	If Not ValueIsFilled(ScenarioParameter.Value) Then
		Raise NStr("vi = 'Chưa điền giá trị tham số ""Kịch bản"".';
					|ru = 'Не заполнено значение параметра ""Сценарий"".';
					|en = 'Parameter ""Scenario"" is not filled in.'; fa = 'Parameter ""Scenario"" is not filled in.';
					|it = 'Il valore del parametro ""Scenario"" non è compilato.';
					|pl = 'Wartość parametru ""Scenariusz"" nie jest wypełniona.';
					|tr = '""Senaryo"" parametresinin değeri doldurulmamış.'");
	EndIf; 
	
	Periodicity = Common.ObjectAttributeValue(ScenarioParameter.Value, "Periodicity");
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Periodicity", Periodicity);
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	If SettingsComposer.Settings.AdditionalProperties.Property("ProductionPlan") Then
		
		ProductionPlan = SettingsComposer.Settings.AdditionalProperties.ProductionPlan;
		PlanSemiFinishedProductsAutomatically = Common.ObjectAttributeValue(
			ProductionPlan, "PlanProfile.PlanSemiFinishedProductsAutomatically");
		
	Else
		
		ProductionPlan = Documents.ProductionPlan.EmptyRef();
		PlanSemiFinishedProductsAutomatically = False;
	
	EndIf;
	
	If PlanSemiFinishedProductsAutomatically Then
		
		NeedTable = NeedsScheduledAutomatically(ProductionPlan);
		
	Else
		
		TransferDemandOfBusinesUnitsThroughTransfers = Common.ObjectAttributeValue(
			ProductionPlan, "PlanProfile.TransferDemandOfBusinesUnitsThroughTransfers");
		NeedTable = NeedsScheduledManually(ProductionPlan, Periodicity, TransferDemandOfBusinesUnitsThroughTransfers);
		
	EndIf;
	
	DataSets = New Structure;
	DataSets.Insert("DataSet1", NeedTable);
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
		DataCompositionSchema, 
		SettingsComposer.GetSettings(), 
		DetailsData,
		, 
		Type("DataCompositionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, DataSets, DetailsData, True);
		
	// Getting the result
	DataCompositionResultSpreadsheetDocumentOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DataCompositionResultSpreadsheetDocumentOutputProcessor.SetDocument(ResultDocument);
	DataCompositionResultSpreadsheetDocumentOutputProcessor.Output(DataCompositionProcessor);
	
EndProcedure

Function NeedsScheduledAutomatically(ProductionPlan)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	CASE ProductionPlansTurnovers.Scenario.Periodicity
		|		WHEN VALUE(Enum.Periodicity.DAY)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, DAY)
		|		WHEN VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, MONTH)
		|		WHEN VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(ProductionPlansTurnovers.Period, YEAR)
		|	END AS DynamicPeriod,
		|	ProductionPlansTurnovers.Products,
		|	ProductionPlansTurnovers.Characteristic,
		|	ProductionPlansTurnovers.Purpose,
		|	ProductionPlansTurnovers.CountTurnover AS NumberOfSemiFinishedProducts,
		|	0 AS ProductsQuantity,
		|	0 AS ConsumptionQuantity,
		|	DATETIME(1, 1, 1) AS ProductionDate,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
		|	ProductionPlansTurnovers.Department AS ProductionDispatcherBusinessUnit,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS AssigneeBusinessUnit,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.Products.EmptyRef) AS ProductsItems,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariant,
		|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
		|	ProductionPlansTurnovers.ProductionPlan,
		|	ProductionPlansTurnovers.ProductionPlan.BeginOfPeriod AS BeginOfPeriod
		|FROM
		|	AccumulationRegister.ProductionPlans.Turnovers(
		|			,
		|			,
		|			Recorder,
		|			ProductionPlan = &ProductionPlan
		|				AND ThisIsASemiFinishedProduct = TRUE) AS ProductionPlansTurnovers
		|
		|UNION ALL
		|
		|SELECT
		|	CASE MaterialConsumptionPlans.Scenario.Periodicity
		|		WHEN VALUE(Enum.Periodicity.DAY)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, DAY)
		|		WHEN VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, MONTH)
		|		WHEN VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(MaterialConsumptionPlans.Period, YEAR)
		|	END,
		|	MaterialConsumptionPlans.Products,
		|	MaterialConsumptionPlans.Characteristic,
		|	MaterialConsumptionPlans.Purpose,
		|	0,
		|	ISNULL(ProductionPlansTurnovers.CountTurnover, 0),
		|	MaterialConsumptionPlans.Count,
		|	MaterialConsumptionPlans.ProductionDate,
		|	MaterialConsumptionPlans.ProductBOM,
		|	MaterialConsumptionPlans.ProductionDispatcherBusinessUnit,
		|	MaterialConsumptionPlans.AssigneeBusinessUnit,
		|	MaterialConsumptionPlans.Warehouse,
		|	MaterialConsumptionPlans.ProductsItems,
		|	MaterialConsumptionPlans.ItemVariant,
		|	MaterialConsumptionPlans.AssignmentOfProducts,
		|	MaterialConsumptionPlans.ProductionPlan,
		|	MaterialConsumptionPlans.ProductionPlan.BeginOfPeriod
		|FROM
		|	AccumulationRegister.MaterialConsumptionPlans AS MaterialConsumptionPlans
		|		LEFT JOIN AccumulationRegister.ProductionPlans.Turnovers(
		|				,
		|				,
		|				Recorder,
		|				ProductionPlan = &ProductionPlan) AS ProductionPlansTurnovers
		|		ON MaterialConsumptionPlans.ProductionDate = ProductionPlansTurnovers.Period
		|			AND MaterialConsumptionPlans.Scenario = ProductionPlansTurnovers.Scenario
		|			AND MaterialConsumptionPlans.Status = ProductionPlansTurnovers.Status
		|			AND MaterialConsumptionPlans.ProductsItems = ProductionPlansTurnovers.Products
		|			AND MaterialConsumptionPlans.ItemVariant = ProductionPlansTurnovers.Characteristic
		|			AND MaterialConsumptionPlans.ProductionDispatcherBusinessUnit = ProductionPlansTurnovers.Department
		|			AND MaterialConsumptionPlans.ProductionPlan = ProductionPlansTurnovers.ProductionPlan
		|			AND MaterialConsumptionPlans.ProductBOM = ProductionPlansTurnovers.BillOfMaterials
		|			AND MaterialConsumptionPlans.AssignmentOfProducts = ProductionPlansTurnovers.Purpose
		|WHERE
		|	MaterialConsumptionPlans.ProductionPlan = &ProductionPlan
		|	AND MaterialConsumptionPlans.ThisIsASemiFinishedProduct = TRUE";
		
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	Return Query.Execute().Unload();
	
EndFunction

Function NeedsScheduledManually(ProductionPlan, Periodicity, TransferDemandOfBusinesUnitsThroughTransfers)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SemiFinishedProducts.DateOfProduction DynamicPeriod,
	|	SemiFinishedProducts.Products,
	|	SemiFinishedProducts.Characteristic,
	|	SemiFinishedProducts.Purpose,
	|	SemiFinishedProducts.Count AS NumberOfSemiFinishedProducts,
	|	0 AS ProductsQuantity,
	|	0 AS ConsumptionQuantity,
	|	DATETIME(1, 1, 1) AS ProductionDate,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	SemiFinishedProducts.Ref.Department AS ProductionDispatcherBusinessUnit,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS AssigneeBusinessUnit,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsItems,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariant,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|	SemiFinishedProducts.Ref AS ProductionPlan,
	|	SemiFinishedProducts.Ref.BeginOfPeriod AS BeginOfPeriod
	|FROM
	|	Document.ProductionPlan.ManufacturedProduct AS SemiFinishedProducts
	|WHERE
	|	SemiFinishedProducts.SemiFinishedProduct
	|	AND SemiFinishedProducts.Ref = &ProductionPlan
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManufacturedProduct.DateOfProduction AS DynamicPeriod,
	|	ManufacturedProduct.Products,
	|	ManufacturedProduct.Characteristic,
	|	ManufacturedProduct.Purpose,
	|	0 AS NumberOfSemiFinishedProducts,
	|	ManufacturedProduct.Count AS ProductsQuantity,
	|	0 AS ConsumptionQuantity,
	|	ManufacturedProduct.DateOfProduction AS ProductionDate,
	|	ManufacturedProduct.BillOfMaterials,
	|	ManufacturedProduct.Ref.Department AS ProductionDispatcherBusinessUnit,
	|	ManufacturedProduct.Products AS ProductsItems,
	|	ManufacturedProduct.Characteristic AS ItemVariant,
	|	ManufacturedProduct.Purpose AS AssignmentOfProducts,
	|	ManufacturedProduct.Purpose.LineOfBusiness AS LineOfBusiness,
	|	ManufacturedProduct.Ref AS ProductionPlan,
	|	ManufacturedProduct.Ref.BeginOfPeriod AS BeginOfPeriod,
	|	ManufacturedProduct.Ref.ProductionManagement2_2 AS ProductionManagement2_2
	|FROM
	|	Document.ProductionPlan.ManufacturedProduct AS ManufacturedProduct
	|WHERE
	|	NOT ManufacturedProduct.SemiFinishedProduct
	|	AND ManufacturedProduct.Ref = &ProductionPlan";
	
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	QueryResults = Query.ExecuteBatch();
	
	ResultTable1 = QueryResults[0].Unload();
	TableProduction = QueryResults[1].Unload();
	
	ListOfData = CommonClientServer.ValueInArray("MaterialsAndServices");
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(
		ProductionPlan,
		Documents.ProductionPlan);
	
	ScheduleParameters = Undefined;
	CachedValues = Undefined;
	
	For Each TSRow In TableProduction Do
		
		If Not ValueIsFilled(TSRow.BillOfMaterials) Or TSRow.ProductsQuantity = 0 Then
			Continue;
		EndIf;
		
		QuantitySign = 1;
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, TSRow);
		ItemData_3.ProductionStart = TSRow.ProductionDate;
		
		If TSRow.ProductsQuantity < 0 Then
			ItemData_3.Count = -TSRow.ProductsQuantity;
			QuantitySign = -1;
		Else
			ItemData_3.Count = TSRow.ProductsQuantity;
		EndIf;
		
		SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(
			ListOfData,
			,
			ProductionSupply.SoftwareOptionAccordingToProductionVersion(TSRow.ProductionManagement2_2));
		SelectionParameters.RoundUpNumberOfUnitItems_ = False;
		
		SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataBySemiFinishedProducts(
			ItemData_3,
			True,
			SelectionParameters);
		
		RowsArray = New Array;
		DataArray = New Array;
		
		If TransferDemandOfBusinesUnitsThroughTransfers Then
			CalculationOfProductionPlan.ForwardMovements(SpecificationData.MaterialsAndServices);
		EndIf;

		// Data on materials
		For Each ElementMaterial In SpecificationData.MaterialsAndServices Do
			
			If Not ElementMaterial.ToPlan Then
				Continue;
			EndIf;
			
			NewRow = ResultTable1.Add();
			FillPropertyValues(NewRow, ElementMaterial,	"Products, Characteristic, Warehouse, BillOfMaterials");
			FillPropertyValues(NewRow, TSRow,	"ProductionDispatcherBusinessUnit,ProductsItems, 
				|ItemVariant,AssignmentOfProducts, ProductionPlan, BeginOfPeriod, ProductionDate, 
				|ProductsQuantity, NumberOfSemiFinishedProducts");
				
			If ElementMaterial.WithAssignment Then
				NewRow.Purpose = TSRow.Purpose;
			Else 
				NewRow.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;
			
			NewRow.ConsumptionQuantity = QuantitySign * ElementMaterial.Count;
			NewRow.AssigneeBusinessUnit = ElementMaterial.StageSubdivision;
			
			NewRow.DynamicPeriod = Documents.ProductionPlan.GetDateBySchedule(
				TSRow.ProductionDate,
				ElementMaterial.DaysFromDemand, 
				ScheduleParameters);
			
			
			ProductionLine = TableProduction.Add();
			FillPropertyValues(ProductionLine, NewRow);
			ProductionLine.ProductionManagement2_2 = TSRow.ProductionManagement2_2;
			ProductionLine.ProductsQuantity = NewRow.ConsumptionQuantity;
			
			RowsArray.Add(ProductionLine);
			
			ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
			ProductData.ProductionStart      = Min(TSRow.BeginOfPeriod, NewRow.DynamicPeriod);
			ProductData.Products            = ProductionLine.Products;
			ProductData.Characteristic          = ProductionLine.Characteristic;
			ProductData.ProductionDispatcherBusinessUnit  = TSRow.ProductionDispatcherBusinessUnit;
			ProductData.LineOfBusiness = TSRow.LineOfBusiness;
			
			DataArray.Add(ProductData);
			
		EndDo;
		
		If RowsArray.UBound() <> -1 Then
			
			ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
			
		EndIf;
		
	EndDo;
	
	For Each TSRow In ResultTable1 Do
	
		TSRow.DynamicPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(TSRow.DynamicPeriod, Periodicity);
	
	EndDo;
	
	Return ResultTable1;
	
EndFunction

#EndRegion

#EndIf
