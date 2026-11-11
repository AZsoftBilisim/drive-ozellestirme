#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.Property("FilterByTransactionTypes")
		Or Parameters.FilterByTransactionTypes.Count() = 0 Then
		Return;
	EndIf;
	
	FillFilterParameters(Parameters);
	
	If Parameters.FilterByTransactionTypes.Count() = 1 Then
		
		BusinessOperation = Parameters.FilterByTransactionTypes.Get(0).Value;
		
		If ValueIsFilled(BusinessOperation) Then
			PrepareParametersForOpeningDocumentForm(BusinessOperation);
		Else
			Return;
		EndIf;
		
	Else
		TransactionKindList.LoadValues(Parameters.FilterByTransactionTypes.UnloadValues());
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Standard subsystems.Pluggable commands
	//pluggablecommandyclient.Start updating commands(this is an object);
	// The end of the standard subsystem.Pluggable commands
	
	If ValueIsFilled(ParametersOfDocumentFormOpening) Then
		OpenBalanceEntryDocument();
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AListOfTheTypesOfTransactionsTheValueStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionTypeList

&AtClient
Procedure TransactionKindListSelection(Item, RowSelected, Field, StandardProcessing)
	
	BusinessOperation = Item.CurrentData.Value;
	StandardProcessing = False;
	
	If ValueIsFilled(BusinessOperation) Then 
		ProcessingSelectionOfBusinessTransaction(BusinessOperation);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectTheOperationType(Command)
	
	BusinessOperation = Items.TransactionKindList.CurrentData.Value;
	
	If ValueIsFilled(BusinessOperation) Then
		ProcessingSelectionOfBusinessTransaction(BusinessOperation);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessingSelectionOfBusinessTransaction(BusinessOperation)
	PrepareParametersForOpeningDocumentForm(BusinessOperation);
	OpenBalanceEntryDocument();
EndProcedure

&AtServer
Function DetermineDocumentOnEconomicOperation(BusinessOperation)
	
	DocumentTypeForEnteringInitialBalances = OBEntryServer.DetermineDocumentOnEconomicOperation(BusinessOperation);
	Return DocumentTypeForEnteringInitialBalances;
	
EndFunction

&AtServer
Procedure PrepareParametersForOpeningDocumentForm(BusinessOperation)
	
	DocumentTypeForEnteringInitialBalances = DetermineDocumentOnEconomicOperation(BusinessOperation);
	NameOfResidueEntryDocument          = Common.ObjectAttributeValue(DocumentTypeForEnteringInitialBalances, "Name");
	NameOfDocumentForm                  = StrTemplate("Document.%1.ObjectForm", NameOfResidueEntryDocument);
	FillingValues                 = OBEntryServer.InitializeDocumentFillValuesEnteringBalances();
	
	FillPropertyValues(FillingValues, FillParameters);
	FillingValues.BusinessOperation = BusinessOperation;
	
	ParametersOfDocumentFormOpening = New Structure();
	ParametersOfDocumentFormOpening.Insert("NameOfDocumentForm",                 NameOfDocumentForm);
	ParametersOfDocumentFormOpening.Insert("FormParameters",                    New Structure());
	ParametersOfDocumentFormOpening.FormParameters.Insert("FillingValues", FillingValues);
	
EndProcedure

&AtClient
Procedure OpenBalanceEntryDocument()
	
	Modified = False;
	
	OpenForm(ParametersOfDocumentFormOpening.NameOfDocumentForm, ParametersOfDocumentFormOpening.FormParameters, FormOwner, );
	Close();
	
EndProcedure

&AtServer
Procedure FillFilterParameters(Var_Parameters)
	FillParameters = OBEntryServer.InitializeDocumentFillValuesEnteringBalances();
	FillPropertyValues(FillParameters, Var_Parameters.FillParameters);
EndProcedure

#EndRegion
