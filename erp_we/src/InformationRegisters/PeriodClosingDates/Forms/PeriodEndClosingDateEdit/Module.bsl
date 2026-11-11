///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UserPresentation = Parameters.UserPresentation;
	SectionPresentation       = Parameters.SectionPresentation;
	Object                    = Parameters.Object;
	PeriodEndClosingDateDetails       = Parameters.PeriodEndClosingDateDetails;
	PermissionDaysCount  = Parameters.PermissionDaysCount;
	PeriodEndClosingDate               = Parameters.PeriodEndClosingDate;
	RecordExists          = Parameters.RecordExists;
	If Not IsBlankString(Parameters.NoClosingDatePresentation) Then
		Items.PeriodEndClosingNotSet.ChoiceList[0].Presentation = Parameters.NoClosingDatePresentation;
	EndIf;	
	
	EnableDataChangeBeforePeriodEndClosingDate = PermissionDaysCount > 0;
	
	If Not ValueIsFilled(SectionPresentation)
	   And Not ValueIsFilled(Object) Then
	   
		Items.SectionPresentation.Visible = False;
		Items.ObjectPresentation.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "NoSectionOrObject");
		
	ElsIf Not ValueIsFilled(SectionPresentation) Then
		Items.SectionPresentation.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "NoSection");
	
	ElsIf Not ValueIsFilled(Object) Then
		Items.ObjectPresentation.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "NoObject");
		
	ElsIf ValueIsFilled(Object) Then
		If TypeOf(Object) = Type("String") Then
			Items.ObjectPresentation.TitleLocation = FormItemTitleLocation.None;
			Items.ObjectPresentation.Hyperlink = False;
		Else
			If Metadata.Documents.Contains(Object.Metadata()) Then
				ObjectPresentation = NStr("vi = 'Chứng từ';
											|ru = 'Документ';
											|en = 'Document'; fa = 'سند';
											|it = 'Documento';
											|pl = 'Dokument';
											|tr = 'Belge'");
			ElsIf Metadata.Enums.Contains(Object.Metadata()) Then
				ObjectPresentation = NStr("vi = 'Phần tử';
											|ru = 'Элемент';
											|en = 'Item'; fa = 'قلم';
											|it = 'Elemento';
											|pl = 'Element';
											|tr = 'Öğe'");
				Items.ObjectPresentation.Hyperlink = False;
			Else	
				ObjectPresentation = Object.Metadata().ObjectPresentation;
				If IsBlankString(ObjectPresentation) Then
					ObjectPresentation = Object.Metadata().Presentation();
				EndIf;
			EndIf;
			Items.ObjectPresentation.Title = ObjectPresentation;
		EndIf;
	EndIf;
	
	If PeriodEndClosingDateDetails = "" Then // Not specified.
		PeriodEndClosingDateDetails = "Custom";
	EndIf;
	
	// Caching the current date on the server.
	BegOfDay = CurrentSessionDate();
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(ThisObject);
	
	If PeriodEndClosingDateDetails = "Custom" Then
		CurrentItem = Items.PeriodEndClosingDateSimpleMode;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	NotifyChoice(ReturnValue);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateHeaderTakesEffectWithDeferredPreemption();
	FillInDescriptionsOfDatesWhenBudgetingPlanningIsBanned();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CustomPeriodEndClosingDateOnChange(Item)
	
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The same event handlers of the date-change and edit-Date-change forms.

&AtClient
Procedure PeriodEndClosingDateDetailsOnChange(Item)
	
	If Item.Name = "PeriodEndClosingNotSet" Then
		PeriodEndClosingDate = '00010101';
	EndIf;
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	UpdateHeaderTakesEffectWithDeferredPreemption();
EndProcedure

&AtClient
Procedure PeriodEndClosingDateDetailsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	PeriodEndClosingDateDetails = Items.PeriodEndClosingDateDetails.ChoiceList[0].Value;
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PeriodEndClosingDateOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure EnableDataChangeBeforePeriodEndClosingDateOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	UpdateHeaderTakesEffectWithDeferredPreemption();
EndProcedure

&AtClient
Procedure PermissionDaysCountOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PermissionDaysCountAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	If IsBlankString(Text) Then
		Return;
	EndIf;
	
	PermissionDaysCount = Text;
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure ObjectPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, Object);
	
EndProcedure

&AtClient
Procedure MoreOptionsClick(Item)
	
	ExtendedModeSelected = True;
	Items.ExtendedMode.Visible = True;
	Items.OperationModesGroup.CurrentPage = Items.ExtendedMode;
	
EndProcedure

&AtClient
Procedure LessOptionsClick(Item)
	
	ExtendedModeSelected = False;
	Items.ExtendedMode.Visible = False;
	Items.OperationModesGroup.CurrentPage = Items.SimpleMode;
	
EndProcedure
&AtClient
Procedure UpdateHeaderTakesEffectWithDeferredPreemption()
	
	TitleText =  NStr("vi = 'Có hiệu lực có gia hạn đến';
						|ru = 'Вступает в действие с отсрочкой в';
						|en = 'Effect delayed for'; fa = 'اثر با تأخیر به مدت';
						|it = 'Entra in azione con un ritardo in';
						|pl = 'Wchodzi w życie z opóźnieniem na';
						|tr = 'Ertelemeli olarak yürürlüğe girer'");

	If Not PeriodEndClosingDateDetails = "Custom" Then
		If PeriodEndClosingDate > BegOfDay Then
			TitleText =  NStr("vi = 'Đã có hiệu lực trước';
								|ru = 'Вступает в действие с упреждением в';
								|en = 'Becomes effective with lookahead at'; fa = 'Becomes effective with lookahead at';
								|it = 'Entra in azione in anticipo di';
								|pl = 'Wchodzi w życie z wyprzedzeniem na';
								|tr = 'Proaktif olarak yürürlüğe girer'");
		EndIf;
	EndIf;
	
	Items.EnableDataChangeBeforePeriodEndClosingDate.Title = TitleText;
	
EndProcedure

&AtClient
Procedure FillInDescriptionsOfDatesWhenBudgetingPlanningIsBanned()
	
	If SectionPresentation = NStr("vi = 'Quản lý ngân sách';
									|ru = 'Бюджетирование';
									|en = 'Budgeting'; fa = 'بودجه‌بندی';
									|it = 'Budgeting';
									|pl = 'Budgeting';
									|tr = 'Bütçeleme'")
		Or SectionPresentation = NStr("vi = 'Lập kế hoạch';
										|ru = 'Планирование';
										|en = 'Planning'; fa = 'برنامه‌ریزی';
										|it = 'Pianificazione';
										|pl = 'Planning';
										|tr = 'Planlama'") Then
		
		If SectionPresentation = NStr("vi = 'Quản lý ngân sách';
										|ru = 'Бюджетирование';
										|en = 'Budgeting'; fa = 'بودجه‌بندی';
										|it = 'Budgeting';
										|pl = 'Budgeting';
										|tr = 'Bütçeleme'") Then
			Items.PeriodEndClosingDateDetails.ChoiceList.Clear();
			Items.PeriodEndClosingDateDetails.ChoiceList.Add("",NStr("vi = 'Chưa cài đặt';
																	|ru = 'Не установлена';
																	|en = 'Not set'; fa = 'تنظیم نشده';
																	|it = 'Non installato';
																	|pl = 'Nie zainstalowana';
																	|tr = 'Kurulmadı'"));
			Items.PeriodEndClosingDateDetails.ChoiceList.Add("Custom",NStr("vi = 'Ngày tùy ý';
																			|ru = 'Произвольная дата';
																			|en = 'Custom date'; fa = 'تاریخ سفارشی';
																			|it = 'Data libera';
																			|pl = 'Dowolna data';
																			|tr = 'Serbest tarih'"));
		EndIf;

		Items.PeriodEndClosingDateDetails.ChoiceList.Add("CurrentDay",NStr("vi = 'Ngày hiện tại';
																			|ru = 'Текущий день';
																			|en = 'Current day'; fa = 'Current day';
																			|it = 'Giorno corrente';
																			|pl = 'Bieżący dzień';
																			|tr = 'Geçerli gün'"));
		Items.PeriodEndClosingDateDetails.ChoiceList.Add("EndOfTheCurrentWeek",NStr("vi = 'Cuối tuần hiện tại';
																					|ru = 'Конец текущей недели';
																					|en = 'End of the current week'; fa = 'End of the current week';
																					|it = 'Fine giorno corrente';
																					|pl = 'Koniec bieżącego tygodnia';
																					|tr = 'Geçerli haftanın sonu'"));
		Items.PeriodEndClosingDateDetails.ChoiceList.Add("EndOfTheCurrentMonth",NStr("vi = 'Cuối tháng hiện tại';
																					|ru = 'Конец текущего месяца';
																					|en = 'End of the current month'; fa = 'End of the current month';
																					|it = 'Fine mese corrente';
																					|pl = 'Koniec bieżącego tygodnia';
																					|tr = 'Geçerli ayın sonu'"));
		Items.PeriodEndClosingDateDetails.ChoiceList.Add("EndOfTheCurrentQuarter",NStr("vi = 'Cuối quý hiện tại';
																						|ru = 'Конец текущего квартала';
																						|en = 'End of the current quarter'; fa = 'End of the current quarter';
																						|it = 'Fine trimeste corrente';
																						|pl = 'Koniec bieżącego kwartału';
																						|tr = 'Geçerli çeyreğin sonu'"));
		Items.PeriodEndClosingDateDetails.ChoiceList.Add("EndOfTheCurrentYear",NStr("vi = 'Cuối năm nay';
																					|ru = 'Конец текущего года';
																					|en = 'End of the current year'; fa = 'End of the current year';
																					|it = 'Fine corrente anno';
																					|pl = 'Koniec bieżącego roku';
																					|tr = 'Geçerli ayın sonu'"));
	EndIf;
	
EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ReturnValue = New Structure;
	ReturnValue.Insert("PeriodEndClosingDateDetails", PeriodEndClosingDateDetails);
	
	If PeriodEndClosingDateDetails = "" Then
		ReturnValue.Insert("PermissionDaysCount", 0);
		ReturnValue.Insert("PeriodEndClosingDate",              '00010101');
	Else
		ReturnValue.Insert("PermissionDaysCount", PermissionDaysCount);
		ReturnValue.Insert("PeriodEndClosingDate",              PeriodEndClosingDate);
	EndIf;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler()
	
	PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(ThisObject);
	
EndProcedure

#EndRegion
