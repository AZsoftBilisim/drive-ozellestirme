
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner") Then
		Asset = Parameters.Filter.Owner;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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

&AtClient
Procedure GenerateBarcodes(Command)
	
	If Items.List.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn nút';
								|ru = 'Необходимо выбрать узлы';
								|en = 'Select sub-assets'; fa = 'Select sub-assets';
								|it = 'È necessario selezionare i nodi';
								|pl = 'Należy wybrać węzły';
								|tr = 'Alt varlıklar seçilmeli'"));
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Khởi tạo mã vạch đối với các nút đã chọn?';
					|ru = 'Сгенерировать штрихкоды для выбранных узлов?';
					|en = 'Generate barcodes for selected sub-assets?'; fa = 'Generate barcodes for selected sub-assets?';
					|it = 'Generare codici a barre per i nodi selezionati?';
					|pl = 'Wygenerować kody kreskowe dla wybranych węzłów?';
					|tr = 'Seçilen alt varlıklar için barkodlar oluşturulsun mu?'");
	CallbackDescription = New CallbackDescription("GenerateBarcodesCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

#Region StandardSubsystems

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region StandardSubsystems

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure GenerateBarcodesCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		RMManagementClient.GenerateNodeBarcodes(Items.List.SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	Result = FindNodeByBarcode(BarcodeData_5);
	If Result = Undefined Then
		ShowMessageBox(, NStr("vi = 'Không thể tìm thấy nút theo mã vạch';
								|ru = 'Не удалось найти узел по штрихкоду';
								|en = 'Cannot find a sub-asset using the barcode'; fa = 'Cannot find a sub-asset using the barcode';
								|it = 'Non è stato possibile trovare il nodo per codice a barre';
								|pl = 'Nie udało się znaleźć węzła wg kodu kreskowego';
								|tr = 'Barkoda ilişkin alt varlık bulunamadı'"));
		Return;
	EndIf;

	Items.List.CurrentRow = Result;
	ShowValue(, Result);
	
EndProcedure

&AtServer
Function FindNodeByBarcode(Val BarcodeData_5)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Owner", Asset);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Filter", FilterParameters);
	
	Result = RMManagement.FindNodesByBarcodes(BarcodeData_5, PickingParameters);
	If Result.ObjectsArray.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return Result.ObjectsArray[0];
	
EndFunction

#EndRegion

#EndRegion