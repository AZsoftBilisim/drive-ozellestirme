#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.ObjectBeforeType) Then
		Return;
	EndIf;
	
	Parameters.Property("ReasonForInterruption", ReasonForInterruption);
	
	ArrayOfMessageText = New Array;
	
	If Parameters.ObjectBeforeType = "DMDocument" Then
		ArrayOfMessageText.Add(NStr("vi = 'Sẽ thực hiện ngắt xử lý chứng từ';
									|ru = 'Будет выполнено прерывание обработки документа';
									|en = 'The document processing will be interrupted'; fa = 'The document processing will be interrupted';
									|it = 'Будет выполнено прерывание обработки документа';
									|pl = 'The document processing will be interrupted';
									|tr = 'Belgenin işlenmesi sonlandırılacaktır'"));
		
	ElsIf Parameters.ObjectBeforeType = "DMMeeting" Then
		ArrayOfMessageText.Add(NStr("vi = 'Sẽ thực hiện ngắt xử lý cuộc họp';
									|ru = 'Будет выполнено прерывание обработки мероприятия';
									|en = 'The event processing will be interrupted'; fa = 'The event processing will be interrupted';
									|it = 'Будет выполнено прерывание обработки мероприятия';
									|pl = 'The event processing will be interrupted';
									|tr = 'Etkinliğin işlenmesi sonlandırılacaktır'"));
		
	Else
		Raise StrTemplate(NStr("vi = 'Kiểu đối tượng xử lý không xác định %1.';
								|ru = 'Неизвестный тип объекта обработки %1.';
								|en = 'Unknown data processor object type: %1.'; fa = 'Unknown data processor object type: %1.';
								|it = 'Неизвестный тип объекта обработки %1.';
								|pl = 'Unknown data processor object type: %1.';
								|tr = '%1 işlemesi nesnesinin bilinmeyen tipi.'"), Parameters.ObjectBeforeType);
		
	EndIf;
	
	ArrayOfMessageText.Add(" ");
	ArrayOfMessageText.Add("""");
	ArrayOfMessageText.Add(Parameters.ObjectBefore);
	ArrayOfMessageText.Add("""");
	ArrayOfMessageText.Add(".");
	ArrayOfMessageText.Add(Chars.LF);
	ArrayOfMessageText.Add(Chars.LF);
	ArrayOfMessageText.Add(NStr("vi = 'Sẽ sắp xếp thông tin về việc thực hiện vào lịch sử.';
								|ru = 'Информация о выполнении будет помещена в историю.';
								|en = 'Execution information will be placed in the history.'; fa = 'Execution information will be placed in the history.';
								|it = 'Информация о выполнении будет помещена в историю.';
								|pl = 'Execution information will be placed in the history.';
								|tr = 'Yürütme bilgileri geçmişe eklenecektir.'"));
	ArrayOfMessageText.Add(Chars.LF);
	ArrayOfMessageText.Add(Chars.LF);
	ArrayOfMessageText.Add(NStr("vi = 'Chú ý! Sẽ không thể thay đổi được những thay đổi được nhập.';
								|ru = 'Внимание! Все внесенные изменения будут необратимыми.';
								|en = 'Note. All changes made will be irreversible.'; fa = 'Note. All changes made will be irreversible.';
								|it = 'Внимание! Все внесенные изменения будут необратимыми.';
								|pl = 'Note. All changes made will be irreversible.';
								|tr = 'Dikkat! Yapılan tüm değişiklikler geri alınamayacaktır.'"));
	
	MessageText = StrConcat(ArrayOfMessageText);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AbortProcessing(Command)
	
	Result = New Structure("ReasonForInterruption", StrReplace(ReasonForInterruption, Chars.LF, " "));
	
	Close(Result);
	
EndProcedure

#EndRegion