
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ExplanationText = "";
	HeightOfExplanation = 1;
	
	If Parameters.Filter.Property("Ref")
	 And TypeOf(Parameters.Filter.Ref) = Type("ValueList") Then
	 	
	 	AvailableOptions = Parameters.Filter.Ref;
		If AvailableOptions.FindByValue(Enums.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount) <> Undefined
			Or Parameters.PropertyNameForSelectionResult = "ReflectionOptionIncreasingQuantityByOrderWarehouse" Then
			HeightOfExplanation = 4;
			ExplanationText = NStr("vi = 'Số lượng hàng hóa theo chứng từ lớn hơn. Sử dụng sơ đồ hai pha khi phản ánh hàng thừa và hàng thiếu.';
									|ru = 'Количество товара по документу больше. Используется ордерная схема при отражении излишков и недостач.';
									|en = 'Quantity of goods against the document is greater. Warehouse management is used to record surpluses and shortages.'; fa = 'Quantity of goods against the document is greater. Warehouse management is used to record surpluses and shortages.';
									|it = 'La quantità della merce secondo il documento è maggiore. Viene utilizzato lo schema dei mandati per la rilevazione di eccedenze e ammanchi.';
									|pl = 'Ilość towarów wg dokumentu jest większa. Schemat zamówień jest wykorzystywany do odzwierciedlenia nadwyżek i niedoborów.';
									|tr = 'Belgedeki ürün miktarı daha fazladır. Sipariş şeması, fazlalıkları ve eksiklikleri yansıtırken kullanılır.'") + Chars.LF + Chars.LF;
		ElsIf AvailableOptions.FindByValue(Enums.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock) <> Undefined
			Or Parameters.PropertyNameForSelectionResult = "ReflectionOptionIncreaseQuantityWithoutInventory" Then
			HeightOfExplanation = 4;
			ExplanationText = NStr("vi = 'Số lượng hàng hóa theo chứng từ lớn hơn. Không sử dụng sơ đồ hai pha khi phản ánh hàng thừa và hàng thiếu.';
									|ru = 'Количество товара по документу больше. Не используется ордерная схема при отражении излишков и недостач.';
									|en = 'Quantity of goods against the document is greater. Warehouse management is not used to record surpluses and shortages.'; fa = 'Quantity of goods against the document is greater. Warehouse management is not used to record surpluses and shortages.';
									|it = 'La quantità della merce secondo il documento è maggiore. Non viene utilizzato lo schema dei mandati per la rilevazione di eccedenze e ammanchi.';
									|pl = 'Ilość towarów wg dokumentu jest większa. Schemat zamówień nie jest wykorzystywany do odzwierciedlenia nadwyżek i niedoborów.';
									|tr = 'Belgedeki ürün miktarı daha fazladır. Sipariş şeması, fazlalıkları ve eksiklikleri yansıtırken kullanılmıyor.'") + Chars.LF + Chars.LF;
		ElsIf AvailableOptions.FindByValue(Enums.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount) <> Undefined
			Or Parameters.PropertyNameForSelectionResult = "ReflectionOptionReductionOfQuantityByOrderWarehouse" Then
			HeightOfExplanation = 4;
			ExplanationText = NStr("vi = 'Số lượng hàng hóa theo chứng từ ít hơn. Sử dụng sơ đồ hai pha khi phản ánh hàng thừa và hàng thiếu.';
									|ru = 'Количество товара по документу меньше. Используется ордерная схема при отражении излишков и недостач.';
									|en = 'Quantity of goods against the document is less. Warehouse management is used to record surpluses and shortages.'; fa = 'Quantity of goods against the document is less. Warehouse management is used to record surpluses and shortages.';
									|it = 'La quantità della merce secondo il documento è minore. Viene utilizzato lo schema dei mandati per la rilevazione di eccedenze e ammanchi.';
									|pl = 'Ilość towarów wg dokumentu jest mniejsza. Schemat zamówień jest wykorzystywany do odzwierciedlenia nadwyżek i niedoborów.';
									|tr = 'Belgedeki ürün miktarı daha azdır. Sipariş şeması, fazlalıkları ve eksiklikleri yansıtırken kullanılır.'") + Chars.LF + Chars.LF;
		ElsIf AvailableOptions.FindByValue(Enums.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock) <> Undefined
			Or Parameters.PropertyNameForSelectionResult = "ReflectionOptionReducingQuantityWithoutInventory" Then
			HeightOfExplanation = 4;
			ExplanationText = NStr("vi = 'Số lượng hàng hóa theo chứng từ ít hơn. Không sử dụng sơ đồ hai pha khi phản ánh hàng thừa và hàng thiếu.';
									|ru = 'Количество товара по документу меньше. Не используется ордерная схема при отражении излишков и недостач.';
									|en = 'Quantity of goods against the document is less. Warehouse management is not used to record surpluses and shortages.'; fa = 'Quantity of goods against the document is less. Warehouse management is not used to record surpluses and shortages.';
									|it = 'La quantità della merce secondo il documento è minore. Non viene utilizzato lo schema dei mandati per la rilevazione di eccedenze e ammanchi.';
									|pl = 'Ilość towarów wg dokumentu jest mniejsza. Schemat zamówień nie jest wykorzystywany do odzwierciedlenia nadwyżek i niedoborów.';
									|tr = 'Belgedeki ürün miktarı daha azdır. Sipariş şeması, fazlalıkları ve eksiklikleri yansıtırken kullanılmıyor.'") + Chars.LF + Chars.LF;
		ElsIf Parameters.PropertyNameForSelectionResult = "ReflectionOptionReducingAmount" Then
			HeightOfExplanation = 2;
			ExplanationText = NStr("vi = 'Số tiền chứng từ nhỏ hơn.';
									|ru = 'Сумма по документу меньше.';
									|en = 'The document amount is smaller.'; fa = 'The document amount is smaller.';
									|it = 'Сумма по документу меньше.';
									|pl = 'The document amount is smaller.';
									|tr = 'Belgedeki tutar daha azdır.'") + Chars.LF + Chars.LF;
		ElsIf Parameters.PropertyNameForSelectionResult = "ReflectionOptionIncreaseAmount" Then
			HeightOfExplanation = 2;
			ExplanationText = NStr("vi = 'Số tiền chứng từ lớn hơn.';
									|ru = 'Сумма по документу больше.';
									|en = 'The document amount is bigger.'; fa = 'The document amount is bigger.';
									|it = 'Сумма по документу больше.';
									|pl = 'The document amount is bigger.';
									|tr = 'Belgedeki tutar daha fazladır.'") + Chars.LF + Chars.LF;
		EndIf;
		
	EndIf;
	
	Items.ExplanationText.Height = HeightOfExplanation;
	ExplanationText = ExplanationText + NStr("vi = 'Hãy chọn phương án phản ánh chênh lệch:';
											|ru = 'Выберите вариант отражения расхождений:';
											|en = 'Select a discrepancy posting option:'; fa = 'Select a discrepancy posting option:';
											|it = 'Selezionate la modalità di rilevazione delle discrepanze:';
											|pl = 'Wybierz opcję, aby odzwierciedlić odchylenie:';
											|tr = 'Tutarsızlığı yansıtmak için seçeneği seç:'");
	
EndProcedure

#EndRegion
