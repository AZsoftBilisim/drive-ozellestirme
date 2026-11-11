
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	Title = Parameters.ItemKind;
	Items.NameForPrinting.Enabled = DisplayItemTitle;
	AdditionalFormMode = Parameters.AdditionalFormMode;
	Items.GroupAddAttributes.Visible = Parameters.ShowRowCodeNote;
	Items.ReverseSign.Visible = Parameters.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup;
	Items.Accuracy.Visible = Parameters.ItemKind = Enums.FinancialReportItemKinds.TotalByGroup;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel, AdditionalFormMode);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure DisplayItemTitleOnChange(Item)
	
	Items.NameForPrinting.Enabled = DisplayItemTitle;
	Object.NameForPrinting = ?(DisplayItemTitle, Object.NameForPrinting, "Group");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
