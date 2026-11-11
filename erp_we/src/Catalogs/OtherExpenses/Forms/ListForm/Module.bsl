
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetDynamicListParameters();

	// StandardSubsystems.AttachableCommands
	TypesList = ListOfExpenseItems.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.ListOfExpenseItemsCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	SelectedRows = Items.ListOfExpenseItems.SelectedRows;
	If SelectedRows.Count() > 0 Then
		ExpenseItem = SelectedRows[0];
		If Not ValueIsFilled(ExpenseItem) Or ThisIsGroupOfExpenditureItems(ExpenseItem) Then
			Cancel = True;
		EndIf; 
	Else
		Cancel = True;
	EndIf;
	
	If Cancel Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
										|ru = 'Команда не может быть выполнена для указанного объекта!';
										|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
										|it = 'Il comando non può essere eseguito per oggetto indicato!';
										|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
										|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
	EndIf; 
	
EndProcedure

&AtClient
Procedure ListOfExpenseItemsOnActivateRow(Item)
	
	SetDynamicListParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListOfExpenseItems);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListOfExpenseItems, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListOfExpenseItems);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetDynamicListParameters()
	
	SelectedRows = Items.ListOfExpenseItems.SelectedRows;
	If SelectedRows.Count() > 0 Then
		ExpenseItem = SelectedRows[0];
	Else
		ExpenseItem = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Owner", ExpenseItem, DataCompositionComparisonType.Equal,, True);
	
EndProcedure

&AtServer
Function ThisIsGroupOfExpenditureItems(ExpenseItem)
	
	Return ExpenseItem.IsFolder;
	
EndFunction

#EndRegion

#EndRegion
