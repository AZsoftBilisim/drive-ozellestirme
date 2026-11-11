#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns the Protocol of the calculation.
//
// Parameters:
// Id - String -
// Period - Date -
// CalculationPeriod - Date -
//
// Returns:
// 	Structure - LongDesc:
// * Protocol - TextDocument -
// * Title - String -
//
Function GetProtocolText(Id, Period = Undefined, CalculationPeriod = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Period) Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	T.Period
		|FROM
		|	InformationRegister.LotAndCostCalculationProtocols AS T
		|WHERE
		|	T.Id = &Id
		|	AND &CalculationPeriod IN (T.CalculationPeriod, UNDEFINED)";
		
		Query.SetParameter("Id", Id);
		Query.SetParameter("CalculationPeriod", CalculationPeriod);
		
		Selection = Query.Execute().Select();
		If Selection.Count() = 0 Then
			
			Raise NStr("vi = 'Biên bản tính toán không tìm thấy. Có lẽ, biên bản đã bị xóa.';
						|ru = 'Протокола расчета не найден. Возможно протокол был удален.';
						|en = 'Cannot find calculation protocol. The protocol might have been deleted.'; fa = 'Cannot find calculation protocol. The protocol might have been deleted.';
						|it = 'Protocollo di calcolo non trovato. Il protocollo potrebbe essere stato cancellato.';
						|pl = 'Nie znaleziono protokołu obliczeń. Protokół mógł zostać usunięty.';
						|tr = 'Hesaplama protokolü bulunamadı. Protokol silinmiş olabilir.'");
			
		EndIf;
		
		Selection.Next();
		
		RecordPeriod = Selection.Period;
		
	Else
		RecordPeriod = Period;
	EndIf;
	
	// Let's read the record of the protocol
	RecordingProtocol = InformationRegisters.LotAndCostCalculationProtocols.CreateRecordManager();
	RecordingProtocol.Period		  = RecordPeriod;
	RecordingProtocol.Id = Id;
	
	RecordingProtocol.Read();
	
	If RecordingProtocol.Selected() Then
		
		// We will get the protocol in the format of a text document
		Protocol = RecordingProtocol.Protocol.Get();
		
		If TypeOf(Protocol) <> Type("TextDocument") Then
			Raise NStr("vi = 'Lỗi nhận văn bản của Biên bản tính toán.';
						|ru = 'Ошибка получения текста протокола расчета.';
						|en = 'An error occurred when receiving the calculation protocol text.'; fa = 'An error occurred when receiving the calculation protocol text.';
						|it = 'Errore durante il recupero del testo del protocollo di calcolo.';
						|pl = 'Błąd podczas pobierania tekstu protokołu obliczeniowego.';
						|tr = 'Hesaplama protokolü metni alınırken hata.'");
		EndIf;
		
	Else
		
		Raise NStr("vi = 'Biên bản tính toán không tìm thấy. Có lẽ, biên bản đã bị xóa.';
					|ru = 'Протокола расчета не найден. Возможно протокол был удален.';
					|en = 'Cannot find calculation protocol. The protocol might have been deleted.'; fa = 'Cannot find calculation protocol. The protocol might have been deleted.';
					|it = 'Protocollo di calcolo non trovato. Il protocollo potrebbe essere stato cancellato.';
					|pl = 'Nie znaleziono protokołu obliczeń. Protokół mógł zostać usunięty.';
					|tr = 'Hesaplama protokolü bulunamadı. Protokol silinmiş olabilir.'");
		
	EndIf;
	
	Return Protocol;
	
EndFunction

#EndRegion

#EndIf
