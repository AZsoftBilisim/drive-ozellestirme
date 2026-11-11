
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	If ValueIsFilled(Parameters.SubjectOf) Then
		CommonClientServer.SetDynamicListFilterItem(List, "SubjectOf", Parameters.SubjectOf, DataCompositionComparisonType.Equal,,True);
	EndIf;
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.SelectionApprovalPeriod.ChoiceList);
	
	List.Parameters.SetParameterValue("IsBlankString",          "");
	List.Parameters.SetParameterValue("OnApproval", NStr("vi = 'Trong quá trình thống nhất';
														|ru = 'В процессе согласования';
														|en = 'Pending approval'; fa = 'در انتظار تأیید';
														|it = 'Nel processo degli accordi';
														|pl = 'W trakcie uzgadniania';
														|tr = 'Onay sürecinde'"));
	List.Parameters.SetParameterValue("Approved",           NStr("vi = 'Đã thống nhất';
																|ru = 'Согласовано';
																|en = 'Approved'; fa = 'تأییدشده';
																|it = 'Concordato';
																|pl = 'Uzgodniono';
																|tr = 'Onaylandı'"));
	List.Parameters.SetParameterValue("NotApproved",         NStr("vi = 'Không thống nhất';
																	|ru = 'Не согласовано';
																	|en = 'Not approved'; fa = 'تأییدنشده';
																	|it = 'Non concordato';
																	|pl = 'Nie uzgodniono';
																	|tr = 'Onaylanmadı'"));
	
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,,ValueIsFilled(State));
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, UpdateDate, Items.SelectionApprovalPeriod.ChoiceList);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	State          = Settings.Get("State");
	Relevance       = Settings.Get("Relevance");
	UpdateDate   = Settings.Get("UpdateDate");
	
	If ValueIsFilled(UpdateDate) Then
		List.Parameters.SetParameterValue("UpdateDate", UpdateDate);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,,ValueIsFilled(State));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"State",
		State,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure SelectionApprovalPeriodOnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.SelectionApprovalPeriod.ChoiceList);
	
EndProcedure

&AtClient
Procedure SelectionApprovalPeriodClearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SelectionApprovalPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"SelectionApprovalPeriod",
		"EventDate");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion