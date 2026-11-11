#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//   Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("ScheduledJobUsed; TheRoutineTaskIsActive");
	Result.Add("GenerationMethod");
	Result.Add("PresentationOfTheSKDTemplate; Settings");
	Result.Add("Schedule; SetUpSchedule");
	
	Return Result;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("DCSTemplateName");
	NotAttributesToEdit.Add("ScheduledJob");
	NotAttributesToEdit.Add("DataCompositionSchema");
	NotAttributesToEdit.Add("StorageOfDataCompositionSettings");
	
	Return NotAttributesToEdit;
	
EndFunction

#EndRegion

#Region Private

#Region Other

Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	
	For Each Template In Metadata.Catalogs.ProductSegments.Templates Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			Continue;
			
		EndIf;
		
		Templates.Add(New Structure("Name, Synonym", Template.Name, Template.Synonym));
		
	EndDo;
	
	Return Templates;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.ProductSegmentOverlaps.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.SegmentContent.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

Procedure AfterImportData(Container) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductSegments.Ref,
	|	ProductSegments.DCSTemplateName
	|FROM
	|	Catalog.ProductSegments AS ProductSegments";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If IsBlankString(Selection.DCSTemplateName) Then
			CatalogObject = Selection.Ref.GetObject(); // CatalogObject.ProductSegments
			CatalogObject.StorageOfDataCompositionSettings = New ValueStorage("");
			CatalogObject.DataCompositionSchema = New ValueStorage("");
			
			CatalogObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
