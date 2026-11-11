
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("RoundingPrecision") Then
		RoundingPrecision = Parameters.RoundingPrecision;
	EndIf;
	
	If Parameters.Property("RoundOffOption") Then
		RoundOffOption = Parameters.RoundOffOption;
	EndIf;
	
	If Parameters.Property("PriceRangeBoundary") Then
		PriceRangeBoundary = Parameters.PriceRangeBoundary;
	Else 
		PriceRangeBoundary = -1;
	EndIf;
	
	If Parameters.Property("SmartRounding") Then
		SmartRounding = Parameters.SmartRounding;
		UsePsychologicalRounding = True;
	EndIf;
	
	If Parameters.Property("ExampleNumber") Then
		ExampleNumber = Parameters.ExampleNumber;
	Else
		ExampleNumber = 1111.11;
	EndIf;
	
	ExampleResult = CalculateExampleResult(ExampleNumber, RoundingPrecision, RoundOffOption, SmartRounding);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	CustomizeForm();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ReturnValue = New Structure;
	ReturnValue.Insert("SmartRounding", SmartRounding);
	ReturnValue.Insert("RoundingPrecision", RoundingPrecision);
	ReturnValue.Insert("RoundOffOption", RoundOffOption);
	Close(ReturnValue);
	
EndProcedure

&AtClient
Procedure GenerateExample(Command)
	
	ExampleResult = CalculateExampleResult(ExampleNumber, RoundingPrecision, RoundOffOption, SmartRounding);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExampleNumberOnChange(Item)
	
	ExampleResult = CalculateExampleResult(ExampleNumber, RoundingPrecision, RoundOffOption, SmartRounding);
	
EndProcedure

&AtClient
Procedure RoundingPrecisionOnChange(Item)
	UpdateRounding();
	If SmartRounding > RoundingPrecision Then
		SmartRounding = RoundingPrecision - 0.01;
	EndIf;
	Items.SmartRounding.MaxValue = RoundingPrecision - 0.01;
EndProcedure

&AtClient
Procedure RoundOffOptionOnChange(Item)
	UpdateRounding();
EndProcedure

&AtClient
Procedure SmartRoundingOnChange(Item)
	UpdateRounding();
EndProcedure

#EndRegion

#Region Private

// Generates a rounding example
//
//
// Parameters:
//	ExampleNumber               - Number - the number used as an example
//	RoundingPrecision        - Number - rounding precision of the number
//	RoundOffOption         - EnumRef.RoundingOptions
//	SmartRounding - Number  - a number that defines the use of anti-rounding.
//
// Returns:
//	CatalogRef.TypesOfPrices - the found type of prices.
//
&AtClientAtServerNoContext
Function CalculateExampleResult(Val ExampleNumber,
	                              Val RoundingPrecision,
	                              Val RoundOffOption,
	                              Val SmartRounding)
	
	If ValueIsFilled(RoundingPrecision) Then
		ExampleNumber = PriceManagementSystemClientServer.RoundUpPrice(ExampleNumber, RoundingPrecision, RoundOffOption);
	EndIf;
	
	Return PriceManagementSystemClientServer.ApplyPsychologicalRounding(ExampleNumber, SmartRounding);
	
EndFunction

// Updates the value of the rounding, and calculates the example
//
&AtClient
Procedure UpdateRounding()
	
	ExampleResult = CalculateExampleResult(ExampleNumber, RoundingPrecision, RoundOffOption, SmartRounding);
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	ConfigureAvailabilityOfFormElements(ThisForm);
	
	// Forming a selection list for the Rounding Rule field The Rounding value
	Items.RoundingPrecision.ChoiceList.Clear();
	RoundingValue             = 0.01;
	EvenIncrement               = False;
	MaximumRoundingValue = 1000;
	PriceRangeBoundary            = -1;
	
	While RoundingValue <= MaximumRoundingValue 
		And (RoundingValue <= PriceRangeBoundary Or PriceRangeBoundary < 0) Do
		
		Items.RoundingPrecision.ChoiceList.Add(RoundingValue);
		RoundingValue = RoundingValue * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
EndProcedure


&AtClientAtServerNoContext
Procedure ConfigureAvailabilityOfFormElements(Form)
	
	Form.Items.SmartRounding.Visible = Form.UsePsychologicalRounding;

EndProcedure

#EndRegion
