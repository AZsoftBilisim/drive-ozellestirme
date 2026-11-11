#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("NonFinancialItem", NonFinancialItem) Then
		MessageText = NStr("vi = 'Mở trực tiếp của hình thức này không được cung cấp. Để mở biểu mẫu, bạn có thể sử dụng lệnh ""Lịch sử thay đổi"" dưới dạng chỉ báo phi tài chính.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Для открытия формы можно воспользоваться командой ""История изменений"" в форме нефинансового показателя.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you select the ""Change history"" command in the form of non-financial item.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you select the ""Change history"" command in the form of non-financial item.';
							|it = 'L''apertura diretta di questo modulo non è prevista. Per aprire un modulo è possibile utilizzare il comando ""Storia delle modifiche"" nel modulo dell''indice non finanziario.';
							|pl = 'Bezpośrednie otwarcie tego formularza nie jest przewidziane. Aby otworzyć formularz, możesz użyć polecenia ""Historia zmian"" w postaci wskaźnika niefinansowego.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Formun açılması için finansal olmayan öğe formunda yer alan ""Değişiklik geçmişi"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;
	
	Parameter = List.Parameters.Items.Find("NonFinancialItem");
	Parameter.Value = NonFinancialItem;
	Parameter.Use = True;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Return;
	EndIf;
	
	Cancel = True;
	
	InstallationParameters = New Structure();
	FillingValues = New Structure("NonFinancialItem, OperationKind", NonFinancialItem,
			PredefinedValue("Enum.OperationKindsOfSettingOfNonFinancialItemValues.EnterIndicatorValue"));
	InstallationParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Document.SetValuesForNonFinancialItems.Form.DocumentForm", InstallationParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

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