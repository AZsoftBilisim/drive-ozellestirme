
#Region Public

// The procedure performs editing of the presentation expression or sorting of the budget report item
// in the formula editor.
//
// Parameters:
//  Form - ClientApplicationForm - the form for editing the budget report element
//  ExpressionName - String - Presentation expressions or Sorting expressions
//  NameForPrinting - String - current name for printing
//
Procedure ChangingExpressionOfSortingViewInFormulaEditor(Form, ExpressionName, NameForPrinting = "") Export
	
	ClearMessages();
	
	If Form.FormName = "Catalog.FinancialReportItems.Form.BudgetFlowItem"
		Or Form.FormName = "Catalog.FinancialReportItems.Form.BudgetFlowItemWithoutSettings"
		Or Form.FormName = "Catalog.FinancialReportItems.Form.BudgetFlowItemForEntering" Then
		Source = Form.BudgetFlowItem;
	ElsIf Form.FormName = "Catalog.FinancialReportItems.Form.BudgetBalanceItem" Then
		Source = Form.BudgetBalanceItem;
	ElsIf Form.FormName = "Catalog.FinancialReportItems.Form.NonFinancialItem" Then
		Source = Form.NonFinancialItem;
	Else
		Source = Form.DimensionKind;
	EndIf;
	
	ExpressionEditingOptions = New Structure;
	ExpressionEditingOptions.Insert("Formula", Form[ExpressionName]);
	ExpressionEditingOptions.Insert("ResultType", New TypeDescription("String"));
	ExpressionEditingOptions.Insert("OperandsTree", BudgetReportingServerCall.OperandTreeForEditingExpressionOfSortingRepresentation(Source, Form.UUID));
	
	AdditionalParameters = New Structure("Form, ExpressionName, Source, NameForPrinting", Form, ExpressionName, Source, NameForPrinting);
	
	CallbackDescription = New CallbackDescription("ChangingExpressionOfSortingViewInFormulaEditorCompletion", ThisObject,
		AdditionalParameters);
	
	OpenForm(
		"CommonForm.FormulasConstructor",
		ExpressionEditingOptions,
		Form,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

// The handler procedure for completing the opening of the general form "Formula Constructor"
//
// Parameters:
//  Result - Arbitrary
//  AdditionalParameters - Structure:
//   *Form - ClientApplicationForm
//   *ExpressionName - String
//   *Source - String
//   *NameForPrinting - String
//
Procedure ChangingExpressionOfSortingViewInFormulaEditorCompletion(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	ExpressionName = AdditionalParameters.ExpressionName;
	Source = AdditionalParameters.Source;
	NameForPrinting = AdditionalParameters.NameForPrinting;
	
	If Result <> Undefined Then
		Result = TrimAll(Result);
		ErrorText = ?(IsBlankString(Result), "",
			FinancialReportingServerCall.ErrorTextOfExpressionOfSortRepresentation(Result, Source,
			NameForPrinting));
		If Not IsBlankString(ErrorText) Then
			CommonClient.MessageToUser(ErrorText);
		Else
			If Form[ExpressionName] <> Result Then
				Form.Modified = True;
				Form[ExpressionName] = Result;
				If IsBlankString(Result) Then
					NameForPrinting = "";
				EndIf;
			EndIf;
			If CommonClientServer.HasAttributeOrObjectProperty(Form.Object, "NameForPrinting") Then
				If Form.Object.NameForPrinting <> NameForPrinting Then
					Form.Modified = True;
					If Not IsBlankString(NameForPrinting) Then
						Form.Object.NameForPrinting = NameForPrinting;
					Else
						Form.Object.NameForPrinting = FinancialReportingServerCall.ObjectAttributeValue(
							Source, "Description");
					EndIf;
				EndIf;
				If Form.Items.Find("NameForPrinting") <> Undefined Then
					Form.Items.NameForPrinting.Enabled = IsBlankString(Result);
				ElsIf Form.Items.Find("Description") <> Undefined Then
					Form.Items.Description.Enabled = IsBlankString(Result);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure sets the offset period in the forms of budget items and budget indicators
// , as well as adjusts the name to display the set offset.
//
// Parameters:
//  Object  - FormDataStructure - form object
//  Form  - ClientApplicationForm - The Form for which we set the offset. Contains including:
//  	* Items - FormAllItems - contains including:
//  		** SettingThePeriodOffset - FormDecoration -  
//  SelectionResult  - Structure - the result of the selection in the offset settings form.
//
Procedure SetOffsetPeriod(Object, Form, SelectionResult) Export
	
	Var ValueIsEmpty;
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	
	PreviousOffsetPresentation = BudgetReportingClientServer.OffsetPresentation(Form);
	
	FillPropertyValues(Form, SelectionResult);
	
	NewOffsetPresentation = BudgetReportingClientServer.OffsetPresentation(Form, ValueIsEmpty);
	Form.Items.SettingThePeriodOffset.Title = NewOffsetPresentation;
	
	If StrFind(Object.NameForPrinting, PreviousOffsetPresentation) Then
		If ValueIsEmpty Then
			Object.NameForPrinting = StrReplace(Object.NameForPrinting, "(" + PreviousOffsetPresentation + ")", "");
		Else
			Object.NameForPrinting = StrReplace(Object.NameForPrinting, PreviousOffsetPresentation, NewOffsetPresentation);
		EndIf;
	ElsIf Not ValueIsEmpty Then
		Postfix = " (" + NewOffsetPresentation + ")";
		If Not Right(Object.NameForPrinting, StrLen(Postfix)) = Postfix Then
			Object.NameForPrinting = Object.NameForPrinting + Postfix;
		EndIf;
	EndIf;
	Object.NameForPrinting = TrimAll(Object.NameForPrinting);
	
EndProcedure

Procedure OpenReportForm(OpeningParameters, OwnerForm) Export
	Var ReportParametersToStore;
	
	AdditionalUniquenessIndex = 0;
	If OpeningParameters.ReportParameters.Property("ReportParametersToStore", ReportParametersToStore) Then
		AdditionalUniquenessIndex = ReportParametersToStore.DataLineIndex;
	EndIf;
	
	UniqueKey = String(OwnerForm.UUID) + "_" + AdditionalUniquenessIndex;
	
	OpenForm(OpeningParameters.FormName, OpeningParameters.ReportParameters, OwnerForm, UniqueKey);
	
EndProcedure

Function ArrayOfEditableCells(TreeRow, ExcludeID, Var_FillChecking = False, Result = Undefined)
	
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	ChildItems = FinancialReportingClient.SubordinateLinesOfFormElement(TreeRow);
	For Each SubordinateItem In ChildItems Do
		If SubordinateItem.ItemKind = BudgetReportingClientServer.ItemKind("EditedValue") Then
			If Var_FillChecking Then
				ThisIsSkippedElement = SubordinateItem.AddressOfItemStructure = ExcludeID;
			Else
				ThisIsSkippedElement = SubordinateItem.GetID() = ExcludeID;
			EndIf;
			If Not ThisIsSkippedElement Then
				Result.Add(SubordinateItem);
			EndIf;
		EndIf;
		ArrayOfEditableCells(SubordinateItem, ExcludeID, Var_FillChecking, Result);
	EndDo;
	
	Return Result;
	
EndFunction

Function NamesOfEditedCells(TreeRow, ExcludeID, Var_FillChecking = False) Export
	
	ArrayOfEditableCells = ArrayOfEditableCells(TreeRow, ExcludeID, Var_FillChecking);
	
	Result = New ValueList;
	For Each Item In ArrayOfEditableCells Do
		Result.Add(Item.NameForPrinting);
	EndDo;
	Result.SortByValue(SortDirection.Desc);
	
	Return Result.UnloadValues();
	
EndFunction

#EndRegion

