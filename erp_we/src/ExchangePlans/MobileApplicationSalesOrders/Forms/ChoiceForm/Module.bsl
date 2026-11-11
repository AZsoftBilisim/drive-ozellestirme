#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SelectionNode = Undefined;
	If Parameters.Property("Ref", SelectionNode) Then
		List.Parameters.SetParameterValue("Ref", SelectionNode);
	EndIf;
	
	Title = NStr("vi = 'Hãy chọn thiết bị có tùy chỉnh cá nhân để đồng bộ';
				|ru = 'Выберите устройство с индивидуальными настройками для синхронизации';
				|en = 'Select a device with custom settings for synchronization'; fa = 'Select a device with custom settings for synchronization';
				|it = 'Selezionare dispositivo con impostazioni individuali per la sincronizzazione';
				|pl = 'Wybierz urządzenie z indywidualnymi ustawieniami do synchronizacji';
				|tr = 'Senkronizasyon için bireysel ayarlara sahip bir cihaz seçin'");
EndProcedure

#EndRegion
