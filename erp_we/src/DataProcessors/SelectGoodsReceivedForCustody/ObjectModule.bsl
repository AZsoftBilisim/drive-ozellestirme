#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("Goods.QuantityIsSelected");
	
	Filter = New Structure("Check", True);
	TaggedProducts = Goods.FindRows(Filter);
	
	For Each RowOfGoods In TaggedProducts Do
		
		If RowOfGoods.QuantityIsSelected = 0 Then
			MessageText = NStr("vi = 'Cột ""Số lượng trên hóa đơn"" không được điền vào số dòng %LineNumber%';
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
			MessageText = NStr("vi = 'Số lượng trong cột ""Số lượng trên hóa đơn"" vượt quá giá trị của cột ""%CountBalance%"" trong số dòng %LineNumber%';
								|ru = 'Количество в колонке ""Количество в накладную"" превышает значение колонки ""%CountBalance%"" в строке номер %LineNumber%';
								|en = 'Quantity in the ""Selected quantity"" column exceeds the value of the """"%CountBalance%"" column in line %LineNumber%'; fa = 'Quantity in the ""Selected quantity"" column exceeds the value of the """"%CountBalance%"" column in line %LineNumber%';
								|it = 'La quantità nella colonna ""Quantità nella bolletta di spedizione"" supera il valore della colonna ""%CountBalance%"" alla riga numero %LineNumber%';
								|pl = 'Ilość w kolumnie ""Ilość do faktury"" przekracza wartość kolumny ""%CountBalance%"" w wierszu numer %LineNumber%';
								|tr = '""İrsaliyedeki Miktar"" sütunundaki miktar, %LineNumber% satır numarasındaki ""%CountBalance%"" sütununun değerini aşıyor'");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfGoods.LineNumber);
			MessageText = StrReplace(MessageText, "%CountBalance%", ?(BalanceMode = "AllReceived", NStr("vi = 'Tổng số được chấp nhận';
																										|ru = 'Всего принято';
																										|en = 'Total received'; fa = 'کل دریافتی';
																										|it = 'In totale accettato';
																										|pl = 'Odebrano ogółem';
																										|tr = 'Toplam kabul edildi'"),
												?(BalanceMode = "Retired", NStr("vi = 'Xuất';
																				|ru = 'Выбывшие';
																				|en = 'Disposed'; fa = 'واگذارشده';
																				|it = 'Spediti';
																				|pl = 'Wyprowadzone';
																				|tr = 'Ayrılanlar'"),
												NStr("vi = 'Cần ghi giảm';
													|ru = 'К списанию';
													|en = 'To write off'; fa = 'برای برداشت';
													|it = 'Da stornare';
													|pl = 'Do rozchodu';
													|tr = 'Gider yazılacak'"))));
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "QuantityIsSelected");
			
			CommonClientServer.MessageToUser(MessageText, Undefined, Field, "", Cancel);
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf