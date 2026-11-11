#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInTheGoodsTable();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Not ClosingInProgress And Modified And Not Exit Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			NStr("vi = 'Đã thay đổi dữ liệu. Đưa các thay đổi vào chứng từ?';
				|ru = 'Данные были изменены. Перенести изменения в документ?';
				|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
				|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
				|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"), QuestionDialogMode.YesNoCancel);

	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfGoods

&AtClient
Procedure TableOfGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.TableOfGoods.CurrentData <> Undefined Then
		If Field.Name = "TableOfGoodsRequestForGoodsQualityControl" Then
			ShowValue(Undefined, Items.TableOfGoods.CurrentData.RequestForGoodsQualityControl);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()

	MoveProductsToDocument();

EndProcedure

&AtClient
Procedure ToChooseTheProductsExecute()
	
	SelectAllProductsOnServer(True);
	
EndProcedure

&AtClient
Procedure ExcludeGoodsExecute()
	
	SelectAllProductsOnServer(False);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Modified = False;
		MoveProductsToDocument();
		
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Modified = False;
		Close();
		
	EndIf;

EndProcedure

&AtServer
Procedure SelectAllProductsOnServer(SelectionValue = True)
	
	For Each TableRow In TableOfGoods.FindRows(New Structure("RowIsSelected", Not SelectionValue)) Do
		
		TableRow.RowIsSelected = SelectionValue;
		
	EndDo;
	
EndProcedure

&AtServer
Function PutProductsInStorage()

	// Forming a table to return to the document.
	SelectedGoodsTable = TableOfGoods.Unload(New Structure("RowIsSelected", True));

	GoodsAddressInStorage = PutToTempStorage(SelectedGoodsTable);

	Return GoodsAddressInStorage;

EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	TableOfGoods.Clear();
	Analysts = QualityControl.AnalystsOfReceivedGoods(Parameters.RequestForControl);
	TableOfGoods.Load(QualityControl.AnalystBalances(Analysts, False, CurrentSessionDate()));
	For Each TSRow In TableOfGoods Do
		TSRow.RequestForGoodsQualityControl = Parameters.RequestForControl;
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()

	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;

	GoodsAddressInStorage = PutProductsInStorage();

	Close();

	NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));

EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
