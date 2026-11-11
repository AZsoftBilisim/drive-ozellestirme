
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Var_Group       = Undefined;
	IndexOf       = 0;
	GroupIndex = 0;
	
	KeyboardShortcuts = Parameters.KeyboardShortcuts;
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	KeyboardShortcuts.QuickGoods AS QuickGoods
	|FROM
	|	Catalog.KeyboardShortcuts AS KeyboardShortcuts
	|WHERE
	|	KeyboardShortcuts.Ref = &Ref");
	
	Query.SetParameter("Ref", KeyboardShortcuts);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	SetPrivilegedMode(False);
	
	ThereAreFastGoods = False;
	If Selection.Next() Then
		
		ThereAreFastGoods = True;
		
		SamplingQuickProducts = Selection.QuickGoods; // ValueStorage
		TSQuickGoods = SamplingQuickProducts.Get(); // See Catalogs.KeyboardShortcuts.NewCommand.Table
		
		For Each TSRow In TSQuickGoods Do
			
			If ValueIsFilled(TSRow.Products) Then
				
				ButtonName = "QuickProduct_" + TSQuickGoods.IndexOf(TSRow);
				
				If Var_Group = Undefined Or IndexOf >= 6 Then
					GroupIndex = GroupIndex + 1;
					Var_Group = Items.Add("Group_" + GroupIndex, Type("FormGroup"), ThisForm);
					Var_Group.Type                 = FormGroupType.UsualGroup;
					Var_Group.ShowTitle = False;
					Var_Group.Representation         = UsualGroupRepresentation.None;
					Var_Group.Group         = ChildFormItemsGroup.Horizontal;
					IndexOf = 0;
				EndIf;
				
				IndexOf = IndexOf + 1;
				
				NewCommand = ThisForm.Commands.Add(ButtonName);
				NewCommand.Action        = "QuickProductSelected";
				
				NewCommand.Representation     = ButtonRepresentation.Text;
				NewCommand.Shortcut = New Shortcut(Key[TSRow.Key], TSRow.Alt, TSRow.Ctrl, TSRow.Shift);
				
				If ValueIsFilled(TSRow.Title) Then
					NewCommand.Title = TSRow.Title;
				Else
					NewCommand.Title = String(TSRow.Products);
				EndIf;
				NewCommand.Title = NewCommand.Title + Chars.LF + TMCommonUse.KeyboardShortcutPresentation(NewCommand.Shortcut);
				
				NewButton = Items.Add(ButtonName, Type("FormButton"), Var_Group);
				NewButton.Type = FormButtonType.UsualButton;
				NewButton.CommandName = NewCommand.Name;
				NewButton.Height = 3;
				NewButton.Width = 12;
				
				NewProduct_ = QuickGoods.Add();
				FillPropertyValues(NewProduct_, TSRow);
				NewProduct_.CommandName = NewCommand.Name;
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Items.NoFastProducts.Visible = Not ThereAreFastGoods;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormEventHandlers

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure QuickProductSelected(Command)
	
	ProductData_8 = ProductData_8(Command.Name);
	
	NotificationParameters = New Structure();
	NotificationParameters.Insert("Products", ProductData_8.Products);
	NotificationParameters.Insert("Characteristic", ProductData_8.Characteristic);
	NotificationParameters.Insert("Package", ProductData_8.Package);
	NotificationParameters.Insert("ItemsType", ProductData_8.ItemsType);
	NotificationParameters.Insert("NumberOfPackages", 1);
	NotificationParameters.Insert("OwnerForm", FormOwner.UUID);
	
	If ProductData_8 <> Undefined Then
		Notify("QuickProductSelected", NotificationParameters);
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ProductData_8(CommandName)
	
	FoundRows = QuickGoods.FindRows(New Structure("CommandName", CommandName));
	If FoundRows.Count() > 0 Then
		
		RowData = FoundRows[0];
		
		ItemsType = Common.ObjectAttributeValue(RowData.Products, "ItemsType");
		
		ReturnStructure = New Structure();
		ReturnStructure.Insert("Products", RowData.Products);
		ReturnStructure.Insert("Characteristic", RowData.Characteristic);
		ReturnStructure.Insert("Package", RowData.Package);
		ReturnStructure.Insert("ItemsType", ItemsType);

		Return ReturnStructure;
		
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion
