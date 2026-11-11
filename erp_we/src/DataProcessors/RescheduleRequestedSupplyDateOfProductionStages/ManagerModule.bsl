#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Changes the desired stage provisioning date to the start date of the stages on the production schedule.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - an order whose stages need to be corrected.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure RescheduleRequestedSupplyDates(ReferenceOrder, StorageAddress) Export
	
	DataCompositionSchema = DataProcessors.RescheduleRequestedSupplyDateOfProductionStages.GetTemplate("Template");
	DetailsData = New DataCompositionDetailsData;
	
	CompositionProcessor = InitializeLayoutProcessor(
		DataCompositionSchema,
		"DataProcessing",
		DetailsData,
		ReferenceOrder);
	
	Stages = New ValueTable; // See ProductionServer.ServiceStructureOfValueTable
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(Stages);
	OutputProcessor.Output(CompositionProcessor);
	
	If Stages.Count() > 0 Then
		Stages.Columns.StageStart.Name = "Date";
		ProcessedItemsCount = Documents.ProductionStage2_2.ChangeDesiredCollateralDates(Stages);
	Else
		ProcessedItemsCount = 0;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ProcessedItemsCount", ProcessedItemsCount);
	Result.Insert("TotalCount1", Stages.Count());
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#Region Private

Procedure ReadAndOutputStagesOfOrder(Parameters, StorageAddress)Export
	
	DataCompositionSchema = DataProcessors.RescheduleRequestedSupplyDateOfProductionStages.GetTemplate("Template");
	DetailsData = New DataCompositionDetailsData;
	
	CompositionProcessor = InitializeLayoutProcessor(
		DataCompositionSchema,
		"DataOutput",
		DetailsData,
		Parameters.ReferenceOrder);
	
	SpreadsheetDocument = New SpreadsheetDocument;		
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(SpreadsheetDocument);
	OutputProcessor.Output(CompositionProcessor, True);
	
	Result = New Structure;
	Result.Insert("SpreadsheetDocument", SpreadsheetDocument);
	Result.Insert("DataCompositionSchema", DataCompositionSchema);
	Result.Insert("DetailsData", DetailsData);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function InitializeLayoutProcessor(DataCompositionSchema, VariantKey, DetailsData, ReferenceOrder)
	
	OrderParameter = DataCompositionSchema.Parameters.Find("ReferenceOrder");
	OrderParameter.Value = ReferenceOrder;
	
	StatusParameter = DataCompositionSchema.Parameters.Find("StatusWorkingSchedule");
	StatusParameter.Value = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
	DataCompositionSettings = DataCompositionSchema.SettingVariants.Find(VariantKey).Settings;
	TemplateComposer = New DataCompositionTemplateComposer;
	
	If VariantKey = "DataProcessing" Then
		GeneratorType = Type("DataCompositionValueCollectionTemplateGenerator");
	Else
		GeneratorType = Type("DataCompositionTemplateGenerator");
	EndIf;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, 
		DataCompositionSettings,
		DetailsData,
		,
		GeneratorType);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData);
	
	Return CompositionProcessor;
	
EndFunction

#EndRegion

#EndIf
