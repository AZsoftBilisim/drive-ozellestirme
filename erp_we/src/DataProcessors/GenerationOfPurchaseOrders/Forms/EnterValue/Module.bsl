#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FillInText = NStr("vi = 'Điền';
						|ru = 'Заполнить';
						|en = 'Fill'; fa = 'پرکردن';
						|it = 'Compilare';
						|pl = 'Wypełnij';
						|tr = 'Doldur'");

	Mode = Parameters.Mode;

	If Mode = "MinimumBalance" Then

		Items.Pages.CurrentPage = Items.PageBalance;
		Title = NStr("vi = 'Điền số dư tối thiểu';
					|ru = 'Заполнение минимального остатка';
					|en = 'Fill in min stock level'; fa = 'تکمیل حداقل سطح موجودی';
					|it = 'Compilazione del residuo minimo';
					|pl = 'Wypełnienie minimalnego ostatku';
					|tr = 'Minimum bakiyenin doldurulması'");
		Items.RadioButtonBalance.ChoiceList.Add(0, NStr("vi = 'Số dư tối thiểu:';
														|ru = 'Минимальный остаток:';
														|en = 'Min stock level:'; fa = 'Min stock level:';
														|it = 'Residuo minimo:';
														|pl = 'Minimalny ostatek:';
														|tr = 'Minimum bakiye:'"));
		Items.Command.Title = FillInText;
		Switch(0);

	ElsIf Mode = "MaximumBalance" Then

		Items.Pages.CurrentPage = Items.PageBalance;
		Title = NStr("vi = 'Điền số dư tối đa';
					|ru = 'Заполнение максимального остатка';
					|en = 'Fill in max balance'; fa = 'تکمیل حداکثر مانده';
					|it = 'Compilazione del residuo massimo';
					|pl = 'Wypełnienie maksymalnego ostatku';
					|tr = 'Maksimum bakiyenin doldurulması'");
		Items.RadioButtonBalance.ChoiceList.Add(0, NStr("vi = 'Số dư tối đa:';
														|ru = 'Максимальный остаток:';
														|en = 'Max balance:'; fa = 'Max balance:';
														|it = 'Residuo massimo:';
														|pl = 'Maksymalny ostatek:';
														|tr = 'Maksimum bakiye:'"));
		Items.Command.Title = FillInText;
		Items.ToolTip.Title = StrReplace(Items.ToolTip.Title,
			NStr("vi = 'Tối thiểu';
				|ru = 'Минимальный';
				|en = 'Minimum'; fa = 'حداقل';
				|it = 'Minimo';
				|pl = 'Minimum';
				|tr = 'Minimum'"), NStr("vi = 'Tối đa';
										|ru = 'Максимальный';
										|en = 'Maximum'; fa = 'حداکثر';
										|it = 'Massimo';
										|pl = 'Maximum';
										|tr = 'Maksimum'"));
		Switch(0);

	ElsIf Mode = "SalesPeriod" Then

		Items.Pages.CurrentPage = Items.PageSalesPeriod;
		Title = NStr("vi = 'Đặt kỳ tính doanh thu bán hàng';
					|ru = 'Установка периода расчета продаж';
					|en = 'Set sales calculation period'; fa = 'Set sales calculation period';
					|it = 'Impostazione del periodo di calcolo delle vendite';
					|pl = 'Ustawienie okresu rozliczenia sprzedaży';
					|tr = 'Satış hesaplama döneminin ayarlanması'");

	EndIf;

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure SwitchWhenChanging(Item)

	Switch(0);

EndProcedure

&AtClient
Procedure Switch1WhenChanging(Item)

	Switch(1);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure Switch(IndexOf)

	RadioButton = IndexOf;
	Items.Balance.Enabled        = RadioButton = 0;

	If Not Items.Balance.Enabled Then
		Balance = 0;
	Else
		DaysCount = 0;
	EndIf;

	Items.DaysCount.Enabled = RadioButton = 1;
	Items.ToolTip.Enabled     = RadioButton = 1;
	Items.Command.Title = ?(RadioButton = 0, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Fill';
													|tr = 'Doldur'"), NStr("vi = 'Tính toán và điền';
																		|ru = 'Рассчитать и заполнить';
																		|en = 'Calculate and populate'; fa = 'Calculate and populate';
																		|it = 'Calcolare e compilare';
																		|pl = 'Rozlicz i wypełnij';
																		|tr = 'Hesapla ve doldur'"));

EndProcedure

&AtClient
Procedure Command(Command)

	Result = New Structure("Mode", Parameters.Mode);

	If Parameters.Mode = "MinimumBalance" Or Parameters.Mode = "MaximumBalance" Then

		Result.Insert("Calculate", RadioButton = 1);
		Result.Insert("Value",     ?(RadioButton = 0, Balance, DaysCount));

	ElsIf Parameters.Mode = "SalesPeriod" Then

	EndIf;

	NotifyChoice(Result);

EndProcedure

#EndRegion
