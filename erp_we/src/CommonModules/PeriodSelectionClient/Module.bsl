////////////////////////////////////////////////////////////////////////////////
// Functions and procedures for ensuring the selection of the period.
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Sets the period values and its representation.
//
// Parameters:
//  Item      - FormField - the form element that the event is associated with.
//  PeriodType   - EnumRef.AvailableReportPeriods - multiplicity of the period.
//  BeginOfPeriod - Date - lower bound of the period.
//  EndOfPeriod - Date - upper bound of the period.
//  Period       - See PeriodSelectionClientServer.GetPresentationOfReportPeriod.
//
Procedure PeriodTypeOnChange(Item, Val PeriodType, BeginOfPeriod, EndOfPeriod, Period) Export
	
	If PeriodType <> PredefinedValue("Enum.AvailableReportPeriods.Custom") Then
		If ValueIsFilled(BeginOfPeriod) Then
			BeginOfPeriod = PeriodSelectionClientServer.BeginningOfReportPeriod(PeriodType, BeginOfPeriod);
			EndOfPeriod  = PeriodSelectionClientServer.EndOfReportPeriod(PeriodType, BeginOfPeriod);
		Else
			BeginOfPeriod = Undefined;
			EndOfPeriod  = Undefined;
		EndIf;
		
		List = PeriodSelectionClientServer.GetListOfPeriods(BeginOfPeriod, PeriodType);
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			Period = ListItem.Presentation;
		Else
			Period = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

// Sets the period values when the view changes.
//
// Parameters:
//  Item      - FormField - the form element that the event is associated with.
//  Period       - See PeriodSelectionClientServer.GetPresentationOfReportPeriod.
//  BeginOfPeriod - Date - lower bound of the period.
//  EndOfPeriod - Date - upper bound of the period.
//
Procedure PeriodOnChange(Item, Val Period, BeginOfPeriod, EndOfPeriod) Export
	
	If IsBlankString(Period) Then
		BeginOfPeriod = Undefined;
		EndOfPeriod  = Undefined;
	EndIf;
	
EndProcedure

// Displays the period selection from the drop-down list.
//
// Parameters:
//  Form        - ClientApplicationForm - where the selection takes place.
//  Item      - FormField - the form element that the event is associated with.
//  StandardProcessing - Boolean - indicates standard (system) event handling.
//  PeriodType   - EnumRef.AvailableReportPeriods - multiplicity of the period.
//  BeginOfPeriod - Date - lower bound of the period.
//	Callback - CallbackDescription - An action performed after the user selects a period.
// 
Procedure PeriodStartChoice(Form, Item, StandardProcessing, PeriodType, BeginOfPeriod, Callback) Export
	
	If BeginOfPeriod = '00010101' Then
		BeginOfPeriod = PeriodSelectionClientServer.BeginningOfReportPeriod(PeriodType, CommonClient.SessionDate());
	EndIf;
	
	StandardProcessing = False;
	
	SelectReportPeriod(Form, Item, PeriodType, BeginOfPeriod, Callback);
	
EndProcedure

// Sets the values of the period.
//
// Parameters:
//  Item      - FormField - the form element that the event is associated with.
//  ValueSelected - Date - start of the selected period.
//  StandardProcessing - Boolean - indicates standard (system) event handling.
//  PeriodType   - EnumRef.AvailableReportPeriods - multiplicity of the period.
//  Period       - See PeriodSelectionClientServer.GetPresentationOfReportPeriod.
//  BeginOfPeriod - Date - lower bound of the period.
//  EndOfPeriod - Date - upper bound of the period.
// 
Procedure PeriodChoiceProcessing(Item, ValueSelected, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod) Export
	
	If TypeOf(ValueSelected) = Type("Date") Then
		BeginOfPeriod = PeriodSelectionClientServer.BeginningOfReportPeriod(PeriodType, ValueSelected);
		EndOfPeriod  = PeriodSelectionClientServer.EndOfReportPeriod(PeriodType, ValueSelected);
		
		ValueSelected = PeriodSelectionClientServer.GetPresentationOfReportPeriod(
			PeriodType, BeginOfPeriod, EndOfPeriod);
			
		Period = ValueSelected;
		StandardProcessing = False;
	EndIf;
	
EndProcedure

