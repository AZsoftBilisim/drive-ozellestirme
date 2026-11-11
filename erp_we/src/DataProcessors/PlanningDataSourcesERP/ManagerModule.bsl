#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	
	For Each Template In Metadata.DataProcessors.PlanningDataSourcesERP.Templates Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			Continue;
			
		EndIf;
		
		If Template.Name = "ProductionPredefined" And Not GetFunctionalOption("UseProduction")
		Then
			
			Continue;
			
		EndIf;
		
		Templates.Add(New Structure("Name, Synonym, FullNameOfTemplateSource", Template.Name, Template.Synonym, "DataProcessor.PlanningDataSourcesERP"));
		
	EndDo;
	
	Return Templates;
	
EndFunction

#EndRegion

#EndRegion

#EndIf