#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	CurrentSessionDate = CurrentSessionDate();
	
	If Parameters.Property("Country") Then
		Country = Parameters.Country;
	Else
		Country = SettingsValueClientServerCached.MainCountry();
	EndIf;
	
	If Parameters.Property("Period") Then
		Period = Parameters.Period;
	Else
		Period = CurrentSessionDate;
	EndIf; 
	
	If Parameters.Property("VATRate") Then
		CommonClientServer.SetDynamicListFilterItem(
			ItemList, "VATRate", Parameters.VATRate);
	EndIf;
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Country", Country);
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Period", ?(Not ValueIsFilled(Period), CurrentSessionDate, EndOfDay(Period)));
	CommonClientServer.SetDynamicListParameter(
		ItemList, "UseExcisableGoods", UseExcisableGoods);
	
	UpdateBidInformation();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_Products" Then
		UpdateBidInformation();
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PeriodOnChange(Item)
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Period", ?(Not ValueIsFilled(Period), CurrentSessionDate, EndOfDay(Period)));
	UpdateBidInformation();
EndProcedure

&AtClient
Procedure CountryOnChange(Item)
	CommonClientServer.SetDynamicListParameter(
		ItemList, "Country", Country);
	UpdateBidInformation();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetVATRateOfProductItemForCurSelection(Command)
	
	StartSettingVATRates(False);
	
EndProcedure

&AtClient
Procedure SetProductSVATRateBasedOnSelectedLines(Command)
	
	SelectedRows = Items.ItemList.SelectedRows;
	If SelectedRows.Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Để tiếp tục, cần tách dòng';
										|ru = 'Для продолжения необходимо выделить строки';
										|en = 'Select lines to continue'; fa = 'Select lines to continue';
										|it = 'Per continuare è necessario evidenziare le righe';
										|pl = 'Aby kontynuować należy wybrać wiersze';
										|tr = 'Devam etmek için satırları seçin'"));
		Return;
	EndIf;
	
	SelectedRowsList.Clear();
	For Each Item In SelectedRows Do
		SelectedRowsList.Add(Item);
	EndDo;
	
	StartSettingVATRates(True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListVATRate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// 
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListVATRate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định>';
													|ru = '<не указана>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non indicata>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
EndProcedure

&AtServer
Procedure UpdateBidInformation()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	COUNT(1) AS Count
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period, Country = &Country) AS ProductsVATRates
	|		ON CatalogProducts.Ref = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &Country) AS BasicVATRates
	|		ON (TRUE)
	|WHERE
	|	CatalogProducts.IsFolder = FALSE
	|
	|GROUP BY
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))";
	Query.SetParameter("Period", Period);
	Query.SetParameter("Country", Country);
	
	StringsList = New Array;
	StringsList.Add(NStr("vi = 'Toàn bộ mặt hàng có thuế suất:';
						|ru = 'Всего номенклатуры со ставками:';
						|en = 'Total items with rates:'; fa = 'Total items with rates:';
						|it = 'Totale nomenclatura con aliquote:';
						|pl = 'Łącznie pozycji ze stawkami:';
						|tr = 'Oran ile tüm öğeler:'"));
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Not ValueIsFilled(Selection.VATRate) Then
			VATRate = NStr("vi = '<chưa chỉ định>';
							|ru = '<не указана>';
							|en = '<not specified>'; fa = '<مشخص نشده>';
							|it = '<non indicata>';
							|pl = '<nie określono>';
							|tr = '<belirtilmedi>'");
		Else
			VATRate = Selection.VATRate;
		EndIf;
		StringsList.Add(StrTemplate(NStr("vi = '%1 - %2 mặt hàng.';
										|ru = '%1 - %2 шт.';
										|en = '%1 - %2 pcs.'; fa = '%1 - %2 pcs.';
										|it = '%1 - %2 pz.';
										|pl = '%1 - %2 szt.';
										|tr = '%1 - %2 tane.'"), VATRate, Selection.Count));
	EndDo;
	
	BidInformation = New FormattedString(StrConcat(StringsList, " "), , StyleColors.HelpText);
	
EndProcedure

&AtServer
Function SetVATRateOfProductItemForCurSelectionOnServer(Result)
	
	Schema = Items.ItemList.GetPerformingDataCompositionScheme();
	Settings = Items.ItemList.GetPerformingDataCompositionSettings();
	
	MethodName = "InformationRegisters.ProductsVATRates.SetVATRateOfProductItemForCurSelection";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Đặt thuế suất GTGT mặt hàng tại các dòng đã chọn';
													|ru = 'Установка ставок НДС номенклатуры по выделенным строкам';
													|en = 'Set VAT rates of items by selected lines'; fa = 'Set VAT rates of items by selected lines';
													|it = 'Impostazione delle aliquote IVA di nomenclatura per righe evidenziate';
													|pl = 'Ustawienie stawek VAT pozycji według wybranych wierszy';
													|tr = 'Seçili satırlar için ürünlerin KDV oranları ayarlanıyor'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, Schema, Settings, Result);
	
EndFunction

&AtServer
Function SetVATRateOfProductItemBasedOnSelectedLinesOnServer(ItemList, Result)
	
	MethodName = "InformationRegisters.ProductsVATRates.SetProductSVATRateBasedOnSelectedLines";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Đặt thuế suất GTGT mặt hàng tại các dòng đã chọn';
													|ru = 'Установка ставок НДС номенклатуры по выделенным строкам';
													|en = 'Set VAT rates of items by selected lines'; fa = 'Set VAT rates of items by selected lines';
													|it = 'Impostazione delle aliquote IVA di nomenclatura per righe evidenziate';
													|pl = 'Ustawienie stawek VAT pozycji według wybranych wierszy';
													|tr = 'Seçili satırlar için ürünlerin KDV oranları ayarlanıyor'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, ItemList, Result);
	
EndFunction

&AtClient
Procedure StartSettingVATRates(BySelectedLines)
	
	FormParameters = New Structure;
	FormParameters.Insert("Period", Period);
	FormParameters.Insert("Country", Country);
	FormParameters.Insert("BySelectedLines", BySelectedLines);
	
	OpenForm("InformationRegister.ProductsVATRates.Form.ParametersSettingVATRates", FormParameters,,,,,
		New CallbackDescription("ParametersSettingVATRatesCompletion", ThisObject),);
	
EndProcedure

&AtClient
Procedure ParametersSettingVATRatesCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Result.BySelectedLines Then
			TimeConsumingOperation = SetVATRateOfProductItemBasedOnSelectedLinesOnServer(SelectedRowsList, Result);
		Else
			TimeConsumingOperation = SetVATRateOfProductItemForCurSelectionOnServer(Result);
		EndIf;
		If TimeConsumingOperation <> Undefined Then
			CallbackOnCompletion = New CallbackDescription("AfterCompletingCompletionOfSettingVATRates", ThisObject);
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputMessages = True;
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCompletingCompletionOfSettingVATRates(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				Items.ItemList.Refresh();
				ShowUserNotification(NStr("vi = 'Đã đặt thuế suất GTGT mặt hàng';
											|ru = 'Ставки НДС номенклатуры установлены';
											|en = 'VAT rates for items are set'; fa = 'VAT rates for items are set';
											|it = 'Aliquote IVA di nomenclatura impostate';
											|pl = 'Stawki VAT pozycji są ustawione';
											|tr = 'Ürünlerin KDV oranları ayarlandı'"));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
