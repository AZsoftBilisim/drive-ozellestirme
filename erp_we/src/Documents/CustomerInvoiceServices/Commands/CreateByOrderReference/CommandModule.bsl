
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpeningParameters = FormOpenParameters(CommandParameter);
	If OpeningParameters = Undefined Then
		Return;
	EndIf;
	
	OpenForm(
		"Document.CustomerInvoiceServices.Form.DocumentForm",
		OpeningParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

&AtServer
Function FormOpenParameters(CommandParameter)
	
	BasisParameters = New Structure;
	
	If CommandParameter.Count() = 1
	 Or Not GetFunctionalOption("UseCustomerInvoicesForSeveralOrders") Then
		
		BasisParameters.Insert("DocumentBasis", CommandParameter[0]);
		
	Else
		
		HeaderAttributes = New Structure;
		If Not SalesServerCall.GenerateDataForFillingInReportsOfCompletedWorks(CommandParameter, HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",    HeaderAttributes);
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction
