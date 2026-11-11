#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters that serve the selection of assignments in document forms.
// 
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// All assignments for the Destination field in the header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Purpose");
	
	Return FormTemplate;
	
EndFunction

// Parameters:
//  Parameters - Structure - consists of:
//   *DataCompositionSettings - DataCompositionSettings
//   *DataCompositionSchema - DataCompositionSchema
//  ResultAddress - String
//  AdditionalResultAddress - String
Procedure UpdatePlannedPurchases(Val Parameters, Val ResultAddress, Val AdditionalResultAddress = "") Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.GenerationOfPurchaseOrdersByPlans.Form.Command.Next");
	
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionSchema = Parameters.DataCompositionSchema;
	
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, Parameters.DataCompositionSettings, , ,Type("DataCompositionValueCollectionTemplateGenerator") , False, );
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate,,, True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor();
	ResultTable2 = OutputProcessor.Output(CompositionProcessor);
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		If ResultTable2.Columns.Find("Currency") = Undefined Then
			ResultTable2.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
		EndIf; 
		ResultTable2.FillValues(IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(), "Currency");
	
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ResultTable2.Count());
	
	PutToTempStorage(ResultTable2, ResultAddress);
	
EndProcedure

#EndRegion

#EndIf