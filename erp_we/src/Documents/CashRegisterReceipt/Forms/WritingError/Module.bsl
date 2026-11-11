
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	MessageText = Parameters.MessageText;
	
	ArrayOfMessageTextLines = New Array;
	ArrayOfMessageTextLines.Add(MessageText);
	
	DataForEventLog = Parameters.DataForEventLog;
	If TypeOf(DataForEventLog) = Type("Structure") Then
		DataArray = New Array;
		For Each KeyAndValue In DataForEventLog Do
			DataArray.Add(String(KeyAndValue.Key) + "=" + String(KeyAndValue.Value));
		EndDo;
		If DataArray.Count() Then
			ArrayOfMessageTextLines.Add(NStr("vi = 'Dữ liệu';
											|ru = 'Данные';
											|en = 'Data'; fa = 'داده';
											|it = 'Data';
											|pl = 'Data';
											|tr = 'Veriler'")+ ":" + StrConcat(DataArray, ","));
		EndIf;
	EndIf;
	
	WriteLogEvent(
		NStr("vi = 'Bán lẻ';
			|ru = 'Розничные продажи';
			|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
			|it = 'Vendite al dettaglio';
			|pl = 'Sprzedaże detaliczne';
			|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,
		Parameters.Data,
		StrConcat(ArrayOfMessageTextLines, " "));
	
EndProcedure
