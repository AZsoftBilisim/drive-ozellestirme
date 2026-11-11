#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	
	For Each Template In Metadata.DataProcessors.PlanningDataSourcesCA.Templates Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			Continue;
			
		EndIf;
		
		If (Template.Name = "ProductionPlansMaterialsPredefined"
			Or Template.Name = "ProductionPlansPredefined"
			Or Template.Name = "ReleasePlansPredefined")
			And Not GetFunctionalOption("UseProductionPlanning")
			Or Template.Name = "MaterialOrdersForProductionPredefined" And Not GetFunctionalOption("UseProduction")
			Or Template.Name = "ProductionPredefined" And (Not GetFunctionalOption("UseProduction") Or Not GetFunctionalOption("ComplexAutomation"))
			Or Template.Name = "BudgetTurnoversPredefined" And Not GetFunctionalOption("UseBudgeting") Then
			
			Continue;
			
		EndIf;
		
		Templates.Add(New Structure("Name, Synonym, FullNameOfTemplateSource", Template.Name, Template.Synonym, "DataProcessor.PlanningDataSourcesCA"));
		
	EndDo;
	
	Return Templates;
	
EndFunction

#EndRegion

#EndRegion

#EndIf