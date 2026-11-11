#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	For Each Set In DataCompositionSchema.DataSets Do
		
		If Set.Name = "UnfulfilledStages" Then
			Continue;
		EndIf;
		
		QueryText = Set.Query;
		
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
				
		QueryText = StrReplace(
			QueryText,
			"&PackagingFactorCanceled",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"Stages.PackageCanceled",
				"Stages.ProductionLot.MainProductProducts"));
				
		Set.Query = QueryText;
	
	EndDo;
	
EndProcedure

#EndRegion

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

#EndIf