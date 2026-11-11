
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DiscountMarkupConditions = Parameters.DiscountMarkupConditions.Copy();
	Title = Title + ": " + String(Parameters.Document);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupCreate",
		"Visible",
		AccessRight("InteractiveInsert", Metadata.Catalogs.DiscountMarkupTerms));
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DiscountsMarkupsServer.AddCommandsToCreateNewConditionsForDiscountsMarkups(ThisObject, Items.GroupCreate);
	
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
	
	SearchResult = DiscountMarkupConditions.FindByValue(Item.CurrentData.Ref);
	
	If SearchResult = Undefined Then
		DiscountMarkupConditions.Add(Item.CurrentData.Ref);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	If DiscountMarkupConditions.Count() = 0 Then
		ShowQueryBox(New CallbackDescription("MoveToDocumentCompletion", ThisObject), NStr("vi = 'Chưa chọn điều kiện nào. Đóng?';
																							|ru = 'Не подобрано ни одного условия. Закрыть?';
																							|en = 'No condition is selected. Close?'; fa = 'No condition is selected. Close?';
																							|it = 'Non è scelta nemmeno una condizione. Chiudere?';
																							|pl = 'Nie wybrano ani jednego warunku. Zamknąć?';
																							|tr = 'Herhangi bir şart seçilmedi. Kapatılsın mı?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	Close(DiscountMarkupConditions);
EndProcedure

&AtClient
Procedure MoveToDocumentCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response = DialogReturnCode.Yes Then
        Close(DiscountMarkupConditions);
    EndIf;
    
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommandToCreateConditionsForProvisionOfDiscountsMargins(Command)
	
	DiscountsMarkupsClient.ProcessCommandToAddConditionsForGrantingDiscountsMarkups(
		ThisObject,
		Command,
		Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
