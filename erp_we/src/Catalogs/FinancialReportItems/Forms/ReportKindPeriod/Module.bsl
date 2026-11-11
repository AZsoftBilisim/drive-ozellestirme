
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	Title = Parameters.ItemKind;
	
	If NumberOfPreviousYears = 0 Then
		NumberOfPreviousYears = 1;
	EndIf;
	
	If NumberOfPreviousPeriods = 0 Then
		NumberOfPreviousPeriods = 1;
	EndIf;
	
	FormControl(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	AdditionalMode_ = Enums.AdditionalModesOfReportItems.ReportKind;
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel, AdditionalMode_);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	If Not OutputIndicatorsOfSimilarPeriodsOfPreviousYears Then
		AttributesNotToCheck.Add("NumberOfPreviousYears");
	EndIf;
	If Not DisplayIndicatorsOfPreviousPeriods Then
		AttributesNotToCheck.Add("NumberOfPreviousPeriods");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure PeriodicityOnChange(Item)
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		OutputIndicatorsOfSimilarPeriodsOfPreviousYears = False;
	EndIf;
	
	Object.NameForPrinting = String(Periodicity);
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OutputIndicatorsOfSimilarPeriodsOfPreviousYearsOnChange(Item)
	FormControl(ThisObject)
EndProcedure