// Selection when changing the period view.
//
// Parameters:
//  Item      - FormField - the form element that the event is associated with.
//  Text        - String - A string of text entered in the input field.
//  ChoiceData - ValueList - values from which the selection was made.
//  Waiting     - Number - Interval in seconds after entering text. "0" means creating a quick selection list.
//  StandardProcessing - Boolean - indicates standard (system) event handling.
//  PeriodType   - EnumRef.AvailableReportPeriods - multiplicity of the period.
//  Period       - See PeriodSelectionClientServer.GetPresentationOfReportPeriod.
//  BeginOfPeriod - Date - lower bound of the period.
//  EndOfPeriod - Date - upper bound of the period.
// 
Procedure AutoSelectionPeriod(Item, Text, ChoiceData, Waiting, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod) Export
	
	ChoiceData = PeriodSelectionClientServer.SelectReportPeriod_(PeriodType, Text, 
		BeginOfPeriod, EndOfPeriod);
		
	StandardProcessing = False;
	
EndProcedure

// Selection when changing the period view.
//
// Parameters:
//  Item      - FormField - the form element that the event is associated with.
//  Text        - String - A string of text entered in the input field.
//  ChoiceData - ValueList - values from which the selection was made.
//  StandardProcessing - Boolean - indicates standard (system) event handling.
//  PeriodType   - EnumRef.AvailableReportPeriods - multiplicity of the period.
//  Period       - See PeriodSelectionClientServer.GetPresentationOfReportPeriod.
//  BeginOfPeriod - Date - lower bound of the period.
//  EndOfPeriod - Date - upper bound of the period.
// 
Procedure PeriodEndOfTextInput(Item, Text, ChoiceData, StandardProcessing, PeriodType, Period, BeginOfPeriod, EndOfPeriod) Export
	
	If IsBlankString(Text) Then
		Return;
	EndIf;
	
	ChoiceData = PeriodSelectionClientServer.SelectReportPeriod_(PeriodType, Text, 
		BeginOfPeriod, EndOfPeriod);
		
	StandardProcessing = False;	
	
EndProcedure

#EndRegion

#Region Private

Procedure SelectReportPeriod(Form, Item, PeriodType, BeginOfPeriod, Callback)
	
	List = PeriodSelectionClientServer.GetListOfPeriods(BeginOfPeriod, PeriodType);
	If List.Count() = 0 Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("List", List);
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("PeriodType", PeriodType);
	AdditionalParameters.Insert("Callback", Callback);

	CallbackDescription = New CallbackDescription("SelectReportPeriodCompletion", ThisObject, AdditionalParameters);
	ListItem = List.FindByValue(BeginOfPeriod);
	
	Form.ShowChooseFromList(CallbackDescription, List, Item, ListItem);
	
EndProcedure

// Processing the selection of the report period from the list
// 
// Parameters:
//  SelectedPeriod - ValueListItem - selected value
//  AdditionalParameters - Structure - additional information that contains:
//      * Form - ClientApplicationForm - the report form in which the selection is made
//      * List - See PeriodSelectionClientServer.GetListOfPeriods
//      * Item - FormField, FormButton - the form element that the event is associated with
//
Procedure SelectReportPeriodCompletion(SelectedPeriod, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	List = AdditionalParameters.List;
	Item = AdditionalParameters.Item;
	PeriodType = AdditionalParameters.PeriodType;
	Callback = AdditionalParameters.Callback;
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	IndexOf = List.IndexOf(SelectedPeriod);
	If IndexOf = 0 Or IndexOf = List.Count() - 1 Then
		SelectReportPeriod(Form, Item, PeriodType, SelectedPeriod.Value, Callback);
	Else
		ReturnSelectedPeriodToForm(PeriodType, SelectedPeriod, Callback);
	EndIf;
	
EndProcedure

Procedure ReturnSelectedPeriodToForm(PeriodType, SelectedPeriod, Callback)
	
	PeriodStructure = New Structure;
	PeriodStructure.Insert("PeriodType", PeriodType);
	PeriodStructure.Insert("Period", SelectedPeriod.Presentation);
	PeriodStructure.Insert("BeginOfPeriod", SelectedPeriod.Value);
	PeriodStructure.Insert("EndOfPeriod", PeriodSelectionClientServer.EndOfReportPeriod(PeriodType, SelectedPeriod.Value));
	
	RunCallback(Callback, PeriodStructure);
	
EndProcedure

#EndRegion