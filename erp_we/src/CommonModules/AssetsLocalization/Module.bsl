////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the directory "Objects of operation".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	
EndProcedure

Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

#Region ItemForm

Procedure OnChangeAttribute(TagName, Form, AdditionalParameters) Export

	
EndProcedure

Procedure SetVisibilityOfInputCommandsBasedOn_(Form, CommandsTable) Export

	
EndProcedure

Procedure FillInAccountingInformation(Form, InformationAboutAccounting, PresentationOfInformation) Export

	
EndProcedure

Procedure FillInCostAndDepreciation(Form, InformationAboutAccounting, CostAndDepreciation) Export

	
EndProcedure

Procedure OnReadCreateAtServer(Form) Export

	
EndProcedure

Procedure SetConditionalAppearance(Form) Export

	
EndProcedure
 
#EndRegion

#Region ListForm

Procedure AddInformation2_4(NonCurrentAsset, InformationAboutAccounting, CostAndDepreciation, ArrayOfAmounts, InformationRecords2_4) Export

	
EndProcedure

Function Get_Information2_2(Val NonCurrentAsset, Val FilterOrganization) Export
	
	InformationRecords2_2 = Undefined;
	
	
	Return InformationRecords2_2;
	
EndFunction

Function ListFormRequestText() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction
 
#EndRegion

#Region Other

Function FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

Function ThereAreRightsToReadInformation() Export

	
	Return True;
	
EndFunction

Function QueryTextRunningTimeValue() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function InitialInformation(PrimaryFacilityOrList, Period) Export

	Result = Undefined;
	
	
	Return Result;
	
EndFunction

Function InformationAboutAccounting(FixedAsset, FilterOrganization, Date, Recorder) Export

	InformationAboutAccounting = NULL;
	
	
	Return InformationAboutAccounting;

EndFunction

Function RequestTextForObjectsAvailableForSelection() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Procedure AddAuxiliaryDetails(AuxiliaryAttributes) Export

	
EndProcedure 

#EndRegion

#EndRegion

#Region Private

#Region Print


#EndRegion

#Region ItemForm

Procedure ReadPeriodicDetails(Form) Export

	
EndProcedure
 

#EndRegion

#Region FormChangeHistory

Procedure WhenCreatedOnServer_ChangeHistory(Form) Export

	
EndProcedure
 
#EndRegion


#EndRegion
