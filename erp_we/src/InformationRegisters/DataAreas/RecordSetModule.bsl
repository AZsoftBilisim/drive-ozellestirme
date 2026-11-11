#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// @skip-check data-exchange-load
Procedure OnWrite(Cancel, Replacing)
	
	// Deceived.The upload is not checked so that an incorrect entry cannot be added.
	// It is necessary to perform the check in the recording, because the data area is guaranteed to be filled in here.
	If Not Common.IsRecordSetDeletion(Replacing) Then
		For Each Record In ThisObject Do
			If Record.DataAreaAuxiliaryData = 0 Then
				Raise NStr("vi = 'Cấm sử dụng vùng có giá trị chia tách 0';
							|ru = 'Запрещено использовать область со значением разделителя 0';
							|en = 'Cannot use an area with a separator value of 0'; fa = 'Cannot use an area with a separator value of 0';
							|it = 'Non è possibile utilizzare l''area con valore di separatore 0';
							|pl = 'Zabronione jest używanie obszaru o wartości separatoraразделителя 0';
							|tr = 'Ayırıcı değeri 0 olan alanın kullanılması yasaktır.'");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
