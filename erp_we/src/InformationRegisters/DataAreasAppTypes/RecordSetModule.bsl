#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If (Count() = 0 Or Common.IsRecordSetDeletion(Replacing)) And Modified() Then
		Cancel = True;
		Raise NStr("vi = 'Đã cấm xóa dữ liệu dạng ứng dụng';
					|ru = 'Запрещено удалять данные вида приложения';
					|en = 'Cannot delete application type data'; fa = 'Cannot delete application type data';
					|it = 'Запрещено удалять данные вида приложения';
					|pl = 'Cannot delete application type data';
					|tr = 'Uygulama türü verilerini silmek yasaktır'");
	EndIf;
	
EndProcedure

// @skip-check data-exchange-load
Procedure OnWrite(Cancel, Replacing)
	
	// Deceived.The upload is not checked so that an incorrect entry cannot be added.
	// It is necessary to perform the check in the recording, because the data area is guaranteed to be filled in here.
	
	If Not Common.IsRecordSetDeletion(Replacing) Then
		For Each Record In ThisObject Do
			If Record.DataAreaAuxiliaryData = 0 Then
				Raise NStr("vi = 'Đã cấm thiết lập dạng ứng dụng cho vùng có giá trị đường chia tách 0';
							|ru = 'Запрещено устанавливать вид приложения для области со значением разделителя 0';
							|en = 'Cannot set application type for areas with 0 separator'; fa = 'Cannot set application type for areas with 0 separator';
							|it = 'Запрещено устанавливать вид приложения для области со значением разделителя 0';
							|pl = 'Cannot set application type for areas with 0 separator';
							|tr = 'Ayırıcı değeri 0 olan alan için uygulama türünün yapılandırılması yasaktır'");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf