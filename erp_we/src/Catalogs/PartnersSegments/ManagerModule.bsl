#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//   Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("GenerationMethod");
	Result.Add("ScheduledJobUsed; TheRoutineTaskIsActive");
	Result.Add("PresentationOfTheSKDTemplate; Settings");
	Result.Add("Schedule; SetUpSchedule");
	Result.Add("SegmentIsUsedToProhibitShipment");
	
	Return Result;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("CheckForInclusionWhileCreatingNew");
	NotAttributesToEdit.Add("DataCompositionSchema");
	NotAttributesToEdit.Add("StorageOfDataCompositionSettings");
	NotAttributesToEdit.Add("ScheduledJob");
	NotAttributesToEdit.Add("DCSTemplateName");
	NotAttributesToEdit.Add("SegmentIsUsedToProhibitShipment");
	
	Return NotAttributesToEdit;
	
EndFunction

// Returns the partner segment that is not allowed to ship if it is the only one
//
// Returns:
//   CatalogRef.PartnersSegments - the segment of partners that is prohibited from shipping.
//
Function GetShipmentBanSegment() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	PartnersSegments.Ref AS Segment
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|WHERE
	|	PartnersSegments.SegmentIsUsedToProhibitShipment
	|	AND NOT PartnersSegments.DeletionMark";
		
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.Segment;
	Else
		Return Catalogs.PartnersSegments.EmptyRef();
	EndIf;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

Procedure AfterImportData(Container) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PartnersSegments.Ref,
	|	PartnersSegments.DCSTemplateName
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If IsBlankString(Selection.DCSTemplateName) Then
			
			CatalogObject = Selection.Ref.GetObject(); // CatalogObject.PartnersSegments
			CatalogObject.StorageOfDataCompositionSettings = New ValueStorage("");
			CatalogObject.DataCompositionSchema = New ValueStorage("");
			
			CatalogObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	UseInteraction = GetFunctionalOption("UseEmailClient");
	
	For Each Template In Metadata.Catalogs.PartnersSegments.Templates Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			Continue;
			
		EndIf;
		
		If Not UseInteraction And Template.Name = "ByInteractions" Then
			
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
	
	Reports.RevenueAndCOGS.AddSalesBySegmentCommand(ReportsCommands);
	
	Reports.PartnersSegmentOverlaps.AddReportCommand(ReportsCommands);
	
	ARAPAccountingServer.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.SegmentContent.AddReportCommand(ReportsCommands);
		
	ReportCommand = Reports.ContactInformation.AddTeamContactInformationForPartners(ReportsCommands);
	
	ReportCommand = Reports.ContactInformation.AddTeamContactInformationOfContactPersons(ReportsCommands);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
