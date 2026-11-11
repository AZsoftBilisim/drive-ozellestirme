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
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StatesOfStages = DataCompositionSchema.DataSets.Find("StatesOfStages");
	
	QueryText = StatesOfStages.Query;
	
	QueryText = StrReplace(
		QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("Stages"));
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorPlan",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackagePlan",
			"Stages.ProductionLot.MainProductProducts"));
			
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorFact",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackageActualData",
			"Stages.ProductionLot.MainProductProducts"));
	
	QueryFields = ProductionProcessEditor.RequestFieldsParametersOfTechnicalProcessOfStage("Stages");
	QueryText = StrReplace(QueryText, "&TechnologicalProcessType", QueryFields.TechnologicalProcessType);
	QueryText = StrReplace(QueryText, "&TechnologicalProcess", QueryFields.TechnologicalProcess);
	
	If ProductionManagementCached.TheProductionScheduleIsUsed()
		And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		QueryText = StrReplace(QueryText,
			"&ThereIsRegulatorySchedule",
			"FALSE");
		QueryText = StrReplace(QueryText,
			"&NormativeScheduleIsBeginning",
			"DATETIME(1,1,1)");
		QueryText = StrReplace(QueryText,
			"&RegulatoryScheduleEnd",
			"DATETIME(1,1,1)");
	Else
		QueryText = StrReplace(QueryText,
			"&ThereIsRegulatorySchedule",
			"StandardProductionSchedule.ProductionStage IS NOT NULL");
		QueryText = StrReplace(QueryText,
			"&NormativeScheduleIsBeginning",
			"DATEADD(Stages.ReferenceOrder.EarliestStartDate, SECOND, StandardProductionSchedule.DurationBeforeStart)");
		QueryText = StrReplace(QueryText,
			"&RegulatoryScheduleEnd",
			"DATEADD(Stages.ReferenceOrder.EarliestStartDate, SECOND, StandardProductionSchedule.DurationBeforeStart + StandardProductionSchedule.ResourceIntensity)");
	EndIf;
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	StatesOfStages.Query = QueryText;
		
	If Not GetFunctionalOption("UseOperationManagement") Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(SettingsComposer, "Operation");
	EndIf;

EndProcedure

#EndRegion

#EndIf
