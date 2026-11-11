#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	IncidentUnderReview = DataCompositionClientServer.GetParameter(SettingsComposer, "IncidentUnderReview").Value;
	
	IncidentsPassed = New Array;
	IncidentDuplicates = Catalogs.Incidents.IncidentDuplicates(IncidentUnderReview, IncidentsPassed);
	
	TableOfIncidents = New ValueTable;
	TableOfIncidents.Columns.Add("Duplicates", New TypeDescription("CatalogRef.Incidents"));
	For Indus = 1 To IncidentDuplicates.Count() Do
		TableOfIncidents.Add();
	EndDo;
	TableOfIncidents.LoadColumn(IncidentDuplicates, "Duplicates");
	
	ExternalSets = New Structure("TableOfIncidents", TableOfIncidents);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#EndIf
