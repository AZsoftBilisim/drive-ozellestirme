
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("MethodOfAllocatingFinishedProductCosts") Then
		Raise NStr("vi = 'Để mở biểu mẫu, cần truyền các tham số.';
					|ru = 'Для открытия формы необходимо передать параметры.';
					|en = 'To open the form, pass the parameters.'; fa = 'To open the form, pass the parameters.';
					|it = 'Per l''apertura del modulo è necessario trasferire i parametri.';
					|pl = 'Aby otworzyć formularz, musisz przekazać parametry.';
					|tr = 'Formun açılması için parametreleri transfer etmeniz gerekmektedir.'");
	EndIf;
	
	MethodOfAllocatingFinishedProductCosts = Parameters.MethodOfAllocatingFinishedProductCosts;
	CheckDisplayInformationMessage();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	CheckDisplayInformationMessage();
	
EndProcedure

&AtClient
Procedure InformationBarURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "GoToProduction" Then
		
		OpenForm("DataProcessor.CAAdministrationPanel.Form.Production",, ThisForm);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionValue = New Structure;
	SelectionValue.Insert("MethodOfAllocatingFinishedProductCosts", MethodOfAllocatingFinishedProductCosts);
	NotifyChoice(SelectionValue);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckDisplayInformationMessage()
	
	InformationBar = Undefined;
	
	If MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByTargetCost Then
		
		RowsArray = New Array();
		PriceKind = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
		If Not ValueIsFilled(PriceKind) Then
			StringText = NStr("vi = 'Trong cài đặt của phần Sản xuất, loại giá của chi phí sản phẩm đầu ra theo kế hoạch không được đặt';
								|ru = 'В настройках раздела ""Производство"" не задан вид цены плановой стоимости выходных изделий';
								|en = 'Price type of the standard cost for finished products is not specified in the Production section settings'; fa = 'Price type of the standard cost for finished products is not specified in the Production section settings';
								|it = 'Nelle impostazioni della sezione ""Produzione"",  il tipo di prezzo del costo di output pianificato non è specificato.';
								|pl = 'W ustawieniach sekcji ""Produkcja"" nie określono rodzaju ceny planowanego kosztu wyjściowego wyrobu';
								|tr = '""Üretim"" bölümündeki ayarlarda, üretilen nihai ürünlerin standart maliyet fiyatının türü belirtilmedi'");
			RowsArray.Add(New FormattedString(StringText));
			RowsArray.Add(" ");
			RowsArray.Add(New FormattedString(NStr("vi = '(mở)';
													|ru = '(открыть)';
													|en = '(open)'; fa = '(open)';
													|it = '(aprire)';
													|pl = '(open)';
													|tr = '(aç)'"),,,, "GoToProduction"));
		EndIf;
		InformationBar = New FormattedString(RowsArray);
	
	EndIf;
	
	Items.InfoBar.Visible = ValueIsFilled(InformationBar);
	
EndProcedure

#EndRegion