
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	DiscountsMarkups = Parameters.DiscountsMarkups.Copy();
	Title = Title + ": " + String(Parameters.Document);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupCreate",
		"Visible",
		AccessRight("InteractiveInsert", Metadata.Catalogs.DiscountsMarkups));
	
	DiscountsMarkupsServer.AddCommandsToCreateNewDiscountsMarkups(ThisObject, Items.GroupCreate);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentData.IsFolder Then
		Return;
	EndIf;
	
	SearchResult = DiscountsMarkups.FindByValue(Item.CurrentData.Ref);
	
	If SearchResult = Undefined Then
		DiscountsMarkups.Add(Item.CurrentData.Ref);
	EndIf;

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

&AtClient
Procedure MoveToDocument(Command)
	
	If DiscountsMarkups.Count() = 0 Then
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("MoveToDocumentCompletion", ThisObject), NStr("vi = 'Không chọn bất kỳ chiết khấu (phụ thu) nào. Đóng?';
																							|ru = 'Не подобрано ни одной скидки (наценки). Закрыть?';
																							|en = 'No discount (markup) is selected. Close?'; fa = 'No discount (markup) is selected. Close?';
																							|it = 'Non è stato selezionato alcun sconto (sovrapprezzo). Chiudere?';
																							|pl = 'Nie wybrano żadnego rabatu (marży). Zamknąć?';
																							|tr = 'Herhangi bir indirim (zam) seçilmedi. Kapatılsın mı?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	Close(DiscountsMarkups);
EndProcedure

&AtClient
Procedure MoveToDocumentCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    Close(DiscountsMarkups);

EndProcedure

&AtClient
Procedure Attachable_ExecuteCommandToAddDiscountMarkUp(Command)
	
	DiscountsMarkupsClient.ProcessCommandToAddDiscountMarkUp(
		ThisObject,
		Command,
		Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
