//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Parameters.Property("AbortAllowed", AbortAllowed);

	DialogTitle = "";
	If Parameters.Property("DialogTitle", DialogTitle) And ValueIsFilled(DialogTitle) Then
		ThisObject.Title = DialogTitle;
		ThisObject.AutoTitle = False;
	EndIf;

	If Not AbortAllowed Then
		Items.TimeConsumingOperationNoteTextDecoration.ToolTip = NStr(
			"vi = 'Giao dịch không thể bị gián đoạn cho đến khi hoàn thành';
			|ru = 'Операцию нельзя прервать до окончания выполнения';
			|en = 'Operation cannot be aborted until it is completed'; fa = 'Operation cannot be aborted until it is completed';
			|it = 'L''operazione non può essere interrotta prima del completamento';
			|pl = 'Operacje nie można przerwać przed zakończeniem wykonania';
			|tr = 'İşlem tamamlanmadan durdurulamaz'");
		Items.TimeConsumingOperationNoteTextDecoration.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Exit Then
		Return;
	EndIf;

	OperationAborted = True;

	Cancel = Not AbortAllowed;

EndProcedure

#EndRegion