#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("Goods.QuantityIsSelected");
	
	Filter = New Structure("Check", True);
	TaggedProducts = Goods.FindRows(Filter); // Array of LineOfATabularSection
	
	For Each RowOfGoods In TaggedProducts Do
		
		If RowOfGoods.QuantityIsSelected = 0 And Not ByPhysicalCountResults Then
			MessageText = NStr("vi = 'Chưa điền cột ""Số lượng trên hóa đơn"" trong dòng số %LineNumber%';
								|ru = 'Не заполнена колонка ""Количество в накладную"" в строке номер %LineNumber%';
								|en = 'Column ""Selected quantity"" in %LineNumber% line is not filled in'; fa = 'Column ""Selected quantity"" in %LineNumber% line is not filled in';
								|it = 'La colonna ""Quantità nella bolla di spedizione""non è compilata alla riga numero %LineNumber%';
								|pl = 'Nie została wypełniona kolumna ""Ilość do faktury"" w wierszu numer %LineNumber%';
								|tr = 'Satır numarası %LineNumber%''daki ""İrsaliyedeki miktar"" sütunu doldurulmadı'");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfGoods.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "QuantityIsSelected");
			
			CommonClientServer.MessageToUser(MessageText, Undefined, Field, "", Cancel);
		EndIf;
		
		If RowOfGoods.LeftToSelect < 0 Then
			MessageText = NStr("vi = 'Số lượng trong cột ""Số lượng trên hóa đơn"" vượt quá giá trị của cột ""Đã chuyển"" trong dòng số %LineNumber%';
								|ru = 'Количество в колонке ""Количество в накладную"" превышает значение колонки ""Передано"" в строке номер %LineNumber%';
								|en = 'Quantity in the ""Selected quantity"" column exceeds the value of the ""Transferred"" column in line %LineNumber%'; fa = 'Quantity in the ""Selected quantity"" column exceeds the value of the ""Transferred"" column in line %LineNumber%';
								|it = 'Quantità nella colonna ""Quantità nella bolletta di spedizione"" supera il valore della colonna ""Trasferito"" alla riga %LineNumber%';
								|pl = 'Liczba w kolumnie „Ilość w fakturze” przekracza wartość kolumny „Wysłane” w wierszu numer %LineNumber%';
								|tr = '""İrsaliyedeki Miktar"" sütunundaki miktar, %LineNumber% satır numarasındaki ""Transfer edildi"" sütununun değerini aşıyor'");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfGoods.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "QuantityIsSelected");
			
			CommonClientServer.MessageToUser(MessageText, Undefined, Field, "", Cancel);
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf