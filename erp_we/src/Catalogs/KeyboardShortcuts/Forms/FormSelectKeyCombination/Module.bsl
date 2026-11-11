
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	KeyArray = New Array;
	
	KeyArray.Add(Key.A);
	KeyArray.Add(Key.B);
	KeyArray.Add(Key.C);
	KeyArray.Add(Key.D);
	KeyArray.Add(Key.E);
	KeyArray.Add(Key.F);
	KeyArray.Add(Key.G);
	KeyArray.Add(Key.H);
	KeyArray.Add(Key.I);
	KeyArray.Add(Key.J);
	KeyArray.Add(Key.K);
	KeyArray.Add(Key.L);
	KeyArray.Add(Key.M);
	KeyArray.Add(Key.N);
	KeyArray.Add(Key.O);
	KeyArray.Add(Key.P);
	KeyArray.Add(Key.Q);
	KeyArray.Add(Key.R);
	KeyArray.Add(Key.S);
	KeyArray.Add(Key.T);
	KeyArray.Add(Key.U);
	KeyArray.Add(Key.V);
	KeyArray.Add(Key.W);
	KeyArray.Add(Key.X);
	KeyArray.Add(Key.Y);
	KeyArray.Add(Key.Z);
	
	KeyArray.Add(Key.F1);
	KeyArray.Add(Key.F2);
	KeyArray.Add(Key.F3);
	KeyArray.Add(Key.F4);
	KeyArray.Add(Key.F5);
	KeyArray.Add(Key.F6);
	KeyArray.Add(Key.F7);
	KeyArray.Add(Key.F8);
	KeyArray.Add(Key.F9);
	KeyArray.Add(Key.F10);
	KeyArray.Add(Key.F11);
	KeyArray.Add(Key.F12);
	
	KeyArray.Add(Key._1);
	KeyArray.Add(Key._2);
	KeyArray.Add(Key._3);
	KeyArray.Add(Key._4);
	KeyArray.Add(Key._5);
	KeyArray.Add(Key._6);
	KeyArray.Add(Key._7);
	KeyArray.Add(Key._8);
	KeyArray.Add(Key._9);
	
	KeyArray.Add(Key.Num0);
	KeyArray.Add(Key.Num1);
	KeyArray.Add(Key.Num2);
	KeyArray.Add(Key.Num3);
	KeyArray.Add(Key.Num4);
	KeyArray.Add(Key.Num5);
	KeyArray.Add(Key.Num6);
	KeyArray.Add(Key.Num7);
	KeyArray.Add(Key.Num8);
	KeyArray.Add(Key.Num9);
	KeyArray.Add(Key.NumAdd);
	KeyArray.Add(Key.NumDecimal);
	KeyArray.Add(Key.NumDivide);
	KeyArray.Add(Key.NumMultiply);
	KeyArray.Add(Key.NumSubtract);
	
	KeyArray.Add(Key.Space);
	KeyArray.Add(Key.BackSpace);
	KeyArray.Add(Key.Break);
	
	Data = Undefined;
	If Parameters.Property("Address") Then
		Data = GetFromTempStorage(Parameters.Address);
	EndIf;
	
	For Each KeyElement In KeyArray Do
		
		NewRow = KeyCombinationsTable.Add();
		NewRow.KeyName = String(KeyElement);
		
		KeyboardShortcutPresentation(NewRow, Data, "Key",        New Shortcut(KeyElement, False,   False,   False));
		
		KeyboardShortcutPresentation(NewRow, Data, "Ctrl",           New Shortcut(KeyElement, False,   True, False));
		KeyboardShortcutPresentation(NewRow, Data, "Alt",            New Shortcut(KeyElement, True, False,   False));
		KeyboardShortcutPresentation(NewRow, Data, "Shift",          New Shortcut(KeyElement, False,   False,   True));
		
		KeyboardShortcutPresentation(NewRow, Data, "Alt_Shift",      New Shortcut(KeyElement, True, False,   True));
		KeyboardShortcutPresentation(NewRow, Data, "Ctrl_Shift",     New Shortcut(KeyElement, False,   True, True));
		KeyboardShortcutPresentation(NewRow, Data, "Ctrl_Alt",       New Shortcut(KeyElement, True, True, False));
		KeyboardShortcutPresentation(NewRow, Data, "Ctrl_Alt_Shift", New Shortcut(KeyElement, True, True, True));
		
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KeyCombinationsTableOnActivateRow(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	Shortcut = SelectedKeyCombination(Item.CurrentData, Item.CurrentItem);
	Presentation = Presentation(Shortcut);
	
EndProcedure

&AtClient
Procedure KeyCombinationsTableOnActivateField(Item)
	
	Shortcut = SelectedKeyCombination(Item.CurrentData, Item.CurrentItem);
	Presentation = Presentation(Shortcut);
	
EndProcedure

&AtClient
Procedure KeyCombinationsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = KeyCombinationsTable.FindByID(RowSelected);
	Close(SelectedKeyCombination(CurrentData, Field));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(Shortcut);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command) Export
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Function FillInStructureOfCombinations(Var_Key, ThisIsAlt, ThisIsCtrl, ThisIsShift)

	ReturnStructure = New Structure;
	ReturnStructure.Insert("Key", Var_Key);
	ReturnStructure.Insert("Alt",     ThisIsAlt);
	ReturnStructure.Insert("Ctrl",    ThisIsCtrl);
	ReturnStructure.Insert("Shift",   ThisIsShift);
	
	Return ReturnStructure;

EndFunction // Fill in the structure of the combinations()

&AtClient
Function SelectedKeyCombination(CurrentData, Field)
	
	Array = New Array;
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableKey,        False,   False,   False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableAlt,            True, False,   False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl,           False,   True, False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableShift,          False,   False,   True));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableAlt_Shift,      True, False,   True));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_Alt,       True, True, False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_Shift,     False,   True, True));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_Alt_Shift, True, True, True));
	
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableKey_,        False,   False,   False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableAlt_,            True, False,   False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_,           False,   True, False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableShift_,          False,   False,   True));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableAlt_Shift_,      True, False,   True));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_Alt_,       True, True, False));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_Shift_,     False,   True, True));
	Array.Add(FillInStructureOfCombinations(Items.KeyCombinationsTableCtrl_Alt_Shift_, True, True, True));
	
	For Each ArrayElement In Array Do
		
		If ArrayElement.Key = Field Then
			
			KeyName = CurrentData.KeyName;
			Return FillInStructureOfCombinations(KeyName, ArrayElement.Alt, ArrayElement.Ctrl, ArrayElement.Shift);
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServerNoContext
Function Presentation(Shortcut)
	
	Return TMCommonUse.KeyboardShortcutPresentation(Shortcut, True);
	
EndFunction

&AtServer
Procedure KeyboardShortcutPresentation(NewRow, Data, Name, Combination)
	
	NewRow[Name] = TMCommonUse.KeyboardShortcutPresentation(Combination, True);
	
	StructureOfCombinations = FillInStructureOfCombinations(String(Combination.Key), Combination.Alt, Combination.Ctrl, Combination.Shift);
	
	If ValueIsFilled(Data) Then
		FoundRows = Data.FormCommands.FindRows(StructureOfCombinations); // Array of ValueTableRow - See Catalog.KeyboardShortcuts.Form.ItemForm.FormCommands
		If FoundRows.Count() > 0 Then
			NewRow[Name+"_"] = FoundRows[0].Title;
		EndIf;
		
		FoundRows = Data.QuickGoods.FindRows(StructureOfCombinations); // Array of ValueTableRow - See Catalog.KeyboardShortcuts.Form.ItemForm.QuickGoods
		If FoundRows.Count() > 0 Then
			NewRow[Name+"_"] = FoundRows[0].Title;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
