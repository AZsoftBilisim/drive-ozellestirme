#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array of String - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Owner");
	
	Return Result;

EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Private

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	Catalogs.LoyaltyCards.AddGenerateCommand(GenerationCommands);
	
EndProcedure  

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Catalogs.LoyaltyCards) Then 
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Catalogs.LoyaltyCards.FullName();
		CreateBasedOnCommand.Id = "ReplaceLoyaltyCardBasedOnLoyaltyCard";
		CreateBasedOnCommand.FormName = "Catalog.LoyaltyCards.Form.RegistrationWizard"; 
		CreateBasedOnCommand.Presentation = "Map loyalty";	
		CreateBasedOnCommand.MultipleChoice = False; 
		
		OpeningParameters = New Structure("Mode, ReplacedCard");
		OpeningParameters.Mode = "ReplaceLoyaltyCard";
		
		CreateBasedOnCommand.FormParameters = OpeningParameters;
		
 		Return CreateBasedOnCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	LoyaltyCardsLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	LoyaltyCardsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// Parameters:
//  DocumentsArray - Array of DocumentRef - 
//  TemplatesNamesArray - Array of String - 
//
// Returns:
//  Structure:
//    *Data - See GetObjectDataByTemplate
//    *Templates - See GetTemplatesAndSectionDescriptions.
//
Function GetPrintInfo(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	Return New Structure("Data,Templates",
				GetObjectDataByTemplate(DocumentsArray, TemplatesNamesArray),
				GetTemplatesAndSectionDescriptions(TemplatesNamesArray));
	
EndFunction

Function GetDescriptionOfQuestionnaireAreas()

	Sections_ = New Structure;
	
	PrintManagement.AddAreaDetails(Sections_, "Title",    "Shared3");
	PrintManagement.AddAreaDetails(Sections_, "Barcode",     "Shared3");
	PrintManagement.AddAreaDetails(Sections_, "MagneticCode", "Shared3");
	PrintManagement.AddAreaDetails(Sections_, "Footer",       "Shared3");
	
	Return Sections_;

EndFunction

// Parameters:
//  DocumentsArray - Array of DocumentRef - 
//  TemplatesNamesArray - Array of String - 
//
// Returns:
//  Map of KeyAndValue:
//    *Key - DocumentRef -
//    *Value - See GetObjectDataFromSelection
//
Function GetObjectDataByTemplate(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	DataByAllObjects = New Map;
	
	QueryResult = GetDataToPrint(DocumentsArray);
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		ObjectDataByTemplates = New Structure;
		ObjectData = GetObjectDataFromSelection(Selection);
		For Each TemplateName In TemplatesNamesArray Do
			ObjectDataByTemplates.Insert(TemplateName, ObjectData);
		EndDo;
		DataByAllObjects.Insert(Selection.Ref, ObjectDataByTemplates);
	EndDo;
	
	Return DataByAllObjects;
	
EndFunction

// Parameters:
//  TemplatesNamesArray - Array of String - 
//
// Returns:
// 	Structure - with the following properties:
//   * DescriptionOfSections - Structure of KeyAndValue:
//                              ** Key - String - name of the layout.
//                              ** Value - See GetDescriptionOfQuestionnaireAreas
//   * TemplatesBinaryData - Structure of KeyAndValue:
//                              ** Key - String - name of the layout.
//                              ** Value - See PrintManagement.PrintFormTemplate
//
Function GetTemplatesAndSectionDescriptions(Val TemplatesNamesArray) Export
	
	DescriptionOfSections = New Structure;
	TemplatesBinaryData = New Structure;
	
	For Each TemplateName In TemplatesNamesArray Do
		
		Template = Undefined;
		DescriptionOfTemplateSections = Undefined;
		
		If TemplateName = "PF_DOC_Questionnaire_ru" Then
			DescriptionOfTemplateSections = GetDescriptionOfQuestionnaireAreas();
			Template = PrintManagement.PrintFormTemplate("Catalog.LoyaltyCards.PF_DOC_Questionnaire_ru");
		EndIf;
		
		If DescriptionOfTemplateSections <> Undefined And Template <> Undefined Then
			
			DescriptionOfSections.Insert(TemplateName, DescriptionOfTemplateSections);
			TemplatesBinaryData.Insert(TemplateName, Template);
			
		EndIf;
		
	EndDo;
	
	Return New Structure(
						"DescriptionOfSections,TemplatesBinaryData",
						DescriptionOfSections,
						TemplatesBinaryData);
	
EndFunction

Function GetDataToPrint(ObjectsArray)
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = 
	"SELECT
	|	LoyaltyCards.Ref                                  AS Ref,
	|	LoyaltyCards.Barcode                                AS Barcode,
	|	LoyaltyCards.MagneticCode                            AS MagneticCode,
	|	LoyaltyCards.Owner.Description                   AS CardKind,
	|	LoyaltyCards.Owner.CardType                       AS CardType,
	|	LoyaltyCards.Owner.Organization.DescriptionFull AS Organization
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	LoyaltyCards.Ref";
	
	Return Query.Execute();
	
EndFunction

Function GetObjectDataFromSelection(Selection)
	
	ObjectData = New Structure;
	
	ObjectData.Insert("Ref",       Selection.Ref);
	ObjectData.Insert("CardType",     Selection.CardType);
	ObjectData.Insert("Barcode",     Selection.Barcode);
	ObjectData.Insert("MagneticCode", Selection.MagneticCode);
	ObjectData.Insert("CardKind",     Selection.CardKind);
	ObjectData.Insert("Organization",  Selection.Organization);
	
	Return ObjectData;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
