
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.StockLevelCode = 0 Then
		Any = 1;
	ElsIf Parameters.StockLevelCode = 1 Then
		ToBeOrderedUrgently = 1;
	ElsIf Parameters.StockLevelCode = 2 Then
		CloseToTheOrder = 1;
	ElsIf Parameters.StockLevelCode = 3 Then
		ForOrderCancellation = 1;
	ElsIf Parameters.StockLevelCode = 4 Then
		LessThanHalf = 1;
	ElsIf Parameters.StockLevelCode = 5 Then
		OverHalf = 1;
	ElsIf Parameters.StockLevelCode = 6 Then
		Surplus = 1;
	EndIf;
	
	Picture = True;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AnyOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("Any");
EndProcedure

&AtClient
Procedure ToBeOrderedUrgentlyOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("ToBeOrderedUrgently");
EndProcedure

&AtClient
Procedure CloseToTheOrderOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("CloseToTheOrder");
EndProcedure

&AtClient
Procedure ForOrderCancellationOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("ForOrderCancellation");
EndProcedure

&AtClient
Procedure LessThanHalfOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("LessThanHalf");
EndProcedure

&AtClient
Procedure OverHalfOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("OverHalf");
EndProcedure

&AtClient
Procedure SurplusOnChange(Item)
	WhenChangingSwitchOfSecurityIndicator("Surplus");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	StockLevelCode =
		?(Any = 1,            0,
		?(ToBeOrderedUrgently = 1,    1,
		?(CloseToTheOrder = 1,    2,
		?(ForOrderCancellation = 1,    3,
		?(LessThanHalf = 1,   4,
		?(OverHalf = 1,   5,
		?(Surplus = 1,          6, Undefined)))))));
	
	ValueSelected = New Structure("StockLevelCode", StockLevelCode);
	
	NotifyChoice(ValueSelected);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WhenChangingSwitchOfSecurityIndicator(SelectedIndicator)
	
	Any =          0;
	ToBeOrderedUrgently =  0;
	CloseToTheOrder =  0;
	ForOrderCancellation =  0;
	LessThanHalf = 0;
	OverHalf = 0;
	Surplus =        0;
	ThisForm[SelectedIndicator] = 1;
	
EndProcedure

#EndRegion
