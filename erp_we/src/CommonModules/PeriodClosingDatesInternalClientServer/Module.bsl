///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Identical procedures and functions of PeriodClosingDates and PeriodEndClosingDateEdit forms.

Function ClosingDatesDetails() Export
	
	List = New Map;
	List.Insert("",                      NStr("vi = 'Chưa cài đặt';
												|ru = 'Не установлена';
												|en = 'No date'; fa = 'بدون تاریخ';
												|it = 'Non installato';
												|pl = 'Nie zainstalowana';
												|tr = 'Kurulmadı'"));
	List.Insert("Custom",      NStr("vi = 'Ngày tùy ý';
									|ru = 'Произвольная дата';
									|en = 'Custom date'; fa = 'تاریخ سفارشی';
									|it = 'Data libera';
									|pl = 'Dowolna data';
									|tr = 'Serbest tarih'"));
	List.Insert("EndOfLastYear",     NStr("vi = 'Kỳ năm trước';
											|ru = 'Конец прошлого года';
											|en = 'End of last year'; fa = 'پایان سال گذشته';
											|it = 'Fine dell''anno scorso';
											|pl = 'Koniec poprzedniego roku';
											|tr = 'Geçen yıl sonu'"));
	List.Insert("EndOfLastQuarter", NStr("vi = 'Kỳ quý trước';
										|ru = 'Конец прошлого квартала';
										|en = 'End of last quarter'; fa = 'پایان فصل گذشته';
										|it = 'Fine dell''ultimo trimestre';
										|pl = 'Koniec poprzedniego kwartału';
										|tr = 'Geçen çeyrek sonu'"));
	List.Insert("EndOfLastMonth",   NStr("vi = 'Kỳ tháng trước';
										|ru = 'Конец прошлого месяца';
										|en = 'End of last month'; fa = 'پایان ماه گذشته';
										|it = 'Fine del mese scorso';
										|pl = 'Koniec poprzedniego miesiąca';
										|tr = 'Geçen ay sonu'"));
	List.Insert("EndOfLastWeek",    NStr("vi = 'Kỳ tuần trước';
										|ru = 'Конец прошлой недели';
										|en = 'End of last week'; fa = 'پایان هفته گذشته';
										|it = 'Fine della settimana scorsa';
										|pl = 'Koniec poprzedniego tygodnia';
										|tr = 'Geçen hafta sonu'"));
	List.Insert("PreviousDay",        NStr("vi = 'Ngày trước';
											|ru = 'Предыдущий день';
											|en = 'Previous day'; fa = 'روز قبل';
											|it = 'Giorno precedente';
											|pl = 'Poprzedni dzień';
											|tr = 'Önceki gün'"));
	List.Insert("CurrentDay",           NStr("vi = 'Ngày hiện tại';
											|ru = 'Текущий день';
											|en = 'Current day'; fa = 'Current day';
											|it = 'Giorno corrente';
											|pl = 'Bieżący dzień';
											|tr = 'Geçerli gün'"));
	List.Insert("EndOfTheCurrentWeek",    NStr("vi = 'Cuối tuần hiện tại';
												|ru = 'Конец текущей недели';
												|en = 'End of the current week'; fa = 'End of the current week';
												|it = 'Fine giorno corrente';
												|pl = 'Koniec bieżącego tygodnia';
												|tr = 'Geçerli haftanın sonu'"));
	List.Insert("EndOfTheCurrentMonth",   NStr("vi = 'Cuối tháng hiện tại';
												|ru = 'Конец текущего месяца';
												|en = 'End of the current month'; fa = 'End of the current month';
												|it = 'Fine mese corrente';
												|pl = 'Koniec bieżącego tygodnia';
												|tr = 'Geçerli ayın sonu'"));
	List.Insert("EndOfTheCurrentQuarter", NStr("vi = 'Cuối quý hiện tại';
												|ru = 'Конец текущего квартала';
												|en = 'End of the current quarter'; fa = 'End of the current quarter';
												|it = 'Fine trimeste corrente';
												|pl = 'Koniec bieżącego kwartału';
												|tr = 'Geçerli çeyreğin sonu'"));
	List.Insert("EndOfTheCurrentYear",     NStr("vi = 'Cuối năm nay';
												|ru = 'Конец текущего года';
												|en = 'End of the current year'; fa = 'End of the current year';
												|it = 'Fine corrente anno';
												|pl = 'Koniec bieżącego roku';
												|tr = 'Geçerli ayın sonu'"));
	
	Return List;
	
EndFunction

Procedure SpecifyPeriodEndClosingDateSetupOnChange(Context, CalculatePeriodEndClosingDate = True) Export
	
	If Not Context.ExtendedModeSelected Then
		If Context.PeriodEndClosingDate <> '00010101' And Context.PeriodEndClosingDateDetails = "" Then
			Context.PeriodEndClosingDateDetails = "Custom";
			
		ElsIf Context.PeriodEndClosingDate = '00010101'
		        And Context.PeriodEndClosingDateDetails = "Custom"
		        And Not Context.RecordExists Then
			
			Context.PeriodEndClosingDateDetails = "";
		EndIf;
	EndIf;
	If Context.PeriodEndClosingDateDetails = "" Then
		Context.PeriodEndClosingDate = "00010101";
	EndIf;
	
	Context.RelativePeriodEndClosingDateLabelText = "";
	
	If Context.PeriodEndClosingDateDetails = "Custom" Or Context.PeriodEndClosingDateDetails = "" Then
		Context.PermissionDaysCount = 0;
		Return;
	EndIf;
	
	CalculatedPeriodEndClosingDates = PeriodEndClosingDateCalculation(
		Context.PeriodEndClosingDateDetails, Context.BegOfDay);
	
	If CalculatePeriodEndClosingDate Then
		Context.PeriodEndClosingDate = CalculatedPeriodEndClosingDates.Current;
	EndIf;
	
	LabelText = "";
	
	If Context.EnableDataChangeBeforePeriodEndClosingDate Then
		Days1 = 60*60*24;
		
		AdjustPermissionDaysCount(
			Context.PeriodEndClosingDateDetails, Context.PermissionDaysCount);
		
		PermissionPeriod = CalculatedPeriodEndClosingDates.Current + Context.PermissionDaysCount * Days1;
		
		If CalculatedPeriodEndClosingDates.Current > Context.BegOfDay Then
			
			EstimatedDatesOfBanTakingIntoAccountDaysOfAnticipation = PeriodEndClosingDateCalculation(Context.PeriodEndClosingDateDetails, 
				Context.BegOfDay + Context.PermissionDaysCount * Days1);
			
		Else
			
			EstimatedDatesOfBanTakingIntoAccountDaysOfAnticipation = Undefined;
			
		EndIf;
		
		If EstimatedDatesOfBanTakingIntoAccountDaysOfAnticipation = Undefined Then
			
			If Context.BegOfDay > PermissionPeriod Then
				
				LabelText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không được phép nhập và chỉnh sửa dữ liệu cho tất cả các khoảng thời gian trước đây
						| theo %1 bao gồm (%2).
						|Việc hoãn cho phép nhập và chỉnh sửa dữ liệu 
						|trong khoảng thời gian từ %3 đến %4 đã trôi qua %5.';
						|ru = 'Запрещен ввод и редактирование данных за все прошлые периоды 
						|по %1 включительно (%2).
						|Отсрочка, разрешавшая ввод и редактирование данных 
						|за период с %3 по %4, истекла %5.';
						|en = 'Data entry and editing for all previous periods 
						|up to %1 are prohibited (%2).
						|Delay that allowed data entry and editing 
						|for the period from %3 to %4 expired on %5.'; fa = 'Data entry and editing for all previous periods 
						|up to %1 are prohibited (%2).
						|Delay that allowed data entry and editing 
						|for the period from %3 to %4 expired on %5.';
						|it = 'L''inserimento e la modifica dei dati è vietata per tutti i periodi precedenti 
						|per %1incluso (%2).
						| Il rinvio che permetteva l''inserimento e modifica dei dati 
						| per il periodo dal %3 al %4 è scaduto %5.';
						|pl = 'Jest zakazane wprowadzenie i edycja danych za wszystkie poprzednie okresy 
						|do %1 włącznie (%2).
						| Odroczenie, pozwalające wprowadzenie i edycję danych 
						|za okres od %3 do %4, wygasło %5.';
						|tr = '
						| itibaren %1 kadar tüm geçmiş dönemlerde veri girişi ve düzenleme yasaktır (%2).
						|Yazılımın 
						| itibaren %3 kadar olan dönem boyunca verilerin girilmesine ve düzenlenmesine izin veren erteleme%4 süresi doldu %5.'"),
					Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]),
					Format(CalculatedPeriodEndClosingDates.Prev + Days1, "DLF=D"), Format(CalculatedPeriodEndClosingDates.Current, "DLF=D"),
					Format(PermissionPeriod, "DLF=D"));
				
			Else
				
				If CalculatePeriodEndClosingDate Then
					Context.PeriodEndClosingDate = CalculatedPeriodEndClosingDates.Prev;
				EndIf;
				
				LabelText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '• Đối với %1 bao gồm, việc nhập và chỉnh sửa dữ liệu bị cấm
						| đối với tất cả các kỳ trước đó theo%2
						| và độ trễ đang có hiệu lực, cho phép nhập và chỉnh sửa dữ liệu
						|trong kỳ từ %4 đến %5;
						| • Từ %6, lệnh cấm sẽ bắt đầu nhập và chỉnh sửa dữ liệu
						|cho tất cả các kỳ trước theo%5 (%3).';
						|ru = '• По %1 включительно запрещен ввод и редактирование данных
						|  за все прошлые периоды по %2
						|  и действует отсрочка, разрешающая ввод и редактирование данных 
						|  за период с %4 по %5;
						|• С %6 начнет действовать запрет на ввод и редактирование данных
						|  за все прошлые периоды по %5 (%3).';
						|en = '• You cannot enter and edit data till %1 inclusive 
						|for all previous periods up to %2; 
						|there is a delay that allows data entry and editing 
						|for the period from %4 to %5;
						|• Period-end closing becomes effective from %6 
						| for all previous periods up to %5 (%3).'; fa = '• You cannot enter and edit data till %1 inclusive 
						|for all previous periods up to %2; 
						|there is a delay that allows data entry and editing 
						|for the period from %4 to %5;
						|• Period-end closing becomes effective from %6 
						| for all previous periods up to %5 (%3).';
						|it = '• Per %1 incluso, è vietato l''inserimento e la modifica  dei dati 
						| per tutti i periodi precedenti per %2
						| ed è valido il rinvio che permette l''inserimento e la modifica dei dati 
						| per il periodo dal %4 al %5;
						|• dal %6 il divieto di inserimento e modifica dei dati 
						| diventa attivo per tutti i periodi precedenti per %5 (%3).';
						|pl = '• Do %1 włącznie jest zakazane wprowadzenie i edycja danych 
						| za wszystkie poprzednie okresy według %2
						|  i działa odroczenie, pozwalające wprowadzenie i edycję danych 
						|  za okres od %4 do %5;
						|• Z dnia%6 zacznie obowiązywać zakaz na wprowadzenie i edycję danych 
						|  za wszystkie poprzednie okresy do%5 (%3).';
						|tr = '•  %1 kadar, tüm geçmiş dönemler  %2
						|  kadar veri girişi ve düzenlenmesi 
						| yasaklanmış olup,  %4 itibaren %5 kadar veri girişine ve düzenlenmesine izin veren erteleme geçerlidir
						|;
						|•  %6 itibaren 
						| kadar tüm geçmiş dönemlere ait %5veri girişi ve düzenlenmesi yasaklanacaktır (%3).'"),
						Format(PermissionPeriod, "DLF=D"), Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]),
						Format(CalculatedPeriodEndClosingDates.Prev + Days1, "DLF=D"),  Format(CalculatedPeriodEndClosingDates.Current, "DLF=D"), 
						Format(PermissionPeriod + Days1, "DLF=D"));
				
			EndIf;
			
		Else
			
			LeadTime = CalculatedPeriodEndClosingDates.Current - Context.PermissionDaysCount * Days1 + 1;
			If EstimatedDatesOfBanTakingIntoAccountDaysOfAnticipation.Current <= CalculatedPeriodEndClosingDates.Current Then
				
				LabelText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không được phép nhập và chỉnh sửa dữ liệu cho tất cả các kỳ trước
				|theo %1 bao gồm (%2).
				|Dự đoán, việc cấm nhập và chỉnh sửa dữ liệu
				|của kỳ tiếp theo từ %3 đến %4 sẽ đến %5.';
				|ru = 'Запрещен ввод и редактирование данных за все прошлые периоды 
				|по %1 включительно (%2).
				|Упреждение, запрещающее ввод и редактирование данных 
				|следующего периода с %3 по %4, настанет %5.';
				|en = 'You cannot enter and edit data for all previous 
				|periods up to and including %1 (%2).
				|Data entry and edit of the following 
				|period from %3 to %4 will be prevented on %5.'; fa = 'You cannot enter and edit data for all previous 
				|periods up to and including %1 (%2).
				|Data entry and edit of the following 
				|period from %3 to %4 will be prevented on %5.';
				|it = 'Vietato l''inserimento e la modifica dei dati per tutti i periodi precedenti 
				| per %1 incluso (%2). 
				| L''anticipazione che vieta l''inserimento e la modifica dei dati 
				| del periodo successivo dal %3 al %4 entra in vigore %5.';
				|pl = 'Jest zakazane wprowadzenie i edycja danych za wszystkie poprzednie okresy  
				|do %1 włącznie (%2).
				|  Wyprzedzenie, zabraniające wprowadzenie i edycję danych 
				|następnego okresu od %3 do %4, nastąpi %5.';
				|tr = '%1 dahil (%2) kadar önceki tüm dönemler için veri girilmesi ve düzenlenmesi yasaktır.
				|%3''ten %4''e kadar olan sonraki dönem için 
				|veri girilmesini ve düzenlenmesini yasaklayan uyarı %5''te gelecektir.'"),
				Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]),
				Format(CalculatedPeriodEndClosingDates.Current + Days1, "DLF=D"), Format(CalculatedPeriodEndClosingDates.Next, "DLF=D"),
				Format(LeadTime, "DLF=D"));
				
			Else
				
				If CalculatePeriodEndClosingDate Then
					Context.PeriodEndClosingDate = EstimatedDatesOfBanTakingIntoAccountDaysOfAnticipation.Current;
				EndIf;
				
				LabelText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã cấm nhập và chỉnh sửa dữ liệu cho tất cả các kỳ trước 
				|theo %1. 
				|Dự đoán, cấm nhập và chỉnh sửa dữ liệu 
				|của kỳ tiếp theo từ %2 đến %3, sẽ đến %4.';
				|ru = 'Запрещен ввод и редактирование данных за все прошлые периоды 
				|по %1 включительно.
				|Упреждение, запрещающее ввод и редактирование данных 
				|следующего периода с %2 по %3, настало %4.';
				|en = 'You cannot enter and edit data for all previous 
				|periods up to and including %1.
				|Data entry and edit of the following 
				|period from %2 to %3 is prevented from %4.'; fa = 'You cannot enter and edit data for all previous 
				|periods up to and including %1.
				|Data entry and edit of the following 
				|period from %2 to %3 is prevented from %4.';
				|it = 'Vietato l''inserimento e la modifica dei dati per tutti i periodi precedenti 
				| per %1 incluso.
				| L''anticipazione che vieta l''inserimento e la modifica dei dati 
				| del periodo successivo dal %2 al %3 è entrata in vigore %4.';
				|pl = 'Jest zakazane wprowadzenie i edycja danych za wszystkie poprzednie okresy 
				|do %1 włącznie. 
				|Wyprzedzenie, zabraniające wprowadzenie i edycję danych 
				|następnego okresu od %2 do %3, nastąpiło %4.';
				|tr = '
				|%1 dahil tüm önceki dönemlere ait verilerin girilmesi ve düzenlenmesi yasaktır.
				|%2''den %3''e kadar olan sonraki dönemler için 
				|verilerin girilmesini ve düzenlenmesini yasaklayan bir uyarı %4''e ulaştı.'"),
				Format(Context.PeriodEndClosingDate, "DLF=D"), Format(CalculatedPeriodEndClosingDates.Current + Days1, "DLF=D"), 
				Format(CalculatedPeriodEndClosingDates.Next, "DLF=D"), Format(LeadTime, "DLF=D"));
				
			EndIf;
			
		EndIf;
		
	Else 
		Context.PermissionDaysCount = 0;
		LabelText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không được phép nhập và chỉnh sửa dữ liệu cho tất cả các kỳ trước đây
			           |theo %1 (%2)';
			           |ru = 'Запрещен ввод и редактирование данных за все прошлые периоды
			           |по %1 (%2)';
			           |en = 'Data entry and editing for all previous periods
			           |up to %1 (%2) are restricted'; fa = 'Data entry and editing for all previous periods
			           |up to %1 (%2) are restricted';
			           |it = 'Vietato inserimento e modifica dei dati  per tutti i periodi precedenti 
			           | per %1 (%2)';
			           |pl = 'Jest zakazane wprowadzenie i edycja danych za wszystkie poprzednie okresy 
			           |do %1 (%2)';
			           |tr = '
			           | ile %1 arasındaki tüm geçmiş dönemler için veri girişi ve düzenlenmesi yasaklanmıştır (%2)'"),
			Format(Context.PeriodEndClosingDate, "DLF=D"), Lower(ClosingDatesDetails()[Context.PeriodEndClosingDateDetails]));
	EndIf;
	
	Context.RelativePeriodEndClosingDateLabelText = LabelText;
	
EndProcedure

// Parameters:
//  Context - ClientApplicationForm:
//    * Items - FormAllItems:
//       ** EnableDataChangeBeforePeriodEndClosingDate - FormField
//       ** PermissionDaysCount - FormField
//       ** NoncustomDateNote - FormField
// 
Procedure UpdatePeriodEndClosingDateDisplayOnChange(Context) Export
	
	If Not Context.ExtendedModeSelected Then
		
		If Context.PeriodEndClosingDateDetails = "" Or Context.PeriodEndClosingDateDetails = "Custom" Then
			Context.ExtendedModeSelected = False;
			Context.Items.ExtendedMode.Visible = False;
			Context.Items.OperationModesGroup.CurrentPage = Context.Items.SimpleMode;
		Else
			Context.ExtendedModeSelected = True;
			Context.Items.ExtendedMode.Visible = True;
			Context.Items.OperationModesGroup.CurrentPage = Context.Items.ExtendedMode;
		EndIf;
		
	EndIf;
	
	If Context.PeriodEndClosingDateDetails = "" Or Context.PeriodEndClosingDateDetails = "Custom" Then
		Context.Items.Custom.CurrentPage = ?(Context.PeriodEndClosingDateDetails = "",
			Context.Items.CustomNotUsed, Context.Items.CustomDateUsed);
		EditFormat = ?(Context.RecordExists, "DE=01.01.0001", "");
		Context.Items.PeriodEndClosingDateSimpleMode.EditFormat = EditFormat;
		Context.Items.PeriodEndClosingDate.EditFormat = EditFormat;
		Context.Items.PeriodEndClosingDateProperties.CurrentPage = Context.Items.GroupLessOptions;
		Context.Items.PeriodEndClosingDateSimpleMode.UpdateEditText();
		Context.Items.PeriodEndClosingDate.UpdateEditText();
		Context.EnableDataChangeBeforePeriodEndClosingDate = False;
		Return;
	EndIf;
	
	Context.Items.PeriodEndClosingDateProperties.CurrentPage = Context.Items.RelativeDate;
	Context.Items.Custom.CurrentPage = Context.Items.CustomNotUsed;
	
	If Context.PeriodEndClosingDateDetails = "PreviousDay" Then
		Context.Items.EnableDataChangeBeforePeriodEndClosingDate.Enabled = False;
		Context.EnableDataChangeBeforePeriodEndClosingDate = False;
	Else
		Context.Items.EnableDataChangeBeforePeriodEndClosingDate.Enabled = True;
	EndIf;
	
	Context.Items.PermissionDaysCount.Enabled = Context.EnableDataChangeBeforePeriodEndClosingDate;
	Context.Items.NoncustomDateNote.Title = Context.RelativePeriodEndClosingDateLabelText;
	
EndProcedure

Function PeriodEndClosingDateCalculation(Val PeriodEndClosingDateOption, Val CurrentDateAtServer)
	
	Days1 = 60*60*24;
	
	CurrentPeriodEndClosingDate    = '00010101';
	PreviousPeriodEndClosingDate = '00010101';
	NextBanDate  = '00010101';
	
	If PeriodEndClosingDateOption = "EndOfLastYear" Then
		CurrentPeriodEndClosingDate    = BegOfYear(CurrentDateAtServer) - Days1;
		PreviousPeriodEndClosingDate = BegOfYear(CurrentPeriodEndClosingDate)   - Days1;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastQuarter" Then
		CurrentPeriodEndClosingDate    = BegOfQuarter(CurrentDateAtServer) - Days1;
		PreviousPeriodEndClosingDate = BegOfQuarter(CurrentPeriodEndClosingDate)   - Days1;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastMonth" Then
		CurrentPeriodEndClosingDate    = BegOfMonth(CurrentDateAtServer) - Days1;
		PreviousPeriodEndClosingDate = BegOfMonth(CurrentPeriodEndClosingDate)   - Days1;
		
	ElsIf PeriodEndClosingDateOption = "EndOfLastWeek" Then
		CurrentPeriodEndClosingDate    = BegOfWeek(CurrentDateAtServer) - Days1;
		PreviousPeriodEndClosingDate = BegOfWeek(CurrentPeriodEndClosingDate)   - Days1;
		
	ElsIf PeriodEndClosingDateOption = "PreviousDay" Then
		CurrentPeriodEndClosingDate    = BegOfDay(CurrentDateAtServer) - Days1;
		PreviousPeriodEndClosingDate = BegOfDay(CurrentPeriodEndClosingDate)   - Days1;
		
	ElsIf PeriodEndClosingDateOption = "CurrentDay" Then
		CurrentPeriodEndClosingDate    = EndOfDay(CurrentDateAtServer);
		NextBanDate  = EndOfDay(EndOfDay(CurrentDateAtServer) + 1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentWeek" Then
		CurrentPeriodEndClosingDate    = EndOfWeek(CurrentDateAtServer);
		NextBanDate  = EndOfWeek(EndOfWeek(CurrentDateAtServer) + 1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentMonth" Then
		CurrentPeriodEndClosingDate    = EndOfMonth(CurrentDateAtServer);
		NextBanDate  = EndOfMonth(EndOfMonth(CurrentDateAtServer) + 1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentQuarter" Then
		CurrentPeriodEndClosingDate    = EndOfQuarter(CurrentDateAtServer);
		NextBanDate  = EndOfQuarter(EndOfQuarter(CurrentDateAtServer) + 1);
		
	ElsIf PeriodEndClosingDateOption = "EndOfTheCurrentYear" Then
		CurrentPeriodEndClosingDate    = EndOfYear(CurrentDateAtServer);
		NextBanDate  = EndOfYear(EndOfYear(CurrentDateAtServer) + 1);
		
	EndIf;
	
	Return New Structure("Current, Prev, Next", CurrentPeriodEndClosingDate, PreviousPeriodEndClosingDate, NextBanDate);
	
EndFunction

Procedure AdjustPermissionDaysCount(Val PeriodEndClosingDateDetails, PermissionDaysCount)
	
	If PermissionDaysCount = 0 Then
		PermissionDaysCount = 1;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastYear" Or PeriodEndClosingDateDetails = "EndOfTheCurrentYear" Then
		If PermissionDaysCount > 90 Then
			PermissionDaysCount = 90;
		EndIf;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastQuarter" Or PeriodEndClosingDateDetails = "EndOfTheCurrentQuarter" Then
		If PermissionDaysCount > 60 Then
			PermissionDaysCount = 60;
		EndIf;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastMonth" Or PeriodEndClosingDateDetails = "EndOfTheCurrentMonth" Then
		If PermissionDaysCount > 25 Then
			PermissionDaysCount = 25;
		EndIf;
		
	ElsIf PeriodEndClosingDateDetails = "EndOfLastWeek" Or PeriodEndClosingDateDetails = "EndOfTheCurrentWeek" Then
		If PermissionDaysCount > 5 Then
			PermissionDaysCount = 5;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
