////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the directory "Intangible assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Parameters - See DocumentsPosting.ParametersOfAccountingMechanism
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
Procedure AddParametersForDocument(Parameters, Document, Properties) Export
	
	
EndProcedure

// The procedure of formation of movements on the slave registers of intangible assets.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	
EndProcedure

// Procedure for forming movements in independent registers of intangible assets.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region EventHandlers

// Called from the corresponding directory handler
//
// Parameters:
//  Object - CatalogObject.IntangibleAssets - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export

	
EndProcedure

#EndRegion

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Adds print commands.
// 
// Parameters:
// 	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion

#Region ItemForm

Procedure SetVisibilityOfInputCommandsBasedOn_(Form, CommandsTable) Export

	
EndProcedure

Procedure FillInAccountingInformation(Form, InformationAboutAccounting, PresentationOfInformation) Export

	
EndProcedure

Procedure FillInCostAndDepreciation(Form, CostAndDepreciation) Export

	
EndProcedure

Procedure OnReadCreateAtServer(Form) Export

	
EndProcedure

Procedure ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure
 
#EndRegion

#Region ListForm

Procedure AddInformation2_4(NonCurrentAsset, InformationAboutAccounting, CostAndDepreciation, ArrayOfAmounts, InformationRecords2_4) Export

	
EndProcedure

Function Get_Information2_2(NonCurrentAsset) Export
	
	InformationRecords2_2 = New Array;
	
	
	Return InformationRecords2_2;
	
EndFunction
 
#EndRegion

#Region Other

Function ThereAreRightsToReadInformation() Export

	
	Return True;
	
EndFunction

Function InitialInformation(IntangibleAsset, Period) Export

	InitialInformation = Undefined;
	

	Return InitialInformation;
	
EndFunction
 
#EndRegion

#EndRegion

#Region Private


#EndRegion
