#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	If Object.ServiceLife <> 0 Then
		
		ServiceLifeOfString = StrTemplate(
					NStr("vi = 'từ %1 đến %2 (%3 tháng)';
						|ru = 'с %1 по %2 (%3 мес)';
						|en = 'from %1 to %2 (%3 months)'; fa = 'from %1 to %2 (%3 months)';
						|it = 'da%1 a %2 (%3mesi)';
						|pl = 'od %1 do %2 (%3 mies)';
						|tr = '%1''dan %2 kadar (%3 ay)'"),
					Format(Object.StartDateOfOperation, NStr("vi = 'ДФ=''ММММ ""năm"" гггг''';
															|ru = 'ДФ=''ММММ гггг ""г""''';
															|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
															|it = 'DF=''MMMM yyyy."""";';
															|pl = 'DF=''ММММ yyyy ""r""''';
															|tr = 'DF=''MMMM yyyy ""yıl.""'''")),
					Format(Object.CompletionDate_, NStr("vi = 'ДФ=''ММММ ""năm"" гггг''';
														|ru = 'ДФ=''ММММ гггг ""г""''';
														|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
														|it = 'DF=''MMMM yyyy."""";';
														|pl = 'DF=''ММММ yyyy ""r""''';
														|tr = 'DF=''MMMM yyyy ""yıl.""'''")),
					String(Object.ServiceLife));
					
	Else
		
		ServiceLifeOfString = StrTemplate(
					NStr("vi = 'từ %1';
						|ru = 'с %1';
						|en = 'from %1'; fa = 'from %1';
						|it = 'da %1 ';
						|pl = 'od %1';
						|tr = '%1 itibarıyla'"),
					Format(Object.StartDateOfOperation, NStr("vi = 'ДФ=''ММММ ""năm"" гггг''';
															|ru = 'ДФ=''ММММ гггг ""г""''';
															|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
															|it = 'DF=''MMMM yyyy."""";';
															|pl = 'DF=''ММММ yyyy ""r""''';
															|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
					
	EndIf;
	
EndProcedure

#EndRegion