
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("DisplayColumnNumbering", DisplayColumnNumbering)
	 Or Not Parameters.Property("DisplayRowsNumbering", DisplayRowsNumbering) Then
		MessageText = NStr("vi = 'Không xem xét mở trực tiếp biểu mẫu này.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı.'");
		Raise MessageText;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	Result = New Structure;
	Result.Insert("DisplayColumnNumbering", DisplayColumnNumbering);
	Result.Insert("DisplayRowsNumbering", DisplayRowsNumbering);
	
	Close(Result);
	
EndProcedure
