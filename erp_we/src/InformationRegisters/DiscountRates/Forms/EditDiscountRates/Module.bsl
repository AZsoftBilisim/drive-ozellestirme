
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Organization = Parameters.Organization;
	Period = Parameters.Period;
	
	For Each BidLine In Parameters.ValuesOfDiscountRates Do
		NewRow = ValuesOfDiscountRates.Add();
		FillPropertyValues(NewRow, BidLine);
	EndDo;

	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.DiscountRates);
	
	Items.ValuesOfDiscountRates.ReadOnly = ReadOnly;
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	Items.ValuesOfDiscountRatesCurrency.Visible = UseMultipleCurrencies;
	If Not UseMultipleCurrencies Then
		DefaultCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	Title = NStr("vi = 'Tỷ lệ tính chiết khấu cho';
				|ru = 'Ставки дисконтирования для';
				|en = 'Discounting rates for'; fa = 'Discounting rates for';
				|it = 'Aliquote sconto per';
				|pl = 'Stawki dyskontowania dla';
				|tr = 'İskonto oranları'") + " " + Organization;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersValuesOfDiscountRates

&AtClient
Procedure ValuesOfDiscountRatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Not UseMultipleCurrencies And ValuesOfDiscountRates.Count() > 0 Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure ValuesOfDiscountRatesOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command) 
	
	If Modified Then
		
		If UseMultipleCurrencies Then
			
			ClearMessages();
			Cancel = False;
			FillingErrors = FillChecking();
			CommonClientServer.ReportErrorsToUser(FillingErrors, Cancel);
			
			If Cancel Then
				Return;
			EndIf;
			
		EndIf;
		
		ValueSelected = New Array;
		For Each BidLine In ValuesOfDiscountRates Do
			NewRow = New Structure("Currency, DiscountRate");
			FillPropertyValues(NewRow, BidLine);
			If Not UseMultipleCurrencies Then
				NewRow.Currency = DefaultCurrency;
			EndIf;
			ValueSelected.Add(NewRow);
		EndDo;
		
		NotifyChoice(ValueSelected);
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function FillChecking()
	
	FillingErrors = Undefined;
	
	ArrayOfCurrencies = New Array;
	DuplicateErrorPattern = NStr("vi = 'Đã chỉ ra tỷ lệ tính chiết khấu đối với tiền tệ %1';
								|ru = 'Ставка дисконтирования для валюты %1 уже указана';
								|en = 'Discounting rate for the %1 currency is already specified'; fa = 'Discounting rate for the %1 currency is already specified';
								|it = 'L''aliquota sconto per la valuta %1 è già indicata';
								|pl = 'Stawka dyskontowania dla waluty %1 jest już podana';
								|tr = '%1 para birimi için iskonto oranları artık belirtildi'");
	
	For Each BidLine In ValuesOfDiscountRates Do
		If BidLine.Currency.IsEmpty() Then
			CommonClientServer.AddUserError(
				FillingErrors,
				"ValuesOfDiscountRates[%1].Currency",
				NStr("vi = 'Chưa điền trường Tiền tệ';
					|ru = 'Поле Валюта не заполнено';
					|en = '""Currency"" is required'; fa = '""Currency"" is required';
					|it = 'Il campo Valuta non è compilato';
					|pl = 'Pole Waluta nie jest wypełnione';
					|tr = 'Para birimi alanı doldurulmadı'"),
				,
				ValuesOfDiscountRates.IndexOf(BidLine));
		ElsIf ArrayOfCurrencies.Find(BidLine.Currency) = Undefined Then
			ArrayOfCurrencies.Add(BidLine.Currency);
		Else
			CommonClientServer.AddUserError(
				FillingErrors,
				"ValuesOfDiscountRates[%1].Currency",
				StrTemplate(DuplicateErrorPattern, BidLine.Currency),
				,
				ValuesOfDiscountRates.IndexOf(BidLine));
		EndIf;
	EndDo;
	
	Return FillingErrors;
	
EndFunction

#EndRegion