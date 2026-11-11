////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Entering balances of non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region FormFixedAssets

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormFixedAssets_WhenExecutingCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormIntangibleAssets

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormIntangibleAssets_WhenExecutingCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormLeasedFixedAssets_

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormLeasedFixedAssets_WhenExecutingCommand_(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormLeasedFixedAssets

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormLeasedFixedAssets_WhenExecutingCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormOfLeasingItemsOnBalance

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormLeasingItemsForBalance_WhenExecutingCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormSettlementsUnderLeaseAgreements

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormSettlementsUnderLeaseAgreements_WhenExecutingCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion

#Region FALineEditingForm

// Parameters:
// 	Item - FormField - 
// 	Form - ClientApplicationForm - 
Procedure FormForEditingOS_LineWhenChangingProps(Item, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	
	
	TMCommonUseClient.ContinueChangingProps(
		Form, 
		Item.Name, 
		ServerCallRequired_,
		AdditionalParameters);
	
EndProcedure

Procedure FormForEditingLineOS_StartSelection(Item, ChoiceData, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure LineEditingFormOS_AutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure LineEditingFormOS_EndOfTextInput(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Function FormEditStringOS_RequiresServerCallToConfigureFormElements(Form, StructureOfChangedProps) Export

	
	Return False;

EndFunction

Procedure FormForEditingOS_StringWhenChangingUsagePeriod(Form, AttributeName, UpdateIfMatch, AttributesList) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure LineEditingFormOS_CurCostOfACWhenChanged(Form) Export
	
	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure FormForEditingOS_LineAccumulatedDepreciationOfACWhenChanging(Form) Export
	
	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure LineEditingFormOS_InitialCostOfACWhenChanged(Form) Export
	
	
	Return; // WE have an empty handler.
	
EndProcedure

#EndRegion

#Region IALineEditingForm

// Parameters:
// 	Item - FormField - 
// 	Form - ClientApplicationForm - 
Procedure IALineEditingForm_OnChangeAttribute(Item, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	
	
	TMCommonUseClient.ContinueChangingProps(
		Form, 
		Item.Name, 
		ServerCallRequired_,
		AdditionalParameters);
	
EndProcedure

Procedure LineEditingFormNMA_StartOfSelection(Item, ChoiceData, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure FormForEditingLineNMA_AutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure IALineEditingForm_EndOfTextInput(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure IALineEditingForm_WhenChangingPeriodOfUse(Form, AttributeName, UpdateIfMatch, AttributesList) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure FormForEditingLineNMA_CurCostOfACWhenChanging(Form) Export
	

	Return; // WE have an empty handler.
	
EndProcedure

Procedure LineEditingFormNMA_AccumulatedDepreciationOfACWhenChanging(Form) Export
	
	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure FormForEditingLineNMA_InitialCostOfACWhenChanging(Form) Export
	
	
	Return; // WE have an empty handler.
	
EndProcedure

#EndRegion


#EndRegion

