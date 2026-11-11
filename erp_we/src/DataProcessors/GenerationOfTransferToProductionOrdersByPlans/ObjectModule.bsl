#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	For Each TSProps In Metadata().TabularSections.GenerationOfOrders.Attributes Do
		If TSProps.FillChecking = FillChecking.ShowError Then
			NotCheckedAttributeArray.Add("GenerationOfOrders." + TSProps.Name);
		EndIf;
	EndDo;
	
	If Not DataPopulationMode Then
		
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2.';
								|ru = 'Не заполнена колонка ""%1"" в строке %2.';
								|en = 'Column ""%1"" in line %2 is not filled in.'; fa = 'Column ""%1"" in line %2 is not filled in.';
								|it = 'Non è stata compilata la colonna ""%1"" nella riga %2.';
								|pl = 'Nie wypełniono kolumny ""%1"" w wierszu%2.';
								|tr = '%2 satırındaki ""%1"" sütunu doldurulmamış.'");
		For Each OrderDataLine In GenerationOfOrders Do
			If Not OrderDataLine.SelectToOrder Or OrderDataLine.NumberOfPackages = 0 Then
				Continue;
			EndIf;
			
			For Each TSProps In Metadata().TabularSections.GenerationOfOrders.Attributes Do
				If TSProps.FillChecking = FillChecking.ShowError 
					And Not ValueIsFilled(OrderDataLine[TSProps.Name]) Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												MessageTemplate, 
												TSProps.Synonym,
												OrderDataLine.LineNumber);
												
					Field = CommonClientServer.PathToTabularSection("GenerationOfOrders", OrderDataLine.LineNumber, TSProps.Name);
					CommonClientServer.MessageToUser(MessageText,, Field,, Cancel);
				EndIf;
			EndDo;
		EndDo;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf
