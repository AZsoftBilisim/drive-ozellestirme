
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	MessageText = Parameters.MessageText;
	
	DataArray = New Array;
	DataForEventLog = Parameters.DataForEventLog;
	If TypeOf(DataForEventLog) = Type("Structure") Then
		For Each KeyAndValue In DataForEventLog Do
			DataArray.Add(String(KeyAndValue.Key) + "=" + String(KeyAndValue.Value));
		EndDo;
	EndIf;
	
	WriteLogEvent(
		NStr("vi = 'Bán lẻ';
			|ru = 'Розничные продажи';
			|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
			|it = 'Vendite al dettaglio';
			|pl = 'Sprzedaże detaliczne';
			|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
		EventLogLevel.Error,,
		Parameters.Data,
		MessageText + " " + NStr("vi = 'Dữ liệu';
								|ru = 'Данные';
								|en = 'Data'; fa = 'داده';
								|it = 'Dati';
								|pl = 'Data';
								|tr = 'Veriler'")+ ":" + StrConcat(DataArray, ","));
	
EndProcedure
