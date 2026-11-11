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
	
	Items.DueDate.ToolTip
		= Metadata.InformationRegisters.UsersInfo.Resources.ValidityPeriod.Tooltip;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If TypeOf(FormOwner) <> Type("ClientApplicationForm") Then
		Return;
	EndIf;
	
	InactivityPeriod = FormOwner.InactivityPeriodBeforeDenyingAuthorization;
	DueDate      = FormOwner.ValidityPeriod;
	
	If FormOwner.UnlimitedValidityPeriod Then
		PeriodType = "NoExpiration";
		CurrentItem = Items.PeriodTypeNoExpiration;
		
	ElsIf ValueIsFilled(DueDate) Then
		PeriodType = "TillDate";
		CurrentItem = Items.PeriodTypeTillDate;
		
	ElsIf ValueIsFilled(InactivityPeriod) Then
		PeriodType = "InactivityPeriod";
		CurrentItem = Items.PeriodTypeTimeout;
	Else
		PeriodType = "NotSpecified";
		CurrentItem = Items.PeriodTypeNotSpecified;
	EndIf;
	
	UpdateAvailability1();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodTypeOnChange(Item)
	
	UpdateAvailability1();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If PeriodType = "TillDate" Then
		If Not ValueIsFilled(DueDate) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa chỉ ra ngày';
					|ru = 'Дата не указана.';
					|en = 'The date is not specified.'; fa = 'The date is not specified.';
					|it = 'Data non indicata.';
					|pl = 'Nie wskazano daty.';
					|tr = 'Tarih belirtilmedi.'"),, "DueDate");
			Return;
			
		ElsIf DueDate <= BegOfDay(CommonClient.SessionDate()) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần hạn chế đến ít nhất ngày mai.';
					|ru = 'Ограничение должно быть до завтра или более.';
					|en = 'The expiration date must be tomorrow or later.'; fa = 'The expiration date must be tomorrow or later.';
					|it = 'La restrizione deve durare fino a domani o più.';
					|pl = 'Ograniczenie musi być do jutra lub dłużej.';
					|tr = 'Kısıtlama yarına kadar veya daha fazla olmalıdır.'"),, "DueDate");
			Return;
		EndIf;
	EndIf;
	
	FormOwner.Modified = True;
	FormOwner.InactivityPeriodBeforeDenyingAuthorization = InactivityPeriod;
	FormOwner.ValidityPeriod = DueDate;
	FormOwner.UnlimitedValidityPeriod = (PeriodType = "NoExpiration");
	
	Items.FormOK.Enabled = False;
	AttachIdleHandler("CloseForm", 0.1, True);
	
EndProcedure

#EndRegion

#Region Private
	
&AtClient
Procedure UpdateAvailability1()
	
	If PeriodType = "TillDate" Then
		Items.DueDate.AutoMarkIncomplete = True;
		Items.DueDate.Enabled = True;
	Else
		Items.DueDate.AutoMarkIncomplete = False;
		DueDate = Undefined;
		Items.DueDate.Enabled = False;
	EndIf;
	
	If PeriodType <> "InactivityPeriod" Then
		InactivityPeriod = 0;
	ElsIf InactivityPeriod = 0 Then
		InactivityPeriod = 60;
	EndIf;
	Items.InactivityPeriod.Enabled = PeriodType = "InactivityPeriod";
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	Close();
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