&AtClient
Procedure DisplayIndicatorsOfPreviousPeriodsOnChange(Item)
	FormControl(ThisObject)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	PeriodicityYear = False;
	If Form.Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		PeriodicityYear = True;
	EndIf;
	Form.Items.GroupIndicatorsOfSimilarPeriodsOfPreviousYears.Visible = Not PeriodicityYear;
	Form.Items.NumberOfPreviousYears.Enabled = Form.OutputIndicatorsOfSimilarPeriodsOfPreviousYears;
	Form.Items.NumberOfPreviousPeriods.Enabled = Form.DisplayIndicatorsOfPreviousPeriods;
	
	If Form.Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		Form.Items.OutputIndicatorsOfSimilarPeriodsOfPreviousYears.Title =
			NStr("vi = 'Hiển thị chỉ tiêu tháng tương ứng của các năm trước';
				|ru = 'Выводить показатели аналогичных месяцев прошлых лет';
				|en = 'Show indicators of similar months of previous years'; fa = 'Show indicators of similar months of previous years';
				|it = 'Rilevare indicatori di mesi analoghi degli anni passati';
				|pl = 'Wyświetlaj wskaźniki analogicznych miesięcy zeszłych lat';
				|tr = 'Önceki yılların benzer aylarındaki göstergeleri göster'");
		Form.Items.DisplayIndicatorsOfPreviousPeriods.Title =
			NStr("vi = 'Hiển thị chỉ tiêu của các tháng trước';
				|ru = 'Выводить показатели предыдущих месяцев';
				|en = 'Show indicators of previous months'; fa = 'Show indicators of previous months';
				|it = 'Rilevare indicatori dei mesi precedenti';
				|pl = 'Wyświetlaj wskaźniki poprzednich miesięcy';
				|tr = 'Önceki ayların göstergelerini göster'");
		Form.Items.NumberOfPreviousPeriods.Title =
			NStr("vi = 'Số tháng đã qua';
				|ru = 'Количество предыдущих месяцев';
				|en = 'Number of previous months'; fa = 'Number of previous months';
				|it = 'Numero di mesi precedenti';
				|pl = 'Ilość poprzednich miesięcy';
				|tr = 'Önceki ayların sayısı'");
	ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		Form.Items.OutputIndicatorsOfSimilarPeriodsOfPreviousYears.Title =
			NStr("vi = 'Hiển thị chỉ tiêu quý tương ứng của các năm trước';
				|ru = 'Выводить показатели аналогичных кварталов прошлых лет';
				|en = 'Show indicators of similar quarters of previous years'; fa = 'Show indicators of similar quarters of previous years';
				|it = 'Rilevare indicatori di trimestri analoghi degli anni passati';
				|pl = 'Wyświetlaj wskaźniki analogicznych kwartałów zeszłych lat';
				|tr = 'Önceki yılların benzer çeyreklerin göstergeleri göster'");
		Form.Items.DisplayIndicatorsOfPreviousPeriods.Title =
			NStr("vi = 'Hiển thị chỉ tiêu của các quý trước';
				|ru = 'Выводить показатели предыдущих кварталов';
				|en = 'Show indicators of previous quarters'; fa = 'Show indicators of previous quarters';
				|it = 'Rilevare indicatori dei trimestri precedenti';
				|pl = 'Wyświetlaj wskaźniki poprzednich kwartałów';
				|tr = 'Önceki çeyreklerin göstergeleri göster'");
		Form.Items.NumberOfPreviousPeriods.Title =
			NStr("vi = 'Số lượng các quý trước';
				|ru = 'Количество предыдущих кварталов';
				|en = 'Number of previous quarters'; fa = 'Number of previous quarters';
				|it = 'Quantità precedenti trimestri';
				|pl = 'Ilość poprzednich kwartałów';
				|tr = 'Önceki çeyreklerin sayısı'");
	ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		Form.Items.OutputIndicatorsOfSimilarPeriodsOfPreviousYears.Title =
			NStr("vi = 'Hiển thị chỉ tiêu nửa năm tương ứng của các năm trước';
				|ru = 'Выводить показатели аналогичных полугодий прошлых лет';
				|en = 'Show indicators of similar half-year periods of previous years'; fa = 'Show indicators of similar half-year periods of previous years';
				|it = 'Rilevare indicatori di semestri analoghi degli anni passati';
				|pl = 'Wyświetlaj wskaźniki analogicznych półroczy zeszłych lat';
				|tr = 'Önceki yılların benzer yarıyıllarındaki göstergeleri göster'");
		Form.Items.DisplayIndicatorsOfPreviousPeriods.Title =
			NStr("vi = 'Hiển thị chỉ tiêu của các nửa năm trước';
				|ru = 'Выводить показатели предыдущих полугодий';
				|en = 'Show indicators for previous half-year periods'; fa = 'Show indicators for previous half-year periods';
				|it = 'Rilevare indicatori dei semestri precedenti';
				|pl = 'Wyświetlaj wskaźniki poprzednich półroczy';
				|tr = 'Önceki yarıyılların göstergelerini göster'");
		Form.Items.NumberOfPreviousPeriods.Title =
			NStr("vi = 'Số lượng nửa năm trước';
				|ru = 'Количество предыдущих полугодий';
				|en = 'Number of previous half-year periods'; fa = 'Number of previous half-year periods';
				|it = 'Numero semestri precedenti';
				|pl = 'Ilość poprzednich półroczy';
				|tr = 'Önceki yarıyılların sayısı'");
	ElsIf Form.Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		Form.Items.OutputIndicatorsOfSimilarPeriodsOfPreviousYears.Title =
			NStr("vi = 'Hiển thị chỉ tiêu cùng kỳ các năm trước';
				|ru = 'Выводить показатели аналогичных периодов прошлых лет';
				|en = 'Show indicators for the same periods of previous years'; fa = 'نمایش شاخص‌های دوره‌های مشابه سال‌های قبل';
				|it = 'Rilevare indicatori di periodi analoghi degli anni passati';
				|pl = 'Wyświetlaj wskaźniki analogicznych okresów zeszłych lat';
				|tr = 'Önceki yılların benzer dönemlerinin göstergelerini göster'");
		Form.Items.DisplayIndicatorsOfPreviousPeriods.Title =
			NStr("vi = 'Hiển thị chỉ tiêu của các năm trước';
				|ru = 'Выводить показатели предыдущих лет';
				|en = 'Show indicators of previous years'; fa = 'Show indicators of previous years';
				|it = 'Rilevare indicatori degli anni precedenti';
				|pl = 'Wyświetlaj wskaźniki poprzednich lat';
				|tr = 'Önceki yılların göstergelerini göster'");
		Form.Items.NumberOfPreviousPeriods.Title =
			NStr("vi = 'Số năm trước';
				|ru = 'Количество предыдущих лет';
				|en = 'Number of previous years'; fa = 'تعداد سال‌های قبل';
				|it = 'Numero anni precedenti';
				|pl = 'Ilość poprzednich lat';
				|tr = 'Önceki yılların sayısı'");
	Else
		Form.Items.OutputIndicatorsOfSimilarPeriodsOfPreviousYears.Title =
			NStr("vi = 'Hiển thị chỉ tiêu cùng kỳ các năm trước';
				|ru = 'Выводить показатели аналогичных периодов прошлых лет';
				|en = 'Show indicators for the same periods of previous years'; fa = 'نمایش شاخص‌های دوره‌های مشابه سال‌های قبل';
				|it = 'Rilevare indicatori di periodi analoghi degli anni passati';
				|pl = 'Wyświetlaj wskaźniki analogicznych okresów zeszłych lat';
				|tr = 'Önceki yılların benzer dönemlerinin göstergelerini göster'");
		Form.Items.DisplayIndicatorsOfPreviousPeriods.Title =
			NStr("vi = 'Hiển thị chỉ tiêu của các kỳ trước';
				|ru = 'Выводить показатели предыдущих периодов';
				|en = 'Show indicators for previous periods'; fa = 'نمایش شاخص‌های دوره‌های قبل';
				|it = 'Rilevare indicatori dei periodi precedenti';
				|pl = 'Wyświetlaj wskaźniki poprzednich okresów';
				|tr = 'Önceki dönemlerin göstergelerini göster'");
		Form.Items.NumberOfPreviousPeriods.Title =
			NStr("vi = 'Số lượng các kỳ trước';
				|ru = 'Количество предыдущих периодов';
				|en = 'Number of previous periods'; fa = 'تعداد دوره‌های قبل';
				|it = 'Numero periodi precedenti';
				|pl = 'Ilość poprzednich okresów';
				|tr = 'Önceki dönemlerin sayısı'");
	EndIf;
	
EndProcedure

#EndRegion
