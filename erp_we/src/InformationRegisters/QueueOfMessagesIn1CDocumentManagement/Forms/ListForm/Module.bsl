#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MaximumQuantity =
		IntegrationWith1CDocumentManagementCore.MaximumNumberOfAttemptsToSendExchangeMessage();
	
	Items.InformationDetails.Title = StrTemplate(
		NStr("vi = 'Số lần thử gửi thông báo tối đa bằng %1. Khi đạt đến số lần này, hệ thống sẽ không thực hiện thêm bất kỳ lần thử gửi nào nữa. Trong trường hợp này, cần sửa lỗi gửi, sau đó xóa thông báo khỏi hàng đợi, hoặc đặt lại bộ đếm lần gửi thử.';
			|ru = 'Максимальное количество попыток отправки сообщения равно %1. При достижении этого количества система не будет предпринимать новых попыток отправки. В такой ситуации нужно устранить ошибку отправки, затем либо удалить сообщение из очереди, либо сбросить счетчик попыток отправки.';
			|en = 'The maximum number of attempts to send a message is %1. When this number is reached, the system will not attempt sending again. In such situation, fix the sending error, then either delete the message from the queue, or reset the sending attempt counter.'; fa = 'The maximum number of attempts to send a message is %1. When this number is reached, the system will not attempt sending again. In such situation, fix the sending error, then either delete the message from the queue, or reset the sending attempt counter.';
			|it = 'The maximum number of attempts to send a message is %1. When this number is reached, the system will not attempt sending again. In such situation, fix the sending error, then either delete the message from the queue, or reset the sending attempt counter.';
			|pl = 'The maximum number of attempts to send a message is %1. When this number is reached, the system will not attempt sending again. In such situation, fix the sending error, then either delete the message from the queue, or reset the sending attempt counter.';
			|tr = 'Maksimum mesaj gönderme girişimi sayısı %1 değerindedir. Bu sayıya ulaşıldığında, sistem daha fazla gönderme girişimi yapmayı durduracaktır. Bu durumda, gönderme hatasını gidermeniz ve ardından mesajı kuyruktan silmeniz veya gönderme girişimi sayacını sıfırlamanız gerekmektedir.'"),
		MaximumQuantity);
	
	AppearanceItem = List.ConditionalAppearance.Items.Add();
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField(Items.Id.Name);
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField(Items.CreationDate.Name);
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField(Items.NumberOfSendingAttempts.Name);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("NumberOfSendingAttempts");
	FilterElement.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	FilterElement.RightValue = MaximumQuantity;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByIDOnChange(Item)
	
	If Not ValueIsFilled(ByID) Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Id",
			Undefined,
			DataCompositionComparisonType.Equal,,
			False);
		Return;
	EndIf;
	
	Try
		Id = New UUID(ByID);
	Except
		ShowMessageBox(, NStr("vi = 'Sai tên định danh';
								|ru = 'Идентификатор неверен';
								|en = 'ID is incorrect'; fa = 'ID is incorrect';
								|it = 'ID non autentico';
								|pl = 'Identyfikator jest niepoprawny';
								|tr = 'Kimlik geçersiz'"));
		CommonClientServer.SetDynamicListFilterItem(List,
			"Id",
			Undefined,
			DataCompositionComparisonType.Equal,,
			False);
		Return;
	EndTry;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Id",
		Id,
		DataCompositionComparisonType.Equal,,
		True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Async Procedure ResetSendingAttemptCounter(Val Command)
	
	MessagesCount = Items.List.SelectedRows.Count();
	
	If MessagesCount = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn thông báo nào.';
								|ru = 'Не выбрано ни одного сообщения.';
								|en = 'No message is selected.'; fa = 'No message is selected.';
								|it = 'No message is selected.';
								|pl = 'No message is selected.';
								|tr = 'Hiçbir mesaj seçilmedi.'"));
		Return;
	EndIf;
	
	QueryText = StrTemplate(
		NStr("vi = 'Đặt lại bộ đếm lần gửi thử đối với %1?';
			|ru = 'Сбросить счетчик попыток отправки для %1?';
			|en = 'Reset the sending attempt counter for %1?'; fa = 'Reset the sending attempt counter for %1?';
			|it = 'Reset the sending attempt counter for %1?';
			|pl = 'Reset the sending attempt counter for %1?';
			|tr = 'Gönderme deneme sayacı %1 için sıfırlansın mı?'"),
		StringDeclensionsByNumber(NStr("vi = 'thông báo';
										|ru = 'сообщение';
										|en = 'Message'; fa = 'پیام';
										|it = 'Message';
										|pl = 'Message';
										|tr = 'mesaj'"), MessagesCount, "NM=Cardinal", "DPAR=Genitive"));
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(QueryText);
	If Response = DialogReturnCode.Yes Then
		ResetSendingAttemptCounterAtServer(Items.List.SelectedRows);
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Clears the number of sending attempts for selected messages.
//
// Parameters:
//   ListOfSelectedMessages - Array of InformationRegisterRecordKey.QueueOfMessagesIn1CDocumentManagement
//
&AtServer
Procedure ResetSendingAttemptCounterAtServer(Val ListOfSelectedMessages)
	
	For Each Message In ListOfSelectedMessages Do
		Record = InformationRegisters.QueueOfMessagesIn1CDocumentManagement.CreateRecordManager();
		Record.PointInTime = Message.PointInTime;
		Record.Id = Message.Id;
		Record.Read();
		If Record.Selected() Then
			Record.NumberOfSendingAttempts = 0;
			Record.Write();
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function StringDeclensionsByNumber(Val RowBeingDeclined, Val Number, Val RowDescription, Val FormatString)
	
	Declensions = GetStringDeclensionsByNumber(RowBeingDeclined, Number,, RowDescription, FormatString);
	
	If Declensions.Count() = 1 Then
		Return Declensions[0];
	Else
		Return Declensions;
	EndIf;
	
EndFunction

#EndRegion